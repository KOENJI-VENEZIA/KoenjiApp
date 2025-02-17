//
//  ReservationMapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//


import SQLite
import Foundation

@MainActor
struct ReservationMapper {
    static func reservation(from row: Row) -> Reservation? {
        guard
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
            let reservationType = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
        else { print("Failed to convert back UUID and enums")
            return nil }
        
// Decode the tables JSON
        var tablesArray: [TableModel] = []
        if let tablesString = row[SQLiteManager.shared.tables],
           let data = tablesString.data(using: .utf8) {
            let decoder = JSONDecoder()
            // Optionally set decoder settings if needed (e.g., dateDecodingStrategy)
            tablesArray = (try? decoder.decode([TableModel].self, from: data)) ?? []
        }
        
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
            reservationType: reservationType,
            group: row[SQLiteManager.shared.group],
            notes: row[SQLiteManager.shared.notes],
            tables: tablesArray,  // Use the decoded array
            creationDate: row[SQLiteManager.shared.creationDate],
            lastEditedOn: row[SQLiteManager.shared.lastEditedOn],
            isMock: row[SQLiteManager.shared.isMock],
            assignedEmoji: row[SQLiteManager.shared.assignedEmoji] ?? "",
            imageData: row[SQLiteManager.shared.imageData]
        )
    }
}

@MainActor
struct SessionMapper {
    
    static func session(from row: Row) -> Session? {
        return Session(
            id: row[SQLiteManager.shared.sessionId],
            uuid: row[SQLiteManager.shared.sessionUUID] ?? "null",
            userName: row[SQLiteManager.shared.sessionUserName],
            isEditing: row[SQLiteManager.shared.sessionIsEditing],
            lastUpdate: row[SQLiteManager.shared.sessionLastUpdate],
            isActive: row[SQLiteManager.shared.sessionIsActive]
        )
        
    }
}
