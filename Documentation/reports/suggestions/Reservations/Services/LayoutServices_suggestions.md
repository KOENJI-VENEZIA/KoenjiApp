Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/LayoutServices.swift...
# Documentation Suggestions for LayoutServices.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/LayoutServices.swift
Total suggestions: 38

## Class Documentation (1)

### that (Line 14)

**Context:**

```swift
import SwiftUI
import os

/// A service class that manages table layouts for different dates and reservation categories.
/// Handles table positioning, movement, locking, and assignment for reservations.
/// Provides functionality for saving and loading layouts, checking table adjacency,
/// and managing the grid representation of tables.
```

**Suggested Documentation:**

```swift
/// that class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Property Documentation (37)

### tables (Line 91)

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

### fallbackKey (Line 99)

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

### fallbackTables (Line 100)

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

### sortedKeys (Line 125)

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

### futureKeys (Line 161)

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

### futureKeys (Line 191)

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

### layoutKey (Line 238)

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

### tables (Line 239)

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

### tableID (Line 246)

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

### selectedTable (Line 248)

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

### assignedTables (Line 258)

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

### assignedTables (Line 265)

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

### index (Line 268)

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

### updatedReservation (Line 271)

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

### unlockedTables (Line 283)

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

### assignedTables (Line 288)

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

### index (Line 295)

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

### updatedReservation (Line 298)

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

### newTable (Line 473)

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

### idx (Line 487)

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

### table2MinX (Line 517)

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

### table2MaxX (Line 518)

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

### table2MinY (Line 519)

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

### table2MaxY (Line 520)

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

### intersects (Line 526)

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

### tableCount (Line 552)

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

### offset (Line 616)

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

### neighborPosition (Line 617)

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

### neighborTable (Line 621)

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

### exactRowMatch (Line 626)

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

### exactColMatch (Line 627)

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

### adjacentDetails (Line 661)

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

### sharedReservationTables (Line 662)

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

### sharedReservations (Line 666)

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

### activeTable (Line 698)

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

### storeTables (Line 704)

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

### table (Line 705)

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


Total documentation suggestions: 38

