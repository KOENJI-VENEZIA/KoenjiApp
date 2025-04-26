//
//  TimelineGantView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//
import SwiftUI
import Foundation
import os

struct TimelineGantView: View {

    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.verticalSizeClass) var verticalSizeClass  // <-- Add this line

    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "TimelineGantView"
    )

    var reservations: [Reservation]
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    // MARK: - State
    // State to track the row arrangement
    @State private var rowAssignments: [Int: Int] = [:] // Map tableID to rowIndex
    @State private var draggedRowID: Int? = nil
    @State private var isDragging: Bool = false

    @State private var dragLocation: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var potentialDropRow: Int? = nil
    
    // Current time state
    @State private var currentTime = Date()
    
    // Create a timer publisher that fires every minute
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // MARK: - Layout Constants
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8
    
    // Table assignment order to match TableAssignmentService
    private let tableAssignmentOrder: [String] = ["T1", "T2", "T3", "T4", "T6", "T7", "T5"]
    
    // Map table names to their IDs
    private var tableNameToID: [String: Int] {
        var mapping: [String: Int] = [:]
        for i in 1...tables {
            mapping["T\(i)"] = i
        }
        return mapping
    }

    // Computed grid rows for the LazyHGrid
    private var gridRows: [GridItem] {
        Array(repeating: GridItem(.fixed(60), spacing: 20), count: gridRowCount)
    }
    
    // MARK: - Time & Category Computations
    private var totalHours: Int {
        let currentHour = Calendar.current.component(.hour, from: Date())
        switch appState.selectedCategory {
        case .lunch:  return 4
        case .dinner: return 6
        case .noBookingZone:
            if currentHour < 18 && currentHour >= 12 {
                return 3
            } else {
                return 13
            }
        }
    }
    
    private var startHour: Int {
        let currentHour = Calendar.current.component(.hour, from: Date())
        switch appState.selectedCategory {
        case .lunch:  return 12
        case .dinner: return 18
        case .noBookingZone:
            if currentHour < 18 && currentHour >= 12 {
                        return 15
                    } else {
                        return 23
                    }
        }
    }
    
    private var totalColumns: Int {
        totalHours * columnsPerHour
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
//                headerText(in: geometry)
                fullScreenToggleOverlay()
                contentView()
                reservationCountText()
                
                // Current time scrubber overlay
                currentTimeScrubber()
                    .zIndex(100) // Ensure it's on top of everything
            }
        }
        .onAppear {
            initializeRowAssignments()
            logReservationsPerTable()
            
            // Initialize current time on appear
            self.currentTime = Date()
            
            // Debug log for reservations
            print("Timeline loaded with \(reservations.count) reservations")
            if reservations.isEmpty {
                print("No reservations found for the current view")
            } else {
                print("First reservation: \(reservations[0].name) at \(reservations[0].startTime)")
            }
        }
        // Use onReceive to safely update the currentTime
        .onReceive(timer) { _ in
            self.currentTime = Date()
            print("Timer fired, current time: \(formatTime(currentTime))")
        }
    }
    
    // Initialize the row assignments to default values
    private func initializeRowAssignments() {
        // Initialize row assignments based on the tableAssignmentOrder
        for (index, tableName) in tableAssignmentOrder.enumerated() {
            if let tableID = tableNameToID[tableName] {
                rowAssignments[tableID] = index
            }
        }
    }
}

// MARK: - Subviews & Helper Functions
extension TimelineGantView {
    /// Displays the header with the day of week and full date.
    private func headerText(in geometry: GeometryProxy) -> some View {
        Text("\(DateHelper.dayOfWeek(for: appState.selectedDate)), \(DateHelper.formatFullDate(appState.selectedDate))")
            .bold()
            .padding()
            .font(.title3)
            .offset(y: (-geometry.size.height / 2) + 20)
    }
    
