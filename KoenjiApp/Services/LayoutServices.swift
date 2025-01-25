//
//  TableServices.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

// PLACEHOLDER: - LayoutServices.swift

import Foundation

class LayoutServices: ObservableObject {
    let store: ReservationStore
    let tableStore: TableStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService
    
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    @Published var tables: [TableModel] = []
    
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false
    
    // MARK: - Initializer
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
        print("Loading tables for key: \(fullKey)")

        // Check if the exact layout exists
        if let tables = cachedLayouts[fullKey] {
            // Assign to self.tables *on the main thread*
            DispatchQueue.main.async {
                self.tables = tables
                print("Loaded exact layout for key: \(fullKey)")
            }
            return tables
        }

        // Fallback: Use the closest prior configuration
        let fallbackKey = findClosestPriorKey(for: date, category: category)
        if let fallbackTables = fallbackKey.flatMap({ cachedLayouts[$0] }) {
            // Copy the fallback layout for this specific timeslot
            cachedLayouts[fullKey] = fallbackTables
            
            DispatchQueue.main.async {
                self.tables = fallbackTables
                print("Copied fallback layout from key: \(fallbackKey ?? "none") to key: \(fullKey)")
            }
            return fallbackTables
        }

        // Final fallback: Initialize with base tables

        
        DispatchQueue.main.async {
            self.cachedLayouts[fullKey] = self.tableStore.baseTables
            self.tables = self.tableStore.baseTables
            print("Initialized new layout for key: \(fullKey) with base tables")
        }
        return self.tableStore.baseTables
    }
    
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
        print("Saved tables for key: \(fullKey)")

        // Propagate changes to future timeslots
        propagateLayoutChange(from: fullKey, tables: tables)
        saveToDisk()
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
    
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tables
            print("Propagated layout to future key: \(futureKey)")
        }
    }
    
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)

        // Reset the layout for this specific key
        cachedLayouts[fullKey] = tableStore.baseTables
        tables = tableStore.baseTables
        print("Reset tables for key: \(fullKey) to base tables.")

        // Propagate reset to future timeslots
        propagateLayoutReset(from: fullKey)
        saveToDisk()
    }

    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tableStore.baseTables
            print("Reset future key: \(futureKey) to base tables.")
        }
    }
    
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
            print("Cached layouts loaded successfully: \(cachedLayouts.keys)")
        } else {
            print("No cached layouts found.")
        }
    }
    
    func setTables(_ newTables: [TableModel]) {
            self.tables = newTables
    }
    
    func setCachedLayouts(_ layouts: [String: [TableModel]]) {
            self.cachedLayouts = layouts
    }
    
    /// Decides if manual or auto/contiguous assignment based on `selectedTableID`.
    /// Returns the tables assigned or `nil` if assignment fails.
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
                DispatchQueue.main.async {
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        self.store.reservations.append(updatedReservation)
                    }
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
                DispatchQueue.main.async {
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        self.store.reservations.append(updatedReservation)
                    }
                }
                return .success(assignedTables)
            } else {
                // Distinguish not enough capacity from unknown error, if you’d like:
                return .failure(.insufficientTables)
            }
        }
    }
    
    func generateAndCacheLayout(for layoutKey: String, date: Date, category: Reservation.ReservationCategory) -> [TableModel]? {
        print("Generating layout for key: \(layoutKey)")
        let layout = loadTables(for: date, category: category) // Your layout generation logic
        
        if !layout.isEmpty {
            cachedLayouts[layoutKey] = layout
            print("Layout cached for key: \(layoutKey)")
        } else {
            print("Failed to generate layout for key: \(layoutKey)")
        }
        return layout
    }
    
    func lockTable(tableID: Int, start: Date, end: Date) {
        var intervals = lockedIntervals[tableID] ?? []
        intervals.append((start, end))  // or TimeIntervalLock(...)
        lockedIntervals[tableID] = intervals
    }

    func unlockTable(tableID: Int, start: Date, end: Date) {
        guard var intervals = lockedIntervals[tableID] else { return }
        // Remove the matching interval. Or if you store a reservation ID:
        // remove the item associated with that reservation ID
        intervals.removeAll(where: { $0.start == start && $0.end == end })
        lockedIntervals[tableID] = intervals
    }

    func unlockAllTables() {
        lockedIntervals.removeAll()
    }
    
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
    
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return cachedLayouts[key] != nil
    }
    
    func computeLayoutSignature(tables: [TableModel]) -> String {
        let sortedTables = tables.sorted { $0.id < $1.id }
        let components = sortedTables.map { table in
            "id_\(table.id)_row_\(table.row)_col_\(table.column)_w_\(table.width)_h_\(table.height)"
        }
        return components.joined(separator: ";")
    }
}

