//
//  ReservationService.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation
import UIKit
import FirebaseFirestore
import Firebase
import FirebaseStorage
import SwiftUI
import OSLog

/// A service class responsible for high-level operations on reservations.
/// This class interacts with the `ReservationStore` for managing reservation data.
class ReservationService: ObservableObject {
    // MARK: - Dependencies
    let store: ReservationStore
    private let resCache: CurrentReservationsCache
    private let clusterStore: ClusterStore
    private let clusterServices: ClusterServices
    private let tableStore: TableStore
    let layoutServices: LayoutServices
    private let tableAssignmentService: TableAssignmentService
    let backupService: FirebaseBackupService
    private let pushAlerts: PushAlerts
    let emailService: EmailService
    private var imageCache: [UUID: UIImage] = [:]
    let notifsManager: NotificationManager
    @Published var changedReservation: Reservation? = nil
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationService")
    
    var reservationListener: ListenerRegistration?
    var sessionListener: ListenerRegistration?
    var webReservationListener: ListenerRegistration?
    
    // MARK: - Initializer
    @MainActor
    init(store: ReservationStore, resCache: CurrentReservationsCache, clusterStore: ClusterStore, clusterServices: ClusterServices, tableStore: TableStore, layoutServices: LayoutServices, tableAssignmentService: TableAssignmentService, backupService: FirebaseBackupService, pushAlerts: PushAlerts, emailService: EmailService, notifsManager: NotificationManager = NotificationManager.shared) {
        self.store = store
        self.resCache = resCache
        self.clusterStore = clusterStore
        self.clusterServices = clusterServices
        self.tableStore = tableStore
        self.layoutServices = layoutServices
        self.tableAssignmentService = tableAssignmentService
        self.backupService = backupService
        self.pushAlerts = pushAlerts
        self.emailService = emailService
        self.notifsManager = notifsManager
        
        self.layoutServices.loadFromDisk()
        self.clusterServices.loadClustersFromDisk()
        self.migrateDatabaseIfNeeded()
        
        self.startReservationsListener()
        self.startSessionListener()
        self.startWebReservationListener()


        self.loadReservationsFromSQLite()
        self.loadSessionsFromSQLite()
        
        let today = Calendar.current.startOfDay(for: Date())
        self.resCache.preloadDates(around: today, range: 5, reservations: self.store.reservations)
//        self.preloadActiveReservationCache(around: today, forDaysBefore: 5, afterDays: 5)
    }
    
    deinit {
        reservationListener?.remove()
        sessionListener?.remove()
        webReservationListener?.remove()
        }
    
    @MainActor
    func migrateDatabaseIfNeeded() {
        do {
            // Get the current database version.
            let currentVersion = try SQLiteManager.shared.db.scalar("PRAGMA user_version") as? Int64 ?? 0
            let targetVersion: Int64 = 2  // Increment this whenever you change your schema
            
            if currentVersion < targetVersion {
                // Example: For version 2, add the sessionUUID column to sessions table.
                if currentVersion < 2 {
                    // Execute raw SQL to add a new column.
                    try SQLiteManager.shared.db.run("ALTER TABLE sessions ADD COLUMN uuid TEXT")
                    logger.info("Migration: Added uuid column to sessions table.")
                }
                
                // Update the database version.
                try SQLiteManager.shared.db.run("PRAGMA user_version = \(targetVersion)")
            }
        } catch {
            logger.error("Database migration error: \(error)")
        }
    }
    
    // MARK: - Placeholder Methods for CRUD Operations

    @MainActor
    func upsertSession(_ session: Session) {
        SQLiteManager.shared.insertSession(session)
        
        DispatchQueue.main.async {
            SessionStore.shared.sessions.append(session)
            SessionStore.shared.sessions = Array(SessionStore.shared.sessions)
        }
        
        // Push changes to Firestore
        #if DEBUG
        let dbRef = backupService.db.collection("sessions")
        #else
        let dbRef = backupService.db.collection("sessions_release")
        #endif
        let data = convertSessionToDictionary(session: session)
            // Using the reservation’s UUID string as the document ID:
        dbRef.document(session.uuid).setData(data) { [self] error in
                if let error = error {
                    self.logger.error("Error pushing session to Firebase: \(error)")
                } else {
                    self.logger.debug("Session pushed to Firebase successfully.")
                }
            }
        
    }
    