    /// A clear overlay that toggles full-screen mode on double tap.
    private func fullScreenToggleOverlay() -> some View {
        Color.clear
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation {
                            appState.isFullScreen.toggle()
                            columnVisibility = appState.isFullScreen ? .detailOnly : .all
                        }
                    }
            )
    }
    
    /// The main content view containing the table headers and scrollable timeline.
    @ViewBuilder
    private func contentView() -> some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone && verticalSizeClass == .compact {
                ScrollView(.vertical) {
                    HStack {
                        tableHeadersView()
                        timelineScrollView()
                    }
                }
            } else {
                HStack {
                    tableHeadersView()
                    timelineScrollView()
                }
            }
        }
        .onAppear {
            // Debug log for content view
            print("Content view appeared, category: \(appState.selectedCategory), start hour: \(startHour)")
        }
    }
    
    private func timelineScrollView() -> some View {
        ScrollView(.horizontal) {
            ZStack(alignment: .leading) {
                backgroundGridView().padding()
                timelineContentView().padding()
                
                // Add the time scrubber directly to the scrollable content
                if isCurrentTimeVisible() {
                    timeScrubberLine()
                        .padding()
                        .zIndex(100) // Ensure it's on top
                }
            }
        }
        .background(Color.clear)
        .overlay(
            // Keep the debug text as an overlay
            VStack {
                let xPosition = calculateTimePosition(for: currentTime)
                let isVisible = isCurrentTimeVisible()
                
                Text("Current: \(formatTime(currentTime)), Visible: \(isVisible ? "Yes" : "No"), Position: \(Int(xPosition))")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(4)
                    .padding(.top, 4)
                
                Spacer()
            }
        )
    }
    
    /// Displays the table headers.
    private func tableHeadersView() -> some View {
        LazyHGrid(rows: gridRows, spacing: 20) {
            Text("TAV.")
                .font(.headline)
                .padding()
            
            // Table headers are now ordered according to tableAssignmentOrder
            ForEach(0..<tables, id: \.self) { rowIndex in
                // Find the tableID that's assigned to this row index
                let tableID = tableIdForRow(rowIndex)
                Text("T\(tableID)")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            }
        }
    }
    
    /// Find the table ID assigned to a specific row index
    private func tableIdForRow(_ rowIndex: Int) -> Int {
        for (tableID, assignedRow) in rowAssignments {
            if assignedRow == rowIndex {
                return tableID
            }
        }
        // Fallback to row index + 1 if no mapping is found
        return rowIndex + 1
    }
    
    
    /// The background grid with vertical markers.
    private func backgroundGridView() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { _ in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 0.5, height: 60)
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3),
                                style: StrokeStyle(
                                    lineWidth: 0.8,
                                    dash: [2, 3]
                                ))
                        .frame(width: 1)
                        .frame(height: UIScreen.main.bounds.height * 0.8)
                }
                .frame(width: cellSize)
            }
        }
    }
    
    /// Combines the time markers and reservations rows.
    private func timelineContentView() -> some View {
        LazyHGrid(rows: gridRows, spacing: 20) {
            timeMarkersRow()
            reservationsRows()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// Displays the row with time markers.
    private func timeMarkersRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { columnIndex in
                let totalMinutes = columnIndex * 15
                let hour = startHour + (totalMinutes / 60)
                let displayHour = hour % 24 // Wrap around at 24
                let currentMinute = totalMinutes % 60
                Text(String(format: "%02d:%02d", displayHour, currentMinute))
                    .frame(width: cellSize)
            }

        }
    }
    
    /// Displays the reservations for each table, based on the current ordering.
    private func reservationsRows() -> some View {
        ForEach(0..<tables, id: \.self) { rowIndex in
            let tableID = tableIdForRow(rowIndex)
            DraggableReservationRow(
                tableID: tableID,
                rowIndex: rowIndex,
                reservations: filteredReservations(for: tableID),
                isDragging: $isDragging,
                draggedRowID: $draggedRowID,
                dragLocation: $dragLocation,
                dragOffset: $dragOffset,
                potentialDropRow: $potentialDropRow,
                calculateWidth: calculateWidth,
                calculatePadding: calculatePadding,
                onDoubleClick: handleReservationDoubleClick,
                onReorder: reorderRow
            )
            .frame(height: 60)
            .background(isDragging ? Color.gray.opacity(0.1) : Color.clear)
        }
    }
    
    /// Handles double-click on a reservation
    private func handleReservationDoubleClick(_ reservation: Reservation) {
        appState.currentReservation = reservation
        appState.showingEditReservation = true
    }
    
    /// Displays the total number of reservations at the bottom.
    private func reservationCountText() -> some View {
        Text("\(reservations.count) \(TextHelper.pluralized(String(localized: "PRENOTAZIONE"), String(localized: "PRENOTAZIONI"), reservations.count))")
            .font(.headline)
            .padding()
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    // MARK: - Drag and Drop Functions
    
    /// Reorders the row assignments based on drag and drop operation
    private func reorderRow(from sourceRowIndex: Int, to destinationRowIndex: Int) {
        guard sourceRowIndex != destinationRowIndex else { return }
        
        withAnimation(.spring()) {
            // Find table IDs for source and destination
            let sourceTableID = tableIdForRow(sourceRowIndex)
            let destTableID = tableIdForRow(destinationRowIndex)
            
            // Update the row assignments
            rowAssignments[sourceTableID] = destinationRowIndex
            rowAssignments[destTableID] = sourceRowIndex
        }
    }
    
    // MARK: - Data & Calculation Helpers
    
    /// Filters reservations for a given table.
    private func filteredReservations(for table: Int) -> [Reservation] {
        reservations.filter { reservation in
            TimelineGantView.logger.info("Table ID: \(table)")
            // Convert integers to strings before joining
            TimelineGantView.logger.info("Reservation tables: \(reservation.tables)")
            let tableIds = reservation.tables.map { String($0.id) }.joined(separator: ", ")
            TimelineGantView.logger.info("Reservation tables id: \(tableIds)")
            TimelineGantView.logger.info("Is there a match? \(reservation.tables.contains { $0.id == table })")
            TimelineGantView.logger.info("Reservations count: \(reservations.count)")
            return reservation.tables.contains { $0.id == table }
        }
    }
    
    /// Logs reservations for each table.
    private func logReservationsPerTable() {
        for table in 0..<tables {
            let tableReservations = reservations.filter { reservation in
                reservation.tables.contains { $0.id == (table + 1) }
            }
            for res in tableReservations {
                AppLog.debug("Table \(table + 1): Reservation '\(res.name)' starting at \(res.startTime) (\(DateHelper.formatTime(res.startTimeDate ?? Date())))")
            }
        }
    }
    
    /// Calculates the left padding (in points) for a reservation view on a specific table.
    private func calculatePadding(for reservation: Reservation, _ table: Int) -> CGFloat {
        let startDate = reservation.startTimeDate ?? Date()
        let categoryStartTime: String = {
            switch appState.selectedCategory {
            case .lunch:  return "12:00"
            case .dinner: return "18:00"
            default:      return "15:01"
            }
        }()
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // in seconds
        let totalMinutes = paddingTime / 60.0
        return totalMinutes <= 0 ? (cellSize / 2.0) : ((CGFloat(totalMinutes) / 15.0) * cellSize) + (cellSize / 2.0)
    }
    
    /// Calculates the width (in points) for a reservation view based on its duration.
    private func calculateWidth(for reservation: Reservation) -> CGFloat {
        let duration = reservation.endTimeDate?.timeIntervalSince(reservation.startTimeDate ?? Date()) ?? 0.0
        let minutes = duration / 60.0
        return CGFloat(minutes / 15.0) * cellSize
    }
    
    // Add current time scrubber view - this will be replaced by the new implementation
    @ViewBuilder
    private func currentTimeScrubber() -> some View {
        // Empty view - we've moved this functionality to the timelineScrollView
        EmptyView()
    }
    
    // New function for the time scrubber line only
    private func timeScrubberLine() -> some View {
        let xPosition = calculateTimePosition(for: currentTime)
        
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Time label at the top
                Text(formatTime(currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
                    .padding(.bottom, 4)
                
                // Vertical line - starts right after the label
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2)
                    .frame(height: UIScreen.main.bounds.height * 0.8) // Make it tall enough to span the entire view
            }
        }
        .offset(x: xPosition) // Position based on current time
    }
    
    // Helper to check if current time is within visible range
    private func isCurrentTimeVisible() -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let currentHour = timeComponents.hour ?? 0
        let currentMinute = timeComponents.minute ?? 0
        
        // Convert to total minutes for more precise comparison
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let startTotalMinutes = startHour * 60
        let endTotalMinutes = (startHour + totalHours) * 60
        
        let isVisible = currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes
        print("Time visibility check: \(currentHour):\(currentMinute) - Start: \(startHour), End: \(startHour + totalHours), Visible: \(isVisible)")
        
        return isVisible
    }
    
    // Calculate position for time scrubber
    private func calculateTimePosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let hour = timeComponents.hour ?? 0
        let minute = timeComponents.minute ?? 0

        // If the hour is less than startHour, assume the time is after midnight and add 24.
        let effectiveHour = hour < startHour ? hour + 24 : hour
        let hoursSinceStart = effectiveHour - startHour
        let minutesFraction = CGFloat(minute) / 60.0

        // Each hour corresponds to (cellSize * 4) points.
        let position = (CGFloat(hoursSinceStart) + minutesFraction) * cellSize * 4
        print("Time position calculation: \(hour):\(minute) (effective: \(effectiveHour)) → \(position) points from start")
        
        return position
    }

    
    // Format time for display
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - DraggableReservationRow
struct DraggableReservationRow: View {
    let tableID: Int
    let rowIndex: Int
    let reservations: [Reservation]
    @Binding var isDragging: Bool
    @Binding var draggedRowID: Int?
    @Binding var dragLocation: CGPoint
    @Binding var dragOffset: CGSize
    @Binding var potentialDropRow: Int?
    let calculateWidth: (Reservation) -> CGFloat
    let calculatePadding: (Reservation, Int) -> CGFloat
    let onDoubleClick: (Reservation) -> Void
    let onReorder: (Int, Int) -> Void
    
