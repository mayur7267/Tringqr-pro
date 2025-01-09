//
//  ContentView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import UIKit
import Combine
import WebKit
import SwiftKeychainWrapper


struct QRHistoryItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let date: Date
    let timestamp: String?
    
    
    var image: UIImage? {
        didSet {
           
        }
    }
    
    enum CodingKeys: CodingKey {
        case id
        case content
        case date
        case timestamp
       
    }
    
    init(content: String, image: UIImage? = nil, timestamp: String? = nil) {
        self.id = UUID()
        self.content = content
        self.image = image
        self.timestamp = timestamp
        
        if let timestamp = timestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let parsedDate = dateFormatter.date(from: timestamp) {
                self.date = parsedDate
            } else {
                print("Invalid timestamp: \(timestamp)")
                self.date = Date.distantPast
            }
        } else {
            print("Missing timestamp for QR item")
            self.date = Date.distantPast
        }
    }
}

struct ScannedHistoryItem: Identifiable, Codable {
    let id: UUID
    let code: String
    let date: Date 
    let eventName: String?
    let event: String?
    let timestamp: String?

    init(code: String, eventName: String? = nil, event: String? = nil, timestamp: String? = nil) {
        self.id = UUID()
        self.code = code
        self.eventName = eventName
        self.event = event
        self.timestamp = timestamp

     
        if let timestamp = timestamp {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            if let parsedDate = dateFormatter.date(from: timestamp) {
                self.date = parsedDate
            } else {
               
                print("Invalid timestamp: \(timestamp)")
                self.date = Date.distantPast
            }
        } else {
            
            print("Missing timestamp for scanned item")
            self.date = Date.distantPast
        }
    }
}

