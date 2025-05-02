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
class LayoutServices: ObservableObject {    
    let resCache: CurrentReservationsCache
    let tableStore: TableStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService
    private let layoutCache: LayoutCache
    
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    @Published var tables: [TableModel] = []
    
    // MARK: - Grid Management
    var grid: [[Int?]] = []
    
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false
    
    // MARK: - Computed Properties
    
    /// Provides access to the cached layouts from the layout cache
    var cachedLayouts: [String: [TableModel]] {
        return layoutCache.cachedLayouts
    }
    
    // MARK: - Initializer
    init(resCache: CurrentReservationsCache, 
         tableStore: TableStore, 
         tableAssignmentService: TableAssignmentService,
         layoutCache: LayoutCache = LayoutCache()) {
        self.resCache = resCache
        self.tableStore = tableStore
        self.tableAssignmentService = tableAssignmentService
        self.layoutCache = layoutCache
        
        // Initialize grid
        self.grid = Array(repeating: Array(repeating: nil, count: tableStore.totalColumns), count: tableStore.totalRows)
        
        // Load layouts from disk
        loadFromDisk()
    }
    
    // MARK: - Grid Management Methods
    
    /// Initialize the grid with the current set of tables
    func initializeGrid(with tablesToMark: [TableModel]? = nil) {
        grid = Array(repeating: Array(repeating: nil, count: tableStore.totalColumns), count: tableStore.totalRows)
        
        // Mark positions of the provided tables or use the current tables
        let tablesToUse = tablesToMark ?? tables
        for table in tablesToUse {
            markTablePosition(table)
        }
        
        Task { @MainActor in
            AppLog.debug("Grid initialized with \(tablesToUse.count) tables")
        }
    }
    
    /// Mark a table's position on the grid
    func markTablePosition(_ table: TableModel) {
        let row = min(max(table.row, 0), tableStore.totalRows - 1)
        let col = min(max(table.column, 0), tableStore.totalColumns - 1)
        
        // Mark the main cell with the table ID
        grid[row][col] = table.id
        
        // Mark the cells occupied by the table width and height
        for r in row..<min(row + table.height, tableStore.totalRows) {
            for c in col..<min(col + table.width, tableStore.totalColumns) {
                grid[r][c] = table.id
            }
        }
    }
    
    /// Clear a table's position from the grid
    func clearTablePosition(_ table: TableModel) {
        let row = min(max(table.row, 0), tableStore.totalRows - 1)
        let col = min(max(table.column, 0), tableStore.totalColumns - 1)
        
        // Clear all cells occupied by the table
        for r in row..<min(row + table.height, tableStore.totalRows) {
            for c in col..<min(col + table.width, tableStore.totalColumns) {
                if grid[r][c] == table.id {
                    grid[r][c] = nil
                }
            }
        }
    }
    
