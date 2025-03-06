Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationInfoCard.swift...
# Documentation Suggestions for ReservationInfoCard.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationInfoCard.swift
Total suggestions: 36

## Class Documentation (1)

### ReservationInfoCard (Line 10)

**Context:**

```swift

import SwiftUI

struct ReservationInfoCard: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
```

**Suggested Documentation:**

```swift
/// ReservationInfoCard class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (8)

### loadReservation (Line 201)

**Context:**

```swift
        }
    }
    
    private func loadReservation() {
        isLoading = true
        
        // First check the cache for the reservation
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### detailTag (Line 234)

**Context:**

```swift
        }
    }
    
    private func detailTag(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the detailTag method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### multilineDetailTag (Line 259)

**Context:**

```swift
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func multilineDetailTag(icon: String, title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the multilineDetailTag method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### statusBadge (Line 286)

**Context:**

```swift
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusBadge(status: Reservation.ReservationStatus) -> some View {
        Label {
            Text(status.localized)
                .font(.caption.weight(.semibold))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the statusBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### categoryBadge (Line 303)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func categoryBadge(category: Reservation.ReservationCategory) -> some View {
        Label {
            Text(category.localized)
                .font(.caption.weight(.semibold))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the categoryBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### typeBadge (Line 317)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func typeBadge(type: Reservation.ReservationType) -> some View {
        Label {
            Text(type.localized)
                .font(.caption.weight(.semibold))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the typeBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### fullScreenImageView (Line 331)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func fullScreenImageView(_ image: Image) -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the fullScreenImageView method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateDuration (Line 354)

**Context:**

```swift
        }
    }
    
    private func calculateDuration(start: String, end: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateDuration method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (27)

### env (Line 11)

**Context:**

```swift
import SwiftUI

struct ReservationInfoCard: View {
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

struct ReservationInfoCard: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView

    let reservationID: UUID
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### unitView (Line 13)

**Context:**

```swift
struct ReservationInfoCard: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView

    let reservationID: UUID
    var onClose: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### reservationID (Line 15)

**Context:**

```swift
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView

    let reservationID: UUID
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onApprove: (() -> Void)?
```

**Suggested Documentation:**

```swift
/// [Description of the reservationID property]
```

### onClose (Line 16)

**Context:**

```swift
    @Environment(LayoutUnitViewModel.self) var unitView

    let reservationID: UUID
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onApprove: (() -> Void)?

```

**Suggested Documentation:**

```swift
/// [Description of the onClose property]
```

### onEdit (Line 17)

**Context:**

```swift

    let reservationID: UUID
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onApprove: (() -> Void)?

    @State var isApproving = false
```

**Suggested Documentation:**

```swift
/// [Description of the onEdit property]
```

### onApprove (Line 18)

**Context:**

```swift
    let reservationID: UUID
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onApprove: (() -> Void)?

    @State var isApproving = false
    @State var showingAlert = false
```

**Suggested Documentation:**

```swift
/// [Description of the onApprove property]
```

### isApproving (Line 20)

**Context:**

```swift
    var onEdit: (Reservation) -> Void
    var onApprove: (() -> Void)?

    @State var isApproving = false
    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var reservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the isApproving property]
```

### showingAlert (Line 21)

**Context:**

```swift
    var onApprove: (() -> Void)?

    @State var isApproving = false
    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var reservation: Reservation?
    @State private var isLoading = true
```

**Suggested Documentation:**

```swift
/// [Description of the showingAlert property]
```

### alertMessage (Line 22)

**Context:**

```swift

    @State var isApproving = false
    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var reservation: Reservation?
    @State private var isLoading = true

```

**Suggested Documentation:**

```swift
/// [Description of the alertMessage property]
```

### reservation (Line 23)

**Context:**

```swift
    @State var isApproving = false
    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var reservation: Reservation?
    @State private var isLoading = true

    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### isLoading (Line 24)

**Context:**

```swift
    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var reservation: Reservation?
    @State private var isLoading = true

    var body: some View {
        Group {
```

**Suggested Documentation:**

```swift
/// [Description of the isLoading property]
```

### body (Line 26)

**Context:**

```swift
    @State private var reservation: Reservation?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading reservation details...")
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### reservation (Line 31)

**Context:**

```swift
            if isLoading {
                ProgressView("Loading reservation details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let reservation = reservation {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### columns (Line 57)

**Context:**

```swift
                                    .padding(.vertical, 8)
                                
                                // Primary info with icons in a grid
                                let columns = [
                                    GridItem(.adaptive(minimum: 180, maximum: .infinity), spacing: 12)
                                ]
                                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
```

**Suggested Documentation:**

```swift
/// [Description of the columns property]
```

### notes (Line 107)

**Context:**

```swift
                                }
                                
                                // Notes section if present
                                if let notes = reservation.notes {
                                    Divider()
                                        .padding(.vertical, 8)
                                    multilineDetailTag(
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### image (Line 119)

**Context:**

```swift
                                }
                                
                                // Image section if present
                                if let image = reservation.image {
                                    Divider()
                                        .padding(.vertical, 8)
                                    VStack(alignment: .leading, spacing: 12) {
```

**Suggested Documentation:**

```swift
/// [Description of the image property]
```

### image (Line 170)

**Context:**

```swift
                    get: { unitView.isShowingFullImage },
                    set: { unitView.isShowingFullImage = $0 }
                )) {
                    if let image = reservation.image {
                        fullScreenImageView(image)
                    }
                }
```

**Suggested Documentation:**

```swift
/// [Description of the image property]
```

### found (Line 206)

**Context:**

```swift
        
        // First check the cache for the reservation
        for (_, reservations) in env.resCache.cache {
            if let found = reservations.first(where: { $0.id == reservationID }) {
                self.reservation = found
                isLoading = false
                return
```

**Suggested Documentation:**

```swift
/// [Description of the found property]
```

### reservations (Line 217)

**Context:**

```swift
        Task {
            do {
                // Try to fetch reservations for the current date
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    if let found = reservations.first(where: { $0.id == reservationID }) {
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### found (Line 220)

**Context:**

```swift
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    if let found = reservations.first(where: { $0.id == reservationID }) {
                        self.reservation = found
                    }
                    isLoading = false
```

**Suggested Documentation:**

```swift
/// [Description of the found property]
```

### formatter (Line 355)

**Context:**

```swift
    }
    
    private func calculateDuration(start: String, end: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startDate = formatter.date(from: start),
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### startDate (Line 358)

**Context:**

```swift
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            return "N/A"
        }
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### endDate (Line 359)

**Context:**

```swift
        formatter.dateFormat = "HH:mm"
        
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            return "N/A"
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the endDate property]
```

### diffComponents (Line 363)

**Context:**

```swift
            return "N/A"
        }
        
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = diffComponents.hour ?? 0
        let minutes = diffComponents.minute ?? 0
        
```

**Suggested Documentation:**

```swift
/// [Description of the diffComponents property]
```

### hours (Line 364)

**Context:**

```swift
        }
        
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = diffComponents.hour ?? 0
        let minutes = diffComponents.minute ?? 0
        
        if hours == 0 {
```

**Suggested Documentation:**

```swift
/// [Description of the hours property]
```

### minutes (Line 365)

**Context:**

```swift
        
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = diffComponents.hour ?? 0
        let minutes = diffComponents.minute ?? 0
        
        if hours == 0 {
            return "\(minutes)m"
```

**Suggested Documentation:**

```swift
/// [Description of the minutes property]
```


Total documentation suggestions: 36

