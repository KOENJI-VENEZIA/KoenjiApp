Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/Models/webReservationDeclineReason.swift...
# Documentation Suggestions for webReservationDeclineReason.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/Models/webReservationDeclineReason.swift
Total suggestions: 3

## Property Documentation (3)

### id (Line 19)

**Context:**

```swift
    case technicalIssue = "technical_issue"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayText: String {
        switch self {
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### displayText (Line 21)

**Context:**

```swift
    
    var id: String { rawValue }
    
    var displayText: String {
        switch self {
        case .capacityIssue:
            return String(localized: "We're at capacity for that time")
```

**Suggested Documentation:**

```swift
/// [Description of the displayText property]
```

### notesText (Line 38)

**Context:**

```swift
        }
    }
    
    var notesText: String {
        switch self {
        case .capacityIssue:
            return String(localized: "Declined: We've reached our capacity for the requested time.")
```

**Suggested Documentation:**

```swift
/// [Description of the notesText property]
```


Total documentation suggestions: 3

