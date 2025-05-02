import Firebase
import SwiftUI
import FirebaseFunctions
import FirebaseStorage

/// A class that manages the dependencies of the app
final class AppDependencies: ObservableObject {
    
    let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    // MARK: - Dependencies
    var store: ReservationStore
    var tableAssignment: TableAssignmentService
    var resCache: CurrentReservationsCache
    var layoutCache: LayoutCache
    var tableStore: TableStore
    var layoutServices: LayoutServices
    var clusterStore: ClusterStore
    var clusterServices: ClusterServices
    var gridData: GridData
    
    // Firebase-dependent services
    var pushAlerts: PushAlerts
    var reservationService: ReservationService
    var scribbleService: ScribbleService
    var listView: ListViewModel
    var profileStore: ProfileStore
    var deviceInfo: DeviceInfo
    var sessionService: SessionService
    var profileService: ProfileService
    var tableService: TableService
    var dataGenerationService: DataGenerationService
    var sessionManager: SessionManager
    
    var salesStore: SalesStore
    var salesService: SalesFirebaseService
    
    // MARK: - Preview Mode Detection
    
    /// Determines if the app is running in preview mode
    static var isPreviewMode: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // MARK: - Firebase Configuration
    /// Safely configures Firebase if not in preview mode
    static func configureFirebaseIfNeeded() {
        if !isPreviewMode {
            // Only configure Firebase if it hasn't been configured yet
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    }
    
    /// Safely gets a Firestore instance, returning nil in preview mode
    static func getFirestore() -> Firestore? {
        if isPreviewMode {
            return nil
        }
        
        // Ensure Firebase is configured before getting Firestore
        configureFirebaseIfNeeded()
        return Firestore.firestore()
    }
    
    /// Safely gets a Database instance, returning nil in preview mode
    static func getDatabase() -> DatabaseReference? {
        if isPreviewMode {
            return nil
        }
        
        // Ensure Firebase is configured before getting Database
        configureFirebaseIfNeeded()
        return Database.database().reference()
    }
    
    init() {
        // Initialize basic dependencies that don't depend on Firebase
        self.store = ReservationStore()
        self.tableAssignment = TableAssignmentService()
        self.tableStore = TableStore()
        self.resCache = CurrentReservationsCache()
        self.layoutCache = LayoutCache()
        self.layoutServices = LayoutServices(
            resCache: resCache,
            tableStore: tableStore,
            tableAssignmentService: tableAssignment,
            layoutCache: layoutCache
        )
        self.clusterStore = ClusterStore(
            layoutCache: layoutCache
        )
        self.clusterServices = ClusterServices(
            store: store,
            clusterStore: clusterStore,
            tableStore: tableStore,
            layoutServices: layoutServices
        )
        
        self.gridData = GridData(store: store)
        self.pushAlerts = PushAlerts()
        self.profileStore = ProfileStore.shared
        self.scribbleService = ScribbleService(layoutServices: layoutServices)
        
        if self.store.sqliteStore == nil {
            do {
                self.store.sqliteStore = try SQLiteReservationStore()
                Task { @MainActor in
                    AppLog.info("Initialized SQLite store in AppDependencies")
                }
            } catch {
                Task { @MainActor in
                    AppLog.error("Failed to initialize SQLite store: \(error)")
                }
            }
        }
        
        self.deviceInfo = DeviceInfo()
        self.sessionService = SessionService()
        self.sessionManager = SessionManager()
        self.profileService = ProfileService(store: store, deviceInfo: deviceInfo)
        self.tableService = TableService(layoutServices: layoutServices, clusterStore: clusterStore, clusterServices: clusterServices, layoutCache: layoutCache)
        self.dataGenerationService = DataGenerationService(store: store, layoutServices: layoutServices, tableStore: tableStore, resCache: resCache, layoutCache: layoutCache)
        
        let tempSalesStore = SalesStore()
        self.salesStore = tempSalesStore
        
        self.reservationService = ReservationService(
            resCache: resCache,
            clusterServices: clusterServices,
            layoutServices: layoutServices,
            tableAssignmentService: tableAssignment,
            pushAlerts: pushAlerts,
            isPreview: isPreview
        )

        let previewDB = isPreview ? nil : Firestore.firestore()
        self.salesService = SalesFirebaseService(
            store: tempSalesStore,
            db: previewDB
        )

        self.listView = ListViewModel(
            reservationService: reservationService,
            store: store,
            layoutServices: layoutServices,
            isPreview: isPreview
        )
        
        if isPreview {
            // Add mock data for preview
            Task { @MainActor in
                AppLog.info("Running in preview mode - using mock data")
            }
            store.reservations = MockData.mockReservations
            Task { @MainActor in
                ProfileStore.shared.updateProfile(MockData.mockProfile)
                ProfileStore.shared.setCurrentProfile(MockData.mockProfile)
                SessionStore.shared.sessions = MockData.mockSessions
            }
        }
    }
    
    /// Loads async data after initialization
    func loadAsyncData() async {
        self.profileService.loadProfiles()
        await sessionService.loadSessionsFromFirebase()
        
        if !isPreview {
            await resCache.loadReservationsFromFirebase(layoutServices: layoutServices)
            await layoutCache.loadLayouts()
            await tableStore.loadTablesFromFirestore()
            
            Task { @MainActor in
                AppLog.info("Cache loaded with reservation data")
            }
        }
        
        Task { @MainActor in
            AppLog.info("Dependencies initialization completed")
        }
    }

    // MARK: - Preview Extension
    #if DEBUG
    static func createPreviewInstance() -> AppDependencies {
        setenv("XCODE_RUNNING_FOR_PREVIEWS", "1", 1)
        
        return AppDependencies()
    }
    #endif
}

// MARK: - Service Protocols
protocol BackupServiceProtocol {
    func saveReservationsToBackup() async
    func loadReservationsFromBackup() async
}

protocol FirebaseListenerProtocol {
    func startReservationListener()
    func stopReservationListener()
    func startSessionListener()
    func stopSessionListener()
}

protocol ReservationServiceProtocol {
    func loadProfiles() async
    func setupFirebaseListeners()
    // Add other essential methods here as needed
}

protocol ListViewModelProtocol {
    // Add essential methods here as needed
}

protocol SalesServiceProtocol {
    func startSalesListener() async
    // Add other essential methods here as needed
}


extension ListViewModel: ListViewModelProtocol {}
extension SalesFirebaseService: SalesServiceProtocol {}
