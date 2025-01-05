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
    lazy var layoutManager: TableLayoutManager = TableLayoutManager()

    // MARK: - Initializer
    init(store: ReservationStore, tableAssignmentService: TableAssignmentService) {
        self.store = store
        self.tableAssignmentService = tableAssignmentService

        // Load data from disk right away (or you can call this from outside)

        self.layoutManager.loadFromDisk()   // If you store layouts in files
        self.loadReservationsFromDisk()     // This updates store.reservations
        self.layoutManager.markTablesInGrid()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        
        let targetDateString = formatter.string(from: date)
        
        return store.reservations.filter { $0.dateString == targetDateString }
    }
    
    // MARK: - Placeholder Methods for Queries
    
    /// Finds an active reservation for a specific table and time.
    /// - Parameters:
    ///   - table: The table model.
    ///   - time: The time to check for reservations.
    /// - Returns: The active reservation if found, else nil.
    func findActiveReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {
        let calendar = Calendar.current
        
        for reservation in store.reservations {
            guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else { continue }
            
            // Ensure reservation date matches the selected date
            guard calendar.isDate(reservationDate, equalTo: date, toGranularity: .day) else { continue }
            
            // Parse the reservation's start and end times
            guard let reservationStart = TimeHelpers.date(from: reservation.startTime, on: reservationDate),
                  let reservationEnd = TimeHelpers.date(from: reservation.endTime, on: reservationDate) else { continue }
            
            // Check if the selected time falls within the reservation's time range
            if time >= reservationStart && time <= reservationEnd {
                if reservation.tables.contains(where: { $0.id == table.id }) {
                    return reservation
                }
            }
        }
        return nil
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
            decoder.dateDecodingStrategy = .iso8601
            
            let decodedReservations = try decoder.decode([Reservation].self, from: data)
            store.setReservations(decodedReservations)  // Here we set store.reservations
            print("Reservations loaded successfully.")
        } catch {
            print("Error loading reservations from disk: \(error)")
        }
    }
    
    /// Saves reservations to persistent storage.
    func saveReservationsToDisk() {
        // We might choose not to save mock reservations
        let filteredReservations = store.reservations.filter { !$0.isMock }

        let fileURL = getReservationsFileURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(filteredReservations)
            try data.write(to: fileURL, options: .atomic)
            print("Reservations saved successfully: \(filteredReservations)")
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
            dateString: "28/12/2024",
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
            dateString: "28/12/2024",
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
        
        // If you want to auto-assign them:
        if let assigned1 = tableAssignmentService.assignTablesAutomatically(for: mockReservation1, reservations: store.getReservations(), tables: store.getTables()) {
            let idx = store.getReservations().firstIndex(where: { $0.id == mockReservation1.id })
            if let i = idx {
                var temp = store.getReservations()[i]
                temp.tables = assigned1
                updateReservation(temp, at: i)
                assigned1.forEach { store.markTable($0, occupied: true) }
            }
        }
        
        if let assigned2 = tableAssignmentService.assignTablesAutomatically(for: mockReservation2, reservations: store.getReservations(), tables: store.getTables()) {
            let idx = store.getReservations().firstIndex(where: { $0.id == mockReservation2.id })
            if let i = idx {
                var temp = store.getReservations()[i]
                temp.tables = assigned2
                updateReservation(temp, at: i)
                assigned2.forEach { store.markTable($0, occupied: true) }
            }
        }
        
        // Save after mocking
        saveReservationsToDisk()
    }
}
