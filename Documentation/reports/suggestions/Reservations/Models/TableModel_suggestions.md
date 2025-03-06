Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Models/TableModel.swift...
# Documentation Suggestions for TableModel.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Models/TableModel.swift
Total suggestions: 33

## Class Documentation (5)

### CodingKeys (Line 34)

**Context:**

```swift
    var height: Int { 3 }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, maxCapacity, row, column, adjacentCount, activeReservationAdjacentCount, isVisible
    }
    
```

**Suggested Documentation:**

```swift
/// CodingKeys class.
///
/// [Add a description of what this class does and its responsibilities]
```

### TableSide (Line 39)

**Context:**

```swift
    }
    
    // MARK: - Table Side Enum
    enum TableSide: CaseIterable {
        case top, bottom, left, right

        func offset() -> (rowOffset: Int, colOffset: Int) {
```

**Suggested Documentation:**

```swift
/// TableSide class.
///
/// [Add a description of what this class does and its responsibilities]
```

### TableModel (Line 54)

**Context:**

```swift
}

// MARK: - Codable Implementation
extension TableModel {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
```

**Suggested Documentation:**

```swift
/// TableModel class.
///
/// [Add a description of what this class does and its responsibilities]
```

### TableCluster (Line 99)

**Context:**

```swift
}

// MARK: - Related Models
struct TableCluster: Equatable, Encodable, Decodable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TableCluster")
    // MARK: - Properties
    var id: UUID = UUID()
```

**Suggested Documentation:**

```swift
/// TableCluster class.
///
/// [Add a description of what this class does and its responsibilities]
```

### CachedCluster (Line 114)

**Context:**

```swift
    }
}

struct CachedCluster: Equatable, Codable, Identifiable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "CachedCluster")
    // MARK: - Properties
    let id: UUID
```

**Suggested Documentation:**