    /// Check if two tables intersect with each other
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
        return !(table1MaxX <= table2MinX || table1MinX >= table2MaxX || 
                 table1MaxY <= table2MinY || table1MinY >= table2MaxY)
    }
    
    /// Check if a table can be placed at a specific position
    func canPlaceTableAt(row: Int, column: Int, width: Int, height: Int, excludingTableId: Int? = nil) -> Bool {
        // Check if position is within grid bounds
        if row < 0 || row + height > tableStore.totalRows || column < 0 || column + width > tableStore.totalColumns {
            return false
        }
        
        // Check if any of the cells are already occupied by another table
        for r in row..<(row + height) {
            for c in column..<(column + width) {
                if let tableId = grid[r][c], tableId != excludingTableId {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Find a table by row and column position
    func findTable(at row: Int, column: Int, amongTables tables: [TableModel]? = nil) -> TableModel? {
        let tablesToSearch = tables ?? self.tables
        return tablesToSearch.first { table in
            let tableRows = row >= table.row && row < (table.row + table.height)
            let tableColumns = column >= table.column && column < (table.column + table.width)
            return tableRows && tableColumns
        }
    }
    
    /// Return a bounding box rectangle for a table
    func boundingBox(for table: TableModel) -> CGRect {
        return CGRect(
            x: CGFloat(table.column),
            y: CGFloat(table.row),
            width: CGFloat(table.width),
            height: CGFloat(table.height)
        )
    }
    
    /// Move a table to a new position if possible
    func moveTable(_ table: TableModel, toRow: Int, toCol: Int, amongTables tables: [TableModel]? = nil) -> (result: Bool, newTable: TableModel) {
        let tablesToCheck = tables ?? self.tables
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))
        
        var newTable = table
        newTable.row = clampedRow
        newTable.column = clampedCol
        
        if canPlaceTable(newTable, amongTables: tablesToCheck) {
            return (true, newTable)
        } else {
            return (false, table)
        }
    }
    
    /// Check if a table can be placed without overlapping with other tables
    func canPlaceTable(_ table: TableModel, amongTables tables: [TableModel]? = nil) -> Bool {
        let tablesToCheck = tables ?? self.tables
        
        // Check if position is within grid bounds
        if table.row < 0 || table.row + table.height > tableStore.totalRows || 
           table.column < 0 || table.column + table.width > tableStore.totalColumns {
            return false
        }
        
        // Check for intersection with other tables
        for otherTable in tablesToCheck where otherTable.id != table.id {
            if tablesIntersect(table, otherTable) {
                return false
            }
        }
        
        return true
    }
    
    /// Returns the current set of tables.
    func getTables() -> [TableModel] {
        return self.tables
    }
    
    /// Generates a unique key based on date and category.
    func keyFor(date: Date, category: Reservation.ReservationCategory) -> String {
        return layoutCache.keyFor(date: date, category: category)
    }
    
    /// Loads tables for a specific date and category.
    func loadTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let fullKey = keyFor(date: date, category: category)
        Task { @MainActor in
            AppLog.debug("Loading tables for key: \(fullKey)")
        }

        if let tables = layoutCache.cachedLayouts[fullKey] {
            self.tables = tables
            initializeGrid(with: tables)
            Task { @MainActor in
                AppLog.debug("Loaded exact layout for key: \(fullKey)")
            }
            return tables
        }

        let fallbackKey = findClosestPriorKey(for: date, category: category)
        if let fallbackTables = fallbackKey.flatMap({ layoutCache.cachedLayouts[$0] }) {
            layoutCache.addOrUpdateLayout(for: date, 
                                         category: category, 
                                         tables: fallbackTables, 
                                         updateFirebase: false)
            
            self.tables = fallbackTables
            initializeGrid(with: fallbackTables)
            Task { @MainActor in
                AppLog.debug("Copied fallback layout from key: \(fallbackKey ?? "none") to key: \(fullKey)")
            }
            return fallbackTables
        }

        layoutCache.addOrUpdateLayout(for: date, 
                                    category: category, 
                                     tables: self.tableStore.baseTables, 
                                     updateFirebase: false)
        self.tables = self.tableStore.baseTables
        initializeGrid(with: self.tableStore.baseTables)
        Task { @MainActor in
            AppLog.debug("Initialized new layout for key: \(fullKey) with base tables")
        }
        return self.tableStore.baseTables
    }
    
    /// Finds the closest prior key in the cached layouts for a given date and category.
    private func findClosestPriorKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = layoutCache.cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Sort keys chronologically
        return sortedKeys.last { $0 < "\(formattedDate)-\(category.rawValue)" }
    }
    
    /// Saves tables for a specific date and category.
    func saveTables(_ tables: [TableModel], for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)
        layoutCache.addOrUpdateLayout(for: date, category: category, tables: tables)
        Task { @MainActor in
            AppLog.debug("Saved tables for key: \(fullKey)")
        }

        propagateLayoutChange(from: fullKey, tables: tables)
        saveToDisk()
    }
    
    /// Saves the current cached layouts to disk using UserDefaults.
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(layoutCache.cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            Task { @MainActor in
                AppLog.info("Layouts saved successfully")
            }
        } else {
            Task { @MainActor in
                AppLog.error("Failed to encode cached layouts")
            }
        }
    }
    
    /// Propagates layout changes from a specific key to future timeslots.
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = layoutCache.cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where layoutCache.cachedLayouts[futureKey] == nil {
            let components = futureKey.split(separator: "-")
            if components.count >= 3 {
                let dateStr = components[0..<components.count-1].joined(separator: "-")
                if let date = DateHelper.parseDate(dateStr),
                   let categoryValue = components.last,
                   let category = Reservation.ReservationCategory(rawValue: String(categoryValue)) {
                    layoutCache.addOrUpdateLayout(for: date, category: category, tables: tables, updateFirebase: false)
                    Task { @MainActor in
                        AppLog.debug("Propagated layout to future key: \(futureKey)")
                    }
                }
            }
        }
    }
    
    /// Resets tables for a specific date and category to the base configuration.
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)

        // Reset the layout for this specific key
        layoutCache.addOrUpdateLayout(for: date, category: category, tables: tableStore.baseTables)
        tables = tableStore.baseTables
        initializeGrid(with: tableStore.baseTables)
        Task { @MainActor in
            AppLog.info("Reset tables for key: \(fullKey) to base tables")
        }

        propagateLayoutReset(from: fullKey)
        saveToDisk()
    }

    /// Propagates layout reset from a specific key to future timeslots.
    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = layoutCache.cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where layoutCache.cachedLayouts[futureKey] == nil {
            let components = futureKey.split(separator: "-")
            if components.count >= 3 {
                let dateStr = components[0..<components.count-1].joined(separator: "-")
                if let date = DateHelper.parseDate(dateStr),
                   let categoryValue = components.last,
                   let category = Reservation.ReservationCategory(rawValue: String(categoryValue)) {
                    layoutCache.addOrUpdateLayout(for: date, category: category, tables: tableStore.baseTables, updateFirebase: false)
                    Task { @MainActor in
                        AppLog.debug("Reset future key: \(futureKey) to base tables")
                    }
                }
            }
        }
    }
    
    /// Loads cached layouts from disk storage.
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               for (key, tables) in decoded {
                   layoutCache.cachedLayouts[key] = tables
               }
               let layoutCount = decoded.keys.count  // Store count in local variable
               Task { @MainActor in
                    AppLog.info("Cached layouts loaded successfully: \(layoutCount) layouts")
               }
        } else {
            Task { @MainActor in
                AppLog.warning("No cached layouts found")
            }
        }
    }
    
    /// Sets the current tables array.
    func setTables(_ newTables: [TableModel]) {
        self.tables = newTables
        initializeGrid(with: newTables)
    }
    
    /// Checks if a layout exists for a specific date and category
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return layoutCache.cachedLayouts[key] != nil
    }
    
    /// Assigns tables for a reservation, either manually or automatically.
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
        guard let tables = layoutCache.cachedLayouts[layoutKey]
               ?? generateAndCacheLayout(for: layoutKey, date: reservationDate, category: reservation.category)
        else {
            return .failure(.noTablesLeft)  // Or .unknown if you prefer
        }
        
        if let tableID = selectedTableID {
            // 1) Check existence
            guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                return .failure(.tableNotFound)
            }
            
            // 2) Check lock
            if isTableLocked(tableID: selectedTable.id, start: reservationStart, end: reservationEnd) {
                let existingReservationsForTable = resCache.getAllReservations().filter { 
                    $0.tables.contains(where: { $0.id == selectedTable.id })
                }
                
                if existingReservationsForTable.isEmpty {
                    return .failure(.tableLocked)
                }
            }
            
            // 3) Attempt manual assignment
            let assignedTables = tableAssignmentService.assignTablesManually(
                for: reservation,
                tables: tables,
                reservations: resCache.getAllReservations(),
                startingFrom: selectedTable
            )
            
            if let assignedTables = assignedTables {
                lockTable(tableID: selectedTable.id, start: reservationStart, end: reservationEnd)
                
                var updatedReservation = reservation
                updatedReservation.tables = assignedTables
                
                resCache.addOrUpdateReservation(updatedReservation)
                
                return .success(assignedTables)
            } else {
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
                reservations: resCache.getAllReservations(),
                tables: unlockedTables
            ) {
                assignedTables.forEach { lockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                
                var updatedReservation = reservation
                updatedReservation.tables = assignedTables
                
                resCache.addOrUpdateReservation(updatedReservation)
                
                return .success(assignedTables)
            } else {
                return .failure(.insufficientTables)
            }
        }
    }
    
    /// Generates and caches a layout for a specific key, date, and category.
    func generateAndCacheLayout(for layoutKey: String, date: Date, category: Reservation.ReservationCategory) -> [TableModel]? {
        Task { @MainActor in
            AppLog.debug("Generating layout for key: \(layoutKey)")
        }
        let layout = loadTables(for: date, category: category) // Your layout generation logic
        let sendableCopy = layout
        if !layout.isEmpty {
            layoutCache.addOrUpdateLayout(for: date, category: category, tables: sendableCopy, updateFirebase: true)
            Task { @MainActor in
                AppLog.debug("Layout cached for key: \(layoutKey)")
            }
        } else {
            Task { @MainActor in
                AppLog.warning("Failed to generate layout for key: \(layoutKey)")
            }
        }
        return layout
    }
    
    /// Locks a table for a specific time interval.
    func lockTable(tableID: Int, start: Date, end: Date) {
        var intervals = lockedIntervals[tableID] ?? []
        intervals.append((start, end))  // or TimeIntervalLock(...)
        lockedIntervals[tableID] = intervals
    }

    /// Unlocks a table for a specific time interval.
    func unlockTable(tableID: Int, start: Date, end: Date) {
        guard var intervals = lockedIntervals[tableID] else { return }

        intervals.removeAll(where: { $0.start == start && $0.end == end })
        lockedIntervals[tableID] = intervals
    }

    /// Unlocks all tables by clearing all lock intervals.
    func unlockAllTables() {
        lockedIntervals.removeAll()
    }
    
    /// Checks if a table is locked for a specific time interval.
    func isTableLocked(tableID: Int, start: Date, end: Date) -> Bool {
        guard let intervals = lockedIntervals[tableID] else {
            return false
        }
        for interval in intervals {
            if start < interval.end && interval.start < end {
                return true
            }
        }
        return false
    }
    
    /// Computes a unique signature for a set of tables based on their properties.
    func computeLayoutSignature(tables: [TableModel]) -> String {
        let sortedTables = tables.sorted { $0.id < $1.id }
        let components = sortedTables.map { table in
            "id_\(table.id)_row_\(table.row)_col_\(table.column)"
        }
        return components.joined(separator: ";")
    }
}

