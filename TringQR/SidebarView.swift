//
//  SidebarView.swift
//  TringQR
//
//  Created by Mayur on 17/12/24.
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
                    .foregroundColor(isSelected ? .gray : .purple)
                    .imageScale(.large)

                Text(title)
                    .font(.body)
                    .foregroundColor(isSelected ? .gray : .black)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.purple.opacity(0.1) : Color.clear)
        }
    }
}


struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isSidebarVisible: Bool
    @Binding var selectedTab: Int
    @Binding var isBackButtonVisible: Bool
    @Binding var showShareSheet: Bool
    @Binding var showLoginView: Bool

    @State private var isEditingName = false
    @State private var newName = UserDefaults.standard.string(forKey: "userName") ?? "Champion" 

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown Version"
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompactDevice = geometry.size.height < 700

            VStack(alignment: .leading, spacing: isCompactDevice ? 10 : 20) {
                VStack {
                    Image("Champion")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isCompactDevice ? 90 : 120, height: isCompactDevice ? 90 : 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.purple, lineWidth: 4)
                        )
                        .padding(.top, isCompactDevice ? 10 : 15)
                        .offset(y: isCompactDevice ? 25 : 35)

                    HStack {
                        if isEditingName {
                            TextField("", text: $newName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(isCompactDevice ? .callout : .headline)
                                .foregroundColor(.black)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                .frame(width: 150)

                            Button(action: {
                                appState.setUserName(newName)
                                UserDefaults.standard.setValue(newName, forKey: "userName")
                                isEditingName = false
                            }) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }

                            Button(action: {
                                isEditingName = false
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                            }
                        } else {
                            Text("Hi \(newName)!")
                                .font(isCompactDevice ? .callout : .headline)
                                .foregroundColor(.black)

                            Button {
                                isEditingName = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .imageScale(.small)
                            }
                        }
                    }

                    .padding(isCompactDevice ? 30 : 50)
                    .offset(y: isCompactDevice ? 10 : 20)
                }
                .frame(maxWidth: .infinity)
                .background(Color.yellow)
                .frame(height: isCompactDevice ? 200 : 260)
                .padding(.bottom, isCompactDevice ? 5 : 10)
                
                
                VStack(spacing: isCompactDevice ? 5 : 10) {
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
                        isSelected: false
                    ) {
                        withAnimation {
                            isSidebarVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showShareSheet = true
                        }
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
                            title: "Create QR",
                            systemImage: "qrcode",
                            isSelected: selectedTab == 4
                        ) {
                            selectedTab = 4
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
                            appState.setUserName("")
                            showLoginView = true
                        } else {
                            showLoginView = true
                        }
                        isSidebarVisible = false
                        isBackButtonVisible = false
                    }
                }
                .padding(.vertical, isCompactDevice ? 5 : 10)
                
                Spacer()
                
                Text("Made in India | v\(appVersion)")
                    .font(.footnote)
                    .foregroundColor(.black)
                    .padding(.bottom, isCompactDevice ? 10 : 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
    }
}



#Preview {
    SidebarView(isSidebarVisible: .constant(true), selectedTab: .constant(0), isBackButtonVisible: .constant(false), showShareSheet: .constant(false), showLoginView: .constant(false))
        .environmentObject(AppState())
}

