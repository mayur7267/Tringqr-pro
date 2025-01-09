//
//  OTPView.swift
//  TringQR
//
//  Created by Mayur on 01/12/24.
//
import SwiftUI
import FirebaseAuth

struct OTPView: View {
    @State private var otp: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var verificationID: String
    @Binding var isOTPViewPresented: Bool
    @Binding var navigateToContent: Bool
    var phoneNumber: String
    var onOTPVerified: () -> Void

    @FocusState private var isOTPFieldFocused: Bool
    @State private var scrollViewProxy: ScrollViewProxy?

    @State private var isResendButtonEnabled = false
    @State private var remainingTime: Int = 60
    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(verificationID: String, isOTPViewPresented: Binding<Bool>, phoneNumber: String, onOTPVerified: @escaping () -> Void,navigateToContent: Binding<Bool>) {
        self._verificationID = State(initialValue: verificationID)
        self._isOTPViewPresented = isOTPViewPresented
        self.phoneNumber = phoneNumber
        self.onOTPVerified = onOTPVerified
        self._navigateToContent = navigateToContent 
    }

    var body: some View {
        VStack {
            Spacer()
            Spacer()

            GIFView(gifName: "otpgif")
                .frame(height: 100)
                .padding()
                .offset(y: -25)

            Spacer()
            Spacer()

            HStack {
                Text("OTP has been sent to: \(phoneNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.trailing, 8)
                    .underline()
                Button(action: {
                    isOTPViewPresented = false
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding()
            .offset(y: -20)

            TextField("Enter OTP", text: $otp)
                .keyboardType(.numberPad)
                .focused($isOTPFieldFocused)
                .onChange(of: otp) { newValue in
                    otp = String(newValue.prefix(6).filter { $0.isNumber })
                    if otp.count == 6 {
                        autoVerifyOTP()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                .padding(.horizontal)
                .onTapGesture {
                    isOTPFieldFocused = true
                }
                .foregroundColor(.black)
                .onChange(of: isOTPFieldFocused) { isFocused in
                    if isFocused {
                        scrollViewProxy?.scrollTo(otp, anchor: .bottom)
                    }
                }
                .offset(y: -35)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            errorMessage = ""
                        }
                    }
            }

            Button(action: {
                verifyOTP()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                } else {
                    Text("Verify")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                        .offset(y: -35)
                }
            }
            .disabled(isLoading || otp.isEmpty)
            .padding(.top)

            Spacer()

            Button(action: {
                resendOTP()
            }) {
                if isResendButtonEnabled {
                    Text("Didn't receive the OTP? Resend")
                        .font(.footnote)
                        .foregroundColor(.white)
                } else {
                    Text("Resend in \(remainingTime) seconds")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .disabled(!isResendButtonEnabled || isLoading)

            Spacer()
            .preferredColorScheme(.light)
        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            otp = ""
            startTimer()

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if isOTPFieldFocused {
                    adjustViewForKeyboard(notification: notification)
                }
            }

            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation {
                    scrollViewProxy?.scrollTo(otp, anchor: .bottom)
                }
            }
        }
        .onReceive(timer) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                isResendButtonEnabled = true
                timer.upstream.connect().cancel()
            }
        }
        .navigationDestination(isPresented: $navigateToContent) {
            ContentView(appState: AppState())
                .navigationBarBackButtonHidden(true)
        }
    }

    private func startTimer() {
        isResendButtonEnabled = false
        remainingTime = 60
    }

    private func autoVerifyOTP() {
        guard otp.count == 6 else { return }
        verifyOTP()
    }

    private func verifyOTP() {
        guard !otp.isEmpty else {
            errorMessage = "Please enter the OTP."
            return
        }
        guard !verificationID.isEmpty else {
            errorMessage = "Verification ID is missing. Please try resending the OTP."
            return
        }
        isLoading = true
        errorMessage = ""
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error verifying OTP: \(error.localizedDescription)"
                    return
                }
                print("User signed in successfully.")
                onOTPVerified()
//               
            }
        }
    }

    private func resendOTP() {
        isLoading = true
        errorMessage = ""
        startTimer()
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("Error during phone number verification: \(error.localizedDescription)")
                return
            }
            if let verificationID = verificationID {
                DispatchQueue.main.async {
                    self.verificationID = verificationID
                }
            }
        }
    }


   
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

   
    private func adjustViewForKeyboard(notification: Notification) {
        if let userInfo = notification.userInfo, let _ = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            withAnimation {
                scrollViewProxy?.scrollTo(otp, anchor: .bottom)
            }
        }
    }
}


#Preview {
    OTPView(
        verificationID: "fakeVerificationID123",
        isOTPViewPresented: .constant(true),
        phoneNumber: "9284272940",
        onOTPVerified: {
            print("OTP Verified!")
        },
        navigateToContent: .constant(false)
        
    )
}
