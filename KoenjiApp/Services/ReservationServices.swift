//
//  ReservationService.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

/// A service class responsible for high-level operations on reservations.
/// This class interacts with the `ReservationStore` for managing reservation data.
class ReservationService: ObservableObject {
    // MARK: - Dependencies
    let store: ReservationStore
    private let resCache: CurrentReservationsCache
    private let clusterStore: ClusterStore
    private let clusterServices: ClusterServices
    private let tableStore: TableStore
    private let layoutServices: LayoutServices
    private let tableAssignmentService: TableAssignmentService
    let backupService: FirebaseBackupService
    private let pushAlerts: PushAlerts
    private var imageCache: [UUID: UIImage] = [:]
    let notifsManager: NotificationManager
    @Published var changedReservation: Reservation? = nil
    
    var listener: ListenerRegistration?
    
    // MARK: - Initializer
    @MainActor
    init(store: ReservationStore, resCache: CurrentReservationsCache, clusterStore: ClusterStore, clusterServices: ClusterServices, tableStore: TableStore, layoutServices: LayoutServices, tableAssignmentService: TableAssignmentService, backupService: FirebaseBackupService, pushAlerts: PushAlerts, notifsManager: NotificationManager = NotificationManager.shared) {
        self.store = store
        self.resCache = resCache
        self.clusterStore = clusterStore
        self.clusterServices = clusterServices
        self.tableStore = tableStore
        self.layoutServices = layoutServices
        self.tableAssignmentService = tableAssignmentService
        self.backupService = backupService
        self.pushAlerts = pushAlerts
        self.notifsManager = notifsManager
        
        self.layoutServices.loadFromDisk()
        self.clusterServices.loadClustersFromDisk()
        
        self.startReservationsListener()
        self.loadReservationsFromSQLite()
        
        let today = Calendar.current.startOfDay(for: Date())
        self.resCache.preloadDates(around: today, range: 5, reservations: self.store.reservations)
//        self.preloadActiveReservationCache(around: today, forDaysBefore: 5, afterDays: 5)
    }
    
    deinit {
            listener?.remove()
        }
    
