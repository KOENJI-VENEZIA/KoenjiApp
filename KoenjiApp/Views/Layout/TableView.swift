import SwiftUI

struct TableView: View {
    let table: TableModel
    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    let currentTime: Date
    
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @ObservedObject var layoutUI: LayoutUIManager

    @Binding var showingNoBookingAlert: Bool

    let onTapEmpty: () -> Void
    let onEditReservation: (Reservation) -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false // State to track dragging
    @State private var isHeld: Bool = false // State for long press hold
    @State private var hasMoved: Bool = false
    let isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    let animationNamespace: Namespace.ID // Animation namespace from LayoutView
    
    @State private var adjacentCount: Int = 0
    @State private var activeReservationAdjacentCount: Int = 0

    var body: some View {
        // Calculate cell size from LayoutUIManager
        let cellSize = layoutUI.cellSize
        
        // Calculate table's current position
        let tableWidth = CGFloat(table.width) * cellSize
        let tableHeight = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + tableWidth / 2
        let yPos = CGFloat(table.row) * cellSize + tableHeight / 2
        
        // Determine if the table is highlighted
        let isHighlighted = store.tableAnimationState[table.id] ?? false
        
        // Get active reservation
        let activeReservation = reservationService.findActiveReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        )
        
        
        ZStack {
            
            let uniqueKey = UUID().uuidString

            // Determine table style and ID suffix dynamically
            let (fillColor, idSuffix): (Color, String) = {
                if isDragging {
                    return (Color(hex: "#AEAB7D").opacity(0.2), "dragging")
                } else if activeReservation != nil {
                    return (Color(hex: "#6A798E"), "reserved")
                } else if isLayoutLocked {
                    return (Color(hex: "#A3B7D2"), "locked")
                } else {
                    return (Color(hex: "#A3B7D2"), "default")
                }
            }()

            RoundedRectangle(cornerRadius: 4.0)
                .fill(fillColor)
                .frame(width: tableWidth * (isDragging ? 1.2 : 1.0), height: tableHeight * (isDragging ? 1.2 : 1.0))
                .matchedGeometryEffect(
                    id: "\(table.id)-\(selectedDate)-\(selectedCategory.rawValue)-\(idSuffix)-\(uniqueKey)",
                    in: animationNamespace
                )

            // Stroke overlay
            RoundedRectangle(cornerRadius: 4.0)
                .stroke(
                    isDragging ? Color.yellow.opacity(0.5) :
                    (isHighlighted ? Color(hex: "#9DA3D0") :
                        (isLayoutLocked ? Color(hex: "#CB7C1F") : Color(hex: "#3B4A5E"))),
                    style: isDragging
                        ? StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3]) // Dashed when dragging
                    : StrokeStyle(lineWidth: (isLayoutLocked ? 3 : 2)) // Solid for other states
                )
                .frame(
                    width: tableWidth,
                    height: tableHeight
                )
            
            // Reservation information or table name
            if let reservation = activeReservation {
                reservationInfo(reservation: reservation, tableWidth: tableWidth, tableHeight: tableHeight)
            } else {
                tableName(name: table.name, tableWidth: tableWidth, tableHeight: tableHeight)
            }
        }
        .contextMenu {
            Button("Delete") {
                print("Tapped delete")
            }
        }
        .position(x: xPos, y: yPos)
        .offset(dragOffset)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    guard !isLayoutLocked else { return }
                    state = value.translation
                }
                .onChanged { value in
                    guard !isLayoutLocked else { return }
                    isDragging = true // Activate dragging state
                }
                .onEnded { value in
                    isDragging = false // Reset dragging state
                    handleDragEnd(
                        translation: value.translation,
                        cellSize: cellSize,
                        tableWidth: tableWidth,
                        tableHeight: tableHeight,
                        xPos: xPos,
                        yPos: yPos
                    )
                }
            )
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.3).onEnded {_ in
            handleTap()
        })
    }

    // MARK: - Subviews
    private func reservationInfo(reservation: Reservation, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(reservation.name)
                .bold()
                .font(.headline)
            Text("\(reservation.numberOfPersons) pers.")
                .font(.footnote)
            Text("\(reservation.phone)")
                .font(.footnote)
            if let remaining = TimeHelpers.remainingTimeString(endTime: reservation.endTime, currentTime: currentTime) {
                Text("Rimasto: \(remaining)")
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            if let duration = TimeHelpers.availableTimeString(endTime: reservation.endTime, startTime: reservation.startTime) {
                Text("\(duration)")
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .frame(maxWidth: tableWidth, maxHeight: tableHeight)
        .background(Color.clear)
        .cornerRadius(4)
        .frame(width: tableWidth, height: tableHeight)
    }

    private func tableName(name: String, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        Text(name)
            .bold()
            .foregroundColor(.blue)
            .font(.caption)
            .padding(4)
            .background(Color.white.opacity(0.7))
            .cornerRadius(4)
            .frame(width: tableWidth - 8, height: tableHeight - 8)
    }

    // MARK: - Gestures
    private func dragGesture(cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat, xPos: CGFloat, yPos: CGFloat) -> some Gesture {
            DragGesture(minimumDistance: 20)
            .updating($dragOffset) { value, state, _ in
                guard !isLayoutLocked else { return }
                state = value.translation
            }
            .onChanged { value in
                guard !isLayoutLocked else { return }
                
                // Define a threshold distance (e.g., 10 points)
                let dragThreshold: CGFloat = 10
                
                if !hasMoved {
                    if abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold {
                        hasMoved = true
                        isDragging = true // Activate dragging state
                    }
                }
            }
            .onEnded { value in
                if hasMoved {
                    handleDragEnd(
                        translation: value.translation,
                        cellSize: cellSize,
                        tableWidth: tableWidth,
                        tableHeight: tableHeight,
                        xPos: xPos,
                        yPos: yPos
                    )
                }
                isDragging = false // Reset dragging state
                hasMoved = false   // Reset movement tracking
            }
    }

    // MARK: - Actions
    private func handleTap() {
        guard selectedCategory != .noBookingZone else {
            showingNoBookingAlert = true
            return
        }

        let startTimeString = DateHelper.formatTime(currentTime)
        let endTimeString = TimeHelpers.calculateEndTime(startTime: startTimeString, category: selectedCategory)

        let isOccupied = store.tableAssignmentService.isTableOccupied(
            table,
            reservations: store.reservations,
            date: selectedDate,
            startTime: startTimeString,
            endTime: endTimeString
        )

        if !isOccupied {
            onTapEmpty()
        } else if let reservation = reservationService.findActiveReservation(for: table, date: selectedDate, time: currentTime) {
            onEditReservation(reservation)
        }
        
        
        print("\(adjacentCount)")
        print("\(activeReservationAdjacentCount)")
    }

    private func handleDragEnd(translation: CGSize, cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat, xPos: CGFloat, yPos: CGFloat) {
        layoutUI.isDragging = false
        guard !isLayoutLocked else {
            store.currentlyDraggedTableID = nil
            return
        }

        let deltaCols = Int(round(translation.width / cellSize))
        let deltaRows = Int(round(translation.height / cellSize))

        let newRow = table.row + deltaRows
        let newCol = table.column + deltaCols

        let proposedFrame = CGRect(
            x: xPos + translation.width - tableWidth / 2,
            y: yPos + translation.height - tableHeight / 2,
            width: tableWidth,
            height: tableHeight
        )

        print("Proposed Frame: \(proposedFrame)")
        print("Grid Bounds: \(gridData.gridBounds)")
        print("Excluded Regions: \(gridData.excludedRegions)")
        
        // Check for blockage before moving the table
        if !gridData.isBlockage(proposedFrame) {
            print("Blockage detected! Table move rejected.")
            store.currentlyDraggedTableID = nil
            return
        }

        // Delegate the move to LayoutUIManager
        layoutUI.attemptMove(table: table, to: (row: newRow, col: newCol))
        
        // Retrieve the updated table from layoutUI.tables
        guard let updatedTable = layoutUI.tables.first(where: { $0.id == table.id }) else {
            print("Error: Updated table not found after move!")
            return
        }
        
        let tables = layoutUI.tables
        store.saveTables(tables, for: selectedDate, category: selectedCategory)
        updateAdjacencyCounts(table: updatedTable, activeTables: tables)
        print("Table positions after move:")
        store.reservations.forEach { reservation in
            print("Reservation \(reservation.id) has tables:")
            reservation.tables.forEach { _ in print("Table \(table.id) at row \(table.row), column \(table.column)") }
        }
        isLayoutReset = false
        print("Saved tables for \(selectedDate) and \(selectedCategory)!")
        store.currentlyDraggedTableID = nil
        print("\(adjacentCount)")
        print("\(activeReservationAdjacentCount)")
    }

    private func updateAdjacencyCounts(table: TableModel, activeTables: [TableModel]) {
        print("Updating adjacency counts for table: \(table.id) [updateAdjacencyCounts() in TableView]")
        print("Date: \(selectedDate), Time: \(currentTime) [updateAdjacencyCounts() in TableView]")

        guard let combinedDateTime = combine(date: selectedDate, time: currentTime) else {
            print("Failed to combine date and time.")
            return
        }

        // Pass `activeTables` to `isTableAdjacent`
        let adjacency = store.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables)
        adjacentCount = adjacency.adjacentCount

        // Process shared reservation tables using a queue
        var visitedTables = Set<Int>()
        var queue = [table]

        while !queue.isEmpty {
            let currentTable = queue.removeFirst()
            if visitedTables.contains(currentTable.id) {
                continue
            }
            visitedTables.insert(currentTable.id)

            // Pass `activeTables` to `isAdjacentWithSameReservation`
            let sharedTables = store.isAdjacentWithSameReservation(for: currentTable, combinedDateTime: combinedDateTime, activeTables: activeTables)
            for sharedTable in sharedTables where !visitedTables.contains(sharedTable.id) {
                queue.append(sharedTable)
            }

            if currentTable.id == table.id {
                activeReservationAdjacentCount = sharedTables.count
            }
        }

        print("Updated adjacentCount: \(adjacentCount) [updateAdjacencyCounts() in TableView]")
        print("Active reservation adjacent count: \(activeReservationAdjacentCount) [updateAdjacencyCounts() in TableView]")
    }
    
    func combine(date: Date, time: Date) -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second

        return calendar.date(from: combinedComponents)
    }
    
}
