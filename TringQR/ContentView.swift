//
//  ContentView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI

struct SidebarItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .foregroundColor(isSelected ? .purple : .gray)
                    .imageScale(.large)

                Text(title)
                    .font(.body)
                    .foregroundColor(isSelected ? .purple : .gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.purple.opacity(0.1) : Color.clear)
        }
    }
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userName: String? = nil
    @Published var scannedHistory: [String] = [] 

    func toggleLogin() {
        isLoggedIn.toggle()
    }

    func setUserName(_ name: String?) {
        userName = name
    }

    func addScannedCode(_ code: String) {
        scannedHistory.append(code)
    }
}


struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var isSidebarVisible = false
    @State private var selectedTab = 1
    @State private var isBackButtonVisible = false
    @State private var showLoginView = false
    var body: some View {
        NavigationView {
            ZStack {
                if showLoginView {
                    LoginView(onLoginSuccess: {
                        appState.isLoggedIn = true
                        appState.setUserName("Google User")
                        showLoginView = false
                    })
                    .transition(.move(edge: .leading))
                } else {
                    GeometryReader { geometry in
                        ZStack {
                            // Background
                            GIFView(gifName: "background")
                                .ignoresSafeArea()

                            VStack {
                                // Navigation Bar
                                HStack {
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
                                            withAnimation {
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

                                HStack {
                                    VStack(alignment: .leading, spacing: 20) {
                                        // Sidebar Header
                                        VStack {
                                            if let userName = appState.userName {
                                                Text("Hi \(userName)!")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                    .padding(30)
                                            } else {
                                                Image("Champion")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.purple, lineWidth: 3)
                                                    )
                                                    .padding(.top, 25)

                                                Text("Hi Champion!")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                    .padding(30)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .background(Color.yellow)

                                        // Sidebar Items
                                        SidebarItem(
                                            title: "Scan History",
                                            systemImage: "clock",
                                            isSelected: selectedTab == 0
                                        ) {
                                            selectedTab = 0
                                            isSidebarVisible = false
                                            isBackButtonVisible = true
                                        }

                                        SidebarItem(
                                            title: "Share",
                                            systemImage: "square.and.arrow.up",
                                            isSelected: selectedTab == 2
                                        ) {
                                            selectedTab = 2
                                            isSidebarVisible = false
                                            isBackButtonVisible = true
                                        }

                                        SidebarItem(
                                            title: "Help",
                                            systemImage: "questionmark.circle",
                                            isSelected: selectedTab == 3
                                        ) {
                                            selectedTab = 3
                                            isSidebarVisible = false
                                            isBackButtonVisible = true
                                        }

                                        SidebarItem(
                                            title: appState.isLoggedIn ? "Sign Out" : "Sign In",
                                            systemImage: "person.circle",
                                            isSelected: false
                                        ) {
                                            if appState.isLoggedIn {
                                                appState.toggleLogin()
                                                appState.setUserName(nil)
                                            } else {
                                                showLoginView = true
                                            }
                                            isSidebarVisible = false
                                            isBackButtonVisible = false
                                        }

                                        Spacer()

                                        Text("Made in India")
                                            .font(.footnote)
                                            .foregroundColor(.black)
                                            .padding(.bottom, 20)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                    .frame(width: geometry.size.width * 0.7)
                                    .background(Color.white)
                                    .edgesIgnoringSafeArea(.bottom)

                                    Spacer()
                                }
                                .transition(.move(edge: .leading))
                            }
                        }
                    }
                    .navigationBarHidden(true)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// Other Views
struct ShareView: View {
    @Binding var isBackButtonVisible: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Text("Share Page")
                .foregroundColor(.white)
        }
        .onAppear {
            isBackButtonVisible = true
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

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading) {
                Text("Scan History")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()

                if appState.scannedHistory.isEmpty {
                    Text("No scan history available.")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    List(appState.scannedHistory, id: \.self) { code in
                        HStack {
                            Image(systemName: "qrcode")
                                .foregroundColor(.white)
                            Text(code)
                                .foregroundColor(.white)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .background(Color.clear)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            isBackButtonVisible = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}