    // Threshold for vertical drag detection.
    private let verticalDragThreshold: CGFloat = 15.0
    
    // Track initial drag direction.
    @State private var dragDirection: DragDirection = .none
    
    private enum DragDirection {
        case none, vertical, horizontal
    }
    
    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                ForEach(reservations) { reservation in
                    RectangleReservationBackground(
                        reservation: reservation,
                        duration: calculateWidth(reservation),
                        padding: calculatePadding(reservation, tableID),
                        tableID: tableID
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                onDoubleClick(reservation)
                            }
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            // Sequence a long press with a drag gesture.
            LongPressGesture(minimumDuration: 0.5)
                .sequenced(before: DragGesture(minimumDistance: 3))
                .onChanged { value in
                    switch value {
                    case .first(true):
                        // Long press detected; waiting for drag.
                        break
                    case .second(true, let drag?):
                        // The long press succeeded and the drag is now active.
                        // Determine the initial drag direction.
                        if dragDirection == .none {
                            let horizontalMovement = abs(drag.translation.width)
                            let verticalMovement = abs(drag.translation.height)
                            
                            // Prioritize scrolling if horizontal movement dominates.
                            if horizontalMovement > verticalMovement && horizontalMovement > 10 {
                                dragDirection = .horizontal
                                return
                            }
                            
                            // Otherwise, if vertical movement exceeds the threshold, activate dragging.
                            if verticalMovement > verticalDragThreshold {
                                dragDirection = .vertical
                                draggedRowID = rowIndex
                                isDragging = true
                            }
                        }
                        
                        // If we're in vertical drag mode, update drag location and potential drop.
                        if dragDirection == .vertical {
                            dragLocation = drag.location
                            dragOffset = drag.translation
                            
                            let rowHeight: CGFloat = 80 // Approximate row height.
                            let rowsToMove = Int(drag.translation.height / rowHeight)
                            let potentialRow = min(max(0, rowIndex + rowsToMove), 6)
                            potentialDropRow = potentialRow
                        }
                    default:
                        break
                    }
                }
                .onEnded { value in
                    // End the drag if we were in vertical mode.
                    if case .second(true, _) = value, dragDirection == .vertical {
                        if let sourceRow = draggedRowID, let destRow = potentialDropRow {
                            onReorder(sourceRow, destRow)
                        }
                    }
                    // Reset state.
                    draggedRowID = nil
                    isDragging = false
                    potentialDropRow = nil
                    dragDirection = .none
                }
        )
        .opacity(draggedRowID == rowIndex ? 0.5 : 1.0)
        .background(
            potentialDropRow == rowIndex && isDragging && draggedRowID != rowIndex ?
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                ) : nil
        )
        .animation(.spring(), value: draggedRowID)
        .animation(.spring(), value: potentialDropRow)
    }
}

