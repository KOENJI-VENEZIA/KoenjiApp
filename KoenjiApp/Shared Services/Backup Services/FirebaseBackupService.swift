import FirebaseFirestore
import FirebaseStorage
import OSLog

/// An error representing a backup conflict.
enum BackupConflictError: Error, LocalizedError {
    case conflictFound(String)
    
    var errorDescription: String? {
        switch self {
        case .conflictFound(let message):
            return message
        }
    }
}

/// A service for uploading and downloading backups to Firebase Storage
class FirebaseBackupService: ObservableObject {
    @Published var isWritingToFirebase = false
    @Published var localBackupFileURL: URL? = nil
    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseBackupService")

    let db: Firestore?
    private let storage: Storage?
    private let store: ReservationStore
    let notifsManager: NotificationManager
    private var backupDirectory: String {
        #if DEBUG
        return "debugBackups"
        #else
        return "backups"
        #endif
    }
    
    /// Whether this service is in preview mode
    private let isPreview: Bool
    
    /// Initializes the backup service with the specified bucket URL
    @MainActor
    init(store: ReservationStore, notifsManager: NotificationManager = NotificationManager.shared, isPreview: Bool = false) {
        self.isPreview = isPreview
        
        if isPreview {
            // In preview mode, we don't initialize Firebase components
            self.db = nil
            self.storage = nil
        } else {
            // Normal mode with Firebase components
            self.db = Firestore.firestore()
            // Explicitly use your bucket URL
            self.storage = Storage.storage(url: "gs://koenji-app.firebasestorage.app")
        }
        
        self.store = store
        self.notifsManager = notifsManager
    }
    
    /// Saves reservations to backup
    ///
    /// This method is a no-op in preview mode
    func saveReservationsToBackup() async {
        if isPreview {
            logger.debug("Preview mode: Skipping Firebase backup")
            return
        }
        
        // Original implementation continues here...
    }
    
    /// Loads reservations from backup
    ///
    /// In preview mode, this loads mock reservations
    func loadReservationsFromBackup() async {
        if isPreview {
            logger.debug("Preview mode: Loading mock reservations")
            self.store.reservations = MockData.mockReservations
            return
        }
        
        // Original implementation continues here...
    }
}