    // MARK: - Placeholder Methods for CRUD Operations

    
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
               print("Added reservation \(reservation.id) with tables \(reservation.tables).")
               
           }
        
        // Push changes to Firestore
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        let data = convertReservationToDictionary(reservation: reservation)
            // Using the reservation’s UUID string as the document ID:
            dbRef.document(reservation.id.uuidString).setData(data) { error in
                if let error = error {
                    print("Error pushing reservation to Firebase: \(error)")
                } else {
                    print("Reservation pushed to Firebase successfully.")
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
    private func convertReservationToDictionary(reservation: Reservation) -> [String: Any] {
        return [
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
            "notes": reservation.notes as Any,
            "tables": reservation.tables.map { table in
                return [
                    "id": table.id,
                    "name": table.name,
                    "maxCapacity": table.maxCapacity,
                    "row": table.row,
                    "column": table.column,
                    "adjacentCount": table.adjacentCount,
                    "activeReservationAdjacentCount": table.activeReservationAdjacentCount,
                    "isVisible": table.isVisible
                ]
            },            "creationDate": reservation.creationDate.timeIntervalSince1970,
            "lastEditedOn": reservation.lastEditedOn.timeIntervalSince1970,
            "isMock": reservation.isMock,
            "assignedEmoji": reservation.assignedEmoji as Any,
            "imageData": reservation.imageData as Any,
            "colorHue": reservation.colorHue
        ]
    }
    
    /// Updates an existing reservation, refreshes the cache, and reassigns tables if needed.
    @MainActor
    func updateReservation(_ oldReservation: Reservation, newReservation: Reservation? = nil, at index: Int? = nil/*, dateString: String? = "", startTime: String? = "", endTime: String? = ""*/, shouldPersist: Bool = true, completion: @escaping () -> Void) {
        // Remove from active cache
        self.invalidateClusterCache(for: oldReservation)
        resCache.removeReservation(oldReservation)
        
        let updatedReservation = newReservation ?? oldReservation

        DispatchQueue.main.async {
            
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == oldReservation.id })

            guard let reservationIndex else {
                print("Error: Reservation with ID \(oldReservation.id) not found.")
                return
            }
            
            SQLiteManager.shared.insertReservation(updatedReservation)
            
            self.store.reservations[reservationIndex] = updatedReservation
            self.store.reservations = Array(self.store.reservations)
            self.changedReservation = updatedReservation
            print("Changed changedReservation, should update UI...")

            let oldReservation = self.store.reservations[reservationIndex]
            
            // 🔹 Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables)
            let newTableIDs = Set(updatedReservation.tables)
            
            if oldTableIDs != newTableIDs {
                print("Table change detected for reservation \(updatedReservation.id). Updating tables...")

                // Unmark only if tables have changed
                oldTableIDs.subtracting(newTableIDs).forEach { self.layoutServices.unmarkTable($0) }

                // Mark only new tables that weren't already assigned
                newTableIDs.subtracting(oldTableIDs).forEach { self.layoutServices.markTable($0, occupied: true) }
                
                // Invalidate cluster cache only if tables changed
                self.invalidateClusterCache(for: updatedReservation)
            } else if newTableIDs == [] {
                oldTableIDs.forEach { self.layoutServices.unmarkTable($0) }
            } else {
                print("No table change detected for reservation \(updatedReservation.id). Skipping table update.")
            }


            
            // Update the reservation in the store
            self.resCache.addOrUpdateReservation(updatedReservation)
            if shouldPersist {
                self.store.finalizeReservation(updatedReservation)
                // Update database
                // Pushes to Firestore
                #if DEBUG
                let dbRef = self.backupService.db.collection("reservations")
                #else
                let dbRef = self.backupService.db.collection("reservations_release")
                #endif
                let data = self.convertReservationToDictionary(reservation: updatedReservation)
                    // Using the reservation’s UUID string as the document ID:
                dbRef.document(updatedReservation.id.uuidString).setData(data) { error in
                        if let error = error {
                            print("Error pushing reservation to Firebase: \(error)")
                        } else {
                            print("Reservation pushed to Firebase successfully.")
                        }
                    }
            }
            print("Updated reservation \(updatedReservation.id).")
            
        }

        // Finalize and save
        
        
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
                        print("Updated reservations.")
                    }

                }
            case .failure(let error):
                switch error {
                    case .noTablesLeft:
                    pushAlerts.alertMessage = "Non ci sono tavoli disponibili."
                    case .insufficientTables:
                    pushAlerts.alertMessage = "Non ci sono abbastanza tavoli per la prenotazione."
                    case .tableNotFound:
                    pushAlerts.alertMessage = "Tavolo selezionato non trovato."
                    case .tableLocked:
                    pushAlerts.alertMessage = "Il tavolo scelto è occupato o bloccato."
                    case .unknown:
                    pushAlerts.alertMessage = "Errore sconosciuto."
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
                print("Error fetching documents for deletion: \(error)")
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
                    print("Error committing batch deletion: \(error)")
                } else {
                    print("Successfully deleted all reservations from Firestore.")
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
                   print("Error clearing Firestore data: \(error)")
               } else {
                   print("All Firestore data cleared successfully.")
               }
           }
        
        print("ReservationService: All data has been cleared.")
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
               print("Failed to parse dateString \(reservation.normalizedDate ?? Date()). Cache invalidation skipped.")
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
        
        print("Reservations loaded from SQLite successfully.")
        print("Loaded n. reservations: \(store.reservations.count)")
        
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
                print("Error downloading JSON backup: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data returned from Firebase Storage")
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
            print("Error decoding JSON backup: \(error)")
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
                    print("Error pushing reservation \(reservation.id) to Firebase: \(error)")
                } else {
                    print("Reservation \(reservation.id) migrated successfully to Firebase.")
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
        print("Debug: Tables populated in mockData: \(layoutServices.tables.map { $0.name })")
        
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
            print("Required resources are missing. Reservation generation aborted.")
            return
        }

        print("Generating reservations for \(daysToSimulate) days with realistic variance (closed on Mondays).")

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
            print("Finished generating reservations.")
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
            print("Skipping Monday: \(reservationDate)")
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
                                print("Generated reservation: \(updatedReservation)")
                            }
                        }
                    case .failure(let error):
                        // Show an alert message based on `error`.
                        switch error {
                        case .noTablesLeft:
                             print("Non ci sono tavoli disponibili.")
                        case .insufficientTables:
                            print("Non ci sono abbastanza tavoli per la prenotazione.")
                        case .tableNotFound:
                            print("Tavolo selezionato non trovato.")
                        case .tableLocked:
                            print("Il tavolo scelto è occupato o bloccato.")
                        case .unknown:
                            print("Errore sconosciuto.")
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
            print("Failed to load \(fileName) from folder \(String(describing: folder)).")
            return []
        }
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            print("Loaded \(lines.count) lines from \(fileName) (folder: \(String(describing: folder))).")
            return lines
        } catch {
            print("Error reading \(fileName): \(error)")
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
                        print("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(result)")
                    }
                }
            } catch {
                print("Task.sleep encountered an error: \(error)")
            }
        }
    }
    
   
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            print("Invalid reservation date or time for updating adjacency counts.")
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
        print("Updated activeReservationAdjacentCount for tables in reservation \(reservation.id).")
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

            print("All caches flushed successfully.")
        }
    }
}


