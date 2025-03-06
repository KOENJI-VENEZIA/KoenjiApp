Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Layout/TableView.swift...
# Documentation Suggestions for TableView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Layout/TableView.swift
Total suggestions: 103

## Class Documentation (5)

### DragState (Line 7)

**Context:**

```swift

// MARK: - Drag State

enum DragState: Equatable {
    case idle
    case dragging(offset: CGSize)
    case started(offset: CGSize)
```

**Suggested Documentation:**

```swift
/// DragState class.
///
/// [Add a description of what this class does and its responsibilities]
```

### TableView (Line 15)

**Context:**

```swift

// MARK: - Main TableView

struct TableView: View {
    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
```

**Suggested Documentation:**

```swift
/// TableView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### TableView (Line 162)

**Context:**

```swift

// MARK: - Main Content & Overlay Subviews

extension TableView {
    /// Combines the background shape, stroke overlay, marks, and text overlays.
    private func mainContent(fillColor: Color, idSuffix: String) -> some View {
        ZStack {
```

**Suggested Documentation:**

```swift
/// TableView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### TableView (Line 501)

**Context:**

```swift

// MARK: - Gesture Definitions

extension TableView {
    private var combinedGestures: some Gesture {
        doubleTapGesture()
            .exclusively(
```

**Suggested Documentation:**

```swift
/// TableView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### TableView (Line 563)

**Context:**

```swift

// MARK: - Helper Methods & Reservation Updates

extension TableView {
    private func updateTableVisibility() {
        print("DEBUG: updating table visibility")
        print("DEBUG: clusters \(clusters)")
```

**Suggested Documentation:**

```swift
/// TableView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (23)

### showedUpMark (Line 333)

**Context:**

```swift
    }

    // MARK: - Mark Subviews
    private func showedUpMark() -> some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the showedUpMark method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### emojiMark (Line 343)

**Context:**

```swift
            .zIndex(2)
    }

    private func emojiMark(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 20))
            .frame(maxWidth: 23, maxHeight: 23)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the emojiMark method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### nearEndMark (Line 351)

**Context:**

```swift
            .zIndex(2)
    }

    private func nearEndMark() -> some View {
        Image(systemName: "figure.walk.motion.trianglebadge.exclamationmark")
            .resizable()
            .scaledToFit()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the nearEndMark method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### lateMark (Line 362)

**Context:**

```swift
            .zIndex(4)
    }

    private func lateMark() -> some View {
        Image(systemName: "clock.badge.exclamationmark.fill")
            .resizable()
            .scaledToFit()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the lateMark method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### reservationInfo (Line 375)

**Context:**

```swift

    // MARK: - Reservation Text Overlays
    @ViewBuilder
    private func reservationInfo(
        tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        if let reservation = tableView.currentActiveReservation {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the reservationInfo method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### upcomingReservationPlaceholder (Line 441)

**Context:**

```swift
    }

    @ViewBuilder
    private func upcomingReservationPlaceholder(
        tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        if let reservation = tableView.firstUpcomingReservation {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the upcomingReservationPlaceholder method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### tableName (Line 480)

**Context:**

```swift
        }
    }

    private func tableName(name: String, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        VStack {
            Text(name)
                .bold()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the tableName method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### tapGesture (Line 509)

**Context:**

```swift
                    .exclusively(before: dragGesture()))
    }

    private func tapGesture() -> some Gesture {
        TapGesture(count: 1).onEnded {
            tableView.tapTimer?.invalidate()
            tableView.tapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
```

**Suggested Documentation:**

```swift
/// [Add a description of what the tapGesture method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### doubleTapGesture (Line 523)

**Context:**

```swift
        }
    }

    private func doubleTapGesture() -> some Gesture {
        TapGesture(count: 2).onEnded {
            tableView.tapTimer?.invalidate()
            tableView.isDoubleTap = true
```

**Suggested Documentation:**

```swift
/// [Add a description of what the doubleTapGesture method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### dragGesture (Line 535)

**Context:**

```swift
        }
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in
                guard !isLayoutLocked else { return }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the dragGesture method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateTableVisibility (Line 564)

**Context:**

```swift
// MARK: - Helper Methods & Reservation Updates

extension TableView {
    private func updateTableVisibility() {
        print("DEBUG: updating table visibility")
        print("DEBUG: clusters \(clusters)")
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateTableVisibility method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateResData (Line 581)

**Context:**

```swift
        }
    }
    
