//
//  ContentView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import UIKit

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userName: String? = nil
    @Published var scannedHistory: [String] = []
    @Published var isFirstLaunch: Bool {
            didSet {
                UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
            }
        }
        
        init() {
            
            self.isFirstLaunch = UserDefaults.standard.object(forKey: "isFirstLaunch") as? Bool ?? true
        }
    func toggleLogin() {
        isLoggedIn.toggle()
    }

    func setUserName(_ name: String?) {
        userName = name
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
        // Initialize showLoginView with the value of isFirstLaunch
        _showLoginView = State(initialValue: appState.isFirstLaunch)
    }

    var body: some View {
        NavigationView {
            ZStack {
                if showLoginView {
                    LoginView(onLoginSuccess: {
                        appState.isLoggedIn = true
                        appState.setUserName("Google User")
                        showLoginView = false
                        appState.completeFirstLaunch()
                    })
                    .transition(.move(edge: .leading))
                } else {
                    GeometryReader { geometry in
                        ZStack {
                            // Background
                            GIFView(gifName: "main")
                                .ignoresSafeArea()

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
                                        }
                                    }

                                    Spacer()

                                    Text("TringQR")
                                        .foregroundColor(.black)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .center)

                                    Spacer()
                                }
                                .frame(height: 44)
                                .padding(.horizontal, 12)
                                .background(Color.white)
                                .shadow(color: Color.gray.opacity(0.2), radius: 1, x: 0, y: 1)
                                .offset(y: 48)
                                Spacer()

                                // Main Content
                                Group {
                                    switch selectedTab {
                                    case 0:
                                        HistoryView(isBackButtonVisible: $isBackButtonVisible)
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

                            // Sidebar
                            if isSidebarVisible {
                                Color.black.opacity(0.5)
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        withAnimation {
                                            isSidebarVisible = false
                                        }
                                    }

                                SidebarView(
                                    isSidebarVisible: $isSidebarVisible,
                                    selectedTab: $selectedTab,
                                    isBackButtonVisible: $isBackButtonVisible,
                                    showShareSheet: $showShareSheet
                                )
                                .frame(width: geometry.size.width * 0.7)
                                .transition(.move(edge: .leading))
                                .animation(.spring(), value: isSidebarVisible)
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    .navigationBarHidden(true)
                }
            }
            .ignoresSafeArea(edges: .top)
            .environmentObject(appState)
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
    @Binding var isBackButtonVisible: Bool
    @EnvironmentObject var appState: AppState

    @State private var showShareSheet = false
    @State private var selectedHistoryItem: String? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(alignment: .leading) {
                    if appState.scannedHistory.isEmpty {
                        Text("No scan history available.")
                            .foregroundColor(.white)
                            .font(.title3)
                            .padding()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 15) {
                                List{
                                    ForEach(appState.scannedHistory, id: \ .self) { code in
                                        HStack {
                                            Image(systemName: "qrcode")
                                                .foregroundColor(.white)
                                                .padding(.trailing, 10)
                                            
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(code)
                                                    .font(.body)
                                                    .foregroundColor(.white)
                                                
                                                Text("Tap to share or swipe to delete")
                                                    .font(.footnote)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedHistoryItem = code
                                            showShareSheet = true
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.8))
                                        .cornerRadius(10)
                                    }
                                    .onDelete(perform: { indexSet in
                                            appState.scannedHistory.remove(atOffsets: indexSet)
                                        })
                                }
                            }
                            .padding()
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .onAppear {
                isBackButtonVisible = true
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Scan History")
            .navigationBarItems(leading: Button(action: {
                isBackButtonVisible = false
            }) {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.purple)
            })
            .sheet(isPresented: $showShareSheet) {
                if let selectedHistoryItem = selectedHistoryItem {
                    ActivityView(activityItems: [selectedHistoryItem])
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appState: AppState())
            .environmentObject(AppState())
    }
}
