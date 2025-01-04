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
    private let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]
    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var tables: [TableModel] = [] {
        didSet {
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
    
    init() {
        layoutManager.loadFromDisk()         // Load cached layouts if any
        loadReservationsFromDisk()          // Load reservation data
        
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
        if let assigned1 = assignTablesAutomatically(for: mockReservation1) {
            let idx = reservations.firstIndex(where: { $0.id == mockReservation1.id })
            if let i = idx {
                var temp = reservations[i]
                temp.tables = assigned1
                reservations[i] = temp
                assigned1.forEach { markTable($0, occupied: true) }
            }
        }
        
        if let assigned2 = assignTablesAutomatically(for: mockReservation2) {
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

// MARK: - Table Assignment
extension ReservationStore {
    /// Assigns tables manually starting from a forced table (`selectedTable`).
    /// 1) Attempts to seat the entire reservation in a contiguous block
    ///    (beginning at `selectedTable` in your `tableAssignmentOrder`).
    /// 2) If that fails, falls back to the "grab any free tables" approach.
    func assignTablesManually(
        for reservation: Reservation,
        startingFrom selectedTable: TableModel
    ) -> [TableModel]? {
        guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else { return nil }
        
        // First ensure the forced table itself is not occupied.
        if isTableOccupied(
            selectedTable,
            date: reservationDate,
            startTimeString: reservation.startTime,
            endTimeString: reservation.endTime,
            excluding: reservation.id
        ) {
            // Forced table is occupied => fail immediately
            return nil
        }
        
        // STEP 1: Try contiguous block (including forcedTable)
        if let contiguousBlock = findContiguousBlockStartingAtTable(
            forcedTable: selectedTable,
            reservation: reservation,
            reservationDate: reservationDate
        ) {
            // If we found a contiguous block that meets capacity, return it.
            return contiguousBlock
        }
        
        // STEP 2: Fallback to old approach: forced table + "grab any free tables"
        return fallbackManualAssignment(for: reservation, forcedTable: selectedTable, reservationDate: reservationDate)
    }
    /// Assigns tables automatically by iterating over them in a predefined order
    /// until capacity is met or no suitable tables remain.
    func assignTablesAutomatically(
        for reservation: Reservation
    ) -> [TableModel]? {
        guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else { return nil }
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        
        // Sort tables based on the defined order
        let orderedTables = tables.sorted { first, second in
            guard let firstIndex = tableAssignmentOrder.firstIndex(of: first.name),
                  let secondIndex = tableAssignmentOrder.firstIndex(of: second.name) else {
                return first.id < second.id
            }
            return firstIndex < secondIndex
        }
        
        // Assign tables if they are not occupied
        for table in orderedTables {
            if assignedCapacity >= reservation.numberOfPersons { break }
            if !isTableOccupied(
                table,
                date: reservationDate,
                startTimeString: reservation.startTime,
                endTimeString: reservation.endTime,
                excluding: reservation.id
            ) {
                assignedTables.append(table)
                assignedCapacity += table.maxCapacity
            }
        }
        
        if assignedCapacity < reservation.numberOfPersons {
            print("Error: Unable to assign enough tables for reservation \(reservation.id)!")
            return nil
        }
        
        print("Auto-assigned for \(reservation.id): \(assignedTables.map { $0.name })")
        return assignedTables
    }
    
    /// Attempts to find a contiguous block of tables (in sorted order) to seat
    /// the entire reservation. If that fails, falls back to auto-assignment.
    func assignTablesPreferContiguous(
        for reservation: Reservation
    ) -> [TableModel]? {
        guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else { return nil }
        
        // Sort tables in your predefined order
        let orderedTables = tables.sorted { first, second in
            guard let firstIndex = tableAssignmentOrder.firstIndex(of: first.name),
                  let secondIndex = tableAssignmentOrder.firstIndex(of: second.name) else {
                return first.id < second.id // fallback
            }
            return firstIndex < secondIndex
        }
        
        // 1) Try to find a single contiguous block that meets capacity
        if let contiguousBlock = findContiguousBlock(
            reservation: reservation,
            orderedTables: orderedTables,
            reservationDate: reservationDate
        ) {
            print("Contiguous assignment for \(reservation.id): \(contiguousBlock.map { $0.name })")
            return contiguousBlock
        }
        
        // 2) If no contiguous block was found, fallback to auto-assign
        let fallback = assignTablesAutomatically(for: reservation)
        if fallback != nil {
            print("Falling back to non-contiguous auto-assign for \(reservation.id).")
        }
        return fallback
    }
    
    /// Sliding-window approach to find one consecutive slice of unoccupied tables
    /// whose total capacity >= reservation.numberOfPersons.
    private func findContiguousBlock(
        reservation: Reservation,
        orderedTables: [TableModel],
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        let n = orderedTables.count
        
        var startIndex = 0
        while startIndex < n {
            var assignedCapacity = 0
            var block: [TableModel] = []
            var currentIndex = startIndex
            
            while currentIndex < n && assignedCapacity < neededCapacity {
                let table = orderedTables[currentIndex]
                
                // If this table is unoccupied in the reservation's time slot,
                // add it to the block
                if !isTableOccupied(
                    table,
                    date: reservationDate,
                    startTimeString: reservation.startTime,
                    endTimeString: reservation.endTime,
                    excluding: reservation.id
                ) {
                    block.append(table)
                    assignedCapacity += table.maxCapacity
                    currentIndex += 1
                } else {
                    // If we hit an occupied table, break this block
                    break
                }
            }
            
            if assignedCapacity >= neededCapacity {
                // Found a contiguous run that meets capacity
                return block
            }
            
            // Move to next starting point
            startIndex += 1
        }
        
        // None of the windows worked
        return nil
    }

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
            return assignTablesManually(for: reservation, startingFrom: selectedTable)
        } else {
            // AUTO CASE
            // user selected "Auto" => prefer contiguous block if you want, or just do auto
            return assignTablesPreferContiguous(for: reservation)
            // or if you only want the old auto, do:
            // return assignTablesAutomatically(for: reservation)
        }
    }
}

// MARK: - Occupancy Check
extension ReservationStore {
    /// Checks if a table is occupied, optionally excluding a specific reservation ID.
    func isTableOccupied(
        _ table: TableModel,
        date: Date,
        startTimeString: String,
        endTimeString: String,
        excluding reservationID: UUID? = nil
    ) -> Bool {
        guard
            let startTime = TimeHelpers.date(from: startTimeString, on: date),
            let endTime = TimeHelpers.date(from: endTimeString, on: date)
        else {
            return false
        }
        
        return reservations.contains { reservation in
            // Exclude a specific reservation if needed
            if let excludeID = reservationID, reservation.id == excludeID {
                return false
            }
            // Convert reservation times
            guard
                let reservationDate = reservation.date,
                let reservationStart = TimeHelpers.date(from: reservation.startTime, on: reservationDate),
                let reservationEnd = TimeHelpers.date(from: reservation.endTime, on: reservationDate)
            else {
                return false
            }
            
            // Overlapping date/time & same table => occupied
            return reservation.date == date
                && reservation.tables.contains(where: { $0.id == table.id })
                && TimeHelpers.timeRangesOverlap(
                    start1: reservationStart,
                    end1: reservationEnd,
                    start2: startTime,
                    end2: endTime
                )
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

extension ReservationStore {
    func availableTables(for reservation: Reservation) -> [TableModel] {
        guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else {
            return []
        }
        
        // Filter out tables that are occupied in this time range.
        return tables.filter { table in
            !isTableOccupied(
                table,
                date: reservationDate,
                startTimeString: reservation.startTime,
                endTimeString: reservation.endTime,
                excluding: reservation.id
            )
        }
    }
}


extension ReservationStore {
    /// Attempts to find a contiguous block of tables (starting exactly at `forcedTable`)
    /// that meets the reservation's capacity.
    /// If successful, returns that block of tables; otherwise returns nil.
    private func findContiguousBlockStartingAtTable(
        forcedTable: TableModel,
        reservation: Reservation,
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = forcedTable.maxCapacity
        
        // If forcedTable alone already can't be used, we skip (we've already checked occupancy).
        if assignedCapacity >= neededCapacity {
            // The forced table alone covers the capacity (unlikely, but let's handle it).
            return [forcedTable]
        }
        
        // Sort the tables in your predefined order
        let orderedTables = tables.sorted { a, b in
            guard let iA = tableAssignmentOrder.firstIndex(of: a.name),
                  let iB = tableAssignmentOrder.firstIndex(of: b.name) else {
                return a.id < b.id
            }
            return iA < iB
        }
        
        // Find the position of forcedTable in that order
        guard let startIndex = orderedTables.firstIndex(where: { $0.id == forcedTable.id }) else {
            // forced table not in list? Should never happen
            return nil
        }
        
        // We'll attempt to accumulate tables from [startIndex+1, ...]
        // continuing contiguously until capacity is met or we hit an occupied table.
        var block = [forcedTable]
        
        var j = startIndex + 1
        while j < orderedTables.count && assignedCapacity < neededCapacity {
            let candidate = orderedTables[j]
            
            // Check occupancy
            if !isTableOccupied(
                candidate,
                date: reservationDate,
                startTimeString: reservation.startTime,
                endTimeString: reservation.endTime,
                excluding: reservation.id
            ) {
                block.append(candidate)
                assignedCapacity += candidate.maxCapacity
                j += 1
            } else {
                // We hit an occupied table => contiguous run is broken
                return nil
            }
        }
        
        // Check final capacity
        if assignedCapacity >= neededCapacity {
            return block
        } else {
            // Even after continuing, we didn't meet capacity => fail
            return nil
        }
    }

    /// The old fallback approach:
    /// 1) We forcibly assign the chosen table,
    /// 2) Then pick other free tables from the sorted list until capacity is met.
    private func fallbackManualAssignment(
        for reservation: Reservation,
        forcedTable: TableModel,
        reservationDate: Date
    ) -> [TableModel]? {
        var assignedCapacity = forcedTable.maxCapacity
        var assignedTables: [TableModel] = [forcedTable]
        
        // Gather all other free tables (excluding the forced one)
        let availableTables = tables.filter { table in
            table.id != forcedTable.id
            && !isTableOccupied(
                table,
                date: reservationDate,
                startTimeString: reservation.startTime,
                endTimeString: reservation.endTime,
                excluding: reservation.id
            )
        }
        .sorted { a, b in
            guard let iA = tableAssignmentOrder.firstIndex(of: a.name),
                  let iB = tableAssignmentOrder.firstIndex(of: b.name) else {
                return a.id < b.id
            }
            return iA < iB
        }
        
        // Continue assigning until capacity is met or we run out of tables
        for table in availableTables {
            if assignedCapacity >= reservation.numberOfPersons {
                break
            }
            assignedTables.append(table)
            assignedCapacity += table.maxCapacity
        }
        
        if assignedCapacity < reservation.numberOfPersons {
            print("Error: Not enough tables to meet capacity in fallback approach!")
            return nil
        }
        
        print("Fallback manual assignment for \(reservation.id): \(assignedTables.map { $0.name })")
        return assignedTables
    }
}
