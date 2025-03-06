Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Models/Reservation.swift...
# Documentation Suggestions for Reservation.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Models/Reservation.swift
Total suggestions: 104

## Class Documentation (19)

### CodingKeys (Line 77)

**Context:**

```swift
    

    
    enum CodingKeys: String, CodingKey {
            case id
            case name
            case phone
```

**Suggested Documentation:**

```swift
/// CodingKeys class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationCategory (Line 104)

**Context:**

```swift
    
    
    // For the sake of simplicity, we will track category as an enum
    enum ReservationCategory: String, CaseIterable, Identifiable, Equatable {
        case lunch
        case dinner
        case noBookingZone
```

**Suggested Documentation:**

```swift
/// ReservationCategory class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Acceptance (Line 112)

**Context:**

```swift
        var id: String { rawValue }
    }

    enum Acceptance: String, CaseIterable {
        case confirmed
        case toConfirm
        case na
```

**Suggested Documentation:**

```swift
/// Acceptance class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationStatus (Line 118)

**Context:**

```swift
        case na
    }
    
    enum ReservationStatus: String, CaseIterable {
        case noShow
        case showedUp
        case canceled
```

**Suggested Documentation:**

```swift
/// ReservationStatus class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationType (Line 129)

**Context:**

```swift
        case na
    }
    
    enum ReservationType: String, CaseIterable {
        case walkIn
        case inAdvance
        case waitingList
```

**Suggested Documentation:**

```swift
/// ReservationType class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 225)

**Context:**

```swift
}

// Add the custom decoding logic here
extension Reservation {
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 374)

**Context:**

```swift



extension Reservation.ReservationCategory: Codable {}
extension Reservation.Acceptance: Codable {}
extension Reservation.ReservationStatus: Codable {}
extension Reservation.ReservationType: Codable {}
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 375)

**Context:**

```swift


extension Reservation.ReservationCategory: Codable {}
extension Reservation.Acceptance: Codable {}
extension Reservation.ReservationStatus: Codable {}
extension Reservation.ReservationType: Codable {}

```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 376)

**Context:**

```swift

extension Reservation.ReservationCategory: Codable {}
extension Reservation.Acceptance: Codable {}
extension Reservation.ReservationStatus: Codable {}
extension Reservation.ReservationType: Codable {}

extension Reservation {
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 377)

**Context:**

```swift
extension Reservation.ReservationCategory: Codable {}
extension Reservation.Acceptance: Codable {}
extension Reservation.ReservationStatus: Codable {}
extension Reservation.ReservationType: Codable {}

extension Reservation {
    static var empty: Reservation {
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 379)

**Context:**

```swift
extension Reservation.ReservationStatus: Codable {}
extension Reservation.ReservationType: Codable {}

extension Reservation {
    static var empty: Reservation {
        return Reservation(
            name: "",
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 401)

**Context:**

```swift
    }
}

extension Reservation.ReservationCategory {
    var localized: String {
        switch self {
        case .lunch:
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 414)

**Context:**

```swift
    }
}

extension Reservation.Acceptance {
    var localized: String {
        switch self {
        case .confirmed:
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 427)

**Context:**

```swift
    }
}

extension Reservation.ReservationType {
    var localized: String {
        switch self {
        case .walkIn:
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 442)

**Context:**

```swift
    }
}

