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
    
    enum DragState {
        case idle
        case dragging(offset: CGSize)
        case started(offset: CGSize)
    }
    @State private var dragState: DragState = .idle
    
    
    
    @State private var isDragging: Bool = false // State to track dragging
    @State private var isHeld: Bool = false // State for long press hold
    @State private var hasMoved: Bool = false
    let isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    let animationNamespace: Namespace.ID // Animation namespace from LayoutView
    let onTableUpdated: (TableModel) -> Void

        
    private var cellSize: CGFloat { return layoutUI.cellSize }
    
    private var tableFrame: CGRect {
        let cellSize = layoutUI.cellSize
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }

    var body: some View {
        // Determine if the table is highlighted
        let isHighlighted = store.tableAnimationState[table.id] ?? false
        
        // Get active reservation
        let activeReservation = reservationService.findActiveReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        )
        
        let isDragging = {
            if case .dragging = dragState { return true }
            return false
        }()
        
        let isLunch = {
            if case .lunch = selectedCategory { return true }
            return false
        }()
        
        
        ZStack {
            
            let uniqueKey = UUID().uuidString

            // Determine table style and ID suffix dynamically
            let (fillColor, idSuffix): (Color, String) = {
                if isDragging {
                    return (Color(hex: "#AEAB7D").opacity(0.2), "dragging")
                } else if activeReservation != nil {
                    return (isLunch ? Color.active_table_lunch : Color.active_table_dinner, "reserved")
                } else if isLayoutLocked {
                    return (Color(hex: "#A3B7D2"), "locked")
                } else {
                    return (Color(hex: "#A3B7D2"), "default")
                }
            }()

            RoundedRectangle(cornerRadius: 8.0)
                .fill(fillColor)
                .frame(width: tableFrame.width * (isDragging ? 1.2 : 1.0), height: tableFrame.height * (isDragging ? 1.2 : 1.0))
                .matchedGeometryEffect(
                    id: "\(table.id)-\(selectedDate)-\(selectedCategory.rawValue)-\(idSuffix)-\(uniqueKey)",
                    in: animationNamespace
                )

            // Stroke overlay
            RoundedRectangle(cornerRadius: 8.0)
                .stroke(
                    isDragging ? Color.yellow.opacity(0.5) :
                    (isHighlighted ? Color(hex: "#9DA3D0") :
                        (isLayoutLocked ? (isLunch ? Color.layout_locked_lunch : Color.layout_locked_dinner) : (isLunch ? Color.layout_unlocked_lunch : Color.layout_unlocked_dinner))),
                    style: isDragging
                        ? StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3]) // Dashed when dragging
                    : StrokeStyle(lineWidth: (isLayoutLocked ? 3 : 2)) // Solid for other states
                )
                .frame(
                    width: tableFrame.width,
                    height: tableFrame.height
                )
            
            // Reservation information or table name
            Group {
                if let reservation = activeReservation {
                    reservationInfo(reservation: reservation, tableWidth: tableFrame.width, tableHeight: tableFrame.height)
                } else {
                    tableName(name: table.name, tableWidth: tableFrame.width, tableHeight: tableFrame.height)
                }
            }
        }
        .contextMenu {
            Button("Delete") {
                print("Tapped delete")
            }
        }
        .position(x: tableFrame.minX, y: tableFrame.minY)
        .offset(dragOffset)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    guard !isLayoutLocked else { return }
                    state = value.translation
                }
                .onChanged { value in
                    guard !isLayoutLocked else { return }
                    dragState = .dragging(offset: value.translation)
                }
                .onEnded { value in
                    dragState = .idle // Reset dragging state
                    handleDragEnd(
                        translation: value.translation,
                        cellSize: cellSize,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height,
                        xPos: tableFrame.minX,
                        yPos: tableFrame.minY
                    )
                }
            )
        .simultaneousGesture(TapGesture(count: 2).onEnded {_ in
            dragState = .idle
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
                .opacity(0.8)

            Text("\(reservation.phone)")
                .font(.footnote)
                .opacity(0.8)

            if let remaining = TimeHelpers.remainingTimeString(endTime: reservation.endTime, currentTime: currentTime) {
                Text("Rimasto: \(remaining)")
                    .foregroundColor(Color(hex: "#B4231F"))
                    .font(.footnote)
            }
            if let duration = TimeHelpers.availableTimeString(endTime: reservation.endTime, startTime: reservation.startTime) {
                Text("\(duration)")
                    .foregroundColor(Color(hex: "#B4231F"))
                    .font(.footnote)
            }
        }
        .background(Color.clear)
        .cornerRadius(8)
        .frame(width: tableFrame.width, height: tableFrame.height)
    }

    private func tableName(name: String, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        Text(name)
            .bold()
            .foregroundColor(.blue)
            .font(.headline)
            .padding(4)
            .background(Color.white.opacity(0.7))
            .cornerRadius(8)
            .frame(width: tableFrame.width - 5, height: tableFrame.height - 5)
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
                
                switch dragState {
                case .idle:
                    // If the drag distance exceeds the threshold, move to the "started" state
                    if abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold {
                        dragState = .started(offset: value.translation)
                    }
                case .started, .dragging:
                    // Update the drag state with the current offset
                    dragState = .dragging(offset: value.translation)
                }
            }
            .onEnded { value in
                switch dragState {
                case .dragging(let offset):
                    // Perform the drag end operation only if it was in the dragging state
                    handleDragEnd(
                        translation: offset,
                        cellSize: cellSize,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height,
                        xPos: tableFrame.minX,
                        yPos: tableFrame.minY
                    )
                default:
                    // No action needed for other states
                    break
                }
                
                // Reset drag state to idle
                dragState = .idle
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
            x: xPos + translation.width - tableFrame.width / 2,
            y: yPos + translation.height - tableFrame.height / 2,
            width: tableFrame.width,
            height: tableFrame.height
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
        layoutUI.attemptMove(table: table, to: (row: newRow, col: newCol), for: selectedDate, activeTables: layoutUI.tables)
        
        // Retrieve the updated table from layoutUI.tables
        guard let updatedTable = layoutUI.tables.first(where: { $0.id == table.id }) else {
            print("Error: Updated table not found after move!")
            return
        }
        
        let tables = layoutUI.tables
        store.saveTables(tables, for: selectedDate, category: selectedCategory)
        if let updatedLayout = store.cachedLayouts[store.keyFor(date: selectedDate, category: selectedCategory)] {
            print("Updated cache for \(selectedCategory):")
            for table in updatedLayout {
                print("Updated table \(table.name) at (\(table.row), \(table.column))")
            }
        }
        
        onTableUpdated(updatedTable)
        isLayoutReset = false
        store.currentlyDraggedTableID = nil
        
    }
    
}
