import UIKit
import UserNotifications
import OSLog

final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        logger.info("Application finished launching")

        // Set NotificationManager as the delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                logger.info("Notification permission status: \(granted ? "granted" : "denied")")
            } catch {
                logger.error("Failed to request notification permission: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        logger.info("Application will terminate")
        
        // Get the device UUID from UserDefaults
        if let deviceUUID = UserDefaults.standard.string(forKey: "deviceUUID"),
           var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID }) {
            session.isActive = false
            // Since we're terminating, we want this to be synchronous
            SessionStore.shared.updateSession(session)
            logger.debug("Session marked as inactive for device: \(deviceUUID)")
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
