//
//  TableServices.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

// PLACEHOLDER: - LayoutServices.swift

import Foundation
import SwiftUI
import os

/// LayoutServices: Manages table layouts for different dates and reservation categories.
/// This class handles table positioning, movement, locking, and assignment for reservations.
/// It provides functionality for saving and loading layouts, checking table adjacency,
/// and managing the grid representation of tables.
class LayoutServices: ObservableObject {
    // MARK: - Private Properties
    /// Logger instance for the LayoutServices class.
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "LayoutServices"
    )
    
    /// The reservation store containing all reservation data.
    let store: ReservationStore
    /// The table store that serves as the single source of truth for table data.
    let tableStore: TableStore          // single source of truth
    /// Service responsible for table assignment logic.
    private let tableAssignmentService: TableAssignmentService
    
    /// Tracks animation states for tables by their ID.
    @Published var tableAnimationState: [Int: Bool] = [:]
    /// ID of the table currently being dragged, if any.
    @Published var currentlyDraggedTableID: Int? = nil
    /// Flag indicating whether the sidebar is visible.
    @Published var isSidebarVisible = true
    /// Cache of table layouts indexed by date-category keys.
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    /// Currently selected reservation category.
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    /// Current time used for layout calculations.
    @Published var currentTime: Date = Date()
    
    /// Current set of tables being displayed.
    @Published var tables: [TableModel] = []
    
    /// Dictionary tracking locked time intervals for each table by ID.
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    /// The key of the last saved layout.
    var lastSavedKey: String? = nil
    /// Flag indicating whether a layout update is in progress.
    var isUpdatingLayout: Bool = false
    
    // MARK: - Initializer
    /// Initializes the LayoutServices with required dependencies.
    /// - Parameters:
    ///   - store: The reservation store containing all reservation data.
    ///   - tableStore: The table store that serves as the single source of truth for table data.
    ///   - tableAssignmentService: Service responsible for table assignment logic.
    init(store: ReservationStore, tableStore: TableStore, tableAssignmentService: TableAssignmentService) {
        self.store = store
        self.tableStore = tableStore
        self.tableAssignmentService = tableAssignmentService
        let key = keyFor(date: currentTime, category: selectedCategory ?? .lunch)
        if cachedLayouts[key] == nil {
            cachedLayouts[key] = self.tableStore.baseTables
            self.tables = self.tableStore.baseTables
        }
    }
    
    /// Returns the current set of tables.
    /// - Returns: An array of TableModel objects representing the current tables.
    func getTables() -> [TableModel] {
        return self.tables
    }
    
    /// Generates a unique key based on date and category.
    func keyFor(date: Date, category: Reservation.ReservationCategory) -> String {
        let formattedDateTime = DateHelper.formatDate(date) // Ensure the date includes both date and time
        return "\(formattedDateTime)-\(category.rawValue)"
    }
    
    /// Loads tables for a specific date and category.
    func loadTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let fullKey = keyFor(date: date, category: category)
        Self.logger.debug("Loading tables for key: \(fullKey)")

        // Check if the exact layout exists
        if let tables = cachedLayouts[fullKey] {
            // Assign to self.tables *on the main thread*
                self.tables = tables
                Self.logger.debug("Loaded exact layout for key: \(fullKey)")
            return tables
        }

        // Fallback: Use the closest prior configuration
        let fallbackKey = findClosestPriorKey(for: date, category: category)
        if let fallbackTables = fallbackKey.flatMap({ cachedLayouts[$0] }) {
            // Copy the fallback layout for this specific timeslot
            cachedLayouts[fullKey] = fallbackTables
            
                self.tables = fallbackTables
                Self.logger.debug("Copied fallback layout from key: \(fallbackKey ?? "none") to key: \(fullKey)")
            return fallbackTables
        }

        // Final fallback: Initialize with base tables
        self.cachedLayouts[fullKey] = self.tableStore.baseTables
        self.tables = self.tableStore.baseTables
        Self.logger.debug("Initialized new layout for key: \(fullKey) with base tables")
        return self.tableStore.baseTables
    }
    
    /// Finds the closest prior key in the cached layouts for a given date and category.
    /// - Parameters:
    ///   - date: The date to find a layout for.
    ///   - category: The reservation category.
    /// - Returns: The closest prior key if found, otherwise nil.
    private func findClosestPriorKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Sort keys chronologically
        return sortedKeys.last { $0 < "\(formattedDate)-\(category.rawValue)" }
    }
    
    /// Saves tables for a specific date and category.
    func saveTables(_ tables: [TableModel], for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)
        cachedLayouts[fullKey] = tables
        Self.logger.debug("Saved tables for key: \(fullKey)")

        // Propagate changes to future timeslots
        propagateLayoutChange(from: fullKey, tables: tables)
        saveToDisk()
    }
    
    /// Saves the current cached layouts to disk using UserDefaults.
    /// Encodes the layouts dictionary to JSON data and stores it with the key "cachedLayouts".
    /// Logs success or failure of the operation.
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            Self.logger.info("Layouts saved successfully")
        } else {
            Self.logger.error("Failed to encode cached layouts")
        }
    }
    
    /// Propagates layout changes from a specific key to future timeslots.
    /// - Parameters:
    ///   - key: The source key from which to propagate changes.
    ///   - tables: The table layout to propagate.
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tables
            Self.logger.debug("Propagated layout to future key: \(futureKey)")
        }
    }
    
    /// Resets tables for a specific date and category to the base configuration.
    /// - Parameters:
    ///   - date: The date for which to reset tables.
    ///   - category: The reservation category.
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)

        // Reset the layout for this specific key
        cachedLayouts[fullKey] = tableStore.baseTables
        tables = tableStore.baseTables
        Self.logger.notice("Reset tables for key: \(fullKey) to base tables")

        // Propagate reset to future timeslots
        propagateLayoutReset(from: fullKey)
        saveToDisk()
    }

    /// Propagates layout reset from a specific key to future timeslots.
    /// - Parameter key: The source key from which to propagate the reset.
    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tableStore.baseTables
            Self.logger.debug("Reset future key: \(futureKey) to base tables")
        }
    }
    
    /// Loads cached layouts from disk storage.
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
               let layoutCount = decoded.keys.count  // Store count in local variable
               Self.logger.info("Cached layouts loaded successfully: \(layoutCount) layouts")
        } else {
            Self.logger.warning("No cached layouts found")
        }
    }
    
    /// Sets the current tables array.
    /// - Parameter newTables: The new array of tables to set.
    func setTables(_ newTables: [TableModel]) {
            self.tables = newTables
    }
    
    /// Sets the cached layouts dictionary.
    /// - Parameter layouts: The new dictionary of layouts to set.
    func setCachedLayouts(_ layouts: [String: [TableModel]]) {
            self.cachedLayouts = layouts
    }
    
    /// Assigns tables for a reservation, either manually or automatically.
    /// - Parameters:
    ///   - reservation: The reservation to assign tables for.
    ///   - selectedTableID: Optional ID of a manually selected table. If nil, automatic assignment is used.
    /// - Returns: A result containing either the assigned tables or an error.
    func assignTables(
        for reservation: Reservation,
        selectedTableID: Int?
    ) -> Result<[TableModel], TableAssignmentError> {
        let reservationDate = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.startTime
        )
        guard let reservationStart = reservation.startTimeDate,
            let reservationEnd = reservation.endTimeDate else { return .failure(.unknown)}
        
        let layoutKey = keyFor(date: reservationDate, category: reservation.category)
        guard let tables = cachedLayouts[layoutKey]
               ?? generateAndCacheLayout(for: layoutKey, date: reservationDate, category: reservation.category)
        else {
            return .failure(.noTablesLeft)  // Or .unknown if you prefer
        }
        
        // Manual assignment if tableID is set
        if let tableID = selectedTableID {
            // 1) Check existence
            guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                return .failure(.tableNotFound)
            }
            
            // 2) Check lock
            if isTableLocked(tableID: selectedTable.id, start: reservationStart, end: reservationEnd), !reservation.tables.contains(selectedTable) {
                return .failure(.tableLocked)
            }
            
            // 3) Attempt manual assignment
            let assignedTables = tableAssignmentService.assignTablesManually(
                for: reservation,
                tables: tables,
                reservations: store.reservations,
                startingFrom: selectedTable
            )
            
            if let assignedTables = assignedTables {
                // Lock tables, update store, etc.
                lockTable(tableID: selectedTable.id, start: reservationStart, end: reservationEnd)
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        self.store.reservations.append(updatedReservation)
                }
                return .success(assignedTables)
            } else {
                // Potentially differentiate between not enough capacity vs. table locked
                return .failure(.insufficientTables)
            }
            
        } else {
            // Auto assignment
            let unlockedTables = tables.filter { !isTableLocked(tableID: $0.id, start: reservationStart, end: reservationEnd) }
            guard !unlockedTables.isEmpty else {
                return .failure(.noTablesLeft)
            }
            
            if let assignedTables = tableAssignmentService.assignTablesPreferContiguous(
                for: reservation,
                reservations: store.reservations,
                tables: unlockedTables
            ) {
                // Lock each table, update store, etc.
                assignedTables.forEach { lockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        self.store.reservations.append(updatedReservation)
                }
                return .success(assignedTables)
            } else {
                // Distinguish not enough capacity from unknown error, if you'd like:
                return .failure(.insufficientTables)
            }
        }
    }
    
    /// Generates and caches a layout for a specific key, date, and category.
    /// - Parameters:
    ///   - layoutKey: The key to use for caching the layout.
    ///   - date: The date for which to generate the layout.
    ///   - category: The reservation category.
    /// - Returns: The generated table layout, or nil if generation failed.
    func generateAndCacheLayout(for layoutKey: String, date: Date, category: Reservation.ReservationCategory) -> [TableModel]? {
        Self.logger.debug("Generating layout for key: \(layoutKey)")
        let layout = loadTables(for: date, category: category) // Your layout generation logic
        
        if !layout.isEmpty {
            cachedLayouts[layoutKey] = layout
            Self.logger.debug("Layout cached for key: \(layoutKey)")
        } else {
            Self.logger.warning("Failed to generate layout for key: \(layoutKey)")
        }
        return layout
    }
    
    /// Locks a table for a specific time interval.
    /// - Parameters:
    ///   - tableID: The ID of the table to lock.
    ///   - start: The start time of the lock interval.
    ///   - end: The end time of the lock interval.
    func lockTable(tableID: Int, start: Date, end: Date) {
        var intervals = lockedIntervals[tableID] ?? []
        intervals.append((start, end))  // or TimeIntervalLock(...)
        lockedIntervals[tableID] = intervals
    }

    /// Unlocks a table for a specific time interval.
    /// - Parameters:
    ///   - tableID: The ID of the table to unlock.
    ///   - start: The start time of the lock interval to remove.
    ///   - end: The end time of the lock interval to remove.
    func unlockTable(tableID: Int, start: Date, end: Date) {
        guard var intervals = lockedIntervals[tableID] else { return }
        // Remove the matching interval. Or if you store a reservation ID:
        // remove the item associated with that reservation ID
        intervals.removeAll(where: { $0.start == start && $0.end == end })
        lockedIntervals[tableID] = intervals
    }

    /// Unlocks all tables by clearing all lock intervals.
    func unlockAllTables() {
        lockedIntervals.removeAll()
    }
    
    /// Checks if a table is locked for a specific time interval.
    /// - Parameters:
    ///   - tableID: The ID of the table to check.
    ///   - start: The start time of the interval to check.
    ///   - end: The end time of the interval to check.
    /// - Returns: True if the table is locked for any part of the specified interval, false otherwise.
    func isTableLocked(tableID: Int, start: Date, end: Date) -> Bool {
        guard let intervals = lockedIntervals[tableID] else {
            return false
        }
        for interval in intervals {
            // Overlap condition: (start1 < end2) && (start2 < end1)
            if start < interval.end && interval.start < end {
                return true
            }
        }
        return false
    }
    
    /// Checks if a layout exists for a specific date and category.
    /// - Parameters:
    ///   - date: The date to check.
    ///   - category: The reservation category.
    /// - Returns: True if a layout exists, false otherwise.
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return cachedLayouts[key] != nil
    }
    
    /// Computes a unique signature for a set of tables based on their properties.
    /// - Parameter tables: The array of tables to compute a signature for.
    /// - Returns: A string signature that uniquely identifies the table configuration.
    func computeLayoutSignature(tables: [TableModel]) -> String {
        let sortedTables = tables.sorted { $0.id < $1.id }
        let components = sortedTables.map { table in
            "id_\(table.id)_row_\(table.row)_col_\(table.column)"
        }
        return components.joined(separator: ";")
    }
}