```swift
/// CachedCluster class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (2)

### offset (Line 42)

**Context:**

```swift
    enum TableSide: CaseIterable {
        case top, bottom, left, right

        func offset() -> (rowOffset: Int, colOffset: Int) {
            switch self {
            case .top: return (-3, 0)
            case .bottom: return (3, 0)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the offset method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### encode (Line 77)

**Context:**

```swift
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        do {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the encode method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (26)

### logger (Line 14)

**Context:**

```swift
/// Represents a physical table in the restaurant.
struct TableModel: Identifiable, Hashable, Codable, Equatable {
    // MARK: - Private Properties
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.koenjiapp",
        category: "TableModel"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### id (Line 20)

**Context:**

```swift
    )
    
    // MARK: - Public Properties
    let id: Int
    let name: String
    let maxCapacity: Int
    var row: Int
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### name (Line 21)

**Context:**

```swift
    
    // MARK: - Public Properties
    let id: Int
    let name: String
    let maxCapacity: Int
    var row: Int
    var column: Int
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### maxCapacity (Line 22)

**Context:**

```swift
    // MARK: - Public Properties
    let id: Int
    let name: String
    let maxCapacity: Int
    var row: Int
    var column: Int
    var adjacentCount: Int = 0
```

**Suggested Documentation:**

```swift
/// [Description of the maxCapacity property]
```

### row (Line 23)

**Context:**

```swift
    let id: Int
    let name: String
    let maxCapacity: Int
    var row: Int
    var column: Int
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
```

**Suggested Documentation:**

```swift
/// [Description of the row property]
```

### column (Line 24)

**Context:**

```swift
    let name: String
    let maxCapacity: Int
    var row: Int
    var column: Int
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
    var isVisible: Bool = true
```

**Suggested Documentation:**

```swift
/// [Description of the column property]
```

### adjacentCount (Line 25)

**Context:**

```swift
    let maxCapacity: Int
    var row: Int
    var column: Int
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
    var isVisible: Bool = true

```

**Suggested Documentation:**

```swift
/// [Description of the adjacentCount property]
```

### activeReservationAdjacentCount (Line 26)

**Context:**

```swift
    var row: Int
    var column: Int
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
    var isVisible: Bool = true

    // MARK: - Computed Properties
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservationAdjacentCount property]
```

### isVisible (Line 27)

**Context:**

```swift
    var column: Int
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
    var isVisible: Bool = true

    // MARK: - Computed Properties
    var width: Int { 3 }
```

**Suggested Documentation:**

```swift
/// [Description of the isVisible property]
```

### width (Line 30)

**Context:**

```swift
    var isVisible: Bool = true

    // MARK: - Computed Properties
    var width: Int { 3 }
    var height: Int { 3 }
    
    // MARK: - Coding Keys
```

**Suggested Documentation:**

```swift
/// [Description of the width property]
```

### height (Line 31)

**Context:**

```swift

    // MARK: - Computed Properties
    var width: Int { 3 }
    var height: Int { 3 }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
```

**Suggested Documentation:**

```swift
/// [Description of the height property]
```

### container (Line 56)

**Context:**

```swift
// MARK: - Codable Implementation
extension TableModel {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(Int.self, forKey: .id)
```

**Suggested Documentation:**

```swift
/// [Description of the container property]
```

### nameCopy (Line 68)

**Context:**

```swift
            activeReservationAdjacentCount = try container.decodeIfPresent(Int.self, forKey: .activeReservationAdjacentCount) ?? 0
            isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
            
            let nameCopy = name
            let idCopy = id
            TableModel.logger.debug("Successfully decoded table: \(nameCopy) (ID: \(idCopy))")
        } catch {
```

**Suggested Documentation:**

```swift
/// [Description of the nameCopy property]
```

### idCopy (Line 69)

**Context:**

```swift
            isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
            
            let nameCopy = name
            let idCopy = id
            TableModel.logger.debug("Successfully decoded table: \(nameCopy) (ID: \(idCopy))")
        } catch {
            TableModel.logger.error("Failed to decode table: \(error.localizedDescription)")
```

**Suggested Documentation:**

```swift
/// [Description of the idCopy property]
```

### container (Line 78)

**Context:**

```swift
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        do {
            try container.encode(id, forKey: .id)
```

**Suggested Documentation:**

```swift
/// [Description of the container property]
```

### logger (Line 100)

**Context:**

```swift

// MARK: - Related Models
struct TableCluster: Equatable, Encodable, Decodable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TableCluster")
    // MARK: - Properties
    var id: UUID = UUID()
    let reservation: Reservation
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### id (Line 102)

**Context:**

```swift
struct TableCluster: Equatable, Encodable, Decodable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TableCluster")
    // MARK: - Properties
    var id: UUID = UUID()
    let reservation: Reservation
    let tables: [TableModel]
    
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### reservation (Line 103)

**Context:**

```swift
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TableCluster")
    // MARK: - Properties
    var id: UUID = UUID()
    let reservation: Reservation
    let tables: [TableModel]
    
    init(id: UUID = UUID(), reservation: Reservation, tables: [TableModel]) {
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### tables (Line 104)

**Context:**

```swift
    // MARK: - Properties
    var id: UUID = UUID()
    let reservation: Reservation
    let tables: [TableModel]
    
    init(id: UUID = UUID(), reservation: Reservation, tables: [TableModel]) {
        self.id = id
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### logger (Line 115)

**Context:**

```swift
}

struct CachedCluster: Equatable, Codable, Identifiable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "CachedCluster")
    // MARK: - Properties
    let id: UUID
    let reservationID: Reservation
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### id (Line 117)

**Context:**

```swift
struct CachedCluster: Equatable, Codable, Identifiable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "CachedCluster")
    // MARK: - Properties
    let id: UUID
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### reservationID (Line 118)

**Context:**

```swift
    static let logger = Logger(subsystem: "com.koenjiapp", category: "CachedCluster")
    // MARK: - Properties
    let id: UUID
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
```

**Suggested Documentation:**

```swift
/// [Description of the reservationID property]
```

### tableIDs (Line 119)

**Context:**

```swift
    // MARK: - Properties
    let id: UUID
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
    var frame: CGRect
```

**Suggested Documentation:**

```swift
/// [Description of the tableIDs property]
```

### date (Line 120)

**Context:**

```swift
    let id: UUID
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
    var frame: CGRect
    
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### category (Line 121)

**Context:**

```swift
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
    var frame: CGRect
    
    init(
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### frame (Line 122)

**Context:**

```swift
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
    var frame: CGRect
    
    init(
        id: UUID = UUID(),
```

**Suggested Documentation:**

```swift
/// [Description of the frame property]
```


Total documentation suggestions: 33

