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
    private let store: ReservationStore
    private let resCache: CurrentReservationsCache
    private let clusterStore: ClusterStore
    private let clusterServices: ClusterServices
    private let tableStore: TableStore
    private let layoutServices: LayoutServices
    private let tableAssignmentService: TableAssignmentService
    private let backupService = FirebaseBackupService()
    
    private var imageCache: [UUID: UIImage] = [:]

    @ObservedObject private var appState: AppState // Use the shared AppState

    // MARK: - Initializer
    init(store: ReservationStore, resCache: CurrentReservationsCache, clusterStore: ClusterStore, clusterServices: ClusterServices, tableStore: TableStore, layoutServices: LayoutServices, tableAssignmentService: TableAssignmentService, appState: AppState) {
        self.store = store
        self.resCache = resCache
        self.clusterStore = clusterStore
        self.clusterServices = clusterServices
        self.tableStore = tableStore
        self.layoutServices = layoutServices
        self.tableAssignmentService = tableAssignmentService
        self.appState = appState

        self.layoutServices.loadFromDisk()
        self.clusterServices.loadClustersFromDisk()
        self.loadReservationsFromDisk()
        
        let today = Calendar.current.startOfDay(for: Date())
        self.resCache.preloadDates(around: today, range: 5, reservations: self.store.reservations)
//        self.preloadActiveReservationCache(around: today, forDaysBefore: 5, afterDays: 5)
    }
    
    // MARK: - Placeholder Methods for CRUD Operations

    
    /// Adds a new reservation.
    /// Assumes the reservation's `tables` have already been assigned
    /// (manually or automatically). If not, it will be unassigned.
    /// This method simply appends it and marks its tables as occupied.
    func addReservation(_ reservation: Reservation) {
           DispatchQueue.main.async {
               self.store.reservations.append(reservation)
               reservation.tables.forEach { self.layoutServices.markTable($0, occupied: true) }
               self.invalidateClusterCache(for: reservation)
               self.saveReservationsToDisk()
               print("Added reservation \(reservation.id).")
           }
       }
    
    /// Updates an existing reservation, refreshes the cache, and reassigns tables if needed.
    func updateReservation(_ updatedReservation: Reservation, at index: Int? = nil) {
        // Remove from active cache
//        removeReservationFromActiveCache(updatedReservation)
        resCache.removeReservation(updatedReservation)

        // Update reservation in the store
        DispatchQueue.main.async {
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == updatedReservation.id })

            guard let reservationIndex else {
                print("Error: Reservation with ID \(updatedReservation.id) not found.")
                return
            }

            let oldReservation = self.store.reservations[reservationIndex]

            // Unmark old tables
            oldReservation.tables.forEach { self.layoutServices.unmarkTable($0) }

            // Update the reservation
            self.store.reservations[reservationIndex] = updatedReservation

            // Mark new tables as occupied
            updatedReservation.tables.forEach { self.layoutServices.markTable($0, occupied: true) }

            // Invalidate cluster cache
            self.invalidateClusterCache(for: updatedReservation)

            print("Updated reservation \(updatedReservation.id).")
        }

        // Finalize and save
        resCache.addOrUpdateReservation(updatedReservation)
        store.finalizeReservation(updatedReservation)
        saveReservationsToDisk()
        automaticBackup()
    }
    

    
    /// Deletes reservations and invalidates the associated cluster cache.
    func deleteReservations(at offsets: IndexSet) {
        DispatchQueue.main.async {
            offsets.forEach { index in
                let reservation = self.store.reservations[index]

                // 1) Remove from activeReservationCache
                self.resCache.removeReservation(reservation)

                // 2) Unlock the tables, invalidate cluster cache, etc.
                reservation.tables.forEach { self.layoutServices.unmarkTable($0) }
                self.invalidateClusterCache(for: reservation)
            }

            // 3) Remove from the reservations array
            self.store.reservations.remove(atOffsets: offsets)

            // 4) Save changes to disk
            self.saveReservationsToDisk()
        }
    }
    


    

    
    
    func clearAllData() {
        store.reservations.removeAll() // Clear in-memory reservations
        
        saveReservationsToDisk(includeMock: true) // Overwrite stored data
        flushAllCaches() // Clear any cached layouts or data
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
               print("Failed to parse dateString \(reservation.normalizedDate). Cache invalidation skipped.")
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
    
    // MARK: - Placeholder Methods for Persistence
    
    /// Loads reservations from persistent storage.
    func loadReservationsFromDisk() {
        withAnimation {
            appState.isWritingToFirebase = true
        }
        let fileURL = getReservationsFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No reservation file found at: \(fileURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Ensure ISO 8601 consistency
            
            // Decode reservations
            var decodedReservations = try decoder.decode([Reservation].self, from: data)
            
            
            // Save normalized reservations to the store
            store.setReservations(decodedReservations)
            print("Reservations loaded and normalized successfully.")
        } catch {
            print("Error loading reservations from disk: \(error)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                self.appState.isWritingToFirebase = false
            }
        }
    }

    func saveReservationsToDisk(includeMock: Bool = false) {
        withAnimation {
            appState.isWritingToFirebase = true
        }
        let fileURL = getReservationsFileURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Ensure ISO 8601 consistency
        
        do {
            let filteredReservations = includeMock
                ? store.reservations // Include mocks if specified
                : store.reservations.filter { !$0.isMock }
            
            let data = try encoder.encode(filteredReservations)
            try data.write(to: fileURL, options: .atomic)
            print("Reservations saved successfully.")
        } catch {
            print("Error saving reservations to disk: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                self.appState.isWritingToFirebase = false
            }
        }
    }
    
    func exportReservations(completion: @escaping (URL?) -> Void) {
        withAnimation {
            appState.isWritingToFirebase = true
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Ensure ISO 8601 consistency

        // Map reservations to their lightweight versions
        let lightweightReservations = store.reservations.map { $0.toLightweight() }

        do {
            // Encode the lightweight reservations to JSON
            let data = try encoder.encode(lightweightReservations)

            // Create a temporary file URL
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReservationsBackup.json")

            // Write the JSON data to the file
            try data.write(to: tempURL, options: .atomic)
            print("Reservations exported successfully to \(tempURL).")

            // Pass the file URL to the completion handler
            completion(tempURL)
        } catch {
            print("Error exporting reservations: \(error)")
            completion(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                self.appState.isWritingToFirebase = false
            }
        }
    }
    
    /// Imports reservations from a JSON file.
    func importReservations(from url: URL, completion: @escaping (Bool) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Ensure ISO 8601 consistency

        do {
            // Read the data from the selected file
            let data = try Data(contentsOf: url)
            
            // Decode the JSON data into an array of reservations
            let importedReservations = try decoder.decode([Reservation].self, from: data)
            
            // Replace the current reservations with the imported ones
            store.reservations = importedReservations
            
            // Save the imported reservations to disk
            saveReservationsToDisk()
            
            print("Reservations imported successfully.")
            completion(true)
        } catch {
            print("Error importing reservations: \(error)")
            completion(false)
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
        
        saveReservationsToDisk() // Save after mocking
    }
}

extension ReservationService {
    // MARK: - Test Data
    
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
        await withTaskGroup(of: Void.self) { group in
            for dayOffset in 0..<daysToSimulate {
                group.addTask {
                    await self.generateReservationsForDay(
                        dayOffset: dayOffset,
                        startDate: startDate,
                        names: names,
                        phoneNumbers: phoneNumbers,
                        notes: notes
                    )
                }
            }
        }

        // 4. Save data to disk after all tasks complete
            self.layoutServices.saveToDisk()
            self.saveReservationsToDisk(includeMock: true)
            print("Finished generating reservations.")
    }

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
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 15)))
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 23)))

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
                isMock: true
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
                            self.store.reservations.append(updatedReservation)
                            print("Generated reservation: \(updatedReservation)")
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
    
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    Task {
                        let randomTable = self.layoutServices.tables.randomElement()!
                        let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                        let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                        
                        let result = self.layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        print("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(result)")
                    }
                }
            } catch {
                print("Task.sleep encountered an error: \(error)")
            }
        }
    }
    
   
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.cachedNormalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            print("Invalid reservation date or time for updating adjacency counts.")
            return
        }

        // Get active tables for the reservation's layout
        let activeTables = layoutServices.getTables(for: reservationDate, category: reservation.category)

        // Iterate over all tables in the reservation
        for table in reservation.tables {
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

// MARK: - Automatic Firebase Backup Service
extension ReservationService {
    
    func automaticBackup() {
            // Export reservations to a local file
            exportReservations { fileURL in
                guard let fileURL = fileURL else {
                    print("Failed to export reservations for backup.")
                    return
                }

                // Upload the file to Firebase Storage
                self.backupService.uploadBackup(fileURL: fileURL) { result in
                    switch result {
                    case .success:
                        print("Automatic backup successful.")
                    case .failure(let error):
                        print("Automatic backup failed: \(error)")
                    }
                }
            }
        }

    func restoreBackup(completion: @escaping (Bool) -> Void) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReservationsBackup.json")
        self.backupService.downloadLatestBackup(to: tempURL) { result in
            switch result {
            case .success:
                self.importReservations(from: tempURL, completion: completion)
            case .failure(let error):
                print("Restore backup failed: \(error)")
                completion(false)
            }
        }
    }
    
    func scheduleAutomaticBackup() {
        // Backup once a day
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            self.automaticBackup()
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
