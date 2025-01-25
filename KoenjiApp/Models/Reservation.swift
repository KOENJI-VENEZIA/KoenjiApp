//
//  Reservation.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation
import SwiftUI

/// Represents a reservation in the system.
struct Reservation: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Acceptance
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    var cachedStartTimeDate: Date?
    var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
    
    var image: Image? {
        if let imageData, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    

    

    
    enum CodingKeys: String, CodingKey {
            case id
            case name
            case phone
            case numberOfPersons
            case dateString
            case category
            case startTime
            case endTime
            case acceptance
            case status
            case reservationType
            case group
            case notes
            case tables
            case creationDate
            case isMock
            case assignedEmoji
            case imageData
        }
    
    
    // For the sake of simplicity, we will track category as an enum
    enum ReservationCategory: String, CaseIterable {
        case lunch
        case dinner
        case noBookingZone
    }

    enum Acceptance: String, CaseIterable {
        case confirmed
        case toConfirm
    }
    
    enum ReservationStatus: String, CaseIterable {
        case noShow
        case showedUp
        case canceled
        case pending
        case late
        case na
    }
    
    enum ReservationType: String, CaseIterable {
        case walkIn
        case inAdvance
        case waitingList
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        phone: String,
        numberOfPersons: Int,
        dateString: String,
        category: ReservationCategory,
        startTime: String,
        endTime: String = "",
        acceptance: Acceptance,
        status: ReservationStatus,
        reservationType: ReservationType,
        group: Bool = false,
        notes: String? = nil,
        tables: [TableModel] = [],
        creationDate: Date = Date(),
        isMock: Bool = false,
        assignedEmoji: String = "",
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.numberOfPersons = numberOfPersons
        self.dateString = dateString
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.acceptance = acceptance
        self.status = status
        self.reservationType = reservationType
        self.group = group
        self.notes = notes
        self.tables = tables
        self.creationDate = creationDate
        self.isMock = isMock
        self.assignedEmoji = assignedEmoji
        self.imageData = imageData
        

        
        self.cachedStartTimeDate = DateHelper.normalizeTime(time: DateHelper.combine(
            date: DateHelper.parseDate(dateString) ?? Date(),
            time: DateHelper.parseTime(startTime) ?? Date()
        ))
        self.cachedEndTimeDate = DateHelper.normalizeTime(time: DateHelper.combine(
            date: DateHelper.parseDate(dateString) ?? Date(),
            time: DateHelper.parseTime(endTime) ?? Date()
        ))
        let date = DateHelper.parseDate(dateString) ?? Date()
        self.cachedNormalizedDate = DateHelper.normalizedInputTime(date: date)
        
        
               // Using DateHelper to combine date and time strings
        let reservationDate = date
        if let combinedStartDate = startTimeDate {
                       
           let calendar = Calendar.current
           // If the creation date is the same day as the reservation's date
           // and the creation time is at or after the start time, mark as walkIn.
           if calendar.isDate(creationDate, inSameDayAs: reservationDate) &&
               creationDate >= combinedStartDate {
               self.reservationType = .walkIn
           } else {
               self.reservationType = .inAdvance
           }
       } else {
           // Fallback if date parsing fails.
           self.reservationType = .inAdvance
       }
    }
    
    var startTimeDate: Date? {
        cachedStartTimeDate
    }

    var endTimeDate: Date? {
        cachedEndTimeDate
    }
    
    var normalizedDate: Date? {
        cachedNormalizedDate
    }
}

// Add the custom decoding logic here
extension Reservation {
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Decode required properties
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            phone = try container.decode(String.self, forKey: .phone)
            numberOfPersons = try container.decode(Int.self, forKey: .numberOfPersons)
            dateString = try container.decode(String.self, forKey: .dateString)
            category = try container.decode(ReservationCategory.self, forKey: .category)
            startTime = try container.decode(String.self, forKey: .startTime)
            endTime = try container.decode(String.self, forKey: .endTime)
            acceptance = try container.decode(Acceptance.self, forKey: .acceptance)
            status = try container.decode(ReservationStatus.self, forKey: .status)
            reservationType = try container.decode(ReservationType.self, forKey: .reservationType)
            group = try container.decode(Bool.self, forKey: .group)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            tables = try container.decode([TableModel].self, forKey: .tables)
            creationDate = try container.decode(Date.self, forKey: .creationDate)

