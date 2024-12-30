//
//  ReservationStore.swift
//  KoenjiApp
//
import Foundation

import SwiftUI

class ReservationStore: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var tables: [TableModel] = [] {
        didSet {
            objectWillChange.send() // Notify SwiftUI about table updates
        }
    }
    
    @Published var tableAnimationState: [Int: Bool] = [:] // Track animation state for tables
    @Published var currentlyDraggedTableID: Int? = nil
    

    
    @Published var isSidebarVisible = true
    
    @Published private var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch

    @Published var currentTime: Date = Date() // Default to the current date and time


    // A 2D grid for overlap checks. `nil` means the cell is unoccupied, otherwise it holds the table's ID.
    private var grid: [[Int?]] = []
    
    let baseTables = [
        TableModel(id: 1, name: "T1", maxCapacity: 2, row: 1, column: 16),
        TableModel(id: 2, name: "T2", maxCapacity: 2, row: 1, column: 11),
        TableModel(id: 3, name: "T3", maxCapacity: 2, row: 1, column: 6),
        TableModel(id: 4, name: "T4", maxCapacity: 2, row: 1, column: 1),
        TableModel(id: 5, name: "T5", maxCapacity: 2, row: 10, column: 7),
        TableModel(id: 6, name: "T6", maxCapacity: 2, row: 5, column: 1),
        TableModel(id: 7, name: "T7", maxCapacity: 2, row: 9, column: 1)
    ]
    
    // Expose total rows/columns so your LayoutView can do .frame(width: 17*cellSize, height: 14*cellSize) if desired
    // total rows is always 14
    var totalRows: Int = 14
    
    // total columns depends on isSidebarVisible
    var totalColumns: Int = 20
    
    init() {
        loadFromDisk()              // Load layouts
        loadReservationsFromDisk()  // Load saved reservations

        if reservations.isEmpty {
            print("No saved reservations found. Loading mock data.")
            mockData()
        }

        // Initialize the grid after loading tables
        markTablesInGrid()
    }

    /// Initializes the grid and sets up the tables.
    /// If `initial` is true, it resets the grid and tables to the base configuration.
    /// If `initial` is false, it only initializes the grid if `tables` is empty.
    func loadTables(initial: Bool = false) {
        guard initial || tables.isEmpty else { return } // Prevent unnecessary overwrites

        // Initialize the grid with `nil`, indicating all cells are unoccupied.
        grid = Array(repeating: Array(repeating: nil, count: totalColumns), count: totalRows)

        // Reset tables to the base configuration.
        tables = baseTables

        // Mark each table's position in the grid with its unique ID.
        for table in tables {
            markTable(table, occupied: true)
        }

        print("loadTables: Grid initialized with \(grid.count) rows and \(grid[0].count) columns, and tables marked.")
    }


    private func mockData() {
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
            dateString: "28/12/2024",
            category: .lunch,
            startTime: "12:00",
            endTime: "13:45",
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
            notes: "Allergic to peanuts",
            isMock: true
        )
        
        reservations.append(mockReservation1)
        reservations.append(mockReservation2)
        
        if let table1 = tables.first, let table2 = tables.dropFirst().first {
            assignTables(for: mockReservation1.id, startingFrom: table1, numberOfPersons: mockReservation1.numberOfPersons, dateString: mockReservation1.dateString, startTimeString: mockReservation1.startTime, endTimeString: mockReservation1.endTime)
            assignTables(for: mockReservation2.id, startingFrom: table2, numberOfPersons: mockReservation2.numberOfPersons, dateString: mockReservation2.dateString, startTimeString: mockReservation2.startTime, endTimeString: mockReservation2.endTime)
        }
    }
    
    // MARK: - CRUD
    
    func addReservation(
        name: String,
        phone: String,
        numberOfPersons: Int,
        date: String,
        category: Reservation.ReservationCategory,
        startTime: String,
        endTime: String,
        notes: String? = nil,
        forcedTable: TableModel? = nil // Add the forcedTable parameter
    ) {
        let newReservation = Reservation(
            id: UUID(),
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: date,
            category: category,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            tables: [],
            creationDate: Date()
        )

        // Add the new reservation without assigning tables yet
        reservations.append(newReservation)

        guard let addedReservation = reservations.last else {
            print("Debug: Failed to add reservation.")
            return
        }

        let startingTable = forcedTable ?? tables.first(where: {
            !isTableOccupied($0, date: addedReservation.date ?? Date(), startTimeString: startTime, endTimeString: endTime)
        }) ?? tables.first!

        print("Debug: Assigning tables for reservation \(addedReservation.id). Starting from table: \(startingTable.name)")

        // Directly assign tables
        assignTables(
            for: addedReservation.id,
            startingFrom: startingTable,
            numberOfPersons: numberOfPersons,
            dateString: date,
            startTimeString: startTime,
            endTimeString: endTime
        )

        // Save the state after assigning tables
        saveReservationsToDisk()
    }



    
    func resetLayout(for date: Date, category: Reservation.ReservationCategory) {
        loadLayout(for: date, category: category, reset: true)
        saveLayout(for: date, category: category)
        print("Layout reset for \(date) - \(category.rawValue)")
    }


    func updateReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            let oldTables = reservations[index].tables
            oldTables.forEach { unmarkTable($0) } // Unmark old tables

            reservations[index] = reservation
            reservation.tables.forEach { markTable($0, occupied: true) } // Mark new tables
            saveReservationsToDisk()
        }
    }

    func updateCategory(for time: Date) {
        let hour = Calendar.current.component(.hour, from: time)
        if hour >= 12 && hour <= 15 {
            selectedCategory = .lunch
        } else if hour >= 18 && hour <= 23 {
            selectedCategory = .dinner
        } else {
            selectedCategory = .noBookingZone
        }
        print("Category updated to \(selectedCategory?.rawValue ?? "none") based on time.")
    }


    func deleteReservations(at offsets: IndexSet) {
        offsets.forEach { index in
            let reservation = reservations[index]
            reservation.tables.forEach { unmarkTable($0) } // Unmark associated tables
        }
        reservations.remove(atOffsets: offsets)
        saveReservationsToDisk()
    }
    
    // MARK: - Move / Swap Logic
    
    func handleDropEnded(for date: Date, category: Reservation.ReservationCategory) {
        saveLayout(for: date, category: category)
        saveToDisk()
        print("handleDropEnded: Layout saved for \(category.rawValue) on \(date)")
        
        handleTimeUpdate(Date())
    }
    
    func handleTimeUpdate(_ newTime: Date) {
        currentTime = newTime
        updateCategory(for: newTime)

        // Log for debugging
        print("Time updated to \(newTime), category set to \(selectedCategory?.rawValue ?? "none")")
    }



    /// Moves a table to (toRow, toCol) if no overlap with other tables, allowing fine-tuning within its own cells.
    /// If the new position completely overlaps another table, perform a swap.
    /// Moves a table to (toRow, toCol) if no overlap with other tables, allowing fine-tuning within its own cells.
    /// If the new position completely overlaps another table of the same size, perform a swap.
    enum MoveResult {
           case move
           case swap(swappedTableID: Int)
           case invalid
       }
       
    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        let maxRow = totalRows - table.height
        let maxCol = totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))

        var newTable = table
        newTable.row = clampedRow
        newTable.column = clampedCol

        // Unmark the table's current position
        unmarkTable(table)
        print("moveTable: Attempting to move \(table.name) to (\(clampedRow), \(clampedCol))")

        // Check if the new position is valid
        if canPlaceTable(newTable) {
            print("moveTable: Can place table \(table.name) at (\(clampedRow), \(clampedCol))")

            // Identify overlapping tables if any
            for otherTable in tables where otherTable.id != table.id && tablesIntersect(newTable, otherTable) {
                print("moveTable: Found overlapping table \(otherTable.name) at (\(otherTable.row), \(otherTable.column))")

                // Attempt to swap
                let swapResult = swapTables(table, otherTable)
                switch swapResult {
                case .swap(let swappedID):
                    print("moveTable: Swapped \(table.name) with \(otherTable.name) successfully.")
                    return .swap(swappedTableID: swappedID)
                case .invalid:
                    // Swap failed; re-mark the original table's position
                    markTable(table, occupied: true)
                    print("moveTable: Swap failed. \(table.name) reverted to original position.")
                    return .invalid
                case .move:
                    // This case shouldn't occur here, but handle it gracefully
                    markTable(newTable, occupied: true)
                    print("moveTable: Unexpected move result.")
                    return .move
                }
            }

            // No overlap; perform a normal move
            withAnimation(.easeInOut(duration: 0.3)) {
                if let idx = tables.firstIndex(where: { $0.id == table.id }) {
                    tables[idx] = newTable
                }
            }
            markTable(newTable, occupied: true)
            saveToDisk()
            print("moveTable: Moved \(table.name) to (\(clampedRow), \(clampedCol)) successfully.")
            return .move
        } else {
            // Invalid move; re-mark the original table's position
            markTable(table, occupied: true)
            print("moveTable: Cannot place \(table.name) at (\(clampedRow), \(clampedCol)). Move failed.")
            return .invalid
        }
    }





    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height

        // Check for no overlap scenarios
        if table1MaxX <= table2MinX || table1MinX >= table2MaxX ||
            table1MaxY <= table2MinY || table1MinY >= table2MaxY {
            print("tablesIntersect: No overlap between \(table1.name) and \(table2.name)")
            return false
        }

        print("tablesIntersect: Overlap detected between \(table1.name) and \(table2.name)")
        return true
    }






    
    /// Swaps the positions of two tables if the swap does not cause overlaps with other tables.
    /// Swaps the positions of two tables if the swap does not cause overlaps with other tables.
    /// Swaps the positions of two tables if the swap does not cause overlaps with other tables.
    func swapTables(_ tableA: TableModel, _ tableB: TableModel) -> MoveResult {
        print("swapTables: Initiating swap between \(tableA.name) and \(tableB.name)")
        
        // Unmark both tables from their current positions
        unmarkTable(tableA)
        unmarkTable(tableB)
        print("swapTables: Unmarked \(tableA.name) and \(tableB.name) from grid.")
        
        // Swap their row and column positions
        let swappedRowA = tableB.row
        let swappedColA = tableB.column
        let swappedRowB = tableA.row
        let swappedColB = tableA.column
        
        var swappedTableA = tableA
        swappedTableA.row = swappedRowA
        swappedTableA.column = swappedColA
        
        var swappedTableB = tableB
        swappedTableB.row = swappedRowB
        swappedTableB.column = swappedColB
        
        print("swapTables: Swapped coordinates - \(swappedTableA.name): (\(swappedTableA.row), \(swappedTableA.column)), \(swappedTableB.name): (\(swappedTableB.row), \(swappedTableB.column))")
        
        // **1. Safely Retrieve Indexes Before Animation**
        // Use guard statements to ensure both tables exist in the `tables` array.
        guard let indexA = tables.firstIndex(where: { $0.id == tableA.id }) else {
            print("swapTables: Table \(tableA.name) not found in tables array.")
            return .invalid
        }
        
        guard let indexB = tables.firstIndex(where: { $0.id == tableB.id }) else {
            print("swapTables: Table \(tableB.name) not found in tables array.")
            return .invalid
        }
        
        // **2. Update Table Positions**

        withAnimation(.easeInOut(duration: 0.6)) {
            tables[indexA] = swappedTableA
            tables[indexB] = swappedTableB
        }
        
        // **3. Validate the New Positions**
        if canPlaceTable(swappedTableA) && canPlaceTable(swappedTableB) {
            // Mark new positions in the grid.
            markTable(swappedTableA, occupied: true)
            markTable(swappedTableB, occupied: true)
            print("swapTables: Marked swapped positions in grid.")
        
            // **4. Trigger Flash Animation for the Swapped Table Only**
            triggerFlashAnimation(for: swappedTableA.id)
            triggerFlashAnimation(for: swappedTableB.id)
        
            // Save the updated layout.
            saveToDisk()
            print("swapTables: Swap successful between \(swappedTableA.name) and \(swappedTableB.name).")
            return .swap(swappedTableID: swappedTableB.id)
        } else {
            // **5. Handle Invalid Swap: Revert Changes**
            print("swapTables: Swap invalid. Reverting tables to original positions.")
            
            // Revert tableA's position without animation.

            
            // Revert tableB's position with animation.
            withAnimation(.easeInOut(duration: 0.6)) {
                tables[indexA] = tableA
                tables[indexB] = tableB
            }
            
            // Re-mark original positions in the grid.
            markTable(tableA, occupied: true)
            markTable(tableB, occupied: true)
            print("swapTables: Re-marked original positions in grid.")
            return .invalid
        }
    }

    
    // MARK: - Intersection / Overlap
    
    private func boundingBox(for table: TableModel) -> CGRect {
        let x = CGFloat(table.column)
        let y = CGFloat(table.row)
        let w = CGFloat(table.width)
        let h = CGFloat(table.height)
        return CGRect(x: x, y: y, width: w, height: h)
    }
    

    
    // MARK: - Filter by Date
    
    func reservations(on date: Date) -> [Reservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current

        let targetDateString = formatter.string(from: date)
        
        return reservations.filter { $0.dateString == targetDateString }
    }
    
    // MARK: - Occupancy Checks
    func areTablesInSameReservation(_ tableA: TableModel, _ tableB: TableModel) -> Bool {
        for reservation in reservations {
            let tableIDs = Set(reservation.tables.map(\.id))
            if tableIDs.contains(tableA.id) && tableIDs.contains(tableB.id) {
                return true
            }
        }
        return false
    }


    /// Returns true if the table can be placed without overlapping other tables
    /// Returns true if the table can be placed without overlapping other tables,
    /// excluding any tables with IDs in the `excludedTableIDs` set.
    func canPlaceTable(_ table: TableModel, excluding excludedTableIDs: Set<Int> = []) -> Bool {
        print("Debug: Checking if table \(table.name) can be placed at (\(table.row), \(table.column))")
        
        var overlappingTables: [TableModel] = []
        
        for otherTable in tables where otherTable.id != table.id && !excludedTableIDs.contains(otherTable.id) {
            if tablesIntersect(table, otherTable) {
                overlappingTables.append(otherTable)
            }
        }
        
        if overlappingTables.isEmpty {
            return true
        }
        
        // Allow placement if there's exactly one overlapping table of the same size
        if overlappingTables.count == 1 {
            let overlappingTable = overlappingTables.first!
            let sameSize = (overlappingTable.width == table.width) && (overlappingTable.height == table.height)
            print("Debug: Overlapping table \(overlappingTable.name) has the same size: \(sameSize)")
            return sameSize
        }
        
        // More than one overlapping table or size mismatch
        print("Debug: Multiple overlapping tables or size mismatch. Cannot place \(table.name) at (\(table.row), \(table.column))")
        return false
    }





    
    /// Mark/unmark the table in the grid with its ID
    /// Marks or unmarks the table in the grid with its ID.
    /// Mark/unmark the table in the grid with its ID
    func markTable(_ table: TableModel, occupied: Bool) {
        for r in table.row..<(table.row + table.height) {
            for c in table.column..<(table.column + table.width) {
                guard r >= 0, r < grid.count, c >= 0, c < grid[0].count else {
                    print("markTable: Invalid cell (\(r), \(c)). Skipping.")
                    continue
                }
                grid[r][c] = occupied ? table.id : nil
            }
        }
        print("markTable: \(occupied ? "Marked" : "Unmarked") \(table.name) in grid at row \(table.row), column \(table.column).")
    }


    func unmarkTable(_ table: TableModel) {
        markTable(table, occupied: false)
    }

    
    func printGridState() {
        print("Current Grid State:")
        for (rowIndex, row) in grid.enumerated() {
            var rowString = ""
            for cell in row {
                if let id = cell {
                    rowString += "\(id) "
                } else {
                    rowString += ". "
                }
            }
            print(rowString)
        }
    }

    
    // MARK: - Active Reservation
    
    func activeReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {


        let calendar = Calendar.current

        // Extract only the date components (year, month, day) from the query date
        let queryDateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        for reservation in reservations {
            // Parse the reservation's `dateString` into a `Date` and extract its components
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            formatter.timeZone = TimeZone.current

            guard let reservationDate = formatter.date(from: reservation.dateString) else {
                print("Debug: Invalid reservation date string for \(reservation.id): \(reservation.dateString)")
                continue
            }

            let reservationDateComponents = calendar.dateComponents([.year, .month, .day], from: reservationDate)

            // Compare the stripped date components
            if queryDateComponents != reservationDateComponents {
 
                continue
            }

            // Check if the reservation is active
            if !reservation.isActive(queryDate: reservationDate, queryTime: time) {
                print("Debug: Reservation \(reservation.id) is not active at the given time.")
                continue
            }

            // Check if the table is assigned to this reservation
            if !reservation.tables.contains(where: { $0.id == table.id }) {
                print("Debug: Table \(table.id) is not assigned to reservation \(reservation.id).")
                continue
            }

            print("Debug: Active reservation found: \(reservation.id)")
            return reservation
        }

        print("Debug: No active reservation for table \(table.name)")
        return nil
    }


    func isTableOccupied(
        _ table: TableModel,
        date: Date,
        startTimeString: String,
        endTimeString: String
    ) -> Bool {
        guard
            let startTime = TimeHelpers.date(from: startTimeString, on: date),
            let endTime = TimeHelpers.date(from: endTimeString, on: date)
        else {
            return false
        }

        // Check for table occupancy
        return reservations.contains(where: { reservation in
            guard let reservationDate = reservation.date else { return false }
            if reservationDate != date { return false }
            if !reservation.tables.contains(where: { $0.id == table.id }) { return false }

            // Check for overlapping time ranges
            let reservationStart = TimeHelpers.date(from: reservation.startTime, on: date)
            let reservationEnd = TimeHelpers.date(from: reservation.endTime, on: date)

            return TimeHelpers.timeRangesOverlap(start1: reservationStart, end1: reservationEnd,
                                                 start2: startTime, end2: endTime)
        })
    }
    
    private func isTableOccupiedByActiveReservation(_ table: TableModel, for reservationID: UUID? = nil) -> Bool {
        // Use the current date and time for active reservations
        let now = Date()

        return reservations.contains(where: { reservation in
            // Exclude the current reservation being processed
            if let reservationID = reservationID, reservation.id == reservationID {
                return false
            }
            // Check if the reservation is active and assigned to the table
            return reservation.isActive(queryDate: now, queryTime: now) &&
                   reservation.tables.contains(where: { $0.id == table.id })
        })
    }


    // MARK: - Assign Tables
    
    func assignTables(
        for reservationID: UUID,
        startingFrom forcedTable: TableModel,
        numberOfPersons: Int,
        dateString: String,
        startTimeString: String,
        endTimeString: String
    ) {
        guard let resIndex = reservations.firstIndex(where: { $0.id == reservationID }) else {
            print("Debug: Reservation with ID \(reservationID) not found.")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        guard let reservationDate = formatter.date(from: dateString) else {
            print("Debug: Invalid reservation date format: \(dateString)")
            return
        }

        let neededCapacity = numberOfPersons
        var assignedCapacity = 0
        var assignedTables = [TableModel]()

        // Handle forced table first
        if !isTableOccupied(forcedTable, date: reservationDate, startTimeString: startTimeString, endTimeString: endTimeString) {
            assignedTables.append(forcedTable)
            assignedCapacity += forcedTable.maxCapacity
        } else {
            print("Debug: Forced table \(forcedTable.name) is occupied.")
        }

        // Calculate additional tables needed
        let additionalCapacityNeeded = neededCapacity - assignedCapacity

        if additionalCapacityNeeded > 0 {
            // Filter available tables in preferred order
            let preferredOrder = [1, 2, 3, 4, 6, 7, 5]
            let availableTables = preferredOrder.compactMap { tableID in
                tables.first(where: { table in
                    table.id == tableID &&
                    !isTableOccupied(
                        table,
                        date: reservationDate,
                        startTimeString: startTimeString,
                        endTimeString: endTimeString
                    ) &&
                    !assignedTables.contains(where: { $0.id == table.id }) // Avoid duplicates
                })
            }
            
            print("Available tables: \(tables.map { $0.name })")
            print("Filtered tables: \(availableTables.map { $0.name })")

            // Assign additional tables
            for table in availableTables {
                if assignedCapacity >= neededCapacity { break }
                assignedTables.append(table)
                assignedCapacity += table.maxCapacity
            }
        }

        // Assign the tables to the reservation
        reservations[resIndex].tables = assignedTables

        // Mark the assigned tables in the grid
        for table in assignedTables {
            markTable(table, occupied: true)
        }

        print("Debug: Assigned tables for reservation \(reservationID): \(assignedTables.map { $0.name })")

        // Trigger UI updates
        objectWillChange.send()
    }


    
    private func layoutKey(for date: Date, category: Reservation.ReservationCategory) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return "\(dateString)-\(category.rawValue)"
    }

    func saveLayout(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutKey(for: date, category: category)
        cachedLayouts[key] = tables
        saveToDisk()
        print("Layout saved for key: \(key)")
    }

    
    func loadLayout(for date: Date, category: Reservation.ReservationCategory, reset: Bool = false) {
        let key = layoutKey(for: date, category: category)
        
        if reset {
            tables = baseTables
        } else if let layout = cachedLayouts[key] {
            tables = layout
        } else {
            tables = baseTables
        }

        // Ensure any time-based category switches are applied
        updateCategory(for: currentTime)

        // Update the grid to reflect current table positions
        markTablesInGrid()
    }



    private func markTablesInGrid() {
        // Reset the grid
        grid = Array(repeating: Array(repeating: nil, count: totalColumns), count: totalRows)
        for table in tables {
            markTable(table, occupied: true)
        }
    }




    func loadDefaultLayout(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        // Return the default layout for the given category or a blank slate
        let defaultLayout = baseTables
        return defaultLayout
    }
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            print("Layouts saved successfully.")
        } else {
            print("Failed to encode cached layouts.")
        }
    }


    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts") {
            let decoder = JSONDecoder()
            if let decodedLayouts = try? decoder.decode([String: [TableModel]].self, from: data) {
                cachedLayouts = decodedLayouts
                print("Cached layouts loaded successfully: \(cachedLayouts.keys)")
            } else {
                print("Failed to decode cached layouts.")
            }
        } else {
            print("No cached layouts found.")
        }
    }



}

