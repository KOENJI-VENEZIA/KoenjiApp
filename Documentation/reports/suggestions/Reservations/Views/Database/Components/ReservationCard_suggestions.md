Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Database/Components/ReservationCard.swift...
# Documentation Suggestions for ReservationCard.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Database/Components/ReservationCard.swift
Total suggestions: 35

## Class Documentation (4)

### ReservationCard (Line 5)

**Context:**

```swift
import SwipeActions
import OSLog

struct ReservationCard: View {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ReservationCard"
```

**Suggested Documentation:**

```swift
/// ReservationCard class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 194)

**Context:**

```swift
}

// MARK: - Color Extensions
extension Reservation.ReservationStatus {
    var color: Color {
        switch self {
        case .pending: return .blue
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 209)

**Context:**

```swift
    }
}

extension Reservation.ReservationCategory {
    var color: Color {
        switch self {
        case .lunch: return .orange
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Reservation (Line 219)

**Context:**

```swift
    }
}

extension Reservation.ReservationType {
    var color: Color {
        switch self {
        case .inAdvance: return .blue
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (2)

### detailRow (Line 145)

**Context:**

```swift
            .clipShape(Capsule())
    }
    
    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the detailRow method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### highlightedText (Line 171)

**Context:**

```swift
    }
    
    // Add highlighting function
    private func highlightedText(for text: String, with searchText: String) -> Text {
        guard !searchText.isEmpty else { return Text(text) }
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the highlightedText method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (29)

### logger (Line 6)

**Context:**

```swift
import OSLog

struct ReservationCard: View {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ReservationCard"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### reservation (Line 11)

**Context:**

```swift
        category: "ReservationCard"
    )
    
    let reservation: Reservation
    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### notesAlertShown (Line 12)

**Context:**

```swift
    )
    
    let reservation: Reservation
    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
    
```

**Suggested Documentation:**

```swift
/// [Description of the notesAlertShown property]
```

### notesToShow (Line 13)

**Context:**

```swift
    
    let reservation: Reservation
    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
    
    let onTap: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the notesToShow property]
```

### currentReservation (Line 14)

**Context:**

```swift
    let reservation: Reservation
    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
    
    let onTap: () -> Void
    let onCancel: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservation property]
```

### onTap (Line 16)

**Context:**

```swift
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
    
    let onTap: () -> Void
    let onCancel: () -> Void
    let onRecover: () -> Void
    let onDelete: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the onTap property]
```

### onCancel (Line 17)

**Context:**

```swift
    @Binding var currentReservation: Reservation?
    
    let onTap: () -> Void
    let onCancel: () -> Void
    let onRecover: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the onCancel property]
```

### onRecover (Line 18)

**Context:**

```swift
    
    let onTap: () -> Void
    let onCancel: () -> Void
    let onRecover: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let searchText: String
```

**Suggested Documentation:**

```swift
/// [Description of the onRecover property]
```

### onDelete (Line 19)

**Context:**

```swift
    let onTap: () -> Void
    let onCancel: () -> Void
    let onRecover: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let searchText: String
    
```

**Suggested Documentation:**

```swift
/// [Description of the onDelete property]
```

### onEdit (Line 20)

**Context:**

```swift
    let onCancel: () -> Void
    let onRecover: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let searchText: String
    
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the onEdit property]
```

### searchText (Line 21)

**Context:**

```swift
    let onRecover: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let searchText: String
    
    var body: some View {
        SwipeView {
```

**Suggested Documentation:**

```swift
/// [Description of the searchText property]
```

### body (Line 23)

**Context:**

```swift
    let onEdit: () -> Void
    let searchText: String
    
    var body: some View {
        SwipeView {
            cardContent
        } trailingActions: { _ in
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### cardContent (Line 57)

**Context:**

```swift
        .swipeActionsMaskCornerRadius(12)
    }
    
