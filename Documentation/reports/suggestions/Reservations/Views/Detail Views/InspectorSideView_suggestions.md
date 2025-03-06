Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/InspectorSideView.swift...
# Documentation Suggestions for InspectorSideView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/InspectorSideView.swift
Total suggestions: 12

## Class Documentation (2)

### InspectorSideView (Line 10)

**Context:**

```swift

import SwiftUI

struct InspectorSideView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
```

**Suggested Documentation:**

```swift
/// InspectorSideView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### SelectedView (Line 23)

**Context:**

```swift
        env.resCache.reservations(for: currentTime)
    }
    
    enum SelectedView {
        case info
        case cancelled
        case waiting
```

**Suggested Documentation:**

```swift
/// SelectedView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (1)

### dismissInfoCard (Line 143)

**Context:**

```swift
    
    // MARK: - Helper Methods
    
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            unitView.showInspector = false
            selectedReservation = nil
```

**Suggested Documentation:**

```swift
/// [Add a description of what the dismissInfoCard method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (9)

### env (Line 11)

**Context:**

```swift
import SwiftUI

struct InspectorSideView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
    
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 12)

**Context:**

```swift

struct InspectorSideView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Binding var selectedReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### unitView (Line 13)

**Context:**

```swift
struct InspectorSideView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Binding var selectedReservation: Reservation?
    @State private var selectedView: SelectedView = .info
```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### selectedReservation (Line 15)

**Context:**

```swift
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Binding var selectedReservation: Reservation?
    @State private var selectedView: SelectedView = .info
    @State var currentTime: Date = Date()
    
```

**Suggested Documentation:**

```swift
/// [Description of the selectedReservation property]
```

### selectedView (Line 16)

**Context:**

```swift
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Binding var selectedReservation: Reservation?
    @State private var selectedView: SelectedView = .info
    @State var currentTime: Date = Date()
    
    var activeReservations: [Reservation] {
```

**Suggested Documentation:**

```swift
/// [Description of the selectedView property]
```

### currentTime (Line 17)

**Context:**

```swift
    
    @Binding var selectedReservation: Reservation?
    @State private var selectedView: SelectedView = .info
    @State var currentTime: Date = Date()
    
    var activeReservations: [Reservation] {
        env.resCache.reservations(for: currentTime)
```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```

### activeReservations (Line 19)

**Context:**

```swift
    @State private var selectedView: SelectedView = .info
    @State var currentTime: Date = Date()
    
    var activeReservations: [Reservation] {
        env.resCache.reservations(for: currentTime)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservations property]
```

### body (Line 29)

**Context:**

```swift
        case waiting
    }
    // MARK: - Body
    var body: some View {

        ZStack {
//            Color(appState.selectedCategory.inspectorColor)
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### reservation (Line 47)

**Context:**

```swift
                switch selectedView {
                case .info:
                    
                if let reservation = selectedReservation {
                    ReservationInfoCard(
                        reservationID: reservation.id,
                        onClose: {
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```


Total documentation suggestions: 12

