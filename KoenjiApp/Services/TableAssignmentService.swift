//
//  TableAssignmentService.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 4/1/25.
//


import Foundation

/// Service responsible for handling table assignment logic.
class TableAssignmentService {
    // MARK: - Dependencies
    let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]

    // MARK: - Methods

    /// Assigns tables manually starting from a forced table (`selectedTable`).
    /// 1) Attempts to seat the entire reservation in a contiguous block
    ///    (beginning at `selectedTable` in your `tableAssignmentOrder`).
    /// 2) If that fails, falls back to the "grab any free tables" approach.
    func assignTablesManually(
        for reservation: Reservation,
        tables: [TableModel],
        reservations: [Reservation],
        startingFrom selectedTable: TableModel
    ) -> [TableModel]? {
        guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else { return nil }
        
        // First ensure the forced table itself is not occupied.
        if isTableOccupied(
            selectedTable,
            reservations: reservations,
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
            tables: tables,
            forcedTable: selectedTable,
            reservation: reservation,
            reservations: reservations,
            reservationDate: reservationDate
        ) {
            // If we found a contiguous block that meets capacity, return it.
            return contiguousBlock
        }
        
        // STEP 2: Fallback to old approach: forced table + "grab any free tables"
        return fallbackManualAssignment(for: reservation, reservations: reservations, tables: tables, forcedTable: selectedTable, reservationDate: reservationDate)
    }

    /// Assigns tables automatically by iterating over them in a predefined order
    /// until capacity is met or no suitable tables remain.
    func assignTablesAutomatically(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else { return nil }
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        var assignedIDs = Set<Int>()

        // Sort tables based on the defined order
        let orderedTables = tables.sorted { first, second in
            guard let firstIndex = tableAssignmentOrder.firstIndex(of: first.name),
                  let secondIndex = tableAssignmentOrder.firstIndex(of: second.name) else {
                return first.id < second.id
            }
            return firstIndex < secondIndex
        }

        var startIndex = 0
        while assignedCapacity < neededCapacity {
            if startIndex >= orderedTables.count {
                // Wrap around to the beginning
                startIndex = 0
            }

            let table = orderedTables[startIndex]

            // Skip already assigned or occupied tables
            if assignedIDs.contains(table.id) || isTableOccupied(
                table,
                reservations: reservations,
                date: reservationDate,
                startTimeString: reservation.startTime,
                endTimeString: reservation.endTime,
                excluding: reservation.id
            ) {
                startIndex += 1
                continue
            }

            // Assign table
            assignedTables.append(table)
            assignedIDs.insert(table.id)
            assignedCapacity += table.maxCapacity
            startIndex += 1

            // If all tables have been checked and capacity isn't met, stop
            if assignedIDs.count == orderedTables.count {
                break
            }
        }

        if assignedCapacity >= neededCapacity {
            print("Auto-assigned for \(reservation.id): \(assignedTables.map { $0.name })")
            return assignedTables
        } else {
            print("Error: Unable to assign enough tables for reservation \(reservation.id)!")
            return nil
        }
    }


    /// Attempts to find a contiguous block of tables (in sorted order) to seat
    /// the entire reservation. If that fails, falls back to auto-assignment.
    func assignTablesPreferContiguous(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel]
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
            reservations: reservations,
            orderedTables: orderedTables,
            reservationDate: reservationDate
        ) {
            print("Contiguous assignment for \(reservation.id): \(contiguousBlock.map { $0.name })")
            return contiguousBlock
        }
        
        // 2) If no contiguous block was found, fallback to auto-assign
        let fallback = assignTablesAutomatically(for: reservation, reservations: reservations, tables: tables)
        if fallback != nil {
            print("Falling back to non-contiguous auto-assign for \(reservation.id).")
        }
        return fallback
    }
    
    /// Sliding-window approach to find one consecutive slice of unoccupied tables
    /// whose total capacity >= reservation.numberOfPersons.
    private func findContiguousBlock(
        reservation: Reservation,
        reservations: [Reservation],
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
                    reservations: reservations,
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

    func isTableOccupied(
        _ table: TableModel,
        reservations: [Reservation],
        date: Date,
        startTimeString: String,
        endTimeString: String,
        excluding reservationID: UUID? = nil
    ) -> Bool {
        
        print("Function called with:")
        print("Table: \(table.name) (ID: \(table.id))")
        print("Date: \(date)")
        print("Start Time String: \(startTimeString)")
        print("End Time String: \(endTimeString)")
        
        guard
            let startTime = TimeHelpers.date(from: startTimeString, on: date),
            let endTime = TimeHelpers.date(from: endTimeString, on: date)
        else {
            print("Failed to parse startTime or endTime.")
            return false
        }
        
        for reservation in reservations {
            // Exclude a specific reservation if needed
            if let excludeID = reservationID, reservation.id == excludeID {
                print("Excluding reservation ID: \(excludeID)")
                continue
            }
            
            // Convert reservation times
            guard
                let reservationDate = reservation.date,
                let reservationStart = TimeHelpers.date(from: reservation.startTime, on: reservationDate),
                let reservationEnd = TimeHelpers.date(from: reservation.endTime, on: reservationDate)
            else {
                print("Failed to parse reservation times for reservation ID: \(reservation.id)")
                continue
            }
            
            print("\nChecking reservation ID: \(reservation.id)")
            print("Requested Date: \(date)")
            print("Reservation Date: \(reservationDate)")
            print("Requested Start Time: \(startTime), End Time: \(endTime)")
            print("Reservation Start Time: \(reservationStart), End Time: \(reservationEnd)")
            print("Table IDs in Reservation: \(reservation.tables.map { $0.id })")
            
            // Check if dates are the same day
            let sameDay = reservationDate.isSameDay(as: date)
            print("Same day: \(sameDay)")
            
            // Check if table is included
            let tableIncluded = reservation.tables.contains(where: { $0.id == table.id })
            print("Table included in reservation: \(tableIncluded)")
            
            // Check time overlap
            let overlap = TimeHelpers.timeRangesOverlap(
                start1: reservationStart,
                end1: reservationEnd,
                start2: startTime,
                end2: endTime
            )
            print("Time ranges overlap: \(overlap)")
            
            if sameDay && tableIncluded && overlap {
                print("Table \(table.name) is occupied by reservation ID: \(reservation.id)")
                return true
            }
        }
        
        print("No overlapping reservations found for table \(table.name).")
        return false
    }
    // Add additional helper methods here as needed.
    /// Attempts to find a contiguous block of tables (starting exactly at `forcedTable`)
    /// that meets the reservation's capacity.
    /// If successful, returns that block of tables; otherwise returns nil.
    private func findContiguousBlockStartingAtTable(
        tables: [TableModel],
        forcedTable: TableModel,
        reservation: Reservation,
        reservations: [Reservation],
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = forcedTable.maxCapacity
        var block = [forcedTable]
        var assignedTables = Set([forcedTable.id]) // Track assigned tables

        // If the forced table alone meets the capacity, return it
        if assignedCapacity >= neededCapacity {
            return block
        }

        // Sort the tables in order
        let orderedTables = tables.sorted {
            guard let iA = tableAssignmentOrder.firstIndex(of: $0.name),
                  let iB = tableAssignmentOrder.firstIndex(of: $1.name) else { return $0.id < $1.id }
            return iA < iB
        }

        // Find the starting index of the forced table
        guard let startIndex = orderedTables.firstIndex(where: { $0.id == forcedTable.id }) else { return nil }

        // Attempt to assign tables forward
        for index in (startIndex + 1)..<orderedTables.count {
            let candidate = orderedTables[index]
            if assignedTables.contains(candidate.id) || isTableOccupied(
                candidate, reservations: reservations, date: reservationDate,
                startTimeString: reservation.startTime, endTimeString: reservation.endTime, excluding: reservation.id
            ) {
                continue
            }
            block.append(candidate)
            assignedTables.insert(candidate.id)
            assignedCapacity += candidate.maxCapacity
            if assignedCapacity >= neededCapacity { return block }
        }

        // Attempt to assign tables backward
        for index in stride(from: startIndex - 1, through: 0, by: -1) {
            let candidate = orderedTables[index]
            if assignedTables.contains(candidate.id) || isTableOccupied(
                candidate, reservations: reservations, date: reservationDate,
                startTimeString: reservation.startTime, endTimeString: reservation.endTime, excluding: reservation.id
            ) {
                continue
            }
            block.append(candidate)
            assignedTables.insert(candidate.id)
            assignedCapacity += candidate.maxCapacity
            if assignedCapacity >= neededCapacity { return block }
        }

        // If capacity still isn't met, return nil
        return nil
    }



    /// The old fallback approach:
    /// 1) We forcibly assign the chosen table,
    /// 2) Then pick other free tables from the sorted list until capacity is met.
    private func fallbackManualAssignment(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel],
        forcedTable: TableModel,
        reservationDate: Date
    ) -> [TableModel]? {
        var assignedCapacity = forcedTable.maxCapacity
        var assignedTables: [TableModel] = [forcedTable]
        var assignedIDs = Set([forcedTable.id])

        // Sort tables by predefined order
        let orderedTables = tables.sorted {
            guard let iA = tableAssignmentOrder.firstIndex(of: $0.name),
                  let iB = tableAssignmentOrder.firstIndex(of: $1.name) else { return $0.id < $1.id }
            return iA < iB
        }

        // Assign tables based on order
        for table in orderedTables {
            if assignedCapacity >= reservation.numberOfPersons { break }
            if assignedIDs.contains(table.id) || isTableOccupied(
                table, reservations: reservations, date: reservationDate,
                startTimeString: reservation.startTime, endTimeString: reservation.endTime, excluding: reservation.id
            ) {
                continue
            }
            assignedTables.append(table)
            assignedIDs.insert(table.id)
            assignedCapacity += table.maxCapacity
        }

        // Return nil if capacity isn't met
        return assignedCapacity >= reservation.numberOfPersons ? assignedTables : nil
    }


    
    func availableTables(
        for reservation: Reservation?,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [(table: TableModel, isCurrentlyAssigned: Bool)] {
        let reservationID = reservation?.id
        let reservationDate = reservation?.date ?? Date()
        let startTime = reservation?.startTime ?? ""
        let endTime = reservation?.endTime ?? ""

        print("Tables: \(tables.map { $0.name })")
        print("Reservations: \(reservations.map { $0.id })")
        print("Debug: Available Tables Method Called")
        print("Reservation ID: \(String(describing: reservationID))")
        print("Reservation Date: \(reservationDate)")
        print("Start Time: \(startTime), End Time: \(endTime)")

        return tables.compactMap { table in
            // Check if the table is occupied
            let isOccupied = isTableOccupied(
                table,
                reservations: reservations,
                date: reservationDate,
                startTimeString: startTime,
                endTimeString: endTime,
                excluding: reservationID
            )

            // Check if the table is currently assigned to the reservation
            let isCurrentlyAssigned = reservation?.tables.contains(where: { $0.id == table.id }) ?? false

            print("Table: \(table.name), ID: \(table.id)")
            print("Occupied: \(isOccupied), Currently Assigned: \(isCurrentlyAssigned)")

            // Include table if it is not occupied or is currently assigned
            if !isOccupied || isCurrentlyAssigned {
                print("Table \(table.name) is available")
                return (table: table, isCurrentlyAssigned: isCurrentlyAssigned)
            }

            print("Table \(table.name) is not available")
            return nil // Exclude table
        }
    }



}
