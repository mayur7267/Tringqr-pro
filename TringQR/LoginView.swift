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
struct Country: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
}

// Sample country data
let countries = [
        Country(name: "India", code: "+91", flag: "🇮🇳"),
        Country(name: "United States", code: "+1", flag: "🇺🇸"),
        Country(name: "United Kingdom", code: "+44", flag: "🇬🇧"),
        Country(name: "Canada", code: "+1", flag: "🇨🇦"),
        Country(name: "Australia", code: "+61", flag: "🇦🇺"),
        Country(name: "Canada", code: "+1", flag: "🇨🇦"),
        Country(name: "Mexico", code: "+52", flag: "🇲🇽"),
        Country(name: "Brazil", code: "+55", flag: "🇧🇷"),
        Country(name: "Argentina", code: "+54", flag: "🇦🇷"),
        Country(name: "France", code: "+33", flag: "🇫🇷"),
        Country(name: "Italy", code: "+39", flag: "🇮🇹"),
        Country(name: "Spain", code: "+34", flag: "🇪🇸"),
        Country(name: "Russia", code: "+7", flag: "🇷🇺"),
        Country(name: "China", code: "+86", flag: "🇨🇳"),
        Country(name: "Japan", code: "+81", flag: "🇯🇵"),
        Country(name: "South Korea", code: "+82", flag: "🇰🇷"),
        Country(name: "South Africa", code: "+27", flag: "🇿🇦"),
        Country(name: "Nigeria", code: "+234", flag: "🇳🇬"),
        Country(name: "Egypt", code: "+20", flag: "🇪🇬"),
        Country(name: "Turkey", code: "+90", flag: "🇹🇷"),
        Country(name: "Saudi Arabia", code: "+966", flag: "🇸🇦"),
        Country(name: "United Arab Emirates", code: "+971", flag: "🇦🇪"),
        Country(name: "Israel", code: "+972", flag: "🇮🇱"),
        Country(name: "Pakistan", code: "+92", flag: "🇵🇰"),
        Country(name: "Bangladesh", code: "+880", flag: "🇧🇩"),
        Country(name: "Sri Lanka", code: "+94", flag: "🇱🇰"),
        Country(name: "Nepal", code: "+977", flag: "🇳🇵"),
        Country(name: "Malaysia", code: "+60", flag: "🇲🇾"),
        Country(name: "Indonesia", code: "+62", flag: "🇮🇩"),
        Country(name: "Thailand", code: "+66", flag: "🇹🇭"),
        Country(name: "Vietnam", code: "+84", flag: "🇻🇳"),
        Country(name: "Philippines", code: "+63", flag: "🇵🇭"),
        Country(name: "Singapore", code: "+65", flag: "🇸🇬"),
        Country(name: "New Zealand", code: "+64", flag: "🇳🇿"),
        Country(name: "Sweden", code: "+46", flag: "🇸🇪"),
        Country(name: "Norway", code: "+47", flag: "🇳🇴"),
        Country(name: "Denmark", code: "+45", flag: "🇩🇰"),
        Country(name: "Finland", code: "+358", flag: "🇫🇮"),
        Country(name: "Iceland", code: "+354", flag: "🇮🇸"),
        Country(name: "Poland", code: "+48", flag: "🇵🇱"),
        Country(name: "Austria", code: "+43", flag: "🇦🇹"),
        Country(name: "Switzerland", code: "+41", flag: "🇨🇭"),
        Country(name: "Belgium", code: "+32", flag: "🇧🇪"),
        Country(name: "Netherlands", code: "+31", flag: "🇳🇱"),
        Country(name: "Ireland", code: "+353", flag: "🇮🇪"),
        Country(name: "Portugal", code: "+351", flag: "🇵🇹"),
        Country(name: "Greece", code: "+30", flag: "🇬🇷"),
        Country(name: "Czech Republic", code: "+420", flag: "🇨🇿"),
        Country(name: "Hungary", code: "+36", flag: "🇭🇺"),
        Country(name: "Romania", code: "+40", flag: "🇷🇴"),
        Country(name: "Bulgaria", code: "+359", flag: "🇧🇬"),
        Country(name: "Slovakia", code: "+421", flag: "🇸🇰"),
        Country(name: "Slovenia", code: "+386", flag: "🇸🇮"),
        Country(name: "Croatia", code: "+385", flag: "🇭🇷"),
        Country(name: "Serbia", code: "+381", flag: "🇷🇸"),
        Country(name: "Montenegro", code: "+382", flag: "🇲🇪"),
        Country(name: "Bosnia and Herzegovina", code: "+387", flag: "🇧🇦"),
        Country(name: "Albania", code: "+355", flag: "🇦🇱"),
        Country(name: "North Macedonia", code: "+389", flag: "🇲🇰"),
        Country(name: "Kosovo", code: "+383", flag: "🇽🇰"),
        Country(name: "Georgia", code: "+995", flag: "🇬🇪"),
        Country(name: "Armenia", code: "+374", flag: "🇦🇲"),
        Country(name: "Azerbaijan", code: "+994", flag: "🇦🇿"),
        Country(name: "Kazakhstan", code: "+7", flag: "🇰🇿"),
        Country(name: "Uzbekistan", code: "+998", flag: "🇺🇿")
]

// MARK: - Login View
struct LoginView: View {
    @State private var selectedCountry: Country = countries.first!
    @State private var phoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var isOTPViewPresented: Bool = false
    @State private var verificationID: String = ""
    @State private var isCountryPickerPresented: Bool = false
    @ObservedObject private var keyboardObserver = KeyboardObserver()

    var onLoginSuccess: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background GIF
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
                            Button(action: {
                                isCountryPickerPresented = true
                            }) {
                                HStack {
                                    Text(selectedCountry.flag)
                                        .font(.system(size: 20))
                                    Text(selectedCountry.code)
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                }
                                .frame(width: 80, height: 50)
                                .background(Color.white)
                                .cornerRadius(5)
                            }
                            
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
        .sheet(isPresented: $isCountryPickerPresented) {
            CountryPicker(selectedCountry: $selectedCountry)
        }
        .sheet(isPresented: $isOTPViewPresented) {
            OTPView(
                verificationID: verificationID,
                isOTPViewPresented: $isOTPViewPresented,
                phoneNumber: selectedCountry.code + phoneNumber,
                onOTPVerified: {
                    onLoginSuccess()
                }
            )
        }
    }

    func sendOTP() {
        let formattedNumber = selectedCountry.code + phoneNumber.trimmingCharacters(in: .whitespaces)

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
struct CountryPicker: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(countries) { country in
                Button(action: {
                    selectedCountry = country
                    dismiss()
                }) {
                    HStack {
                        Text(country.flag)
                            .font(.system(size: 20))
                        Text(country.name)
                        Spacer()
                        Text(country.code)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView {
        print("Login Successful!")
    }
}
