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

            let adjustedReservationEnd = reservationEnd.addingTimeInterval(-1) // Exclude the end time completely
            return time >= reservationStart && time < adjustedReservationEnd &&
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
    
    func generateReservations(daysToSimulate: Int, force: Bool = false) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Load resources once
        let names = loadStringsFromFile(fileName: "names")
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers")
        let notes = loadStringsFromFile(fileName: "notes")

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
            print("Required resources are missing. Reservation generation aborted.")
            return
        }

        print("Generating reservations for \(daysToSimulate) days with realistic variance (closed on Mondays).")

        // Use a background queue for heavy processing
        DispatchQueue.global(qos: .userInitiated).async {
            var totalGenerated = 0 // Track how many reservations are successfully created

            for dayOffset in 0..<daysToSimulate {
                let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: today)!
                let dayOfWeek = Calendar.current.component(.weekday, from: reservationDate)

                // Skip Mondays (weekday 2 in Gregorian calendar)
                if dayOfWeek == 2 {
                    print("Skipping Monday: \(reservationDate)")
                    continue
                }

                // Determine the daily target number of reservations with variance
                let maxDailyReservations = Int.random(in: 10...30) // Adjust as needed for busier/slower days
                var dailyGeneratedReservations = 0

                // Precompute all possible time slots for the day
                var availableTimeSlots: [(start: Date, end: Date, category: Reservation.ReservationCategory)] = []

                // Lunch slots
                for hour in 12...13 {
                    for minute in stride(from: 0, to: 60, by: 10) {
                        let start = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: reservationDate)!
                        let end = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: start)!
                        if start < end {
                            availableTimeSlots.append((start, end, .lunch))
                        }
                    }
                }

                // Dinner slots
                for hour in 18...21 {
                    for minute in stride(from: 0, to: 60, by: 10) {
                        let start = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: reservationDate)!
                        let end = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: start)!
                        if start < end {
                            availableTimeSlots.append((start, end, .dinner))
                        }
                    }
                }

                // Shuffle available slots for randomness
                availableTimeSlots.shuffle()

                while dailyGeneratedReservations < maxDailyReservations && !availableTimeSlots.isEmpty {
                    // Pick a random slot
                    let slot = availableTimeSlots.removeFirst()
                    let startTime = slot.start
                    let endTime = slot.end
                    let category = slot.category

                    // Generate group size with weighted probabilities
                    let numberOfPersons = {
                        let random = Double.random(in: 0...1)
                        switch random {
                        case 0..<0.7: return Int.random(in: 2...5) // 70% chance for groups of 2–5
                        case 0.7..<0.9: return Int.random(in: 6...8) // 20% chance for groups of 6–8
                        default: return Int.random(in: 9...12) // 10% chance for groups of 9–12
                        }
                    }()

                    // Generate reservation
                    var reservation = Reservation(
                        id: UUID(),
                        name: names.randomElement()!, // Use a random name
                        phone: phoneNumbers.randomElement()!, // Use a random phone number
                        numberOfPersons: numberOfPersons, // Reference the group size
                        dateString: DateHelper.formatFullDate(reservationDate),
                        category: category,
                        startTime: DateHelper.timeFormatter.string(from: startTime),
                        endTime: DateHelper.timeFormatter.string(from: endTime),
                        acceptance: .confirmed,
                        status: .pending,
                        reservationType: .inAdvance,
                        group: Bool.random(),
                        notes: notes.randomElement(), // Use a random note or nil
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
                        DispatchQueue.main.async {
                            reservation.tables = assignedTables
                            self.store.finalizeReservation(reservation, tables: assignedTables)

                            // Avoid duplicates
                            if !self.store.reservations.contains(where: { $0.id == reservation.id }) {
                                self.store.reservations.append(reservation)
                                totalGenerated += 1
                                dailyGeneratedReservations += 1
                                print("Generated reservation #\(totalGenerated): \(reservation)")
                            } else {
                                print("Duplicate reservation detected for ID \(reservation.id). Skipping.")
                            }
                        }
                    } else {
                        print("Failed to assign tables for reservation \(reservation.id).")
                    }
                }

                if availableTimeSlots.isEmpty {
                    print("All time slots are filled for \(reservationDate).")
                }
            }

            DispatchQueue.main.async {
                print("Finished generating reservations. Total generated: \(totalGenerated)")
            }
        }
    }
    
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(folder)/\(fileName)" : fileName
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

extension Date {
    /// Returns the start of the next minute for the current date.
    func startOfNextMinute() -> Date {
        let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: self)!
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextMinute))!
    }
}
