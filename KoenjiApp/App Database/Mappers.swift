//
//  ReservationMapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//


import SQLite
import Foundation
import OSLog
import UIKit

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
    
    
    /// Handles a session update from Firebase
    ///
    /// This method processes a session update from Firebase and updates the local database.
    ///
    /// - Parameters:
    ///   - id: The ID of the session
    ///   - data: The session data from Firebase
    static func handleSessionUpdate(id: String, data: [String: Any]) async {
        // Extract session data
        guard let uuid = data["uuid"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            logger.error("Invalid session data for ID: \(id)")
            return
        }
        
        let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
        let deviceName = data["deviceName"] as? String ?? "Unknown Device"
        let profileImageURL = data["profileImageURL"] as? String
        
        // Create the session
        let session = Session(
            id: id,
            uuid: uuid,
            userName: userName,
            isEditing: isEditing,
            lastUpdate: lastUpdate,
            isActive: isActive,
            deviceName: deviceName,
            profileImageURL: profileImageURL
        )
        
        // Update the local database
        SQLiteManager.shared.insertSession(session)
        
        // Update the session store - already on main actor
        // Check if the session already exists in the store
        if let index = SessionStore.shared.sessions.firstIndex(where: { $0.id == id && $0.uuid == uuid }) {
            // Update the existing session
            SessionStore.shared.sessions[index] = session
        } else {
            // Add the new session
            SessionStore.shared.sessions.append(session)
            SessionStore.shared.sessions = Array(Set(SessionStore.shared.sessions))
        }
        
        // Check if we need to manage devices for this profile
        if let profile = SQLiteManager.shared.getProfile(withID: id) {
            // Log warning if there are too many devices
            if profile.devices.count > 5 {
                logger.warning("Profile \(id) has \(profile.devices.count) devices, which is more than recommended.")
            }
        }
        
        // Check if we need to create a profile for this session
        // No profile exists, create one from the session
        if SQLiteManager.shared.getProfile(withID: id) == nil {
            let emailToUse = "user@example.com" // Default email
            
            // Extract first name and last name from userName
            let components = userName.components(separatedBy: " ")
            let firstName = components.first ?? ""
            let lastName = components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
            
            // Create a device for this session
            let device = Device(
                id: uuid,
                name: deviceName,
                lastActive: lastUpdate,
                isActive: isActive
            )
            
            // Create the profile
            let profile = Profile(
                id: id,
                firstName: firstName,
                lastName: lastName,
                email: emailToUse,
                imageURL: nil,
                devices: [device],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save the profile
            SQLiteManager.shared.insertProfile(profile)
            
            // Update the profile store - already on main actor
            ProfileStore.shared.updateProfile(profile)
            
            // If this is the current user's profile, update the current profile
            let userIdentifier = UserDefaults.standard.string(forKey: "userIdentifier") ?? ""
            if profile.id == userIdentifier {
                ProfileStore.shared.setCurrentProfile(profile)
            }
            
            logger.info("Created profile from session: \(id)")
        } else {
            // Profile exists, update the device
            if let profile = SQLiteManager.shared.getProfile(withID: id) {
                var updatedProfile = profile
                
                // Check if this device is already in the profile
                if let index = profile.devices.firstIndex(where: { $0.id == uuid }) {
                    // Update the existing device
                    updatedProfile.devices[index].lastActive = lastUpdate
                    updatedProfile.devices[index].isActive = isActive
                    
                    // Update the device name if it's unknown or different
                    if updatedProfile.devices[index].name == "Unknown Device" ||
                       (deviceName != "Unknown Device" && updatedProfile.devices[index].name != deviceName) {
                        updatedProfile.devices[index].name = deviceName
                    }
                } else {
                    // Add this device to the profile
                    let device = Device(
                        id: uuid,
                        name: deviceName,
                        lastActive: lastUpdate,
                        isActive: isActive
                    )
                    updatedProfile.devices.append(device)
                }
                
                updatedProfile.updatedAt = Date()
                
                // Save the updated profile
                SQLiteManager.shared.insertProfile(updatedProfile)
                
                // Update the profile store - already on main actor
                ProfileStore.shared.updateProfile(updatedProfile)
                
                // If this is the current user's profile, update the current profile
                let userIdentifier = UserDefaults.standard.string(forKey: "userIdentifier") ?? ""
                if updatedProfile.id == userIdentifier {
                    ProfileStore.shared.setCurrentProfile(updatedProfile)
                }
                
                logger.info("Updated profile device from session: \(id)")
            }
        }
        
        logger.info("Session updated: \(id)")
    }
    
    /// Handles a profile update from Firebase
    ///
    /// This method processes a profile update from Firebase and updates the local database.
    ///
    /// - Parameters:
    ///   - id: The ID of the profile
    ///   - data: The profile data from Firebase
    static func handleProfileUpdate(id: String, data: [String: Any]) async {
        // Extract profile data
        guard let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval,
              let updatedAtTimestamp = data["updatedAt"] as? TimeInterval else {
            logger.error("Invalid profile data for ID: \(id)")
            return
        }
        
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        let updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)
        let imageURL = data["imageURL"] as? String
        
        // Extract devices
        var devices: [Device] = []
        if let devicesData = data["devices"] as? [[String: Any]] {
            for deviceData in devicesData {
                if let deviceId = deviceData["id"] as? String,
                   let deviceName = deviceData["name"] as? String,
                   let lastActiveTimestamp = deviceData["lastActive"] as? TimeInterval,
                   let isActive = deviceData["isActive"] as? Bool {
                    
                    let device = Device(
                        id: deviceId,
                        name: deviceName,
                        lastActive: Date(timeIntervalSince1970: lastActiveTimestamp),
                        isActive: isActive
                    )
                    devices.append(device)
                }
            }
        }
        
        // Create the profile
        let profile = Profile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            imageURL: imageURL,
            devices: devices,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Update the local database
        SQLiteManager.shared.insertProfile(profile)
        
        // Update the profile store - already on main actor
        ProfileStore.shared.updateProfile(profile)
        
        // If this is the current user's profile, update the current profile
        let userIdentifier = UserDefaults.standard.string(forKey: "userIdentifier") ?? ""
        if profile.id == userIdentifier {
            ProfileStore.shared.setCurrentProfile(profile)
            
            // Check if the current device has been deactivated remotely
            // Get the current scene phase
            let scenePhase = UIApplication.shared.applicationState
            
            // Only check device activation status if the app is active
            // This prevents false logout when returning from background
            if scenePhase == .active {
                // Add a small delay to allow session updates to complete
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                if SessionManager.shared.checkDeviceActivationStatus() {
                    // Post a notification to trigger logout in the app
                    NotificationCenter.default.post(name: NSNotification.Name("RemoteLogoutRequested"), object: nil)
                }
            }
        }
        
        logger.info("Profile updated: \(id)")
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
