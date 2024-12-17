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
    @Binding var selectedTab: Int
    @Binding var isSidebarVisible: Bool
    @Binding var isBackButtonVisible: Bool
    @EnvironmentObject var appState: AppState
    @State private var showShareSheet = false

    var body: some View {
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
            .frame(width: 250)
            .background(Color.white)
            .shadow(radius: 5)
            .transition(.move(edge: .leading))
            
            Spacer()
        }
    }
}
#Preview {
    SidebarView(selectedTab: .constant(0), isSidebarVisible: .constant(true), isBackButtonVisible: .constant(false))
        .environmentObject(AppState())
}