// MARK: - Movement Operations
extension LayoutServices {
    /// Represents the result of a table move operation.
    enum MoveResult {
        case move    
        case invalid
    }

    /// Attempts to move a table to a new position.
    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        clearTablePosition(table)
        Task { @MainActor in
            AppLog.debug("Attempting to move \(table.name) to (\(toRow), \(toCol))")
        }

        let (canMove, newTable) = moveTable(table, toRow: toRow, toCol: toCol, amongTables: tables)

        if canMove {
            Task { @MainActor in
                AppLog.debug("Can place table \(table.name) at (\(newTable.row), \(newTable.column))")
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                if let idx = self.tables.firstIndex(where: { $0.id == table.id }) {
                    self.tables[idx] = newTable
                }
                markTablePosition(newTable)
            }
            Task { @MainActor in
                AppLog.info("Moved \(table.name) to (\(newTable.row), \(newTable.column)) successfully")
            }
            return .move
        } else {
            withAnimation(.spring) {
                markTablePosition(table)
            }
            Task { @MainActor in
                AppLog.info("Cannot place \(table.name) at (\(toRow), \(toCol)). Move failed")
            }
            return .invalid
        }
    }
}

// MARK: - Table Placement Helpers
extension LayoutServices {
    /// Checks if a table can be placed at a new position for a given date and category.
    func canPlaceTable(_ table: TableModel, for date: Date, category: Reservation.ReservationCategory, activeTables: [TableModel]) -> Bool {
        Task { @MainActor in
            AppLog.debug("Checking placement for table: \(table.name) at row: \(table.row), column: \(table.column), width: \(table.width), height: \(table.height)")
        }
        
        return canPlaceTable(table, amongTables: activeTables)
    }
}

