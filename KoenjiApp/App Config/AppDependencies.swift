import Firebase
import SwiftUI
import OSLog

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
    var backupService: FirebaseBackupService
    var pushAlerts: PushAlerts
    var reservationService: ReservationService
    var scribbleService: ScribbleService
    var listView: ListViewModel

    @Published var salesStore: SalesStore?
    @Published var salesService: SalesFirebaseService?
    
    @MainActor
    init() {
        logger.debug("Initializing app dependencies")
        
        // Configure Firebase
        FirebaseApp.configure()
        logger.info("Firebase configured")

        // Initialize dependencies
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
        self.backupService = FirebaseBackupService(
            store: store, notifsManager: NotificationManager.shared)
        self.pushAlerts = PushAlerts()
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
            emailService: emailService
        )
        self.scribbleService = ScribbleService(layoutServices: layoutServices)
        self.listView = ListViewModel(
            reservationService: reservationService,
            store: store,
            layoutServices: layoutServices
        )
        
        let salesStore = SalesStore()
        self.salesStore = salesStore
        self.salesService = SalesFirebaseService(store: salesStore)
        
        // Start listeners
        Task {
            await self.salesService?.startSalesListener()
        }
        
        logger.info("All dependencies initialized successfully")
    }
}