    /// Adds a new reservation.
    /// Assumes the reservation's `tables` have already been assigned
    /// (manually or automatically). If not, it will be unassigned.
    /// This method simply appends it and marks its tables as occupied.
    @MainActor
    func addReservation(_ reservation: Reservation) {
        // Update Database
        SQLiteManager.shared.insertReservation(reservation)

        // Manage in-store memory
        DispatchQueue.main.async {
            self.resCache.addOrUpdateReservation(reservation)
            self.store.reservations.append(reservation)
            self.store.reservations = Array(self.store.reservations)
            self.changedReservation = reservation
            reservation.tables.forEach { self.layoutServices.markTable($0, occupied: true) }
            self.invalidateClusterCache(for: reservation)
            self.logger.debug("Added reservation \(reservation.id) with tables \(reservation.tables)")
        }
        
        // Push changes to Firestore with the improved dictionary conversion
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        let data = convertReservationToDictionary(reservation: reservation)
        
        // Using the reservation's UUID string as the document ID:
        dbRef.document(reservation.id.uuidString).setData(data) { error in
            if let error = error {
                self.logger.error("Error pushing reservation to Firebase: \(error)")
            } else {
                self.logger.debug("Reservation pushed to Firebase successfully.")
            }
        }
    }
    
    @MainActor
    func addReservations(_ reservations: [Reservation]) {
        for reservation in reservations {
            SQLiteManager.shared.insertReservation(reservation)
        }
    }
    
    @MainActor
    private func convertSessionToDictionary(session: Session) -> [String: Any] {
        return [
            "id": session.id,
            "uuid": session.uuid,
            "userName": session.userName,
            "isEditing": session.isEditing,
            "lastUpdate": session.lastUpdate.timeIntervalSince1970,
            "isActive": session.isActive
        ]
    }
    
    @MainActor
    private func convertReservationToDictionary(reservation: Reservation) -> [String: Any] {
        // Convert tables to a simpler format that Firestore can handle better
        let tableIds = reservation.tables.map { $0.id }
        
        // Create a thread-safe copy for Firestore
        var dict: [String: Any] = [
            "id": reservation.id.uuidString,
            "name": reservation.name,
            "phone": reservation.phone,
            "numberOfPersons": reservation.numberOfPersons,
            "dateString": reservation.dateString,
            "category": reservation.category.rawValue,
            "startTime": reservation.startTime,
            "endTime": reservation.endTime,
            "acceptance": reservation.acceptance.rawValue,
            "status": reservation.status.rawValue,
            "reservationType": reservation.reservationType.rawValue,
            "group": reservation.group,
            "tableIds": tableIds,
            "tables": reservation.tables.map { table in
                return [
                    "id": table.id,
                    "name": table.name,
                    "maxCapacity": table.maxCapacity
                ]
            },
            "creationDate": reservation.creationDate.timeIntervalSince1970,
            "lastEditedOn": reservation.lastEditedOn.timeIntervalSince1970,
            "isMock": reservation.isMock,
            "colorHue": reservation.colorHue,
            "preferredLanguage": reservation.preferredLanguage
        ]
        
        // Handle optional values separately and safely
        if let notes = reservation.notes {
            dict["notes"] = notes
        } else {
            dict["notes"] = NSNull()
        }
        
        if let assignedEmoji = reservation.assignedEmoji {
            dict["assignedEmoji"] = assignedEmoji
        } else {
            dict["assignedEmoji"] = NSNull()
        }
        
        if let imageData = reservation.imageData {
            dict["imageData"] = imageData
        } else {
            dict["imageData"] = NSNull()
        }
        
        return dict
    }

    /// Updates an existing reservation, refreshes the cache, and reassigns tables if needed.
    @MainActor
    func updateReservation(_ oldReservation: Reservation, newReservation: Reservation? = nil, at index: Int? = nil, shouldPersist: Bool = true, completion: @escaping () -> Void) {
        // Remove from active cache
        self.invalidateClusterCache(for: oldReservation)
        resCache.removeReservation(oldReservation)
        
        let updatedReservation = newReservation ?? oldReservation

        DispatchQueue.main.async {
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == oldReservation.id })

            guard let reservationIndex else {
                self.logger.error("Error: Reservation with ID \(oldReservation.id) not found.")
                return
            }
            
