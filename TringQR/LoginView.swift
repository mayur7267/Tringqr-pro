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
//class APIManager {
//    static let shared = APIManager()
//
//    func makeRequest(endpoint: String, method: String, parameters: [String: Any]? = nil, headers: [String: String]? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
//        guard let url = URL(string: endpoint) else {
//            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//
//        if let headers = headers {
//            for (key, value) in headers {
//                request.setValue(value, forHTTPHeaderField: key)
//            }
//        }
//
//        if let parameters = parameters {
//            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
//        }
//
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
//                return
//            }
//
//            completion(.success(data))
//        }.resume()
//    }
//}

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
    Country(name: "Albania", code: "+355", flag: "🇦🇱"),
        Country(name: "Algeria", code: "+213", flag: "🇩🇿"),
        Country(name: "Angola", code: "+244", flag: "🇦🇴"),
        Country(name: "Argentina", code: "+54", flag: "🇦🇷"),
        Country(name: "Armenia", code: "+374", flag: "🇦🇲"),
        Country(name: "Australia", code: "+61", flag: "🇦🇺"),
        Country(name: "Austria", code: "+43", flag: "🇦🇹"),
        Country(name: "Azerbaijan", code: "+994", flag: "🇦🇿"),
        Country(name: "Bahrain", code: "+973", flag: "🇧🇭"),
        Country(name: "Bangladesh", code: "+880", flag: "🇧🇩"),
        Country(name: "Belgium", code: "+32", flag: "🇧🇪"),
        Country(name: "Bolivia", code: "+591", flag: "🇧🇴"),
        Country(name: "Bosnia and Herzegovina", code: "+387", flag: "🇧🇦"),
        Country(name: "Brazil", code: "+55", flag: "🇧🇷"),
        Country(name: "Bulgaria", code: "+359", flag: "🇧🇬"),
        Country(name: "Cambodia", code: "+855", flag: "🇰🇭"),
        Country(name: "Canada", code: "+1", flag: "🇨🇦"),
        Country(name: "Chile", code: "+56", flag: "🇨🇱"),
        Country(name: "China", code: "+86", flag: "🇨🇳"),
        Country(name: "Colombia", code: "+57", flag: "🇨🇴"),
        Country(name: "Costa Rica", code: "+506", flag: "🇨🇷"),
        Country(name: "Croatia", code: "+385", flag: "🇭🇷"),
        Country(name: "Czech Republic", code: "+420", flag: "🇨🇿"),
        Country(name: "Denmark", code: "+45", flag: "🇩🇰"),
        Country(name: "Dominican Republic", code: "+1-809", flag: "🇩🇴"),
        Country(name: "Ecuador", code: "+593", flag: "🇪🇨"),
        Country(name: "Egypt", code: "+20", flag: "🇪🇬"),
        Country(name: "El Salvador", code: "+503", flag: "🇸🇻"),
        Country(name: "Estonia", code: "+372", flag: "🇪🇪"),
        Country(name: "Finland", code: "+358", flag: "🇫🇮"),
        Country(name: "France", code: "+33", flag: "🇫🇷"),
        Country(name: "Georgia", code: "+995", flag: "🇬🇪"),
        Country(name: "Germany", code: "+49", flag: "🇩🇪"),
        Country(name: "Ghana", code: "+233", flag: "🇬🇭"),
        Country(name: "Greece", code: "+30", flag: "🇬🇷"),
        Country(name: "Guatemala", code: "+502", flag: "🇬🇹"),
        Country(name: "Honduras", code: "+504", flag: "🇭🇳"),
        Country(name: "Hungary", code: "+36", flag: "🇭🇺"),
        Country(name: "Iceland", code: "+354", flag: "🇮🇸"),
    
        Country(name: "Indonesia", code: "+62", flag: "🇮🇩"),
        Country(name: "Ireland", code: "+353", flag: "🇮🇪"),
        Country(name: "Israel", code: "+972", flag: "🇮🇱"),
        Country(name: "Italy", code: "+39", flag: "🇮🇹"),
        Country(name: "Jamaica", code: "+1-876", flag: "🇯🇲"),
        Country(name: "Japan", code: "+81", flag: "🇯🇵"),
        Country(name: "Kazakhstan", code: "+7", flag: "🇰🇿"),
        Country(name: "Kenya", code: "+254", flag: "🇰🇪"),
        Country(name: "Kosovo", code: "+383", flag: "🇽🇰"),
        Country(name: "Kuwait", code: "+965", flag: "🇰🇼"),
        Country(name: "Latvia", code: "+371", flag: "🇱🇻"),
        Country(name: "Lebanon", code: "+961", flag: "🇱🇧"),
        Country(name: "Lithuania", code: "+370", flag: "🇱🇹"),
        Country(name: "Luxembourg", code: "+352", flag: "🇱🇺"),
        Country(name: "Malaysia", code: "+60", flag: "🇲🇾"),
        Country(name: "Mexico", code: "+52", flag: "🇲🇽"),
        Country(name: "Montenegro", code: "+382", flag: "🇲🇪"),
        Country(name: "Morocco", code: "+212", flag: "🇲🇦"),
        Country(name: "Netherlands", code: "+31", flag: "🇳🇱"),
        Country(name: "New Zealand", code: "+64", flag: "🇳🇿"),
        Country(name: "Nicaragua", code: "+505", flag: "🇳🇮"),
        Country(name: "Nigeria", code: "+234", flag: "🇳🇬"),
        Country(name: "North Macedonia", code: "+389", flag: "🇲🇰"),
        Country(name: "Norway", code: "+47", flag: "🇳🇴"),
        Country(name: "Pakistan", code: "+92", flag: "🇵🇰"),
        Country(name: "Panama", code: "+507", flag: "🇵🇦"),
        Country(name: "Peru", code: "+51", flag: "🇵🇪"),
        Country(name: "Philippines", code: "+63", flag: "🇵🇭"),
        Country(name: "Poland", code: "+48", flag: "🇵🇱"),
        Country(name: "Portugal", code: "+351", flag: "🇵🇹"),
        Country(name: "Puerto Rico", code: "+1-787", flag: "🇵🇷"),
        Country(name: "Qatar", code: "+974", flag: "🇶🇦"),
        Country(name: "Romania", code: "+40", flag: "🇷🇴"),
        Country(name: "Russia", code: "+7", flag: "🇷🇺"),
        Country(name: "Rwanda", code: "+250", flag: "🇷🇼"),
        Country(name: "Saudi Arabia", code: "+966", flag: "🇸🇦"),
        Country(name: "Senegal", code: "+221", flag: "🇸🇳"),
        Country(name: "Serbia", code: "+381", flag: "🇷🇸"),
        Country(name: "Singapore", code: "+65", flag: "🇸🇬"),
        Country(name: "Slovakia", code: "+421", flag: "🇸🇰"),
        Country(name: "Slovenia", code: "+386", flag: "🇸🇮"),
        Country(name: "South Africa", code: "+27", flag: "🇿🇦"),
        Country(name: "South Korea", code: "+82", flag: "🇰🇷"),
        Country(name: "Spain", code: "+34", flag: "🇪🇸"),
        Country(name: "Sri Lanka", code: "+94", flag: "🇱🇰"),
        Country(name: "Sweden", code: "+46", flag: "🇸🇪"),
        Country(name: "Switzerland", code: "+41", flag: "🇨🇭"),
        Country(name: "Tanzania", code: "+255", flag: "🇹🇿"),
        Country(name: "Thailand", code: "+66", flag: "🇹🇭"),
        Country(name: "Tunisia", code: "+216", flag: "🇹🇳"),
        Country(name: "Turkey", code: "+90", flag: "🇹🇷"),
        Country(name: "Uganda", code: "+256", flag: "🇺🇬"),
        Country(name: "United Arab Emirates", code: "+971", flag: "🇦🇪"),
        Country(name: "United Kingdom", code: "+44", flag: "🇬🇧"),
        Country(name: "United States", code: "+1", flag: "🇺🇸"),
        Country(name: "Uruguay", code: "+598", flag: "🇺🇾"),
        Country(name: "Uzbekistan", code: "+998", flag: "🇺🇿"),
        Country(name: "Venezuela", code: "+58", flag: "🇻🇪"),
        Country(name: "Vietnam", code: "+84", flag: "🇻🇳"),
        Country(name: "Zimbabwe", code: "+263", flag: "🇿🇼")
]
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Login View
struct LoginView: View {
    @State private var selectedCountry: Country = countries.first ?? Country(name: "India", code: "+91", flag: "🇮🇳")
    @State private var phoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var isOTPViewPresented: Bool = false
    @State private var verificationID: String = ""
    @State private var isCountryPickerPresented: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @ObservedObject private var keyboardObserver = KeyboardObserver()

