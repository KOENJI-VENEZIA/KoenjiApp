import Foundation

/// Service responsible for handling table assignment logic.
class TableAssignmentService: ObservableObject {
    // MARK: - Dependencies
    let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]

    // MARK: - Public Methods

    /// Assigns tables manually starting from a forced table.
    func assignTablesManually(
        for reservation: Reservation,
        tables: [TableModel],
        reservations: [Reservation],
        startingFrom selectedTable: TableModel
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else { return nil }

        // Check if the forced table is available
        if isTableOccupied(
            selectedTable,
            reservations: reservations,
            date: reservationDate,
            startTime: reservation.startTime,
            endTime: reservation.endTime,
            excluding: reservation.id
        ) {
            return nil // Forced table is occupied
        }

        // Try to find a contiguous block starting at the forced table
        if let contiguousBlock = findContiguousBlockStartingAtTable(
            tables: tables,
            forcedTable: selectedTable,
            reservation: reservation,
            reservations: reservations,
            reservationDate: reservationDate
        ) {
            return contiguousBlock
        }

        // Fallback to non-contiguous assignment
        return fallbackManualAssignment(for: reservation, reservations: reservations, tables: tables, forcedTable: selectedTable, reservationDate: reservationDate)
    }

    /// Assigns tables automatically in the predefined order.
    func assignTablesAutomatically(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else { return nil }
        return assignTablesInOrder(for: reservation, reservations: reservations, tables: tables, reservationDate: reservationDate)
    }

    /// Assigns tables preferring contiguous blocks but falls back to auto-assignment.
    func assignTablesPreferContiguous(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else {
            print("Failed to parse reservation date string: \(reservation.normalizedDate ?? Date()) for reservation ID: \(reservation.id) [assignTablesPreferContiguous() from TableAssignmentService]")
            return nil
        }
        print("Parsed reservation date: \(reservationDate) for reservation ID: \(reservation.id) [assignTablesPreferContiguous() from TableAssignmentService]")
        // Try to find a single contiguous block
        if let contiguousBlock = findContiguousBlock(
            reservation: reservation,
            reservations: reservations,
            orderedTables: sortTables(tables),
            reservationDate: reservationDate
        ) {
            print("Found contiguous block for reservation ID: \(reservation.id). Assigned tables: \(contiguousBlock.map { $0.name }) [assignTablesPreferContiguous() from TableAssignmentService]")
            return contiguousBlock
        }

        print("No contiguous block found for reservation ID: \(reservation.id). Proceeding to fallback. [assignTablesPreferContiguous() from TableAssignmentService]")

        // Fallback to automatic assignment
        return assignTablesInOrder(for: reservation, reservations: reservations, tables: tables, reservationDate: reservationDate)
    }

    /// Checks for table availability.
    func availableTables(
        for reservation: Reservation?,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [(table: TableModel, isCurrentlyAssigned: Bool)] {
        let reservationID = reservation?.id
        let reservationDate = reservation?.normalizedDate ?? Date()
        let startTime = reservation?.startTime ?? ""
        let endTime = reservation?.endTime ?? ""

        return tables.compactMap { table in
            let isOccupied = isTableOccupied(
                table,
                reservations: reservations,
                date: reservationDate,
                startTime: startTime,
                endTime: endTime,
                excluding: reservationID
            )
            let isCurrentlyAssigned = reservation?.tables.contains(where: { $0.id == table.id }) ?? false
            return (!isOccupied || isCurrentlyAssigned) ? (table, isCurrentlyAssigned) : nil
        }
    }

    // MARK: - Private Helpers

    func isTableOccupied(
        _ table: TableModel,
        reservations: [Reservation],
        date: Date,
        startTime: String,
        endTime: String,
        excluding reservationID: UUID? = nil
    ) -> Bool {
        guard let start = DateHelper.combineDateAndTime(date: date, timeString: startTime),
              let end = DateHelper.combineDateAndTime(date: date, timeString: endTime) else {
            print("Failed to combine date and time for startTime: \(startTime), endTime: \(endTime)")
            return false
        }

        // we should evaluate if it's okay to keep it 0 or we want to hard code it; eventually it could be configured in the settings!
        let gracePeriod: TimeInterval = 0 

        return reservations.contains { reservation in
            // Exclude current reservation if editing
            if reservation.id == reservationID { return false }

            guard let reservationDate = reservation.normalizedDate,
                  let reservationStart = reservation.startTimeDate,
                  let reservationEnd = reservation.endTimeDate,
                  reservation.tables.contains(where: { $0.id == table.id }) else {
                print("Failed to parse reservation: \(reservation.name)")
                return false
            }
            
            guard reservationDate.isSameDay(as: date) else { return false }
            // Check if the reservation ends within 5 minutes before the new reservation's start
            

            // Adjust reservation times for buffer
            let adjustedReservationEnd = reservationEnd.addingTimeInterval(gracePeriod)
            let reservationEndsCloseToNewStart = adjustedReservationEnd > start && reservationEnd <= start

            let overlaps = TimeHelpers.timeRangesOverlap(
                start1: reservationStart,
                end1: adjustedReservationEnd,
                start2: start,
                end2: end
            )

            return overlaps || reservationEndsCloseToNewStart
        }
    }
    
    private func assignTablesInOrder(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel],
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        let orderedTables = sortTables(tables)

        for table in orderedTables where !isTableOccupied(
            table,
            reservations: reservations,
            date: reservationDate,
            startTime: reservation.startTime,
            endTime: reservation.endTime,
            excluding: reservation.id
        ) {
            assignedTables.append(table)
            assignedCapacity += table.maxCapacity
            if assignedCapacity >= neededCapacity { return assignedTables }
        }
        print("Failed to assign tables in order [assignTablesInOrder() from TableAssignmentService]")
        return nil
    }

    private func findContiguousBlock(
        reservation: Reservation,
        reservations: [Reservation],
        orderedTables: [TableModel],
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var block: [TableModel] = []
        var assignedCapacity = 0

        for table in orderedTables where !isTableOccupied(
            table,
            reservations: reservations,
            date: reservationDate,
            startTime: reservation.startTime,
            endTime: reservation.endTime,
            excluding: reservation.id
        ) {
            block.append(table)
            assignedCapacity += table.maxCapacity
            if assignedCapacity >= neededCapacity { return block }
        }
        return nil
    }

    private func findContiguousBlockStartingAtTable(
        tables: [TableModel],
        forcedTable: TableModel,
        reservation: Reservation,
        reservations: [Reservation],
        reservationDate: Date
    ) -> [TableModel]? {
        let orderedTables = sortTables(tables)
        let startIndex = orderedTables.firstIndex { $0.id == forcedTable.id } ?? 0
        let slice = orderedTables[startIndex...]

        return findContiguousBlock(
            reservation: reservation,
            reservations: reservations,
            orderedTables: Array(slice),
            reservationDate: reservationDate
        )
    }

    private func fallbackManualAssignment(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel],
        forcedTable: TableModel,
        reservationDate: Date
    ) -> [TableModel]? {
        var assignedTables: [TableModel] = [forcedTable]
        let orderedTables = sortTables(tables)
        var assignedCapacity = forcedTable.maxCapacity

        for table in orderedTables where table.id != forcedTable.id && !isTableOccupied(
            table,
            reservations: reservations,
            date: reservationDate,
            startTime: reservation.startTime,
            endTime: reservation.endTime,
            excluding: reservation.id
        ) {
            assignedTables.append(table)
            assignedCapacity += table.maxCapacity
            if assignedCapacity >= reservation.numberOfPersons { return assignedTables }
        }
        return nil
    }

    private func sortTables(_ tables: [TableModel]) -> [TableModel] {
        tables.sorted {
            guard let index1 = tableAssignmentOrder.firstIndex(of: $0.name),
                  let index2 = tableAssignmentOrder.firstIndex(of: $1.name) else { return $0.id < $1.id }
            return index1 < index2
        }
    }
}

enum TableAssignmentError: Error {
    case noTablesLeft       // No tables are available at all
    case insufficientTables // There are tables, but not enough to seat the requested party
    case tableNotFound      // The manually selected table doesn't exist in the layout
    case tableLocked        // The requested table is currently locked/occupied
    case unknown            // Fallback for any undefined error
}