    private func updateResData(_ date: Date, refreshedKey: String, forceUpdate: Bool = false) {
        updateTableVisibility()
        let now = Date()
        // if we already refreshed in last 0.5 seconds, skip
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateResData method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateRemainingTime (Line 630)

**Context:**

```swift
        }
    }

    private func updateRemainingTime(_ date: Date) {
        cachedRemainingTime = TimeHelpers.remainingTimeString(
            endTime: tableView.currentActiveReservation?.endTimeDate ?? Date(),
            currentTime: date
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateRemainingTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateCachedReservation (Line 657)

**Context:**

```swift
        }
    }

    private func updateCachedReservation(_ date: Date) {
        if let reservation = env.resCache.reservation(
            forTable: table.id, datetime: date, category: appState.selectedCategory),
            reservation.status != .canceled,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateCachedReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateLateReservation (Line 671)

**Context:**

```swift
        }
    }

    private func updateLateReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation,
           env.resCache.lateReservations(currentTime: date).contains(where: { $0.id == reservation.id })
        {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateLateReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateNearEndReservation (Line 693)

**Context:**

```swift
        }
    }

    private func updateNearEndReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation,
            env.resCache.nearingEndReservations(currentTime: date).contains(where: {
                $0.id == reservation.id
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateNearEndReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateFirstUpcoming (Line 705)

**Context:**

```swift
        }
    }

    private func updateFirstUpcoming(_ date: Date) {
        let tableID = table.id
        let category = appState.selectedCategory
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateFirstUpcoming method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleCancelled (Line 725)

**Context:**

```swift
        }
    }

    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            updatedReservation.status = .canceled
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleCancelled method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleEmojiAssignment (Line 747)

**Context:**

```swift
        }
    }

    private func handleEmojiAssignment(_ activeReservation: Reservation?, _ emoji: String) {
        guard var reservationActive = activeReservation else { return }
        print("Emoji: \(emoji)")
        reservationActive.assignedEmoji = emoji
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleEmojiAssignment method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleTap (Line 769)

**Context:**

```swift
        }
    }

    private func handleTap(_ activeReservation: Reservation) {
        var currentReservation = activeReservation
        print("1 - Status in HandleTap: \(currentReservation.status)")
        if currentReservation.status == .pending || currentReservation.status == .late {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleTap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleDoubleTap (Line 814)

**Context:**

```swift
        }
    }

    private func handleDoubleTap() {
        if let reservation = tableView.currentActiveReservation {
            unitView.showInspector = true
            onEditReservation(reservation)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleDoubleTap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleDragEnd (Line 825)

**Context:**

```swift
        }
    }

    private func handleDragEnd(
        translation: CGSize, cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat,
        xPos: CGFloat, yPos: CGFloat
    ) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleDragEnd method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### debounce (Line 895)

**Context:**

```swift
        env.layoutServices.currentlyDraggedTableID = nil
    }

    private func debounce(action: @escaping () -> Void, delay: TimeInterval = 0.1) {
        tableView.debounceWorkItem?.cancel()
        let newWorkItem = DispatchWorkItem { action() }
        tableView.debounceWorkItem = newWorkItem
```

**Suggested Documentation:**

```swift
/// [Add a description of what the debounce method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (75)

### env (Line 17)

**Context:**

```swift

struct TableView: View {
    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @ObservedObject var notifsManager = NotificationManager.shared
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 18)

**Context:**

```swift
struct TableView: View {
    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @ObservedObject var notifsManager = NotificationManager.shared

```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### notifsManager (Line 20)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @ObservedObject var notifsManager = NotificationManager.shared

    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(LayoutUnitViewModel.self) var unitView
```

**Suggested Documentation:**

```swift
/// [Description of the notifsManager property]
```

### layoutUI (Line 22)

**Context:**

```swift

    @ObservedObject var notifsManager = NotificationManager.shared

    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(LayoutUnitViewModel.self) var unitView
    @Environment(\.colorScheme) var colorScheme
    @Environment(ClusterManager.self) var clusterManager
