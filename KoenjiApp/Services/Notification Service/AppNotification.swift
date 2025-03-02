//
//  AppNotification.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 2/2/25.
//


import Foundation
import UserNotifications
import SwiftUI
import OSLog

/// A manager to handle scheduling local notifications and keeping an in‑app log.
@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var notifications: [AppNotification] = []
    @Published var selectedReservationID: UUID?
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "NotificationManager")
    
    // Dictionary to track last notification times for each reservation and type
    private var lastNotificationTimes: [String: Date] = [:]

    static let shared = NotificationManager()
    
    private override init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }
    /// Checks if enough time has passed to send another notification
    func canSendNotification(for reservationId: UUID, type: NotificationType, minimumInterval: TimeInterval) async -> Bool {
        let key = "\(reservationId)-\(type.localized)"
        
        if let lastTime = lastNotificationTimes[key] {
            let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
            if timeSinceLastNotification < minimumInterval {
                logger.debug("Skipping notification: minimum interval not reached for reservation \(reservationId)")
                return false
            }
        }
        
        // Update the last notification time
        lastNotificationTimes[key] = Date()
        return true
    }

    /// Adds a new notification to the in‑app log and schedules a local notification.
    
    func requestNotificationAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission granted: \(granted)")
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
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
          
      // Include reservation ID in the user info if available
      if let reservation = reservation {
          content.userInfo = ["reservationID": reservation.id.uuidString]
      }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) // Debug with 3s delay
        let request = UNNotificationRequest(identifier: newNotification.id.uuidString,
                                            content: content,
                                            trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Notification scheduled: \(title)")
        } catch {
            logger.error("Error scheduling notification: \(error.localizedDescription)")
        }
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract values before entering the Task block
        guard let reservationIDString = response.notification.request.content.userInfo["reservationID"] as? String,
              let reservationID = UUID(uuidString: reservationIDString) else {
            completionHandler()
            return
        }
        let notificationIdentifier = response.notification.request.identifier

        Task {
            // Dispatch work that touches actor-isolated properties onto the main actor.
            await MainActor.run {
                self.selectedReservationID = reservationID
                self.logger.info("Notification tapped: \(notificationIdentifier)")
            }
        }
        
        completionHandler()
    }
    
    // You might also need this delegate method for when notifications are presented while app is in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound when notification arrives in foreground
        completionHandler([.banner, .sound])
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
