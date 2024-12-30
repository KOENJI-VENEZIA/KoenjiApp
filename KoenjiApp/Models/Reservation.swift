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
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var isMock: Bool = false // Distinguish mock data

    /// A convenience accessor for converting `dateString` into a Foundation.Date.
    /// (You will want better date/time conversion in a real app!)
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current

        return formatter.date(from: dateString)
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

    init(
        id: UUID = UUID(),
        name: String,
        phone: String,
        numberOfPersons: Int,
        dateString: String,
        category: ReservationCategory,
        startTime: String,
        endTime: String = "",
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
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(tables, forKey: .tables)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(isMock, forKey: .isMock)
    }
}

extension Reservation {
    /// Checks if this reservation is active at `queryTime` (between startTime and endTime).
    /// Also checks if the date matches and category matches the provided 'currentCategory' (if needed).
    func isActive(queryDate: Date, queryTime: Date) -> Bool {
        print("Debug: Checking if reservation \(id) is active")

        let calendar = Calendar.current

        // Extract and compare only the date components (year, month, day)
        guard let reservationDate = self.date else {
            print("Debug: Invalid reservation date format for \(dateString)")
            return false
        }

        let queryDateComponents = calendar.dateComponents([.year, .month, .day], from: queryDate)
        let reservationDateComponents = calendar.dateComponents([.year, .month, .day], from: reservationDate)

        if queryDateComponents != reservationDateComponents {
            print("Debug: Date mismatch. Reservation date: \(reservationDateComponents), Query date: \(queryDateComponents)")
            return false
        }

        // Parse reservation start and end times
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard
            let startTime = formatter.date(from: self.startTime),
            let endTime = formatter.date(from: self.endTime)
        else {
            print("Debug: Invalid start or end time. Start time: \(self.startTime), End time: \(self.endTime)")
            return false
        }

        // Use a fixed base date for all time comparisons
        let baseDate = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1))! // Fixed base date

        guard
            let normalizedStartTime = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                                    minute: calendar.component(.minute, from: startTime),
                                                    second: 0,
                                                    of: baseDate),
            let normalizedEndTime = calendar.date(bySettingHour: calendar.component(.hour, from: endTime),
                                                  minute: calendar.component(.minute, from: endTime),
                                                  second: 0,
                                                  of: baseDate),
            let normalizedQueryTime = calendar.date(bySettingHour: calendar.component(.hour, from: queryTime),
                                                    minute: calendar.component(.minute, from: queryTime),
                                                    second: 0,
                                                    of: baseDate)
        else {
            print("Debug: Failed to normalize time components.")
            return false
        }

        // Compare times
        let isActive = normalizedQueryTime >= normalizedStartTime && normalizedQueryTime <= normalizedEndTime
        print("Debug: Time comparison. Start time: \(normalizedStartTime), End time: \(normalizedEndTime), Query time: \(normalizedQueryTime), Is active: \(isActive)")
        return isActive
    }
}

extension Reservation.ReservationCategory: Codable {}