// MARK: - RectangleReservationBackground Subview
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
    private let cellHeight: CGFloat = 60
    
    private var shouldShowReservation: Bool {
        reservation.tables.map(\.id).min() == tableID
    }
    
    private var isTableOccupied: Bool {
        reservation.tables.map(\.id).contains(tableID) && !shouldShowReservation
    }
    
    var body: some View {
        Group {
            if shouldShowReservation || isTableOccupied {
                HStack(spacing: 0) {
                    if padding > 0 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: padding)
                    }
                    
                    if isTableOccupied {
                        // Occupancy indicator for spanned tables
                        RoundedRectangle(cornerRadius: 8)
                            .fill(reservation.assignedColor.opacity(0.2))
                            .frame(width: duration, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        reservation.assignedColor.opacity(0.4),
                                        style: StrokeStyle(
                                            lineWidth: 1,
                                            dash: [4, 8],
                                            dashPhase: 10
                                        )
                                    )
                            )
                            .overlay(
                                // Add reservation name to occupied table indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                    Text(reservation.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                            )
                    } else {
                        // Main reservation card
                        RoundedRectangle(cornerRadius: 12)
                            .fill(reservation.assignedColor.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .overlay(
                                // Card content
                                VStack(alignment: .leading, spacing: 6) {
                                    // Top row with name and status
                                    HStack(spacing: 8) {
                                        Text(reservation.name)
                                            .font(.headline)
                                            .bold()
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // Status badge
                                        Label(reservation.status.localized, systemImage: statusIcon(for: reservation.status))
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(reservation.status.color.opacity(0.12))
                                            .foregroundColor(reservation.status.color)
                                            .clipShape(Capsule())
                                    }
                                    
                                    // Bottom row with details
                                    HStack(spacing: 12) {
                                        Label("\(reservation.numberOfPersons)p", systemImage: "person.2.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        
                                        Label("\(reservation.startTime)-\(reservation.endTime)", systemImage: "clock.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        if reservation.tables.count > 1 {
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            
                                            Label("\(reservation.tables.count) tavoli", systemImage: "tablecells")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            )
                            .frame(width: duration)
                    }
                }
                .frame(height: isTableOccupied ? 30 : cellHeight)
            }
        }
    }
    
    private func statusIcon(for status: Reservation.ReservationStatus) -> String {
        switch status {
        case .showedUp: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
}

//#Preview {
//    @Previewable @StateObject var resCache = CurrentReservationsCache()
//    @Previewable @StateObject var appState = AppState()
//    @Previewable @State var columnVisibility: NavigationSplitViewVisibility = .all
//
//    TimelineGantView(reservations: columnVisibility: $columnVisibility)
//        .environmentObject(resCache)
//        .environmentObject(appState)
//}
