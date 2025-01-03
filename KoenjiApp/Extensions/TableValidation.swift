import Foundation

/// Extension to manage table validation and relationships
extension ReservationStore {
    
    // MARK: - Table Validation

    /// Checks if a table is occupied by an active reservation.
    func isTableOccupiedByActiveReservation(_ table: TableModel, for reservationID: UUID? = nil) -> Bool {
        let now = Date()

        return reservations.contains { reservation in
            // Exclude the current reservation being processed
            if let reservationID = reservationID, reservation.id == reservationID {
                return false
            }

            // Parse reservation times and validate occupation
            guard
                let reservationDate = reservation.date,
                let reservationStart = TimeHelpers.date(from: reservation.startTime, on: reservationDate),
                let reservationEnd = TimeHelpers.date(from: reservation.endTime, on: reservationDate)
            else {
                print("isTableOccupiedByActiveReservation: Invalid date or time for reservation \(reservation.id)")
                return false
            }

            // Check if the reservation is active and assigned to the table
            return reservationDate == now &&
                   TimeHelpers.timeRangesOverlap(
                       start1: reservationStart,
                       end1: reservationEnd,
                       start2: now,
                       end2: now
                   ) &&
                   reservation.tables.contains(where: { $0.id == table.id })
        }
    }

    /// Checks if two tables belong to the same reservation.
    func areTablesInSameReservation(_ tableA: TableModel, _ tableB: TableModel) -> Bool {
        return reservations.contains { reservation in
            let tableIDs = Set(reservation.tables.map(\.id))
            return tableIDs.contains(tableA.id) && tableIDs.contains(tableB.id)
        }
    }
}
