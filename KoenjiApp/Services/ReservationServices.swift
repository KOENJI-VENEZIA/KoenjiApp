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

        self.store.loadFromDisk()   // If you store layouts in files
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
            // Append the new reservation
            self.store.reservations.append(reservation)
            
            // Mark any assigned tables as occupied
            reservation.tables.forEach { self.store.markTable($0, occupied: true) }
            
            // Save reservations to disk
            self.saveReservationsToDisk()
            
            print("Debug: Added new reservation \(reservation.id) with \(reservation.tables.count) tables.")
        }
    }
    
    /// Updates an existing reservation with new details (e.g. new tables).
    /// Unmarks old tables, updates the store, then re-marks new tables as occupied.
    func updateReservation(_ updatedReservation: Reservation, at index: Int? = nil) {
        // Determine the index: use the provided index or search by ID
        let reservationIndex = index ?? store.reservations.firstIndex(where: { $0.id == updatedReservation.id })
        
        // Ensure the index exists
        guard let reservationIndex else {
            print("Error: Reservation with ID \(updatedReservation.id) not found.")
            return
        }
        
        let oldReservation = store.reservations[reservationIndex]
        
        // Unmark old tables
        oldReservation.tables.forEach { store.unmarkTable($0) }
        
        // Overwrite the reservation in place
        store.reservations[reservationIndex] = updatedReservation
        
        // Mark new tables as occupied
        updatedReservation.tables.forEach { store.markTable($0, occupied: true) }
        
        // Save
        saveReservationsToDisk()
        
        print("Debug: Updated reservation \(updatedReservation.id) with \(updatedReservation.tables.count) tables at index \(reservationIndex).")
    }
    
    /// Deletes reservations at specified offsets and unmarks their tables.
    func deleteReservations(at offsets: IndexSet) {
        offsets.forEach { index in
            let reservation = store.reservations[index]
            // Unmark tables associated with the reservation
            reservation.tables.forEach { store.unmarkTable($0) }
        }
        // Remove reservations from the list
        store.reservations.remove(atOffsets: offsets)
        
        // Save
        saveReservationsToDisk()
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
    
    // MARK: - Placeholder Methods for Queries
    
    /// Finds an active reservation for a specific table and time.
    /// - Parameters:
    ///   - table: The table model.
    ///   - date: The date to check for reservations.
    ///   - time: The time to check for reservations.
    /// - Returns: The active reservation if found, else nil.
    func findActiveReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {
        // Create the composite key for the cache
        let cacheKey = ReservationStore.ActiveReservationCacheKey(tableID: table.id, date: date, time: time)

        // Fast path: Check if the reservation is cached
        if let cachedReservation = store.activeReservationCache[cacheKey] {
            return cachedReservation
        }

        // Fallback: Iterate through reservations and find matching ones
        let datesToCheck = [date, Calendar.current.date(byAdding: .day, value: -1, to: date)!]

        let activeReservation = store.reservations.first(where: { reservation in
            // Parse reservation date
            guard let reservationDate = DateHelper.parseFullDate(reservation.dateString),
                  datesToCheck.contains(where: { Calendar.current.isDate(reservationDate, equalTo: $0, toGranularity: .day) }) else { return false }

            // Combine start and end times with reservation date
            guard let reservationStart = DateHelper.combineDateAndTime(date: reservationDate, timeString: reservation.startTime),
                  let reservationEnd = DateHelper.combineDateAndTime(date: reservationDate, timeString: reservation.endTime) else { return false }

            // Validate the time range and check table association
            return time >= reservationStart && time <= reservationEnd &&
                   reservation.tables.contains { $0.id == table.id }
        })

        // Cache the result for future lookups
        if let activeReservation = activeReservation {
            store.activeReservationCache[cacheKey] = activeReservation
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

    func saveReservationsToDisk() {
        let fileURL = getReservationsFileURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Ensure ISO 8601 consistency
        
        do {
            let filteredReservations = store.reservations.filter { !$0.isMock } // Exclude mocks
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
