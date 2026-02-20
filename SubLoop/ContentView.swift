//
//  ContentView.swift
//  SubLoop
//
//  Created by Efe Okumuş on 16.02.2026.
//

import SwiftUI
import SwiftData
import Charts

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case try_ = "TRY"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .try_: return "₺"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .try_: return "Turkish Lira"
        }
    }
}

@Model
class Subscription {
    var id: UUID
    var name: String
    var icon: String
    var price: Double
    var currency: String
    var category: String
    var nextPaymentDate: Date
    var accentColorRed: Double
    var accentColorGreen: Double
    var accentColorBlue: Double
    
    init(name: String, icon: String, price: Double, currency: String, category: String, nextPaymentDate: Date, accentColor: Color) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.price = price
        self.currency = currency
        self.category = category
        self.nextPaymentDate = nextPaymentDate
        
        let uiColor = UIColor(accentColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.accentColorRed = Double(red)
        self.accentColorGreen = Double(green)
        self.accentColorBlue = Double(blue)
    }
    
    var accentColor: Color {
        Color(red: accentColorRed, green: accentColorGreen, blue: accentColorBlue)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    @State private var showingAddSubscription = false
    @State private var showingEditSubscription = false
    @State private var showingSettings = false
    @State private var subscriptionToEdit: Subscription?
    @State private var notificationPermissionGranted = false
    @AppStorage("selectedCurrency") private var selectedCurrency: String = Currency.usd.rawValue
    
    private var currentCurrency: Currency {
        Currency(rawValue: selectedCurrency) ?? .usd
    }
    
    private var totalMonthlySpend: Double {
        subscriptions.reduce(0) { $0 + $1.price }
    }
    
    private var categorySpending: [(category: String, amount: Double, color: Color)] {
        let grouped = Dictionary(grouping: subscriptions, by: { $0.category })
        return grouped.map { category, subs in
            let total = subs.reduce(0) { $0 + $1.price }
            let color = categoryColor(for: category)
            return (category, total, color)
        }.sorted { $0.amount > $1.amount }
    }
    
    private func categoryColor(for category: String) -> Color {
        let colors: [Color] = [
            Color(red: 0.4, green: 0.7, blue: 1.0),
            Color(red: 0.6, green: 0.4, blue: 1.0),
            Color(red: 0.5, green: 0.8, blue: 1.0),
            Color(red: 0.7, green: 0.3, blue: 1.0),
            Color(red: 0.3, green: 0.6, blue: 0.9),
            .purple,
            .pink,
            .blue
        ]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        totalSpendCard
                        
                        analyticsChart
                        
                        subscriptionsList
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("SubLoop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSubscription = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
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
            }
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView(currency: currentCurrency)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showingEditSubscription) {
                if let subscription = subscriptionToEdit {
                    EditSubscriptionView(subscription: subscription, currency: currentCurrency)
                        .environment(\.modelContext, modelContext)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            addSampleDataIfNeeded()
            requestNotificationPermission()
        }
    }
    
    private var totalSpendCard: some View {
        VStack(spacing: 12) {
            Text("Total Monthly Spend")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(formatCurrency(totalMonthlySpend))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.7, blue: 1.0),
                            Color(red: 0.6, green: 0.4, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("per month")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.3),
                                    Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
    
    private var analyticsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Analysis")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            if subscriptions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.3),
                                    Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 20)
                    
                    Text("No data to analyze")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 20) {
                    Chart(categorySpending, id: \.category) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartBackground { _ in
                        VStack {
                            Text(formatCurrency(totalMonthlySpend))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
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
                            Text("Total")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .onTapGesture {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(categorySpending, id: \.category) { item in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(item.category)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text(formatCurrency(item.amount))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(Int((item.amount / totalMonthlySpend) * 100))%")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 45, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.08, green: 0.08, blue: 0.18))
                            )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.2),
                                            Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.15), radius: 15, x: 0, y: 8)
                )
            }
        }
    }
    
    private var subscriptionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Subscriptions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("(\(subscriptions.count))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            if subscriptions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5),
                                    Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 40)
                    
                    Text("No subscriptions yet")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Tap + to start tracking your subscriptions")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(subscriptions) { subscription in
                        subscriptionRow(subscription)
                            .onTapGesture {
                                subscriptionToEdit = subscription
                                showingEditSubscription = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteSubscription(subscription)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    private func subscriptionRow(_ subscription: Subscription) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(subscription.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: subscription.icon)
                    .font(.system(size: 22))
                    .foregroundColor(subscription.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Monthly subscription")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(formatCurrency(subscription.price))
                .font(.system(size: 18, weight: .bold, design: .rounded))
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currentCurrency.symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currentCurrency.symbol)0.00"
    }
    
    private func addSampleDataIfNeeded() {
        print("[DEBUG] addSampleDataIfNeeded called. Current count: \(subscriptions.count)")
        // Commented out sample data - let user add their own subscriptions
        /*
        if subscriptions.isEmpty {
            let today = Date()
            let calendar = Calendar.current
            
            let sampleSubscriptions = [
                Subscription(name: "Netflix", icon: "play.tv.fill", price: 15.99, currency: "$", nextPaymentDate: calendar.date(byAdding: .day, value: 15, to: today)!, accentColor: .red),
                Subscription(name: "Spotify", icon: "music.note", price: 10.99, currency: "$", nextPaymentDate: calendar.date(byAdding: .day, value: 10, to: today)!, accentColor: .green),
                Subscription(name: "iCloud", icon: "icloud.fill", price: 2.99, currency: "$", nextPaymentDate: calendar.date(byAdding: .day, value: 5, to: today)!, accentColor: .blue),
                Subscription(name: "YouTube Premium", icon: "play.rectangle.fill", price: 11.99, currency: "$", nextPaymentDate: calendar.date(byAdding: .day, value: 20, to: today)!, accentColor: .red),
                Subscription(name: "Apple One", icon: "applelogo", price: 19.95, currency: "$", nextPaymentDate: calendar.date(byAdding: .day, value: 25, to: today)!, accentColor: Color(red: 0.5, green: 0.5, blue: 0.5))
            ]
            
            for subscription in sampleSubscriptions {
                modelContext.insert(subscription)
                if notificationPermissionGranted {
                    NotificationManager.shared.schedulePaymentReminder(for: subscription)
                }
            }
        }
        */
    }
    
    private func requestNotificationPermission() {
        Task {
            notificationPermissionGranted = await NotificationManager.shared.requestAuthorization()
        }
    }
    
    private func deleteSubscriptions(at offsets: IndexSet) {
        for index in offsets {
            let subscription = subscriptions[index]
            deleteSubscription(subscription)
        }
    }
    
    private func deleteSubscription(_ subscription: Subscription) {
        NotificationManager.shared.cancelNotification(for: subscription.id)
        modelContext.delete(subscription)
        try? modelContext.save()
    }
}

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let currency: Currency
    
    @State private var name = ""
    @State private var price = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = Color.blue
    @State private var selectedCategory = "Entertainment"
    @State private var nextPaymentDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    
    let availableCategories = ["Entertainment", "Productivity", "Cloud Storage", "Music", "Gaming", "Fitness", "News", "Education", "Other"]
    
    let availableIcons = [
        ("star.fill", "Star"),
        ("play.tv.fill", "TV"),
        ("music.note", "Music"),
        ("icloud.fill", "Cloud"),
        ("gamecontroller.fill", "Gaming"),
        ("book.fill", "Books"),
        ("cart.fill", "Shopping"),
        ("film.fill", "Movies"),
        ("headphones", "Audio"),
        ("dumbbell.fill", "Fitness"),
        ("fork.knife", "Food"),
        ("airplane", "Travel")
    ]
    
    let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        Color(red: 0.4, green: 0.7, blue: 1.0),
        Color(red: 0.6, green: 0.4, blue: 1.0)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 16) {
                            Text("Subscription Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("", text: $name, prompt: Text("e.g., Netflix").foregroundColor(.white.opacity(0.3)))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
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
                        
                        VStack(spacing: 16) {
                            Text("Monthly Price")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Text(currency.symbol)
                                    .font(.system(size: 24, weight: .bold))
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
                                
                                TextField("", text: $price, prompt: Text("0.00").foregroundColor(.white.opacity(0.3)))
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
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
                        
                        VStack(spacing: 16) {
                            Text("Next Payment Date")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("", selection: $nextPaymentDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .tint(Color(red: 0.4, green: 0.7, blue: 1.0))
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
                        
                        VStack(spacing: 16) {
                            Text("Choose Icon")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                ForEach(availableIcons, id: \.0) { icon, label in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : .white.opacity(0.6))
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(
                                                                    selectedIcon == icon ?
                                                                    LinearGradient(
                                                                        colors: [
                                                                            Color(red: 0.4, green: 0.7, blue: 1.0),
                                                                            Color(red: 0.6, green: 0.4, blue: 1.0)
                                                                        ],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    ) :
                                                                    LinearGradient(
                                                                        colors: [Color.white.opacity(0.1)],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    ),
                                                                    lineWidth: selectedIcon == icon ? 2 : 1
                                                                )
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 16) {
                            Text("Choose Color")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                                ForEach(availableColors.indices, id: \.self) { index in
                                    Button(action: {
                                        selectedColor = availableColors[index]
                                    }) {
                                        Circle()
                                            .fill(availableColors[index])
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedColor == availableColors[index] ?
                                                        Color.white : Color.clear,
                                                        lineWidth: 3
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        
                        Button(action: saveSubscription) {
                            Text("Save Subscription")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.4, green: 0.7, blue: 1.0),
                                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.4), radius: 20, x: 0, y: 10)
                                )
                        }
                        .disabled(name.isEmpty || price.isEmpty)
                        .opacity(name.isEmpty || price.isEmpty ? 0.5 : 1.0)
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func saveSubscription() {
        guard let priceValue = Double(price.replacingOccurrences(of: ",", with: ".")),
              !name.isEmpty else {
            print("[DEBUG] Save failed - validation error")
            return
        }
        
        print("[DEBUG] Creating subscription: \(name) - $\(priceValue)")
        
        let newSubscription = Subscription(
            name: name,
            icon: selectedIcon,
            price: priceValue,
            currency: currency.rawValue,
            category: selectedCategory,
            nextPaymentDate: nextPaymentDate,
            accentColor: selectedColor
        )
        
        print("[DEBUG] Inserting subscription into modelContext")
        modelContext.insert(newSubscription)
        
        do {
            try modelContext.save()
            print("[DEBUG] Successfully saved subscription to SwiftData")
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            print("[ERROR] Failed to save subscription: \(error)")
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
        
        NotificationManager.shared.schedulePaymentReminder(for: newSubscription)
        
        print("[DEBUG] Dismissing AddSubscriptionView")
        dismiss()
    }
}

struct EditSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let subscription: Subscription
    let currency: Currency
    
    @State private var name: String
    @State private var price: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @State private var selectedCategory: String
    @State private var nextPaymentDate: Date
    
    let availableCategories = ["Entertainment", "Productivity", "Cloud Storage", "Music", "Gaming", "Fitness", "News", "Education", "Other"]
    
    init(subscription: Subscription, currency: Currency) {
        self.subscription = subscription
        self.currency = currency
        _name = State(initialValue: subscription.name)
        _price = State(initialValue: String(format: "%.2f", subscription.price))
        _selectedIcon = State(initialValue: subscription.icon)
        _selectedColor = State(initialValue: subscription.accentColor)
        _selectedCategory = State(initialValue: subscription.category)
        _nextPaymentDate = State(initialValue: subscription.nextPaymentDate)
    }
    
    let availableIcons = [
        ("star.fill", "Star"),
        ("play.tv.fill", "TV"),
        ("music.note", "Music"),
        ("icloud.fill", "Cloud"),
        ("gamecontroller.fill", "Gaming"),
        ("book.fill", "Books"),
        ("cart.fill", "Shopping"),
        ("film.fill", "Movies"),
        ("headphones", "Audio"),
        ("dumbbell.fill", "Fitness"),
        ("fork.knife", "Food"),
        ("airplane", "Travel")
    ]
    
    let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        Color(red: 0.4, green: 0.7, blue: 1.0),
        Color(red: 0.6, green: 0.4, blue: 1.0)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 16) {
                            Text("Subscription Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("", text: $name, prompt: Text("e.g., Netflix").foregroundColor(.white.opacity(0.3)))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
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
                        
                        VStack(spacing: 16) {
                            Text("Monthly Price")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Text(currency.symbol)
                                    .font(.system(size: 24, weight: .bold))
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
                                
                                TextField("", text: $price, prompt: Text("0.00").foregroundColor(.white.opacity(0.3)))
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
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
                        
                        VStack(spacing: 16) {
                            Text("Next Payment Date")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("", selection: $nextPaymentDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .tint(Color(red: 0.4, green: 0.7, blue: 1.0))
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
                        
                        VStack(spacing: 16) {
                            Text("Choose Icon")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                ForEach(availableIcons, id: \.0) { icon, label in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : .white.opacity(0.6))
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(
                                                                    selectedIcon == icon ?
                                                                    LinearGradient(
                                                                        colors: [
                                                                            Color(red: 0.4, green: 0.7, blue: 1.0),
                                                                            Color(red: 0.6, green: 0.4, blue: 1.0)
                                                                        ],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    ) :
                                                                    LinearGradient(
                                                                        colors: [Color.white.opacity(0.1)],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    ),
                                                                    lineWidth: selectedIcon == icon ? 2 : 1
                                                                )
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 16) {
                            Text("Choose Color")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                                ForEach(availableColors.indices, id: \.self) { index in
                                    Button(action: {
                                        selectedColor = availableColors[index]
                                    }) {
                                        Circle()
                                            .fill(availableColors[index])
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedColor == availableColors[index] ?
                                                        Color.white : Color.clear,
                                                        lineWidth: 3
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        
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
                        
                        Button(action: updateSubscription) {
                            Text("Update Subscription")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.4, green: 0.7, blue: 1.0),
                                                    Color(red: 0.6, green: 0.4, blue: 1.0)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.4), radius: 20, x: 0, y: 10)
                                )
                        }
                        .disabled(name.isEmpty || price.isEmpty)
                        .opacity(name.isEmpty || price.isEmpty ? 0.5 : 1.0)
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private func updateSubscription() {
        guard let priceValue = Double(price.replacingOccurrences(of: ",", with: ".")),
              !name.isEmpty else {
            print("[DEBUG] Update failed - validation error")
            return
        }
        
        print("[DEBUG] Updating subscription: \(name) - $\(priceValue)")
        
        subscription.name = name
        subscription.price = priceValue
        subscription.icon = selectedIcon
        subscription.category = selectedCategory
        subscription.nextPaymentDate = nextPaymentDate
        
        let uiColor = UIColor(selectedColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        subscription.accentColorRed = Double(red)
        subscription.accentColorGreen = Double(green)
        subscription.accentColorBlue = Double(blue)
        
        do {
            try modelContext.save()
            print("[DEBUG] Successfully updated subscription")
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        } catch {
            print("[ERROR] Failed to update subscription: \(error)")
            
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.error)
        }
        
        NotificationManager.shared.rescheduleNotification(for: subscription)
        
        print("[DEBUG] Dismissing EditSubscriptionView")
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
