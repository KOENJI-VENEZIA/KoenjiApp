Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/LayoutServices.swift...
# Documentation Suggestions for LayoutServices.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/LayoutServices.swift
Total suggestions: 115

## Class Documentation (4)

### LayoutServices (Line 14)

**Context:**

```swift
import SwiftUI
import os

class LayoutServices: ObservableObject {
    // MARK: - Private Properties
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
```

**Suggested Documentation:**

```swift
/// LayoutServices class.
///
/// [Add a description of what this class does and its responsibilities]
```

### LayoutServices (Line 318)

**Context:**

```swift
}

// MARK: - Table Placement Helpers
extension LayoutServices {
    /// Checks if a table can be placed at a new position for a given date and category.
    func canPlaceTable(_ table: TableModel, for date: Date, category: Reservation.ReservationCategory, activeTables: [TableModel]) -> Bool {
        Self.logger.debug("Checking placement for table: \(table.name) at row: \(table.row), column: \(table.column), width: \(table.width), height: \(table.height)")
```

**Suggested Documentation:**

```swift
/// LayoutServices class.
///
/// [Add a description of what this class does and its responsibilities]
```

### LayoutServices (Line 363)

**Context:**

```swift
    }
}

extension LayoutServices {
    
    // MARK: - Movement

```

**Suggested Documentation:**

```swift
/// LayoutServices class.
///
/// [Add a description of what this class does and its responsibilities]
```

### MoveResult (Line 367)

**Context:**

```swift
    
    // MARK: - Movement

    enum MoveResult {
        case move
        case invalid
    }
```

**Suggested Documentation:**

```swift
/// MoveResult class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (27)

### getTables (Line 50)

**Context:**

```swift
        }
    }
    
    func getTables() -> [TableModel] {
        return self.tables
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getTables method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### findClosestPriorKey (Line 91)

**Context:**

```swift
        return self.tableStore.baseTables
    }
    
    private func findClosestPriorKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the findClosestPriorKey method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### saveToDisk (Line 110)

**Context:**

```swift
        saveToDisk()
    }
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the saveToDisk method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### propagateLayoutChange (Line 120)

**Context:**

```swift
        }
    }
    
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the propagateLayoutChange method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### resetTables (Line 131)

**Context:**

```swift
        }
    }
    
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)

        // Reset the layout for this specific key
```

**Suggested Documentation:**

```swift
/// [Add a description of what the resetTables method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### propagateLayoutReset (Line 144)

**Context:**

```swift
        saveToDisk()
    }

    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the propagateLayoutReset method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### loadFromDisk (Line 155)

**Context:**

```swift
        }
    }
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadFromDisk method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### setTables (Line 166)

**Context:**

```swift
        }
    }
    
    func setTables(_ newTables: [TableModel]) {
            self.tables = newTables
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the setTables method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### setCachedLayouts (Line 170)

**Context:**

```swift
            self.tables = newTables
    }
    
    func setCachedLayouts(_ layouts: [String: [TableModel]]) {
            self.cachedLayouts = layouts
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the setCachedLayouts method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateAndCacheLayout (Line 259)

**Context:**

```swift
        }
    }
    
    func generateAndCacheLayout(for layoutKey: String, date: Date, category: Reservation.ReservationCategory) -> [TableModel]? {
        Self.logger.debug("Generating layout for key: \(layoutKey)")
        let layout = loadTables(for: date, category: category) // Your layout generation logic
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateAndCacheLayout method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### lockTable (Line 272)

**Context:**

```swift
        return layout
    }
    
    func lockTable(tableID: Int, start: Date, end: Date) {
        var intervals = lockedIntervals[tableID] ?? []
        intervals.append((start, end))  // or TimeIntervalLock(...)
        lockedIntervals[tableID] = intervals
```

**Suggested Documentation:**

```swift
/// [Add a description of what the lockTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### unlockTable (Line 278)

**Context:**

```swift
        lockedIntervals[tableID] = intervals
    }

    func unlockTable(tableID: Int, start: Date, end: Date) {
        guard var intervals = lockedIntervals[tableID] else { return }
        // Remove the matching interval. Or if you store a reservation ID:
        // remove the item associated with that reservation ID
```

**Suggested Documentation:**

```swift
/// [Add a description of what the unlockTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### unlockAllTables (Line 286)

**Context:**

```swift
        lockedIntervals[tableID] = intervals
    }

    func unlockAllTables() {
        lockedIntervals.removeAll()
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the unlockAllTables method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### isTableLocked (Line 290)

**Context:**

```swift
        lockedIntervals.removeAll()
    }
    
    func isTableLocked(tableID: Int, start: Date, end: Date) -> Bool {
        guard let intervals = lockedIntervals[tableID] else {
            return false
        }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the isTableLocked method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### layoutExists (Line 303)

**Context:**

```swift
        return false
    }
    
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return cachedLayouts[key] != nil
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the layoutExists method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### computeLayoutSignature (Line 308)

