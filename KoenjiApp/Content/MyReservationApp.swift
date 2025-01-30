import UIKit
import SwiftUI
import Firebase
import FirebaseAuth

@main
struct MyReservationApp: App {
    @StateObject private var store: ReservationStore
    @StateObject private var resCache: CurrentReservationsCache
    @StateObject private var reservationService: ReservationService
    @StateObject private var clusterStore: ClusterStore
    @StateObject private var clusterServices: ClusterServices
    @StateObject private var tableStore: TableStore
    @StateObject private var layoutServices: LayoutServices
    @StateObject private var gridData: GridData
    @StateObject private var appState: AppState
    @StateObject private var backupService: FirebaseBackupService
    @StateObject private var scribbleService: ScribbleService
    @State var listView: ListViewModel

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
        
        
        
        let gridData = GridData(store: localStore)
        _gridData = StateObject(wrappedValue: gridData)
        
        let backupService = FirebaseBackupService(store: localStore)
        _backupService = StateObject(wrappedValue: backupService)
        
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
            backupService: backupService,
            appState: appState
        )
        _reservationService = StateObject(wrappedValue: service)
        
        let scribbleService = ScribbleService(layoutServices: layoutServices)
        _scribbleService = StateObject(wrappedValue: scribbleService)
        
        let listView = ListViewModel(reservationService: service, store: localStore, layoutServices: layoutServices)
        _listView = State(wrappedValue: listView)
        
        authenticateUser()


    }

    var body: some Scene {
        WindowGroup {

            
            ContentViewWrapper(listView: listView)
                .environmentObject(store)
                .environmentObject(tableStore)
                .environmentObject(resCache)
                .environmentObject(layoutServices)
                .environmentObject(clusterServices)
                .environmentObject(gridData)
                .environmentObject(backupService)
                .environmentObject(appState) // Inject AppState
                .environmentObject(reservationService) // For the new service
                .environmentObject(scribbleService)


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

