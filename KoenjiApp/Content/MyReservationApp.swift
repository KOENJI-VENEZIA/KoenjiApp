import UIKit
import SwiftUI
import Firebase
import FirebaseAuth

@main
struct MyReservationApp: App {
    @StateObject private var store = ReservationStore(tableAssignmentService: TableAssignmentService())
    @StateObject private var resCache = CurrentReservationsCache()
    @StateObject private var reservationService: ReservationService
    @StateObject private var clusterStore = ClusterStore(store: ReservationStore.shared, tableStore: TableStore.shared, layoutServices: LayoutServices(store: ReservationStore.shared, tableStore: TableStore.shared, tableAssignmentService: TableAssignmentService()))
    @StateObject private var clusterServices: ClusterServices
    @StateObject private var tableStore = TableStore(store: ReservationStore.shared)
    @StateObject private var layoutServices = LayoutServices(store: ReservationStore.shared, tableStore: TableStore.shared, tableAssignmentService: TableAssignmentService())
    


    @StateObject private var gridData = GridData(store: ReservationStore.shared)

    @StateObject private var appState = AppState()
    


    init() {
        
        
        FirebaseApp.configure()
        
        
        // 1) Create a *local* store first
        let localStore = ReservationStore(tableAssignmentService: TableAssignmentService())
        let localTableStore = TableStore(store: localStore)
        
        let resCache = CurrentReservationsCache()
        _resCache = StateObject(wrappedValue: resCache)
        
        let layoutServices = LayoutServices(store: localStore, tableStore: localTableStore, tableAssignmentService: localStore.tableAssignmentService)
        _layoutServices = StateObject(wrappedValue: layoutServices)
        
        let localClusterStore = ClusterStore(store: localStore, tableStore: localTableStore, layoutServices: layoutServices)
        // 2) Wrap it in a StateObject
        _store = StateObject(wrappedValue: localStore)
        _clusterStore = StateObject(wrappedValue: localClusterStore)
        _tableStore = StateObject(wrappedValue: localTableStore)

        let clusterService = ClusterServices(store: localStore, clusterStore: localClusterStore, tableStore: localTableStore, layoutServices: layoutServices)
        
        _clusterServices = StateObject(wrappedValue: clusterService)
        
        let appState = AppState()
        _appState = StateObject(wrappedValue: appState)
        
        // 3) Now you can safely pass `localStore` into your service
        let service = ReservationService(
            store: localStore,
            resCache: resCache,
            clusterStore: localClusterStore,
            clusterServices: clusterService,
            tableStore: localTableStore,
            layoutServices: layoutServices,
            tableAssignmentService: localStore.tableAssignmentService,
            appState: appState
        )
        _reservationService = StateObject(wrappedValue: service)
        
        authenticateUser()

    }

    var body: some Scene {
        WindowGroup {

            
            ContentViewWrapper()
                .environmentObject(store)
                .environmentObject(resCache)
                .environmentObject(tableStore)
                .environmentObject(reservationService) // For the new service
                .environmentObject(clusterServices)
                .environmentObject(layoutServices)
                .environmentObject(gridData)
                .environmentObject(appState) // Inject AppState

        }
    
        
    }
    
    func authenticateUser() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Authentication failed: \(error)")
            } else {
                print("User authenticated: \(authResult?.user.uid ?? "No UID")")
            }
        }
    }

}

