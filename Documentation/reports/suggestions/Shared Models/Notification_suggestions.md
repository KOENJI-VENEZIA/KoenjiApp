Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Models/Notification.swift...
# Documentation Suggestions for Notification.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Models/Notification.swift
Total suggestions: 9

## Class Documentation (2)

### NotificationType (Line 10)

**Context:**

```swift

import SwiftUI

enum NotificationType: Equatable {
    case late
    case nearEnd
    case canceled
```

**Suggested Documentation:**

```swift
/// NotificationType class.
///
/// [Add a description of what this class does and its responsibilities]
```

### NotificationType (Line 31)

**Context:**

```swift
    let type: NotificationType
}

extension NotificationType {
    var localized: String {
        switch self {
        case .late:
```

**Suggested Documentation:**

```swift
/// NotificationType class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Property Documentation (7)

### id (Line 23)

**Context:**

```swift

/// A simple model representing a notification within your app.
struct AppNotification: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### title (Line 24)

**Context:**

```swift
/// A simple model representing a notification within your app.
struct AppNotification: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date = Date()
    let reservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the title property]
```

### message (Line 25)

**Context:**

```swift
struct AppNotification: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date = Date()
    let reservation: Reservation?
    let type: NotificationType
```

**Suggested Documentation:**

```swift
/// [Description of the message property]
```

### date (Line 26)

**Context:**

```swift
    let id = UUID()
    let title: String
    let message: String
    let date: Date = Date()
    let reservation: Reservation?
    let type: NotificationType
}
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### reservation (Line 27)

**Context:**

```swift
    let title: String
    let message: String
    let date: Date = Date()
    let reservation: Reservation?
    let type: NotificationType
}

```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### type (Line 28)

**Context:**

```swift
    let message: String
    let date: Date = Date()
    let reservation: Reservation?
    let type: NotificationType
}

extension NotificationType {
```

**Suggested Documentation:**

```swift
/// [Description of the type property]
```

### localized (Line 32)

**Context:**

```swift
}

extension NotificationType {
    var localized: String {
        switch self {
        case .late:
            return String(localized: "ritardo")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```


Total documentation suggestions: 9