```

**Suggested Documentation:**

```swift
/// [Description of the layoutUI property]
```

### unitView (Line 23)

**Context:**

```swift
    @ObservedObject var notifsManager = NotificationManager.shared

    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(LayoutUnitViewModel.self) var unitView
    @Environment(\.colorScheme) var colorScheme
    @Environment(ClusterManager.self) var clusterManager

```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### colorScheme (Line 24)

**Context:**

```swift

    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(LayoutUnitViewModel.self) var unitView
    @Environment(\.colorScheme) var colorScheme
    @Environment(ClusterManager.self) var clusterManager

    // MARK: Local State & Bindings
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### clusterManager (Line 25)

**Context:**

```swift
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(LayoutUnitViewModel.self) var unitView
    @Environment(\.colorScheme) var colorScheme
    @Environment(ClusterManager.self) var clusterManager

    // MARK: Local State & Bindings
    @State var tableView: TableViewModel = TableViewModel()
```

**Suggested Documentation:**

```swift
/// [Description of the clusterManager property]
```

### tableView (Line 28)

**Context:**

```swift
    @Environment(ClusterManager.self) var clusterManager

    // MARK: Local State & Bindings
    @State var tableView: TableViewModel = TableViewModel()
    private let normalizedTimeCache = NormalizedTimeCache()
    let logger = Logger(subsystem: "com.koenjiapp", category: "TableView")
    let table: TableModel
```

**Suggested Documentation:**

```swift
/// [Description of the tableView property]
```

### normalizedTimeCache (Line 29)

**Context:**

```swift

    // MARK: Local State & Bindings
    @State var tableView: TableViewModel = TableViewModel()
    private let normalizedTimeCache = NormalizedTimeCache()
    let logger = Logger(subsystem: "com.koenjiapp", category: "TableView")
    let table: TableModel
    let clusters: [CachedCluster]
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedTimeCache property]
```

### logger (Line 30)

**Context:**

```swift
    // MARK: Local State & Bindings
    @State var tableView: TableViewModel = TableViewModel()
    private let normalizedTimeCache = NormalizedTimeCache()
    let logger = Logger(subsystem: "com.koenjiapp", category: "TableView")
    let table: TableModel
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### table (Line 31)

**Context:**

```swift
    @State var tableView: TableViewModel = TableViewModel()
    private let normalizedTimeCache = NormalizedTimeCache()
    let logger = Logger(subsystem: "com.koenjiapp", category: "TableView")
    let table: TableModel
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the table property]
```

### clusters (Line 32)

**Context:**

```swift
    private let normalizedTimeCache = NormalizedTimeCache()
    let logger = Logger(subsystem: "com.koenjiapp", category: "TableView")
    let table: TableModel
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the clusters property]
```

### onTapEmpty (Line 33)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "TableView")
    let table: TableModel
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
```

**Suggested Documentation:**

```swift
/// [Description of the onTapEmpty property]
```

### onStatusChange (Line 34)

**Context:**

```swift
    let table: TableModel
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID
```

**Suggested Documentation:**

```swift
/// [Description of the onStatusChange property]
```

### onEditReservation (Line 35)

**Context:**

```swift
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID
    let onTableUpdated: (TableModel) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the onEditReservation property]
```

### isLayoutLocked (Line 36)

**Context:**

```swift
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID
    let onTableUpdated: (TableModel) -> Void

```

**Suggested Documentation:**

```swift
/// [Description of the isLayoutLocked property]
```

### animationNamespace (Line 37)

**Context:**

```swift
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID
    let onTableUpdated: (TableModel) -> Void

    @Binding var statusChanged: Int
```

**Suggested Documentation:**

```swift
/// [Description of the animationNamespace property]
```

### onTableUpdated (Line 38)

**Context:**

```swift
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID
    let onTableUpdated: (TableModel) -> Void

    @Binding var statusChanged: Int

```

**Suggested Documentation:**

```swift
/// [Description of the onTableUpdated property]
```

### statusChanged (Line 40)

**Context:**

```swift
    let animationNamespace: Namespace.ID
    let onTableUpdated: (TableModel) -> Void

    @Binding var statusChanged: Int

    @GestureState private var dragOffset: CGSize = .zero
    @State private var cachedRemainingTime: String?
```

**Suggested Documentation:**

