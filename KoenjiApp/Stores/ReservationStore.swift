//
//  ReservationStore.swift
//  KoenjiApp
//
//  An updated version of ReservationStore without forcedTable logic.
//

import Foundation
import SwiftUI

class ReservationStore: ObservableObject {
    
    // MARK: - Properties
    
    // Lazy Initialization
    lazy var layoutManager: TableLayoutManager = TableLayoutManager(reservationStore: self)
    let tableAssignmentService: TableAssignmentService

    // Constants
    let reservationsFileName = "reservations.json"
    let baseTables = [
        TableModel(id: 1, name: "T1", maxCapacity: 2, row: 1, column: 14),
        TableModel(id: 2, name: "T2", maxCapacity: 2, row: 1, column: 10),
        TableModel(id: 3, name: "T3", maxCapacity: 2, row: 1, column: 6),
        TableModel(id: 4, name: "T4", maxCapacity: 2, row: 1, column: 1),
        TableModel(id: 5, name: "T5", maxCapacity: 2, row: 8, column: 7),
        TableModel(id: 6, name: "T6", maxCapacity: 2, row: 6, column: 1),
        TableModel(id: 7, name: "T7", maxCapacity: 2, row: 11, column: 1)
    ]
    
    // Layout Dimensions
    let totalRows: Int = 15
    let totalColumns: Int = 18

    
    /// Defines the order of tables for assignment (used in auto-assign).
    
    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var tables: [TableModel] = [] {
        didSet {
            print("Tables updated: \(tables.map { $0.name })")
            objectWillChange.send() // Notify SwiftUI about table updates
        }
    }
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    // Private Variables
    var grid: [[Int?]] = []
    
    // MARK: - Initializers
    
    init(
        tableAssignmentService: TableAssignmentService
) {
        self.tableAssignmentService = tableAssignmentService
        layoutManager.loadFromDisk()         // Load cached layouts if any
        loadReservationsFromDisk()          // Load reservation data
        
        // Ensure tables are populated
        if tables.isEmpty {
            print("No tables loaded. Populating base tables.")
            self.tables = baseTables
        }
    
        if reservations.isEmpty {
            print("No saved reservations found. Loading mock data.")
            mockData()                       // Load mock data if no reservations are found
        }
        
        layoutManager.markTablesInGrid()     // Initialize the grid with table positions
    }
}


// MARK: - CRUD Operations
extension ReservationStore {
    /// Adds a new reservation.
    /// Assumes the reservation's `tables` have already been assigned
    /// (manually or automatically). If not, it will be unassigned.
    /// This method simply appends it and marks its tables as occupied.
    func addReservation(_ reservation: Reservation) {
        // Append the new reservation
        reservations.append(reservation)
        
        // Mark any assigned tables as occupied
        reservation.tables.forEach { markTable($0, occupied: true) }
        
        // Save
        saveReservationsToDisk()
        
        print("Debug: Added new reservation \(reservation.id) with \(reservation.tables.count) tables.")
    }
    
    /// Updates an existing reservation with new details (e.g. new tables).
    /// Unmarks old tables, updates the store, then re-marks new tables as occupied.
    func updateReservation(_ updatedReservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == updatedReservation.id }) {
            let oldReservation = reservations[index]
            
            // Unmark old tables
            oldReservation.tables.forEach { unmarkTable($0) }
            
            // Overwrite the reservation in place
            reservations[index] = updatedReservation
            
            // Mark new tables as occupied
            updatedReservation.tables.forEach { markTable($0, occupied: true) }
            
            // Save
            saveReservationsToDisk()
            
            print("Debug: Updated reservation \(updatedReservation.id) with \(updatedReservation.tables.count) tables.")
        }
    }
    
    /// Deletes reservations at specified offsets and unmarks their tables.
    func deleteReservations(at offsets: IndexSet) {
        offsets.forEach { index in
            let reservation = reservations[index]
            // Unmark tables associated with the reservation
            reservation.tables.forEach { unmarkTable($0) }
        }
        // Remove reservations from the list
        reservations.remove(atOffsets: offsets)
        
        // Save
        saveReservationsToDisk()
    }
}

