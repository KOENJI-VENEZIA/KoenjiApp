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

    // State variable for animation
    @State private var isSwapped: Bool = false

    var body: some View {
        // Calculate cell size
        let cellSize = layoutVM.cellSize
        let tableWidth = CGFloat(table.width) * cellSize
        let tableHeight = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + tableWidth / 2
        let yPos = CGFloat(table.row) * cellSize + tableHeight / 2
        
        let isHighlighted = store.tableAnimationState[table.id] ?? false


        // Retrieve active reservation for the table
        let activeReservation = store.activeReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        )

        ZStack {
            Rectangle()
                .fill(
                    isHighlighted
                        ? Color.orange.opacity(0.4) // Highlight during swap
                        : (activeReservation != nil ? Color.green.opacity(0.3) : Color.blue.opacity(0.15))
                )
                .overlay(Rectangle().stroke(isHighlighted ? Color.orange : Color.blue, lineWidth: 2))
                .frame(width: tableWidth, height: tableHeight)

            if let reservation = activeReservation {
                VStack(spacing: 2) {
                    Text(reservation.name).bold().font(.caption)
                    Text("\(reservation.numberOfPersons) pers").font(.footnote)
                    if let remaining = TimeHelpers.remainingTimeString(endTime: reservation.endTime, currentTime: currentTime) {
                        Text("Rimasto: \(remaining)").foregroundColor(.red).font(.footnote)
                    }
                    if let duration = TimeHelpers.availableTimeString(endTime: reservation.endTime, startTime: reservation.startTime) {
                        Text("\(duration)").foregroundColor(.red).font(.footnote)
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.7))
                .cornerRadius(4)
                .frame(width: tableWidth - 8, height: tableHeight - 8)
            } else {
                Text(table.name)
                    .bold().foregroundColor(.blue).font(.caption)
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
                .onEnded { value in
                    layoutVM.isDragging = false
                    guard !isLayoutLocked else { return }

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
                    case .swap:
                        print("Table \(table.name) successfully swapped.")
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isSwapped = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                isSwapped = false
                            }
                        }
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
                }
        )
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