            SQLiteManager.shared.insertReservation(updatedReservation)
            
            self.store.reservations[reservationIndex] = updatedReservation
            self.store.reservations = Array(self.store.reservations)
            self.changedReservation = updatedReservation
            self.logger.info("Changed changedReservation, should update UI...")

            let oldReservation = self.store.reservations[reservationIndex]
            
            // 🔹 Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables.map { $0.id })
            let newTableIDs = Set(updatedReservation.tables.map { $0.id })
            
            if oldTableIDs != newTableIDs {
                self.logger.debug("Table change detected for reservation \(updatedReservation.id). Updating tables...")

                // Unmark only if tables have changed
                for tableID in oldTableIDs.subtracting(newTableIDs) {
                    if let table = oldReservation.tables.first(where: { $0.id == tableID }) {
                        self.layoutServices.unmarkTable(table)
                    }
                }

                // Mark only new tables that weren't already assigned
                for tableID in newTableIDs.subtracting(oldTableIDs) {
                    if let table = updatedReservation.tables.first(where: { $0.id == tableID }) {
                        self.layoutServices.markTable(table, occupied: true)
                    }
                }
                
                // Invalidate cluster cache only if tables changed
                self.invalidateClusterCache(for: updatedReservation)
            } else if newTableIDs.isEmpty {
                oldReservation.tables.forEach { self.layoutServices.unmarkTable($0) }
            } else {
                self.logger.info("No table change detected for reservation \(updatedReservation.id). Skipping table update.")
            }

