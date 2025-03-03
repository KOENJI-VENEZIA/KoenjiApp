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

    let db: Firestore!
    private let storage: Storage
    private let store: ReservationStore
    let notifsManager: NotificationManager
    private var backupDirectory: String {
        #if DEBUG
        return "debugBackups"
        #else
        return "backups"
        #endif
    }
    
    /// Initializes the backup service with the specified bucket URL
    @MainActor
    init(store: ReservationStore, notifsManager: NotificationManager = NotificationManager.shared) {
        self.db = Firestore.firestore()
        // Explicitly use your bucket URL
        self.storage = Storage.storage(url: "gs://koenji-app.firebasestorage.app")
        self.store = store
        self.notifsManager = notifsManager
    }

}
