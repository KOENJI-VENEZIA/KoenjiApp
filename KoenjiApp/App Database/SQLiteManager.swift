//
//  SQLiteManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//


import Foundation
import SQLite
import Logging

typealias Expression = SQLite.Expression

class SQLiteManager {
    // MARK: - Static Properties
    nonisolated(unsafe) static let shared = SQLiteManager()
    
    // MARK: - Database Properties
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
    let preferredLanguage = Expression<String?>("preferredLanguage")
    // You can add additional columns (or serialize complex types like `tables` into JSON)
    
    
    let sessionsTable = Table("sessions")
    let sessionId = Expression<String>("id")
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
    let sessionLastUpdate = Expression<Date>("lastUpdate")
    let sessionIsActive = Expression<Bool>("isActive")
    let sessionDeviceName = Expression<String?>("deviceName")
    let sessionProfileImageURL = Expression<String?>("profileImageURL")
    
    // Add profiles table
    let profilesTable = Table("profiles")
    let profileId = Expression<String>("id")
    let profileFirstName = Expression<String>("firstName")
    let profileLastName = Expression<String>("lastName")
    let profileEmail = Expression<String>("email")
    let profileImageURL = Expression<String?>("imageURL")
    let profileCreatedAt = Expression<Date>("createdAt")
    let profileUpdatedAt = Expression<Date>("updatedAt")
    
    // Add devices table
    let devicesTable = Table("devices")
    let deviceId = Expression<String>("id")
    let deviceProfileId = Expression<String>("profileId")
    let deviceName = Expression<String>("name")
    let deviceLastActive = Expression<Date>("lastActive")
    let deviceIsActive = Expression<Bool>("isActive")
    
