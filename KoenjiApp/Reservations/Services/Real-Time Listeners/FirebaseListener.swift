//
//  FirebaseListener.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//

import Foundation
import OSLog
import Firebase
import FirebaseDatabase

extension ReservationService {
    
    // MARK: - Reservations Listener
    
    @MainActor
    func startReservationsListener() {
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        reservationListener = dbRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                self?.logger.error("Error listening for reservations: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            var reservationsByID: [UUID: Reservation] = [:]
            for document in snapshot.documents {
                let data = document.data()
                if let reservation = self?.convertDictionaryToReservation(data: data) {
                    reservationsByID[reservation.id] = reservation
                    // Also upsert into SQLite:
                    SQLiteManager.shared.insertReservation(reservation)
                }
            }
            // Replace the entire in-memory store with unique values:
            DispatchQueue.main.async {
                self?.store.setReservations(Array(reservationsByID.values))
                self?.logger.debug("Listener updated reservations. Count: \(reservationsByID.values.count)")
            }
        }
    }
    
    func convertDictionaryToReservation(data: [String: Any]) -> Reservation? {
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let notes = data["notes"] as? String,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval,
            let isMock = data["isMock"] as? Bool,
            let preferredLanguage = data["preferredLanguage"] as? String
        else {
            return nil
        }
        
        // Convert tables: Firestore stores them as an array of dictionaries.
        var tables: [TableModel] = []
        if let tablesArray = data["tables"] as? [[String: Any]] {
            let decoder = JSONDecoder()
            for tableDict in tablesArray {
                if let jsonData = try? JSONSerialization.data(withJSONObject: tableDict, options: []),
                   let table = try? decoder.decode(TableModel.self, from: jsonData) {
                    tables.append(table)
                }
            }
        }
        
        return Reservation(
            id: id,
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes,
            tables: tables,
            creationDate: Date(timeIntervalSince1970: creationTimestamp),
            lastEditedOn: Date(timeIntervalSince1970: lastEditedTimestamp),
            isMock: isMock,
            assignedEmoji: data["assignedEmoji"] as? String ?? "",
            imageData: data["imageData"] as? Data,
            preferredLanguage: preferredLanguage
        )
    }
    
    // MARK: - Sessions Listener
    
    @MainActor
    func startSessionListener() {
        #if DEBUG
        let dbRef = backupService.db.collection("sessions")
        #else
        let dbRef = backupService.db.collection("sessions_release")
        #endif
        sessionListener = dbRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                self?.logger.error("Error listening for sessions: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            
            var sessionsById: [String: Session] = [:]
            for document in snapshot.documents {
                let data = document.data()
                if let session = self?.convertDictionaryToSession(data: data) {
                    sessionsById[session.uuid] = session
                    // Also upsert into SQLite:
                    SQLiteManager.shared.insertSession(session)
                }
            }
            // Replace the entire in-memory store with unique values:
            DispatchQueue.main.async {
                SessionStore.shared.setSessions(Array(sessionsById.values))
                self?.logger.debug("Listener updated sessions. Count: \(sessionsById.values.count)")
            }
        }
    }
    
    private func convertDictionaryToSession(data: [String: Any]) -> Session? {
        guard
            let id = data["id"] as? String,
            let uuid = data["uuid"] as? String,
            let userName = data["userName"] as? String,
            let isEditing = data["isEditing"] as? Bool,
            let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
            let isActive = data["isActive"] as? Bool
        else { return nil }
        
        return Session(
            id: id,
            uuid: uuid,
            userName: userName,
            isEditing: isEditing,
            lastUpdate: Date(timeIntervalSince1970: lastUpdateTimestamp),
            isActive: isActive
        )
    }
    
    // MARK: - Realtime Database Presence Detection
    
    func setupRealtimeDatabasePresence(for deviceUUID: String) {
        // Get a reference to the Realtime Database
        let databaseRef = Database.database().reference()
        
        // Create a reference for the client's connection state using the .info/connected node
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        // Observe the connection state
        connectedRef.observe(.value) { snapshot in
            guard let connected = snapshot.value as? Bool, connected else {
                // Not connected, so no updates are made here.
                return
            }
            
            // Define a reference to the session node for this device
            #if DEBUG
            let sessionRef = databaseRef.child("sessions").child(deviceUUID)
            #else
            let sessionRef = databaseRef.child("sessions_release").child(deviceUUID)
            #endif

            
            // Mark the session as active when connected
            sessionRef.child("isActive").setValue(true)
            
            // Set up onDisconnect handlers to mark the session inactive and update the last active timestamp
            sessionRef.child("isActive").onDisconnectSetValue(false)
            sessionRef.child("lastActive").setValue(ServerValue.timestamp())
            sessionRef.child("lastActive").onDisconnectSetValue(ServerValue.timestamp())
        }
    }
}
