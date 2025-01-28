import Foundation
import SwiftUI

/// Extension to manage grid-related operations for tables
extension LayoutServices {
    
    // MARK: - Movement

    enum MoveResult {
        case move
        case invalid
    }

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
        print("moveTable: Attempting to move \(table.name) to (\(clampedRow), \(clampedCol))")

        // Check if the new position is valid
        if canPlaceTable(newTable) {
            print("moveTable: Can place table \(table.name) at (\(clampedRow), \(clampedCol))")

            // Perform the move
            
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let idx = self.tables.firstIndex(where: { $0.id == table.id }) {
                        self.tables[idx] = newTable
                    }
                
                self.markTable(newTable, occupied: true)
            }
            print("moveTable: Moved \(table.name) to (\(clampedRow), \(clampedCol)) successfully.")
            return .move
        } else {
            // Invalid move; re-mark the original table's position
            
                withAnimation(.spring) {
                    self.markTable(table, occupied: true)
                }
            
            print("moveTable: Cannot place \(table.name) at (\(clampedRow), \(clampedCol)). Move failed.")
            return .invalid
        }
    }

    // MARK: - Occupancy Checks

    func tablesIntersect(_ table1: TableModel, _ table2: TableModel) -> Bool {
        let table1MinX = table1.column
        let table1MaxX = table1.column + table1.width
        let table1MinY = table1.row
        let table1MaxY = table1.row + table1.height

        let table2MinX = table2.column
        let table2MaxX = table2.column + table2.width
        let table2MinY = table2.row
        let table2MaxY = table2.row + table2.height

        // Log details for debugging
        print("Table 1: (\(table1MinX), \(table1MaxX)) x (\(table1MinY), \(table1MaxY))")
        print("Table 2: (\(table2MinX), \(table2MaxX)) x (\(table2MinY), \(table2MaxY))")

        // Check for no overlap scenarios
        let intersects = !(table1MaxX <= table2MinX || table1MinX >= table2MaxX || table1MaxY <= table2MinY || table1MinY >= table2MaxY)
        print("Intersect Result: \(intersects)")
        return intersects
    }

    func canPlaceTable(_ table: TableModel) -> Bool {
        for otherTable in tables where otherTable.id != table.id {
            if tablesIntersect(table, otherTable) {
                return false
            }
        }
        return true
    }

    // MARK: - Helpers

    func markTable(_ table: TableModel, occupied: Bool) {
        print("Marking table \(table.id) at \(table.row), \(table.column) with occupied=\(occupied)")
        
        print("Tables and grid state after operation:")
        print(tables)
        for r in table.row..<(table.row + table.height) {
            for c in table.column..<(table.column + table.width) {
                guard r >= 0, r < tableStore.grid.count, c >= 0, c < tableStore.grid[0].count else {
                    print("markTable: Skipping out-of-bounds position (\(r), \(c))")
                    continue }
                tableStore.grid[r][c] = occupied ? table.id : nil
            }
        }
    }

    func unmarkTable(_ table: TableModel) {
        
        markTable(table, occupied: false)
    }

    func boundingBox(for table: TableModel) -> CGRect {
        CGRect(
            x: CGFloat(table.column),
            y: CGFloat(table.row),
            width: CGFloat(table.width),
            height: CGFloat(table.height)
        )
    }
    
    func markTablesInGrid() {
        print("Marking tables in grid...")
        tableStore.grid = Array(
            repeating: Array(repeating: nil, count: tableStore.totalColumns),
            count: tableStore.totalRows
        )
        print("Tables in array:")

        for table in tables {
            print("Table \(table.id): \(table.row), \(table.column), \(table.width)x\(table.height)")
            markTable(table, occupied: true)
            print("Marked table \(table.id) at row \(table.row), column \(table.column)")

        }
    }
    
    // MARK: - Adjacency
    
    
    func isTableAdjacent(_ table: TableModel, combinedDateTime: Date, activeTables: [TableModel]) -> (adjacentCount: Int, adjacentDetails: [TableModel.TableSide: TableModel]) {
        var adjacentCount = 0
        var adjacentDetails: [TableModel.TableSide: TableModel] = [:]


        print("Active tables: \(activeTables.map { "Table \($0.id) at (\($0.row), \($0.column))" })")
        print("Checking neighbors for table \(table.id) at row \(table.row), column \(table.column):")

        for side in TableModel.TableSide.allCases {
            let offset = side.offset()
            let neighborPosition = (row: table.row + offset.rowOffset, col: table.column + offset.colOffset)

            print("Neighbor position: \(neighborPosition.row), \(neighborPosition.col) for side \(side)")

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
                print("Found adjacent table \(neighborTable.id) at side \(side).")
            } else {
                print("No active table found at neighbor position.")
            }
        }

        print("Adjacent tables for table \(table.id): \(adjacentCount), details: \(adjacentDetails.map { ($0.key, $0.value.id) })")
        return (adjacentCount, adjacentDetails)
    }
    

    
    // MARK: - Reservation-Aware Adjacency
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
                print("Shared reservation with table \(adjacentTable.id).")
            }
        }

        print("Shared reservation tables for table \(table.id): \(sharedReservationTables.map { $0.id })")
        return sharedReservationTables
    }
    
    // MARK: - Helpers for Adjacency
    
    // Lookup a table by grid position
    func fetchTable(row: Int, column: Int, combinedDateTime: Date, activeTables: [TableModel]) -> TableModel? {
        guard row >= 0, column >= 0 else {
            print("fetchTable: Invalid grid position (\(row), \(column))")
            return nil
        }

        print("fetchTable: Checking for table at (\(row), \(column))")

        // Check active tables first
        if let activeTable = activeTables.first(where: { $0.row == row && $0.column == column }) {
            print("fetchTable: Found active table \(activeTable.id) at (\(row), \(column))")
            return activeTable
        }

        // Fallback to tables managed by the store
        let storeTables = store.reservations.flatMap { $0.tables }
        if let table = storeTables.first(where: { $0.row == row && $0.column == column }) {
            print("fetchTable: Found table \(table.id) in store at (\(row), \(column))")
            return table
        }

        print("fetchTable: No table found at (\(row), \(column))")
        return nil
    }

   
    
    func getTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            return tables
        } else {
            // If no layout exists for this date and category, fallback to base tables
            print("No cached tables found for \(key). Returning base tables.")
            return tableStore.baseTables
        }
    }
    

}