    private init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory,
                                                              in: .userDomainMask,
                                                              appropriateFor: nil,
                                                              create: true)
            let dbURL = documentDirectory.appendingPathComponent("reservations.sqlite3")
            db = try Connection(dbURL.path)
            createReservationsTable()
            createSessionsTable()
            createProfilesTable()
            createDevicesTable()
            Task { @MainActor in 
                AppLog.info("SQLite database initialized at: \(dbURL.path)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("SQLite initialization failed: \(error.localizedDescription)")
                fatalError("SQLite initialization failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func createReservationsTable() {
        do {
            // First, check if the table exists
            let tableExists = try db.scalar("SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'reservations')") as? Int64 == 1
            
            if !tableExists {
                // Create the table if it doesn't exist
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
                    table.column(preferredLanguage)
                })
                Task { @MainActor in 
                    AppLog.debug("Reservations table created")
                }
            } else {
                // Check if the preferredLanguage column exists
                let hasPreferredLanguage = try db.scalar("SELECT COUNT(*) FROM pragma_table_info('reservations') WHERE name='preferredLanguage'") as? Int64 == 1
                
                if !hasPreferredLanguage {
                    // Add the new column if it doesn't exist
                    try db.run(reservationsTable.addColumn(preferredLanguage))
                    Task { @MainActor in 
                        AppLog.info("Added preferredLanguage column to existing reservations table")
                    }
                }
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Database operation failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func createSessionsTable() {
        do {
            try db.run(sessionsTable.create(ifNotExists: true) { table in
                table.column(sessionId, primaryKey: true)
                table.column(sessionUUID)
                table.column(sessionUserName)
                table.column(sessionIsEditing)
                table.column(sessionLastUpdate)
                table.column(sessionIsActive)
                table.column(sessionDeviceName)
                table.column(sessionProfileImageURL)
            })
            Task { @MainActor in 
                AppLog.debug("Sessions table created or verified")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to create sessions table: \(error.localizedDescription)")
            }
        }
    }
    
    private func createProfilesTable() {
        do {
            try db.run(profilesTable.create(ifNotExists: true) { table in
                table.column(profileId, primaryKey: true)
                table.column(profileFirstName)
                table.column(profileLastName)
                table.column(profileEmail)
                table.column(profileImageURL)
                table.column(profileCreatedAt)
                table.column(profileUpdatedAt)
            })
            Task { @MainActor in 
                AppLog.debug("Profiles table created or verified")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to create profiles table: \(error.localizedDescription)")
            }
        }
    }
    
    private func createDevicesTable() {
        do {
            try db.run(devicesTable.create(ifNotExists: true) { table in
                table.column(deviceId, primaryKey: true)
                table.column(deviceProfileId)
                table.column(deviceName)
                table.column(deviceLastActive)
                table.column(deviceIsActive)
                
                table.foreignKey(deviceProfileId, references: profilesTable, profileId, update: .cascade, delete: .cascade)
            })
            Task { @MainActor in 
                AppLog.debug("Devices table created or verified")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to create devices table: \(error.localizedDescription)")
            }
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
               colorHue <- reservation.colorHue,
               preferredLanguage <- reservation.preferredLanguage
           )
           try db.run(insert)
           Task { @MainActor in 
               AppLog.info("Inserted/Updated reservation: \(reservation.id)")
           }
       } catch {
           Task { @MainActor in 
               AppLog.error("Failed to insert reservation: \(error.localizedDescription)")
           }
       }
    }
    
    func insertSession(_ session: Session) {
        do {
            let insert = sessionsTable.insert(or: .replace,
                sessionId <- session.id,
                sessionUUID <- session.uuid,
                sessionUserName <- session.userName,
                sessionIsEditing <- session.isEditing,
                sessionLastUpdate <- session.lastUpdate,
                sessionIsActive <- session.isActive,
                sessionDeviceName <- session.deviceName,
                sessionProfileImageURL <- session.profileImageURL
            )
            try db.run(insert)
            Task { @MainActor in 
                AppLog.info("Inserted/Updated session: \(session.id)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to insert session: \(error.localizedDescription)")
            }
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
                colorHue <- reservation.colorHue,
                preferredLanguage <- reservation.preferredLanguage
            )
            try db.run(update)
            Task { @MainActor in 
                AppLog.info("Updated reservation: \(reservation.id)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("SQLite Update error: \(error)")
            }
        }
    }
    
    /// Deletes a Reservation from the database.
    func deleteReservation(withID reservationID: UUID) {
        do {
            let row = reservationsTable.filter(id == reservationID.uuidString)
            try db.run(row.delete())
            Task { @MainActor in 
                AppLog.info("Deleted reservation: \(reservationID)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to delete reservation: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteSession(withID sessionID: String) {
        do {
            let row = sessionsTable.filter(id == sessionID)
            try db.run(row.delete())
            Task { @MainActor in 
                AppLog.info("Deleted session: \(sessionID)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("SQLite Delete error: \(error)")
            }
        }
    }
    
    func deleteAllReservations() {
        do {
            // This deletes all rows in the table.
            try db.run(reservationsTable.delete())
            Task { @MainActor in 
                AppLog.info("All reservations deleted from database")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to delete all reservations: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteAllSessions() {
        do {
            try db.run(sessionsTable.delete())
            Task { @MainActor in 
                AppLog.info("All sessions deleted from database")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to delete all sessions: \(error.localizedDescription)")
            }
        }
    }
    
    
    /// Fetches all Reservations from the database.
    func fetchReservations() -> [Reservation] {
        var reservations: [Reservation] = []
        do {
            for row in try db.prepare(reservationsTable) {
                Task { @MainActor in 
                    AppLog.debug("Processing row for reservation")
                }
                if let reservation = reservation(from: row) {
                    Task { @MainActor in 
                        AppLog.debug("Successfully mapped reservation: \(reservation.name)")
                    }
                    reservations.append(reservation)
                }
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to fetch reservations: \(error.localizedDescription)")
            }
        }
        let uniqueReservations = Dictionary(grouping: reservations, by: { $0.id }).compactMap { $0.value.first }
        Task { @MainActor in 
            AppLog.info("Fetched \(uniqueReservations.count) unique reservations")
        }
        return uniqueReservations
    }
    
    func fetchSessions() -> [Session] {
        var sessions: [Session] = []
        do {
            for row in try db.prepare(sessionsTable) {
                Task { @MainActor in 
                    AppLog.debug("Processing row for session")
                }
                let session = session(from: row)
                    Task { @MainActor in 
                        AppLog.debug("Successfully mapped session: \(session.userName)")
                    }
                    sessions.append(session)
            }
            Task { @MainActor in 
                AppLog.info("Fetched \(sessions.count) sessions")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to fetch sessions: \(error.localizedDescription)")
            }
        }
        return sessions
    }
    
    // Add profile methods
    func insertProfile(_ profile: Profile) {
        do {
            let insert = profilesTable.insert(or: .replace,
                profileId <- profile.id,
                profileFirstName <- profile.firstName,
                profileLastName <- profile.lastName,
                profileEmail <- profile.email,
                profileImageURL <- profile.imageURL,
                profileCreatedAt <- profile.createdAt,
                profileUpdatedAt <- profile.updatedAt
            )
            try db.run(insert)
            
            // Insert or update devices
            for device in profile.devices {
                insertDevice(device, profileId: profile.id)
            }
            
            Task { @MainActor in 
                AppLog.info("Inserted/Updated profile: \(profile.id)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to insert profile: \(error.localizedDescription)")
            }
        }
    }
    
    func insertDevice(_ device: Device, profileId: String) {
        do {
            let insert = devicesTable.insert(or: .replace,
                deviceId <- device.id,
                deviceProfileId <- profileId,
                deviceName <- device.name,
                deviceLastActive <- device.lastActive,
                deviceIsActive <- device.isActive
            )
            try db.run(insert)
            Task { @MainActor in 
                AppLog.info("Inserted/Updated device: \(device.id) for profile: \(profileId)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to insert device: \(error.localizedDescription)")
            }
        }
    }
    
    func getProfile(withID id: String) -> Profile? {
        do {
            let query = profilesTable.filter(profileId == id)
            
            guard let row = try db.pluck(query) else {
                Task { @MainActor in 
                    AppLog.debug("No profile found with ID: \(id)")
                }
                return nil
            }
            
            // Get devices for this profile
            let devices = try getDevices(forProfileID: id)
            
            return Profile(
                id: row[profileId],
                firstName: row[profileFirstName],
                lastName: row[profileLastName],
                email: row[profileEmail],
                imageURL: row[profileImageURL],
                devices: devices,
                createdAt: row[profileCreatedAt],
                updatedAt: row[profileUpdatedAt]
            )
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to get profile: \(error.localizedDescription)")
            }
            return nil
        }
    }
    
    func getDevices(forProfileID profileId: String) throws -> [Device] {
        let query = devicesTable.filter(deviceProfileId == profileId)
        var devices: [Device] = []
        
        for row in try db.prepare(query) {
            let device = Device(
                id: row[deviceId],
                name: row[deviceName],
                lastActive: row[deviceLastActive],
                isActive: row[deviceIsActive]
            )
            devices.append(device)
        }
        
        return devices
    }
    
    func getAllProfiles() -> [Profile] {
        do {
            var profiles: [Profile] = []
            
            for row in try db.prepare(profilesTable) {
                let id = row[profileId]
                let devices = try getDevices(forProfileID: id)
                
                let profile = Profile(
                    id: id,
                    firstName: row[profileFirstName],
                    lastName: row[profileLastName],
                    email: row[profileEmail],
                    imageURL: row[profileImageURL],
                    devices: devices,
                    createdAt: row[profileCreatedAt],
                    updatedAt: row[profileUpdatedAt]
                )
                profiles.append(profile)
            }
            
            return profiles
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to get all profiles: \(error.localizedDescription)")
            }
            return []
        }
    }
    
    func updateDeviceStatus(deviceId: String, isActive: Bool) {
        do {
            let device = devicesTable.filter(self.deviceId == deviceId)
            try db.run(device.update(deviceIsActive <- isActive, deviceLastActive <- Date()))
            Task { @MainActor in 
                AppLog.info("Updated device status: \(deviceId), isActive: \(isActive)")
            }
        } catch {
            Task { @MainActor in 
                AppLog.error("Failed to update device status: \(error.localizedDescription)")
            }
        }
    }
}
