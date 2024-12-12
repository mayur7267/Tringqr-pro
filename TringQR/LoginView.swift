//
//  LoginView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

// MARK: - Keyboard Observer
class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { notification -> CGFloat? in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let screenHeight = UIScreen.main.bounds.height
                    return frame.origin.y >= screenHeight ? 0 : screenHeight - frame.origin.y
                }
                return nil
            }
            .assign(to: \.keyboardHeight, on: self)
    }

    deinit {
        cancellable?.cancel()
    }
}

// MARK: - API Manager
class APIManager {
    static let shared = APIManager()

    func makeRequest(endpoint: String, method: String, parameters: [String: Any]? = nil, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }

            completion(.success(data))
        }.resume()
    }
}

// MARK: - Login View
struct LoginView: View {
    @State private var phoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var isOTPViewPresented: Bool = false
    @State private var verificationID: String = ""
    @ObservedObject private var keyboardObserver = KeyboardObserver()

    var onLoginSuccess: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                GIFView(gifName: "background2")
                    .ignoresSafeArea()

                VStack {
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            onLoginSuccess()
                        }) {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.yellow)
                                .cornerRadius(25)
                        }
                        .padding(.trailing, 30)
                    }

                    Spacer()

                    // App Title
                    VStack(spacing: 5) {
                        Text("TringQR")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("World's fastest QR Code scanner")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Login Section
                    VStack(spacing: 20) {
                        Text("Sign in with phone number")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Phone Number Input
                        HStack(spacing: 0) {
                            ZStack {
                                Color.white
                                Text("+91")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 60, height: 50)
                            .cornerRadius(5)

                            TextField("Enter 10 Digits", text: $phoneNumber)
                                .keyboardType(.numberPad)
                                .padding(.leading, 10)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(5)
                        }

                        // Send OTP Button
                        Button(action: {
                            sendOTP()
                        }) {
                            Text("Send OTP")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .cornerRadius(8)
                        }

                        Text("or continue with")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        // Google Sign-In Button
                        Button(action: {
                            signInWithGoogle()
                        }) {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .medium))
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
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Terms and Privacy
                    VStack(spacing: 2) {
                        Text("By registering, you agree to our")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))

                        Text("Terms of Use & Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    .padding(.bottom, 10)
                }
                .padding(.bottom, keyboardObserver.keyboardHeight)
                .animation(.easeOut(duration: 0.3), value: keyboardObserver.keyboardHeight)
            }
        }
        .sheet(isPresented: $isOTPViewPresented) {
            OTPView(
                verificationID: verificationID, isOTPViewPresented: $isOTPViewPresented,
                phoneNumber: "+91\(phoneNumber)",
                onOTPVerified: {
                    registerUser() // Call BE after OTP
                }
            )
        }
    }

//    func sendOTP() {
//        let phoneNumber = "+91" + self.phoneNumber.trimmingCharacters(in: .whitespaces)
//
//        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
//            if let error = error {
//                print("Error sending OTP: \(error.localizedDescription)")
//                return
//            }
//
//            guard let verificationID = verificationID else {
//                print("Error: verificationID is nil")
//                return
//            }
//
//            print("Verification ID: \(verificationID)")
//            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
//            self.verificationID = verificationID
//            print("OTP sent successfully: \(verificationID)")
//            DispatchQueue.main.async {
//                self.isOTPViewPresented = true
//            }
//        }
//    }
    func sendOTP() {
            let formattedNumber = "+91" + phoneNumber.trimmingCharacters(in: .whitespaces)

            isLoading = true
            PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { id, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        print("Error sending OTP: \(error.localizedDescription)")
                        return
                    }
                    guard let id = id else {
                        print("Error: Verification ID is nil")
                        return
                    }
                    self.verificationID = id
                    self.isOTPViewPresented = true
                }
            }
        }

    private func registerUser() {
        let url = "https://core-api-619357594029.asia-south1.run.app/api/v1/users"
        let headers = ["Authorization": "Bearer \(getToken())"]
        let user: [String: Any] = [
            "first_name": "John",
            "last_name": "Smith",
            "email": "user@example.com",
            "phone_number": "+91\(phoneNumber)",
            "type": "User",
            "gender": "Male",
            "display_name": "User_\(Int.random(in: 1000...9999))",
            "dob": "2000-01-01",
            "avatar_url": "https://example.com/avatar.jpg",
            "referredBy": "",
            "deviceId": "ios123",
            "notificationId": "abcd-1234-5678"
        ]

        APIManager.shared.makeRequest(endpoint: url, method: "POST", parameters: user, headers: headers) { result in
            switch result {
            case .success:
                print("User registered successfully.")
                onLoginSuccess()
            case .failure(let error):
                print("Registration failed: \(error.localizedDescription)")
            }
        }
    }

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config

        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Google Sign-In failed: \(error.localizedDescription)")
                    return
                }

                onLoginSuccess()
            }
        }
    }

    private func getToken() -> String {
        return UserDefaults.standard.string(forKey: "tringboxToken") ?? ""
    }
}
#Preview {
    LoginView {
        print("Login Successful!")
    }
}
