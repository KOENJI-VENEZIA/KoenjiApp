//
//  TableValidation.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

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

            // Check if the reservation is active and assigned to the table
            return reservation.isActive(queryDate: now, queryTime: now) &&
                   reservation.tables.contains(where: { $0.id == table.id })
        }
    }
    
    /// Checks if two tables belong to the same reservation.
    func areTablesInSameReservation(_ tableA: TableModel, _ tableB: TableModel) -> Bool {
        for reservation in reservations {
            let tableIDs = Set(reservation.tables.map(\.id))
            if tableIDs.contains(tableA.id) && tableIDs.contains(tableB.id) {
                return true
            }
        }
        return false
    }
}