// MARK: - Adjacency
extension LayoutServices {
    /// Checks if a table is adjacent to other tables and returns details about adjacent tables.
    func isTableAdjacent(_ table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> (adjacentCount: Int, adjacentDetails: [TableModel.TableSide: TableModel]) {
        var adjacentCount = 0
        var adjacentDetails: [TableModel.TableSide: TableModel] = [:]

        Task { @MainActor in
            AppLog.debug("Active tables: \(activeTables.map { "Table \($0.id) at (\($0.row), \($0.column))" })")
            AppLog.debug("Checking neighbors for table \(table.id) at row \(table.row), column \(table.column)")
        }

        for side in TableModel.TableSide.allCases {
            let offset = side.offset()
            let neighborPosition = (row: table.row + offset.rowOffset, col: table.column + offset.colOffset)

            if let neighborTable = activeTables.first(where: { neighbor in
                guard neighbor.id != table.id else { return false }
                
                let exactRowMatch = neighbor.row == neighborPosition.row
                let exactColMatch = neighbor.column == neighborPosition.col

                return (neighbor.height == 3 && neighbor.width == 3 && exactRowMatch && exactColMatch)
            }) {
                adjacentCount += 1
                adjacentDetails[side] = neighborTable
                Task { @MainActor in
                    AppLog.debug("Found adjacent table \(neighborTable.id) at side)")
                }
            } else {
                Task { @MainActor in
                    AppLog.debug("No active table found at neighbor position")
                }
            }
        }

        Task { @MainActor in
            AppLog.debug("Adjacent tables for table \(table.id): count=\(adjacentCount)")
        }
        return (adjacentCount, adjacentDetails)
    }
    
    // MARK: - Reservation-Aware Adjacency
    /// Checks if a table is adjacent to other tables that share the same reservation.
    func isAdjacentWithSameReservation(for table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> [TableModel] {
        let reservationIDs = resCache.getAllReservations()
            .filter { $0.tables.contains(where: { $0.id == table.id }) }
            .map { $0.id }

        let adjacentDetails = isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables).adjacentDetails
        var sharedReservationTables: [TableModel] = []

        for (_, adjacentTable) in adjacentDetails {
            let sharedReservations = resCache.getAllReservations().filter { reservation in
                reservation.tables.contains(where: { $0.id == adjacentTable.id }) && reservationIDs.contains(reservation.id)
            }

            if !sharedReservations.isEmpty {
                sharedReservationTables.append(adjacentTable)
                Task { @MainActor in
                    AppLog.debug("Found shared reservation with table \(adjacentTable.id)")
                }
            }
        }

        Task { @MainActor in
            AppLog.debug("Shared reservation tables for table \(table.id): \(sharedReservationTables.map { $0.id })")
        }
        return sharedReservationTables
    }
    
    // MARK: - Helpers for Adjacency
    
    /// Looks up a table by its grid position.
    func fetchTable(row: Int, column: Int, combinedDateTime: Date, activeTables: [TableModel]) -> TableModel? {
        guard row >= 0, column >= 0 else {
            Task { @MainActor in
                AppLog.warning("Invalid grid position (\(row), \(column))")
            }
            return nil
        }

        // First check in active tables
        if let activeTable = findTable(at: row, column: column, amongTables: activeTables) {
            Task { @MainActor in
                AppLog.debug("Found active table \(activeTable.id) at (\(row), \(column))")
            }
            return activeTable
        }

        // Then look in all reservation tables
        let storeTables = resCache.getAllReservations().flatMap { $0.tables }
        if let table = findTable(at: row, column: column, amongTables: storeTables) {
            Task { @MainActor in
                AppLog.debug("Found table \(table.id) in store at (\(row), \(column))")
            }
            return table
        }

        Task { @MainActor in
            AppLog.debug("No table found at (\(row), \(column))")
        }
        return nil
    }
    
    /// Gets tables for a specific date and category, using cached layouts if available.
    func getTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = layoutCache.cachedLayouts[key] {
            return tables
        } else {
            Task { @MainActor in
                AppLog.info("No cached tables found for \(key). Returning base tables")
            }
            return tableStore.baseTables
        }
    }
}

