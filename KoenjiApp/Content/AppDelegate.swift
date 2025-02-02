import UIKit
import UserNotifications

import UIKit
import UserNotifications

final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            print("✅ AppDelegate initialized and didFinishLaunching called!")

            Task {
                let center = UNUserNotificationCenter.current()
                center.delegate = self
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    print("✅ Notification permission granted: \(granted)")
                } catch {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
            }
            return true
        }
        
    
    /// Ensures notifications appear when the app is in the foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📢 Received a notification in the foreground.")
        completionHandler([.banner, .sound])
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