            // Update the reservation in the store
            self.resCache.addOrUpdateReservation(updatedReservation)
            if shouldPersist {
                self.store.finalizeReservation(updatedReservation)
                // Update database
                // Pushes to Firestore with the improved dictionary conversion
                #if DEBUG
                let dbRef = self.backupService.db.collection("reservations")
                #else
                let dbRef = self.backupService.db.collection("reservations_release")
                #endif
                
                let data = self.convertReservationToDictionary(reservation: updatedReservation)
                
                // Using the reservation's UUID string as the document ID:
                dbRef.document(updatedReservation.id.uuidString).setData(data) { error in
                    if let error = error {
                        self.logger.error("Error pushing reservation to Firebase: \(error)")
                    } else {
                        self.logger.debug("Reservation pushed to Firebase successfully.")
                    }
                }
            }
            self.logger.debug("Updated reservation \(updatedReservation.id).")
        }

        // Finalize and save
        completion()
    }
    
    @MainActor
    func updateAllReservationsInFirestore() async {
        logger.info("Beginning update of all reservations in Firestore...")
        
        let allReservations = self.store.reservations
        
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        var successCount = 0
        var errorCount = 0
        
        for reservation in allReservations {
            do {
                // Since convertReservationToDictionary is also @MainActor, we're staying on the same actor
                let data = convertReservationToDictionary(reservation: reservation)
                
                // Create a properly isolated copy of the dictionary for Firestore
                try await Task {
                    try await dbRef.document(reservation.id.uuidString).setData(data)
                }.value
                
                successCount += 1
                logger.debug("Updated reservation \(reservation.id) in Firestore")
            } catch {
                errorCount += 1
                logger.error("Failed to update reservation \(reservation.id) in Firestore: \(error)")
            }
        }
        
        logger.info("Completed updating all reservations in Firestore. Success: \(successCount), Errors: \(errorCount)")
    }

    
    
    @MainActor
    func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
                    // do actual saving logic here
                    updatedReservation.tables = assignedTables
                    updatedReservation.reservationType = .inAdvance
                    updatedReservation.status = .pending
                    self.updateReservation(updatedReservation) {
                        self.logger.info("Updated reservations.")
                    }

                }
            case .failure(let error):
                switch error {
                    case .noTablesLeft:
                    pushAlerts.alertMessage = String(localized: "Non ci sono tavoli disponibili.")
                    case .insufficientTables:
                    pushAlerts.alertMessage = String(localized: "Non ci sono abbastanza tavoli per la prenotazione.")
                    case .tableNotFound:
                    pushAlerts.alertMessage = String(localized: "Tavolo selezionato non trovato.")
                    case .tableLocked:
                    pushAlerts.alertMessage = String(localized: "Il tavolo scelto è occupato o bloccato.")
                    case .unknown:
                    pushAlerts.alertMessage = String(localized: "Errore sconosciuto.")
                    }
                    pushAlerts.showAlert = true
            }
        }
    }
    

    @MainActor
    func clearAllDataFromFirestore(completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        #if DEBUG
        let reservationsRef = db.collection("reservations")
        #else
        let reservationsRef = db.collection("reservations_release")
        #endif
        reservationsRef.getDocuments { snapshot, error in
            if let error = error {
                self.logger.error("Error fetching documents for deletion: \(error)")
                completion(error)
                return
            }
            
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            
            let batch = db.batch()
            snapshot.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    self.logger.error("Error committing batch deletion: \(error)")
                } else {
                    self.logger.debug("Successfully deleted all reservations from Firestore.")
                }
                completion(error)
            }
        }
    }
    
    @MainActor func clearAllData() {
        store.reservations.removeAll() // Clear in-memory reservations
        
        SQLiteManager.shared.deleteAllReservations()
        flushAllCaches() // Clear any cached layouts or data
        
        clearAllDataFromFirestore { error in
               if let error = error {
                   self.logger.error("Error clearing Firestore data: \(error)")
               } else {
                   self.logger.debug("All Firestore data cleared successfully.")
               }
           }
        
        logger.info("ReservationService: All data has been cleared.")
    }
    
    /// Fetches reservations for a specific date.
    /// - Parameter date: The date for which to fetch reservations.
    /// - Returns: A list of reservations for the given date.
    func fetchReservations(on date: Date) -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date) // Use centralized helper
        return store.reservations.filter { $0.dateString == targetDateString }
    }
    
    /// Retrieves reservations for a specific category on a given date.
    func fetchReservations(on date: Date, for category: Reservation.ReservationCategory) -> [Reservation] {
        fetchReservations(on: date).filter { $0.category == category }
    }
    
    // MARK: - Cluster Cache Invalidation

       /// Invalidates the cluster cache for the given reservation.
       private func invalidateClusterCache(for reservation: Reservation) {
           guard let reservationDate = reservation.normalizedDate else {
               self.logger.error("Failed to parse dateString \(reservation.normalizedDate ?? Date()). Cache invalidation skipped.")
               return
           }
           self.clusterStore.invalidateClusterCache(for: reservationDate, category: reservation.category)
       }
        
    
    // MARK: - Methods for Queries
    
    
    
    /// Retrieves reservations by category.
    /// - Parameter category: The reservation category.
    /// - Returns: A list of reservations matching the category.
    func getReservations(by category: Reservation.ReservationCategory) -> [Reservation] {
        // Retrieve all reservations from the ReservationStore
        let allReservations = store.getReservations()
        
        // Filter reservations matching the specified category
        let filteredReservations = allReservations.filter { $0.category == category }
        
        // Return the filtered list
        return filteredReservations
    }
    
    // MARK: - Methods for Database Persistence
    
    @MainActor
    func loadReservationsFromSQLite() {
        withAnimation {
            backupService.isWritingToFirebase = true
        }
        
        let reservations = SQLiteManager.shared.fetchReservations()
        store.reservations = reservations
        
        logger.info("Reservations loaded from SQLite successfully.")
        logger.debug("Loaded n. reservations: \(self.store.reservations.count)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                self.backupService.isWritingToFirebase = false
            }
        }
    }
    
    @MainActor
    func loadSessionsFromSQLite() {
        withAnimation {
            backupService.isWritingToFirebase = true
        }

        let sessions = SQLiteManager.shared.fetchSessions()
        SessionStore.shared.sessions = sessions
        
        logger.info("Sessions loaded from SQLite successfully.")
        logger.debug("Loaded n. sessions: \(SessionStore.shared.sessions.count)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                self.backupService.isWritingToFirebase = false
            }
        }
    }
    
    /// Downloads the backup file from Firebase Storage and migrates it.
    @MainActor
    func migrateJSONBackupFromFirebase() {
        // Create a reference to your backup file using its gs:// URL.
        let backupRef = Storage.storage().reference(forURL: "gs://koenji-app.firebasestorage.app/debugBackups/ReservationsBackup.json_2025-01-30_19:02")
        
        // Define a maximum download size (e.g., 10 MB).
        let maxDownloadSize: Int64 = 10 * 1024 * 1024
        
        // Fetch the data.
        backupRef.getData(maxSize: maxDownloadSize) { data, error in
            if let error = error {
                self.logger.error("Error downloading JSON backup: \(error)")
                return
            }
            
            guard let data = data else {
                self.logger.warning("No data returned from Firebase Storage")
                return
            }
            
            // Now migrate using the downloaded data.
            self.migrateJSONBackup(from: data)
        }
    }

    /// Decodes the JSON backup data and inserts each reservation.
    @MainActor
    func migrateJSONBackup(from data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let reservationsFromJSON = try decoder.decode([Reservation].self, from: data)
            
            // Insert each reservation into SQLite and push to Firebase if needed.
            insertReservationsAndPushToFirebase(reservationsFromJSON)
            
        } catch {
            self.logger.error("Error decoding JSON backup: \(error)")
        }
    }
    
    @MainActor
    func insertReservationsAndPushToFirebase(_ reservations: [Reservation]) {
        // Optionally, wrap this in a SQLite transaction if you have many records.
        for reservation in reservations {
            // Insert into SQLite:
            SQLiteManager.shared.insertReservation(reservation)
            
            // Push to Firebase:
            #if DEBUG
            let dbRef = Firestore.firestore().collection("reservations")
            #else
            let dbRef = Firestore.firestore().collection("reservations_release")
            #endif
            let data = convertReservationToDictionary(reservation: reservation)
            dbRef.document(reservation.id.uuidString).setData(data) { error in
                if let error = error {
                    self.logger.error("Error pushing reservation \(reservation.id) to Firebase: \(error)")
                } else {
                    self.logger.debug("Reservation \(reservation.id) migrated successfully to Firebase.")
                }
            }
        }
    }
    
    // MARK: - Helper Methods (Optional)
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(store.reservationsFileName)
    }
}

