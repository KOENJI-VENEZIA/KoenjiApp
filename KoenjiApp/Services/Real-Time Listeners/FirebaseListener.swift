//
//  FirebaseListener.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//
import Foundation

extension ReservationService {
    @MainActor
    func startReservationsListener() {
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        reservationListener = dbRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error listening for reservations: \(error)")
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
                print("Listener updated reservations. Count: \(reservationsByID.values.count)")
            }
        }
    }
    
    /// Converts a dictionary (from Firestore) into a Reservation.
    private func convertDictionaryToReservation(data: [String: Any]) -> Reservation? {
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
                let creationTimestamp = data["creationDate"] as? TimeInterval,
                let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval,
                let isMock = data["isMock"] as? Bool
        else {
                return nil
            }
            
            // Convert tables: Firestore stores it as an array of dictionaries.
            var tables: [TableModel] = []
            if let tablesArray = data["tables"] as? [[String: Any]] {
                let decoder = JSONDecoder()
                // One way is to convert the dictionary to Data then decode it.
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
                notes: data["notes"] as? String,
                tables: tables,
                creationDate: Date(timeIntervalSince1970: creationTimestamp),
                lastEditedOn: Date(timeIntervalSince1970: lastEditedTimestamp),
                isMock: isMock,
                assignedEmoji: data["assignedEmoji"] as? String ?? "",
                imageData: data["imageData"] as? Data
            )
        }
}

extension ReservationService {
    @MainActor
    func startSessionListener() {
    #if DEBUG
    let dbRef = backupService.db.collection("sessions")
    #else
    let dbRef = backupService.db.collection("sessions_release")
    #endif
        sessionListener = dbRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error listening for sessions: \(error)")
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
                print("Listener updated sessions. Count: \(sessionsById.values.count)")
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
}
