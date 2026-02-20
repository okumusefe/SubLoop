//
//  CategoryPicker.swift
//  SubLoop
//
//  Created by Efe Okumuş on 17.02.2026.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: String
    let availableCategories = ["Entertainment", "Productivity", "Cloud Storage", "Music", "Gaming", "Fitness", "News", "Education", "Other"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Menu {
                ForEach(availableCategories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }) {
                        HStack {
                            Text(category)
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
}