// MARK: - Mock Data
extension ReservationService {
    /// Loads two sample reservations for demonstration purposes.
    @MainActor
    private func mockData() {
        layoutServices.setTables(tableStore.baseTables)
        self.logger.debug("Tables populated in mockData: \(self.layoutServices.tables.map { $0.name })")
        
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
            dateString: DateHelper.formatFullDate(Date()), // Use today
            category: .lunch,
            startTime: "12:00",
            endTime: "13:45",
            acceptance: .confirmed,
            status: .pending,
            reservationType: .inAdvance,
            group: false,
            notes: "Birthday",
            isMock: true
        )
        
        let mockReservation2 = Reservation(
            name: "Bob",
            phone: "+33 98765432101",
            numberOfPersons: 4,
            dateString: DateHelper.formatFullDate(Date()), // Use today
            category: .dinner,
            startTime: "19:30",
            endTime: "21:45",
            acceptance: .confirmed,
            status: .pending,
            reservationType: .inAdvance,
            group: false,
            notes: "Allergic to peanuts",
            isMock: true
        )
        
        addReservation(mockReservation1)
        addReservation(mockReservation2)
        
    }
}

extension ReservationService {
    // MARK: - Test Data
    
    @MainActor
    func generateReservations(
        daysToSimulate: Int,
        force: Bool = false,
        startFromLastSaved: Bool = true
    ) async {
        // 1. Determine start date
        var startDate = Calendar.current.startOfDay(for: Date())

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                guard let lhsDate = lhs.startTimeDate, let rhsDate = rhs.startTimeDate else {
                    return false
                }
                return lhsDate < rhsDate
            }) {
                if let lastReservationDate = maxReservation.startTimeDate,
                   let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastReservationDate) {
                    startDate = nextDay
                }
            }
        }

        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
            self.logger.warning("Required resources are missing. Reservation generation aborted.")
            return
        }

        logger.info("Generating reservations for \(daysToSimulate) days with realistic variance (closed on Mondays).")

        // 3. Perform parallel reservation generation
        for dayOffset in 0..<daysToSimulate {
               await self.generateReservationsForDay(
                   dayOffset: dayOffset,
                   startDate: startDate,
                   names: names,
                   phoneNumbers: phoneNumbers,
                   notes: notes
               )
           }

        // 4. Save data to disk after all tasks complete
        self.resCache.preloadDates(around: startDate, range: daysToSimulate, reservations: store.reservations)
            self.layoutServices.saveToDisk()
        self.logger.info("Finished generating reservations.")
    }

    @MainActor
    private func generateReservationsForDay(
        dayOffset: Int,
        startDate: Date,
        names: [String],
        phoneNumbers: [String],
        notes: [String]
    ) async {
        let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)!
        let dayOfWeek = Calendar.current.component(.weekday, from: reservationDate)

        // Skip Mondays
        if dayOfWeek == 2 {
            self.logger.info("Skipping Monday: \(reservationDate)")
            return
        }

        let maxDailyReservations = Int.random(in: 10...30)
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 14)))
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 22)))

        while totalGeneratedReservations < maxDailyReservations && !availableTimeSlots.isEmpty {
            guard let startTime = availableTimeSlots.min() else { break }
            availableTimeSlots.remove(startTime)

            let numberOfPersons = self.generateWeightedGroupSize()
            let durationMinutes: Int = {
                if numberOfPersons <= 2 { return Int.random(in: 90...105) }
                if numberOfPersons >= 10 { return Int.random(in: 120...150) }
                return 105
            }()

            let endTime = self.roundToNearestFiveMinutes(
                Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!
            )

            if let nextSlot = availableTimeSlots.min(), nextSlot < endTime.addingTimeInterval(600) {
                availableTimeSlots.remove(nextSlot)
            }

            let category: Reservation.ReservationCategory = Calendar.current.component(.hour, from: startTime) < 15 ? .lunch : .dinner
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

            let reservation = Reservation(
                id: UUID(),
                name: names.randomElement()!,
                phone: phoneNumbers.randomElement()!,
                numberOfPersons: numberOfPersons,
                dateString: dateString,
                category: category,
                startTime: startTimeString,
                endTime: DateHelper.timeFormatter.string(from: endTime),
                acceptance: .confirmed,
                status: .pending,
                reservationType: .inAdvance,
                group: Bool.random(),
                notes: notes.randomElement(),
                tables: [],
                creationDate: Date(),
                isMock: false
            )

            
            // Offload table assignment and reservation updates to the background thread


                await MainActor.run {
                let assignmentResult = self.layoutServices.assignTables(for: reservation, selectedTableID: nil)
                    switch assignmentResult {
                    case .success(let assignedTables):
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        
                    let key = self.layoutServices.keyFor(date: reservationDate, category: category)
                    
                    if self.layoutServices.cachedLayouts[key] == nil {
                        self.layoutServices.cachedLayouts[key] = self.tableStore.baseTables
                    }
                        guard let reservationStart = reservation.startTimeDate,
                              let reservationEnd = reservation.endTimeDate else { break }
                        
                        assignedTables.forEach { self.layoutServices.unlockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                        self.store.finalizeReservation(updatedReservation)

                        if !self.store.reservations.contains(where: { $0.id == updatedReservation.id }) {
                            self.resCache.addOrUpdateReservation(updatedReservation)
                            self.store.reservations.append(updatedReservation)
                            self.updateReservation(updatedReservation) {
                                self.logger.info("Generated reservation: \(updatedReservation.name)")
                            }
                        }
                    case .failure(let error):
                        // Show an alert message based on `error`.
                        switch error {
                        case .noTablesLeft:
                             print(String(localized: "Non ci sono tavoli disponibili."))
                        case .insufficientTables:
                            print(String(localized: "Non ci sono abbastanza tavoli per la prenotazione."))
                        case .tableNotFound:
                            print(String(localized: "Tavolo selezionato non trovato."))
                        case .tableLocked:
                            print(String(localized: "Il tavolo scelto è occupato o bloccato."))
                        case .unknown:
                            print(String(localized: "Errore sconosciuto."))
                        }
                        
                }
                    
                
            }
            
            totalGeneratedReservations += 1

        }
    }

    private func generateTimeSlots(for date: Date, range: (Int, Int)) -> [Date] {
        var slots: [Date] = []
        for hour in range.0..<range.1 {
            for minute in stride(from: 0, to: 60, by: 5) { // Step of 5 minutes
                if let slot = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    slots.append(slot)
                }
            }
        }
        return slots
    }
    
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }

    private func generateWeightedGroupSize() -> Int {
        let random = Double.random(in: 0...1)
        switch random {
        case 0..<0.5: return Int.random(in: 2...3) // 70% chance for groups of 2–5
        case 0.5..<0.7: return Int.random(in: 4...5)
        case 0.7..<0.8: return Int.random(in: 6...7) // 20% chance for groups of 6–8
        case 0.8..<0.95: return Int.random(in: 8...9)
        case 0.95..<0.99: return Int.random(in: 9...12)
        default: return Int.random(in: 13...14) //
        }
    }
    
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(String(describing: folder))/\(fileName)" : fileName
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "txt") else {
            self.logger.warning("Failed to load \(fileName) from folder \(String(describing: folder)).")
            return []
        }
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            self.logger.debug("Loaded \(lines.count) lines from \(fileName) (folder: \(String(describing: folder))).")
            return lines
        } catch {
            self.logger.error("Error reading \(fileName): \(error)")
            return []
        }
    }
    
    @MainActor
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    
                    let randomTable = self.layoutServices.tables.randomElement()!
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
                    let layoutServices = self.layoutServices // Capture layoutServices explicitly
                    Task {
                        let result = layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        self.logger.debug("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(String(describing: result))")
                    }
                }
            } catch {
                self.logger.error("Task.sleep encountered an error: \(error)")
            }
        }
    }
    
   
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            self.logger.warning("Invalid reservation date or time for updating adjacency counts.")
            return
        }

        // Get active tables for the reservation's layout
        let activeTables = layoutServices.getTables(for: reservationDate, category: reservation.category)

        // Iterate over all tables in the reservation
        for table in reservation.tables {
            let adjacentTables = layoutServices.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables)
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id}) {
                layoutServices.tables[index].adjacentCount = adjacentTables.adjacentCount
            }
            // Calculate adjacent tables with shared reservations
            let sharedTables = layoutServices.isAdjacentWithSameReservation(for: table, combinedDateTime: combinedDateTime, activeTables: activeTables)

            // Update `activeReservationAdjacentCount` for this table
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id }) {
                layoutServices.tables[index].activeReservationAdjacentCount = sharedTables.count
            }

            // Update in the cached layout
            let key = layoutServices.keyFor(date: reservationDate, category: reservation.category)
            if let cachedIndex = layoutServices.cachedLayouts[key]?.firstIndex(where: { $0.id == table.id }) {
                layoutServices.cachedLayouts[key]?[cachedIndex].activeReservationAdjacentCount = sharedTables.count
            }
        }

        // Save changes to disk
        layoutServices.saveToDisk()
        self.logger.info("Updated activeReservationAdjacentCount for tables in reservation \(reservation.id).")
    }
    
}

