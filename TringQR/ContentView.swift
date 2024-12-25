//
//  ContentView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import UIKit
import Combine

struct ScannedHistoryItem: Identifiable, Codable {
    let id: UUID
    let code: String
    let date: Date

    init(code: String) {
        self.id = UUID()
        self.code = code
        self.date = Date()
    }
}


class AppState: ObservableObject {
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
                    UserDefaults.standard.set(encoded, forKey: "scannedHistory")
                }
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
    
    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
        if let data = UserDefaults.standard.data(forKey: "scannedHistory"),
                   let decoded = try? JSONDecoder().decode([ScannedHistoryItem].self, from: data) {
                    self.scannedHistory = decoded
                } else {
                    self.scannedHistory = []
                }
        self.isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
        self.isSidebarVisible = UserDefaults.standard.bool(forKey: "isSidebarVisible")
    }

    func toggleLogin() {
        isLoggedIn.toggle()
    }

    func setUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: "userName")
    }

    func setPhoneNumber(_ number: String?) {
        phoneNumber = number
        UserDefaults.standard.set(number, forKey: "phoneNumber")
    }

    func addScannedCode(_ code: String) {
            let newItem = ScannedHistoryItem(code: code)
            scannedHistory.append(newItem)
        }

    func completeFirstLaunch() {
        isFirstLaunch = false
    }

    func toggleSidebar() {
        isSidebarVisible.toggle()
    }
    
    func signOut() {
        isLoggedIn = false
        userName = ""
        phoneNumber = nil
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
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
                                if selectedTab != 0 {
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
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text("Help Page")
                .foregroundColor(.white)
        }
        .onAppear {
            isBackButtonVisible = true
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
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showShareSheet = false
    @State private var selectedHistoryItem: ScannedHistoryItem? = nil
    var body: some View {
        ZStack {
           
            Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Main Content
                if appState.scannedHistory.isEmpty {
                    Spacer()
                    Text("No scan history available.")
                        .foregroundColor(.gray)
                        .font(.system(size: 17))
                    Spacer()
                } else {
                    ScrollView {
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
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let selectedHistoryItem = selectedHistoryItem {
                ActivityView(activityItems: [selectedHistoryItem.code])
            }
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
