import FirebaseFirestore
import FirebaseStorage

/// A service for uploading and downloading backups to Firebase Storage
class FirebaseBackupService: ObservableObject {
    private let db: Firestore
    private let storage: Storage
    private let store: ReservationStore
    /// Initializes the backup service with the specified bucket URL
    init(store: ReservationStore) {
        self.db = Firestore.firestore()
        
        // Explicitly use your bucket URL
        self.storage = Storage.storage(url: "gs://koenji-app.firebasestorage.app")
        self.store = store
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
    
    @MainActor
    func restoreBackup(fileName: String, completion: @escaping () -> Void) {
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        downloadBackup(fileName: fileName, to: localURL) { result in
            switch result {
            case .success:
                print("Backup downloaded successfully to: \(localURL)")
                
                self.importReservations(from: localURL)
                
                DispatchQueue.main.async {
                    completion() // Notify when done
                }
                
            case .failure(let error):
                print("Error downloading backup: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion() // Call completion to avoid being stuck
                }
            }
        }
    }
    
    private func importReservations(from url: URL) {
        print("Attempting to import file at URL: \(url)")

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let reservations = try decoder.decode([Reservation].self, from: data)
            print("Reservations decoded successfully: \(reservations.count) entries.")

            handleImportedReservations(reservations)
        } catch let decodingError as DecodingError {
            print("Decoding error: \(decodingError)")
        } catch {
            print("Failed to import reservations: \(error.localizedDescription)")
        }
    }

    private func handleImportedReservations(_ reservations: [Reservation]) {
        // Integrate the imported reservations into your app's data
        print("Imported \(reservations.count) reservations:")
        reservations.forEach { print($0) }

        // Example: Save them to your ReservationService
        store.reservations.append(contentsOf: reservations)
    }

}
