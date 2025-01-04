import UIKit
import SwiftUI

@main
struct MyReservationApp: App {
    @StateObject private var store: ReservationStore
    @Environment(\.scenePhase) private var scenePhase


    init() {
        // Create TableAssignmentService with initial data
        let tableAssignmentService = TableAssignmentService()

        // Initialize ReservationStore
        _store = StateObject(
            wrappedValue: ReservationStore(tableAssignmentService: tableAssignmentService)
        )
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
                store.layoutManager.loadFromDisk()             // Load layouts
                store.loadReservationsFromDisk() // Load reservations
            }
        }
        
    }
    


}

