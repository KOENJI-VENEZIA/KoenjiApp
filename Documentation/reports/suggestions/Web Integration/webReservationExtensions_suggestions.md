Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/webReservationExtensions.swift...
# Documentation Suggestions for webReservationExtensions.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/webReservationExtensions.swift
Total suggestions: 39

## Class Documentation (9)

### Reservation (Line 12)

**Context:**

```swift
import OSLog

// Extension to add visual distinction for web reservations
extension Reservation {
    
    var isWebReservation: Bool {
        guard let notes = notes else { return false }
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationCard (Line 39)

**Context:**

```swift
}

// Add web reservation badge to ReservationCard
extension ReservationCard {
    @ViewBuilder
    func webReservationBadge(for reservation: Reservation) -> some View {
        if reservation.isWebReservation {
```

**Suggested Documentation:**

```swift
/// ReservationCard class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationInfoCard (Line 55)

**Context:**

```swift
}

// Extension to ReservationInfoCard to add web-specific actions
extension ReservationInfoCard {
    @ViewBuilder
    func webReservationActions(for reservation: Reservation) -> some View {
        if reservation.isWebReservation && reservation.acceptance == .toConfirm {
```

**Suggested Documentation:**

```swift
/// ReservationInfoCard class.
///
/// [Add a description of what this class does and its responsibilities]
```

### to (Line 127)

**Context:**

```swift
    }
}

// Add extension to ReservationCard to display web reservation badges
extension ReservationCard {
    var webReservationIndicator: some View {
        Group {
```

**Suggested Documentation:**

```swift
/// to class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationCard (Line 128)

**Context:**

```swift
}

// Add extension to ReservationCard to display web reservation badges
extension ReservationCard {
    var webReservationIndicator: some View {
        Group {
            if reservation.isWebReservation {
```

**Suggested Documentation:**

```swift
/// ReservationCard class.
///
/// [Add a description of what this class does and its responsibilities]
```

### WebReservationModifier (Line 160)

**Context:**

```swift
}

// View modifier to add visual distinction for web reservations
struct WebReservationModifier: ViewModifier {
    let reservation: Reservation
    
    func body(content: Content) -> some View {
```

**Suggested Documentation:**

```swift
/// WebReservationModifier class.
///
/// [Add a description of what this class does and its responsibilities]
```

### View (Line 214)

**Context:**

```swift
}

// Extension to make the modifier easier to use
extension View {
    func webReservationStyle(for reservation: Reservation) -> some View {
        self.modifier(WebReservationModifier(reservation: reservation))
    }
```

**Suggested Documentation:**

```swift
/// View view.
///
/// [Add a description of what this view does and its responsibilities]
```

### DatabaseView (Line 221)

**Context:**

```swift
}

// Extension to DatabaseView to add web reservation filter and badge
extension DatabaseView {
    // Enhanced web reservation filter with improved visual feedback

    var webReservationFilter: some View {
```

**Suggested Documentation:**

```swift
/// DatabaseView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### DatabaseView (Line 273)

**Context:**

```swift


// Update the filterReservations function to handle web reservations
extension DatabaseView {
    // Updated filterReservationsExpanded function that properly handles web reservations

    func filterReservationsExpanded(
```

**Suggested Documentation:**

```swift
/// DatabaseView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (6)

### webReservationBadge (Line 41)

**Context:**

```swift
// Add web reservation badge to ReservationCard
extension ReservationCard {
    @ViewBuilder
    func webReservationBadge(for reservation: Reservation) -> some View {
        if reservation.isWebReservation {
            Text("Web")
                .font(.caption2)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the webReservationBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### webReservationActions (Line 57)

**Context:**

```swift
// Extension to ReservationInfoCard to add web-specific actions
extension ReservationInfoCard {
    @ViewBuilder
    func webReservationActions(for reservation: Reservation) -> some View {
        if reservation.isWebReservation && reservation.acceptance == .toConfirm {
            VStack(spacing: 12) {
                Divider()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the webReservationActions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### approveReservation (Line 108)

**Context:**

```swift
        }
    }
    
    private func approveReservation(_ reservation: Reservation) async {
        isApproving = true
        
        Task {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the approveReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### body (Line 163)

**Context:**

```swift
struct WebReservationModifier: ViewModifier {
    let reservation: Reservation
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the body method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### webReservationStyle (Line 215)

**Context:**

```swift

// Extension to make the modifier easier to use
extension View {
    func webReservationStyle(for reservation: Reservation) -> some View {
        self.modifier(WebReservationModifier(reservation: reservation))
    }
}
```

**Suggested Documentation:**

```swift
/// [Add a description of what the webReservationStyle method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### filterReservationsExpanded (Line 276)

**Context:**

```swift
extension DatabaseView {
    // Updated filterReservationsExpanded function that properly handles web reservations

    func filterReservationsExpanded(
        filters: Set<FilterOption>,
        searchText: String,
        currentReservations: [Reservation]
```

**Suggested Documentation:**

```swift
/// [Add a description of what the filterReservationsExpanded method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (24)

### isWebReservation (Line 14)

**Context:**

```swift
// Extension to add visual distinction for web reservations
extension Reservation {
    
    var isWebReservation: Bool {
        guard let notes = notes else { return false }
        Self.logger.debug("\(notes)")
        return notes.contains("web reservation")
```

**Suggested Documentation:**

```swift
/// [Description of the isWebReservation property]
```

### notes (Line 15)

**Context:**

```swift
extension Reservation {
    
    var isWebReservation: Bool {
        guard let notes = notes else { return false }
        Self.logger.debug("\(notes)")
        return notes.contains("web reservation")
    }
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### hasEmail (Line 20)

**Context:**

```swift
        return notes.contains("web reservation")
    }
    
    var hasEmail: Bool {
        return notes?.contains("Email:") ?? false
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the hasEmail property]
```

### emailAddress (Line 24)

**Context:**

```swift
        return notes?.contains("Email:") ?? false
    }
    
    var emailAddress: String? {
        guard let notes = notes else { return nil }
        
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
```

**Suggested Documentation:**

```swift
/// [Description of the emailAddress property]
```

### notes (Line 25)

**Context:**

```swift
    }
    
    var emailAddress: String? {
        guard let notes = notes else { return nil }
        
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### emailRegex (Line 27)

**Context:**

```swift
    var emailAddress: String? {
        guard let notes = notes else { return nil }
        
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range),
              let emailRange = Range(match.range(at: 1), in: notes) else {
```

**Suggested Documentation:**

```swift
/// [Description of the emailRegex property]
```

### range (Line 28)

**Context:**

```swift
        guard let notes = notes else { return nil }
        
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range),
              let emailRange = Range(match.range(at: 1), in: notes) else {
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the range property]
```

### match (Line 29)

**Context:**

```swift
        
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range),
              let emailRange = Range(match.range(at: 1), in: notes) else {
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the match property]
```

### emailRange (Line 30)

**Context:**

```swift
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range),
              let emailRange = Range(match.range(at: 1), in: notes) else {
            return nil
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the emailRange property]
```

### updatedReservation (Line 87)

**Context:**

```swift
                
                Button(action: {
                    // Logic to decline the reservation
                    let updatedReservation = env.reservationService.separateReservation(
                        reservation, 
                        notesToAdd: "Declined web reservation"
                    )
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### success (Line 112)

**Context:**

```swift
        isApproving = true
        
        Task {
            let success = await env.reservationService.approveWebReservation(reservation)
            
            await MainActor.run {
                isApproving = false
```

**Suggested Documentation:**

```swift
/// [Description of the success property]
```

### webReservationIndicator (Line 129)

**Context:**

```swift

// Add extension to ReservationCard to display web reservation badges
extension ReservationCard {
    var webReservationIndicator: some View {
        Group {
            if reservation.isWebReservation {
                HStack(spacing: 4) {
```

**Suggested Documentation:**

```swift
/// [Description of the webReservationIndicator property]
```

### reservation (Line 161)

**Context:**

```swift

// View modifier to add visual distinction for web reservations
struct WebReservationModifier: ViewModifier {
    let reservation: Reservation
    
    func body(content: Content) -> some View {
        content
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### webReservationFilter (Line 224)

**Context:**

```swift
extension DatabaseView {
    // Enhanced web reservation filter with improved visual feedback

    var webReservationFilter: some View {
        Button(action: {
            // Clear other filters when toggling web pending to avoid filter conflicts
            if env.listView.selectedFilters.contains(.webPending) {
```

**Suggested Documentation:**

```swift
/// [Description of the webReservationFilter property]
```

### filtered (Line 281)

**Context:**

```swift
        searchText: String,
        currentReservations: [Reservation]
    ) -> [Reservation] {
        var filtered = currentReservations
        
        // Case 1: If ".webPending" is the only filter or one of the filters
        if filters.contains(.webPending) {
```

**Suggested Documentation:**

```swift
/// [Description of the filtered property]
```

### date (Line 308)

**Context:**

```swift
            }
            if filters.contains(.date), !filters.contains(.none) {
                filtered = filtered.filter { reservation in
                    if let date = reservation.normalizedDate {
                        return date >= filterStartDate && date <= filterEndDate
                    }
                    return false
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### matches (Line 318)

**Context:**

```swift
        // Case 2: Other filters are applied but not ".webPending"
        else if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the matches property]
```

### date (Line 335)

**Context:**

```swift
                    matches = matches && (reservation.numberOfPersons == filterPeople)
                }
                if filters.contains(.date) {
                    if let date = reservation.normalizedDate {
                        matches = matches && (date >= filterStartDate && date <= filterEndDate)
                    } else {
                        matches = false
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### lowercasedSearchText (Line 357)

**Context:**

```swift
        
        // Apply search text filter regardless of other filters
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
```

**Suggested Documentation:**

```swift
/// [Description of the lowercasedSearchText property]
```

### nameMatch (Line 359)

**Context:**

```swift
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
```

**Suggested Documentation:**

```swift
/// [Description of the nameMatch property]
```

### tableMatch (Line 360)

**Context:**

```swift
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the tableMatch property]
```

### notesMatch (Line 364)

**Context:**

```swift
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                let emailMatch = reservation.emailAddress?.lowercased().contains(lowercasedSearchText) ?? false
                let phoneMatch = reservation.phone.lowercased().contains(lowercasedSearchText)
                
```

**Suggested Documentation:**

```swift
/// [Description of the notesMatch property]
```

### emailMatch (Line 365)

**Context:**

```swift
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                let emailMatch = reservation.emailAddress?.lowercased().contains(lowercasedSearchText) ?? false
                let phoneMatch = reservation.phone.lowercased().contains(lowercasedSearchText)
                
                return nameMatch || tableMatch || notesMatch || emailMatch || phoneMatch
```

**Suggested Documentation:**

```swift
/// [Description of the emailMatch property]
```

### phoneMatch (Line 366)

**Context:**

```swift
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                let emailMatch = reservation.emailAddress?.lowercased().contains(lowercasedSearchText) ?? false
                let phoneMatch = reservation.phone.lowercased().contains(lowercasedSearchText)
                
                return nameMatch || tableMatch || notesMatch || emailMatch || phoneMatch
            }
```

**Suggested Documentation:**

```swift
/// [Description of the phoneMatch property]
```


Total documentation suggestions: 39

