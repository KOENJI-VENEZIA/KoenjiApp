import SwiftUI

struct TableDragView: View {
    let table: TableModel

    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    let currentTime: Date

    @EnvironmentObject var store: ReservationStore
    @ObservedObject var layoutVM: LayoutViewModel

    @Binding var showingNoBookingAlert: Bool

    let onTapEmpty: () -> Void
    let onEditReservation: (Reservation) -> Void

    @GestureState private var dragOffset: CGSize = .zero
    let isLayoutLocked: Bool

    @Namespace var animationNamespace // Define namespace here

    var body: some View {
        // Calculate cell size from LayoutViewModel
        let cellSize = layoutVM.cellSize

        // Calculate table's current position based on row and column
        let tableWidth = CGFloat(table.width) * cellSize
        let tableHeight = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + tableWidth / 2
        let yPos = CGFloat(table.row) * cellSize + tableHeight / 2

        // Determine if the table is highlighted (i.e., should flash)
        let isHighlighted = store.tableAnimationState[table.id] ?? false

        // Determine if the table is currently being dragged
        let isDragging = store.currentlyDraggedTableID == table.id

        // Retrieve active reservation for the table
        let activeReservation = store.activeReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        )

        ZStack {
            // Base Rectangle with conditional color change if dragging
            Rectangle()
                .fill(
                    isDragging ?
                        Color.yellow.opacity(0.3) : // Color when dragging
                        (activeReservation != nil ? Color.green.opacity(0.3) : Color.blue.opacity(0.15))
                )
                .overlay(
                    Rectangle().stroke(
                        isDragging ? Color.yellow : (isHighlighted ? Color.orange : Color.blue),
                        lineWidth: 2
                    )
                )
                .frame(width: tableWidth, height: tableHeight)
                .matchedGeometryEffect(id: table.id, in: animationNamespace) // Apply matchedGeometryEffect

            // Flash Overlay only for swapped tables (isHighlighted && not dragging)
            if isHighlighted && !isDragging {
                Rectangle()
                    .fill(Color.orange.opacity(0.4))
                    .frame(width: tableWidth, height: tableHeight)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: isHighlighted) // Match duration
                    .allowsHitTesting(false) // Ensure overlay doesn't block interactions
            }

            // Reservation Information
            if let reservation = activeReservation {
                VStack(spacing: 2) {
                    Text(reservation.name)
                        .bold()
                        .font(.caption)
                    Text("\(reservation.numberOfPersons) pers")
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
                .padding(4)
                .background(Color.white.opacity(0.7))
                .cornerRadius(4)
                .frame(width: tableWidth - 8, height: tableHeight - 8)
            } else {
                Text(table.name)
                    .bold()
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(4)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(4)
                    .frame(width: tableWidth - 8, height: tableHeight - 8)
            }
        }
        .position(x: xPos, y: yPos)
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { (value, state, _) in
                    guard !isLayoutLocked else { return }
                    state = value.translation
                }
                .onChanged { _ in
                    // Set the currently dragged table ID when drag starts
                    if !isDragging {
                        store.currentlyDraggedTableID = table.id
                    }
                }
                .onEnded { value in
                    layoutVM.isDragging = false
                    guard !isLayoutLocked else {
                        // Reset currentlyDraggedTableID if layout is locked
                        store.currentlyDraggedTableID = nil
                        return
                    }

                    let dx = value.translation.width
                    let dy = value.translation.height
                    let deltaCols = Int(round(dx / cellSize))
                    let deltaRows = Int(round(dy / cellSize))

                    print("Drag ended. dx: \(dx), dy: \(dy), deltaCols: \(deltaCols), deltaRows: \(deltaRows)")

                    let newRow = table.row + deltaRows
                    let newCol = table.column + deltaCols

                    // Invoke moveTable and check the result
                    let moveResult = store.moveTable(table, toRow: newRow, toCol: newCol)

                    switch moveResult {
                    case .swap(let swappedID):
                        print("Table \(table.name) successfully swapped with table ID \(swappedID).")
                        // Flash animation is handled within swapTables
                        store.saveLayout(for: selectedDate, category: selectedCategory)
                        store.saveToDisk()
                        
                    case .move:
                        print("Table \(table.name) successfully moved.")
                        store.saveLayout(for: selectedDate, category: selectedCategory)
                        store.saveToDisk()
                        
                    case .invalid:
                        print("Failed to move or swap table \(table.name).")
                        layoutVM.showInvalidMoveFeedback()
                    }

                    // Reset the currently dragged table ID
                    store.currentlyDraggedTableID = nil
                }
        )
        .onChange(of: isHighlighted) { newValue in
            if newValue && !isDragging {
                // The overlay will animate automatically due to state change
            }
        }
        .onTapGesture {
            guard selectedCategory != .noBookingZone else {
                showingNoBookingAlert = true
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            formatter.timeZone = TimeZone.current

            let startTimeString = formatter.string(from: currentTime)
            let endTimeString = TimeHelpers.calculateEndTime(startTime: startTimeString)

            let isOccupied = store.isTableOccupied(
                table,
                date: selectedDate,
                startTimeString: startTimeString,
                endTimeString: endTimeString
            )
            if !isOccupied {
                onTapEmpty()
            } else if let reservation = activeReservation {
                onEditReservation(reservation)
            }
        }
    }
}
