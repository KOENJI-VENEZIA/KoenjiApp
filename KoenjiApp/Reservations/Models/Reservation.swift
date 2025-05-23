//
//  Reservation.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation
import SwiftUI
import OSLog
/// Represents a reservation in the system.
struct Reservation: Identifiable, Hashable, Codable {
    // Static logger instead of instance logger
    static let logger = Logger(subsystem: "com.koenjiapp", category: "Reservation")
    
    // MARK: - Public Properties
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String {
        didSet {
            updateCachedDates()
        }
    }
    
    var category: ReservationCategory
    
    var startTime: String {
        didSet {
            updateCachedDates()
        }
    }
    
    var endTime: String {
        didSet {
            updateCachedDates()
        }
    }
    var acceptance: Acceptance
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
    private var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
    
    var image: Image? {
        if let imageData, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    private(set) var colorHue: Double
    
    // A computed property to convert hue → SwiftUI Color
    var assignedColor: Color {
        Color(hue: colorHue, saturation: 0.6, brightness: 0.8)
    }
    
    var preferredLanguage: String?

    var effectiveLanguage: String {
        return preferredLanguage ?? "it"
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
            case lastEditedOn   // ← Added key
            case isMock
            case assignedEmoji
            case imageData
            case colorHue
            case preferredLanguage

        }
    
    
    // For the sake of simplicity, we will track category as an enum
    enum ReservationCategory: String, CaseIterable, Identifiable, Equatable {
        case lunch
        case dinner
        case noBookingZone
        
        var id: String { rawValue }
    }

    enum Acceptance: String, CaseIterable {
        case confirmed
        case toConfirm
        case na
    }
    
    enum ReservationStatus: String, CaseIterable {
        case noShow
        case showedUp
        case canceled
        case pending
        case late
        case toHandle
        case deleted
        case na
    }
    
    enum ReservationType: String, CaseIterable {
        case walkIn
        case inAdvance
        case waitingList
        case na
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
        lastEditedOn: Date? = nil, // ← Optional new parameter
        isMock: Bool = false,
        assignedEmoji: String = "",
        imageData: Data? = nil,
        preferredLanguage: String? = nil
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
        self.lastEditedOn = lastEditedOn ?? creationDate
        self.isMock = isMock
        self.assignedEmoji = assignedEmoji
        self.imageData = imageData
        
        self.colorHue = Reservation.stableHue(for: id)
        self.preferredLanguage = preferredLanguage

        
        // Initialize cached dates
        self.updateCachedDates()
                
        // Additional Initialization Logic
        self.determineReservationType()
        
        // Store values in local constants before logging to avoid capturing self
        let nameCopy = name
        let dateStringCopy = dateString
        let startTimeCopy = startTime
        Task { @MainActor in
            AppLog.debug("Created reservation: \(nameCopy) for \(dateStringCopy) at \(startTimeCopy)")
        }
    }
    
    var startTimeDate: Date? {
        return cachedStartTimeDate
    }
    
    var endTimeDate: Date? {
        return cachedEndTimeDate
    }
    
    var normalizedDate: Date? {
        return cachedNormalizedDate
    }
    
    var duration: String {
        TimeHelpers.availableTimeString(
            endTime: endTime, startTime: startTime) ?? "0.0"
    }
    
    private static func stableHue(for uuid: UUID) -> Double {
            let uuidString = uuid.uuidString
            var hash = 5381
            for byte in uuidString.utf8 {
                hash = ((hash << 5) &+ hash) &+ Int(byte)
            }
            // Map hash to [0.0, 1.0)
            let hue = Double(abs(hash) % 360) / 360.0
            return hue
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
            if let timestamp = try? container.decode(Double.self, forKey: .creationDate) {
                    creationDate = Date(timeIntervalSince1970: timestamp)
                } else if let dateStr = try? container.decode(String.self, forKey: .creationDate),
                          let parsedDate = ISO8601DateFormatter().date(from: dateStr) {
                    creationDate = parsedDate
                } else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .creationDate,
                        in: container,
                        debugDescription: "creationDate is neither a Double (timestamp) nor a valid ISO8601 string."
                    )
                }
                // Try to decode lastEditedOn; if missing, default to creationDate.
                if let lastEdited = try container.decodeIfPresent(Date.self, forKey: .lastEditedOn) {
                    lastEditedOn = lastEdited
                } else {
                    lastEditedOn = creationDate
                }
            // Provide a default value for `isMock` if the key is missing
            isMock = try container.decodeIfPresent(Bool.self, forKey: .isMock) ?? false
            assignedEmoji = try container.decodeIfPresent(String.self, forKey: .assignedEmoji)
            imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)

            // Provide a default value for `colorHue` if missing
            if let hue = try container.decodeIfPresent(Double.self, forKey: .colorHue) {
                colorHue = hue
            } else {
                colorHue = Reservation.stableHue(for: id) // Generate a hue based on UUID
            }

            preferredLanguage = try container.decodeIfPresent(String.self, forKey: .preferredLanguage)

        // Initialize cached dates
              self.updateCachedDates()
              
              // Additional Initialization Logic
              self.determineReservationType()
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
        try container.encode(lastEditedOn, forKey: .lastEditedOn)  // ← Encode the new property.
        try container.encode(isMock, forKey: .isMock)
        try container.encode(assignedEmoji, forKey: .assignedEmoji)
        try container.encode(imageData, forKey: .imageData)
        try container.encode(colorHue, forKey: .colorHue)
        try container.encodeIfPresent(preferredLanguage, forKey: .preferredLanguage)


    }
    
    /// Updates the cached date properties based on the current date and time strings.
       mutating private func updateCachedDates() {
           guard let date = DateHelper.parseDate(dateString) else {
               // Store the value before logging to avoid capturing mutating self
               let dateStringCopy = dateString
               Task { @MainActor in
                    AppLog.error("Failed to parse date string: \(dateStringCopy)")
               }
               return
           }
           
           guard let start = DateHelper.parseTime(startTime),
                 let end = DateHelper.parseTime(endTime) else {
               // Store the values before logging to avoid capturing mutating self
               let startTimeCopy = startTime
               let endTimeCopy = endTime
               Task { @MainActor in
                    AppLog.error("Failed to parse time strings - Start: \(startTimeCopy), End: \(endTimeCopy)")
               }
               return
           }
           
           cachedStartTimeDate = DateHelper.normalizeTime(time: DateHelper.combine(date: date, time: start))
           cachedEndTimeDate = DateHelper.normalizeTime(time: DateHelper.combine(date: date, time: end))
           cachedNormalizedDate = DateHelper.normalizedInputTime(date: date)
           
           // Store the value before logging to avoid capturing mutating self
           let nameCopy = name
           Task { @MainActor in
                AppLog.debug("Updated cached dates for reservation: \(nameCopy)")
           }
       }
       
       /// Determines the reservation type based on creation date and reservation date.
       mutating private func determineReservationType() {
           guard let reservationDate = DateHelper.parseDate(dateString),
                 let combinedStartDate = startTimeDate else {
               Task { @MainActor in
                    AppLog.warning("Unable to determine reservation type, defaulting to inAdvance")
               }
               self.reservationType = .inAdvance
               return
           }
           
           let calendar = Calendar.current
           if calendar.isDate(creationDate, inSameDayAs: reservationDate) &&
                creationDate >= combinedStartDate, self.reservationType != .waitingList {
               self.reservationType = .walkIn
               Task { @MainActor in
                    AppLog.debug("Determined reservation type: walkIn")
               }
           } else if self.reservationType != .waitingList {
               self.reservationType = .inAdvance
               Task { @MainActor in
                    AppLog.debug("Determined reservation type: inAdvance")
               }
           } else {
               self.reservationType = .waitingList
               Task { @MainActor in
                    AppLog.debug("Determined reservation type: waitingList")
                }
           }
       }
       
       /// Updates cached dates externally if needed.
       /// Call this method whenever you modify dateString, startTime, or endTime programmatically.
       mutating func externallyUpdateCachedDates() {
           updateCachedDates()
           determineReservationType()
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
            return String(localized: "pranzo")
        case .dinner:
            return String(localized: "cena")
        case .noBookingZone:
            return String(localized: "(chiusura)")
        }
    }
}

