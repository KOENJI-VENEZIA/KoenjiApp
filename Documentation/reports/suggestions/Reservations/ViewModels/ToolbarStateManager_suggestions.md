Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/ToolbarStateManager.swift...
# Documentation Suggestions for ToolbarStateManager.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/ToolbarStateManager.swift
Total suggestions: 15

## Class Documentation (2)

### NavigationDirection (Line 10)

**Context:**

```swift
import SwiftUI
import Observation

enum NavigationDirection {
    case forward
    case backward
}
```

**Suggested Documentation:**

```swift
/// NavigationDirection class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ToolbarStateManager (Line 16)

**Context:**

```swift
}

@Observable
class ToolbarStateManager {
     var isDragging: Bool = false
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
```

**Suggested Documentation:**

```swift
/// ToolbarStateManager manager.
///
/// [Add a description of what this manager does and its responsibilities]
```

## Method Documentation (3)

### toolbarGesture (Line 28)

**Context:**

```swift

    
    
    @MainActor func toolbarGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                self.isDragging = true
```

**Suggested Documentation:**

```swift
/// [Add a description of what the toolbarGesture method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculatePosition (Line 99)

**Context:**

```swift
            }
    }
    
    func calculatePosition(geometry: GeometryProxy, isPhone: Bool = false) -> CGPoint {
        if toolbarState == .pinnedLeft {
            return CGPoint(x: isPhone ? 45 : 45, y: geometry.size.height / 2)
        } else if toolbarState == .pinnedRight {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculatePosition method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### transitionForCurrentState (Line 111)

**Context:**

```swift
        }
    }
    
    func transitionForCurrentState(geometry: GeometryProxy) -> AnyTransition {
        switch toolbarState {

        case .pinnedLeft:
```

**Suggested Documentation:**

```swift
/// [Add a description of what the transitionForCurrentState method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (10)

### isDragging (Line 17)

**Context:**

```swift

@Observable
class ToolbarStateManager {
     var isDragging: Bool = false
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
```

**Suggested Documentation:**

```swift
/// [Description of the isDragging property]
```

### toolbarState (Line 18)

**Context:**

```swift
@Observable
class ToolbarStateManager {
     var isDragging: Bool = false
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
     var lastPinnedPosition: CGPoint = .zero
```

**Suggested Documentation:**

```swift
/// [Description of the toolbarState property]
```

### dragAmount (Line 19)

**Context:**

```swift
class ToolbarStateManager {
     var isDragging: Bool = false
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
     var lastPinnedPosition: CGPoint = .zero
     var navigationDirection: NavigationDirection = .forward
```

**Suggested Documentation:**

```swift
/// [Description of the dragAmount property]
```

### isToolbarVisible (Line 20)

**Context:**

```swift
     var isDragging: Bool = false
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
     var lastPinnedPosition: CGPoint = .zero
     var navigationDirection: NavigationDirection = .forward

```

**Suggested Documentation:**

```swift
/// [Description of the isToolbarVisible property]
```

### lastPinnedPosition (Line 21)

**Context:**

```swift
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
     var lastPinnedPosition: CGPoint = .zero
     var navigationDirection: NavigationDirection = .forward


```

**Suggested Documentation:**

```swift
/// [Description of the lastPinnedPosition property]
```

### navigationDirection (Line 22)

**Context:**

```swift
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
     var lastPinnedPosition: CGPoint = .zero
     var navigationDirection: NavigationDirection = .forward



```

**Suggested Documentation:**

```swift
/// [Description of the navigationDirection property]
```

### currentLocation (Line 33)

**Context:**

```swift
            .onChanged { value in
                self.isDragging = true
                
                var currentLocation = value.location
                let currentOffset = value.translation
                
                if self.toolbarState != .pinnedBottom {
```

**Suggested Documentation:**

```swift
/// [Description of the currentLocation property]
```

### currentOffset (Line 34)

**Context:**

```swift
                self.isDragging = true
                
                var currentLocation = value.location
                let currentOffset = value.translation
                
                if self.toolbarState != .pinnedBottom {
                    currentLocation.y = (geometry.size.height / 2) + currentOffset.height
```

**Suggested Documentation:**

```swift
/// [Description of the currentOffset property]
```

### currentLocation (Line 47)

**Context:**

```swift
            .onEnded { value in
                defer { self.isDragging = false }
                
                var currentLocation = value.location
                let currentOffset = value.translation
                
                // Handle toolbar visibility
```

**Suggested Documentation:**

```swift
/// [Description of the currentLocation property]
```

### currentOffset (Line 48)

**Context:**

```swift
                defer { self.isDragging = false }
                
                var currentLocation = value.location
                let currentOffset = value.translation
                
                // Handle toolbar visibility
                switch self.toolbarState {
```

**Suggested Documentation:**

```swift
/// [Description of the currentOffset property]
```


Total documentation suggestions: 15

