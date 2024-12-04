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
    @Binding var isOTPViewPresented: Bool
    
    var verificationID: String
    var phoneNumber: String 
    var onOTPVerified: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("OTP is sent to: \(phoneNumber)")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            
            TextField("Enter OTP here", text: $otp)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .cornerRadius(5)
            
            Button(action: {
                verifyOTP()
            }) {
                Text("Verify")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
            .padding(.top)
            
            Spacer()
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
}


#Preview {
    OTPView(
        isOTPViewPresented: .constant(true),
        verificationID: "fakeVerificationID123",
        phoneNumber: "9373500779",
        onOTPVerified: {
            print("OTP Verified!")
        }
    )
}
