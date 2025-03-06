Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Models/GroupSort.swift...
# Documentation Suggestions for GroupSort.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Models/GroupSort.swift
Total suggestions: 12

## Class Documentation (4)

### GroupedReservations (Line 10)

**Context:**

```swift

import Foundation

struct GroupedReservations: Identifiable {
    let id = UUID()
    let label: String
    let reservations: [Reservation]
```

**Suggested Documentation:**

```swift
/// GroupedReservations class.
///
/// [Add a description of what this class does and its responsibilities]
```

### SortOption (Line 18)

**Context:**

```swift
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
}

enum SortOption: String, CaseIterable {
    case alphabetically = "A-Z"
    case chronologically = "per_data"
    case byNumberOfPeople = "per_persone"
```

**Suggested Documentation:**

```swift
/// SortOption class.
///
/// [Add a description of what this class does and its responsibilities]
```

### GroupOption (Line 41)

**Context:**

```swift
    }
}

enum GroupOption: String, CaseIterable {
    case none = "nessuno"
    case table = "per_tavolo"
    case day = "per_giorno"
```

**Suggested Documentation:**

```swift
/// GroupOption class.
///
/// [Add a description of what this class does and its responsibilities]
```

### FilterOption (Line 64)

**Context:**

```swift
    }
}

enum FilterOption: String, CaseIterable {
    case none = "nessuno"
    case people = "per_numero_ospiti"
    case date = "per_data"
```

**Suggested Documentation:**

```swift
/// FilterOption class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Property Documentation (8)

### id (Line 11)

**Context:**

```swift
import Foundation

struct GroupedReservations: Identifiable {
    let id = UUID()
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?  // Used for date-based groupings
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### label (Line 12)

**Context:**

```swift

struct GroupedReservations: Identifiable {
    let id = UUID()
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?  // Used for date-based groupings
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
```

**Suggested Documentation:**

```swift
/// [Description of the label property]
```

### reservations (Line 13)

**Context:**

```swift
struct GroupedReservations: Identifiable {
    let id = UUID()
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?  // Used for date-based groupings
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
}
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### sortDate (Line 14)

**Context:**

```swift
    let id = UUID()
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?  // Used for date-based groupings
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
}

```

**Suggested Documentation:**

```swift
/// [Description of the sortDate property]
```

### sortString (Line 15)

**Context:**

```swift
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?  // Used for date-based groupings
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
}

enum SortOption: String, CaseIterable {
```

**Suggested Documentation:**

```swift
/// [Description of the sortString property]
```

### localized (Line 25)

**Context:**

```swift
    case removeSorting = "nessuno"
    case byCreationDate = "per_ultime_aggiunte"
    
    var localized: String {
        switch self {
        case .alphabetically:
            return "A-Z"
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### localized (Line 48)

**Context:**

```swift
    case week = "per_settimana"
    case month = "per_mese"
    
    var localized: String {
        switch self {
        case .none:
            return String(localized: "Nessuno")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### localized (Line 74)

**Context:**

```swift
    case waitingList = "waiting_list"
    case webPending = "web_pending"
    
    var localized: String {
        switch self {
        case .none:
            return String(localized: "Nessuno")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```


Total documentation suggestions: 12

