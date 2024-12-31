import SwiftUI

@main
struct MyReservationApp: App {
    @StateObject private var store = ReservationStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        print("App initialized.")
    }

    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
                .onAppear {
                    print("App appearing. Loading data...")
                    // Data loading already handled by ReservationStore initializer
                }
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
