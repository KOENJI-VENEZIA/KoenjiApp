Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Entry/SidebarView.swift...
# Documentation Suggestions for SidebarView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Entry/SidebarView.swift
Total suggestions: 13

## Class Documentation (1)

### SidebarView (Line 10)

**Context:**

```swift

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel
```

**Suggested Documentation:**

```swift
/// SidebarView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Property Documentation (12)

### env (Line 11)

**Context:**

```swift
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel

```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 12)

**Context:**

```swift

struct SidebarView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel

    @StateObject private var notificationManager = NotificationManager.shared
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### viewModel (Line 13)

**Context:**

```swift
struct SidebarView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel

    @StateObject private var notificationManager = NotificationManager.shared

```

**Suggested Documentation:**

```swift
/// [Description of the viewModel property]
```

### notificationManager (Line 15)

**Context:**

```swift
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel

    @StateObject private var notificationManager = NotificationManager.shared

    @State var unitView = LayoutUnitViewModel()
    
```

**Suggested Documentation:**

```swift
/// [Description of the notificationManager property]
```

### unitView (Line 17)

**Context:**

```swift

    @StateObject private var notificationManager = NotificationManager.shared

    @State var unitView = LayoutUnitViewModel()
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### selectedReservation (Line 19)

**Context:**

```swift

    @State var unitView = LayoutUnitViewModel()
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
```

**Suggested Documentation:**

```swift
/// [Description of the selectedReservation property]
```

### currentReservation (Line 20)

**Context:**

```swift
    @State var unitView = LayoutUnitViewModel()
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservation property]
```

### selectedCategory (Line 21)

**Context:**

```swift
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    @State private var showingReservationInfo = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedCategory property]
```

### columnVisibility (Line 22)

**Context:**

```swift
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    @State private var showingReservationInfo = false

```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```

### showingReservationInfo (Line 24)

**Context:**

```swift
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    @State private var showingReservationInfo = false

    init(selectedReservation: Binding<Reservation?>, currentReservation: Binding<Reservation?>, selectedCategory: Binding<Reservation.ReservationCategory?>, columnVisibility: Binding<NavigationSplitViewVisibility>) {

```

**Suggested Documentation:**

```swift
/// [Description of the showingReservationInfo property]
```

### body (Line 37)

**Context:**

```swift
        
        
    }
    var body: some View {

        ZStack {
            appState.selectedCategory.sidebarColor
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### reservationID (Line 117)

**Context:**

```swift
                       get: { notificationManager.selectedReservationID != nil },
                       set: { if !$0 { notificationManager.selectedReservationID = nil } }
                   )) {
                       if let reservationID = notificationManager.selectedReservationID {
                           NavigationStack {
                               ReservationInfoCard(
                                   reservationID: reservationID,
```

**Suggested Documentation:**

```swift
/// [Description of the reservationID property]
```


Total documentation suggestions: 13