            // Provide a default value for `isMock` if the key is missing
            isMock = try container.decodeIfPresent(Bool.self, forKey: .isMock) ?? false
            assignedEmoji = try container.decodeIfPresent(String.self, forKey: .assignedEmoji)
            imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)

            // **Compute Cached Dates After Decoding**
        self.cachedStartTimeDate = DateHelper.normalizeTime(time: DateHelper.combine(
                date: DateHelper.parseDate(dateString) ?? Date(),
                time: DateHelper.parseTime(startTime) ?? Date()
            ))
        self.cachedEndTimeDate = DateHelper.normalizeTime(time: DateHelper.combine(
                date: DateHelper.parseDate(dateString) ?? Date(),
                time: DateHelper.parseTime(endTime) ?? Date()
            ))
        
            let date = DateHelper.parseDate(dateString) ?? Date()
            self.cachedNormalizedDate = DateHelper.normalizedInputTime(date: date)

            // **Additional Initialization Logic (if any)**
            let reservationDate = date
            if let combinedStartDate = startTimeDate {
                let calendar = Calendar.current
                if calendar.isDate(creationDate, inSameDayAs: reservationDate) &&
                    creationDate >= combinedStartDate {
                    self.reservationType = .walkIn
                } else {
                    self.reservationType = .inAdvance
                }
            } else {
                // Fallback if date parsing fails.
                self.reservationType = .inAdvance
            }
        }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode all properties
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(phone, forKey: .phone)
        try container.encode(numberOfPersons, forKey: .numberOfPersons)
        try container.encode(dateString, forKey: .dateString)
        try container.encode(category, forKey: .category)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(acceptance, forKey: .acceptance)
        try container.encode(status, forKey: .status)
        try container.encode(reservationType, forKey: .reservationType)
        try container.encode(group, forKey: .group)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(tables, forKey: .tables)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(isMock, forKey: .isMock)
        try container.encode(assignedEmoji, forKey: .assignedEmoji)
        try container.encode(imageData, forKey: .imageData)
    }
}





extension Reservation.ReservationCategory: Codable {}
extension Reservation.Acceptance: Codable {}
extension Reservation.ReservationStatus: Codable {}
extension Reservation.ReservationType: Codable {}

extension Reservation {
    static var empty: Reservation {
        return Reservation(
            name: "",
            phone: "",
            numberOfPersons: 0,
            dateString: "",
            category: .noBookingZone,
            startTime: "",
            endTime: "",
            acceptance: .toConfirm,
            status: .pending,
            reservationType: .walkIn,
            group: false,
            notes: nil,
            tables: [],
            creationDate: Date(),
            isMock: true // Mark it as mock or empty data
        )
    }
}

extension Reservation.ReservationCategory {
    var localized: String {
        switch self {
        case .lunch:
            return "pranzo"
        case .dinner:
            return "cena"
        case .noBookingZone:
            return "(chiusura)"
        }
    }
}

extension Reservation.Acceptance {
    var localized: String {
        switch self {
        case .confirmed:
            return "confermata"
        case .toConfirm:
            return "da confermare"
        }
    }
}

extension Reservation.ReservationType {
    var localized: String {
        switch self {
        case .walkIn:
            return "walk-in"
        case .inAdvance:
            return "con anticipo"
        case .waitingList:
            return "waiting list"
        }
    }
}

extension Reservation.ReservationStatus {
    var localized: String {
        switch self {
            case .pending:
            return "prenotato"
        case .canceled:
            return "cancellazione"
        case .noShow:
            return "no show"
        case .showedUp:
            return "arrivati"
        case .late:
            return "in ritardo"
        case .na:
            return "N/A"
        }
    }
}

struct LightweightReservation: Codable {
    var id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var assignedEmoji: String?
    
    // Exclude the image data here
}

extension Reservation {
    // Helper to create a lightweight version of the reservation
    func toLightweight() -> LightweightReservation {
        return LightweightReservation(id: id, name: name, phone: phone, numberOfPersons: numberOfPersons, dateString: dateString, category: category, startTime: startTime, endTime: endTime, acceptance: acceptance, status: status, reservationType: reservationType, group: group, tables: tables, creationDate: creationDate)
    }
}
