import UIKit
import SwiftUI
import Firebase

@main
struct MyReservationApp: App {
    @StateObject private var env = AppDependencies()
    @StateObject private var appState: AppState
    
    init() {
       
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
    }
    
    var body: some Scene {
        WindowGroup {
            
            ContentViewWrapper()
                .environmentObject(env)
                .environmentObject(env.store)
                .environmentObject(env.tableStore)
                .environmentObject(env.resCache)
                .environmentObject(env.layoutServices)
                .environmentObject(env.clusterServices)
                .environmentObject(env.gridData)
                .environmentObject(env.backupService)
                .environment(env.pushAlerts)
                .environmentObject(env.reservationService)
                .environmentObject(env.scribbleService)
                .environmentObject(env.tableAssignment)
                .environmentObject(appState)
        }
    }
}

