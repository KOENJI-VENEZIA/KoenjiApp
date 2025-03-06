Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Timeline/TimelineGantView.swift...
# Documentation Suggestions for TimelineGantView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Timeline/TimelineGantView.swift
Total suggestions: 114

## Class Documentation (5)

### TimelineGantView (Line 11)

**Context:**

```swift
import Foundation
import os

struct TimelineGantView: View {

    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
```

**Suggested Documentation:**

```swift
/// TimelineGantView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### TimelineGantView (Line 135)

**Context:**

```swift
}

// MARK: - Subviews & Helper Functions
extension TimelineGantView {
    private func dragOverlay() -> some View {
        Group {
            if let draggedID = draggedRowID, isDragging {
```

**Suggested Documentation:**

```swift
/// TimelineGantView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### DraggableReservationRow (Line 506)

**Context:**

```swift
}

// MARK: - DraggableReservationRow
struct DraggableReservationRow: View {
    let tableID: Int
    let rowIndex: Int
    let reservations: [Reservation]
```

**Suggested Documentation:**

```swift
/// DraggableReservationRow class.
///
/// [Add a description of what this class does and its responsibilities]
```

### DragDirection (Line 526)

**Context:**

```swift
    // Track initial drag direction.
    @State private var dragDirection: DragDirection = .none
    
    private enum DragDirection {
        case none, vertical, horizontal
    }
    
```

**Suggested Documentation:**

```swift
/// DragDirection class.
///
/// [Add a description of what this class does and its responsibilities]
```

### RectangleReservationBackground (Line 624)

**Context:**

```swift
}

// MARK: - RectangleReservationBackground Subview
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
```

**Suggested Documentation:**

```swift
/// RectangleReservationBackground class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (10)

### initializeRowAssignments (Line 124)

**Context:**

```swift
    }
    
    // Initialize the row assignments to default values
    private func initializeRowAssignments() {
        // Initialize row assignments based on the tableAssignmentOrder
        for (index, tableName) in tableAssignmentOrder.enumerated() {
            if let tableID = tableNameToID[tableName] {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the initializeRowAssignments method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### dragOverlay (Line 136)

**Context:**

```swift

// MARK: - Subviews & Helper Functions
extension TimelineGantView {
    private func dragOverlay() -> some View {
        Group {
            if let draggedID = draggedRowID, isDragging {
                let tableID = tableIdForRow(draggedID)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the dragOverlay method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### contentView (Line 187)

**Context:**

```swift
    
    /// The main content view containing the table headers and scrollable timeline.
    @ViewBuilder
    private func contentView() -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone && verticalSizeClass == .compact {
                ScrollView(.vertical) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the contentView method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### timelineScrollView (Line 209)

**Context:**

```swift
        }
    }
    
    private func timelineScrollView() -> some View {
        ScrollView(.horizontal) {
            ZStack(alignment: .leading) {
                backgroundGridView().padding()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the timelineScrollView method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### currentTimeScrubber (Line 428)

**Context:**

```swift
    
    // Add current time scrubber view - this will be replaced by the new implementation
    @ViewBuilder
    private func currentTimeScrubber() -> some View {
        // Empty view - we've moved this functionality to the timelineScrollView
        EmptyView()
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the currentTimeScrubber method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### timeScrubberLine (Line 434)

**Context:**

```swift
    }
    
    // New function for the time scrubber line only
    private func timeScrubberLine() -> some View {
        let xPosition = calculateTimePosition(for: currentTime)
        
        return ZStack(alignment: .top) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the timeScrubberLine method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### isCurrentTimeVisible (Line 462)

**Context:**

```swift
    }
    
    // Helper to check if current time is within visible range
    private func isCurrentTimeVisible() -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentHour = timeComponents.hour ?? 0
```

**Suggested Documentation:**

```swift
/// [Add a description of what the isCurrentTimeVisible method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateTimePosition (Line 480)

**Context:**

```swift
    }
    
    // Calculate position for time scrubber
    private func calculateTimePosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let hour = timeComponents.hour ?? 0
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateTimePosition method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### formatTime (Line 498)

**Context:**

```swift
    }
    
    // Format time for display
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the formatTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### statusIcon (Line 740)

**Context:**

```swift
        }
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

## Property Documentation (99)

### env (Line 14)

**Context:**

```swift
struct TimelineGantView: View {

    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.verticalSizeClass) var verticalSizeClass  // <-- Add this line

```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 15)

**Context:**

```swift

    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.verticalSizeClass) var verticalSizeClass  // <-- Add this line

    private static let logger = Logger(
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### verticalSizeClass (Line 16)

**Context:**

```swift
    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.verticalSizeClass) var verticalSizeClass  // <-- Add this line

    private static let logger = Logger(
        subsystem: "com.koenjiapp",
```

**Suggested Documentation:**

```swift
/// [Description of the verticalSizeClass property]
```

### logger (Line 18)

**Context:**

```swift
    @EnvironmentObject var appState: AppState
    @Environment(\.verticalSizeClass) var verticalSizeClass  // <-- Add this line

    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "TimelineGantView"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### reservations (Line 23)

**Context:**

```swift
        category: "TimelineGantView"
    )

    var reservations: [Reservation]
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    // MARK: - State
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### columnVisibility (Line 24)

**Context:**

```swift
    )

    var reservations: [Reservation]
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    // MARK: - State
    // State to track the row arrangement
```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```

### rowAssignments (Line 28)

**Context:**

```swift
    
    // MARK: - State
    // State to track the row arrangement
    @State private var rowAssignments: [Int: Int] = [:] // Map tableID to rowIndex
    @State private var draggedRowID: Int? = nil
    @State private var isDragging: Bool = false

```

**Suggested Documentation:**

```swift
/// [Description of the rowAssignments property]
```

### draggedRowID (Line 29)

**Context:**

```swift
    // MARK: - State
    // State to track the row arrangement
    @State private var rowAssignments: [Int: Int] = [:] // Map tableID to rowIndex
    @State private var draggedRowID: Int? = nil
    @State private var isDragging: Bool = false

    @State private var dragLocation: CGPoint = .zero
```

**Suggested Documentation:**

```swift
/// [Description of the draggedRowID property]
```

### isDragging (Line 30)

**Context:**

```swift
    // State to track the row arrangement
    @State private var rowAssignments: [Int: Int] = [:] // Map tableID to rowIndex
    @State private var draggedRowID: Int? = nil
    @State private var isDragging: Bool = false

    @State private var dragLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
```

**Suggested Documentation:**

```swift
/// [Description of the isDragging property]
```

### dragLocation (Line 32)

**Context:**

```swift
    @State private var draggedRowID: Int? = nil
    @State private var isDragging: Bool = false

    @State private var dragLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var potentialDropRow: Int? = nil
    
```

**Suggested Documentation:**

```swift
/// [Description of the dragLocation property]
```

### dragOffset (Line 33)

**Context:**

```swift
    @State private var isDragging: Bool = false

    @State private var dragLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var potentialDropRow: Int? = nil
    
    // Current time state
```

**Suggested Documentation:**

```swift
/// [Description of the dragOffset property]
```

### potentialDropRow (Line 34)

**Context:**

```swift

    @State private var dragLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var potentialDropRow: Int? = nil
    
    // Current time state
    @State private var currentTime = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the potentialDropRow property]
```

### currentTime (Line 37)

**Context:**

```swift
    @State private var potentialDropRow: Int? = nil
    
    // Current time state
    @State private var currentTime = Date()
    
    // Create a timer publisher that fires every minute
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```

### timer (Line 40)

**Context:**

```swift
    @State private var currentTime = Date()
    
    // Create a timer publisher that fires every minute
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // MARK: - Layout Constants
    private let tables: Int = 7
```

**Suggested Documentation:**

```swift
/// [Description of the timer property]
```

### tables (Line 43)

**Context:**

```swift
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // MARK: - Layout Constants
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### columnsPerHour (Line 44)

**Context:**

```swift
    
    // MARK: - Layout Constants
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8
    
```

**Suggested Documentation:**

```swift
/// [Description of the columnsPerHour property]
```

### cellSize (Line 45)

**Context:**

```swift
    // MARK: - Layout Constants
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8
    
    // Table assignment order to match TableAssignmentService
```

**Suggested Documentation:**

```swift
/// [Description of the cellSize property]
```

### gridRowCount (Line 46)

**Context:**

```swift
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8
    
    // Table assignment order to match TableAssignmentService
    private let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]
```

**Suggested Documentation:**

```swift
/// [Description of the gridRowCount property]
```

### tableAssignmentOrder (Line 49)

**Context:**

```swift
    private let gridRowCount: Int = 8
    
    // Table assignment order to match TableAssignmentService
    private let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]
    
    // Map table names to their IDs
    private var tableNameToID: [String: Int] {
```

**Suggested Documentation:**

```swift
/// [Description of the tableAssignmentOrder property]
```

### tableNameToID (Line 52)

**Context:**

```swift
    private let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]
    
    // Map table names to their IDs
    private var tableNameToID: [String: Int] {
        var mapping: [String: Int] = [:]
        for i in 1...tables {
            mapping["T\(i)"] = i
```

**Suggested Documentation:**

```swift
/// [Description of the tableNameToID property]
```

### mapping (Line 53)

**Context:**

```swift
    
    // Map table names to their IDs
    private var tableNameToID: [String: Int] {
        var mapping: [String: Int] = [:]
        for i in 1...tables {
            mapping["T\(i)"] = i
        }
```

**Suggested Documentation:**

```swift
/// [Description of the mapping property]
```

### gridRows (Line 61)

**Context:**

```swift
    }

    // Computed grid rows for the LazyHGrid
    private var gridRows: [GridItem] {
        Array(repeating: GridItem(.fixed(60), spacing: 20), count: gridRowCount)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the gridRows property]
```

### totalHours (Line 66)

**Context:**

```swift
    }
    
    // MARK: - Time & Category Computations
    private var totalHours: Int {
        switch appState.selectedCategory {
        case .lunch:  return 4
        case .dinner: return 6
```

**Suggested Documentation:**

```swift
/// [Description of the totalHours property]
```

### startHour (Line 74)

**Context:**

```swift
        }
    }
    
    private var startHour: Int {
        switch appState.selectedCategory {
        case .lunch:  return 12
        case .dinner: return 18
```

**Suggested Documentation:**

```swift
/// [Description of the startHour property]
```

### totalColumns (Line 82)

**Context:**

```swift
        }
    }
    
    private var totalColumns: Int {
        totalHours * columnsPerHour
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the totalColumns property]
```

### body (Line 87)

**Context:**

```swift
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
//                headerText(in: geometry)
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### tableID (Line 127)

**Context:**

```swift
    private func initializeRowAssignments() {
        // Initialize row assignments based on the tableAssignmentOrder
        for (index, tableName) in tableAssignmentOrder.enumerated() {
            if let tableID = tableNameToID[tableName] {
                rowAssignments[tableID] = index
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### draggedID (Line 138)

**Context:**

```swift
extension TimelineGantView {
    private func dragOverlay() -> some View {
        Group {
            if let draggedID = draggedRowID, isDragging {
                let tableID = tableIdForRow(draggedID)
                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: 12)
```

**Suggested Documentation:**

```swift
/// [Description of the draggedID property]
```

### tableID (Line 139)

**Context:**

```swift
    private func dragOverlay() -> some View {
        Group {
            if let draggedID = draggedRowID, isDragging {
                let tableID = tableIdForRow(draggedID)
                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.white)
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### xPosition (Line 227)

**Context:**

```swift
        .overlay(
            // Keep the debug text as an overlay
            VStack {
                let xPosition = calculateTimePosition(for: currentTime)
                let isVisible = isCurrentTimeVisible()
                
                Text("Current: \(formatTime(currentTime)), Visible: \(isVisible ? "Yes" : "No"), Position: \(Int(xPosition))")
```

**Suggested Documentation:**

```swift
/// [Description of the xPosition property]
```

### isVisible (Line 228)

**Context:**

```swift
            // Keep the debug text as an overlay
            VStack {
                let xPosition = calculateTimePosition(for: currentTime)
                let isVisible = isCurrentTimeVisible()
                
                Text("Current: \(formatTime(currentTime)), Visible: \(isVisible ? "Yes" : "No"), Position: \(Int(xPosition))")
                    .font(.caption)
```

**Suggested Documentation:**

```swift
/// [Description of the isVisible property]
```

### tableID (Line 253)

**Context:**

```swift
            // Table headers are now ordered according to tableAssignmentOrder
            ForEach(0..<tables, id: \.self) { rowIndex in
                // Find the tableID that's assigned to this row index
                let tableID = tableIdForRow(rowIndex)
                Text("T\(tableID)")
                    .padding()
                    .background(
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### totalMinutes (Line 311)

**Context:**

```swift
    private func timeMarkersRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { columnIndex in
                let totalMinutes = columnIndex * 15
                let currentHour = startHour + (totalMinutes / 60)
                let currentMinute = totalMinutes % 60
                Text(String(format: "%02d:%02d", currentHour, currentMinute))
```

**Suggested Documentation:**

```swift
/// [Description of the totalMinutes property]
```

### currentHour (Line 312)

**Context:**

```swift
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { columnIndex in
                let totalMinutes = columnIndex * 15
                let currentHour = startHour + (totalMinutes / 60)
                let currentMinute = totalMinutes % 60
                Text(String(format: "%02d:%02d", currentHour, currentMinute))
                    .frame(width: cellSize)
```

**Suggested Documentation:**

```swift
/// [Description of the currentHour property]
```

### currentMinute (Line 313)

**Context:**

```swift
            ForEach(0..<totalColumns, id: \.self) { columnIndex in
                let totalMinutes = columnIndex * 15
                let currentHour = startHour + (totalMinutes / 60)
                let currentMinute = totalMinutes % 60
                Text(String(format: "%02d:%02d", currentHour, currentMinute))
                    .frame(width: cellSize)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the currentMinute property]
```

### tableID (Line 323)

**Context:**

```swift
    /// Displays the reservations for each table, based on the current ordering.
    private func reservationsRows() -> some View {
        ForEach(0..<tables, id: \.self) { rowIndex in
            let tableID = tableIdForRow(rowIndex)
            DraggableReservationRow(
                tableID: tableID,
                rowIndex: rowIndex,
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### sourceTableID (Line 365)

**Context:**

```swift
        
        withAnimation(.spring()) {
            // Find table IDs for source and destination
            let sourceTableID = tableIdForRow(sourceRowIndex)
            let destTableID = tableIdForRow(destinationRowIndex)
            
            // Update the row assignments
```

**Suggested Documentation:**

```swift
/// [Description of the sourceTableID property]
```

### destTableID (Line 366)

**Context:**

```swift
        withAnimation(.spring()) {
            // Find table IDs for source and destination
            let sourceTableID = tableIdForRow(sourceRowIndex)
            let destTableID = tableIdForRow(destinationRowIndex)
            
            // Update the row assignments
            rowAssignments[sourceTableID] = destinationRowIndex
```

**Suggested Documentation:**

```swift
/// [Description of the destTableID property]
```

### tableIds (Line 382)

**Context:**

```swift
            TimelineGantView.logger.info("Table ID: \(table)")
            // Convert integers to strings before joining
            TimelineGantView.logger.info("Reservation tables: \(reservation.tables)")
            let tableIds = reservation.tables.map { String($0.id) }.joined(separator: ", ")
            TimelineGantView.logger.info("Reservation tables id: \(tableIds)")
            TimelineGantView.logger.info("Is there a match? \(reservation.tables.contains { $0.id == table })")
            TimelineGantView.logger.info("Reservations count: \(reservations.count)")
```

**Suggested Documentation:**

```swift
/// [Description of the tableIds property]
```

### tableReservations (Line 393)

**Context:**

```swift
    /// Logs reservations for each table.
    private func logReservationsPerTable() {
        for table in 0..<tables {
            let tableReservations = reservations.filter { reservation in
                reservation.tables.contains { $0.id == (table + 1) }
            }
            for res in tableReservations {
```

**Suggested Documentation:**

```swift
/// [Description of the tableReservations property]
```

### startDate (Line 404)

**Context:**

```swift
    
    /// Calculates the left padding (in points) for a reservation view on a specific table.
    private func calculatePadding(for reservation: Reservation, _ table: Int) -> CGFloat {
        let startDate = reservation.startTimeDate ?? Date()
        let categoryStartTime: String = {
            switch appState.selectedCategory {
            case .lunch:  return "12:00"
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### categoryStartTime (Line 405)

**Context:**

```swift
    /// Calculates the left padding (in points) for a reservation view on a specific table.
    private func calculatePadding(for reservation: Reservation, _ table: Int) -> CGFloat {
        let startDate = reservation.startTimeDate ?? Date()
        let categoryStartTime: String = {
            switch appState.selectedCategory {
            case .lunch:  return "12:00"
            case .dinner: return "18:00"
```

**Suggested Documentation:**

```swift
/// [Description of the categoryStartTime property]
```

### categoryDate (Line 412)

**Context:**

```swift
            default:      return "15:01"
            }
        }()
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // in seconds
        let totalMinutes = paddingTime / 60.0
```

**Suggested Documentation:**

```swift
/// [Description of the categoryDate property]
```

### combinedCategoryDate (Line 413)

**Context:**

```swift
            }
        }()
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // in seconds
        let totalMinutes = paddingTime / 60.0
        return totalMinutes <= 0 ? (cellSize / 2.0) : ((CGFloat(totalMinutes) / 15.0) * cellSize) + (cellSize / 2.0)
```

**Suggested Documentation:**

```swift
/// [Description of the combinedCategoryDate property]
```

### paddingTime (Line 414)

**Context:**

```swift
        }()
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // in seconds
        let totalMinutes = paddingTime / 60.0
        return totalMinutes <= 0 ? (cellSize / 2.0) : ((CGFloat(totalMinutes) / 15.0) * cellSize) + (cellSize / 2.0)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the paddingTime property]
```

### totalMinutes (Line 415)

**Context:**

```swift
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // in seconds
        let totalMinutes = paddingTime / 60.0
        return totalMinutes <= 0 ? (cellSize / 2.0) : ((CGFloat(totalMinutes) / 15.0) * cellSize) + (cellSize / 2.0)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the totalMinutes property]
```

### duration (Line 421)

**Context:**

```swift
    
    /// Calculates the width (in points) for a reservation view based on its duration.
    private func calculateWidth(for reservation: Reservation) -> CGFloat {
        let duration = reservation.endTimeDate?.timeIntervalSince(reservation.startTimeDate ?? Date()) ?? 0.0
        let minutes = duration / 60.0
        return CGFloat(minutes / 15.0) * cellSize
    }
```

**Suggested Documentation:**

```swift
/// [Description of the duration property]
```

### minutes (Line 422)

**Context:**

```swift
    /// Calculates the width (in points) for a reservation view based on its duration.
    private func calculateWidth(for reservation: Reservation) -> CGFloat {
        let duration = reservation.endTimeDate?.timeIntervalSince(reservation.startTimeDate ?? Date()) ?? 0.0
        let minutes = duration / 60.0
        return CGFloat(minutes / 15.0) * cellSize
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the minutes property]
```

### xPosition (Line 435)

**Context:**

```swift
    
    // New function for the time scrubber line only
    private func timeScrubberLine() -> some View {
        let xPosition = calculateTimePosition(for: currentTime)
        
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
```

**Suggested Documentation:**

```swift
/// [Description of the xPosition property]
```

### calendar (Line 463)

**Context:**

```swift
    
    // Helper to check if current time is within visible range
    private func isCurrentTimeVisible() -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentHour = timeComponents.hour ?? 0
        let currentMinute = timeComponents.minute ?? 0
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### timeComponents (Line 464)

**Context:**

```swift
    // Helper to check if current time is within visible range
    private func isCurrentTimeVisible() -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentHour = timeComponents.hour ?? 0
        let currentMinute = timeComponents.minute ?? 0
        
```

**Suggested Documentation:**

```swift
/// [Description of the timeComponents property]
```

### currentHour (Line 465)

**Context:**

```swift
    private func isCurrentTimeVisible() -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentHour = timeComponents.hour ?? 0
        let currentMinute = timeComponents.minute ?? 0
        
        // Convert to total minutes for more precise comparison
```

**Suggested Documentation:**

```swift
/// [Description of the currentHour property]
```

### currentMinute (Line 466)

**Context:**

```swift
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentHour = timeComponents.hour ?? 0
        let currentMinute = timeComponents.minute ?? 0
        
        // Convert to total minutes for more precise comparison
        let currentTotalMinutes = currentHour * 60 + currentMinute
```

**Suggested Documentation:**

```swift
/// [Description of the currentMinute property]
```

### currentTotalMinutes (Line 469)

**Context:**

```swift
        let currentMinute = timeComponents.minute ?? 0
        
        // Convert to total minutes for more precise comparison
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let startTotalMinutes = startHour * 60
        let endTotalMinutes = (startHour + totalHours) * 60
        
```

**Suggested Documentation:**

```swift
/// [Description of the currentTotalMinutes property]
```

### startTotalMinutes (Line 470)

**Context:**

```swift
        
        // Convert to total minutes for more precise comparison
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let startTotalMinutes = startHour * 60
        let endTotalMinutes = (startHour + totalHours) * 60
        
        let isVisible = currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
```

**Suggested Documentation:**

```swift
/// [Description of the startTotalMinutes property]
```

### endTotalMinutes (Line 471)

**Context:**

```swift
        // Convert to total minutes for more precise comparison
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let startTotalMinutes = startHour * 60
        let endTotalMinutes = (startHour + totalHours) * 60
        
        let isVisible = currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
        print("Time visibility check: \(currentHour):\(currentMinute) - Start: \(startHour), End: \(startHour + totalHours), Visible: \(isVisible)")
```

**Suggested Documentation:**

```swift
/// [Description of the endTotalMinutes property]
```

### isVisible (Line 473)

**Context:**

```swift
        let startTotalMinutes = startHour * 60
        let endTotalMinutes = (startHour + totalHours) * 60
        
        let isVisible = currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
        print("Time visibility check: \(currentHour):\(currentMinute) - Start: \(startHour), End: \(startHour + totalHours), Visible: \(isVisible)")
        
        return isVisible
```

**Suggested Documentation:**

```swift
/// [Description of the isVisible property]
```

### calendar (Line 481)

**Context:**

```swift
    
    // Calculate position for time scrubber
    private func calculateTimePosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let hour = timeComponents.hour ?? 0
        let minute = timeComponents.minute ?? 0
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### timeComponents (Line 482)

**Context:**

```swift
    // Calculate position for time scrubber
    private func calculateTimePosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let hour = timeComponents.hour ?? 0
        let minute = timeComponents.minute ?? 0
        
```

**Suggested Documentation:**

```swift
/// [Description of the timeComponents property]
```

### hour (Line 483)

**Context:**

```swift
    private func calculateTimePosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let hour = timeComponents.hour ?? 0
        let minute = timeComponents.minute ?? 0
        
        // Calculate hours and minutes since category start
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### minute (Line 484)

**Context:**

```swift
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let hour = timeComponents.hour ?? 0
        let minute = timeComponents.minute ?? 0
        
        // Calculate hours and minutes since category start
        let hoursSinceStart = hour - startHour
```

**Suggested Documentation:**

```swift
/// [Description of the minute property]
```

### hoursSinceStart (Line 487)

**Context:**

```swift
        let minute = timeComponents.minute ?? 0
        
        // Calculate hours and minutes since category start
        let hoursSinceStart = hour - startHour
        let minutesFraction = CGFloat(minute) / 60.0
        
        // Calculate position (each hour is cellSize * 4 wide)
```

**Suggested Documentation:**

```swift
/// [Description of the hoursSinceStart property]
```

### minutesFraction (Line 488)

**Context:**

```swift
        
        // Calculate hours and minutes since category start
        let hoursSinceStart = hour - startHour
        let minutesFraction = CGFloat(minute) / 60.0
        
        // Calculate position (each hour is cellSize * 4 wide)
        let position = (CGFloat(hoursSinceStart) * cellSize * 4) + (minutesFraction * cellSize * 4)
```

**Suggested Documentation:**

```swift
/// [Description of the minutesFraction property]
```

### position (Line 491)

**Context:**

```swift
        let minutesFraction = CGFloat(minute) / 60.0
        
        // Calculate position (each hour is cellSize * 4 wide)
        let position = (CGFloat(hoursSinceStart) * cellSize * 4) + (minutesFraction * cellSize * 4)
        print("Time position calculation: \(hour):\(minute) → \(position) points from start")
        
        return position
```

**Suggested Documentation:**

```swift
/// [Description of the position property]
```

### formatter (Line 499)

**Context:**

```swift
    
    // Format time for display
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### tableID (Line 507)

**Context:**

```swift

// MARK: - DraggableReservationRow
struct DraggableReservationRow: View {
    let tableID: Int
    let rowIndex: Int
    let reservations: [Reservation]
    @Binding var isDragging: Bool
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### rowIndex (Line 508)

**Context:**

```swift
// MARK: - DraggableReservationRow
struct DraggableReservationRow: View {
    let tableID: Int
    let rowIndex: Int
    let reservations: [Reservation]
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
```

**Suggested Documentation:**

```swift
/// [Description of the rowIndex property]
```

### reservations (Line 509)

**Context:**

```swift
struct DraggableReservationRow: View {
    let tableID: Int
    let rowIndex: Int
    let reservations: [Reservation]
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### isDragging (Line 510)

**Context:**

```swift
    let tableID: Int
    let rowIndex: Int
    let reservations: [Reservation]
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
```

**Suggested Documentation:**

```swift
/// [Description of the isDragging property]
```

### draggedRowID (Line 511)

**Context:**

```swift
    let rowIndex: Int
    let reservations: [Reservation]
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
```

**Suggested Documentation:**

```swift
/// [Description of the draggedRowID property]
```

### dragLocation (Line 512)

**Context:**

```swift
    let reservations: [Reservation]
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
```

**Suggested Documentation:**

```swift
/// [Description of the dragLocation property]
```

### dragOffset (Line 513)

**Context:**

```swift
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
```

**Suggested Documentation:**

```swift
/// [Description of the dragOffset property]
```

### potentialDropRow (Line 514)

**Context:**

```swift
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
    let onDoubleClick: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the potentialDropRow property]
```

### calculateWidth (Line 515)

**Context:**

```swift
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
    let onDoubleClick: (Reservation) -> Void
    let onReorder: (Int, Int) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the calculateWidth property]
```

### calculatePadding (Line 516)

**Context:**

```swift
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
    let onDoubleClick: (Reservation) -> Void
    let onReorder: (Int, Int) -> Void
    
```

**Suggested Documentation:**

```swift
/// [Description of the calculatePadding property]
```

### onDoubleClick (Line 517)

**Context:**

```swift
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
    let onDoubleClick: (Reservation) -> Void
    let onReorder: (Int, Int) -> Void
    
    // Threshold for vertical drag detection.
```

**Suggested Documentation:**

```swift
/// [Description of the onDoubleClick property]
```

### onReorder (Line 518)

**Context:**

```swift
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
    let onDoubleClick: (Reservation) -> Void
    let onReorder: (Int, Int) -> Void
    
    // Threshold for vertical drag detection.
    private let verticalDragThreshold: CGFloat = 15.0
```

**Suggested Documentation:**

```swift
/// [Description of the onReorder property]
```

### verticalDragThreshold (Line 521)

**Context:**

```swift
    let onReorder: (Int, Int) -> Void
    
    // Threshold for vertical drag detection.
    private let verticalDragThreshold: CGFloat = 15.0
    
    // Track initial drag direction.
    @State private var dragDirection: DragDirection = .none
```

**Suggested Documentation:**

```swift
/// [Description of the verticalDragThreshold property]
```

### dragDirection (Line 524)

**Context:**

```swift
    private let verticalDragThreshold: CGFloat = 15.0
    
    // Track initial drag direction.
    @State private var dragDirection: DragDirection = .none
    
    private enum DragDirection {
        case none, vertical, horizontal
```

**Suggested Documentation:**

```swift
/// [Description of the dragDirection property]
```

### body (Line 530)

**Context:**

```swift
        case none, vertical, horizontal
    }
    
    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                ForEach(reservations) { reservation in
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### drag (Line 559)

**Context:**

```swift
                    case .first(true):
                        // Long press detected; waiting for drag.
                        break
                    case .second(true, let drag?):
                        // The long press succeeded and the drag is now active.
                        // Determine the initial drag direction.
                        if dragDirection == .none {
```

**Suggested Documentation:**

```swift
/// [Description of the drag property]
```

### horizontalMovement (Line 563)

**Context:**

```swift
                        // The long press succeeded and the drag is now active.
                        // Determine the initial drag direction.
                        if dragDirection == .none {
                            let horizontalMovement = abs(drag.translation.width)
                            let verticalMovement = abs(drag.translation.height)
                            
                            // Prioritize scrolling if horizontal movement dominates.
```

**Suggested Documentation:**

```swift
/// [Description of the horizontalMovement property]
```

### verticalMovement (Line 564)

**Context:**

```swift
                        // Determine the initial drag direction.
                        if dragDirection == .none {
                            let horizontalMovement = abs(drag.translation.width)
                            let verticalMovement = abs(drag.translation.height)
                            
                            // Prioritize scrolling if horizontal movement dominates.
                            if horizontalMovement > verticalMovement && horizontalMovement > 10 {
```

**Suggested Documentation:**

```swift
/// [Description of the verticalMovement property]
```

### rowHeight (Line 585)

**Context:**

```swift
                            dragLocation = drag.location
                            dragOffset = drag.translation
                            
                            let rowHeight: CGFloat = 80 // Approximate row height.
                            let rowsToMove = Int(drag.translation.height / rowHeight)
                            let potentialRow = min(max(0, rowIndex + rowsToMove), 6)
                            potentialDropRow = potentialRow
```

**Suggested Documentation:**

```swift
/// [Description of the rowHeight property]
```

### rowsToMove (Line 586)

**Context:**

```swift
                            dragOffset = drag.translation
                            
                            let rowHeight: CGFloat = 80 // Approximate row height.
                            let rowsToMove = Int(drag.translation.height / rowHeight)
                            let potentialRow = min(max(0, rowIndex + rowsToMove), 6)
                            potentialDropRow = potentialRow
                        }
```

**Suggested Documentation:**

```swift
/// [Description of the rowsToMove property]
```

### potentialRow (Line 587)

**Context:**

```swift
                            
                            let rowHeight: CGFloat = 80 // Approximate row height.
                            let rowsToMove = Int(drag.translation.height / rowHeight)
                            let potentialRow = min(max(0, rowIndex + rowsToMove), 6)
                            potentialDropRow = potentialRow
                        }
                    default:
```

**Suggested Documentation:**

```swift
/// [Description of the potentialRow property]
```

### sourceRow (Line 597)

**Context:**

```swift
                .onEnded { value in
                    // End the drag if we were in vertical mode.
                    if case .second(true, _) = value, dragDirection == .vertical {
                        if let sourceRow = draggedRowID, let destRow = potentialDropRow {
                            onReorder(sourceRow, destRow)
                        }
                    }
```

**Suggested Documentation:**

```swift
/// [Description of the sourceRow property]
```

### destRow (Line 597)

**Context:**

```swift
                .onEnded { value in
                    // End the drag if we were in vertical mode.
                    if case .second(true, _) = value, dragDirection == .vertical {
                        if let sourceRow = draggedRowID, let destRow = potentialDropRow {
                            onReorder(sourceRow, destRow)
                        }
                    }
```

**Suggested Documentation:**

```swift
/// [Description of the destRow property]
```

### reservation (Line 625)

**Context:**

```swift

// MARK: - RectangleReservationBackground Subview
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### duration (Line 626)

**Context:**

```swift
// MARK: - RectangleReservationBackground Subview
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
    private let cellHeight: CGFloat = 60
```

**Suggested Documentation:**

```swift
/// [Description of the duration property]
```

### padding (Line 627)

**Context:**

```swift
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
    private let cellHeight: CGFloat = 60
    
```

**Suggested Documentation:**

```swift
/// [Description of the padding property]
```

### tableID (Line 628)

**Context:**

```swift
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
    private let cellHeight: CGFloat = 60
    
    private var shouldShowReservation: Bool {
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```

### cellHeight (Line 629)

**Context:**

```swift
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
    private let cellHeight: CGFloat = 60
    
    private var shouldShowReservation: Bool {
        reservation.tables.map(\.id).min() == tableID
```

**Suggested Documentation:**

```swift
/// [Description of the cellHeight property]
```

### shouldShowReservation (Line 631)

**Context:**

```swift
    let tableID: Int
    private let cellHeight: CGFloat = 60
    
    private var shouldShowReservation: Bool {
        reservation.tables.map(\.id).min() == tableID
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the shouldShowReservation property]
```

### isTableOccupied (Line 635)

**Context:**

```swift
        reservation.tables.map(\.id).min() == tableID
    }
    
    private var isTableOccupied: Bool {
        reservation.tables.map(\.id).contains(tableID) && !shouldShowReservation
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the isTableOccupied property]
```

### body (Line 639)

**Context:**

```swift
        reservation.tables.map(\.id).contains(tableID) && !shouldShowReservation
    }
    
    var body: some View {
        Group {
            if shouldShowReservation || isTableOccupied {
                HStack(spacing: 0) {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### resCache (Line 751)

**Context:**

```swift
}

//#Preview {
//    @Previewable @StateObject var resCache = CurrentReservationsCache()
//    @Previewable @StateObject var appState = AppState()
//    @Previewable @State var columnVisibility: NavigationSplitViewVisibility = .all
//
```

**Suggested Documentation:**

```swift
/// [Description of the resCache property]
```

### appState (Line 752)

**Context:**

```swift

//#Preview {
//    @Previewable @StateObject var resCache = CurrentReservationsCache()
//    @Previewable @StateObject var appState = AppState()
//    @Previewable @State var columnVisibility: NavigationSplitViewVisibility = .all
//
//    TimelineGantView(reservations: columnVisibility: $columnVisibility)
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### columnVisibility (Line 753)

**Context:**

```swift
//#Preview {
//    @Previewable @StateObject var resCache = CurrentReservationsCache()
//    @Previewable @StateObject var appState = AppState()
//    @Previewable @State var columnVisibility: NavigationSplitViewVisibility = .all
//
//    TimelineGantView(reservations: columnVisibility: $columnVisibility)
//        .environmentObject(resCache)
```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```


Total documentation suggestions: 114

