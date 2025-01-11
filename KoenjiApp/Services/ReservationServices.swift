//
//  ReservationService.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation

/// A service class responsible for high-level operations on reservations.
/// This class interacts with the `ReservationStore` for managing reservation data.
class ReservationService: ObservableObject {
    // MARK: - Dependencies
    private let store: ReservationStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService

    // MARK: - Initializer
    init(store: ReservationStore, tableAssignmentService: TableAssignmentService) {
        self.store = store
        self.tableAssignmentService = tableAssignmentService

        // Load data from disk right away (or you can call this from outside)

        self.store.loadFromDisk()
        self.store.loadClustersFromDisk()// If you store layouts in files
        self.loadReservationsFromDisk()     // This updates store.reservations
        self.store.markTablesInGrid()
    }
    
    // MARK: - Placeholder Methods for CRUD Operations

    
    /// Adds a new reservation.
    /// Assumes the reservation's `tables` have already been assigned
    /// (manually or automatically). If not, it will be unassigned.
    /// This method simply appends it and marks its tables as occupied.
    func addReservation(_ reservation: Reservation) {
           DispatchQueue.main.async {
               self.store.reservations.append(reservation)
               reservation.tables.forEach { self.store.markTable($0, occupied: true) }
               self.invalidateClusterCache(for: reservation)
               self.saveReservationsToDisk()
               print("Added reservation \(reservation.id).")
           }
       }
    
    /// Updates an existing reservation, refreshes the cache, and reassigns tables if needed.
       func updateReservation(_ updatedReservation: Reservation, at index: Int? = nil) {
           DispatchQueue.main.async {
               let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == updatedReservation.id })

               guard let reservationIndex else {
                   print("Error: Reservation with ID \(updatedReservation.id) not found.")
                   return
               }

               let oldReservation = self.store.reservations[reservationIndex]
               oldReservation.tables.forEach { self.store.unmarkTable($0) }

