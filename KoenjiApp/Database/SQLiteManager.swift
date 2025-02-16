//
//  SQLiteManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//


import Foundation
import SQLite
typealias Expression = SQLite.Expression

@MainActor
class SQLiteManager {
    static let shared = SQLiteManager()
    var db: Connection!
    
    // Define the table and columns. (We convert UUID to String.)
    let reservationsTable = Table("reservations")
    let id = Expression<String>("id")
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
    let colorHue = Expression<Double>("colorHue")
    // You can add additional columns (or serialize complex types like `tables` into JSON)
    
    private init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                in: .userDomainMask,
                                                                appropriateFor: nil,
                                                                create: true)
            let dbURL = documentDirectory.appendingPathComponent("reservations.sqlite3")
            db = try Connection(dbURL.path)
            createReservationsTable()
        } catch {
            print("SQLite init error: \(error)")
        }
    }
    
    private func createReservationsTable() {
        do {
            try db.run(reservationsTable.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(name)
                table.column(phone)
                table.column(numberOfPersons)
                table.column(dateString)
                table.column(category)
                table.column(startTime)
                table.column(endTime)
                table.column(acceptance)
                table.column(status)
                table.column(reservationType)
                table.column(group)
                table.column(notes)
                table.column(tables)
                table.column(creationDate)
                table.column(lastEditedOn)
                table.column(isMock)
                table.column(assignedEmoji)
                table.column(imageData)
                table.column(colorHue)
            })
        } catch {
            print("Error creating reservations table: \(error)")
        }
    }
    
    // MARK: - CRUD Methods
    
    /// Inserts a Reservation into the database.
    func insertReservation(_ reservation: Reservation) {
        do {
           let encoder = JSONEncoder()
           let tablesData = try encoder.encode(reservation.tables)
           let tablesString = String(data: tablesData, encoding: .utf8)
           
           let insert = reservationsTable.insert(or: .replace,
               id <- reservation.id.uuidString,
               name <- reservation.name,
               phone <- reservation.phone,
               numberOfPersons <- reservation.numberOfPersons,
               dateString <- reservation.dateString,
               category <- reservation.category.rawValue,
               startTime <- reservation.startTime,
               endTime <- reservation.endTime,
               acceptance <- reservation.acceptance.rawValue,
               status <- reservation.status.rawValue,
               reservationType <- reservation.reservationType.rawValue,
               group <- reservation.group,
               notes <- reservation.notes,
               tables <- tablesString,
               creationDate <- reservation.creationDate,
               lastEditedOn <- reservation.lastEditedOn,
               isMock <- reservation.isMock,
               assignedEmoji <- reservation.assignedEmoji,
               imageData <- reservation.imageData,
               colorHue <- reservation.colorHue
           )
           try db.run(insert)
       } catch {
           print("SQLite Insert/Replace error: \(error)")
       }
    }
    
    /// Updates an existing Reservation in the database.
    func updateReservation(_ reservation: Reservation) {
        do {
            let encoder = JSONEncoder()
            // Optionally set any encoder settings you use (e.g., dateEncodingStrategy)
            let tablesData = try encoder.encode(reservation.tables)
            let tablesString = String(data: tablesData, encoding: .utf8)
            let row = reservationsTable.filter(id == reservation.id.uuidString)
            let update = row.update(
                name <- reservation.name,
                phone <- reservation.phone,
                numberOfPersons <- reservation.numberOfPersons,
                dateString <- reservation.dateString,
                category <- reservation.category.rawValue,
                startTime <- reservation.startTime,
                endTime <- reservation.endTime,
                acceptance <- reservation.acceptance.rawValue,
                status <- reservation.status.rawValue,
                reservationType <- reservation.reservationType.rawValue,
                group <- reservation.group,
                notes <- reservation.notes,
                tables <- tablesString,
                creationDate <- reservation.creationDate,
                lastEditedOn <- reservation.lastEditedOn,
                isMock <- reservation.isMock,
                assignedEmoji <- reservation.assignedEmoji,
                imageData <- reservation.imageData,
                colorHue <- reservation.colorHue
            )
            try db.run(update)
        } catch {
            print("SQLite Update error: \(error)")
        }
    }
    
    /// Deletes a Reservation from the database.
    func deleteReservation(withID reservationID: UUID) {
        do {
            let row = reservationsTable.filter(id == reservationID.uuidString)
            try db.run(row.delete())
        } catch {
            print("SQLite Delete error: \(error)")
        }
    }
    
    func deleteAllReservations() {
        do {
            // This deletes all rows in the table.
            try db.run(reservationsTable.delete())
            print("All reservations have been deleted from SQLite.")
        } catch {
            print("Error deleting all reservations: \(error)")
        }
    }
    
    
    
    /// Fetches all Reservations from the database.
    func fetchReservations() -> [Reservation] {
        var reservations: [Reservation] = []
        do {
            for row in try db.prepare(reservationsTable) {
                print("DEBUG: Checking row \(row)...")
                // Map the row into a Reservation. Note that you may need custom logic to convert strings back to enums.
                if let reservation = ReservationMapper.reservation(from: row) {
                    print("DEBUG: Found reservation of \(reservation.name). Appending it...")
                    reservations.append(reservation)
                }
            }
        } catch {
            print("DEBUG: SQLite Fetch error: \(error)")
        }
        let uniqueReservations = Dictionary(grouping: reservations, by: { $0.id }).compactMap { $0.value.first }
        return uniqueReservations    }
}
