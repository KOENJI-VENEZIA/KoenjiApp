Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationsInfoListView.swift...
# Documentation Suggestions for ReservationsInfoListView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationsInfoListView.swift
Total suggestions: 33

## Class Documentation (2)

### ReservationsInfoListView (Line 12)

**Context:**

```swift
import Foundation
import SwipeActions

struct ReservationsInfoListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

```

**Suggested Documentation:**

```swift
/// ReservationsInfoListView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### ReservationRows (Line 238)

**Context:**

```swift
    }
}

struct ReservationRows: View {
    let reservation: Reservation
    var onSelected: (Reservation) -> Void
    var body: some View {
```

**Suggested Documentation:**

```swift
/// ReservationRows class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (8)

### loadReservations (Line 135)

**Context:**

```swift
        }
    }
    
    private func loadReservations() {
        isLoading = true
        Task {
            do {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByCategory (Line 152)

**Context:**

```swift
        }
    }
    
    private func groupByCategory(_ activeReservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByCategory method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### reservations (Line 172)

**Context:**

```swift
        return grouped
    }
    
    func reservations(at date: Date) -> [Reservation] {
        return env.resCache.reservations(for: date)
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the reservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### filterReservations (Line 176)

**Context:**

```swift
        return env.resCache.reservations(for: date)
    }
    
    func filterReservations(_ reservations: [Reservation]) -> [Reservation] {
        reservations.filter { reservation in
            return reservation.status != .canceled && reservation.reservationType != .waitingList
        }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the filterReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleCancelled (Line 182)

**Context:**

```swift
        }
    }
    
    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            withAnimation {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleCancelled method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### showReservationInTime (Line 206)

**Context:**

```swift
    }
    
    
    private func showReservationInTime(_ reservation: Reservation) {
        if let reservationStart = reservation.startTimeDate {
            let combinedDate = DateHelper.combine(date: appState.selectedDate, time: reservationStart)
            
```

**Suggested Documentation:**

```swift
/// [Add a description of what the showReservationInTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### markReservationStatus (Line 214)

**Context:**

```swift
        }
    }
    
    private func markReservationStatus(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .pending || updatedReservation.status == .late {
            updatedReservation.status = .showedUp
```

**Suggested Documentation:**

```swift
/// [Add a description of what the markReservationStatus method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### statusIcon (Line 280)

**Context:**

```swift
        .padding(.vertical, 4)
    }
    
    private func statusIcon(for status: Reservation.ReservationStatus) -> String {
        switch status {
        case .showedUp: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the statusIcon method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (23)

### env (Line 13)

**Context:**

```swift
import SwipeActions

struct ReservationsInfoListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 14)

**Context:**

```swift

struct ReservationsInfoListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### selection (Line 16)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the selection property]
```

### isLoading (Line 17)

**Context:**

```swift
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the isLoading property]
```

### colorScheme (Line 18)

**Context:**

```swift

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### onClose (Line 19)

**Context:**

```swift
    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
    
```

**Suggested Documentation:**

```swift
/// [Description of the onClose property]
```

### onEdit (Line 20)

**Context:**

```swift
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
    
    
```

**Suggested Documentation:**

```swift
/// [Description of the onEdit property]
```

### onCancelled (Line 21)

**Context:**

```swift
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
    
    
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the onCancelled property]
```

### body (Line 24)

**Context:**

```swift
    var onCancelled: (Reservation) -> Void
    
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading reservations...")
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### reservations (Line 31)

**Context:**

```swift
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    let reservations = reservations(at: appState.selectedDate)
                    let filtered = filterReservations(reservations)
                    let grouped = groupByCategory(filtered)
                    
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### filtered (Line 32)

**Context:**

```swift
            } else {
                List(selection: $selection) {
                    let reservations = reservations(at: appState.selectedDate)
                    let filtered = filterReservations(reservations)
                    let grouped = groupByCategory(filtered)
                    
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
```

**Suggested Documentation:**

```swift
/// [Description of the filtered property]
```

### grouped (Line 33)

**Context:**

```swift
                List(selection: $selection) {
                    let reservations = reservations(at: appState.selectedDate)
                    let filtered = filterReservations(reservations)
                    let grouped = groupByCategory(filtered)
                    
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                        Section(
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### reservationsInGroup (Line 50)

**Context:**

```swift
                            .background(.clear)
                            .padding(.vertical, 4)
                        ) {
                            if let reservationsInGroup = grouped[groupKey] {
                                ForEach(reservationsInGroup) { reservation in
                                    SwipeView {
                                        ReservationRows(
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsInGroup property]
```

### grouped (Line 155)

**Context:**

```swift
    private func groupByCategory(_ activeReservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
        for reservation in activeReservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### category (Line 159)

**Context:**

```swift
        for reservation in activeReservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
            var category: Reservation.ReservationCategory = .lunch
           
            if reservation.category == .dinner {
                category = .dinner
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### key (Line 165)

**Context:**

```swift
                category = .dinner
            }

            let key = "\(category.localized.uppercased())"
            grouped[key, default: []].append(reservation)
        }

```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### updatedReservation (Line 183)

**Context:**

```swift
    }
    
    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            withAnimation {
                updatedReservation.status = .canceled
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### reservationStart (Line 207)

**Context:**

```swift
    
    
    private func showReservationInTime(_ reservation: Reservation) {
        if let reservationStart = reservation.startTimeDate {
            let combinedDate = DateHelper.combine(date: appState.selectedDate, time: reservationStart)
            
            appState.selectedDate = combinedDate
```

**Suggested Documentation:**

```swift
/// [Description of the reservationStart property]
```

### combinedDate (Line 208)

**Context:**

```swift
    
    private func showReservationInTime(_ reservation: Reservation) {
        if let reservationStart = reservation.startTimeDate {
            let combinedDate = DateHelper.combine(date: appState.selectedDate, time: reservationStart)
            
            appState.selectedDate = combinedDate
        }
```

**Suggested Documentation:**

```swift
/// [Description of the combinedDate property]
```

### updatedReservation (Line 215)

**Context:**

```swift
    }
    
    private func markReservationStatus(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .pending || updatedReservation.status == .late {
            updatedReservation.status = .showedUp
        }
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### reservation (Line 239)

**Context:**

```swift
}

struct ReservationRows: View {
    let reservation: Reservation
    var onSelected: (Reservation) -> Void
    var body: some View {
         
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### onSelected (Line 240)

**Context:**

```swift

struct ReservationRows: View {
    let reservation: Reservation
    var onSelected: (Reservation) -> Void
    var body: some View {
         
        VStack(spacing: 12) {
```

**Suggested Documentation:**

```swift
/// [Description of the onSelected property]
```

### body (Line 241)

**Context:**

```swift
struct ReservationRows: View {
    let reservation: Reservation
    var onSelected: (Reservation) -> Void
    var body: some View {
         
        VStack(spacing: 12) {
            HStack {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```


Total documentation suggestions: 33