**Context:**

```swift
        return cachedLayouts[key] != nil
    }
    
    func computeLayoutSignature(tables: [TableModel]) -> String {
        let sortedTables = tables.sorted { $0.id < $1.id }
        let components = sortedTables.map { table in
            "id_\(table.id)_row_\(table.row)_col_\(table.column)"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the computeLayoutSignature method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### moveTable (Line 372)

**Context:**

```swift
        case invalid
    }

    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the moveTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### tablesIntersect (Line 411)

**Context:**

```swift

    // MARK: - Occupancy Checks

    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
```

**Suggested Documentation:**

```swift
/// [Add a description of what the tablesIntersect method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### canPlaceTable (Line 431)

**Context:**

```swift
        return intersects
    }

    func canPlaceTable(_ table: TableModel) -> Bool {
        for otherTable in tables where otherTable.id != table.id {
            if tablesIntersect(table, otherTable) {
                return false
```

**Suggested Documentation:**

```swift
/// [Add a description of what the canPlaceTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### markTable (Line 442)

**Context:**

```swift

    // MARK: - Helpers

    func markTable(_ table: TableModel, occupied: Bool) {
        Self.logger.debug("Marking table \(table.id) at \(table.row), \(table.column) with occupied=\(occupied)")
        
        let tableCount = tables.count
```

**Suggested Documentation:**

```swift
/// [Add a description of what the markTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### unmarkTable (Line 458)

**Context:**

```swift
        }
    }

    func unmarkTable(_ table: TableModel) {
        
        markTable(table, occupied: false)
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the unmarkTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### boundingBox (Line 463)

**Context:**

```swift
        markTable(table, occupied: false)
    }

    func boundingBox(for table: TableModel) -> CGRect {
        CGRect(
            x: CGFloat(table.column),
            y: CGFloat(table.row),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the boundingBox method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### markTablesInGrid (Line 472)

**Context:**

```swift
        )
    }
    
    func markTablesInGrid() {
        Self.logger.debug("Marking tables in grid...")
        tableStore.grid = Array(
            repeating: Array(repeating: nil, count: tableStore.totalColumns),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the markTablesInGrid method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### isTableAdjacent (Line 489)

**Context:**

```swift
    // MARK: - Adjacency
    
    
    func isTableAdjacent(_ table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> (adjacentCount: Int, adjacentDetails: [TableModel.TableSide: TableModel]) {
        var adjacentCount = 0
        var adjacentDetails: [TableModel.TableSide: TableModel] = [:]

```

**Suggested Documentation:**

```swift
/// [Add a description of what the isTableAdjacent method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### isAdjacentWithSameReservation (Line 529)

**Context:**

```swift

    
    // MARK: - Reservation-Aware Adjacency
    func isAdjacentWithSameReservation(for table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> [TableModel] {
        // Get all reservation IDs for the given table
        let reservationIDs = store.reservations
            .filter { $0.tables.contains(where: { $0.id == table.id }) }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the isAdjacentWithSameReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### fetchTable (Line 558)

**Context:**

```swift
    // MARK: - Helpers for Adjacency
    
    // Lookup a table by grid position
    func fetchTable(row: Int, column: Int, combinedDateTime: Date, activeTables: [TableModel]) -> TableModel? {
        guard row >= 0, column >= 0 else {
            Self.logger.warning("Invalid grid position (\(row), \(column))")
            return nil
```

**Suggested Documentation:**

```swift
/// [Add a description of what the fetchTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getTables (Line 585)

**Context:**

```swift

   
    
    func getTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            return tables
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getTables method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (84)

### logger (Line 16)

**Context:**

```swift

class LayoutServices: ObservableObject {
    // MARK: - Private Properties
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "LayoutServices"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### store (Line 21)

**Context:**

```swift
        category: "LayoutServices"
    )
    
    let store: ReservationStore
    let tableStore: TableStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService
    
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### tableStore (Line 22)

**Context:**

```swift
    )
    
    let store: ReservationStore
    let tableStore: TableStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService
    
    @Published var tableAnimationState: [Int: Bool] = [:]
```

**Suggested Documentation:**

```swift
/// [Description of the tableStore property]
```

### tableAssignmentService (Line 23)

**Context:**

```swift
    
    let store: ReservationStore
    let tableStore: TableStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService
    
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the tableAssignmentService property]
```

### tableAnimationState (Line 25)

**Context:**

```swift
    let tableStore: TableStore          // single source of truth
    private let tableAssignmentService: TableAssignmentService
    
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
```

**Suggested Documentation:**

```swift
/// [Description of the tableAnimationState property]
```

### currentlyDraggedTableID (Line 26)

**Context:**

```swift
    private let tableAssignmentService: TableAssignmentService
    
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
```

**Suggested Documentation:**

```swift
/// [Description of the currentlyDraggedTableID property]
```

### isSidebarVisible (Line 27)

**Context:**

```swift
    
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the isSidebarVisible property]
```

### cachedLayouts (Line 28)

**Context:**

```swift
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
```

**Suggested Documentation:**

```swift
/// [Description of the cachedLayouts property]
```

### selectedCategory (Line 29)

**Context:**

```swift
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    @Published var tables: [TableModel] = []
```

**Suggested Documentation:**

```swift
/// [Description of the selectedCategory property]
```

### currentTime (Line 30)

**Context:**

```swift
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    @Published var tables: [TableModel] = []
    
```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```

### tables (Line 32)

**Context:**

```swift
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    @Published var tables: [TableModel] = []
    
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    var lastSavedKey: String? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### lockedIntervals (Line 34)

**Context:**

```swift
    
    @Published var tables: [TableModel] = []
    
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false
    
```

**Suggested Documentation:**

```swift
/// [Description of the lockedIntervals property]
```

### lastSavedKey (Line 35)

**Context:**

```swift
    @Published var tables: [TableModel] = []
    
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false
    
    // MARK: - Initializer
```

**Suggested Documentation:**

```swift
/// [Description of the lastSavedKey property]
```

### isUpdatingLayout (Line 36)

**Context:**

```swift
    
    var lockedIntervals: [Int: [(start: Date, end: Date)]] = [:]
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false
    
    // MARK: - Initializer
    init(store: ReservationStore, tableStore: TableStore, tableAssignmentService: TableAssignmentService) {
```

**Suggested Documentation:**

```swift
/// [Description of the isUpdatingLayout property]
```

### key (Line 43)

**Context:**

```swift
        self.store = store
        self.tableStore = tableStore
        self.tableAssignmentService = tableAssignmentService
        let key = keyFor(date: currentTime, category: selectedCategory ?? .lunch)
        if cachedLayouts[key] == nil {
            cachedLayouts[key] = self.tableStore.baseTables
            self.tables = self.tableStore.baseTables
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### tables (Line 66)

**Context:**

```swift
        Self.logger.debug("Loading tables for key: \(fullKey)")

        // Check if the exact layout exists
        if let tables = cachedLayouts[fullKey] {
            // Assign to self.tables *on the main thread*
                self.tables = tables
                Self.logger.debug("Loaded exact layout for key: \(fullKey)")
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### fallbackKey (Line 74)

**Context:**

```swift
        }

        // Fallback: Use the closest prior configuration
        let fallbackKey = findClosestPriorKey(for: date, category: category)
        if let fallbackTables = fallbackKey.flatMap({ cachedLayouts[$0] }) {
            // Copy the fallback layout for this specific timeslot
            cachedLayouts[fullKey] = fallbackTables
```

**Suggested Documentation:**

```swift
/// [Description of the fallbackKey property]
```

### fallbackTables (Line 75)

**Context:**

```swift

        // Fallback: Use the closest prior configuration
        let fallbackKey = findClosestPriorKey(for: date, category: category)
        if let fallbackTables = fallbackKey.flatMap({ cachedLayouts[$0] }) {
            // Copy the fallback layout for this specific timeslot
            cachedLayouts[fullKey] = fallbackTables
            
```

**Suggested Documentation:**

```swift
/// [Description of the fallbackTables property]
```

### formattedDate (Line 92)

**Context:**

```swift
    }
    
    private func findClosestPriorKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Sort keys chronologically
```

**Suggested Documentation:**

```swift
/// [Description of the formattedDate property]
```

### allKeys (Line 93)

**Context:**

```swift
    
    private func findClosestPriorKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Sort keys chronologically
        return sortedKeys.last { $0 < "\(formattedDate)-\(category.rawValue)" }
```

**Suggested Documentation:**

```swift
/// [Description of the allKeys property]
```

### sortedKeys (Line 95)

**Context:**

```swift
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Sort keys chronologically
        return sortedKeys.last { $0 < "\(formattedDate)-\(category.rawValue)" }
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the sortedKeys property]
```

### encoder (Line 111)

**Context:**

```swift
    }
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            Self.logger.info("Layouts saved successfully")
```

**Suggested Documentation:**

```swift
/// [Description of the encoder property]
```

### data (Line 112)

**Context:**

```swift
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            Self.logger.info("Layouts saved successfully")
        } else {
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### category (Line 121)

**Context:**

```swift
    }
    
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### allKeys (Line 122)

**Context:**

```swift
    
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
```

**Suggested Documentation:**

```swift
/// [Description of the allKeys property]
```

### futureKeys (Line 124)

**Context:**

```swift
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tables
            Self.logger.debug("Propagated layout to future key: \(futureKey)")
```

**Suggested Documentation:**

```swift
/// [Description of the futureKeys property]
```

### fullKey (Line 132)

**Context:**

```swift
    }
    
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)

        // Reset the layout for this specific key
        cachedLayouts[fullKey] = tableStore.baseTables
```

**Suggested Documentation:**

```swift
/// [Description of the fullKey property]
```

### category (Line 145)

**Context:**

```swift
    }

    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### allKeys (Line 146)

**Context:**

```swift

    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
```

**Suggested Documentation:**

```swift
/// [Description of the allKeys property]
```

### futureKeys (Line 148)

**Context:**

```swift
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tableStore.baseTables
            Self.logger.debug("Reset future key: \(futureKey) to base tables")
```

**Suggested Documentation:**

```swift
/// [Description of the futureKeys property]
```

### data (Line 156)

**Context:**

```swift
    }
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
               let layoutCount = decoded.keys.count  // Store count in local variable
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### decoded (Line 157)

**Context:**

```swift
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
               let layoutCount = decoded.keys.count  // Store count in local variable
               Self.logger.info("Cached layouts loaded successfully: \(layoutCount) layouts")
```

**Suggested Documentation:**

```swift
/// [Description of the decoded property]
```

### layoutCount (Line 159)

**Context:**

```swift
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
               let layoutCount = decoded.keys.count  // Store count in local variable
               Self.logger.info("Cached layouts loaded successfully: \(layoutCount) layouts")
        } else {
            Self.logger.warning("No cached layouts found")
```

**Suggested Documentation:**

```swift
/// [Description of the layoutCount property]
```

### layoutKey (Line 187)

**Context:**

```swift
        guard let reservationStart = reservation.startTimeDate,
            let reservationEnd = reservation.endTimeDate else { return .failure(.unknown)}
        
        let layoutKey = keyFor(date: reservationDate, category: reservation.category)
        guard let tables = cachedLayouts[layoutKey]
               ?? generateAndCacheLayout(for: layoutKey, date: reservationDate, category: reservation.category)
        else {
```

**Suggested Documentation:**

```swift
/// [Description of the layoutKey property]
```

### tables (Line 188)

**Context:**

```swift
            let reservationEnd = reservation.endTimeDate else { return .failure(.unknown)}
        
        let layoutKey = keyFor(date: reservationDate, category: reservation.category)
        guard let tables = cachedLayouts[layoutKey]
               ?? generateAndCacheLayout(for: layoutKey, date: reservationDate, category: reservation.category)
        else {
            return .failure(.noTablesLeft)  // Or .unknown if you prefer
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### tableID (Line 195)

**Context:**

```swift
        }
        
        // Manual assignment if tableID is set
        if let tableID = selectedTableID {
            // 1) Check existence
            guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                return .failure(.tableNotFound)
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### selectedTable (Line 197)

**Context:**

```swift
        // Manual assignment if tableID is set
        if let tableID = selectedTableID {
            // 1) Check existence
            guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                return .failure(.tableNotFound)
            }
            
```

**Suggested Documentation:**

```swift
/// [Description of the selectedTable property]
```

### assignedTables (Line 207)

**Context:**

```swift
            }
            
            // 3) Attempt manual assignment
            let assignedTables = tableAssignmentService.assignTablesManually(
                for: reservation,
                tables: tables,
                reservations: store.reservations,
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### assignedTables (Line 214)

**Context:**

```swift
                startingFrom: selectedTable
            )
            
            if let assignedTables = assignedTables {
                // Lock tables, update store, etc.
                lockTable(tableID: selectedTable.id, start: reservationStart, end: reservationEnd)
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### index (Line 217)

**Context:**

```swift
            if let assignedTables = assignedTables {
                // Lock tables, update store, etc.
                lockTable(tableID: selectedTable.id, start: reservationStart, end: reservationEnd)
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### updatedReservation (Line 220)

**Context:**

```swift
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        self.store.reservations.append(updatedReservation)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### unlockedTables (Line 232)

**Context:**

```swift
            
        } else {
            // Auto assignment
            let unlockedTables = tables.filter { !isTableLocked(tableID: $0.id, start: reservationStart, end: reservationEnd) }
            guard !unlockedTables.isEmpty else {
                return .failure(.noTablesLeft)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the unlockedTables property]
```

### assignedTables (Line 237)

**Context:**

```swift
                return .failure(.noTablesLeft)
            }
            
            if let assignedTables = tableAssignmentService.assignTablesPreferContiguous(
                for: reservation,
                reservations: store.reservations,
                tables: unlockedTables
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### index (Line 244)

**Context:**

```swift
            ) {
                // Lock each table, update store, etc.
                assignedTables.forEach { lockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### updatedReservation (Line 247)

**Context:**

```swift
                    if let index = self.store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        self.store.reservations[index].tables = assignedTables
                    } else {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        self.store.reservations.append(updatedReservation)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### layout (Line 261)

**Context:**

```swift
    
    func generateAndCacheLayout(for layoutKey: String, date: Date, category: Reservation.ReservationCategory) -> [TableModel]? {
        Self.logger.debug("Generating layout for key: \(layoutKey)")
        let layout = loadTables(for: date, category: category) // Your layout generation logic
        
        if !layout.isEmpty {
            cachedLayouts[layoutKey] = layout
```

**Suggested Documentation:**

```swift
/// [Description of the layout property]
```

### intervals (Line 273)

**Context:**

```swift
    }
    
    func lockTable(tableID: Int, start: Date, end: Date) {
        var intervals = lockedIntervals[tableID] ?? []
        intervals.append((start, end))  // or TimeIntervalLock(...)
        lockedIntervals[tableID] = intervals
    }
```

**Suggested Documentation:**

```swift
/// [Description of the intervals property]
```

### intervals (Line 279)

**Context:**

```swift
    }

    func unlockTable(tableID: Int, start: Date, end: Date) {
        guard var intervals = lockedIntervals[tableID] else { return }
        // Remove the matching interval. Or if you store a reservation ID:
        // remove the item associated with that reservation ID
        intervals.removeAll(where: { $0.start == start && $0.end == end })
```

**Suggested Documentation:**

```swift
/// [Description of the intervals property]
```

### intervals (Line 291)

**Context:**

```swift
    }
    
    func isTableLocked(tableID: Int, start: Date, end: Date) -> Bool {
        guard let intervals = lockedIntervals[tableID] else {
            return false
        }
        for interval in intervals {
```

**Suggested Documentation:**

```swift
/// [Description of the intervals property]
```

### key (Line 304)

**Context:**

```swift
    }
    
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return cachedLayouts[key] != nil
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### sortedTables (Line 309)

**Context:**

```swift
    }
    
    func computeLayoutSignature(tables: [TableModel]) -> String {
        let sortedTables = tables.sorted { $0.id < $1.id }
        let components = sortedTables.map { table in
            "id_\(table.id)_row_\(table.row)_col_\(table.column)"
        }
```

**Suggested Documentation:**

```swift
/// [Description of the sortedTables property]
```

### components (Line 310)

**Context:**

```swift
    
    func computeLayoutSignature(tables: [TableModel]) -> String {
        let sortedTables = tables.sorted { $0.id < $1.id }
        let components = sortedTables.map { table in
            "id_\(table.id)_row_\(table.row)_col_\(table.column)"
        }
        return components.joined(separator: ";")
```

**Suggested Documentation:**

```swift
/// [Description of the components property]
```

### maxRow (Line 373)

**Context:**

```swift
    }

    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))
```

**Suggested Documentation:**

```swift
/// [Description of the maxRow property]
```

### maxCol (Line 374)

**Context:**

```swift

    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))

```

**Suggested Documentation:**

```swift
/// [Description of the maxCol property]
```

### clampedRow (Line 375)

**Context:**

```swift
    func moveTable(_ table: TableModel, toRow: Int, toCol: Int) -> MoveResult {
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))

        var newTable = table
```

**Suggested Documentation:**

```swift
/// [Description of the clampedRow property]
```

### clampedCol (Line 376)

**Context:**

```swift
        let maxRow = tableStore.totalRows - table.height
        let maxCol = tableStore.totalColumns - table.width
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))

        var newTable = table
        newTable.row = clampedRow
```

**Suggested Documentation:**

```swift
/// [Description of the clampedCol property]
```

### newTable (Line 378)

**Context:**

```swift
        let clampedRow = max(0, min(toRow, maxRow))
        let clampedCol = max(0, min(toCol, maxCol))

        var newTable = table
        newTable.row = clampedRow
        newTable.column = clampedCol

```

**Suggested Documentation:**

```swift
/// [Description of the newTable property]
```

### idx (Line 392)

**Context:**

```swift

            // Perform the move
            withAnimation(.easeInOut(duration: 0.5)) {
                if let idx = self.tables.firstIndex(where: { $0.id == table.id }) {
                    self.tables[idx] = newTable
                }
                self.markTable(newTable, occupied: true)
```

**Suggested Documentation:**

```swift
/// [Description of the idx property]
```

### table1MinX (Line 412)

**Context:**

```swift
    // MARK: - Occupancy Checks

    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height
```

**Suggested Documentation:**

```swift
/// [Description of the table1MinX property]
```

### table1MaxX (Line 413)

**Context:**

```swift

    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

```

**Suggested Documentation:**

```swift
/// [Description of the table1MaxX property]
```

### table1MinY (Line 414)

**Context:**

```swift
    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
```

**Suggested Documentation:**

```swift
/// [Description of the table1MinY property]
```

### table1MaxY (Line 415)

**Context:**

```swift
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
```

**Suggested Documentation:**

```swift
/// [Description of the table1MaxY property]
```

### table2MinX (Line 417)

**Context:**

```swift
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height
```

**Suggested Documentation:**

```swift
/// [Description of the table2MinX property]
```

### table2MaxX (Line 418)

**Context:**

```swift
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height

```

**Suggested Documentation:**

```swift
/// [Description of the table2MaxX property]
```

### table2MinY (Line 419)

**Context:**

```swift

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height

        Self.logger.debug("Checking intersection - Table 1: (\(table1MinX), \(table1MaxX)) x (\(table1MinY), \(table1MaxY))")
```

**Suggested Documentation:**

```swift
/// [Description of the table2MinY property]
```

### table2MaxY (Line 420)

**Context:**

```swift
        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height

        Self.logger.debug("Checking intersection - Table 1: (\(table1MinX), \(table1MaxX)) x (\(table1MinY), \(table1MaxY))")
        Self.logger.debug("Checking intersection - Table 2: (\(table2MinX), \(table2MaxX)) x (\(table2MinY), \(table2MaxY))")
```

**Suggested Documentation:**

```swift
/// [Description of the table2MaxY property]
```

### intersects (Line 426)

**Context:**

```swift
        Self.logger.debug("Checking intersection - Table 2: (\(table2MinX), \(table2MaxX)) x (\(table2MinY), \(table2MaxY))")

        // Check for no overlap scenarios
        let intersects = !(table1MaxX <= table2MinX || table1MinX >= table2MaxX || table1MaxY <= table2MinY || table1MinY >= table2MaxY)
        Self.logger.debug("Intersection result: \(intersects)")
        return intersects
    }
```

**Suggested Documentation:**

```swift
/// [Description of the intersects property]
```

### tableCount (Line 445)

**Context:**

```swift
    func markTable(_ table: TableModel, occupied: Bool) {
        Self.logger.debug("Marking table \(table.id) at \(table.row), \(table.column) with occupied=\(occupied)")
        
        let tableCount = tables.count
        Self.logger.debug("Tables and grid state after operation: \(tableCount) tables")
        
        for r in table.row..<(table.row + table.height) {
```

**Suggested Documentation:**

```swift
/// [Description of the tableCount property]
```

### adjacentCount (Line 490)

**Context:**

```swift
    
    
    func isTableAdjacent(_ table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> (adjacentCount: Int, adjacentDetails: [TableModel.TableSide: TableModel]) {
        var adjacentCount = 0
        var adjacentDetails: [TableModel.TableSide: TableModel] = [:]

        Self.logger.debug("Active tables: \(activeTables.map { "Table \($0.id) at (\($0.row), \($0.column))" })")
```

**Suggested Documentation:**

```swift
/// [Description of the adjacentCount property]
```

### adjacentDetails (Line 491)

**Context:**

```swift
    
    func isTableAdjacent(_ table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> (adjacentCount: Int, adjacentDetails: [TableModel.TableSide: TableModel]) {
        var adjacentCount = 0
        var adjacentDetails: [TableModel.TableSide: TableModel] = [:]

        Self.logger.debug("Active tables: \(activeTables.map { "Table \($0.id) at (\($0.row), \($0.column))" })")
        Self.logger.debug("Checking neighbors for table \(table.id) at row \(table.row), column \(table.column)")
```

**Suggested Documentation:**

```swift
/// [Description of the adjacentDetails property]
```

### offset (Line 497)

**Context:**

```swift
        Self.logger.debug("Checking neighbors for table \(table.id) at row \(table.row), column \(table.column)")

        for side in TableModel.TableSide.allCases {
            let offset = side.offset()
            let neighborPosition = (row: table.row + offset.rowOffset, col: table.column + offset.colOffset)

            Self.logger.debug("Checking neighbor position: \(neighborPosition.row), \(neighborPosition.col) for side \(String(describing: side))")
```

**Suggested Documentation:**

```swift
/// [Description of the offset property]
```

### neighborPosition (Line 498)

**Context:**

```swift

        for side in TableModel.TableSide.allCases {
            let offset = side.offset()
            let neighborPosition = (row: table.row + offset.rowOffset, col: table.column + offset.colOffset)

            Self.logger.debug("Checking neighbor position: \(neighborPosition.row), \(neighborPosition.col) for side \(String(describing: side))")

```

**Suggested Documentation:**

```swift
/// [Description of the neighborPosition property]
```

### neighborTable (Line 502)

**Context:**

```swift

            Self.logger.debug("Checking neighbor position: \(neighborPosition.row), \(neighborPosition.col) for side \(String(describing: side))")

            if let neighborTable = activeTables.first(where: { neighbor in
                // Ensure the neighbor is not the current table
                guard neighbor.id != table.id else { return false }
                
```

**Suggested Documentation:**

```swift
/// [Description of the neighborTable property]
```

### exactRowMatch (Line 507)

**Context:**

```swift
                guard neighbor.id != table.id else { return false }
                
                // Strictly check if the neighbor overlaps at the exact position
                let exactRowMatch = neighbor.row == neighborPosition.row
                let exactColMatch = neighbor.column == neighborPosition.col

                // Return true only if there's an exact match or an overlap
```

**Suggested Documentation:**

```swift
/// [Description of the exactRowMatch property]
```

### exactColMatch (Line 508)

**Context:**

```swift
                
                // Strictly check if the neighbor overlaps at the exact position
                let exactRowMatch = neighbor.row == neighborPosition.row
                let exactColMatch = neighbor.column == neighborPosition.col

                // Return true only if there's an exact match or an overlap
                return (neighbor.height == 3 && neighbor.width == 3 && exactRowMatch && exactColMatch)
```

**Suggested Documentation:**

```swift
/// [Description of the exactColMatch property]
```

### reservationIDs (Line 531)

**Context:**

```swift
    // MARK: - Reservation-Aware Adjacency
    func isAdjacentWithSameReservation(for table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> [TableModel] {
        // Get all reservation IDs for the given table
        let reservationIDs = store.reservations
            .filter { $0.tables.contains(where: { $0.id == table.id }) }
            .map { $0.id }

```

**Suggested Documentation:**

```swift
/// [Description of the reservationIDs property]
```

### adjacentDetails (Line 536)

**Context:**

```swift
            .map { $0.id }

        // Get adjacent details using active tables
        let adjacentDetails = isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables).adjacentDetails
        var sharedReservationTables: [TableModel] = []

        for (_, adjacentTable) in adjacentDetails {
```

**Suggested Documentation:**

```swift
/// [Description of the adjacentDetails property]
```

### sharedReservationTables (Line 537)

**Context:**

```swift

        // Get adjacent details using active tables
        let adjacentDetails = isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables).adjacentDetails
        var sharedReservationTables: [TableModel] = []

        for (_, adjacentTable) in adjacentDetails {
            // Check if the adjacent table shares a reservation
```

**Suggested Documentation:**

```swift
/// [Description of the sharedReservationTables property]
```

### sharedReservations (Line 541)

**Context:**

```swift

        for (_, adjacentTable) in adjacentDetails {
            // Check if the adjacent table shares a reservation
            let sharedReservations = store.reservations.filter { reservation in
                reservation.tables.contains(where: { $0.id == adjacentTable.id }) && reservationIDs.contains(reservation.id)
            }

```

**Suggested Documentation:**

```swift
/// [Description of the sharedReservations property]
```

### activeTable (Line 567)

**Context:**

```swift
        Self.logger.debug("Checking for table at (\(row), \(column))")

        // Check active tables first
        if let activeTable = activeTables.first(where: { $0.row == row && $0.column == column }) {
            Self.logger.debug("Found active table \(activeTable.id) at (\(row), \(column))")
            return activeTable
        }
```

**Suggested Documentation:**

```swift
/// [Description of the activeTable property]
```

### storeTables (Line 573)

**Context:**

```swift
        }

        // Fallback to tables managed by the store
        let storeTables = store.reservations.flatMap { $0.tables }
        if let table = storeTables.first(where: { $0.row == row && $0.column == column }) {
            Self.logger.debug("Found table \(table.id) in store at (\(row), \(column))")
            return table
```

**Suggested Documentation:**

```swift
/// [Description of the storeTables property]
```

### table (Line 574)

**Context:**

```swift

        // Fallback to tables managed by the store
        let storeTables = store.reservations.flatMap { $0.tables }
        if let table = storeTables.first(where: { $0.row == row && $0.column == column }) {
            Self.logger.debug("Found table \(table.id) in store at (\(row), \(column))")
            return table
        }
```

**Suggested Documentation:**

```swift
/// [Description of the table property]
```

### key (Line 586)

**Context:**

```swift
   
    
    func getTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            return tables
        } else {
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### tables (Line 587)

**Context:**

```swift
    
    func getTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            return tables
        } else {
            Self.logger.notice("No cached tables found for \(key). Returning base tables")
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```


Total documentation suggestions: 115

