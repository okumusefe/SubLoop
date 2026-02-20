//
//  NotificationManager.swift
//  SubLoop
//
//  Created by Efe Okumuş on 17.02.2026.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func schedulePaymentReminder(for subscription: Subscription) {
        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = "Your \(subscription.name) subscription is due tomorrow ($\(String(format: "%.2f", subscription.price)))."
        content.sound = .default
        content.badge = 1
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: subscription.nextPaymentDate)
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        guard let reminderDate = Calendar.current.date(from: dateComponents),
              let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: reminderDate) else {
            return
        }
        
        let reminderComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayBefore)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
        let request = UNNotificationRequest(identifier: subscription.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotification(for subscriptionId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [subscriptionId.uuidString])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func rescheduleNotification(for subscription: Subscription) {
        cancelNotification(for: subscription.id)
        schedulePaymentReminder(for: subscription)
    }
}
