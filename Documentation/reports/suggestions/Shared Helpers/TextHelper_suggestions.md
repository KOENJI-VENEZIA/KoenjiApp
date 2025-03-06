Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Helpers/TextHelper.swift...
# Documentation Suggestions for TextHelper.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Helpers/TextHelper.swift
Total suggestions: 2

## Class Documentation (1)

### TextHelper (Line 11)

**Context:**

```swift
import SwiftUI
import Foundation

struct TextHelper {
    
    static func pluralized(_ singular: String, _ plural: String, _ count: Int) -> String {
        return count == 1 ? singular : plural
```

**Suggested Documentation:**

```swift
/// TextHelper class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (1)

### pluralized (Line 13)

**Context:**

```swift

struct TextHelper {
    
    static func pluralized(_ singular: String, _ plural: String, _ count: Int) -> String {
        return count == 1 ? singular : plural
    }
}
```

**Suggested Documentation:**

```swift
/// [Add a description of what the pluralized method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```


Total documentation suggestions: 2

