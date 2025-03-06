Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Models/Notification.swift...
# Documentation Suggestions for Notification.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Models/Notification.swift
Total suggestions: 3

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

## Property Documentation (1)

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


Total documentation suggestions: 3

