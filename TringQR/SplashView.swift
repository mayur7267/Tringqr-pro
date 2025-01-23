//
//  SplashView.swift
//  TringQR
//
//  Created by Mayur on 23/01/25.
//



import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.5

    var body: some View {
        VStack {
            if isActive {
              
                ContentView(appState: AppState())
            } else {
                
                Image("splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .opacity(opacity)
                    .cornerRadius(12)
                    .onAppear {
                       
                        withAnimation(.easeIn(duration: 0.4)) {
                            opacity = 1.0
                        }

                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isActive = true
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SplashView()
}
