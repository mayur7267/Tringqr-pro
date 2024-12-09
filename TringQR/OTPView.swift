//
//  OTPView.swift
//  TringQR
//
//  Created by Mayur on 01/12/24.
//

import SwiftUI
import FirebaseAuth

struct OTPView: View {
    @State var otp: String = ""
    @State var isLoading: Bool = false
    @State var errorMessage: String = ""
    @State var verificationID: String
    
    @Binding var isOTPViewPresented: Bool

    var phoneNumber: String
    var onOTPVerified: () -> Void

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
                .padding()
                .background(Color.white)
                .cornerRadius(5)
                .padding(.horizontal)

            // Error Message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
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

            Spacer()
        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.black], startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }

    // MARK: - Verify OTP Logic
    private func verifyOTP() {
        guard !otp.isEmpty else {
            errorMessage = "Please enter the OTP."
            return
        }

        isLoading = true
        errorMessage = ""

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)

        Auth.auth().signIn(with: credential) { authResult, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error verifying OTP: \(error.localizedDescription)"
                return
            }

            
            onOTPVerified()
        }
    }

    // MARK: - Resend OTP Logic
    private func resendOTP() {
        isLoading = true
        errorMessage = ""

        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { newVerificationID, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error resending OTP: \(error.localizedDescription)"
                return
            }

            if let newVerificationID = newVerificationID {
                verificationID = newVerificationID
                errorMessage = "A new OTP has been sent to \(phoneNumber)."
            }
        }
    }
}

#Preview {
    OTPView(
        verificationID: "fakeVerificationID123",
        isOTPViewPresented: .constant(true),     // Place this second
        phoneNumber: "9284272940",               // Then phoneNumber
        onOTPVerified: {                         // Callback function comes last
            print("OTP Verified!")
        }
    )
}
