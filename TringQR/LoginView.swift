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
import FirebaseMessaging
import AVKit
import AuthenticationServices
import CryptoKit
import AppTrackingTransparency


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




struct Country: Identifiable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
}


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




struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCountry: Country = countries.first ?? Country(name: "India", code: "+91", flag: "🇮🇳")
    @State private var phoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var verificationID: String = ""
    @State private var isCountryPickerPresented: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var navigateToOTP: Bool = false
    @State private var navigateToContent: Bool = false
    @State private var isPrivacyPolicyPresented: Bool = false
    
    @State private var currentNonce: String?
    
    @ObservedObject private var keyboardObserver = KeyboardObserver()
    
    var onLoginSuccess: (String) -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isCompactDevice = geometry.size.height < 700
                ZStack {
                    VideoBackgroundView()
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        Spacer()
                        
                        VStack(spacing: isCompactDevice ? 3 : 5) {
                            Text("TringQR")
                                .font(.system(size: isCompactDevice ? 50 : 55, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("World's fastest QR Code scanner")
                                .font(.system(size: isCompactDevice ? 8 : 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: isCompactDevice ? 15 : 20) {
                            Text("Sign in with phone number")
                                .font(.system(size: isCompactDevice ? 14 : 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 0) {
                                Button(action: {
                                    isCountryPickerPresented = true
                                }) {
                                    HStack {
                                        Text(selectedCountry.flag)
                                            .font(.system(size: isCompactDevice ? 18 : 20))
                                        Text(selectedCountry.code)
                                            .font(.system(size: isCompactDevice ? 14 : 16))
                                            .foregroundColor(.black)
                                    }
                                    .frame(width: isCompactDevice ? 70 : 80, height: isCompactDevice ? 45 : 50)
                                    .background(Color.white)
                                    .cornerRadius(5)
                                }
                                
                                TextField("Enter 10 Digits", text: $phoneNumber)
                                    .keyboardType(.numberPad)
                                    .padding(.leading, 10)
                                    .frame(height: isCompactDevice ? 45 : 50)
                                    .foregroundColor(.black)
                                    .background(Color.white)
                                    .cornerRadius(5)
                                    .onChange(of: phoneNumber) { newValue in
                                        phoneNumber = String(newValue.prefix(10))
                                        if phoneNumber.count == 10 {
                                            sendOTP()
                                        }
                                    }
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                self.hideKeyboard()
                                            }
                                        }
                                    }
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                            } else {
                                Button(action: {
                                    sendOTP()
                                }) {
                                    Text("Send OTP")
                                        .font(.system(size: isCompactDevice ? 14 : 16, weight: .medium))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(isCompactDevice ? 12 : 16)
                                        .background(Color.yellow)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Text("or continue with")
                                .font(.system(size: isCompactDevice ? 12 : 14))
                                .foregroundColor(.white.opacity(0.7))
                            
                            appleSignInButton
                                .frame(height: isCompactDevice ? 45 : 50)
                                .cornerRadius(8)
                                
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, isCompactDevice ? 15 : 20)
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("By registering, you agree to our")
                                .font(.system(size: isCompactDevice ? 10 : 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: {
                                isPrivacyPolicyPresented = true
                            }) {
                                Text("Terms of Use & Privacy Policy")
                                    .font(.system(size: isCompactDevice ? 10 : 12))
                                    .foregroundColor(.yellow)
                                    .underline()
                            }
                        }
                        .padding(.bottom, isCompactDevice ? 5 : 10)
                        .offset(y: isCompactDevice ? -10 : -20)
                    }
                    .ignoresSafeArea(.keyboard)
                }
                .ignoresSafeArea()

            }
            .onAppear {
                if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                    appState.requestTrackingPermission()
                            }
                        }
            .navigationDestination(isPresented: $navigateToOTP) {
                OTPView(
                    verificationID: verificationID,
                    isOTPViewPresented: $navigateToOTP,
                    phoneNumber: selectedCountry.code + phoneNumber,
                    onOTPVerified: {[self] in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            registerUser()
                        }
                    },
                    navigateToContent: $navigateToContent
                )
                .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $navigateToContent) {
                ContentView(appState: appState,displayName: appState.userName ?? "Apple User")
                    .navigationBarBackButtonHidden(true)
            }
            .sheet(isPresented: $isCountryPickerPresented) {
                CountryPicker(selectedCountry: $selectedCountry)
            }
            .sheet(isPresented: $isPrivacyPolicyPresented) {
                PrivacyPolicyView(isBackButtonVisible: .constant(false))
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .preferredColorScheme(.light)
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    
    var appleSignInButton: some View {
        SignInWithAppleButton(
            onRequest: { request in
                debugPrint("Apple Sign-In request started")
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            },
            onCompletion: { result in
                debugPrint("Apple Sign-In result received")
                handleAppleSignIn(result)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: 50)
        .cornerRadius(8)
        .padding(.horizontal, 20)
    }

    private func debugPrint(_ message: String) {
           print("DEBUG: \(message)")
       }
       
       private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
           debugPrint("Starting Apple Sign In process")
           switch result {
           case .success(let authorization):
               if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                   guard let nonce = currentNonce else {
                       debugPrint("Invalid state: Missing nonce")
                       return
                   }
                   
                   guard let appleIDToken = appleIDCredential.identityToken else {
                       debugPrint("Missing identity token")
                       return
                   }
                   
                   guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                       debugPrint("Unable to serialize token string")
                       return
                   }
                   
                   let credential = OAuthProvider.credential(
                       withProviderID: "apple.com",
                       idToken: idTokenString,
                       rawNonce: nonce
                   )
                   
                   let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                       .compactMap { $0 }
                       .joined(separator: " ")
                   
                   debugPrint("Starting Firebase authentication")
                   isLoading = true
                   
                   Auth.auth().signIn(with: credential) { authResult, error in
                       if let error = error {
                           debugPrint("Firebase auth error: \(error.localizedDescription)")
                           DispatchQueue.main.async {
                               self.isLoading = false
                               self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                               self.showErrorAlert = true
                           }
                           return
                       }
                       
                       guard let user = authResult?.user else {
                           debugPrint("No user data received")
                           DispatchQueue.main.async {
                               self.isLoading = false
                               self.errorMessage = "Failed to get user data"
                               self.showErrorAlert = true
                           }
                           return
                       }
                       
                       debugPrint("Firebase auth successful for user: \(user.uid)")
                       
                       
                       user.getIDToken { idToken, error in
                           guard let idToken = idToken else {
                               debugPrint("Failed to get ID token: \(error?.localizedDescription ?? "unknown error")")
                               return
                           }
                           
                           DispatchQueue.main.async {
                               self.appState.setAuthToken(idToken)
                               debugPrint("Auth token set in AppState")
                               
                               
                               let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDeviceID"
                               
                               Messaging.messaging().token { fcmToken, error in
                                   let fcmToken = fcmToken ?? ""
                                   
                                   let registerRequest = RegisterUserRequest(
                                       type: "User",
                                       email: user.email ?? "support@tringbox.com",
                                       display_name: displayName.isEmpty ? "Apple User" : displayName,
                                       phone_number: user.phoneNumber ?? "",
                                       notificationId: fcmToken,
                                       deviceId: deviceId
                                   )
                                   
                                   debugPrint("Sending register request")
                                   APIManager.shared.registerUser(request: registerRequest, token: idToken) { result in
                                       DispatchQueue.main.async {
                                           self.isLoading = false
                                           
                                           switch result {
                                           case .success(let response):
                                               debugPrint("User registration successful")
                                               self.onLoginSuccess(displayName.isEmpty ? "Apple User" : displayName)
                                               
                                              
                                               DispatchQueue.main.async {
                                                   debugPrint("Setting navigateToContent to true")
                                                   self.navigateToContent = true
                                               }
                                               
                                           case .failure(let error):
                                               debugPrint("Registration failed: \(error)")
                                               self.errorMessage = "Failed to register user: \(error.localizedDescription)"
                                               self.showErrorAlert = true
                                           }
                                       }
                                   }
                               }
                           }
                       }
                   }
               }
           case .failure(let error):
               debugPrint("Apple Sign In failed: \(error)")
               DispatchQueue.main.async {
                   self.isLoading = false
                   self.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                   self.showErrorAlert = true
               }
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
                self.navigateToOTP = true
            }
        }
    }
    
    func registerUser(displayName: String? = nil) {
        let formattedPhoneNumber = selectedCountry.code + phoneNumber.trimmingCharacters(in: .whitespaces)
        
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is signed in.")
            errorMessage = "No user is signed in"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        currentUser.getIDToken { idToken, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    print("Failed to fetch ID token: \(error.localizedDescription)")
                    errorMessage = "Failed to fetch authentication token"
                    showErrorAlert = true
                }
                return
            }
            
            guard let idToken = idToken else {
                DispatchQueue.main.async {
                    isLoading = false
                    print("ID token is nil.")
                    errorMessage = "Authentication token is missing"
                    showErrorAlert = true
                }
                return
            }
            
            
            DispatchQueue.main.async {
                appState.setAuthToken(idToken)
            }
            
            Messaging.messaging().token { fcmToken, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        print("Error fetching FCM token: \(error.localizedDescription)")
                        errorMessage = "Failed to setup notifications"
                        showErrorAlert = true
                    }
                    return
                }
                
                let fcmToken = fcmToken ?? ""
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDeviceID"
                
                let registerRequest = RegisterUserRequest(
                    type: "User",
                    email: "support@tringbox.com",
                    display_name: displayName ?? "Tringbox",
                    phone_number: formattedPhoneNumber,
                    notificationId: fcmToken,
                    deviceId: deviceId
                )
                
                print("Register Request Payload: \(registerRequest)")
                
                APIManager.shared.registerUser(request: registerRequest, token: idToken) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch result {
                        case .success(let response):
                            print("User registered successfully: \(response)")
                            onLoginSuccess(displayName ?? formattedPhoneNumber)
                            navigateToContent = true
                        case .failure(let error):
                            print("Error during user registration: \(error.localizedDescription)")
                            errorMessage = "Failed to register user. Please try again."
                            showErrorAlert = true
                        }
                    }
                }
            }
        }
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
struct PrivacyPolicyView: View {
    @Binding var isBackButtonVisible: Bool

    var body: some View {
        ZStack {
            Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
                .edgesIgnoringSafeArea(.all)
            WebView(urlString: "https://cdn-tringbox-photos.s3.ap-south-1.amazonaws.com/privacy-policy.html")
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            isBackButtonVisible = true
        }
        .navigationBarHidden(true)
    }
}
struct VideoBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        
        guard let path = Bundle.main.path(forResource: "logback", ofType: "mp4") else {
            fatalError("Video file not found.")
        }
        let videoURL = URL(fileURLWithPath: path)
        
        
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(playerLayer)
        
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        player.isMuted = true
        player.play()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
struct Preview_loginview: PreviewProvider {
    static var previews: some View {
        LoginView {_ in 
            print("Login Successful!")
        }
        .previewDevice("iPhone SE (3rd generation)")
    }
}

