Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/App Config/AppState.swift...
# Documentation Suggestions for AppState.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/App Config/AppState.swift
Total suggestions: 26

## Class Documentation (1)

### AppState (Line 11)

**Context:**

```swift
import SwiftUI
import OSLog

class AppState: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppState")

    // MARK: - Published Properties
```

**Suggested Documentation:**

```swift
/// AppState class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (1)

### updateCategoryForDate (Line 43)

**Context:**

```swift
        logger.info("AppState initialized with category: \(selectedCategory.localized)")
    }

    private func updateCategoryForDate() -> Reservation.ReservationCategory {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateCategoryForDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (24)

### logger (Line 12)

**Context:**

```swift
import OSLog

class AppState: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppState")

    // MARK: - Published Properties
    @Published var inspectorColor: Color = Color.inspector_generic
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### inspectorColor (Line 15)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppState")

    // MARK: - Published Properties
    @Published var inspectorColor: Color = Color.inspector_generic
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the inspectorColor property]
```

### selectedDate (Line 16)

**Context:**

```swift

    // MARK: - Published Properties
    @Published var inspectorColor: Color = Color.inspector_generic
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedDate property]
```

### selectedCategory (Line 17)

**Context:**

```swift
    // MARK: - Published Properties
    @Published var inspectorColor: Color = Color.inspector_generic
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the selectedCategory property]
```

### systemTime (Line 18)

**Context:**

```swift
    @Published var inspectorColor: Color = Color.inspector_generic
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the systemTime property]
```

### isManuallyOverridden (Line 19)

**Context:**

```swift
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the isManuallyOverridden property]
```

### changedReservation (Line 20)

**Context:**

```swift
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
```

**Suggested Documentation:**

```swift
/// [Description of the changedReservation property]
```

### showingEditReservation (Line 21)

**Context:**

```swift
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
    @Published var canSave = true
```

**Suggested Documentation:**

```swift
/// [Description of the showingEditReservation property]
```

### currentReservation (Line 22)

**Context:**

```swift
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservation property]
```

### isRestoring (Line 23)

**Context:**

```swift
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
```

**Suggested Documentation:**

```swift
/// [Description of the isRestoring property]
```

### canSave (Line 24)

**Context:**

```swift
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
```

**Suggested Documentation:**

```swift
/// [Description of the canSave property]
```

### showingDatePicker (Line 25)

**Context:**

```swift
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
```

**Suggested Documentation:**

```swift
/// [Description of the showingDatePicker property]
```

### isFullScreen (Line 26)

**Context:**

```swift
    @Published var isRestoring = false
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false
```

**Suggested Documentation:**

```swift
/// [Description of the isFullScreen property]
```

### columnVisibility (Line 27)

**Context:**

```swift
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false
    @Published var lastRefreshedKeys: [String] = []
```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```

### rotationAngle (Line 28)

**Context:**

```swift
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false
    @Published var lastRefreshedKeys: [String] = []

```

**Suggested Documentation:**

```swift
/// [Description of the rotationAngle property]
```

### isContentReady (Line 29)

**Context:**

```swift
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false
    @Published var lastRefreshedKeys: [String] = []

    // MARK: - State Properties
```

**Suggested Documentation:**

```swift
/// [Description of the isContentReady property]
```

### lastRefreshedKeys (Line 30)

**Context:**

```swift
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false
    @Published var lastRefreshedKeys: [String] = []

    // MARK: - State Properties
    @State var dates: [Date] = []
```

**Suggested Documentation:**

```swift
/// [Description of the lastRefreshedKeys property]
```

### dates (Line 33)

**Context:**

```swift
    @Published var lastRefreshedKeys: [String] = []

    // MARK: - State Properties
    @State var dates: [Date] = []
    @State var selectedIndex: Int = 15
    @State var showingAddReservationSheet: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the dates property]
```

### selectedIndex (Line 34)

**Context:**

```swift

    // MARK: - State Properties
    @State var dates: [Date] = []
    @State var selectedIndex: Int = 15
    @State var showingAddReservationSheet: Bool = false

    init(selectedCategory: Reservation.ReservationCategory = .lunch) {
```

**Suggested Documentation:**

```swift
/// [Description of the selectedIndex property]
```

### showingAddReservationSheet (Line 35)

**Context:**

```swift
    // MARK: - State Properties
    @State var dates: [Date] = []
    @State var selectedIndex: Int = 15
    @State var showingAddReservationSheet: Bool = false

    init(selectedCategory: Reservation.ReservationCategory = .lunch) {
        self.selectedCategory = selectedCategory
```

**Suggested Documentation:**

```swift
/// [Description of the showingAddReservationSheet property]
```

### calendar (Line 44)

**Context:**

```swift
    }

    private func updateCategoryForDate() -> Reservation.ReservationCategory {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)

```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### hour (Line 45)

**Context:**

```swift

    private func updateCategoryForDate() -> Reservation.ReservationCategory {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)

        let category: Reservation.ReservationCategory
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### minute (Line 46)

**Context:**

```swift
    private func updateCategoryForDate() -> Reservation.ReservationCategory {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)

        let category: Reservation.ReservationCategory
        if hour >= 12 && (hour < 15 || (hour == 15 && minute == 0)) {
```

**Suggested Documentation:**

```swift
/// [Description of the minute property]
```

### category (Line 48)

**Context:**

```swift
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)

        let category: Reservation.ReservationCategory
        if hour >= 12 && (hour < 15 || (hour == 15 && minute == 0)) {
            category = .lunch
        } else if hour >= 18 && (hour < 23 || (hour == 23 && minute <= 45)) {
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```


Total documentation suggestions: 26