extension Reservation.ReservationStatus {
    var localized: String {
        switch self {
        case .pending:
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### LightweightReservation (Line 465)

**Context:**

```swift
    }
}

struct LightweightReservation: Codable {
    var id: UUID
    var name: String
    var phone: String
```

**Suggested Documentation:**

```swift
/// LightweightReservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 486)

**Context:**

```swift
    // Exclude the image data here
}

extension Reservation {
    // Helper to create a lightweight version of the reservation
    func toLightweight() -> LightweightReservation {
        return LightweightReservation(id: id, name: name, phone: phone, numberOfPersons: numberOfPersons, dateString: dateString, category: category, startTime: startTime, endTime: endTime, acceptance: acceptance, status: status, reservationType: reservationType, group: group, tables: tables, creationDate: creationDate, preferredLanguage: preferredLanguage)
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 493)

**Context:**

```swift
    }
}

extension Reservation.ReservationCategory {
    var sidebarColor: Color {
        switch self {
        case .lunch: return Color.sidebar_lunch
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 503)

**Context:**

```swift
    }
}

extension Reservation.ReservationCategory {
    var inspectorColor: Color {
        switch self {
        case .lunch: return Color.inspector_lunch
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (3)

### stableHue (Line 212)

**Context:**

```swift
            endTime: endTime, startTime: startTime) ?? "0.0"
    }
    
    private static func stableHue(for uuid: UUID) -> Double {
            let uuidString = uuid.uuidString
            var hash = 5381
            for byte in uuidString.utf8 {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the stableHue method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### encode (Line 283)

**Context:**

```swift
              self.determineReservationType()
        }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode all properties
```

**Suggested Documentation:**

```swift
/// [Add a description of what the encode method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### toLightweight (Line 488)

**Context:**

```swift

extension Reservation {
    // Helper to create a lightweight version of the reservation
    func toLightweight() -> LightweightReservation {
        return LightweightReservation(id: id, name: name, phone: phone, numberOfPersons: numberOfPersons, dateString: dateString, category: category, startTime: startTime, endTime: endTime, acceptance: acceptance, status: status, reservationType: reservationType, group: group, tables: tables, creationDate: creationDate, preferredLanguage: preferredLanguage)
    }
}
```

**Suggested Documentation:**

```swift
/// [Add a description of what the toLightweight method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (82)

### logger (Line 14)

**Context:**

```swift
/// Represents a reservation in the system.
struct Reservation: Identifiable, Hashable, Codable {
    // Static logger instead of instance logger
    static let logger = Logger(subsystem: "com.koenjiapp", category: "Reservation")
    
    // MARK: - Public Properties
    let id: UUID
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### id (Line 17)

**Context:**

```swift
    static let logger = Logger(subsystem: "com.koenjiapp", category: "Reservation")
    
    // MARK: - Public Properties
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### name (Line 18)

**Context:**

```swift
    
    // MARK: - Public Properties
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String {
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### phone (Line 19)

**Context:**

```swift
    // MARK: - Public Properties
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String {
        didSet {
```

**Suggested Documentation:**

```swift
/// [Description of the phone property]
```

### numberOfPersons (Line 20)

**Context:**

```swift
    let id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String {
        didSet {
            updateCachedDates()
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### dateString (Line 21)

**Context:**

```swift
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String {
        didSet {
            updateCachedDates()
        }
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### category (Line 27)

**Context:**

```swift
        }
    }
    
    var category: ReservationCategory
    
    var startTime: String {
        didSet {
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### startTime (Line 29)

**Context:**

```swift
    
    var category: ReservationCategory
    
    var startTime: String {
        didSet {
            updateCachedDates()
        }
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 35)

**Context:**

```swift
        }
    }
    
    var endTime: String {
        didSet {
            updateCachedDates()
        }
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### acceptance (Line 40)

**Context:**

```swift
            updateCachedDates()
        }
    }
    var acceptance: Acceptance
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### status (Line 41)

**Context:**

```swift
        }
    }
    var acceptance: Acceptance
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationType (Line 42)

**Context:**

```swift
    }
    var acceptance: Acceptance
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### group (Line 43)

**Context:**

```swift
    var acceptance: Acceptance
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
```

**Suggested Documentation:**

```swift
/// [Description of the group property]
```

### notes (Line 44)

**Context:**

```swift
    var status: ReservationStatus
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### tables (Line 45)

**Context:**

```swift
    var reservationType: ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### creationDate (Line 46)

**Context:**

```swift
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
```

**Suggested Documentation:**

```swift
/// [Description of the creationDate property]
```

### lastEditedOn (Line 47)

**Context:**

```swift
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
```

**Suggested Documentation:**

```swift
/// [Description of the lastEditedOn property]
```

### isMock (Line 48)

**Context:**

```swift
    var tables: [TableModel]
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
```

**Suggested Documentation:**

```swift
/// [Description of the isMock property]
```

### assignedEmoji (Line 49)

**Context:**

```swift
    let creationDate: Date
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
    private var cachedEndTimeDate: Date?
```

**Suggested Documentation:**

```swift
/// [Description of the assignedEmoji property]
```

### imageData (Line 50)

**Context:**

```swift
    var lastEditedOn: Date      // ← New property to track when the reservation was last edited.
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
    private var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### cachedStartTimeDate (Line 51)

**Context:**

```swift
    var isMock: Bool = false // Distinguish mock data
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
    private var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
    
```

**Suggested Documentation:**

```swift
/// [Description of the cachedStartTimeDate property]
```

### cachedEndTimeDate (Line 52)

**Context:**

```swift
    var assignedEmoji: String?
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
    private var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
    
    var image: Image? {
```

**Suggested Documentation:**

```swift
/// [Description of the cachedEndTimeDate property]
```

### cachedNormalizedDate (Line 53)

**Context:**

```swift
    var imageData: Data? // Store image data for the reservation
    private var cachedStartTimeDate: Date?
    private var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
    
    var image: Image? {
        if let imageData, let uiImage = UIImage(data: imageData) {
```

**Suggested Documentation:**

```swift
/// [Description of the cachedNormalizedDate property]
```

### image (Line 55)

**Context:**

```swift
    private var cachedEndTimeDate: Date?
    var cachedNormalizedDate: Date?
    
    var image: Image? {
        if let imageData, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the image property]
```

### imageData (Line 56)

**Context:**

```swift
    var cachedNormalizedDate: Date?
    
    var image: Image? {
        if let imageData, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        return nil
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### uiImage (Line 56)

**Context:**

```swift
    var cachedNormalizedDate: Date?
    
    var image: Image? {
        if let imageData, let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        }
        return nil
```

**Suggested Documentation:**

```swift
/// [Description of the uiImage property]
```

### colorHue (Line 62)

**Context:**

```swift
        return nil
    }
    
    private(set) var colorHue: Double
    
    // A computed property to convert hue → SwiftUI Color
    var assignedColor: Color {
```

**Suggested Documentation:**

```swift
/// [Description of the colorHue property]
```

### assignedColor (Line 65)

**Context:**

```swift
    private(set) var colorHue: Double
    
    // A computed property to convert hue → SwiftUI Color
    var assignedColor: Color {
        Color(hue: colorHue, saturation: 0.6, brightness: 0.8)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the assignedColor property]
```

### preferredLanguage (Line 69)

**Context:**

```swift
        Color(hue: colorHue, saturation: 0.6, brightness: 0.8)
    }
    
    var preferredLanguage: String?

    var effectiveLanguage: String {
        return preferredLanguage ?? "it"
```

**Suggested Documentation:**

```swift
/// [Description of the preferredLanguage property]
```

### effectiveLanguage (Line 71)

**Context:**

```swift
    
    var preferredLanguage: String?

    var effectiveLanguage: String {
        return preferredLanguage ?? "it"
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the effectiveLanguage property]
```

### id (Line 109)

**Context:**

```swift
        case dinner
        case noBookingZone
        
        var id: String { rawValue }
    }

    enum Acceptance: String, CaseIterable {
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### nameCopy (Line 189)

**Context:**

```swift
        self.determineReservationType()
        
        // Store values in local constants before logging to avoid capturing self
        let nameCopy = name
        let dateStringCopy = dateString
        let startTimeCopy = startTime
        Self.logger.debug("Created reservation: \(nameCopy) for \(dateStringCopy) at \(startTimeCopy)")
```

**Suggested Documentation:**

```swift
/// [Description of the nameCopy property]
```

### dateStringCopy (Line 190)

**Context:**

```swift
        
        // Store values in local constants before logging to avoid capturing self
        let nameCopy = name
        let dateStringCopy = dateString
        let startTimeCopy = startTime
        Self.logger.debug("Created reservation: \(nameCopy) for \(dateStringCopy) at \(startTimeCopy)")
    }
```

**Suggested Documentation:**

```swift
/// [Description of the dateStringCopy property]
```

### startTimeCopy (Line 191)

**Context:**

```swift
        // Store values in local constants before logging to avoid capturing self
        let nameCopy = name
        let dateStringCopy = dateString
        let startTimeCopy = startTime
        Self.logger.debug("Created reservation: \(nameCopy) for \(dateStringCopy) at \(startTimeCopy)")
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the startTimeCopy property]
```

### startTimeDate (Line 195)

**Context:**

```swift
        Self.logger.debug("Created reservation: \(nameCopy) for \(dateStringCopy) at \(startTimeCopy)")
    }
    
    var startTimeDate: Date? {
        return cachedStartTimeDate
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the startTimeDate property]
```

### endTimeDate (Line 199)

**Context:**

```swift
        return cachedStartTimeDate
    }
    
    var endTimeDate: Date? {
        return cachedEndTimeDate
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the endTimeDate property]
```

### normalizedDate (Line 203)

**Context:**

```swift
        return cachedEndTimeDate
    }
    