extension Reservation.Acceptance {
    var localized: String {
        switch self {
        case .confirmed:
            return String(localized: "confermata")
        case .toConfirm:
            return String(localized: "da confermare")
        case .na:
            return String(localized: "N/A")
        }
    }
}

extension Reservation.ReservationType {
    var localized: String {
        switch self {
        case .walkIn:
            return String(localized: "walk-in")
        case .inAdvance:
            return String(localized: "con anticipo")
        case .waitingList:
            return String(localized: "waiting list")
        case .na:
            return String(localized: "N/A")
        }
    }
}

extension Reservation.ReservationStatus {
    var localized: String {
        switch self {
        case .pending:
            return String(localized: "prenotato")
        case .canceled:
            return String(localized: "cancellazione")
        case .noShow:
            return String(localized: "no show")
        case .showedUp:
            return String(localized: "arrivati")
        case .late:
            return String(localized: "in ritardo")
        case .toHandle:
            return String(localized: "in sospeso")
        case .deleted:
            return String(localized: "eliminata")
        case .na:
            return String(localized: "N/A")
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
    var preferredLanguage: String?
    // Exclude the image data here
}

extension Reservation {
    // Helper to create a lightweight version of the reservation
    func toLightweight() -> LightweightReservation {
        return LightweightReservation(id: id, name: name, phone: phone, numberOfPersons: numberOfPersons, dateString: dateString, category: category, startTime: startTime, endTime: endTime, acceptance: acceptance, status: status, reservationType: reservationType, group: group, tables: tables, creationDate: creationDate, preferredLanguage: preferredLanguage)
    }
}

extension Reservation.ReservationCategory {
    var sidebarColor: Color {
        switch self {
        case .lunch: return Color.sidebar_lunch
        case .dinner: return Color.sidebar_dinner
        case .noBookingZone: return Color.sidebar_generic
        }
    }
}

extension Reservation.ReservationCategory {
    var inspectorColor: Color {
        switch self {
        case .lunch: return Color.inspector_lunch
        case .dinner: return Color.inspector_dinner
        case .noBookingZone: return Color.inspector_generic
        }
    }
}