// MARK: - Table Placement Helpers
/// Extension providing methods for table placement and overlap detection.
extension LayoutServices {
    /// Checks if a table can be placed at a new position for a given date and category.
    func canPlaceTable(_ table: TableModel, for date: Date, category: Reservation.ReservationCategory, activeTables: [TableModel]) -> Bool {
        Self.logger.debug("Checking placement for table: \(table.name) at row: \(table.row), column: \(table.column), width: \(table.width), height: \(table.height)")
        
        // Ensure the table is within grid bounds
        guard table.row >= 0, table.column >= 0,
              table.row + table.height <= tableStore.totalRows,
              table.column + table.width <= tableStore.totalColumns else {
            Self.logger.notice("Table \(table.name) is out of bounds")
            return false
        }
                
        // Check for overlap with existing tables
        for existingTable in activeTables where existingTable.id != table.id {
            Self.logger.debug("Comparing with existing table: \(existingTable.name) at row: \(existingTable.row), column: \(existingTable.column), width: \(existingTable.width), height: \(existingTable.height)")
            if tablesIntersect(existingTable, table) {
                Self.logger.notice("Table \(table.name) intersects with \(existingTable.name). Cannot place")
                return false
            }
        }
        
        Self.logger.debug("Table \(table.name) can be placed")
        return true
    }
    
    
    /// Checks if two tables overlap with each other.
    /// - Parameters:
    ///   - table1: The first table to check.
    ///   - table2: The second table to check.
    /// - Returns: True if the tables overlap, false otherwise.
    private func tablesOverlap(table1: TableModel, table2: TableModel) -> Bool {
        let table1Rect = CGRect(
            x: table1.column,
            y: table1.row,
            width: table1.width,
            height: table1.height
        )
        let table2Rect = CGRect(
            x: table2.column,
            y: table2.row,
            width: table2.width,
            height: table2.height
        )
        return table1Rect.intersects(table2Rect)
    }
}

