import Firebase
import SwiftUI
import OSLog
import FirebaseFunctions
import FirebaseStorage

/// A class that manages the dependencies of the app
///
/// This class initializes and manages the various services and stores used in the app.
/// It provides a central location for initializing and accessing all the app's dependencies.
final class AppDependencies: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppDependencies")
    // MARK: - Dependencies
    var store: ReservationStore
    var tableAssignment: TableAssignmentService
    var resCache: CurrentReservationsCache
    var tableStore: TableStore
    var layoutServices: LayoutServices
    var clusterStore: ClusterStore
    var clusterServices: ClusterServices
    var emailService: EmailService
    var gridData: GridData
    
    // Firebase-dependent services
    var backupService: FirebaseBackupService
    var pushAlerts: PushAlerts
    var reservationService: ReservationService
    var scribbleService: ScribbleService
    var listView: ListViewModel
    var profileStore: ProfileStore
    var firebaseListener: FirebaseListener

    @Published var salesStore: SalesStore
    @Published var salesService: SalesFirebaseService
    
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
                let logger = Logger(subsystem: "com.koenjiapp", category: "AppDependencies")
                logger.info("Firebase configured")
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
    
    /// Safely gets a Functions instance, returning nil in preview mode
    static func getFunctions() -> Functions? {
        if isPreviewMode {
            return nil
        }
        
        // Ensure Firebase is configured before getting Functions
        configureFirebaseIfNeeded()
        return Functions.functions()
    }
    
    /// Safely gets a Storage instance, returning nil in preview mode
    static func getStorage(url: String? = nil) -> Storage? {
        if isPreviewMode {
            return nil
        }
        
        // Ensure Firebase is configured before getting Storage
        configureFirebaseIfNeeded()
        
        if let url = url {
            return Storage.storage(url: url)
        } else {
            return Storage.storage()
        }
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
    
    @MainActor
    init() {
        logger.debug("Initializing app dependencies")
        
        // Check if we're running in preview mode
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        // Configure Firebase first in non-preview mode
        if !isPreview {
            // Regular initialization with Firebase - must be done before any Firebase services are used
//            FirebaseApp.configure()
            logger.info("Firebase configured")
        }
        
        // Create a preview-safe database reference that doesn't try to connect to Firebase
        let previewDB = isPreview ? nil : Firestore.firestore()
        
        // Create local variables for properties that need to be used during initialization
        let tempSalesStore = SalesStore()
        
        // Initialize basic dependencies that don't depend on Firebase
        self.store = ReservationStore()
        self.tableAssignment = TableAssignmentService()
        self.tableStore = TableStore(store: store)
        self.resCache = CurrentReservationsCache()
        self.layoutServices = LayoutServices(
            store: store,
            tableStore: tableStore,
            tableAssignmentService: tableAssignment
        )
        self.clusterStore = ClusterStore(
            store: store,
            tableStore: tableStore,
            layoutServices: layoutServices
        )
        self.clusterServices = ClusterServices(
            store: store,
            clusterStore: clusterStore,
            tableStore: tableStore,
            layoutServices: layoutServices
        )
        
        self.emailService = EmailService()
        self.gridData = GridData(store: store)
        self.pushAlerts = PushAlerts()
        self.profileStore = ProfileStore.shared
        self.scribbleService = ScribbleService(layoutServices: layoutServices)
        
        // Initialize Firebase-dependent services with preview-safe behavior
        self.firebaseListener = FirebaseListener(store: store)
        
        // Backup service with preview-safe behavior
        self.backupService = FirebaseBackupService(
            store: store, 
            notifsManager: NotificationManager.shared,
            isPreview: isPreview
        )
        
        // Reservation service with preview-safe behavior
        self.reservationService = ReservationService(
            store: store,
            resCache: resCache,
            clusterStore: clusterStore,
            clusterServices: clusterServices,
            tableStore: tableStore,
            layoutServices: layoutServices,
            tableAssignmentService: tableAssignment,
            backupService: backupService,
            pushAlerts: pushAlerts,
            emailService: emailService,
            firebaseListener: firebaseListener,
            isPreview: isPreview
        )
        
        // List view with preview-safe behavior
        self.listView = ListViewModel(
            reservationService: reservationService,
            store: store,
            layoutServices: layoutServices,
            isPreview: isPreview
        )
        
        // Initialize the published properties last
        self.salesStore = tempSalesStore
        self.salesService = SalesFirebaseService(
            store: tempSalesStore,
            db: previewDB
        )
        
        // Set the shared instance after all properties are initialized
        ReservationService.shared = self.reservationService
        
        // Start listeners in non-preview mode
        if !isPreview {
            // Start listeners
            Task {
                await self.salesService.startSalesListener()
                
                // Load profiles
                self.reservationService.loadProfiles()
                
                // Setup Firebase listeners
                self.reservationService.setupFirebaseListeners()
            }
            
            logger.info("Firebase services initialized")
        } else {
            // Add mock data for preview
            logger.info("Running in preview mode - using mock data")
            store.reservations = MockData.mockReservations
            ProfileStore.shared.updateProfile(MockData.mockProfile)
            ProfileStore.shared.setCurrentProfile(MockData.mockProfile)
            SessionStore.shared.sessions = MockData.mockSessions
        }
        
        logger.info("Dependencies initialization completed")
    }

    // MARK: - Preview Extension
    #if DEBUG
    /// Creates a mock instance of AppDependencies for use in previews
    @MainActor
    static func createPreviewInstance() -> AppDependencies {
        // Set the preview environment flag
        setenv("XCODE_RUNNING_FOR_PREVIEWS", "1", 1)
        
        // Create the instance (it will detect the environment flag)
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

// MARK: - Mock Implementations
class MockBackupService: BackupServiceProtocol {
    let store: ReservationStore
    
    init(store: ReservationStore) {
        self.store = store
    }
    
    func saveReservationsToBackup() async {
        // No-op for preview mode
    }
    
    func loadReservationsFromBackup() async {
        // Use mock data
        self.store.reservations = MockData.mockReservations
    }
}

class MockFirebaseListener: FirebaseListenerProtocol {
    func startReservationListener() {
        // No-op for preview mode
    }
    
    func stopReservationListener() {
        // No-op for preview mode
    }
    
    func startSessionListener() {
        // No-op for preview mode
    }
    
    func stopSessionListener() {
        // No-op for preview mode
    }
}

class MockReservationService: ReservationServiceProtocol {
    let store: ReservationStore
    let resCache: CurrentReservationsCache
    let layoutServices: LayoutServices
    
    var changedReservation: Reservation? = nil
    
    init(store: ReservationStore, resCache: CurrentReservationsCache, layoutServices: LayoutServices) {
        self.store = store
        self.resCache = resCache
        self.layoutServices = layoutServices
    }
    
    @MainActor func loadProfiles() {
        // Use mock profiles
        ProfileStore.shared.updateProfile(MockData.mockProfile)
        ProfileStore.shared.setCurrentProfile(MockData.mockProfile)
    }
    
    func setupFirebaseListeners() {
        // No-op for preview mode
    }
    
    func loadReservationsFromFirebase() {
        
    }
    
    func updateReservation(_ reservation: Reservation, newReservation: Reservation, completion: @escaping () -> Void) {
        
    }
    
    func approveWebReservation(_ reservation: Reservation) {
        
    }
    
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        return reservation
    }
}

class MockListViewModel: ListViewModelProtocol {
    let store: ReservationStore
    
    init(store: ReservationStore) {
        self.store = store
    }
}

class MockSalesService: SalesServiceProtocol {
    let store: SalesStore
    
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()
    
    init(store: SalesStore) {
        self.store = store
    }
    
    func startSalesListener() async {
        // No-op for preview mode
    }
    
    func updatePeopleFilter() {
        
    }
    
    func updateDateFilter() {
        
    }
    
    func handleEditTap(_ reservation: Reservation) {
        
    }
    
    func handleCancel(_ reservation: Reservation) {
        
    }
    
    func handleDelete(_ reservation: Reservation) {
        
    }
    
    func handleRecover(_ reservation: Reservation) {
        
    }
}

// Extend FirebaseBackupService to conform to BackupServiceProtocol
extension FirebaseBackupService: BackupServiceProtocol {}

// Extend FirebaseListener to conform to FirebaseListenerProtocol
extension FirebaseListener: FirebaseListenerProtocol {}

// Extend ReservationService to conform to ReservationServiceProtocol
extension ReservationService: ReservationServiceProtocol {}

// Extend ListViewModel to conform to ListViewModelProtocol
extension ListViewModel: ListViewModelProtocol {}

// Extend SalesFirebaseService to conform to SalesServiceProtocol
extension SalesFirebaseService: SalesServiceProtocol {}
