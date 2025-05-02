import UIKit
import SwiftUI
import Firebase


@main
struct MyReservationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var env = AppDependencies()
    @StateObject private var appState: AppState
    @StateObject private var viewModel = AppleSignInViewModel()
    
    // Check if we're running in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    init() {
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        
        // Configure Firebase if needed (will be skipped in preview mode)
        AppDependencies.configureFirebaseIfNeeded()
        
        checkForAppUpgrade()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
                .environmentObject(env)
                .environmentObject(viewModel)
                .environmentObject(env.store)
                .environmentObject(env.tableStore)
                .environmentObject(env.resCache)
                .environmentObject(env.layoutServices)
                .environmentObject(env.clusterServices)
                .environmentObject(env.gridData)
                .environment(env.pushAlerts)
                .environmentObject(env.reservationService)
                .environmentObject(env.scribbleService)
                .environmentObject(env.tableAssignment)
                .environmentObject(env.tableService)
                .environmentObject(env.layoutCache)
                .environmentObject(env.sessionService)
                .environmentObject(env.profileService)
                .environmentObject(env.salesService)
                .environmentObject(env.dataGenerationService)
                .environmentObject(appState)
                .task { @MainActor [env] in
                    await env.loadAsyncData()
                }
        }
    }
    
    func checkForAppUpgrade() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let storedVersion = UserDefaults.standard.string(forKey: "appVersion") ?? "0"
        
        if currentVersion != storedVersion {
            // App has been upgraded, so clear stored login credentials.
            UserDefaults.standard.removeObject(forKey: "isLoggedIn")
            UserDefaults.standard.removeObject(forKey: "userIdentifier")
            
            // Optionally, you can clear other sensitive data as well.
            
            // Update the stored app version
            UserDefaults.standard.set(currentVersion, forKey: "appVersion")
            
            print("App upgraded. Cleared login credentials.")
        }
    }
}