               self.store.reservations[reservationIndex] = updatedReservation
               updatedReservation.tables.forEach { self.store.markTable($0, occupied: true) }
               self.invalidateClusterCache(for: updatedReservation)
               self.saveReservationsToDisk()
               print("Updated reservation \(updatedReservation.id).")
           }
       }
    
    /// Deletes reservations and invalidates the associated cluster cache.
    func deleteReservations(at offsets: IndexSet) {
        DispatchQueue.main.async {
            offsets.forEach { index in
                let reservation = self.store.reservations[index]

                // Unlock the tables associated with the reservation
                reservation.tables.forEach { self.store.unmarkTable($0) }

                // Invalidate cluster cache for this reservation
                self.invalidateClusterCache(for: reservation)

                // (Optional) Perform any additional cancellation logic
                print("Cancelled reservation \(reservation.id.uuidString).")
            }

            // Remove the reservations from the array
            self.store.reservations.remove(atOffsets: offsets)

            // Save the updated reservations to disk
            self.saveReservationsToDisk()

            print("Deleted reservations at offsets \(offsets).")
        }
    }
    
    /// Fetches reservations for a specific date.
    /// - Parameter date: The date for which to fetch reservations.
    /// - Returns: A list of reservations for the given date.
    func fetchReservations(on date: Date) -> [Reservation] {
        let targetDateString = DateHelper.formatFullDate(date) // Use centralized helper
        return store.reservations.filter { $0.dateString == targetDateString }
    }
    
    /// Retrieves reservations for a specific category on a given date.
    func fetchReservations(on date: Date, for category: Reservation.ReservationCategory) -> [Reservation] {
        fetchReservations(on: date).filter { $0.category == category }
    }
    
    // MARK: - Cluster Cache Invalidation

       /// Invalidates the cluster cache for the given reservation.
       private func invalidateClusterCache(for reservation: Reservation) {
           guard let reservationDate = DateHelper.parseFullDate(reservation.dateString) else {
               print("Failed to parse dateString \(reservation.dateString). Cache invalidation skipped.")
               return
           }
           self.store.invalidateClusterCache(for: reservationDate, category: reservation.category)
       }
    
    // MARK: - Placeholder Methods for Queries
    
    /// Finds an active reservation for a specific table and time.
    /// - Parameters:
    ///   - table: The table model.
    ///   - date: The date to check for reservations.
    ///   - time: The time to check for reservations.
    /// - Returns: The active reservation if found, else nil.
    func findActiveReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {
        let cacheKey = ReservationStore.ActiveReservationCacheKey(tableID: table.id, date: date, time: time)

        // Fast path: Check if the reservation is cached
        if let cachedReservation = store.activeReservationCache[cacheKey] {
            print("Cache hit for key: \(cacheKey)")
            return cachedReservation
        }

        // Fallback: Iterate through active reservations and find matching ones
        guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: date) else {
            print("Failed to compute previous date.")
            return nil
        }
        let datesToCheck = [date, previousDate]

        let activeReservation = store.activeReservations.first(where: { reservation in
            guard let reservationDate = DateHelper.parseFullDate(reservation.dateString),
                  datesToCheck.contains(where: { Calendar.current.isDate(reservationDate, equalTo: $0, toGranularity: .day) }) else {
                return false
            }

            guard let reservationStart = DateHelper.combineDateAndTime(date: reservationDate, timeString: reservation.startTime),
                  let reservationEnd = DateHelper.combineDateAndTime(date: reservationDate, timeString: reservation.endTime) else {
                return false
            }

            return time >= reservationStart && time <= reservationEnd &&
                   reservation.tables.contains { $0.id == table.id }
        })

        // Synchronously cache the result and log
        if let activeReservation = activeReservation {
            store.activeReservationCache[cacheKey] = activeReservation
            print("Cached reservation for key: \(cacheKey)")
        } else {
            print("No active reservation found for table ID: \(table.id) on date: \(DateHelper.formatFullDate(date)) at time: \(DateHelper.timeFormatter.string(from: time))")
        }

        return activeReservation
    }
    
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
        let fileURL = getReservationsFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No reservation file found at: \(fileURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Ensure ISO 8601 consistency
            
            let decodedReservations = try decoder.decode([Reservation].self, from: data)
            store.setReservations(decodedReservations) // Update store
            print("Reservations loaded successfully.")
        } catch {
            print("Error loading reservations from disk: \(error)")
        }
    }

    func saveReservationsToDisk(includeMock: Bool = false) {
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
        store.setTables(store.baseTables)
        print("Debug: Tables populated in mockData: \(store.tables.map { $0.name })")
        
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
    
    func generateReservations(for days: Int, reservationsPerDay: Int, force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())

        // Use a background queue for heavy processing
        DispatchQueue.global(qos: .userInitiated).async {
            var totalGenerated = 0 // Track how many reservations are successfully created

            for dayOffset in 0..<days {
                let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: today)!
                
                for _ in 0..<reservationsPerDay {
                    let randomTableID = Int.random(in: 1...7) // Assuming table IDs range from 1 to 7
                    let startTime = DateHelper.randomTime(for: reservationDate, range: (12, 23)) // Lunch to dinner
                    let endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime)!
                    let category: Reservation.ReservationCategory = Bool.random() ? .lunch : .dinner

                    var reservation = Reservation(
                        id: UUID(),
                        name: ["Alice", "Bob", "Charlie", "Diana"].randomElement()!,
                        phone: "123-456-\(Int.random(in: 1000...9999))",
                        numberOfPersons: Int.random(in: 1...6),
                        dateString: DateHelper.formatFullDate(reservationDate),
                        category: category,
                        startTime: DateHelper.timeFormatter.string(from: startTime),
                        endTime: DateHelper.timeFormatter.string(from: endTime),
                        acceptance: .confirmed,
                        status: .pending,
                        reservationType: .inAdvance,
                        group: Bool.random(),
                        notes: Bool.random() ? "Allergic to peanuts" : nil,
                        tables: [],
                        creationDate: Date(),
                        isMock: true
                    )
                    
                    // Ensure layout is initialized
                    let key = self.store.keyFor(date: reservationDate, category: category)
                    DispatchQueue.main.sync {
                        if self.store.cachedLayouts[key] == nil {
                            print("Initializing layout for key: \(key)")
                            self.store.cachedLayouts[key] = self.store.baseTables
                            self.store.saveToDisk()
                        }
                    }

                    // Assign tables using the store logic
                    if let assignedTables = self.store.assignTables(for: reservation, selectedTableID: nil) {
                        reservation.tables = assignedTables
                        DispatchQueue.main.async {
                            self.store.finalizeReservation(reservation, tables: assignedTables)

                            // Eliminate duplicates before appending
                            if !self.store.reservations.contains(where: { $0.id == reservation.id }) {
                                self.store.reservations.append(reservation) // Append only if it's not a duplicate
                                totalGenerated += 1 // Increment the counter
                            } else {
                                print("Duplicate reservation detected for ID \(reservation.id). Skipping.")
                            }
                        }
                    } else {
                        print("Failed to assign tables for reservation \(reservation.id).")
                    }
                }
            }

            // Final log to track progress
            DispatchQueue.main.async {
                print("Finished generating reservations. Total generated: \(totalGenerated)")
            }
        }
    }
    
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    Task {
                        let randomTable = self.store.tables.randomElement()!
                        let newRow = Int.random(in: 0..<self.store.totalRows)
                        let newColumn = Int.random(in: 0..<self.store.totalColumns)
                        
                        let result = self.store.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        print("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(result)")
                    }
                }
            } catch {
                print("Task.sleep encountered an error: \(error)")
            }
        }
    }
    
}

extension ReservationService {
    /// Clears all caches in the store and resets layouts and clusters.
    func flushAllCaches() {
        DispatchQueue.main.async {
            // Clear cached layouts
            self.store.cachedLayouts.removeAll()
            self.store.saveToDisk() // Persist changes

            // Clear cluster cache
            self.store.clusterCache.removeAll()
            self.store.saveClustersToDisk() // Persist changes

            // Clear active reservation cache
            self.store.activeReservationCache.removeAll()

            print("All caches flushed successfully.")
        }
    }
}