class AppState: ObservableObject {
    @Published var currentUserId: String? {
        didSet {
            UserDefaults.standard.set(currentUserId, forKey: "currentUserId")
        }
    }

    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }

    @Published var userName: String? {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }

    @Published var phoneNumber: String? {
        didSet {
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        }
    }

   

    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
        }
    }

    @Published var isSidebarVisible: Bool {
        didSet {
            UserDefaults.standard.set(isSidebarVisible, forKey: "isSidebarVisible")
        }
    }
  
    @Published var scannedHistory: [ScannedHistoryItem] = []
    @Published var scannedHistorySet: Set<String> = []
    private let lock = DispatchQueue(label: "appStateLock")
    
    @Published var qrHistory: [QRHistoryItem] = []
    @Published var qrHistorySet: Set<String> = []
    

    init() {
        self.currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
        self.isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") == nil || UserDefaults.standard.bool(forKey: "isFirstLaunch")
        self.isSidebarVisible = UserDefaults.standard.bool(forKey: "isSidebarVisible")
        
        restoreHistoryFromBackend()
    }

    func restoreHistoryFromBackend() {
        let deviceId = getDeviceId()
        print("Starting history fetch for deviceId: \(deviceId)")
        
        fetchScanHistory(deviceId: deviceId) { [weak self] history in
            guard let self = self else { return }
            print("Received history response: \(String(describing: history))")

            DispatchQueue.main.async {
                guard let history = history else {
                    print("History is nil")
                    return
                }

                let newItems = history.compactMap { item -> ScannedHistoryItem? in
                    guard let code = item["eventName"] as? String else {
                        print("Failed to extract code from item: \(item)")
                        return nil
                    }
                    let historyItem = ScannedHistoryItem(
                        code: code,
                        eventName: item["eventName"] as? String,
                        event: item["event"] as? String,
                        timestamp: item["updatedAt"] as? String
                    )
                    print("Created history item: \(historyItem)")
                    return historyItem
                }

                print("Processing \(newItems.count) new history items")
                self.scannedHistory = newItems
                self.scannedHistorySet = Set(newItems.map { $0.code })
                print("Updated scannedHistory count: \(self.scannedHistory.count)")
            }
        }
    }


    func addScannedCode(_ code: String, deviceId: String, os: String, event: String, eventName: String, completion: @escaping () -> Void) {
        print("Adding scanned code: \(code)")
        
        let newItem = ScannedHistoryItem(
            code: code,
            eventName: eventName,
            event: event,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

       
        sendToBackend(code: code, deviceId: deviceId, os: os, event: event, eventName: eventName) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                print("Successfully saved to backend")
                
               
                DispatchQueue.main.async {
                    if !self.scannedHistorySet.contains(code) {
                        self.scannedHistorySet.insert(code)
                        self.scannedHistory.insert(newItem, at: 0)
                        print("Added to local history. Current count: \(self.scannedHistory.count)")
                    }
                }
            } else {
                print("Failed to save to backend")
            }
            completion()
        }
    }
    func sendToBackend(code: String, deviceId: String, os: String, event: String, eventName: String, completion: @escaping (Bool) -> Void) {
            guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/users/activity") else {
                print("Invalid URL")
                completion(false)
                return
            }

            let payload: [String: Any] = [
                "code": code,
                "deviceId": deviceId,
                "os": os,
                "event": event,
                "eventName": eventName
            ]

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
                print("Sending payload to backend: \(payload)")
            } catch {
                print("Error encoding JSON: \(error)")
                completion(false)
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending data to backend: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    completion(false)
                    return
                }

                print("Backend response status code: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Backend response data: \(responseString)")
                }

                completion(httpResponse.statusCode == 200 || httpResponse.statusCode == 201)
            }.resume()
        }
    func fetchScanHistory(deviceId: String, completion: @escaping ([[String: Any]]?) -> Void) {
        guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/users/activity/\(deviceId)") else {
            print("Invalid URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
            }

            do {
                
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("Successfully parsed JSON array: \(jsonArray)")
                    completion(jsonArray)
                } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let jsonArray = jsonDict["data"] as? [[String: Any]] {
                    
                    print("Successfully parsed JSON array from 'data' key: \(jsonArray)")
                    completion(jsonArray)
                } else {
                    print("Failed to parse JSON as array or dictionary")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error)")
                print("Raw data: \(data)")
                completion(nil)
            }
        }.resume()
    }
    
    func restoreQRHistoryFromBackend() {
            let deviceId = getDeviceId()
            print("Starting QR history fetch for deviceId: \(deviceId)")
            
            fetchQRHistory(deviceId: deviceId) { [weak self] history in
                guard let self = self else { return }
                print("Received QR history response: \(String(describing: history))")
                
                DispatchQueue.main.async {
                    guard let history = history else {
                        print("QR History is nil")
                        return
                    }
                    
                    let newItems = history.compactMap { item -> QRHistoryItem? in
                        guard let content = item["content"] as? String else {
                            print("Failed to extract content from item: \(item)")
                            return nil
                        }
                        
                        // Generate QR image from content
                        let qrImage = self.generateQRImage(from: content)
                        
                        let historyItem = QRHistoryItem(
                            content: content,
                            image: qrImage,
                            timestamp: item["updatedAt"] as? String
                        )
                        print("Created QR history item: \(historyItem)")
                        return historyItem
                    }
                    
                    print("Processing \(newItems.count) new QR history items")
                    self.qrHistory = newItems
                    self.qrHistorySet = Set(newItems.map { $0.content })
                    print("Updated qrHistory count: \(self.qrHistory.count)")
                }
            }
        }
        
        func addQRCode(_ content: String, image: UIImage, completion: @escaping () -> Void) {
            print("Adding QR code: \(content)")
            
            let deviceId = getDeviceId()
            
            let newItem = QRHistoryItem(
                content: content,
                image: image,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
            
            sendQRToBackend(content: content, deviceId: deviceId) { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    print("Successfully saved QR to backend")
                    
                    DispatchQueue.main.async {
                        if !self.qrHistorySet.contains(content) {
                            self.qrHistorySet.insert(content)
                            self.qrHistory.insert(newItem, at: 0)
                            print("Added to local QR history. Current count: \(self.qrHistory.count)")
                        }
                    }
                } else {
                    print("Failed to save QR to backend")
                }
                completion()
            }
        }
        
        private func sendQRToBackend(content: String, deviceId: String, completion: @escaping (Bool) -> Void) {
            guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/qr/scan/create") else {
                print("Invalid URL")
                completion(false)
                return
            }
            
            let payload: [String: Any] = [
                "content": content,
                "deviceId": deviceId,
                "event": "create qr"
            ]
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
                print("Sending QR payload to backend: \(payload)")
            } catch {
                print("Error encoding JSON: \(error)")
                completion(false)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending QR data to backend: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response type")
                    completion(false)
                    return
                }
                
                print("Backend QR response status code: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Backend QR response data: \(responseString)")
                }
                
                completion(httpResponse.statusCode == 200 || httpResponse.statusCode == 201)
            }.resume()
        }
        
        private func fetchQRHistory(deviceId: String, completion: @escaping ([[String: Any]]?) -> Void) {
            guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/qr/scan/\(deviceId)") else {
                print("Invalid URL")
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    completion(nil)
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw QR response: \(responseString)")
                }
                
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        print("Successfully parsed QR JSON array: \(jsonArray)")
                        completion(jsonArray)
                    } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let jsonArray = jsonDict["data"] as? [[String: Any]] {
                        print("Successfully parsed QR JSON array from 'data' key: \(jsonArray)")
                        completion(jsonArray)
                    } else {
                        print("Failed to parse QR JSON as array or dictionary")
                        completion(nil)
                    }
                } catch {
                    print("QR JSON parsing error: \(error)")
                    print("Raw data: \(data)")
                    completion(nil)
                }
            }.resume()
        }
    
    private func generateQRImage(from content: String) -> UIImage? {
            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            
            let data = Data(content.utf8)
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    return UIImage(cgImage: cgimg)
                }
            }
            return nil
        }
    
    
    func getDeviceId() -> String {
        let keychainKey = "com.app.uniqueDeviceId"
        if let deviceId = KeychainWrapper.standard.string(forKey: keychainKey) {
            return deviceId
        } else {
            let newDeviceId = UUID().uuidString
            KeychainWrapper.standard.set(newDeviceId, forKey: keychainKey)
            return newDeviceId
        }
    }

    func toggleLogin() {
        isLoggedIn.toggle()
    }

    func setCurrentUserId(_ id: String?) {
        currentUserId = id
    }

    func setUserName(_ name: String) {
        userName = name
    }

    func setPhoneNumber(_ number: String?) {
        phoneNumber = number
    }

    func signOut() {
        isLoggedIn = false
        userName = ""
        phoneNumber = nil
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
    }

    func completeFirstLaunch() {
        isFirstLaunch = false
    }

    func toggleSidebar() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                self.isSidebarVisible.toggle()
            }
        }
    }
}


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 1
    @State private var isBackButtonVisible = false
    @State private var showLoginView: Bool = false
    @State private var showShareSheet = false
    @State private var dragOffset = CGSize.zero
    @Environment(\.scenePhase) private var scenePhase
    
    init(appState: AppState) {
        _showLoginView = State(initialValue: !appState.isLoggedIn && appState.isFirstLaunch)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
                        .ignoresSafeArea()
                    
                    if showLoginView {
                        LoginView(onLoginSuccess: { displayName in
                            if displayName.isEmpty {
                                appState.isLoggedIn = false
                                appState.setUserName("")
                            } else {
                                appState.isLoggedIn = true
                                appState.setUserName(displayName)
                            }
                            showLoginView = false
                            appState.completeFirstLaunch()
                        })
                        .transition(.move(edge: .leading))
                    } else {
                        ZStack(alignment: .leading) {
                            if selectedTab != 0 && selectedTab != 3 && selectedTab != 4 {
                                GIFView(gifName: "main")
                                    .ignoresSafeArea(edges: .all)
                            }
                            
                            VStack(spacing: 0) {
                                if selectedTab != 4 {
                                    HStack(alignment: .center) {
                                        if isBackButtonVisible {
                                            Button(action: {
                                                withAnimation {
                                                    selectedTab = 1
                                                    isBackButtonVisible = false
                                                }
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "chevron.left")
                                                        .foregroundColor(.black)
                                                        .imageScale(.medium)
                                                    Text("Back")
                                                        .foregroundColor(.black)
                                                        .font(.subheadline)
                                                }
                                            }
                                        } else {
                                            Button(action: {
                                                print("Hamburger tapped! Sidebar visibility: \(appState.isSidebarVisible)")
                                                appState.toggleSidebar()
                                            }) {
                                                Image(systemName: "line.3.horizontal")
                                                    .bold()
                                                    .foregroundColor(.black)
                                                    .imageScale(.large)
                                                    .contentShape(Rectangle())
                                                    .frame(width: adaptiveButtonSize(for: geometry), height: adaptiveButtonSize(for: geometry))
                                                    .background(Color.clear)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        
                                        Spacer()
                                        
                                        Text(selectedTab == 0 ? "Scan History" : "TringQR")
                                            .foregroundColor(.black)
                                            .font(.system(size: adaptiveFontSize(for: geometry)))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .offset(x: isBackButtonVisible ? 0 : -20)
                                        
                                        Spacer()
                                    }
                                    .frame(height: adaptiveHeaderHeight(for: geometry))
                                    .padding(.horizontal, adaptiveHorizontalPadding(for: geometry))
                                    .background(Color.white)
                                    .padding(.vertical, adaptiveVerticalPadding(for: geometry))
                                    .offset(y: 0)
                                    .zIndex(2)
                                }
                                
                                Group {
                                    switch selectedTab {
                                    case 0:
                                        HistoryView()
                                            .environmentObject(appState)
                                    case 1:
                                        ScannerView()
                                            .environmentObject(appState)
                                    case 2:
                                        ShareView(isBackButtonVisible: $isBackButtonVisible)
                                    case 3:
                                        HelpView(isBackButtonVisible: $isBackButtonVisible)
                                    case 4:
                                        CreateQRView(selectedTab: $selectedTab,isBackButtonVisible: $isBackButtonVisible)
                                            .transition(.move(edge: .trailing))
                                            .ignoresSafeArea()
                                    default:
                                        Text("Unknown View")
                                    }
                                }
                            }
                            
                            if appState.isSidebarVisible {
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            appState.toggleSidebar()
                                        }
                                    }
                                    .transition(.opacity)
                                
                                HStack(spacing: 0) {
                                    SidebarView(
                                        isSidebarVisible: $appState.isSidebarVisible,
                                        selectedTab: $selectedTab,
                                        isBackButtonVisible: $isBackButtonVisible,
                                        showShareSheet: $showShareSheet,
                                        showLoginView: $showLoginView
                                    )
                                    .frame(width: geometry.size.width * adaptiveSidebarWidth(for: geometry))
                                    .background(Color.white)
                                    .edgesIgnoringSafeArea(.bottom)
                                    .offset(x: appState.isSidebarVisible ? 0 + dragOffset.width : -geometry.size.width * adaptiveSidebarWidth(for: geometry) + dragOffset.width)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                if !appState.isSidebarVisible {
                                                    dragOffset.width = max(gesture.translation.width, 0)
                                                } else {
                                                    dragOffset.width = min(gesture.translation.width, 0)
                                                }
                                            }
                                            .onEnded { gesture in
                                                let threshold = geometry.size.width * 0.25
                                                if dragOffset.width > threshold {
                                                    withAnimation {
                                                        appState.isSidebarVisible = true
                                                    }
                                                } else if dragOffset.width < -threshold {
                                                    withAnimation {
                                                        appState.isSidebarVisible = false
                                                    }
                                                }
                                                dragOffset = .zero
                                            }
                                    )
                                    .transition(.move(edge: .leading))
                                    .zIndex(4)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .environmentObject(appState)
            .ignoresSafeArea(edges: .all)
            .sheet(isPresented: $showShareSheet) {
                let shareText = "Check out this amazing app!"
                let shareURL = URL(string: "https://example.com")!
                ShareSheet(items: [shareText, shareURL])
            }
        }
        .onAppear {
            withAnimation(.easeInOut) {
                appState.isSidebarVisible = false
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if (newPhase == .inactive || newPhase == .background) && appState.isSidebarVisible {
                print("App moved to background. Hiding sidebar.")
                withAnimation {
                    appState.isSidebarVisible = false
                }
            }
        }
    }
}
private func adaptiveHeaderHeight(for geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        if screenHeight <= 667 {
            return 40
        } else if screenHeight <= 812 {
            return 44
        } else {
            return 44
        }
    }

