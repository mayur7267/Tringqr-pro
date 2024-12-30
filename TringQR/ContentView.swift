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
        self.date = Date()
        self.eventName = eventName
        self.event = event
        self.timestamp = timestamp
    }
}

class AppState: ObservableObject {
    // MARK: - Published Properties
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
    
    @Published var scannedHistory: [ScannedHistoryItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(scannedHistory) {
                KeychainWrapper.standard.set(encoded, forKey: "scannedHistory")
            }
            // Update the set whenever history changes
            scannedHistorySet = Set(scannedHistory.map { $0.code })
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
    
    // MARK: - Private Properties
    @Published var scannedHistorySet: Set<String> = []
    private let lock = DispatchQueue(label: "appStateLock")
    
    // MARK: - Initialization
    init() {
        // Initialize from UserDefaults
        self.currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
        self.scannedHistory = []
        self.isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") == nil || UserDefaults.standard.bool(forKey: "isFirstLaunch")
        self.isSidebarVisible = UserDefaults.standard.bool(forKey: "isSidebarVisible")
        
        // Load cached history from Keychain
        if let data = KeychainWrapper.standard.data(forKey: "scannedHistory"),
           let decoded = try? JSONDecoder().decode([ScannedHistoryItem].self, from: data) {
            self.scannedHistory = decoded
            self.scannedHistorySet = Set(decoded.map { $0.code })
        }
        
        // Fetch remote history
        restoreHistoryFromBackend()
    }
    
    // MARK: - History Management
    func restoreHistoryFromBackend() {
        let deviceId = getDeviceId()
        fetchScanHistory(deviceId: deviceId) { [weak self] history in
            guard let self = self, let history = history else { return }
            
            DispatchQueue.main.async {
            
                let newItems = history.compactMap { item -> ScannedHistoryItem? in
                    guard let code = item["code"] as? String else { return nil }
                    return ScannedHistoryItem(
                        code: code,
                        eventName: item["eventName"] as? String,
                        event: item["event"] as? String,
                        timestamp: item["timestamp"] as? String
                    )
                }
                
                // Append new items to existing history
                if !newItems.isEmpty {
                    self.lock.sync {
                        self.scannedHistory.append(contentsOf: newItems)
                        newItems.forEach { item in
                            self.scannedHistorySet.insert(item.code)
                        }
                    }
                }
            }
        }
    }
    
    func addScannedCode(_ code: String, deviceId: String,os: String, event: String, eventName: String) {
        lock.sync {
            guard !scannedHistorySet.contains(code) else { return }
            let newItem = ScannedHistoryItem(code: code, eventName: eventName, event: event)
            scannedHistory.append(newItem)
            scannedHistorySet.insert(code)
        }
        sendToBackend(code: code, deviceId: deviceId,os: "iOS", event: "scan", eventName: eventName)
    }
    
    // MARK: - Network Requests
    func fetchScanHistory(deviceId: String, completion: @escaping ([[String: Any]]?) -> Void) {
        guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/users/activity/\(deviceId)") else {
            print("Invalid URL for fetching history")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching history: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(nil)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("Server returned status code: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let activities = json["activities"] as? [[String: Any]] else {
                    print("Failed to parse JSON response")
                    completion(nil)
                    return
                }
                
                let history = activities.map { activity -> [String: Any] in
                    var mappedActivity: [String: Any] = [:]
                    mappedActivity["code"] = activity["code"] as? String ?? ""
                    mappedActivity["eventName"] = activity["eventName"] as? String ?? ""
                    mappedActivity["event"] = activity["event"] as? String ?? ""
                    mappedActivity["timestamp"] = activity["timestamp"] as? String ?? ""
                    return mappedActivity
                }
                
                print("Successfully fetched history: \(history)")
                completion(history)
                
            } catch {
                print("Error parsing response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    private func sendToBackend(code: String, deviceId: String, os: String, event: String, eventName: String) {
        guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/users/activity") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "deviceId": deviceId,
            "os": os,
            "eventName": eventName,
            "event": event,
            "code": code
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Failed to serialize payload")
            return
        }

        URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            if let error = error {
                print("Error sending data to backend: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                print("Successfully sent data to backend.")
            } else {
                print("Failed with response: \(String(describing: response))")
            }
        }.resume()
    }

    
    // MARK: - User Management
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
    
    // MARK: - UI State Management
    func completeFirstLaunch() {
        isFirstLaunch = false
    }

    func toggleSidebar() {
        isSidebarVisible.toggle()
    }
    
    // MARK: - Device Management
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
}


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedTab = 1
    @State private var isBackButtonVisible = false
    @State private var showLoginView: Bool
    @State private var showShareSheet = false
    @Environment(\.scenePhase) private var scenePhase
    
