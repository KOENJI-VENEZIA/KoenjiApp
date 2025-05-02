//
//  FirestoreMappers.swift
//  KoenjiApp
//
//  Auto-generated during concurrency refactor – 27 Apr 2025.
//  Updated for multi-entity support – Current Date
//

import Foundation
import FirebaseFirestore

// MARK: - Generic Mapper Protocol

/// Protocol defining requirements for Firebase document mapping
public protocol FirestoreMapper {
    associatedtype Entity
    static func decode(from document: DocumentSnapshot) throws -> Entity
    static func encode(_ entity: Entity) -> [String: Any]
}

// MARK: - Reservation Mapper

/// Reservation-specific implementation of FirestoreMapper
public enum ReservationMapper: FirestoreMapper {
    public typealias Entity = Reservation
    
    /// Decode a Firestore `DocumentSnapshot` into a `Reservation`.
    /// Throws if mandatory fields are missing or invalid.
    public static func decode(from document: DocumentSnapshot) throws -> Reservation {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }

        do {
            // Mandatory scalar fields - using nil coalescing for more resilience
            let idString = data["id"] as? String ?? document.documentID
            let id = UUID(uuidString: idString) ?? UUID()
            let name = data["name"] as? String ?? "Unknown Name"
            let phone = data["phone"] as? String ?? "No Phone"
            let pax = data["numberOfPersons"] as? Int ?? 2
            let dateString = data["dateString"] as? String ?? DateHelper.formatDate(Date())
            let catRaw = data["category"] as? String ?? "dinner"
            let category = Reservation.ReservationCategory(rawValue: catRaw) ?? .dinner
            let startTime = data["startTime"] as? String ?? "19:00"
            let endTime = data["endTime"] as? String ?? "21:00"
            let accRaw = data["acceptance"] as? String ?? "confirmed"
            let acceptance = Reservation.Acceptance(rawValue: accRaw) ?? .confirmed
            let statusRaw = data["status"] as? String ?? "pending"
            let status = Reservation.ReservationStatus(rawValue: statusRaw) ?? .pending
            let typeRaw = data["reservationType"] as? String ?? "inAdvance"
            let resType = Reservation.ReservationType(rawValue: typeRaw) ?? .inAdvance
            let group = data["group"] as? Bool ?? false
            let isMock = data["isMock"] as? Bool ?? false
            
            // Handle dates - support both TimeInterval and Timestamp
            let creationDate: Date
            if let creationTS = data["creationDate"] as? TimeInterval {
                creationDate = Date(timeIntervalSince1970: creationTS)
            } else if let timestamp = data["creationDate"] as? Timestamp {
                creationDate = timestamp.dateValue()
            } else {
                creationDate = Date() // Default to current date if missing
            }
            
            let lastEditedOn: Date
            if let editedTS = data["lastEditedOn"] as? TimeInterval {
                lastEditedOn = Date(timeIntervalSince1970: editedTS)
            } else if let timestamp = data["lastEditedOn"] as? Timestamp {
                lastEditedOn = timestamp.dateValue()
            } else {
                // Fallback to creationDate if lastEditedOn is missing
                lastEditedOn = creationDate
            }

            // Tables
            var tables: [TableModel] = []
            if let tablesData = data["tables"] as? [[String: Any]] {
                for t in tablesData {
                    if let id = t["id"] as? Int,
                       let name = t["name"] as? String,
                       let cap = t["maxCapacity"] as? Int {
                        tables.append(TableModel(id: id, name: name,
                                                maxCapacity: cap, row: 0, column: 0))
                    }
                }
            } else if let ids = data["tableIds"] as? [Int] {
                tables = ids.map { id in
                    TableModel(id: id, name: "Table \(id)",
                              maxCapacity: 4, row: 0, column: 0)
                }
            }

            // Optionals
            let notes = data["notes"] as? String
            let assigned = data["assignedEmoji"] as? String
            let imageData = data["imageData"] as? Data
            let language = data["preferredLanguage"] as? String
            
            // Log a warning about legacy data requiring default values
            if idString == document.documentID || phone == "No Phone" {
                Task { @MainActor in
                    AppLog.warning("Using default values for legacy reservation: \(name)")
                }
            }

            return Reservation(
                id: id,
                name: name,
                phone: phone,
                numberOfPersons: pax,
                dateString: dateString,
                category: category,
                startTime: startTime,
                endTime: endTime,
                acceptance: acceptance,
                status: status,
                reservationType: resType,
                group: group,
                notes: notes,
                tables: tables,
                creationDate: creationDate,
                lastEditedOn: lastEditedOn,
                isMock: isMock,
                assignedEmoji: assigned ?? "",
                imageData: imageData,
                preferredLanguage: language
            )
        }
    }

    /// Encode a `Reservation` value for Firestore.
    public static func encode(_ reservation: Reservation) -> [String: Any] {
        let tableIds = reservation.tables.map(\.id)

        var dict: [String: Any] = [
            "id": reservation.id.uuidString,
            "name": reservation.name,
            "phone": reservation.phone,
            "numberOfPersons": reservation.numberOfPersons,
            "dateString": reservation.dateString,
            "category": reservation.category.rawValue,
            "startTime": reservation.startTime,
            "endTime": reservation.endTime,
            "acceptance": reservation.acceptance.rawValue,
            "status": reservation.status.rawValue,
            "reservationType": reservation.reservationType.rawValue,
            "group": reservation.group,
            "tableIds": tableIds,
            "tables": reservation.tables.map { ["id": $0.id,
                                                "name": $0.name,
                                                "maxCapacity": $0.maxCapacity] },
            "creationDate": reservation.creationDate.timeIntervalSince1970,
            "lastEditedOn": reservation.lastEditedOn.timeIntervalSince1970,
            "isMock": reservation.isMock,
            "colorHue": reservation.colorHue,
            "preferredLanguage": reservation.preferredLanguage ?? "it"
        ]

        dict["notes"] = reservation.notes ?? NSNull()
        dict["assignedEmoji"] = reservation.assignedEmoji ?? NSNull()
        dict["imageData"] = reservation.imageData ?? NSNull()
        return dict
    }
}

