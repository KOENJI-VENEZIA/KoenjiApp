Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/TableViewModel.swift...
# Documentation Suggestions for TableViewModel.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/TableViewModel.swift
Total suggestions: 21

## Class Documentation (1)

### TableViewModel (Line 10)

**Context:**

```swift

import SwiftUI

@Observable class TableViewModel {
    var systemTime: Date = Date()
    var dragState: DragState = .idle
    var selectedTable: TableModel?
```

**Suggested Documentation:**

```swift
/// TableViewModel view model.
///
/// [Add a description of what this view model does and its responsibilities]
```

## Property Documentation (20)

### systemTime (Line 11)

**Context:**

```swift
import SwiftUI

@Observable class TableViewModel {
    var systemTime: Date = Date()
    var dragState: DragState = .idle
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
```

**Suggested Documentation:**

```swift
/// [Description of the systemTime property]
```

### dragState (Line 12)

**Context:**

```swift

@Observable class TableViewModel {
    var systemTime: Date = Date()
    var dragState: DragState = .idle
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
```

**Suggested Documentation:**

```swift
/// [Description of the dragState property]
```

### selectedTable (Line 13)

**Context:**

```swift
@Observable class TableViewModel {
    var systemTime: Date = Date()
    var dragState: DragState = .idle
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedTable property]
```

### isDragging (Line 14)

**Context:**

```swift
    var systemTime: Date = Date()
    var dragState: DragState = .idle
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the isDragging property]
```

### isHeld (Line 15)

**Context:**

```swift
    var dragState: DragState = .idle
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the isHeld property]
```

### hasMoved (Line 16)

**Context:**

```swift
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
```

**Suggested Documentation:**

```swift
/// [Description of the hasMoved property]
```

### showEmojiPicker (Line 17)

**Context:**

```swift
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
    var selectedEmoji: String = ""
```

**Suggested Documentation:**

```swift
/// [Description of the showEmojiPicker property]
```

### showFullEmojiPicker (Line 18)

**Context:**

```swift
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
    var selectedEmoji: String = ""
    var tapTimer: Timer?
```

**Suggested Documentation:**

```swift
/// [Description of the showFullEmojiPicker property]
```

### isContextMenuActive (Line 19)

**Context:**

```swift
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
    var selectedEmoji: String = ""
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
```

**Suggested Documentation:**

```swift
/// [Description of the isContextMenuActive property]
```

### selectedEmoji (Line 20)

**Context:**

```swift
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
    var selectedEmoji: String = ""
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedEmoji property]
```

### tapTimer (Line 21)

**Context:**

```swift
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
    var selectedEmoji: String = ""
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the tapTimer property]
```

### debounceWorkItem (Line 22)

**Context:**

```swift
    var isContextMenuActive = false
    var selectedEmoji: String = ""
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the debounceWorkItem property]
```

### isDoubleTap (Line 23)

**Context:**

```swift
    var selectedEmoji: String = ""
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the isDoubleTap property]
```

### currentActiveReservation (Line 24)

**Context:**

```swift
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the currentActiveReservation property]
```

### firstUpcomingReservation (Line 25)

**Context:**

```swift
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
    var isLate: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the firstUpcomingReservation property]
```

### lateReservation (Line 26)

**Context:**

```swift
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
    var isLate: Bool = false
    var showedUp: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the lateReservation property]
```

### nearEndReservation (Line 27)

**Context:**

```swift
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
    var isLate: Bool = false
    var showedUp: Bool = false
    var isManuallyOverridden: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the nearEndReservation property]
```

### isLate (Line 28)

**Context:**

```swift
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
    var isLate: Bool = false
    var showedUp: Bool = false
    var isManuallyOverridden: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the isLate property]
```

### showedUp (Line 29)

**Context:**

```swift
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
    var isLate: Bool = false
    var showedUp: Bool = false
    var isManuallyOverridden: Bool = false

}
```

**Suggested Documentation:**

```swift
/// [Description of the showedUp property]
```

### isManuallyOverridden (Line 30)

**Context:**

```swift
    var nearEndReservation: Reservation?
    var isLate: Bool = false
    var showedUp: Bool = false
    var isManuallyOverridden: Bool = false

}

```

**Suggested Documentation:**

```swift
/// [Description of the isManuallyOverridden property]
```


Total documentation suggestions: 21

