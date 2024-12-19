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


struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isSidebarVisible: Bool
    @Binding var selectedTab: Int
    @Binding var isBackButtonVisible: Bool
    @Binding var showShareSheet: Bool
    @Binding var showLoginView: Bool

    var body: some View {
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
                isSelected: false
            ) {
                withAnimation {
                    isSidebarVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
                title: appState.isLoggedIn ? "Sign Out" : "Sign In",
                systemImage: "person.circle",
                isSelected: false
            ) {
                if appState.isLoggedIn {
                    appState.toggleLogin()
                    appState.setUserName(nil)
                    showLoginView = true
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
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}


#Preview {
    SidebarView(isSidebarVisible: .constant(true), selectedTab: .constant(0), isBackButtonVisible: .constant(false), showShareSheet: .constant(false), showLoginView: .constant(false))
        .environmentObject(AppState())
}

