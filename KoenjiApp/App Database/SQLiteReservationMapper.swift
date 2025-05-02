//
//  SQLiteReservationMappers.swift
//  KoenjiApp
//
//  Created by Refactor Bot on 27 Apr 2025.
//
//  This file contains *pure* mappers that convert SQLite rows
//  into the value types used by the actor-based data layer.
//  It has **no** UI, Firebase, or Main-Actor dependencies.
//

import SQLite
import Foundation

// MARK: - Reservation ----------------------------------------------------

/// Converts an SQLite `Row` into a `Reservation`.
///
/// - Important: Returns `nil` if any enum / UUID value is malformed.
func reservation(from row: Row) -> Reservation? {
    guard
        let uuid        = UUID(uuidString: row[SQLiteManager.shared.id]),
        let category    = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
        let acceptance  = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
        let status      = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
        let type        = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
    else { return nil }

    // Decode tables JSON (array of `TableModel` or array of Int ids)
    let tablesJSON   = row[SQLiteManager.shared.tables]
    let tables: [TableModel] = decodeTables(jsonString: tablesJSON)

    return Reservation(
        id: uuid,
        name: row[SQLiteManager.shared.name],
        phone: row[SQLiteManager.shared.phone],
        numberOfPersons: row[SQLiteManager.shared.numberOfPersons],
        dateString: row[SQLiteManager.shared.dateString],
        category: category,
        startTime: row[SQLiteManager.shared.startTime],
        endTime: row[SQLiteManager.shared.endTime],
        acceptance: acceptance,
        status: status,
        reservationType: type,
        group: row[SQLiteManager.shared.group],
        notes: row[SQLiteManager.shared.notes],
        tables: tables,
        creationDate: row[SQLiteManager.shared.creationDate],
        lastEditedOn: row[SQLiteManager.shared.lastEditedOn],
        isMock: row[SQLiteManager.shared.isMock],
        assignedEmoji: row[SQLiteManager.shared.assignedEmoji] ?? "",
        imageData: row[SQLiteManager.shared.imageData],
        preferredLanguage: row[SQLiteManager.shared.preferredLanguage]
    )
}

/// Helper that copes with both `[TableModel]` and `[Int]` legacy formats.
private func decodeTables(jsonString: String?) -> [TableModel] {
    guard
        let jsonString,
        let data = jsonString.data(using: .utf8)
    else { return [] }

    let decoder = JSONDecoder()
    if let tables = try? decoder.decode([TableModel].self, from: data) {
        return tables
    }
    if let ids = try? decoder.decode([Int].self, from: data) {
        return ids.map { id in
            TableModel(id: id, name: "Table \(id)", maxCapacity: 4, row: 0, column: 0)
        }
    }
    return []
}

// MARK: - Session --------------------------------------------------------

func session(from row: Row) -> Session {
    Session(
        id:          row[SQLiteManager.shared.sessionId],
        uuid:        row[SQLiteManager.shared.sessionUUID] ?? "null",
        userName:    row[SQLiteManager.shared.sessionUserName],
        isEditing:   row[SQLiteManager.shared.sessionIsEditing],
        lastUpdate:  row[SQLiteManager.shared.sessionLastUpdate],
        isActive:    row[SQLiteManager.shared.sessionIsActive]
    )
}