```swift
/// [Description of the statusChanged property]
```

### dragOffset (Line 42)

**Context:**

```swift

    @Binding var statusChanged: Int

    @GestureState private var dragOffset: CGSize = .zero
    @State private var cachedRemainingTime: String?
    @State private var lastRefreshDate: Date? = Date.distantPast

```

**Suggested Documentation:**

```swift
/// [Description of the dragOffset property]
```

### cachedRemainingTime (Line 43)

**Context:**

```swift
    @Binding var statusChanged: Int

    @GestureState private var dragOffset: CGSize = .zero
    @State private var cachedRemainingTime: String?
    @State private var lastRefreshDate: Date? = Date.distantPast

    @State private var isVisible: Bool = true
```

**Suggested Documentation:**

```swift
/// [Description of the cachedRemainingTime property]
```

### lastRefreshDate (Line 44)

**Context:**

```swift

    @GestureState private var dragOffset: CGSize = .zero
    @State private var cachedRemainingTime: String?
    @State private var lastRefreshDate: Date? = Date.distantPast

    @State private var isVisible: Bool = true
    
```

**Suggested Documentation:**

```swift
/// [Description of the lastRefreshDate property]
```

### isVisible (Line 46)

**Context:**

```swift
    @State private var cachedRemainingTime: String?
    @State private var lastRefreshDate: Date? = Date.distantPast

    @State private var isVisible: Bool = true
    
    
    // MARK: Computed Properties
```

**Suggested Documentation:**

```swift
/// [Description of the isVisible property]
```

### cellSize (Line 50)

**Context:**

```swift
    
    
    // MARK: Computed Properties
    private var cellSize: CGFloat { env.gridData.cellSize }

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
```

**Suggested Documentation:**

```swift
/// [Description of the cellSize property]
```

### tableFrame (Line 52)

**Context:**

```swift
    // MARK: Computed Properties
    private var cellSize: CGFloat { env.gridData.cellSize }

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
```

**Suggested Documentation:**

```swift
/// [Description of the tableFrame property]
```

### width (Line 53)

**Context:**

```swift
    private var cellSize: CGFloat { env.gridData.cellSize }

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
```

**Suggested Documentation:**

```swift
/// [Description of the width property]
```

### height (Line 54)

**Context:**

```swift

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
```

**Suggested Documentation:**

```swift
/// [Description of the height property]
```

### xPos (Line 55)

**Context:**

```swift
    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the xPos property]
```

### yPos (Line 56)

**Context:**

```swift
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }

```

**Suggested Documentation:**

```swift
/// [Description of the yPos property]
```

### isHighlighted (Line 60)

**Context:**

```swift
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }

    private var isHighlighted: Bool {
        env.layoutServices.tableAnimationState[table.id] ?? false
    }

```

**Suggested Documentation:**

```swift
/// [Description of the isHighlighted property]
```

### isDragging (Line 64)

**Context:**

```swift
        env.layoutServices.tableAnimationState[table.id] ?? false
    }

    private var isDragging: Bool {
        if case .dragging = tableView.dragState { return true }
        return false
    }
```

**Suggested Documentation:**

```swift
/// [Description of the isDragging property]
```

### body (Line 70)

**Context:**

```swift
    }

    // MARK: - Body
    var body: some View {

        // Determine fill color and an ID suffix for matched geometry
        let (fillColor, idSuffix): (Color, String) = {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### activeRes (Line 74)

**Context:**

```swift

        // Determine fill color and an ID suffix for matched geometry
        let (fillColor, idSuffix): (Color, String) = {
            if isDragging, let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.1), "dragging_1")
            } else if isDragging, tableView.currentActiveReservation == nil {
                return (Color(hex: "#AEAB7D").opacity(0.1), "dragging_2")
```

**Suggested Documentation:**

```swift
/// [Description of the activeRes property]
```

### activeRes (Line 78)

**Context:**

```swift
                return (activeRes.assignedColor.opacity(0.1), "dragging_1")
            } else if isDragging, tableView.currentActiveReservation == nil {
                return (Color(hex: "#AEAB7D").opacity(0.1), "dragging_2")
            } else if let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.2), "reserved")
            } else if isLayoutLocked, let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.2), "locked")