extension TimeHelpers {
    static func timeRangesOverlap(start1: Date?, end1: Date?, start2: Date, end2: Date) -> Bool {
        guard let start1 = start1, let end1 = end1 else { return false }
        return (start1 < end2 && end1 > start2)
    }

    static func date(from timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: components.hour ?? 0,
                             minute: components.minute ?? 0,
                             second: 0,
                             of: date)
    }
}

import Foundation

private let reservationsFileName = "reservations.json"

extension ReservationStore {
    // Save reservations to a file
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
            print("Failed to save reservations: \(error)")
        }
    }



    // Load reservations from a file
    func loadReservationsFromDisk() {
        let fileURL = getReservationsFileURL()
        print("Loading reservations from: \(fileURL.path)")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Reservations file not found.")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            print("Loaded reservations data: \(String(data: data, encoding: .utf8) ?? "N/A")")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            reservations = try decoder.decode([Reservation].self, from: data)
            print("Reservations loaded successfully: \(reservations)")
        } catch {
            print("Failed to load reservations: \(error)")
        }
    }



    // Get the file URL for reservations
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(reservationsFileName)
    }
}

extension ReservationStore {
    func triggerFlashAnimation(for tableID: Int) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) { // Adjusted duration
                self.tableAnimationState[tableID] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match the duration
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.tableAnimationState[tableID] = false
                }
            }
        }
    }
}
