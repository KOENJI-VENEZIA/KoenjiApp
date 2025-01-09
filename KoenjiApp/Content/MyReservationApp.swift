import UIKit
import SwiftUI

@main
struct MyReservationApp: App {
    @StateObject private var store = ReservationStore(tableAssignmentService: TableAssignmentService())
    @StateObject private var reservationService: ReservationService
    @StateObject private var gridData = GridData(store: ReservationStore.shared)



    init() {
        
        // 1) Create a *local* store first
        let localStore = ReservationStore(tableAssignmentService: TableAssignmentService())

        // 2) Wrap it in a StateObject
        _store = StateObject(wrappedValue: localStore)

        // 3) Now you can safely pass `localStore` into your service
        let service = ReservationService(
            store: localStore,
            tableAssignmentService: localStore.tableAssignmentService
        )
        _reservationService = StateObject(wrappedValue: service)

    }

    var body: some Scene {
        WindowGroup {

            
            ContentViewWrapper()
                .environmentObject(store)
                .environmentObject(reservationService) // For the new service
                .environmentObject(gridData)
        }
    
        
    }
    


}