private func adaptiveFontSize(for geometry: GeometryProxy) -> CGFloat {
       let screenWidth = geometry.size.width
       if screenWidth <= 375 {
           return 16
       } else if screenWidth <= 428 {
           return 17
       } else {
           return 17
       }
   }
private func adaptiveHorizontalPadding(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        if screenWidth <= 375 { 
            return 10
        } else {
            return 12
        }
    }
private func adaptiveVerticalPadding(for geometry: GeometryProxy) -> CGFloat {
    let screenHeight = geometry.size.height
    let device = UIDevice.current
    let hasNotch = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0 > 20
    
    if screenHeight <= 667 { // iPhone SE, 7, 8
        return hasNotch ? 30 : 15
    } else if screenHeight <= 812 { // iPhone X, 11 Pro, 12 mini
        return hasNotch ? 35 : 20
    } else { // Larger devices
        return hasNotch ? 40 : 25
    }
}
private func adaptiveSidebarWidth(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = geometry.size.width
        if screenWidth <= 375 {
            return 0.75
        } else {
            return 0.7
        }
    }
private func adaptiveButtonSize(for geometry: GeometryProxy) -> CGFloat {
       let screenWidth = geometry.size.width
       if screenWidth <= 375 {
           return 40
       } else {
           return 44
       }
   }

