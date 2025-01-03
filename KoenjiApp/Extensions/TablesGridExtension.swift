//
//  TableGridExtension.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation
import SwiftUI

/// Extension to manage grid-related operations for tables
extension ReservationStore {
    
    // MARK: - Movement

    enum MoveResult {
        case move
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

            // Perform the move
            withAnimation(.easeInOut(duration: 0.3)) {
                if let idx = tables.firstIndex(where: { $0.id == table.id }) {
                    tables[idx] = newTable
                }
            }
            markTable(newTable, occupied: true)
            print("moveTable: Moved \(table.name) to (\(clampedRow), \(clampedCol)) successfully.")
            return .move
        } else {
            // Invalid move; re-mark the original table's position
            markTable(table, occupied: true)
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

        // Check for no overlap scenarios
        return !(table1MaxX <= table2MinX || table1MinX >= table2MaxX || table1MaxY <= table2MinY || table1MinY >= table2MaxY)
    }

    func canPlaceTable(_ table: TableModel, excluding excludedTableIDs: Set<Int> = []) -> Bool {
        for otherTable in tables where otherTable.id != table.id && !excludedTableIDs.contains(otherTable.id) {
            if tablesIntersect(table, otherTable) {
                return false
            }
        }
        return true
    }

    // MARK: - Helpers

    func markTable(_ table: TableModel, occupied: Bool) {
        for r in table.row..<(table.row + table.height) {
            for c in table.column..<(table.column + table.width) {
                guard r >= 0, r < grid.count, c >= 0, c < grid[0].count else { continue }
                grid[r][c] = occupied ? table.id : nil
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

    // MARK: - Utilities

    func isTableOccupied(_ table: TableModel, date: Date, startTimeString: String, endTimeString: String) -> Bool {
        guard
            let startTime = TimeHelpers.date(from: startTimeString, on: date),
            let endTime = TimeHelpers.date(from: endTimeString, on: date)
        else {
            return false
        }

        return reservations.contains { reservation in
            guard let reservationDate = reservation.date else { return false }
            if reservationDate != date { return false }
            if !reservation.tables.contains(where: { $0.id == table.id }) { return false }

            let reservationStart = TimeHelpers.date(from: reservation.startTime, on: date)
            let reservationEnd = TimeHelpers.date(from: reservation.endTime, on: date)

            return TimeHelpers.timeRangesOverlap(start1: reservationStart, end1: reservationEnd, start2: startTime, end2: endTime)
        }
    }
}
