//
//  WebReservationNotificationHandler.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import SwiftUI
import UserNotifications
import FirebaseFunctions
import OSLog
import Firebase


// Extension to AppDelegate for handling web reservation notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Store the original notification handler to chain calls

    
        func setupWebReservationNotifications() {
                logger.info("Setting up web reservation notifications")
    
                // Register for remote notifications
                UIApplication.shared.registerForRemoteNotifications()
    
                // Add notification categories (Approve/Decline)
                let approveAction = UNNotificationAction(
                    identifier: "APPROVE_ACTION",
                    title: "Approve",
                    options: [.foreground]
                )
    
                let declineAction = UNNotificationAction(
                    identifier: "DECLINE_ACTION",
                    title: "Decline",
                    options: [.destructive, .foreground]
                )
    
                let webReservationCategory = UNNotificationCategory(
                    identifier: "WEB_RESERVATION",
                    actions: [approveAction, declineAction],
                    intentIdentifiers: [],
                    options: []
                )
    
                UNUserNotificationCenter.current().setNotificationCategories([webReservationCategory])
    
                // Save original notification handler if it exists
            if let existingDelegate = UNUserNotificationCenter.current().delegate as? NotificationManager {
                  // That manager has a userNotificationCenter(...) closure
                  Task { @MainActor in
                    // Wrap it
                    self.originalNotificationHandler = LegacyNotificationHandlerBox(
                      block: existingDelegate.userNotificationCenter
                    )
                  }
                }
    
                // Set this delegate to handle notification actions
                UNUserNotificationCenter.current().delegate = self
            }
    
            /// nonisolated delegate method so we can accept the non-Sendable UNNotificationResponse.
            /// Then we hop to the main actor for anything that's main-actor isolated.
            nonisolated func userNotificationCenter(
                _ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse
            ) async {
                let userInfo = response.notification.request.content.userInfo
    
                // Check if this is one of our web-reservation notifications
                guard
                    let type = userInfo["type"] as? String,
                    type == "new_web_reservation",
                    let reservationId = userInfo["reservationId"] as? String,
                    let uuid = UUID(uuidString: reservationId)
                else {
                    // Not a web reservation; forward to original handler, if any
                    await forwardToOriginalHandler(center: center, response: response)
                    return
                }
    
                logger.info("Processing web reservation notification action: \(response.actionIdentifier)")
    
                let action = response.actionIdentifier
    
                switch action {
                case "APPROVE_ACTION":
                    // Approve the reservation on main actor
                    await MainActor.run {
                        self.handleApproveReservation(uuid: uuid)
                    }
    
                case "DECLINE_ACTION":
                    // Decline the reservation on main actor
                    await MainActor.run {
                        self.handleDeclineReservation(uuid: uuid)
                    }
    
                default:
                    // User just tapped the notification
                    logger.info("Opening web reservation from notification: \(uuid)")
                    // Changing `selectedReservationID` is presumably main-actor isolated
                    await MainActor.run {
                        NotificationManager.shared.selectedReservationID = uuid
                    }
                }
            }
    
            /// Forward a notification we don't handle to the original handler (if any).
        nonisolated private func forwardToOriginalHandler(
            center: UNUserNotificationCenter,
            response: UNNotificationResponse
          ) async {
            // 1) Read the box from the main actor
            let handlerBox = await MainActor.run { self.originalNotificationHandler }
            guard let box = handlerBox else { return }
    
            // 2) Bridge the completion-based callback
            await withCheckedContinuation { continuation in
              box.block(center, response) {
                continuation.resume(returning: ())
              }
            }
          }
    
            /// MainActor-isolated approach to approving a reservation.
            @MainActor private func handleApproveReservation(uuid: UUID) {
                let dependencies = AppDependencies.shared
                guard let reservation = findReservation(with: uuid, in: dependencies) else {
                    logger.warning("Could not find reservation with ID: \(uuid)")
                    return
                }
    
                logger.info("Approving web reservation from notification: \(uuid)")
                // This call is presumably either sync or async on the main actor. If it's truly async, we can do:
                Task {
                    await dependencies.reservationService.approveWebReservation(reservation)
                }
            }
    
            /// MainActor-isolated approach to declining a reservation.
            @MainActor private func handleDeclineReservation(uuid: UUID) {
                let dependencies = AppDependencies.shared
                guard let reservation = findReservation(with: uuid, in: dependencies) else {
                    logger.warning("Could not find reservation with ID: \(uuid)")
                    return
                }
    
                logger.info("Declining web reservation from notification: \(uuid)")
    
                // If separateReservation is synchronous, call directly
                let updatedReservation = dependencies.reservationService.separateReservation(
                    reservation,
                    notesToAdd: "Declined from notification"
                )
    
                // If updateReservation is completion-based, wrap it in a continuation
                Task {
                    await withCheckedContinuation { continuation in
                        dependencies.reservationService.updateReservation(
                            reservation,
                            newReservation: updatedReservation
                        ) {
                            continuation.resume(returning: ())
                        }
                    }
                }
            }
    
        private func findReservation(with id: UUID, in dependencies: AppDependencies) -> Reservation? {
            return dependencies.store.reservations.first { $0.id == id }
        }
    
        // Register device for push notifications
        // Register device token with completely detached task
        func registerDeviceWithFirebaseSafely(token: String, deviceId: String) {
            // Check if we're running in preview mode
            if AppDependencies.isPreviewMode {
                logger.debug("Preview mode: Skipping device registration with Firebase")
                return
            }
            
            // Create a fire-and-forget Task that's completely detached from calling context
            // This avoids crossing any actor boundaries with the Firebase result
            Task.detached {
                do {
                    let userId = UserDefaults.standard.string(forKey: "userIdentifier") ?? deviceId
    
                    let data: [String: Any] = [
                        "token": token,
                        "deviceId": deviceId,
                        "userId": userId
                    ]
    
                    // Use the safe Firebase initialization method
                    guard let functions = AppDependencies.getFunctions() else {
                        // This should never happen since we already checked for preview mode
                        return
                    }
    
                    // Log from within the detached task
                    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseTask")
                    logger.info("Registering device token with Firebase")
    
                    // Since this entire Task is detached, the non-Sendable result stays within
                    // the context of this task and never needs to cross boundaries
                    _ = try await functions.httpsCallable("registerDeviceToken").call(data)
    
                    logger.info("Device successfully registered for push notifications")
                } catch {
                    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseTask")
                    logger.error("Error registering device: \(error.localizedDescription)")
                }
            }
        }
    
            // Handle notification registration failures
            func application(
                _ application: UIApplication,
                didFailToRegisterForRemoteNotificationsWithError error: Error
            ) {
                logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
            }
    
            // Register device for push notifications
            func application(
                _ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
            ) {
                // Convert token to string
                let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
                let token = tokenParts.joined()
    
                logger.info("Device registered for push notifications with token: \(token)")
    
                // Generate a unique device ID if not already stored
                let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
                // Register with Firebase using fire-and-forget approach
                registerDeviceWithFirebaseSafely(token: token, deviceId: deviceUUID)
            }
        
}

// Add shared instance to AppDependencies for easier access
extension AppDependencies {
    // Private static instance to implement singleton pattern
    nonisolated(unsafe) private static var _shared: AppDependencies?
    
    // Initialize the shared instance at app launch
    static func initializeSharedInstance(_ instance: AppDependencies) {
        _shared = instance
    }
    
    // Access the shared instance safely - this approach doesn't rely on @MainActor
    static var shared: AppDependencies {
        // Check if we have already stored a reference
        if let existing = _shared {
            return existing
        }
        
        // If we don't have a shared instance yet, that's a serious error
        // Log it and return a no-op implementation that won't crash
        let logger = Logger(subsystem: "com.koenjiapp", category: "AppDependencies")
        logger.error("Fatal: Failed to access shared AppDependencies. App must call initializeSharedInstance during launch")
        
        // Instead of potentially crashing, we'll force a main thread operation
        // This is a last resort and should never happen in normal operation
        DispatchQueue.main.async {
            // Post a notification that can be observed to help debug
            NotificationCenter.default.post(
                name: Notification.Name("AppDependencies.MissingSharedInstance"),
                object: nil
            )
        }
        
        fatalError("AppDependencies.shared accessed before initialization")
    }
}
