import UIKit
import SwiftUI

@main
struct MyReservationApp: App {
    @StateObject private var store = ReservationStore()
    @Environment(\.scenePhase) private var scenePhase


    init() {
        let _ = NavigationBarModifier()

    }

    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
                .environmentObject(store)
        }
        
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("App became active. Reloading data...")
                store.loadFromDisk()             // Load layouts
                store.loadReservationsFromDisk() // Load reservations
            }
        }
        
    }
    


}