// MARK: - Conflict Manager
extension ReservationService {
    struct ReservationKey: Hashable {
        let day: Date
        let category: Reservation.ReservationCategory
    }
    
    // A helper struct to represent an event in time.
    struct TimeEvent {
        let time: Date
        /// +guestDelta on reservation start, –guestDelta on reservation end.
        let guestDelta: Int
        let reservation: Reservation
    }

    /// Checks all reservations (loaded into store.reservations) for conflicts.
    @MainActor
    func checkForConflictsAndCleanup() async {
        var conflictFound = false

        // Dictionaries keyed by reservation id.
        var overbookingConflicts: [Reservation.ID: Reservation] = [:]
        var inconsistencyConflicts: [Reservation.ID: Reservation] = [:]

        // Group reservations by day (using cachedNormalizedDate if available) and category.
        let grouped = Dictionary(grouping: store.reservations) { res -> ReservationKey in
            let day = Calendar.current.startOfDay(for: res.cachedNormalizedDate ?? Date())
            return ReservationKey(day: day, category: res.category)
        }

        // Process each group.
        for (key, reservationsForGroup) in grouped {
            // --- Overcapacity Check (Time Sensitive) ---
            // Exclude reservations that do not count toward overbooking.
            let validForOverbooking = reservationsForGroup.filter { res in
                let excludedStatuses: [Reservation.ReservationStatus] = [.canceled, .toHandle, .deleted]
                return !excludedStatuses.contains(res.status) && res.reservationType != .waitingList
            }
            if validForOverbooking.isEmpty {
                // Nothing to check in this group.
                continue
            }

            // Build an array of time events.
            var events: [TimeEvent] = []
            for res in validForOverbooking {
                events.append(TimeEvent(time: res.startTimeDate ?? Date(), guestDelta: res.numberOfPersons, reservation: res))
                events.append(TimeEvent(time: res.endTimeDate ?? Date(), guestDelta: -res.numberOfPersons, reservation: res))
            }
            // Sort events by time. If two events have the same time, process the addition before the removal.
            events.sort {
                if $0.time == $1.time {
                    return $0.guestDelta < $1.guestDelta
                }
                return $0.time < $1.time
            }

            var cumulativeGuests = 0
            var currentOverlapping: [Reservation] = []

            for event in events {
                if event.guestDelta > 0 {
                    currentOverlapping.append(event.reservation)
                } else {
                    if let idx = currentOverlapping.firstIndex(where: { $0.id == event.reservation.id }) {
                        currentOverlapping.remove(at: idx)
                    }
                }
                cumulativeGuests += event.guestDelta

                if cumulativeGuests > 14 {
                    conflictFound = true
                    // Overbooking occurred at event.time. Among the currently overlapping reservations, choose
                    // the candidate with the latest lastEditedOn.
                    if let candidate = currentOverlapping.max(by: { $0.creationDate < $1.creationDate }) {
                        overbookingConflicts[candidate.id] = candidate
                        print("Overcapacity conflict in group \(key.day) \(key.category) at time \(event.time): candidate reservation \(candidate.id)")
                    }
                }
            }

            // --- Check for Duplicate Table Assignments Within Each Reservation ---
            for res in reservationsForGroup {
                let tableIDs = res.tables.map { $0.id }
                if tableIDs.count != Set(tableIDs).count {
                    conflictFound = true
                    inconsistencyConflicts[res.id] = res
                    print("Inconsistency conflict: Reservation \(res.id) in group \(key.day) \(key.category) has duplicate table assignments: \(tableIDs)")
                }
            }
        }

        // --- Additional Consistency Checks on the Entire Store ---
        for res in store.reservations {
            // Canceled or waiting list reservations should not have tables.
            if (res.status == .canceled || res.reservationType == .waitingList) && !res.tables.isEmpty {
                conflictFound = true
                inconsistencyConflicts[res.id] = res
                print("Consistency conflict: Reservation \(res.id) is \(res.status)/\(res.reservationType) but has tables assigned.")
            }
        }

        if conflictFound {
            // Notify the user that conflicts have been detected.
            await notifsManager.addNotification(
                title: "Errore di sincronizzazione",
                message: "Trovato n. \(overbookingConflicts.count) possibili overbooking e/o n. \(inconsistencyConflicts.count) inconsistenze. Risoluzione automatica in corso: controlla tra le prenotazioni in sospeso al termine del processo!",
                type: .sync
            )

            // --- Resolve Overbooking Conflicts ---
            if !overbookingConflicts.isEmpty {
                for (_, res) in overbookingConflicts {
                    print("Cleaning overbooking conflict: Deleting reservation \(res.id)")
                    let notesToAdd = "Hai aggiunto questa prenotazione senza che ci fossero abbastanza tavoli disponibili al momento dell'inserimento. Sei sicuro di averla presa correttamente? I tavoli che avevi tentato di assegnare erano: [  \(res.tables.map { String($0.id) }.joined(separator: ", ")) ]"
                    let updatedRes = separateReservation(res, notesToAdd: notesToAdd)
                    // Optionally, update the reservation in the store array if needed:
                    if let index = store.reservations.firstIndex(where: { $0.id == res.id }) {
                        store.reservations[index] = updatedRes
                    }
                    updateReservation(updatedRes, shouldPersist: false) {
                        print("Updated reservations.")
                    }
                }
            }

            // --- Resolve Inconsistency Conflicts ---
            // Since Reservation is a struct, iterate over the indices.
            for index in store.reservations.indices {
                var res = store.reservations[index]
                if inconsistencyConflicts.keys.contains(res.id) {
                    // If a canceled or waiting list reservation still has tables, clear them.
                    if (res.status == .canceled || res.status == .toHandle || res.reservationType == .waitingList) && !res.tables.isEmpty {
                        print("Cleaning inconsistency: Clearing tables for reservation \(res.id) (status: \(res.status), type: \(res.reservationType))")
                        res.tables = []
                        store.reservations[index] = res
                        updateReservation(res, shouldPersist: false) {
                            print("Updated reservations.")
                        }
                    }
                    // Otherwise, if the reservation should have tables but has none, attempt to assign tables.
                    else if res.tables.isEmpty {
                        print("Cleaning inconsistency: Reservation \(res.id) should have tables but has none. Attempting assignment.")
                        let assignmentResult = layoutServices.assignTables(for: res, selectedTableID: nil)
                        switch assignmentResult {
                        case .success(let assignedTables):
                            res.tables = assignedTables
                            res.reservationType = .inAdvance
                            res.status = .pending
                            store.reservations[index] = res
                            updateReservation(res, shouldPersist: false) {
                                print("Updated reservations.")
                            }
                            await notifsManager.addNotification(
                                title: "Sincronizzazione",
                                message: "Ripristinati tavoli assegnati per prenotazione \(res.name)!",
                                type: .sync
                            )
                        case .failure:
                            print("Assignment failed for reservation \(res.id). Treating as overbooking.")
                            let notesToAdd = "Tentativo di inserire automaticamente la prenotazione fallito. Potrebbe trattarsi di overbooking. Sei sicuro di aver preso la prenotazione in modo corretto? La prenotazione non aveva tavoli assegnati: potrebbe trattarsi di una cancellazione, o una in lista d'attesa."
                            let updatedRes = separateReservation(res, notesToAdd: notesToAdd)
                            updateReservation(updatedRes, shouldPersist: false) {
                                print("Updated reservations.")
                            }
                        }
                    }
                }
            }

            // After cleanup, persist changes.
            await notifsManager.addNotification(
                title: "Sincronizzazione",
                message: "Risoluzione automatica completata. Backup e salvataggio automatico in corso...",
                type: .sync
            )
        
        } else {
            await notifsManager.addNotification(
                title: "Sincronizzazione",
                message: "Sincronizzazione effettuata con successo. Nessun conflitto rilevato.",
                type: .sync
            )
            print("No conflicts found.")
        }
    }
    
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
            print("Updated reservation")
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
