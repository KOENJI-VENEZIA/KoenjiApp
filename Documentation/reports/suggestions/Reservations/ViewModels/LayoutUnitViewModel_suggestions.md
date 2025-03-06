Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/LayoutUnitViewModel.swift...
# Documentation Suggestions for LayoutUnitViewModel.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/LayoutUnitViewModel.swift
Total suggestions: 24

## Class Documentation (1)

### LayoutUnitViewModel (Line 13)

**Context:**

```swift
import ScreenshotSwiftUI

@Observable
class LayoutUnitViewModel {
    
    var dates: [Date] = []
    var selectedIndex: Int = 15
```

**Suggested Documentation:**

```swift
/// LayoutUnitViewModel view model.
///
/// [Add a description of what this view model does and its responsibilities]
```

## Property Documentation (23)

### dates (Line 15)

**Context:**

```swift
@Observable
class LayoutUnitViewModel {
    
    var dates: [Date] = []
    var selectedIndex: Int = 15

    var systemTime: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the dates property]
```

### selectedIndex (Line 16)

**Context:**

```swift
class LayoutUnitViewModel {
    
    var dates: [Date] = []
    var selectedIndex: Int = 15

    var systemTime: Date = Date()
    var isManuallyOverridden: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedIndex property]
```

### systemTime (Line 18)

**Context:**

```swift
    var dates: [Date] = []
    var selectedIndex: Int = 15

    var systemTime: Date = Date()
    var isManuallyOverridden: Bool = false
    var showInspector: Bool = false
    var showingDatePicker: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the systemTime property]
```

### isManuallyOverridden (Line 19)

**Context:**

```swift
    var selectedIndex: Int = 15

    var systemTime: Date = Date()
    var isManuallyOverridden: Bool = false
    var showInspector: Bool = false
    var showingDatePicker: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the isManuallyOverridden property]
```

### showInspector (Line 20)

**Context:**

```swift

    var systemTime: Date = Date()
    var isManuallyOverridden: Bool = false
    var showInspector: Bool = false
    var showingDatePicker: Bool = false

    var showNotifsCenter: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showInspector property]
```

### showingDatePicker (Line 21)

**Context:**

```swift
    var systemTime: Date = Date()
    var isManuallyOverridden: Bool = false
    var showInspector: Bool = false
    var showingDatePicker: Bool = false

    var showNotifsCenter: Bool = false
    var showingAddReservationSheet: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showingDatePicker property]
```

### showNotifsCenter (Line 23)

**Context:**

```swift
    var showInspector: Bool = false
    var showingDatePicker: Bool = false

    var showNotifsCenter: Bool = false
    var showingAddReservationSheet: Bool = false
    var tableForNewReservation: TableModel? = nil

```

**Suggested Documentation:**

```swift
/// [Description of the showNotifsCenter property]
```

### showingAddReservationSheet (Line 24)

**Context:**

```swift
    var showingDatePicker: Bool = false

    var showNotifsCenter: Bool = false
    var showingAddReservationSheet: Bool = false
    var tableForNewReservation: TableModel? = nil

    var showingNoBookingAlert: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showingAddReservationSheet property]
```

### tableForNewReservation (Line 25)

**Context:**

```swift

    var showNotifsCenter: Bool = false
    var showingAddReservationSheet: Bool = false
    var tableForNewReservation: TableModel? = nil

    var showingNoBookingAlert: Bool = false
    var isLayoutLocked: Bool = true
```

**Suggested Documentation:**

```swift
/// [Description of the tableForNewReservation property]
```

### showingNoBookingAlert (Line 27)

**Context:**

```swift
    var showingAddReservationSheet: Bool = false
    var tableForNewReservation: TableModel? = nil

    var showingNoBookingAlert: Bool = false
    var isLayoutLocked: Bool = true
    var isZoomLocked: Bool = false
    var isLayoutReset: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showingNoBookingAlert property]
```

### isLayoutLocked (Line 28)

**Context:**

```swift
    var tableForNewReservation: TableModel? = nil

    var showingNoBookingAlert: Bool = false
    var isLayoutLocked: Bool = true
    var isZoomLocked: Bool = false
    var isLayoutReset: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the isLayoutLocked property]
```

