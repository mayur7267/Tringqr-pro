//
//  LoginView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct LoginView: View {
    @State private var phoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var navigateToMainPage = false
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Text("TringQR")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("World's fastest QR Code scanner")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 5)
                
                Spacer()

                VStack(alignment: .leading) {
                    Text("Sign in with phone number")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("+91")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(5)
                        
                        TextField("Enter 10 Digits", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(5)
                    }
                    .padding(.vertical)

                    Button(action: {
                        sendOTP()
                    }) {
                        Text("Send OTP")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    Text("or continue with")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 10)
                    
                    Button(action: {
                        signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                            Text("Continue with Google")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding()

                Spacer()
                
                Text("By registering, you agree to our")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    + Text(" Terms of Use & Privacy Policy")
                    .font(.footnote)
                    .foregroundColor(.yellow)

                NavigationLink("", destination: ContentView(), isActive: $navigateToMainPage)
            }
            .padding()
            .background(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()
        }
    }

    func sendOTP() {
        let phoneNumber = "+91" + self.phoneNumber
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("Error sending OTP: \(error.localizedDescription)")
                return
            }
           
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            print("OTP sent successfully.")
        }
    }

    private func signInWithGoogle() {
           guard let clientID = FirebaseApp.app()?.options.clientID else { return }

           let config = GIDConfiguration(clientID: clientID)
           GIDSignIn.sharedInstance.configuration = config

           guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else { return }

           GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
               if let error = error {
                   print("Google Sign-In failed: \(error.localizedDescription)")
                   return
               }

               guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }

               // Authenticate with Firebase
               let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                              accessToken: user.accessToken.tokenString)

               Auth.auth().signIn(with: credential) { authResult, error in
                   if let error = error {
                       print("Firebase Google Sign-In failed: \(error.localizedDescription)")
                       return
                   }

                   
                   navigateToMainPage = true
               }
           }
       }
   
}
#Preview {
    LoginView()
}
