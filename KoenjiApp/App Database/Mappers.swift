//
//  ReservationMapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//


import SQLite
import Foundation
import OSLog

@MainActor
struct ReservationMapper {
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func reservation(from row: Row) -> Reservation? {
        guard
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
            let reservationType = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
        else {
            logger.error("Failed to convert UUID or enums for reservation row")
            return nil
        }
        
        var tablesArray: [TableModel] = []
        if let tablesString = row[SQLiteManager.shared.tables],
           let data = tablesString.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                // First try to decode as an array of TableModel objects
                tablesArray = try decoder.decode([TableModel].self, from: data)
                logger.debug("Successfully decoded \(tablesArray.count) tables as TableModel objects")
            } catch {
                logger.error("Failed to decode tables as TableModel array: \(error.localizedDescription)")
                
                // If that fails, try to decode as an array of table IDs
                do {
                    let tableIds = try decoder.decode([Int].self, from: data)
                    logger.debug("Successfully decoded \(tableIds.count) table IDs")
                    
                    // Convert table IDs to TableModel objects
                    tablesArray = tableIds.map { id in
                        TableModel(id: id, name: "Table \(id)", maxCapacity: 4, row: 0, column: 0) // Default values
                    }
                    logger.debug("Converted \(tablesArray.count) table IDs to TableModel objects")
                } catch {
                    logger.error("Failed to decode tables as ID array: \(error.localizedDescription)")
                    
                    // Log the actual JSON string for debugging
                    logger.debug("Raw tables JSON: \(tablesString)")
                }
            }
        } else {
            logger.warning("No tables data found for reservation")
        }
        
        let reservation = Reservation(
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
            imageData: row[SQLiteManager.shared.imageData],
            preferredLanguage: row[SQLiteManager.shared.preferredLanguage]
        )
        
        logger.debug("Successfully mapped reservation: \(reservation.name) with \(tablesArray.count) tables")
        return reservation
    }
}

@MainActor
struct SessionMapper {
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func session(from row: Row) -> Session? {
        let session = Session(
            id: row[SQLiteManager.shared.sessionId],
            uuid: row[SQLiteManager.shared.sessionUUID] ?? "null",
            userName: row[SQLiteManager.shared.sessionUserName],
            isEditing: row[SQLiteManager.shared.sessionIsEditing],
            lastUpdate: row[SQLiteManager.shared.sessionLastUpdate],
            isActive: row[SQLiteManager.shared.sessionIsActive]
        )
        logger.debug("Successfully mapped session: \(session.id)")
        return session
    }
}
