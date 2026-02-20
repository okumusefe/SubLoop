//
//  SettingsView.swift
//  SubLoop
//
//  Created by Efe Okumuş on 17.02.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedCurrency") private var selectedCurrency: String = Currency.usd.rawValue
    
    private var currentCurrency: Currency {
        Currency(rawValue: selectedCurrency) ?? .usd
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Currency")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Select your preferred currency for displaying subscription prices")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            VStack(spacing: 12) {
                                ForEach(Currency.allCases, id: \.self) { currency in
                                    Button(action: {
                                        selectedCurrency = currency.rawValue
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        currentCurrency == currency ?
                                                        LinearGradient(
                                                            colors: [
                                                                Color(red: 0.4, green: 0.7, blue: 1.0),
                                                                Color(red: 0.6, green: 0.4, blue: 1.0)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ) :
                                                        LinearGradient(
                                                            colors: [Color(red: 0.15, green: 0.15, blue: 0.25)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 50, height: 50)
                                                
                                                Text(currency.symbol)
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(currency.name)
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Text(currency.rawValue)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            
                                            Spacer()
                                            
                                            if currentCurrency == currency {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
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
                                            }
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(
                                                            currentCurrency == currency ?
                                                            LinearGradient(
                                                                colors: [
                                                                    Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5),
                                                                    Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.5)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ) :
                                                            LinearGradient(
                                                                colors: [Color.white.opacity(0.05)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: currentCurrency == currency ? 2 : 1
                                                        )
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                InfoRow(title: "Version", value: "1.0.0")
                                InfoRow(title: "Developer", value: "SubLoop Team")
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
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
                }
            }
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SettingsView()
}