/// Extension providing methods for table movement, occupancy checks, and adjacency detection.
extension LayoutServices {
    
    // MARK: - Movement

    /// Represents the result of a table move operation.
    enum MoveResult {
        case move    /// The move was successful.
        case invalid /// The move was invalid and could not be completed.
    }

    /// Attempts to move a table to a new position.
    /// - Parameters:
    ///   - table: The table to move.
    ///   - toRow: The target row position.
    ///   - toCol: The target column position.
    /// - Returns: A MoveResult indicating whether the move was successful.
    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))

        var newTable = table
        newTable.row = clampedRow
        newTable.column = clampedCol

        // Unmark the table's current position
        unmarkTable(table)
        Self.logger.debug("Attempting to move \(table.name) to (\(clampedRow), \(clampedCol))")

        // Check if the new position is valid
        if canPlaceTable(newTable) {
            Self.logger.debug("Can place table \(table.name) at (\(clampedRow), \(clampedCol))")

            // Perform the move
            withAnimation(.easeInOut(duration: 0.5)) {
                if let idx = self.tables.firstIndex(where: { $0.id == table.id }) {
                    self.tables[idx] = newTable
                }
                self.markTable(newTable, occupied: true)
            }
            Self.logger.info("Moved \(table.name) to (\(clampedRow), \(clampedCol)) successfully")
            return .move
        } else {
            // Invalid move; re-mark the original table's position
            withAnimation(.spring) {
                self.markTable(table, occupied: true)
            }
            Self.logger.notice("Cannot place \(table.name) at (\(clampedRow), \(clampedCol)). Move failed")
            return .invalid
        }
    }

    // MARK: - Occupancy Checks

    /// Checks if two tables intersect with each other.
    /// - Parameters:
    ///   - table1: The first table to check.
    ///   - table2: The second table to check.
    /// - Returns: True if the tables intersect, false otherwise.
    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height

        Self.logger.debug("Checking intersection - Table 1: (\(table1MinX), \(table1MaxX)) x (\(table1MinY), \(table1MaxY))")
        Self.logger.debug("Checking intersection - Table 2: (\(table2MinX), \(table2MaxX)) x (\(table2MinY), \(table2MaxY))")

        // Check for no overlap scenarios
        let intersects = !(table1MaxX <= table2MinX || table1MinX >= table2MaxX || table1MaxY <= table2MinY || table1MinY >= table2MaxY)
        Self.logger.debug("Intersection result: \(intersects)")
        return intersects
    }

    /// Checks if a table can be placed without overlapping with other tables.
    /// - Parameter table: The table to check placement for.
    /// - Returns: True if the table can be placed, false otherwise.
    func canPlaceTable(_ table: TableModel) -> Bool {
        for otherTable in tables where otherTable.id != table.id {
            if tablesIntersect(table, otherTable) {
                return false
            }
        }
        return true
    }

    // MARK: - Helpers

    /// Marks a table as occupied or unoccupied in the grid.
    /// - Parameters:
    ///   - table: The table to mark.
    ///   - occupied: Whether the table should be marked as occupied (true) or unoccupied (false).
    func markTable(_ table: TableModel, occupied: Bool) {
        Self.logger.debug("Marking table \(table.id) at \(table.row), \(table.column) with occupied=\(occupied)")
        
        let tableCount = tables.count
        Self.logger.debug("Tables and grid state after operation: \(tableCount) tables")
        
        for r in table.row..<(table.row + table.height) {
            for c in table.column..<(table.column + table.width) {
                guard r >= 0, r < tableStore.grid.count, c >= 0, c < tableStore.grid[0].count else {
                    Self.logger.warning("Skipping out-of-bounds position (\(r), \(c))")
                    continue }
                tableStore.grid[r][c] = occupied ? table.id : nil
            }
        }
    }

    /// Unmarks a table in the grid, setting it as unoccupied.
    /// - Parameter table: The table to unmark.
    func unmarkTable(_ table: TableModel) {
        
        markTable(table, occupied: false)
    }

    /// Returns a bounding box rectangle for a table.
    /// - Parameter table: The table to get a bounding box for.
    /// - Returns: A CGRect representing the table's bounding box.
    func boundingBox(for table: TableModel) -> CGRect {
        CGRect(
            x: CGFloat(table.column),
            y: CGFloat(table.row),
            width: CGFloat(table.width),
            height: CGFloat(table.height)
        )
    }
    
    /// Initializes the grid and marks all tables as occupied.
    func markTablesInGrid() {
        Self.logger.debug("Marking tables in grid...")
        tableStore.grid = Array(
            repeating: Array(repeating: nil, count: tableStore.totalColumns),
            count: tableStore.totalRows
        )

        for table in tables {
            Self.logger.debug("Table \(table.id): \(table.row), \(table.column), \(table.width)x\(table.height)")
            markTable(table, occupied: true)
            Self.logger.debug("Marked table \(table.id) at row \(table.row), column \(table.column)")
        }
    }
    
    // MARK: - Adjacency
    
    
    /// Checks if a table is adjacent to other tables and returns details about adjacent tables.
    /// - Parameters:
    ///   - table: The table to check adjacency for.
    ///   - combinedDateTime: The date and time to check adjacency at.
    ///   - activeTables: The active tables to check against.
    /// - Returns: A tuple containing the count of adjacent tables and details about which sides have adjacent tables.
    func isTableAdjacent(_ table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> (adjacentCount: Int, adjacentDetails: [TableModel.TableSide: TableModel]) {
        var adjacentCount = 0
        var adjacentDetails: [TableModel.TableSide: TableModel] = [:]

        Self.logger.debug("Active tables: \(activeTables.map { "Table \($0.id) at (\($0.row), \($0.column))" })")
        Self.logger.debug("Checking neighbors for table \(table.id) at row \(table.row), column \(table.column)")

        for side in TableModel.TableSide.allCases {
            let offset = side.offset()
            let neighborPosition = (row: table.row + offset.rowOffset, col: table.column + offset.colOffset)

            Self.logger.debug("Checking neighbor position: \(neighborPosition.row), \(neighborPosition.col) for side \(String(describing: side))")

            if let neighborTable = activeTables.first(where: { neighbor in
                // Ensure the neighbor is not the current table
                guard neighbor.id != table.id else { return false }
                
                // Strictly check if the neighbor overlaps at the exact position
                let exactRowMatch = neighbor.row == neighborPosition.row
                let exactColMatch = neighbor.column == neighborPosition.col

                // Return true only if there's an exact match or an overlap
                return (neighbor.height == 3 && neighbor.width == 3 && exactRowMatch && exactColMatch)
            }) {
                // Correctly track the table that overlaps
                adjacentCount += 1
                adjacentDetails[side] = neighborTable
                Self.logger.debug("Found adjacent table \(neighborTable.id) at side \(String(describing: side))")
            } else {
                Self.logger.debug("No active table found at neighbor position")
            }
        }

        Self.logger.debug("Adjacent tables for table \(table.id): count=\(adjacentCount), details: \(adjacentDetails.map { ($0.key, $0.value.id) })")
        return (adjacentCount, adjacentDetails)
    }
    

    
    // MARK: - Reservation-Aware Adjacency
    /// Checks if a table is adjacent to other tables that share the same reservation.
    /// - Parameters:
    ///   - table: The table to check.
    ///   - combinedDateTime: The date and time to check at.
    ///   - activeTables: The active tables to check against.
    /// - Returns: An array of tables that are adjacent and share the same reservation.
    func isAdjacentWithSameReservation(for table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> [TableModel] {
        // Get all reservation IDs for the given table
        let reservationIDs = store.reservations
            .filter { $0.tables.contains(where: { $0.id == table.id }) }
            .map { $0.id }

        // Get adjacent details using active tables
        let adjacentDetails = isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables).adjacentDetails
        var sharedReservationTables: [TableModel] = []

        for (_, adjacentTable) in adjacentDetails {
            // Check if the adjacent table shares a reservation
            let sharedReservations = store.reservations.filter { reservation in
                reservation.tables.contains(where: { $0.id == adjacentTable.id }) && reservationIDs.contains(reservation.id)
            }

            if !sharedReservations.isEmpty {
                sharedReservationTables.append(adjacentTable)
                Self.logger.debug("Found shared reservation with table \(adjacentTable.id)")
            }
        }

        Self.logger.debug("Shared reservation tables for table \(table.id): \(sharedReservationTables.map { $0.id })")
        return sharedReservationTables
    }
    
    // MARK: - Helpers for Adjacency
    
    /// Looks up a table by its grid position.
    /// - Parameters:
    ///   - row: The row position to look up.
    ///   - column: The column position to look up.
    ///   - combinedDateTime: The date and time to check at.
    ///   - activeTables: The active tables to check first.
    /// - Returns: The table at the specified position, or nil if no table is found.
    func fetchTable(row: Int, column: Int, combinedDateTime: Date, activeTables: [TableModel]) -> TableModel? {
        guard row >= 0, column >= 0 else {
            Self.logger.warning("Invalid grid position (\(row), \(column))")
            return nil
        }

        Self.logger.debug("Checking for table at (\(row), \(column))")

        // Check active tables first
        if let activeTable = activeTables.first(where: { $0.row == row && $0.column == column }) {
            Self.logger.debug("Found active table \(activeTable.id) at (\(row), \(column))")
            return activeTable
        }

        // Fallback to tables managed by the store
        let storeTables = store.reservations.flatMap { $0.tables }
        if let table = storeTables.first(where: { $0.row == row && $0.column == column }) {
            Self.logger.debug("Found table \(table.id) in store at (\(row), \(column))")
            return table
        }

        Self.logger.debug("No table found at (\(row), \(column))")
        return nil
    }

   
    
    /// Gets tables for a specific date and category, using cached layouts if available.
    /// - Parameters:
    ///   - date: The date to get tables for.
    ///   - category: The reservation category.
    /// - Returns: An array of tables for the specified date and category.
    func getTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            return tables
        } else {
            Self.logger.notice("No cached tables found for \(key). Returning base tables")
            return tableStore.baseTables
        }
    }
    

}

