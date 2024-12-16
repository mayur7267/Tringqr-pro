//
//  ContentView.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//

import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

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

    @State private var isSidebarVisible = false {
        didSet {
            print("Sidebar visibility changed to: \(isSidebarVisible)")
        }
    }
    @State private var selectedTab = 1
    @State private var isBackButtonVisible = false
    @State private var showLoginView = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                if appState.isFirstLaunch {
                    // Show LoginView for first-time launch
                    LoginView(onLoginSuccess: {
                        appState.isLoggedIn = true
                        appState.setUserName("Google User")
                        appState.completeFirstLaunch()
                    })
                    .transition(.move(edge: .leading))
                } else {
                    // Regular Content
                    GeometryReader { geometry in
                        ZStack {
                            GIFView(gifName: "background")
                                .ignoresSafeArea()

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
                                            print("Hamburger button tapped")
                                            withAnimation {
                                                isSidebarVisible.toggle()
                                            }
                                        }) {
                                            Image(systemName: "line.3.horizontal")
                                                .bold()
                                                .foregroundColor(.black)
                                                .imageScale(.large)
                                        }
                                        .padding(16)
                                        .contentShape(Rectangle()) 
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

                            if isSidebarVisible {
                                Color.black.opacity(0.5)
                                    .edgesIgnoringSafeArea(.all)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isSidebarVisible = false
                                        }
                                    }

                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 20) {
                                        VStack {
                                            if let userName = appState.userName {
                                                Text("Hi \(userName)!")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                    .padding(30)
                                            } else {
                                                Text("Hi Champion!")
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                    .padding(30)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .background(Color.yellow)

                                        SidebarItem(title: "Scan History", systemImage: "clock", isSelected: selectedTab == 0) {
                                            selectedTab = 0
                                            isSidebarVisible = false
                                            isBackButtonVisible = true
                                        }
                                        SidebarItem(title: "Scanner", systemImage: "camera", isSelected: selectedTab == 1) {
                                            selectedTab = 1
                                            isSidebarVisible = false
                                            withAnimation { isBackButtonVisible = false }
                                        }
                                        SidebarItem(title: "Share", systemImage: "square.and.arrow.up", isSelected: selectedTab == 2) {
                                            selectedTab = 2
                                            isSidebarVisible = false
                                            isBackButtonVisible = true
                                            showShareSheet = true
                                        }
                                        .sheet(isPresented: $showShareSheet) {
                                            let shareText = "Check out this amazing app!"
                                            let shareURL = URL(string: "https://example.com")!
                                            ActivityView(activityItems: [shareText, shareURL])
                                        }
                                        SidebarItem(title: "Help", systemImage: "questionmark.circle", isSelected: selectedTab == 3) {
                                            selectedTab = 3
                                            isSidebarVisible = false
                                            isBackButtonVisible = true
                                        }
                                    }
                                    .frame(width: geometry.size.width * 0.7)
                                    .background(Color.white)
                                    .shadow(radius: 5)
                                    .transition(.move(edge: .leading))
                                    Spacer()
                                }
                                .transition(.move(edge: .leading))
                                .animation(.easeInOut(duration: 0.3), value: isSidebarVisible)
                            }
                        }
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
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
                                .onDelete { indexSet in
                                    appState.scannedHistory.remove(atOffsets: indexSet)
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
        ContentView()
            .environmentObject(AppState())
    }
}