### isZoomLocked (Line 29)

**Context:**

```swift

    var showingNoBookingAlert: Bool = false
    var isLayoutLocked: Bool = true
    var isZoomLocked: Bool = false
    var isLayoutReset: Bool = false

    var isScribbleModeEnabled: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the isZoomLocked property]
```

### isLayoutReset (Line 30)

**Context:**

```swift
    var showingNoBookingAlert: Bool = false
    var isLayoutLocked: Bool = true
    var isZoomLocked: Bool = false
    var isLayoutReset: Bool = false

    var isScribbleModeEnabled: Bool = false
    var drawings: [String: PKDrawing] = [:]
```

**Suggested Documentation:**

```swift
/// [Description of the isLayoutReset property]
```

### isScribbleModeEnabled (Line 32)

**Context:**

```swift
    var isZoomLocked: Bool = false
    var isLayoutReset: Bool = false

    var isScribbleModeEnabled: Bool = false
    var drawings: [String: PKDrawing] = [:]

    var toolPickerShows = false
```

**Suggested Documentation:**

```swift
/// [Description of the isScribbleModeEnabled property]
```

### drawings (Line 33)

**Context:**

```swift
    var isLayoutReset: Bool = false

    var isScribbleModeEnabled: Bool = false
    var drawings: [String: PKDrawing] = [:]

    var toolPickerShows = false

```

**Suggested Documentation:**

```swift
/// [Description of the drawings property]
```

### toolPickerShows (Line 35)

**Context:**

```swift
    var isScribbleModeEnabled: Bool = false
    var drawings: [String: PKDrawing] = [:]

    var toolPickerShows = false

    var capturedImage: UIImage? = nil
    var cachedScreenshot: ScreenshotMaker?
```

**Suggested Documentation:**

```swift
/// [Description of the toolPickerShows property]
```

### capturedImage (Line 37)

**Context:**

```swift

    var toolPickerShows = false

    var capturedImage: UIImage? = nil
    var cachedScreenshot: ScreenshotMaker?
    var isSharing: Bool = false
    var isPresented: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the capturedImage property]
```

### cachedScreenshot (Line 38)

**Context:**

```swift
    var toolPickerShows = false

    var capturedImage: UIImage? = nil
    var cachedScreenshot: ScreenshotMaker?
    var isSharing: Bool = false
    var isPresented: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the cachedScreenshot property]
```

### isSharing (Line 39)

**Context:**

```swift

    var capturedImage: UIImage? = nil
    var cachedScreenshot: ScreenshotMaker?
    var isSharing: Bool = false
    var isPresented: Bool = false

    var refreshID = UUID()
```

**Suggested Documentation:**

```swift
/// [Description of the isSharing property]
```

### isPresented (Line 40)

**Context:**

```swift
    var capturedImage: UIImage? = nil
    var cachedScreenshot: ScreenshotMaker?
    var isSharing: Bool = false
    var isPresented: Bool = false

    var refreshID = UUID()
    var scale: CGFloat = 1
```

**Suggested Documentation:**

```swift
/// [Description of the isPresented property]
```

### refreshID (Line 42)

**Context:**

```swift
    var isSharing: Bool = false
    var isPresented: Bool = false

    var refreshID = UUID()
    var scale: CGFloat = 1
    var isShowingFullImage: Bool = false
    
```

**Suggested Documentation:**

```swift
/// [Description of the refreshID property]
```

### scale (Line 43)

**Context:**

```swift
    var isPresented: Bool = false

    var refreshID = UUID()
    var scale: CGFloat = 1
    var isShowingFullImage: Bool = false
    
}
```

**Suggested Documentation:**

```swift
/// [Description of the scale property]
```

### isShowingFullImage (Line 44)

**Context:**

```swift

    var refreshID = UUID()
    var scale: CGFloat = 1
    var isShowingFullImage: Bool = false
    
}

```

**Suggested Documentation:**

```swift
/// [Description of the isShowingFullImage property]
```


Total documentation suggestions: 24

