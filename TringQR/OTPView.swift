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
    var phoneNumber: String
    var onOTPVerified: () -> Void

    @FocusState private var isOTPFieldFocused: Bool
    @State private var scrollViewProxy: ScrollViewProxy?

    init(verificationID: String, isOTPViewPresented: Binding<Bool>, phoneNumber: String, onOTPVerified: @escaping () -> Void) {
        self._verificationID = State(initialValue: verificationID)
        self._isOTPViewPresented = isOTPViewPresented
        self.phoneNumber = phoneNumber
        self.onOTPVerified = onOTPVerified
    }

    var body: some View {
        VStack {
            Spacer()
            Spacer()
           
            GIFView(gifName: "otpgif")
                .frame(height: 100)
                .padding()

            Spacer()
            Spacer()

            // OTP Sent Message
            Text("OTP has been sent to \(phoneNumber)")
                .font(.headline)
                .foregroundColor(.white)
                .padding()

            // OTP Input Field
            TextField("Enter OTP", text: $otp)
                .keyboardType(.numberPad)
                .focused($isOTPFieldFocused)
                .onChange(of: otp) { newValue in
                    otp = String(newValue.prefix(6).filter { $0.isNumber })
                }
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                .padding(.horizontal)
                .onTapGesture {
                    isOTPFieldFocused = true
                }
                .onChange(of: isOTPFieldFocused) { isFocused in
                    if isFocused {
                        scrollViewProxy?.scrollTo(otp, anchor: .bottom)
                    }
                }

            // Error Message
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

            // Verify Button
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
                }
            }
            .disabled(isLoading || otp.isEmpty)
            .padding(.top)

            Spacer()

            // Resend OTP Button
            Button(action: {
                resendOTP()
            }) {
                Text("Didn't receive the OTP? Resend")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.top)
            }
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
           
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
    }

    // MARK: - Verify OTP Logic
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
            }
        }
    }


    // MARK: - Resend OTP Logic
    private func resendOTP() {
        isLoading = true
        errorMessage = ""
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("Error during phone number verification: \(error.localizedDescription)")
                return
            }
            if let verificationID = verificationID {
                DispatchQueue.main.async {
                    self.isOTPViewPresented = true
                    self.verificationID = verificationID
                }
            }
        }
        
    }

    // MARK: - Hide Keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Adjust view for keyboard
    private func adjustViewForKeyboard(notification: Notification) {
        if let userInfo = notification.userInfo, let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
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
        }
    )
}
