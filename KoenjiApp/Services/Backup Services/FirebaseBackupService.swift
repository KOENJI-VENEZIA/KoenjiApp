import FirebaseFirestore
import FirebaseStorage

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

    /// Uploads a backup file to Firebase Storage without conflict checking.
    /// - Parameters:
    ///   - fileURL: The local file URL to upload.
    ///   - completion: Completion handler with success or failure.
    func uploadBackup(fileURL: URL?, completion: @escaping (Result<Void, Error>) -> Void) {
        // Generate a timestamp string (used as part of the file name)
        guard let fileURL = fileURL else { return }
        let timestamp = DateHelper.formatDate(Date()) + "_" + DateHelper.formatTime(Date())
        let storageRef = storage.reference().child("\(backupDirectory)/\(fileURL.lastPathComponent)_\(timestamp)")

        storageRef.putFile(from: fileURL, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Checks for a conflict between a local backup (using its timestamp)
    /// and the most recent remote backup.
    /// - Parameters:
    ///   - localTimestamp: The timestamp of your local backup (when you last saved locally).
    ///   - completion: Returns `true` if a remote backup is newer.
    func checkForBackupConflict(localTimestamp: Date, completion: @escaping (Bool) -> Void) {
        listBackups { result in
            switch result {
            case .success(let fileNames):
                // Extract remote timestamps from the file names
                let remoteDates = fileNames.compactMap { self.extractDate(from: $0) }
                // If any remote backup is newer than our local backup timestamp, we have a conflict.
                if let remoteLatest = remoteDates.max(), remoteLatest > localTimestamp {
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure(let error):
                print("Error listing backups: \(error.localizedDescription)")
                completion(false) // In case of error, assume no conflict.
            }
        }
    }
    
    /// Uploads a backup file after performing a conflict check.
    /// - Parameters:
    ///   - fileURL: The local file URL to upload.
    ///   - localTimestamp: The timestamp representing the last local backup save.
    ///   - alertManager: Your alert manager used to show warning messages.
    ///   - completion: Completion handler with success or failure.
    @MainActor
    func uploadBackupWithConflictCheck(fileURL: URL?,
                                       localTimestamp: Date,
                                       alertManager: PushAlerts,
                                       completion: @escaping (Result<Void, Error>) -> Void) {
        guard let fileURL = fileURL else { return }
        checkForBackupConflict(localTimestamp: localTimestamp) { conflict in
            if conflict {
                // A newer remote backup exists.
                DispatchQueue.main.async {
                    alertManager.activeAddAlert = .error("A newer backup already exists. Do you want to override it?")
                }
                completion(.failure(BackupConflictError.conflictFound("A newer backup already exists.")))
            } else {
                // No conflict detected, so proceed with the upload.
                self.uploadBackup(fileURL: fileURL, completion: completion)
            }
        }
    }
    
    /// Lists all backup file names in the backup directory.
    /// - Parameter completion: Completion handler with the list of file names.
    func listBackups(completion: @escaping (Result<[String], Error>) -> Void) {
        let storageRef = storage.reference().child(backupDirectory)
        
        storageRef.listAll { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let fileNames = result?.items.map { $0.name } // Extract file names
                completion(.success(fileNames ?? []))
            }
        }
    }
    
    /// Downloads a backup file from Firebase Storage.
    /// - Parameters:
    ///   - fileName: The name of the backup file to download.
    ///   - localURL: The local destination for the downloaded file.
    ///   - completion: Completion handler with success or failure.
    func downloadBackup(fileName: String, to localURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference().child("\(backupDirectory)/\(fileName)")
        
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
    
    
    private func handleImportedReservations(_ importedReservations: [Reservation]) {
        print("Imported \(importedReservations.count) reservations (merge mode).")
        
        // Build a dictionary of imported reservations for quick lookup.
        // In case of duplicate IDs, choose the one with the later lastEditedOn date.
        let importedDict = Dictionary(importedReservations.map { ($0.id, $0) },
                                      uniquingKeysWith: { (existing, new) in
                                          return existing.lastEditedOn > new.lastEditedOn ? existing : new
                                      })
        
        var changesOccurred = false
        
        // Update existing reservations that need to be updated.
        for index in store.reservations.indices {
            let currentReservation = store.reservations[index]
            if let importedReservation = importedDict[currentReservation.id] {
                if importedReservation.lastEditedOn > currentReservation.lastEditedOn &&
                   importedReservation != currentReservation {
                    store.reservations[index] = importedReservation
                    changesOccurred = true
                }
            }
        }
        
        // Append new reservations not already in the store.
        let currentIDs = Set(store.reservations.map { $0.id })
        let newReservations = importedReservations.filter { !currentIDs.contains($0.id) }
        if !newReservations.isEmpty {
            store.reservations.append(contentsOf: newReservations)
            changesOccurred = true
        }
        
        if changesOccurred {
            print("Reservations updated. Now there are \(store.reservations.count) reservations.")
//             Notify the user that reservations have been updated.
            Task { @MainActor in
                await NotificationManager.shared.addNotification(title: "Prenotazioni aggiornate", message: "Nuove modifiche rilevate: sincronizzazione completata.", type: .sync)
            }
        } else {
            print("No changes detected; store.reservations remains unchanged.")
        }
    }
    
    /// Extracts a Date from a backup file name based on our naming pattern.
    /// Example file name: "ReservationsBackup.json_2025-02-02_12:45"
    private func extractDate(from fileName: String) -> Date? {
        let pattern = #"ReservationsBackup\.json_(\d{4}-\d{2}-\d{2})_(\d{2}:\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(fileName.startIndex..., in: fileName)
        if let match = regex.firstMatch(in: fileName, range: range),
           let dateRange = Range(match.range(at: 1), in: fileName),
           let timeRange = Range(match.range(at: 2), in: fileName) {
            let dateString = fileName[dateRange]
            let timeString = fileName[timeRange]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.date(from: "\(dateString) \(timeString)")
        }
        return nil
    }
}
