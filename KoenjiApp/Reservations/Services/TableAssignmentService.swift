import Foundation
import OSLog

/// Service responsible for handling table assignment logic.
///
/// The TableAssignmentService manages the assignment of tables to reservations based on
/// various strategies including manual assignment, automatic assignment, and contiguous block
/// assignment. It also provides functionality to check table availability and occupancy.
///
/// This service is a core component of the reservation system, ensuring that tables are
/// efficiently assigned while respecting business rules and constraints.
class TableAssignmentService: ObservableObject {
    // MARK: - Dependencies
    
    /// The preferred order for assigning tables automatically.
    ///
    /// This array defines the sequence in which tables should be assigned when using
    /// automatic assignment strategies. Tables earlier in the array are assigned first.
    let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]

    // MARK: - Private Properties
    
    /// Logger instance for debugging and tracking service operations.
    let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "TableAssignmentService"
    )

    // MARK: - Public Methods

    /// Assigns tables manually starting from a forced table.
    ///
    /// This method attempts to assign tables to a reservation, starting with a specific
    /// selected table. It first checks if the selected table is available, then tries to
    /// find a contiguous block of tables starting from that table. If a contiguous block
    /// isn't possible, it falls back to non-contiguous assignment.
    ///
    /// - Parameters:
    ///   - reservation: The reservation that needs tables assigned
    ///   - tables: Available tables in the restaurant
    ///   - reservations: Existing reservations that might conflict
    ///   - selectedTable: The table to start assignment from
    /// - Returns: An array of assigned tables if successful, nil if assignment failed
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
    ///
    /// This method assigns tables to a reservation following the order defined in
    /// `tableAssignmentOrder`. It attempts to assign tables until the required capacity
    /// for the reservation is met.
    ///
    /// - Parameters:
    ///   - reservation: The reservation that needs tables assigned
    ///   - reservations: Existing reservations that might conflict
    ///   - tables: Available tables in the restaurant
    /// - Returns: An array of assigned tables if successful, nil if assignment failed
    func assignTablesAutomatically(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else { return nil }
        return assignTablesInOrder(for: reservation, reservations: reservations, tables: tables, reservationDate: reservationDate)
    }

    /// Assigns tables preferring contiguous blocks but falls back to auto-assignment.
    ///
    /// This method first attempts to find a contiguous block of tables that can accommodate
    /// the reservation. If no suitable contiguous block is found, it falls back to the
    /// automatic assignment strategy.
    ///
    /// - Parameters:
    ///   - reservation: The reservation that needs tables assigned
    ///   - reservations: Existing reservations that might conflict
    ///   - tables: Available tables in the restaurant
    /// - Returns: An array of assigned tables if successful, nil if assignment failed
    func assignTablesPreferContiguous(
        for reservation: Reservation,
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else {
            Task { @MainActor in
                AppLog.error("Failed to parse reservation date for reservation ID: \(reservation.id)")
            }
            return nil
        }
        Task { @MainActor in
            AppLog.debug("Processing reservation date: \(reservationDate) for reservation ID: \(reservation.id)")
        }
        // Try to find a single contiguous block
        if let contiguousBlock = findContiguousBlock(
            reservation: reservation,
            reservations: reservations,
            orderedTables: sortTables(tables),
            reservationDate: reservationDate
        ) {
            Task { @MainActor in
                AppLog.info("Found contiguous block for reservation ID: \(reservation.id). Tables: \(contiguousBlock.map { $0.name }.joined(separator: ", "))")
            }
            return contiguousBlock
        }

        Task { @MainActor in
            AppLog.debug("No contiguous block found for reservation ID: \(reservation.id). Using fallback assignment.")
        }

        // Fallback to automatic assignment
        return assignTablesInOrder(for: reservation, reservations: reservations, tables: tables, reservationDate: reservationDate)
    }

    /// Checks for table availability.
    ///
    /// This method determines which tables are available for a given reservation by checking
    /// if each table is occupied during the reservation's time period. It also indicates
    /// which tables are currently assigned to the reservation.
    ///
    /// - Parameters:
    ///   - reservation: The reservation to check availability for (optional)
    ///   - reservations: All existing reservations
    ///   - tables: All tables in the restaurant
    /// - Returns: An array of tuples containing available tables and whether they're currently assigned to the reservation
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

    /// Checks if a table is occupied for a given time period.
    /// 
    /// This method excludes reservations with statuses like .canceled, .noShow, .deleted,
    /// and types like .waitingList since these reservations don't actually occupy tables.
    /// This ensures that tables previously assigned to reservations that were later cancelled
    /// or moved to the waiting list are correctly shown as available.
    ///
    /// - Parameters:
    ///   - table: The table to check
    ///   - reservations: All existing reservations
    ///   - date: The date to check
    ///   - startTime: The start time of the period to check
    ///   - endTime: The end time of the period to check
    ///   - reservationID: Optional ID of a reservation to exclude from the check
    /// - Returns: True if the table is occupied during the specified period, false otherwise
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
            Task { @MainActor in
                AppLog.error("Failed to combine date and time. Start: \(startTime), End: \(endTime)")
            }
            return false
        }

        // we should evaluate if it's okay to keep it 0 or we want to hard code it; eventually it could be configured in the settings!
        let gracePeriod: TimeInterval = 0 

        return reservations.contains { reservation in
            // Exclude current reservation if editing
            if reservation.id == reservationID { return false }
            
            // Exclude reservations with statuses that don't actually occupy tables
            if reservation.status == .canceled || 
               reservation.status == .noShow || 
               reservation.status == .deleted {
                return false
            }
            
            // Exclude reservations with types that don't actually occupy tables
            if reservation.reservationType == .waitingList {
                return false
            }
            
            // First check if this reservation has the table we're checking
            // Only proceed with date checks if the table is actually assigned
            guard reservation.tables.contains(where: { $0.id == table.id }) else {
                return false
            }

            // Now check dates for reservations that have this table
            guard let reservationDate = reservation.normalizedDate,
                  let reservationStart = reservation.startTimeDate,
                  let reservationEnd = reservation.endTimeDate else {
                // Only log warnings for reservations that claim to have this table
                // but have invalid date information
                Task { @MainActor in
                    AppLog.warning("Failed to parse reservation details for: \(reservation.name)")
                }
                return false
            }
            
            guard reservationDate.isSameDay(as: date) else { return false }
            
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
    
    /// Assigns tables in the predefined order until the required capacity is met.
    ///
    /// - Parameters:
    ///   - reservation: The reservation that needs tables assigned
    ///   - reservations: Existing reservations that might conflict
    ///   - tables: Available tables in the restaurant
    ///   - reservationDate: The normalized date of the reservation
    /// - Returns: An array of assigned tables if successful, nil if assignment failed
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
            if assignedCapacity >= neededCapacity { 
                Task { @MainActor in
                    AppLog.debug("Successfully assigned \(assignedTables.count) tables with capacity \(assignedCapacity)")
                }
                return assignedTables 
            }
        }
        Task { @MainActor in
            AppLog.warning("Failed to assign tables in order. Required capacity: \(neededCapacity), Found: \(assignedCapacity)")
        }
        return nil
    }

    /// Finds a contiguous block of tables that can accommodate the reservation.
    ///
    /// - Parameters:
    ///   - reservation: The reservation that needs tables assigned
    ///   - reservations: Existing reservations that might conflict
    ///   - orderedTables: Tables ordered by preference
    ///   - reservationDate: The normalized date of the reservation
    /// - Returns: An array of tables forming a contiguous block if found, nil otherwise
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

    /// Finds a contiguous block of tables starting from a specific table.
    ///
    /// - Parameters:
    ///   - tables: All available tables
    ///   - forcedTable: The table to start the block from
    ///   - reservation: The reservation that needs tables assigned
    ///   - reservations: Existing reservations that might conflict
    ///   - reservationDate: The normalized date of the reservation
    /// - Returns: An array of tables forming a contiguous block if found, nil otherwise
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

    /// Fallback method for manual assignment when contiguous blocks aren't possible.
    ///
    /// - Parameters:
    ///   - reservation: The reservation that needs tables assigned
    ///   - reservations: Existing reservations that might conflict
    ///   - tables: All available tables
    ///   - forcedTable: The table that must be included in the assignment
    ///   - reservationDate: The normalized date of the reservation
    /// - Returns: An array of assigned tables if successful, nil if assignment failed
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

    /// Sorts tables according to the predefined assignment order.
    ///
    /// - Parameter tables: The tables to sort
    /// - Returns: Sorted array of tables based on the tableAssignmentOrder
    private func sortTables(_ tables: [TableModel]) -> [TableModel] {
        tables.sorted {
            guard let index1 = tableAssignmentOrder.firstIndex(of: $0.name),
                  let index2 = tableAssignmentOrder.firstIndex(of: $1.name) else { return $0.id < $1.id }
            return index1 < index2
        }
    }
}

/// Errors that can occur during table assignment.
enum TableAssignmentError: Error {
    /// No tables are available at all
    case noTablesLeft
    
    /// There are tables, but not enough to seat the requested party
    case insufficientTables
    
    /// The manually selected table doesn't exist in the layout
    case tableNotFound
    
    /// The requested table is currently locked/occupied
    case tableLocked
    
    /// Fallback for any undefined error
    case unknown
}