    var normalizedDate: Date? {
        return cachedNormalizedDate
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### duration (Line 207)

**Context:**

```swift
        return cachedNormalizedDate
    }
    
    var duration: String {
        TimeHelpers.availableTimeString(
            endTime: endTime, startTime: startTime) ?? "0.0"
    }
```

**Suggested Documentation:**

```swift
/// [Description of the duration property]
```

### uuidString (Line 213)

**Context:**

```swift
    }
    
    private static func stableHue(for uuid: UUID) -> Double {
            let uuidString = uuid.uuidString
            var hash = 5381
            for byte in uuidString.utf8 {
                hash = ((hash << 5) &+ hash) &+ Int(byte)
```

**Suggested Documentation:**

```swift
/// [Description of the uuidString property]
```

### hash (Line 214)

**Context:**

```swift
    
    private static func stableHue(for uuid: UUID) -> Double {
            let uuidString = uuid.uuidString
            var hash = 5381
            for byte in uuidString.utf8 {
                hash = ((hash << 5) &+ hash) &+ Int(byte)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the hash property]
```

### hue (Line 219)

**Context:**

```swift
                hash = ((hash << 5) &+ hash) &+ Int(byte)
            }
            // Map hash to [0.0, 1.0)
            let hue = Double(abs(hash) % 360) / 360.0
            return hue
        }
}
```

**Suggested Documentation:**

```swift
/// [Description of the hue property]
```

### container (Line 227)

**Context:**

```swift
// Add the custom decoding logic here
extension Reservation {
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Decode required properties
            id = try container.decode(UUID.self, forKey: .id)
```

**Suggested Documentation:**

```swift
/// [Description of the container property]
```

### timestamp (Line 244)

**Context:**

```swift
            group = try container.decode(Bool.self, forKey: .group)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            tables = try container.decode([TableModel].self, forKey: .tables)
            if let timestamp = try? container.decode(Double.self, forKey: .creationDate) {
                    creationDate = Date(timeIntervalSince1970: timestamp)
                } else if let dateStr = try? container.decode(String.self, forKey: .creationDate),
                          let parsedDate = ISO8601DateFormatter().date(from: dateStr) {
```

**Suggested Documentation:**

```swift
/// [Description of the timestamp property]
```

### dateStr (Line 246)

**Context:**

```swift
            tables = try container.decode([TableModel].self, forKey: .tables)
            if let timestamp = try? container.decode(Double.self, forKey: .creationDate) {
                    creationDate = Date(timeIntervalSince1970: timestamp)
                } else if let dateStr = try? container.decode(String.self, forKey: .creationDate),
                          let parsedDate = ISO8601DateFormatter().date(from: dateStr) {
                    creationDate = parsedDate
                } else {
```

**Suggested Documentation:**

```swift
/// [Description of the dateStr property]
```

### parsedDate (Line 247)

**Context:**

```swift
            if let timestamp = try? container.decode(Double.self, forKey: .creationDate) {
                    creationDate = Date(timeIntervalSince1970: timestamp)
                } else if let dateStr = try? container.decode(String.self, forKey: .creationDate),
                          let parsedDate = ISO8601DateFormatter().date(from: dateStr) {
                    creationDate = parsedDate
                } else {
                    throw DecodingError.dataCorruptedError(
```

**Suggested Documentation:**

```swift
/// [Description of the parsedDate property]
```

### lastEdited (Line 257)

**Context:**

```swift
                    )
                }
                // Try to decode lastEditedOn; if missing, default to creationDate.
                if let lastEdited = try container.decodeIfPresent(Date.self, forKey: .lastEditedOn) {
                    lastEditedOn = lastEdited
                } else {
                    lastEditedOn = creationDate
```

**Suggested Documentation:**

```swift
/// [Description of the lastEdited property]
```

### hue (Line 268)

**Context:**

```swift
            imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)

            // Provide a default value for `colorHue` if missing
            if let hue = try container.decodeIfPresent(Double.self, forKey: .colorHue) {
                colorHue = hue
            } else {
                colorHue = Reservation.stableHue(for: id) // Generate a hue based on UUID
```

**Suggested Documentation:**

```swift
/// [Description of the hue property]
```

### container (Line 284)

**Context:**

```swift
        }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode all properties
        try container.encode(id, forKey: .id)
```

**Suggested Documentation:**

```swift
/// [Description of the container property]
```

### date (Line 314)

**Context:**

```swift
    
    /// Updates the cached date properties based on the current date and time strings.
       mutating private func updateCachedDates() {
           guard let date = DateHelper.parseDate(dateString) else {
               // Store the value before logging to avoid capturing mutating self
               let dateStringCopy = dateString
               Self.logger.error("Failed to parse date string: \(dateStringCopy)")
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### dateStringCopy (Line 316)

**Context:**

```swift
       mutating private func updateCachedDates() {
           guard let date = DateHelper.parseDate(dateString) else {
               // Store the value before logging to avoid capturing mutating self
               let dateStringCopy = dateString
               Self.logger.error("Failed to parse date string: \(dateStringCopy)")
               return
           }
```

**Suggested Documentation:**

```swift
/// [Description of the dateStringCopy property]
```

### start (Line 321)

**Context:**

```swift
               return
           }
           
           guard let start = DateHelper.parseTime(startTime),
                 let end = DateHelper.parseTime(endTime) else {
               // Store the values before logging to avoid capturing mutating self
               let startTimeCopy = startTime
```

**Suggested Documentation:**

```swift
/// [Description of the start property]
```

### end (Line 322)

**Context:**

```swift
           }
           
           guard let start = DateHelper.parseTime(startTime),
                 let end = DateHelper.parseTime(endTime) else {
               // Store the values before logging to avoid capturing mutating self
               let startTimeCopy = startTime
               let endTimeCopy = endTime
```

**Suggested Documentation:**

```swift
/// [Description of the end property]
```

### startTimeCopy (Line 324)

**Context:**

```swift
           guard let start = DateHelper.parseTime(startTime),
                 let end = DateHelper.parseTime(endTime) else {
               // Store the values before logging to avoid capturing mutating self
               let startTimeCopy = startTime
               let endTimeCopy = endTime
               Self.logger.error("Failed to parse time strings - Start: \(startTimeCopy), End: \(endTimeCopy)")
               return
```

**Suggested Documentation:**

```swift
/// [Description of the startTimeCopy property]
```

### endTimeCopy (Line 325)

**Context:**

```swift
                 let end = DateHelper.parseTime(endTime) else {
               // Store the values before logging to avoid capturing mutating self
               let startTimeCopy = startTime
               let endTimeCopy = endTime
               Self.logger.error("Failed to parse time strings - Start: \(startTimeCopy), End: \(endTimeCopy)")
               return
           }
```

**Suggested Documentation:**

```swift
/// [Description of the endTimeCopy property]
```

### nameCopy (Line 335)

**Context:**

```swift
           cachedNormalizedDate = DateHelper.normalizedInputTime(date: date)
           
           // Store the value before logging to avoid capturing mutating self
           let nameCopy = name
           Self.logger.debug("Updated cached dates for reservation: \(nameCopy)")
       }
       
```

**Suggested Documentation:**

```swift
/// [Description of the nameCopy property]
```

### reservationDate (Line 341)

**Context:**

```swift
       
       /// Determines the reservation type based on creation date and reservation date.
       mutating private func determineReservationType() {
           guard let reservationDate = DateHelper.parseDate(dateString),
                 let combinedStartDate = startTimeDate else {
               Self.logger.warning("Unable to determine reservation type, defaulting to inAdvance")
               self.reservationType = .inAdvance
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### combinedStartDate (Line 342)

**Context:**

```swift
       /// Determines the reservation type based on creation date and reservation date.
       mutating private func determineReservationType() {
           guard let reservationDate = DateHelper.parseDate(dateString),
                 let combinedStartDate = startTimeDate else {
               Self.logger.warning("Unable to determine reservation type, defaulting to inAdvance")
               self.reservationType = .inAdvance
               return
```

**Suggested Documentation:**

```swift
/// [Description of the combinedStartDate property]
```

### calendar (Line 348)

**Context:**

```swift
               return
           }
           
           let calendar = Calendar.current
           if calendar.isDate(creationDate, inSameDayAs: reservationDate) &&
                creationDate >= combinedStartDate, self.reservationType != .waitingList {
               self.reservationType = .walkIn
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### empty (Line 380)

**Context:**

```swift
extension Reservation.ReservationType: Codable {}

extension Reservation {
    static var empty: Reservation {
        return Reservation(
            name: "",
            phone: "",
```

**Suggested Documentation:**

```swift
/// [Description of the empty property]
```

### localized (Line 402)

**Context:**

```swift
}

extension Reservation.ReservationCategory {
    var localized: String {
        switch self {
        case .lunch:
            return String(localized: "pranzo")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### localized (Line 415)

**Context:**

```swift
}

extension Reservation.Acceptance {
    var localized: String {
        switch self {
        case .confirmed:
            return String(localized: "confermata")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### localized (Line 428)

**Context:**

```swift
}

extension Reservation.ReservationType {
    var localized: String {
        switch self {
        case .walkIn:
            return String(localized: "walk-in")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### localized (Line 443)

**Context:**

```swift
}

extension Reservation.ReservationStatus {
    var localized: String {
        switch self {
        case .pending:
            return String(localized: "prenotato")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### id (Line 466)

**Context:**

```swift
}

struct LightweightReservation: Codable {
    var id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### name (Line 467)

**Context:**

```swift

struct LightweightReservation: Codable {
    var id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### phone (Line 468)

**Context:**

```swift
struct LightweightReservation: Codable {
    var id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
```

**Suggested Documentation:**

```swift
/// [Description of the phone property]
```

### numberOfPersons (Line 469)

**Context:**

```swift
    var id: UUID
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### dateString (Line 470)

**Context:**

```swift
    var name: String
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### category (Line 471)

**Context:**

```swift
    var phone: String
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### startTime (Line 472)

**Context:**

```swift
    var numberOfPersons: Int
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 473)

**Context:**

```swift
    var dateString: String  // "yyyy-mm-dd"
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### acceptance (Line 474)

**Context:**

```swift
    var category: Reservation.ReservationCategory
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
    var group: Bool
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### status (Line 475)

**Context:**

```swift
    var startTime: String   // "HH:MM"
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
    var group: Bool
    var notes: String?
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationType (Line 476)

**Context:**

```swift
    var endTime: String     // computed but editable by user
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### group (Line 477)

**Context:**

```swift
    var acceptance: Reservation.Acceptance
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
```

**Suggested Documentation:**

```swift
/// [Description of the group property]
```

### notes (Line 478)

**Context:**

```swift
    var status: Reservation.ReservationStatus
    var reservationType: Reservation.ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var assignedEmoji: String?
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### tables (Line 479)

**Context:**

```swift
    var reservationType: Reservation.ReservationType
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var assignedEmoji: String?
    var preferredLanguage: String?
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### creationDate (Line 480)

**Context:**

```swift
    var group: Bool
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var assignedEmoji: String?
    var preferredLanguage: String?
    // Exclude the image data here
```

**Suggested Documentation:**

```swift
/// [Description of the creationDate property]
```

### assignedEmoji (Line 481)

**Context:**

```swift
    var notes: String?
    var tables: [TableModel]
    let creationDate: Date
    var assignedEmoji: String?
    var preferredLanguage: String?
    // Exclude the image data here
}
```

**Suggested Documentation:**

```swift
/// [Description of the assignedEmoji property]
```

### preferredLanguage (Line 482)

**Context:**

```swift
    var tables: [TableModel]
    let creationDate: Date
    var assignedEmoji: String?
    var preferredLanguage: String?
    // Exclude the image data here
}

```

**Suggested Documentation:**

```swift
/// [Description of the preferredLanguage property]
```

### sidebarColor (Line 494)

**Context:**

```swift
}

extension Reservation.ReservationCategory {
    var sidebarColor: Color {
        switch self {
        case .lunch: return Color.sidebar_lunch
        case .dinner: return Color.sidebar_dinner
```

**Suggested Documentation:**

```swift
/// [Description of the sidebarColor property]
```

### inspectorColor (Line 504)

**Context:**

```swift
}

extension Reservation.ReservationCategory {
    var inspectorColor: Color {
        switch self {
        case .lunch: return Color.inspector_lunch
        case .dinner: return Color.inspector_dinner
```

**Suggested Documentation:**

```swift
/// [Description of the inspectorColor property]
```


Total documentation suggestions: 104