    init(appState: AppState) {
        _showLoginView = State(initialValue: !appState.isLoggedIn && appState.isFirstLaunch)
    }
    
    var body: some View {
        NavigationStack {
            NavigationView {
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
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                if selectedTab != 0 && selectedTab != 3 {
                                    GIFView(gifName: "main")
                                        .ignoresSafeArea(edges: .all)
                                }
                                
                                VStack(spacing: 0) {
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
                                                withAnimation(.easeInOut) {
                                                    appState.toggleSidebar()
                                                }
                                            }) {
                                                Image(systemName: "line.3.horizontal")
                                                    .bold()
                                                    .foregroundColor(.black)
                                                    .imageScale(.large)
                                                    .contentShape(Rectangle())
                                            }
                                            .border(Color.clear)
                                            .frame(width: 44, height: 44)
                                            .background(Color.clear)
                                            .zIndex(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(selectedTab == 0 ? "Scan History" : "TringQR")
                                            .foregroundColor(.black)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .offset(x: -20)
                                        Spacer()
                                    }
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color.white)
                                    .padding(.vertical, 40)
                                    .offset(y: 0)
                                    .zIndex(2)
                                    
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
                                               
                                        default:
                                            Text("Unknown View")
                                        }
                                    }
                                }
                                
                                if appState.isSidebarVisible {
                                    Color.black.opacity(0.5)
                                        .ignoresSafeArea()
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                appState.isSidebarVisible = false
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
                                        .frame(width: geometry.size.width * 0.7)
                                        .background(Color.white)
                                        .edgesIgnoringSafeArea(.bottom)
                                        .offset(x: appState.isSidebarVisible ? 0 : -geometry.size.width * 0.7) // Slide in/out
                                    .animation(.easeInOut(duration: 0.3), value: appState.isSidebarVisible)
                                        .transition(.move(edge: .leading))
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .navigationBarHidden(true)
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
        }
        .onAppear {
            appState.isSidebarVisible = false
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                appState.isSidebarVisible = false
            }
        }
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
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Main Content
                if filteredHistory.isEmpty {
                    Spacer()
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
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredHistory) { historyItem in
                                HistoryItemView(
                                    historyItem: historyItem,
                                    showShareSheet: $showShareSheet,
                                    selectedHistoryItem: $selectedHistoryItem
                                )
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deleteHistoryItem(historyItem)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let selectedHistoryItem = selectedHistoryItem {
                ActivityView(activityItems: [selectedHistoryItem.code])
            }
        }
        .onAppear {
            if let deviceId = UIDevice.current.identifierForVendor?.uuidString {
                appState.fetchScanHistory(deviceId: deviceId) { history in
                    guard let history = history else {
                        print("No history found or an error occurred.")
                        return
                    }

                    // Map the raw history to ScannedHistoryItem objects
                    let scannedItems = history.compactMap { item -> ScannedHistoryItem? in
                        guard let code = item["code"] as? String else { return nil }
                        return ScannedHistoryItem(
                            code: code,
                            eventName: item["eventName"] as? String,
                            event: item["event"] as? String,
                            timestamp: item["timestamp"] as? String
                        )
                    }

                    DispatchQueue.main.async {
                        appState.scannedHistory = scannedItems
                    }
                }
            } else {
                print("Failed to get device ID")
            }
        }

    }

    private var filteredHistory: [ScannedHistoryItem] {
        return appState.scannedHistory
    }

    private func deleteHistoryItem(_ item: ScannedHistoryItem) {
        showDeleteConfirmation = true
        if let index = appState.scannedHistory.firstIndex(where: { $0.id == item.id }) {
            appState.scannedHistory.remove(at: index)
        }
    }
}

struct HistoryItemView: View {
    let historyItem: ScannedHistoryItem
    @Binding var showShareSheet: Bool
    @Binding var selectedHistoryItem: ScannedHistoryItem?
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme // Detect light/dark mode
    
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
                deleteHistoryItem(historyItem)
            }) {
                Label("Delete", systemImage: "trash")
            }
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



#Preview {
    ContentView(appState: AppState())
        .environmentObject(AppState())
}