// MARK: - Mock Data
extension ReservationStore {
    /// Loads two sample reservations for demonstration purposes.
    private func mockData() {
        self.tables = baseTables
        print("Debug: Tables populated in mockData: \(tables.map { $0.name })")
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
        
        // Just append them (unassigned) for testing
        reservations.append(contentsOf: [mockReservation1, mockReservation2])
        
        // If you want to auto-assign them:
        if let assigned1 = tableAssignmentService.assignTablesAutomatically(for: mockReservation1, reservations: self.reservations, tables: self.tables) {
            let idx = reservations.firstIndex(where: { $0.id == mockReservation1.id })
            if let i = idx {
                var temp = reservations[i]
                temp.tables = assigned1
                reservations[i] = temp
                assigned1.forEach { markTable($0, occupied: true) }
            }
        }
        
        if let assigned2 = tableAssignmentService.assignTablesAutomatically(for: mockReservation2, reservations: self.reservations, tables: self.tables) {
            let idx = reservations.firstIndex(where: { $0.id == mockReservation2.id })
            if let i = idx {
                var temp = reservations[i]
                temp.tables = assigned2
                reservations[i] = temp
                assigned2.forEach { markTable($0, occupied: true) }
            }
        }
        
        // Save after mocking
        saveReservationsToDisk()
    }
}

// MARK: - Queries
extension ReservationStore {
    /// Updates the category (lunch, dinner, or noBookingZone) based on time
    func updateCategory(for time: Date) {
        let hour = Calendar.current.component(.hour, from: time)
        switch hour {
        case 12...15:
            selectedCategory = .lunch
        case 18...23:
            selectedCategory = .dinner
        default:
            selectedCategory = .noBookingZone
        }
        
        print("Category updated to \(selectedCategory?.rawValue ?? "none") based on time.")
    }
    
    /// Returns all reservations for a given date.
    func reservations(on date: Date) -> [Reservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        
        let targetDateString = formatter.string(from: date)
        
        return reservations.filter { $0.dateString == targetDateString }
    }

    /// Called when time changes (e.g. user picks a new time).
    func handleTimeUpdate(_ newTime: Date) {
        currentTime = newTime
        updateCategory(for: newTime)
        print("Time updated to \(newTime), category set to \(selectedCategory?.rawValue ?? "none")")
    }
}

// MARK: - Active Reservation Query
extension ReservationStore {
    /// Checks for an active reservation for the given table/time.
    func activeReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {
        let calendar = Calendar.current

        for reservation in reservations {
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
}

// MARK: - Persistence
extension ReservationStore {
    /// Saves all non-mock reservations to disk in JSON format.
    func saveReservationsToDisk() {
        let filteredReservations = reservations.filter { !$0.isMock }
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
    
    /// Loads reservations from disk, if the file exists.
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
            reservations = try decoder.decode([Reservation].self, from: data)
            print("Reservations loaded successfully.")
        } catch {
            print("Error loading reservations from disk: \(error)")
        }
    }
    
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(reservationsFileName)
    }
}

// MARK: - Getters
extension ReservationStore {
    func getReservations() -> [Reservation] {
        return self.reservations
    }

    func getTables() -> [TableModel] {
        return self.tables
    }
}

// MARK: - Table Assignment
extension ReservationStore {

    /// Decides if manual or auto/contiguous assignment based on `selectedTableID`.
    /// Returns the tables assigned or `nil` if assignment fails.
    func assignTables(
        for reservation: Reservation,
        selectedTableID: Int?
    ) -> [TableModel]? {
        if let tableID = selectedTableID {
            // MANUAL CASE
            // user forcibly picked a specific table => do "manual with contiguous first" approach
            guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                return nil // table not found
            }
            return tableAssignmentService.assignTablesManually(for: reservation, tables: self.tables, reservations: self.reservations, startingFrom: selectedTable)

        } else {
            // AUTO CASE
            // user selected "Auto" => prefer contiguous block if you want, or just do auto
            return tableAssignmentService.assignTablesPreferContiguous(for: reservation, reservations: self.reservations, tables: self.tables)

            // or if you only want the old auto, do:
            // return assignTablesAutomatically(for: reservation)
        }
    }
}


// MARK: - Misc Helpers
extension ReservationStore {
    func formattedDate(date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    func triggerFlashAnimation(for tableID: Int) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.tableAnimationState[tableID] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.tableAnimationState[tableID] = false
                }
            }
        }
    }
}


