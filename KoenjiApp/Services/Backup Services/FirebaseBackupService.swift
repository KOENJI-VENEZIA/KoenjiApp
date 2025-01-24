import FirebaseFirestore
import FirebaseStorage

/// A service for uploading and downloading backups to Firebase Storage
class FirebaseBackupService {
    private let db: Firestore
    private let storage: Storage

    /// Initializes the backup service with the specified bucket URL
    init() {
        self.db = Firestore.firestore()
        
        // Explicitly use your bucket URL
        self.storage = Storage.storage(url: "gs://koenji-app.firebasestorage.app")
    }

    /// Uploads a backup file to Firebase Storage
    /// - Parameters:
    ///   - fileURL: The local file URL to upload
    ///   - completion: Completion handler with success or failure
    func uploadBackup(fileURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let timestamp = DateHelper.formatDate(Date()) + "_" + DateHelper.formatTime(Date())
        let storageRef = storage.reference().child("backups/\(fileURL.lastPathComponent)_\(timestamp)")

        storageRef.putFile(from: fileURL, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func listBackups(completion: @escaping (Result<[String], Error>) -> Void) {
        let storageRef = storage.reference().child("backups")

        storageRef.listAll { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let fileNames = result?.items.map { $0.name } // Extract file names
                completion(.success(fileNames ?? ["error"]))
            }
        }
    }
    /// Downloads a backup file from Firebase Storage
    /// - Parameters:
    ///   - localURL: The local destination for the downloaded file
    ///   - completion: Completion handler with success or failure
    func downloadBackup(fileName: String, to localURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference().child("backups/\(fileName)")

        storageRef.write(toFile: localURL) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func downloadLatestBackup(to localURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        listBackups { result in
            switch result {
            case .success(let fileNames):
                // Sort by timestamp (assuming file names include dates and times)
                guard let latestFile = fileNames.sorted().last else {
                    completion(.failure(NSError(domain: "No backups found", code: 404, userInfo: nil)))
                    return
                }

                // Download the latest file
                self.downloadBackup(fileName: latestFile, to: localURL, completion: completion)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
