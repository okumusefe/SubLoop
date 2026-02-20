//
//  SplashScreenView.swift
//  SubLoop
//
//  Created by Efe Okumuş on 17.02.2026.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.8
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                    
                    Text("SubLoop")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0),
                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(logoOpacity)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    logoOpacity = 1.0
                    logoScale = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
