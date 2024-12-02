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
    @Binding var isOTPViewPresented: Bool // To dismiss the OTP view
    
    var verificationID: String
    var onOTPVerified: () -> Void // Closure to notify parent view on success
    
    var body: some View {
        VStack {
            Spacer()
            
            // App Title
            Text("TringQR")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Enter the OTP sent to your phone number")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 5)
            
            Spacer()
            
            // OTP Input Section
            VStack(alignment: .leading) {
                Text("Enter OTP")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter OTP", text: $otp)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(5)
                
                Button(action: {
                    verifyOTP()
                }) {
                    Text("Verify OTP")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
                .padding(.top)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            .padding()
            
            Spacer()
            
            // Dismiss Button
            Button(action: {
                isOTPViewPresented = false // Dismiss the OTP view
            }) {
                Text("Cancel")
                    .font(.footnote)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
    }
    
    private func verifyOTP() {
        guard !otp.isEmpty else {
            errorMessage = "Please enter the OTP."
            return
        }
        
        isLoading = true
        
        // Create a credential using the verificationID and OTP
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otp)
        
        // Sign in with the credential
        Auth.auth().signIn(with: credential) { authResult, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error verifying OTP: \(error.localizedDescription)"
                return
            }
            
            
            onOTPVerified()
        }
    }
}


#Preview {
    OTPView(
        isOTPViewPresented: .constant(true), verificationID: "fakeVerificationID123",
        onOTPVerified: {
            print("OTP Verified!")
        }
    )
}

