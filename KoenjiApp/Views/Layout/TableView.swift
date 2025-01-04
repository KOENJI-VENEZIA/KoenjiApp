import SwiftUI

struct TableView: View {
    let table: TableModel
    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    let currentTime: Date
    
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @ObservedObject var layoutUI: LayoutUIManager

    @Binding var showingNoBookingAlert: Bool

    let onTapEmpty: () -> Void
    let onEditReservation: (Reservation) -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false // State to track dragging
    @State private var isHeld: Bool = false // State for long press hold
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID // Animation namespace from LayoutView

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
        let activeReservation = store.activeReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        )
        
        
        ZStack {
            // Table rectangle with conditional coloring
            RoundedRectangle(cornerRadius: 4.0)
                .fill(isDragging ? Color.yellow.opacity(0.2)
                      : (activeReservation != nil ? Color.green.opacity(0.3)
                         : (isLayoutLocked ? Color.orange.opacity(0.3) : Color.clear)))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 4.0)
                        .stroke(isDragging ? Color.yellow.opacity(0.5)
                                : (isHighlighted ? Color(hex: "#9DA3D0") : (isLayoutLocked ? Color.orange : Color.blue)),
                                lineWidth: 2)
                )
                .frame(width: tableWidth * (isDragging ? 1.2 : 1.0), height: tableHeight * (isDragging ? 1.2 : 1.0)) // Scale up if held
                .matchedGeometryEffect(id: table.id, in: animationNamespace)
            
            // Flash overlay for highlighted tables
            RoundedRectangle(cornerRadius: 4.0)
                .fill(isHighlighted && !isDragging ? Color(hex: "#9DA3D0").opacity(0.4) : Color.clear)
                .animation(.easeInOut(duration: 0.5), value: isHighlighted)
                .frame(width: tableWidth, height: tableHeight)
                .allowsHitTesting(false)
            
            
            // Reservation information or table name
            if let reservation = activeReservation {
                reservationInfo(reservation: reservation, tableWidth: tableWidth, tableHeight: tableHeight)
            } else {
                tableName(name: table.name, tableWidth: tableWidth, tableHeight: tableHeight)
            }
        }
        .position(x: xPos, y: yPos)
        .offset(dragOffset)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onChanged { _ in
                    isHeld = true // Activate hold state
                }
                .sequenced(before: DragGesture(minimumDistance: 20))
                .updating($dragOffset) { value, state, _ in
                    switch value {
                    case .second(true, let dragValue?):
                        guard !isLayoutLocked else { return }
                        state = dragValue.translation
                    default:
                        break
                    }
                }
                .onChanged { value in
                    switch value {
                    case .second(true, _):
                        isDragging = true // Activate dragging state
                    default:
                        break
                    }
                }
                .onEnded { value in
                    isHeld = false // Reset hold state
                    switch value {
                    case .second(true, let dragValue?):
                        isDragging = false // Reset dragging state
                        handleDragEnd(
                            translation: dragValue.translation,
                            cellSize: cellSize,
                            tableWidth: tableWidth,
                            tableHeight: tableHeight,
                            xPos: xPos,
                            yPos: yPos
                        )
                    default:
                        isDragging = false // Ensure state is reset
                    }
                }
        )
        .simultaneousGesture(TapGesture().onEnded {
            handleTap()
        })
    }

    // MARK: - Subviews
    private func reservationInfo(reservation: Reservation, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(reservation.name)
                .bold()
                .font(.caption)
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
        .background(Color.white.opacity(0.7))
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
        LongPressGesture(minimumDuration: 0.1)
            .onChanged { _ in
                isHeld = true // Activate hold state
            }
            .sequenced(before: DragGesture(minimumDistance: 20))
            .updating($dragOffset) { value, state, _ in
                switch value {
                case .second(true, let dragValue?):
                    guard !isLayoutLocked else { return }
                    state = dragValue.translation
                default:
                    break
                }
            }
            .onChanged { value in
                switch value {
                case .second(true, _):
                    isDragging = true // Activate dragging state
                default:
                    break
                }
            }
            .onEnded { value in
                isHeld = false // Reset hold state
                switch value {
                case .second(true, let dragValue?):
                    isDragging = false // Reset dragging state
                    handleDragEnd(
                        translation: dragValue.translation,
                        cellSize: cellSize,
                        tableWidth: tableWidth,
                        tableHeight: tableHeight,
                        xPos: xPos,
                        yPos: yPos
                    )
                default:
                    isDragging = false // Ensure state is reset
                }
            }
    }

    // MARK: - Actions
    private func handleTap() {
        guard selectedCategory != .noBookingZone else {
            showingNoBookingAlert = true
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let startTimeString = formatter.string(from: currentTime)
        let endTimeString = TimeHelpers.calculateEndTime(startTime: startTimeString, category: selectedCategory)

        let isOccupied = store.tableAssignmentService.isTableOccupied(
            table,
            reservations: store.reservations,
            date: selectedDate,
            startTimeString: startTimeString,
            endTimeString: endTimeString
        )

        if !isOccupied {
            onTapEmpty()
        } else if let reservation = store.activeReservation(for: table, date: selectedDate, time: currentTime) {
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
            x: xPos + translation.width - tableWidth / 2,
            y: yPos + translation.height - tableHeight / 2,
            width: tableWidth,
            height: tableHeight
        )

        if !gridData.isBlockage(proposedFrame) {
            layoutUI.showInvalidMoveFeedback()
            store.currentlyDraggedTableID = nil
            return
        }

        switch store.moveTable(table, toRow: newRow, toCol: newCol) {
        case .move:
            store.layoutManager.saveLayout(for: selectedDate, category: selectedCategory)
        case .invalid:
            layoutUI.showInvalidMoveFeedback()
        }
        store.currentlyDraggedTableID = nil
    }
}
