//
//  AppNotification.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 2/2/25.
//


import Foundation
import UserNotifications
import SwiftUI

/// A manager to handle scheduling local notifications and keeping an in‑app log.
@MainActor
final class NotificationManager: ObservableObject {
    @Published var notifications: [AppNotification] = []
    
    static let shared = NotificationManager()
        /// Adds a new notification to the in‑app log and schedules a local notification.
    
    func requestNotificationAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
        } catch {
            print("❌ Notification permission error: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func addNotification(title: String, message: String, type: NotificationType, reservation: Reservation? = nil) async {
        let newNotification = AppNotification(title: title, message: message, reservation: reservation, type: type)
        notifications.append(newNotification)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) // Debug with 3s delay
        let request = UNNotificationRequest(identifier: newNotification.id.uuidString,
                                            content: content,
                                            trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification scheduled: \(title)")
        } catch {
            print("❌ Error scheduling notification: \(error.localizedDescription)")
        }
    }
    
    
    
    /// Removes a specific notification from the in‑app log.
    @MainActor
    func removeNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
    }

    @MainActor
    func clearNotifications() {
        notifications.removeAll()
    }
}