    var onLoginSuccess: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                GIFView(gifName: "background2")
                    .ignoresSafeArea()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            DispatchQueue.main.async {
                                onLoginSuccess()
                            }
                            
                        }label: {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.yellow)
                                .cornerRadius(25)
                                .padding(.vertical, 40)
                        }
                        .padding(.trailing, 30)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 5) {
                        Text("TringQR")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("World's fastest QR Code scanner")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("Sign in with phone number")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        } else {
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
                        }

                        Text("or continue with")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
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
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
            }
            .ignoresSafeArea()
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
                    self.errorMessage = "Error sending OTP: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    return
                }
                guard let id = id else {
                    self.errorMessage = "Verification ID is nil."
                    self.showErrorAlert = true
                    return
                }
                self.verificationID = id
                self.isOTPViewPresented = true
            }
        }
    }

    func registerUser() {
        // Create a request object with the JSON data
        let request = RegisterUserRequest(
            first_name: "Tring",
            last_name: "Box",
            dob: "2024-08-01",
            gender: "Male",
            type: "User",
            email: "support@tringbox.com",
            display_name: "Tringbox",
            phone_number: "+15146430901",
            notificationId: "802a6eea-1ae2-4254-85fa-fd4b877c2dc3",
            deviceId: "sampleDevice1"
        )

        // Replace "your_bearer_token_here" and "your_id_token_here" with actual values
        let bearerToken = "your_bearer_token_here"
        let idToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFhYWMyNzEwOTkwNDljMGRmYzA1OGUwNjEyZjA4ZDA2YzMwYTA0MTUiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcHJqLW0tdHJpbmdxci1hcHAiLCJhdWQiOiJwcmotbS10cmluZ3FyLWFwcCIsImF1dGhfdGltZSI6MTczNDQ0MzgzNSwidXNlcl9pZCI6Im9YZ2FYOVlGbTBQRDEzUXJMS0lVQUlCNWJLdDEiLCJzdWIiOiJvWGdhWDlZRm0wUEQxM1FyTEtJVUFJQjViS3QxIiwiaWF0IjoxNzM0NDQzODM1LCJleHAiOjE3MzQ0NDc0MzUsImVtYWlsIjoic3VwcG9ydEB0cmluZ2JveC5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsic3VwcG9ydEB0cmluZ2JveC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9fQ.m9eZctd_xtHC404_HgzLudmh56AaDtUa_22D_P9sKr1_o0J1-hiMB2QenJiLtCNspZXvSr8SFP4oe2IBBISeGiKq5fMv-AGxcONqlW5cvBdpzj7LkaCVtpen4OOU8XTPn8_Po6-bDOfimh7UJVZDhl3qbhGEFD95lKuVZkNVlfrCmGxhsuAaiGBD5dBI4s7uq4Nmo7gRJzDjjpNPOAVJ-NE-WjN6G-9m_ZV-mgp9AhNb8_31K3dPiyA5ieyp0TPpB7LtMDqtV2hvY6JqTKVYKZE04k0Y46ogZBfTtyEkh_7YUzU-RBLdPWIOjhVSeHMoNE6QzZnPNVb9ytexdlYwgw"

        // Call the API
        APIManager.shared.registerUser(request: request, token: bearerToken, idToken: idToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("User registered successfully: \(response)")
                case .failure(let error):
                    print("Registration failed: \(error.localizedDescription)")
                }
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
    @State private var searchText = ""

    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return countries
        } else {
            let predicate = NSPredicate(format: "SELF CONTAINS[cd] %@", searchText)
            return countries.filter { country in
                predicate.evaluate(with: country.name)
            }
        }
    }


    init(selectedCountry: Binding<Country>) {
        self._selectedCountry = selectedCountry
    }

    var body: some View {
        NavigationView {
            List(filteredCountries) { country in
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
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Countries")
            .onAppear {
                if selectedCountry.name.isEmpty {
                    selectedCountry = countries.first(where: { $0.name == "India" })!
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
