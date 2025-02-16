import Firebase
import SwiftUI

final class AppDependencies: ObservableObject {
    // Dependencies that are ObservableObjects can be stored as plain properties.
    var store: ReservationStore
    var tableAssignment: TableAssignmentService
    var resCache: CurrentReservationsCache
    var tableStore: TableStore
    var layoutServices: LayoutServices
    var clusterStore: ClusterStore
    var clusterServices: ClusterServices
    var gridData: GridData
    var backupService: FirebaseBackupService
    var pushAlerts: PushAlerts
    var reservationService: ReservationService
    var scribbleService: ScribbleService
    var listView: ListViewModel

    @MainActor
    init() {
        // Configure Firebase first.
        FirebaseApp.configure()

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
            pushAlerts: pushAlerts
        )
        self.scribbleService = ScribbleService(layoutServices: layoutServices)
        self.listView = ListViewModel(
            reservationService: reservationService,
            store: store,
            layoutServices: layoutServices
        )
    }
}
