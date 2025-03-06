Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/App Database/Mappers.swift...
# Documentation Suggestions for Mappers.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/App Database/Mappers.swift
Total suggestions: 18

## Class Documentation (2)

### ReservationMapper (Line 14)

**Context:**

```swift
import OSLog

@MainActor
struct ReservationMapper {
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
```

**Suggested Documentation:**

```swift
/// ReservationMapper class.
///
/// [Add a description of what this class does and its responsibilities]
```

### SessionMapper (Line 91)

**Context:**

```swift
}

@MainActor
struct SessionMapper {
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
```

**Suggested Documentation:**

```swift
/// SessionMapper class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (2)

### reservation (Line 18)

**Context:**

```swift
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func reservation(from row: Row) -> Reservation? {
        guard
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the reservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### session (Line 95)

**Context:**

```swift
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func session(from row: Row) -> Session? {
        let session = Session(
            id: row[SQLiteManager.shared.sessionId],
            uuid: row[SQLiteManager.shared.sessionUUID] ?? "null",
```

**Suggested Documentation:**

```swift
/// [Add a description of what the session method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (14)

### logger (Line 16)

**Context:**

```swift
@MainActor
struct ReservationMapper {
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func reservation(from row: Row) -> Reservation? {
        guard
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### uuid (Line 20)

**Context:**

```swift
    
    static func reservation(from row: Row) -> Reservation? {
        guard
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
```

**Suggested Documentation:**

```swift
/// [Description of the uuid property]
```

### category (Line 21)

**Context:**

```swift
    static func reservation(from row: Row) -> Reservation? {
        guard
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
            let reservationType = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### acceptance (Line 22)

**Context:**

```swift
        guard
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
            let reservationType = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
        else {
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### status (Line 23)

**Context:**

```swift
            let uuid = UUID(uuidString: row[SQLiteManager.shared.id]),
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
            let reservationType = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
        else {
            logger.error("Failed to convert UUID or enums for reservation row")
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationType (Line 24)

**Context:**

```swift
            let category = Reservation.ReservationCategory(rawValue: row[SQLiteManager.shared.category]),
            let acceptance = Reservation.Acceptance(rawValue: row[SQLiteManager.shared.acceptance]),
            let status = Reservation.ReservationStatus(rawValue: row[SQLiteManager.shared.status]),
            let reservationType = Reservation.ReservationType(rawValue: row[SQLiteManager.shared.reservationType])
        else {
            logger.error("Failed to convert UUID or enums for reservation row")
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### tablesArray (Line 30)

**Context:**

```swift
            return nil
        }
        
        var tablesArray: [TableModel] = []
        if let tablesString = row[SQLiteManager.shared.tables],
           let data = tablesString.data(using: .utf8) {
            let decoder = JSONDecoder()
```

**Suggested Documentation:**

```swift
/// [Description of the tablesArray property]
```

### tablesString (Line 31)

**Context:**

```swift
        }
        
        var tablesArray: [TableModel] = []
        if let tablesString = row[SQLiteManager.shared.tables],
           let data = tablesString.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
```

**Suggested Documentation:**

```swift
/// [Description of the tablesString property]
```

### data (Line 32)

**Context:**

```swift
        
        var tablesArray: [TableModel] = []
        if let tablesString = row[SQLiteManager.shared.tables],
           let data = tablesString.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                // First try to decode as an array of TableModel objects
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### decoder (Line 33)

**Context:**

```swift
        var tablesArray: [TableModel] = []
        if let tablesString = row[SQLiteManager.shared.tables],
           let data = tablesString.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                // First try to decode as an array of TableModel objects
                tablesArray = try decoder.decode([TableModel].self, from: data)
```

**Suggested Documentation:**

```swift
/// [Description of the decoder property]
```

### tableIds (Line 43)

**Context:**

```swift
                
                // If that fails, try to decode as an array of table IDs
                do {
                    let tableIds = try decoder.decode([Int].self, from: data)
                    logger.debug("Successfully decoded \(tableIds.count) table IDs")
                    
                    // Convert table IDs to TableModel objects
```

**Suggested Documentation:**

```swift
/// [Description of the tableIds property]
```

### reservation (Line 62)

**Context:**

```swift
            logger.warning("No tables data found for reservation")
        }
        
        let reservation = Reservation(
            id: uuid,
            name: row[SQLiteManager.shared.name],
            phone: row[SQLiteManager.shared.phone],
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### logger (Line 93)

**Context:**

```swift
@MainActor
struct SessionMapper {
    // Static logger for use in static methods
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func session(from row: Row) -> Session? {
        let session = Session(
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### session (Line 96)

**Context:**

```swift
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationMapper")
    
    static func session(from row: Row) -> Session? {
        let session = Session(
            id: row[SQLiteManager.shared.sessionId],
            uuid: row[SQLiteManager.shared.sessionUUID] ?? "null",
            userName: row[SQLiteManager.shared.sessionUserName],
```

**Suggested Documentation:**

```swift
/// [Description of the session property]
```


Total documentation suggestions: 18