    private var cardContent: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 16) {
                // Main content column
```

**Suggested Documentation:**

```swift
/// [Description of the cardContent property]
```

### notes (Line 89)

**Context:**

```swift
                .frame(width: geometry.size.width * 0.55, alignment: .leading)
                
                // Notes column (if present)
                if let notes = reservation.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Note", systemImage: "note.text")
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### statusBadge (Line 115)

**Context:**

```swift
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusBadge: some View {
        Text(reservation.status.localized)
            .font(.caption2)
            .padding(.horizontal, 6)
```

**Suggested Documentation:**

```swift
/// [Description of the statusBadge property]
```

### categoryBadge (Line 125)

**Context:**

```swift
            .clipShape(Capsule())
    }
    
    private var categoryBadge: some View {
        Text(reservation.category.localized)
            .font(.caption2)
            .padding(.horizontal, 6)
```

**Suggested Documentation:**

```swift
/// [Description of the categoryBadge property]
```

### typeBadge (Line 135)

**Context:**

```swift
            .clipShape(Capsule())
    }
    
    private var typeBadge: some View {
        Text(reservation.reservationType.localized)
            .font(.caption2)
            .padding(.horizontal, 6)
```

**Suggested Documentation:**

```swift
/// [Description of the typeBadge property]
```

### cardBackground (Line 156)

**Context:**

```swift
        }
    }
    
    private var cardBackground: some View {
        Group {
            if reservation.status == .canceled {
                Color.gray.opacity(0.2)
```

**Suggested Documentation:**

```swift
/// [Description of the cardBackground property]
```

### lowercasedText (Line 173)

**Context:**

```swift
    // Add highlighting function
    private func highlightedText(for text: String, with searchText: String) -> Text {
        guard !searchText.isEmpty else { return Text(text) }
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
```

**Suggested Documentation:**

```swift
/// [Description of the lowercasedText property]
```

### lowercasedSearchText (Line 174)

**Context:**

```swift
    private func highlightedText(for text: String, with searchText: String) -> Text {
        guard !searchText.isEmpty else { return Text(text) }
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        
```

**Suggested Documentation:**

```swift
/// [Description of the lowercasedSearchText property]
```

### highlighted (Line 175)

**Context:**

```swift
        guard !searchText.isEmpty else { return Text(text) }
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedSearchText,
```

**Suggested Documentation:**

```swift
/// [Description of the highlighted property]
```

### currentIndex (Line 176)

**Context:**

```swift
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedSearchText,
                                              range: currentIndex..<lowercasedText.endIndex) {
```

**Suggested Documentation:**

```swift
/// [Description of the currentIndex property]
```

### range (Line 178)

**Context:**

```swift
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedSearchText,
                                              range: currentIndex..<lowercasedText.endIndex) {
            let prefix = String(text[currentIndex..<range.lowerBound])
            highlighted = highlighted + Text(prefix)
```

**Suggested Documentation:**

```swift
/// [Description of the range property]
```

### prefix (Line 180)

**Context:**

```swift
        
        while let range = lowercasedText.range(of: lowercasedSearchText,
                                              range: currentIndex..<lowercasedText.endIndex) {
            let prefix = String(text[currentIndex..<range.lowerBound])
            highlighted = highlighted + Text(prefix)
            let match = String(text[range])
            highlighted = highlighted + Text(match).foregroundColor(.yellow)
```

**Suggested Documentation:**

```swift
/// [Description of the prefix property]
```

### match (Line 182)

**Context:**

```swift
                                              range: currentIndex..<lowercasedText.endIndex) {
            let prefix = String(text[currentIndex..<range.lowerBound])
            highlighted = highlighted + Text(prefix)
            let match = String(text[range])
            highlighted = highlighted + Text(match).foregroundColor(.yellow)
            currentIndex = range.upperBound
        }
```

**Suggested Documentation:**

```swift
/// [Description of the match property]
```

### suffix (Line 187)

**Context:**

```swift
            currentIndex = range.upperBound
        }
        
        let suffix = String(text[currentIndex..<lowercasedText.endIndex])
        highlighted = highlighted + Text(suffix)
        return highlighted
    }
```

**Suggested Documentation:**

```swift
/// [Description of the suffix property]
```

### color (Line 195)

**Context:**

```swift

// MARK: - Color Extensions
extension Reservation.ReservationStatus {
    var color: Color {
        switch self {
        case .pending: return .blue
        case .showedUp: return .green
```

**Suggested Documentation:**

```swift
/// [Description of the color property]
```

### color (Line 210)

**Context:**

```swift
}

extension Reservation.ReservationCategory {
    var color: Color {
        switch self {
        case .lunch: return .orange
        case .dinner: return .indigo
```

**Suggested Documentation:**

```swift
/// [Description of the color property]
```

### color (Line 220)

**Context:**

```swift
}

extension Reservation.ReservationType {
    var color: Color {
        switch self {
        case .inAdvance: return .blue
        case .walkIn: return .green
```

**Suggested Documentation:**

```swift
/// [Description of the color property]
```


Total documentation suggestions: 35