// MARK: - Session Mapper

/// Session-specific implementation of FirestoreMapper
public enum SessionMapper: FirestoreMapper {
    public typealias Entity = Session
    
    public static func decode(from document: DocumentSnapshot) throws -> Session {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        guard
            let id        = data["id"]        as? String,
            let userName  = data["userName"]  as? String,
            let isEditing = data["isEditing"] as? Bool,
            let lastTS    = data["lastUpdate"] as? TimeInterval,
            let isActive  = data["isActive"]  as? Bool
        else {
            throw NSError(domain: "com.koenjiapp", code: 11,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        let uuid  = data["uuid"]        as? String ?? document.documentID
        let dev   = data["deviceName"]  as? String
        let image = data["profileImageURL"] as? String

        return Session(id: id, uuid: uuid, userName: userName,
                       isEditing: isEditing,
                       lastUpdate: Date(timeIntervalSince1970: lastTS),
                       isActive: isActive,
                       deviceName: dev,
                       profileImageURL: image)
    }
    
    public static func encode(_ session: Session) -> [String: Any] {
        var data: [String: Any] = [
            "id": session.id,
            "uuid": session.uuid,
            "userName": session.userName,
            "isEditing": session.isEditing,
            "lastUpdate": session.lastUpdate.timeIntervalSince1970,
            "isActive": session.isActive
        ]
        
        // Add optional fields
        if let deviceName = session.deviceName {
            data["deviceName"] = deviceName
        }
        
        if let profileImageURL = session.profileImageURL {
            data["profileImageURL"] = profileImageURL
        }
        
        return data
    }
}

// MARK: - Profile Mapper

/// Profile-specific implementation of FirestoreMapper
public enum ProfileMapper: FirestoreMapper {
    public typealias Entity = Profile
    
    public static func decode(from document: DocumentSnapshot) throws -> Profile {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 20,
                          userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
        guard
            let id = data["id"] as? String,
            let firstName = data["firstName"] as? String,
            let lastName = data["lastName"] as? String,
            let email = data["email"] as? String,
            let createdTS = data["createdAt"] as? TimeInterval,
            let updatedTS = data["updatedAt"] as? TimeInterval
        else {
            throw NSError(domain: "com.koenjiapp", code: 21,
                          userInfo: [NSLocalizedDescriptionKey: "Missing required profile fields"])
        }
        
        // Parse devices
        var devices: [Device] = []
        if let devicesData = data["devices"] as? [[String: Any]] {
            for deviceData in devicesData {
                if let deviceId = deviceData["id"] as? String,
                   let deviceName = deviceData["name"] as? String,
                   let lastActiveTS = deviceData["lastActive"] as? TimeInterval,
                   let isActive = deviceData["isActive"] as? Bool {
                    
                    let device = Device(
                        id: deviceId,
                        name: deviceName,
                        lastActive: Date(timeIntervalSince1970: lastActiveTS),
                        isActive: isActive
                    )
                    devices.append(device)
                }
            }
        }
        
        let imageURL = data["imageURL"] as? String
        
        return Profile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            imageURL: imageURL,
            devices: devices,
            createdAt: Date(timeIntervalSince1970: createdTS),
            updatedAt: Date(timeIntervalSince1970: updatedTS)
        )
    }
    
    public static func encode(_ profile: Profile) -> [String: Any] {
        var deviceData: [[String: Any]] = []
        
        for device in profile.devices {
            let deviceDict: [String: Any] = [
                "id": device.id,
                "name": device.name,
                "lastActive": device.lastActive.timeIntervalSince1970,
                "isActive": device.isActive
            ]
            deviceData.append(deviceDict)
        }
        
        var data: [String: Any] = [
            "id": profile.id,
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "email": profile.email,
            "devices": deviceData,
            "createdAt": profile.createdAt.timeIntervalSince1970,
            "updatedAt": profile.updatedAt.timeIntervalSince1970
        ]
        
        if let imageURL = profile.imageURL {
            data["imageURL"] = imageURL
        }
        
        return data
    }
}

// MARK: - Compatibility Functions

/// Legacy function for backward compatibility
public func reservation(from document: DocumentSnapshot) throws -> Reservation {
    return try ReservationMapper.decode(from: document)
}

/// Legacy function for backward compatibility
public func dictionary(from reservation: Reservation) -> [String: Any] {
    return ReservationMapper.encode(reservation)
}

/// Legacy function for backward compatibility
public func session(from document: DocumentSnapshot) throws -> Session {
    return try SessionMapper.decode(from: document)
}

// MARK: - EncodableWithID Extensions

extension Session: EncodableWithID {
    public var documentID: String {
        return uuid
    }
}

extension Profile: EncodableWithID {
    public var documentID: String {
        return id
    }
}