extension ReservationService {
    /// Clears all caches in the store and resets layouts and clusters.
    @MainActor
    func flushAllCaches() {
        DispatchQueue.main.async {
            // Clear cached layouts
            self.layoutServices.cachedLayouts.removeAll()
            self.layoutServices.saveToDisk() // Persist changes

            // Clear cluster cache
            self.clusterStore.clusterCache.removeAll()
            self.clusterServices.saveClustersToDisk() // Persist changes

            // Clear active reservation cache
            self.store.activeReservationCache.removeAll()

            self.logger.info("All caches flushed successfully.")
        }
    }
}


// MARK: - Conflict Manager
extension ReservationService {

    
    // MARK: - Helper Method
    
    /// “Deletes” a reservation by marking it with “NA” values and clearing its tables and notes.
    @MainActor
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        var updatedReservation = reservation  // Create a mutable copy
        let finalNotes = notesToAdd == "" ? "" : "\(notesToAdd)\n\n"
        updatedReservation.status = .pending
        updatedReservation.notes = "\(finalNotes)[da controllare];"
        return updatedReservation
    }
    
    @MainActor
    func deleteReservation(_ reservation: Reservation) {
        var updatedReservation = reservation  // Create a mutable copy
        updatedReservation.reservationType = .na
        updatedReservation.status = .deleted
        updatedReservation.acceptance = .na
        updatedReservation.tables = []
        updatedReservation.notes = "[eliminata];"
        
        updateReservation(updatedReservation) {
            self.logger.info("Updated reservation")
        }
    }
}

extension Date {
    /// Returns the start of the next minute for the current date.
    func startOfNextMinute() -> Date {
        let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: self)!
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextMinute))!
    }
}

extension Date {
    func normalizedToDayStart() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}
