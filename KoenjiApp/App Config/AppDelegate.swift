import UIKit
import Firebase
import FirebaseFunctions
import UserNotifications
import Logging

typealias LegacyNotificationHandler =
  @convention(block) (UNUserNotificationCenter, UNNotificationResponse, @escaping () -> Void) -> Void

// 2) Wrap it in a box that's @unchecked Sendable
struct LegacyNotificationHandlerBox: @unchecked Sendable {
  let block: LegacyNotificationHandler
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    var originalNotificationHandler: LegacyNotificationHandlerBox? = nil
    
    // Check if we're running in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        
        // Initialize the new logging system (once for the entire app)
        AppLog.initialize()
        
        // Enable Firebase logging in production builds only
        #if DEBUG
        AppLog.setFirebaseLogging(enabled: false)
        #else
        AppLog.setFirebaseLogging(enabled: true)
        #endif
        
        // Log using the new system
        AppLog.info("Application finished launching", category: "AppDelegate")

        // Only setup web reservation notifications if not in preview mode
        if !isPreview {
            setupWebReservationNotifications()
        } else {
            AppLog.debug("Preview mode: Skipping web reservation notifications setup")
        }
        
        // Set NotificationManager as the delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                AppLog.info("Notification permission status: \(granted ? "granted" : "denied")")
            } catch {
                AppLog.error("Failed to request notification permission: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppLog.info("Application will terminate")
        
        // Skip session updates in preview mode
        if isPreview {
            AppLog.debug("Preview mode: Skipping session update on termination")
            return
        }
        
        // Get the device UUID from UserDefaults
        if let deviceUUID = UserDefaults.standard.string(forKey: "deviceUUID"),
           var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID }) {
            session.isActive = false
            // Since we're terminating, we want this to be synchronous
            SessionStore.shared.updateSession(session)
            AppLog.debug("Session marked as inactive for device: \(deviceUUID)")
        }
    }
}

extension UNUserNotificationCenter {

    func requestNotificationQQQ1(
        options: UNAuthorizationOptions
    ) async throws -> Bool {
        try await withCheckedThrowingContinuation { cont in
            self.requestAuthorization(options: options) { success, error in
                if success {
                    cont.resume(returning: true)
                } else {
                    cont.resume(throwing: error!)
                }
            }
        }
    }
}
