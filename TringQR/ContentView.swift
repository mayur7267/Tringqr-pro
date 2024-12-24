//
//  ContentView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import UIKit

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet {
            // Persist login status when it changes
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }
    @Published var userName: String? = nil
    @Published var phoneNumber: String? = nil
    @Published var scannedHistory: [String] {
        didSet {
            UserDefaults.standard.set(scannedHistory, forKey: "scannedHistory")
        }
    }
    @Published var isFirstLaunch: Bool {
        didSet {
            UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
        }
    }

    init() {
        
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.userName = UserDefaults.standard.string(forKey: "userName")
        self.phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")
        self.scannedHistory = UserDefaults.standard.stringArray(forKey: "scannedHistory") ?? []
        self.isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
    }

    func toggleLogin() {
        isLoggedIn.toggle()
    }

    func setUserName(_ name: String?) {
        userName = name
        UserDefaults.standard.set(name, forKey: "userName")
    }
    
    func setPhoneNumber(_ number: String?) {
        phoneNumber = number
        UserDefaults.standard.set(number, forKey: "phoneNumber")
    }

    func addScannedCode(_ code: String) {
        scannedHistory.append(code)
    }

    func completeFirstLaunch() {
        isFirstLaunch = false
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var isSidebarVisible = false
    @State private var selectedTab = 1
    @State private var isBackButtonVisible = false
    @State private var showLoginView: Bool
    @State private var showShareSheet = false

    init(appState: AppState) {
        _showLoginView = State(initialValue: !appState.isLoggedIn && appState.isFirstLaunch)
    }

    var body: some View {
        NavigationStack {
            NavigationView {
                ZStack {
                    
                    Color(red: 220/255, green: 220/255, blue: 220/255)
                        .ignoresSafeArea()


                    if showLoginView {
                        LoginView(onLoginSuccess: { 
                            appState.isLoggedIn = true
                            appState.setUserName($0)
                            showLoginView = false
                            appState.completeFirstLaunch()
                        })
                        .transition(.move(edge: .leading))
                    } else {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                if selectedTab != 0 {
                                            GIFView(gifName: "main")
                                                .ignoresSafeArea(edges: .all)
                                        }
                                
                                VStack(spacing: 0) {
                                    // Navigation Bar
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
                                                withAnimation(.spring()) {
                                                    isSidebarVisible.toggle()
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
                                        
                                        Spacer()
                                    }
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color.white)
                                    .padding(.vertical, 40)
                                    .offset(y: 0)
                                    .zIndex(2)
                                    
                                    // Main Content
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
                                
                                // Sidebar and overlay
                                if isSidebarVisible {
                                    Color.black.opacity(0.5)
                                        .ignoresSafeArea()
                                        .onTapGesture {
                                            withAnimation {
                                                isSidebarVisible = false
                                            }
                                        }
                                    
                                    HStack(spacing: 0) {
                                        SidebarView(
                                            isSidebarVisible: $isSidebarVisible,
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
                .sheet(isPresented: $showShareSheet) { // Add sheet modifier here
                    let shareText = "Check out this amazing app!"
                    let shareURL = URL(string: "https://example.com")!
                    ShareSheet(items: [shareText, shareURL])
                }
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
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showShareSheet = false
    @State private var selectedHistoryItem: String? = nil

    var body: some View {
        ZStack {
            // Light yellow background covering the entire screen
            Color(red: 220/255, green: 220/255, blue: 220/255) // Light yellow
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
                            ForEach(appState.scannedHistory, id: \.self) { historyItem in
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
                ActivityView(activityItems: [selectedHistoryItem])
            }
        }
    }
}


struct HistoryItemView: View {
    let historyItem: String
    @Binding var showShareSheet: Bool
    @Binding var selectedHistoryItem: String?
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(historyItem)
                    .font(.system(size: 16))
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: historyItem),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 4)
                
                Button(action: {
                    selectedHistoryItem = historyItem
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                }
            }
            
            Text("13-12-2024 6:17 PM")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
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
                if let url = URL(string: historyItem),
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
    
    private func deleteHistoryItem(_ item: String) {
        if let index = appState.scannedHistory.firstIndex(of: item) {
            appState.scannedHistory.remove(at: index)
        }
    }
}



#Preview {
    ContentView(appState: AppState())
        .environmentObject(AppState())
}
