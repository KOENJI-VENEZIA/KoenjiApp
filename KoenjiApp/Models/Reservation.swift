//
//  Reservation.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation

/// Represents a reservation in the system.
struct Reservation: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "DD/MM/YYYY"
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

    /// A convenience accessor for converting `dateString` into a Foundation.Date.
    /// (You will want better date/time conversion in a real app!)
    var date: Date? {
        return DateHelper.parseDate(dateString)
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
    }
    
    enum ReservationType: String, CaseIterable {
        case walkIn
        case inAdvance
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
        isMock: Bool = false
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
    }
}

extension Reservation {
    /// Checks if the reservation is active at the given date and time.
    func isActive(on date: Date, at time: Date) -> Bool {
        guard let reservationDate = self.date,
              reservationDate.isSameDay(as: date),
              let start = self.startDate,
              let end = self.endDate else {
            return false
        }

        return TimeHelpers.timeRangesOverlap(start1: start, end1: end, start2: time, end2: time)
    }
}

extension Reservation {
    /// Combines `dateString` and `startTime` to generate a `Date` object for the reservation's start.
    var startDate: Date? {
        guard let reservationDate = date,
                let startTimeDate = DateHelper.parseTime(startTime) else {
              return nil
          }

          let calendar = Calendar.current
          let timeComponents = calendar.dateComponents([.hour, .minute], from: startTimeDate)

          return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                               minute: timeComponents.minute ?? 0,
                               second: 0,
                               of: reservationDate)
      }

      /// Parse and normalize the end date-time of the reservation.
      var endDate: Date? {
          guard let reservationDate = date,
                let endTimeDate = DateHelper.parseTime(endTime) else {
              return nil
          }

          let calendar = Calendar.current
          let timeComponents = calendar.dateComponents([.hour, .minute], from: endTimeDate)

          return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                               minute: timeComponents.minute ?? 0,
                               second: 0,
                               of: reservationDate)
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
