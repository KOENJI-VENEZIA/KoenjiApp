
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

    var body: some View {
        // Calculate cell size from LayoutViewModel
        let cellSize = layoutVM.cellSize

        // Calculate table's current position based on row and column
        let tableWidth = CGFloat(table.width) * cellSize
        let tableHeight = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + tableWidth / 2
        let yPos = CGFloat(table.row) * cellSize + tableHeight / 2

        // Retrieve active reservation for the table
        let activeReservation = store.activeReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        )

        ZStack {
            Rectangle()
                .fill(activeReservation != nil ? Color.green.opacity(0.3) : Color.blue.opacity(0.15))
                .overlay(Rectangle().stroke(Color.blue, lineWidth: 2))
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
                .onChanged { _ in
                    layoutVM.isDragging = true
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

                    // Directly invoke moveTable from the store
                    let moveSuccess = store.moveTable(table, toRow: newRow, toCol: newCol)

                    if moveSuccess {
                        print("Table \(table.name) successfully moved or swapped.")
                        store.saveLayout(for: selectedDate, category: selectedCategory)
                        store.saveToDisk()
                    } else {
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
