Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Views/Helper Views/ToolbarViews.swift...
# Documentation Suggestions for ToolbarViews.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Views/Helper Views/ToolbarViews.swift
Total suggestions: 9

## Class Documentation (2)

### ToolbarExtended (Line 10)

**Context:**

```swift

import SwiftUI

struct ToolbarExtended: View {

    let geometry: GeometryProxy
    @Binding var toolbarState: ToolbarState
```

**Suggested Documentation:**

```swift
/// ToolbarExtended class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ToolbarMinimized (Line 35)

**Context:**

```swift
}


struct ToolbarMinimized: View {
    
    @Environment(\.colorScheme) var colorScheme

```

**Suggested Documentation:**

```swift
/// ToolbarMinimized class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Property Documentation (7)

### geometry (Line 12)

**Context:**

```swift

struct ToolbarExtended: View {

    let geometry: GeometryProxy
    @Binding var toolbarState: ToolbarState
    let small: Bool
    var timeline: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the geometry property]
```

### toolbarState (Line 13)

**Context:**

```swift
struct ToolbarExtended: View {

    let geometry: GeometryProxy
    @Binding var toolbarState: ToolbarState
    let small: Bool
    var timeline: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the toolbarState property]
```

### small (Line 14)

**Context:**

```swift

    let geometry: GeometryProxy
    @Binding var toolbarState: ToolbarState
    let small: Bool
    var timeline: Bool = false

    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the small property]
```

### timeline (Line 15)

**Context:**

```swift
    let geometry: GeometryProxy
    @Binding var toolbarState: ToolbarState
    let small: Bool
    var timeline: Bool = false

    var body: some View {

```

**Suggested Documentation:**

```swift
/// [Description of the timeline property]
```

### body (Line 17)

**Context:**

```swift
    let small: Bool
    var timeline: Bool = false

    var body: some View {

            // MARK: Background (RoundedRectangle)
            RoundedRectangle(cornerRadius: 12)
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### colorScheme (Line 37)

**Context:**

```swift

struct ToolbarMinimized: View {
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### body (Line 39)

**Context:**

```swift
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 12)
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```


Total documentation suggestions: 9