struct ShareView: View {
    @Binding var isBackButtonVisible: Bool
    @State private var isSharing = true

    var body: some View {
        ZStack {
            LinearGradient(
                
                gradient: Gradient(colors: [Color.gray, Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text("Sharing...")
                .font(.title)
                .foregroundColor(.white)
        }
        .onAppear {
            isBackButtonVisible = true
        }
        .sheet(isPresented: $isSharing, onDismiss: {
            isBackButtonVisible = true
        }) {
            let shareText = "Check out this amazing app!"
            let shareURL = URL(string: "https://example.com")!
            ActivityView(activityItems: [shareText, shareURL])
        }
    }
}



struct HelpView: View {
    @Binding var isBackButtonVisible: Bool

    var body: some View {
        ZStack {
            Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
                .edgesIgnoringSafeArea(.all)
            WebView(urlString: "https://cdn-tringbox-photos.s3.ap-south-1.amazonaws.com/about/index.html")
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            isBackButtonVisible = true
        }
        .navigationBarHidden(true)
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
struct SignInView: View {
    @Binding var isBackButtonVisible: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text("Sign In Page")
                .foregroundColor(.white)
        }
        .onAppear {
            isBackButtonVisible = true
        }
    }
}




struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showShareSheet = false
    @State private var selectedHistoryItem: ScannedHistoryItem? = nil
    @State private var isRefreshing = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollView {
                    PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                        refreshScanHistory()
                    }
                    
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    if appState.scannedHistory.isEmpty {
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("No scan history available.")
                                .foregroundColor(.gray)
                                .font(.system(size: 17))
                            Text("Start scanning codes to see them here!")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(appState.scannedHistory) { historyItem in
                                HistoryItemView(
                                    historyItem: historyItem,
                                    showShareSheet: $showShareSheet,
                                    selectedHistoryItem: $selectedHistoryItem
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
                .coordinateSpace(name: "pullToRefresh")
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let selectedHistoryItem = selectedHistoryItem {
                ActivityView(activityItems: [selectedHistoryItem.code])
            }
        }
        .onAppear {
            refreshScanHistory()
        }
    }

    private func refreshScanHistory() {
        isRefreshing = true
        
        let deviceId = appState.getDeviceId()
        print("Refreshing scan history for device: \(deviceId)")
        
        appState.fetchScanHistory(deviceId: deviceId) { history in
            DispatchQueue.main.async {
                isRefreshing = false
                
                if let history = history {
                    
                    let scannedItems = history.compactMap { item -> ScannedHistoryItem? in
                        guard let code = item["eventName"] as? String else { return nil }
                        return ScannedHistoryItem(
                            code: code,
                            eventName: item["eventName"] as? String,
                            event: item["event"] as? String,
                            timestamp: item["updatedAt"] as? String
                        )
                    }
                    
                   
                    if !scannedItems.isEmpty {
                        appState.scannedHistory = scannedItems
                        errorMessage = nil
                    } else if appState.scannedHistory.isEmpty {
                        
                        errorMessage = "No scan history available yet"
                    }
                }
                
                print("History refresh complete. Items count: \(appState.scannedHistory.count)")
            }
        }
    }
}
struct PullToRefresh: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .named(coordinateSpaceName)).midY > 50 {
                Spacer()
                    .onAppear {
                        if !isRefreshing {
                            isRefreshing = true
                            onRefresh()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isRefreshing = false
                            }
                        }
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                }
                Spacer()
            }
        }
        .padding(.top, isRefreshing ? 0 : -50)
    }
}
struct HistoryItemView: View {
    let historyItem: ScannedHistoryItem
    @Binding var showShareSheet: Bool
    @Binding var selectedHistoryItem: ScannedHistoryItem?
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(historyItem.code)
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: historyItem.code),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding(.horizontal, 4)
                
                Button(action: {
                    selectedHistoryItem = historyItem
                    DispatchQueue.main.async {
                        showShareSheet = true
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            
            Text(formattedDate(historyItem.date))
                .font(.system(size: 12))
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                    )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .contextMenu {
            Button(action: {
                selectedHistoryItem = historyItem
                showShareSheet = true
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                if let url = URL(string: historyItem.code),
                   UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("Open Link", systemImage: "arrow.up.right.square")
            }
            
            Button(role: .destructive, action: {
                showDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Item", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteHistoryItem(historyItem)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item?")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteHistoryItem(_ item: ScannedHistoryItem) {
        if let index = appState.scannedHistory.firstIndex(where: { $0.id == item.id }) {
            appState.scannedHistory.remove(at: index)
        }
    }
}

struct Preview_contentview: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(appState: AppState())
                .environmentObject(AppState())
                .previewDevice("iPhone SE (3rd generation)")
            
            ContentView(appState: AppState())
                .environmentObject(AppState())
                .previewDevice("iPhone 14 Pro")
        }
    }
}