```

**Suggested Documentation:**

```swift
/// [Description of the activeRes property]
```

### activeRes (Line 80)

**Context:**

```swift
                return (Color(hex: "#AEAB7D").opacity(0.1), "dragging_2")
            } else if let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.2), "reserved")
            } else if isLayoutLocked, let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.2), "locked")
            } else {
                return (Color(hex: "#A3B7D2").opacity(0.1), "default")
```

**Suggested Documentation:**

```swift
/// [Description of the activeRes property]
```

### reservations (Line 106)

**Context:**

```swift
            debounceAsync {
                // Fetch reservations asynchronously for the new date
                do {
                    let reservations = try await env.resCache.fetchReservations(for: newDate)
                    
                    await MainActor.run {
                        env.resCache.preloadDates(around: newDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservations (Line 138)

**Context:**

```swift
        .onChange(of: appState.selectedCategory) {
            debounceAsync {
                // Fetch reservations asynchronously for the selected date with the new category
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservation (Line 208)

**Context:**

```swift
            Divider()

            Button("Cancellazione") {
                if let reservation = tableView.currentActiveReservation {
                    handleCancelled(reservation)
                }
            }
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### strokeOverlay (Line 228)

**Context:**

```swift
        }
    }

    private var strokeOverlay: some View {

        Group {

```

**Suggested Documentation:**

```swift
/// [Description of the strokeOverlay property]
```

### reservation (Line 232)

**Context:**

```swift

        Group {

            if let reservation = tableView.currentActiveReservation,
                reservation.id != tableView.nearEndReservation?.id
            {
                RoundedRectangle(cornerRadius: 12.0)
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### reservation (Line 378)

**Context:**

```swift
    private func reservationInfo(
        tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        if let reservation = tableView.currentActiveReservation {
            VStack(spacing: 2) {
                Text(reservation.name)
                    .bold()
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### remaining (Line 394)

**Context:**

```swift
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                if let remaining = cachedRemainingTime {
                    Text("Tempo rimasto:")
                        .bold()
                        .multilineTextAlignment(.center)
```

**Suggested Documentation:**

```swift
/// [Description of the remaining property]
```

### reservation (Line 444)

**Context:**

```swift
    private func upcomingReservationPlaceholder(
        tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        if let reservation = tableView.firstUpcomingReservation {
            VStack(spacing: 2) {
                Text(reservation.name)
                    .bold()
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### upcomingTime (Line 460)

**Context:**

```swift
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                if let upcomingTime = DateHelper.timeUntilReservation(
                    currentTime: appState.selectedDate,
                    reservationDateString: reservation.dateString,
                    reservationStartTimeString: reservation.startTime)
```

**Suggested Documentation:**

```swift
/// [Description of the upcomingTime property]
```

### combinedGestures (Line 502)

**Context:**

```swift
// MARK: - Gesture Definitions

extension TableView {
    private var combinedGestures: some Gesture {
        doubleTapGesture()
            .exclusively(
                before: tapGesture()
```

**Suggested Documentation:**

```swift
/// [Description of the combinedGestures property]
```

### reservation (Line 514)

**Context:**

```swift
            tableView.tapTimer?.invalidate()
            tableView.tapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                Task { @MainActor in
                    if !tableView.isDoubleTap, let reservation = tableView.currentActiveReservation
                    {
                        handleTap(reservation)
                    }
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### now (Line 583)

**Context:**

```swift
    
    private func updateResData(_ date: Date, refreshedKey: String, forceUpdate: Bool = false) {
        updateTableVisibility()
        let now = Date()
        // if we already refreshed in last 0.5 seconds, skip
        guard now.timeIntervalSince(lastRefreshDate ?? Date()) > 0.5 else {
            return
```

**Suggested Documentation:**

```swift
/// [Description of the now property]
```

### formatter (Line 590)

**Context:**

```swift
        }
        lastRefreshDate = now
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")

```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### formattedDate (Line 594)

**Context:**

```swift
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let formattedDate = formatter.string(from: date)
        let key =
            "\(formattedDate)-\(refreshedKey)-\(appState.selectedCategory.rawValue)-\(table.id)"

```

**Suggested Documentation:**

```swift
/// [Description of the formattedDate property]
```

### key (Line 595)

**Context:**

```swift
        formatter.timeZone = TimeZone(identifier: "UTC")

        let formattedDate = formatter.string(from: date)
        let key =
            "\(formattedDate)-\(refreshedKey)-\(appState.selectedCategory.rawValue)-\(table.id)"

        // Check if we need to fetch fresh data from Firebase
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### reservations (Line 603)

**Context:**

```swift
            Task {
                do {
                    // Fetch reservations asynchronously from Firebase
                    let reservations = try await env.resCache.fetchReservations(for: date)
                    
                    // Update the cache with the fetched reservations
                    await MainActor.run {
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservationEnd (Line 636)

**Context:**

```swift
            currentTime: date
        )

        let reservationEnd = tableView.currentActiveReservation?.endTimeDate ?? Date()
        let timeRemaining = reservationEnd.timeIntervalSince(date)
        
        guard let reservation = tableView.currentActiveReservation else { return }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationEnd property]
```

### timeRemaining (Line 637)

**Context:**

```swift
        )

        let reservationEnd = tableView.currentActiveReservation?.endTimeDate ?? Date()
        let timeRemaining = reservationEnd.timeIntervalSince(date)
        
        guard let reservation = tableView.currentActiveReservation else { return }
        
```

**Suggested Documentation:**

```swift
/// [Description of the timeRemaining property]
```

### reservation (Line 639)

**Context:**

```swift
        let reservationEnd = tableView.currentActiveReservation?.endTimeDate ?? Date()
        let timeRemaining = reservationEnd.timeIntervalSince(date)
        
        guard let reservation = tableView.currentActiveReservation else { return }
        
        // Only send near-end notification if time remaining is between 25-30 minutes
        if timeRemaining <= 30 * 60 && timeRemaining > 25 * 60 {
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### reservation (Line 658)

**Context:**

```swift
    }

    private func updateCachedReservation(_ date: Date) {
        if let reservation = env.resCache.reservation(
            forTable: table.id, datetime: date, category: appState.selectedCategory),
            reservation.status != .canceled,
           reservation.status != .deleted,
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### reservation (Line 672)

**Context:**

```swift
    }

    private func updateLateReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation,
           env.resCache.lateReservations(currentTime: date).contains(where: { $0.id == reservation.id })
        {
            tableView.lateReservation = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### reservation (Line 694)

**Context:**

```swift
    }

    private func updateNearEndReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation,
            env.resCache.nearingEndReservations(currentTime: date).contains(where: {
                $0.id == reservation.id
            })
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### tableID (Line 706)

**Context:**

```swift
    }

    private func updateFirstUpcoming(_ date: Date) {
        let tableID = table.id
        let category = appState.selectedCategory
        
        logger.debug("Updating upcoming reservation for table \(tableID) at \(DateHelper.formatDate(date)) in \(category.rawValue) category")
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### category (Line 707)

**Context:**

```swift

    private func updateFirstUpcoming(_ date: Date) {
        let tableID = table.id
        let category = appState.selectedCategory
        
        logger.debug("Updating upcoming reservation for table \(tableID) at \(DateHelper.formatDate(date)) in \(category.rawValue) category")
        
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### reservation (Line 711)

**Context:**

```swift
        
        logger.debug("Updating upcoming reservation for table \(tableID) at \(DateHelper.formatDate(date)) in \(category.rawValue) category")
        
        if let reservation = env.resCache.firstUpcomingReservation(
            forTable: tableID,
            date: date,
            time: date,
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### updatedReservation (Line 726)

**Context:**

```swift
    }

    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            updatedReservation.status = .canceled
        }
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### reservationActive (Line 748)

**Context:**

```swift
    }

    private func handleEmojiAssignment(_ activeReservation: Reservation?, _ emoji: String) {
        guard var reservationActive = activeReservation else { return }
        print("Emoji: \(emoji)")
        reservationActive.assignedEmoji = emoji
        
```

**Suggested Documentation:**

```swift
/// [Description of the reservationActive property]
```

### currentReservation (Line 770)

**Context:**

```swift
    }

    private func handleTap(_ activeReservation: Reservation) {
        var currentReservation = activeReservation
        print("1 - Status in HandleTap: \(currentReservation.status)")
        if currentReservation.status == .pending || currentReservation.status == .late {
            currentReservation.status = .showedUp
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservation property]
```

### reservation (Line 815)

**Context:**

```swift
    }

    private func handleDoubleTap() {
        if let reservation = tableView.currentActiveReservation {
            unitView.showInspector = true
            onEditReservation(reservation)
        } else if tableView.currentActiveReservation == nil
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### deltaCols (Line 835)

**Context:**

```swift
            return
        }

        let deltaCols = Int(round(translation.width / cellSize))
        let deltaRows = Int(round(translation.height / cellSize))

        let newRow = table.row + deltaRows
```

**Suggested Documentation:**

```swift
/// [Description of the deltaCols property]
```

### deltaRows (Line 836)

**Context:**

```swift
        }

        let deltaCols = Int(round(translation.width / cellSize))
        let deltaRows = Int(round(translation.height / cellSize))

        let newRow = table.row + deltaRows
        let newCol = table.column + deltaCols
```

**Suggested Documentation:**

```swift
/// [Description of the deltaRows property]
```

### newRow (Line 838)

**Context:**

```swift
        let deltaCols = Int(round(translation.width / cellSize))
        let deltaRows = Int(round(translation.height / cellSize))

        let newRow = table.row + deltaRows
        let newCol = table.column + deltaCols

        let proposedFrame = CGRect(
```

**Suggested Documentation:**

```swift
/// [Description of the newRow property]
```

### newCol (Line 839)

**Context:**

```swift
        let deltaRows = Int(round(translation.height / cellSize))

        let newRow = table.row + deltaRows
        let newCol = table.column + deltaCols

        let proposedFrame = CGRect(
            x: xPos + translation.width - tableFrame.width / 2,
```

**Suggested Documentation:**

```swift
/// [Description of the newCol property]
```

### proposedFrame (Line 841)

**Context:**

```swift
        let newRow = table.row + deltaRows
        let newCol = table.column + deltaCols

        let proposedFrame = CGRect(
            x: xPos + translation.width - tableFrame.width / 2,
            y: yPos + translation.height - tableFrame.height / 2,
            width: tableFrame.width,
```

**Suggested Documentation:**

```swift
/// [Description of the proposedFrame property]
```

### updatedTable (Line 866)

**Context:**

```swift
        )

        // Retrieve the updated table from layoutUI.tables
        guard let updatedTable = layoutUI.tables.first(where: { $0.id == table.id }) else {
            print("Error: Updated table not found after move!")
            return
        }
```

**Suggested Documentation:**

```swift
/// [Description of the updatedTable property]
```

### combinedDate (Line 871)

**Context:**

```swift
            return
        }

        let combinedDate = DateHelper.combine(
            date: appState.selectedDate, time: appState.selectedDate)
        if let updatedLayout = env.layoutServices.cachedLayouts[
            env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)]
```

**Suggested Documentation:**

```swift
/// [Description of the combinedDate property]
```

### updatedLayout (Line 873)

**Context:**

```swift

        let combinedDate = DateHelper.combine(
            date: appState.selectedDate, time: appState.selectedDate)
        if let updatedLayout = env.layoutServices.cachedLayouts[
            env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)]
        {
            print("Updated cache for \(appState.selectedCategory):")
```

**Suggested Documentation:**

```swift
/// [Description of the updatedLayout property]
```

### reservation (Line 882)

**Context:**

```swift
            }
        }

        if let reservation = tableView.currentActiveReservation {
            env.reservationService.updateActiveReservationAdjacencyCounts(for: reservation)
        }
        let layoutKey = env.layoutServices.keyFor(
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### layoutKey (Line 885)

**Context:**

```swift
        if let reservation = tableView.currentActiveReservation {
            env.reservationService.updateActiveReservationAdjacencyCounts(for: reservation)
        }
        let layoutKey = env.layoutServices.keyFor(
            date: combinedDate, category: appState.selectedCategory)
        env.layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        env.layoutServices.saveToDisk()
```

**Suggested Documentation:**

```swift
/// [Description of the layoutKey property]
```

### newWorkItem (Line 897)

**Context:**

```swift

    private func debounce(action: @escaping () -> Void, delay: TimeInterval = 0.1) {
        tableView.debounceWorkItem?.cancel()
        let newWorkItem = DispatchWorkItem { action() }
        tableView.debounceWorkItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the newWorkItem property]
```


Total documentation suggestions: 103

