// LayoutViewModel.swift
import SwiftUI

class LayoutUIManager: ObservableObject {
    // MARK: - Dragging State
    @Published var draggingTable: TableModel? = nil
    @Published var draggingOffset: CGSize = .zero
    @Published var isDragging: Bool = false

    // MARK: - Pop-up / Alert
    @Published var showAlert = false
    @Published var alertMessage = ""

    // MARK: - Grid / Cell size
    let cellSize: CGFloat = 40
    @Published var tables: [TableModel] = [] {
        didSet {
            objectWillChange.send() // Notify SwiftUI of changes
        }
    }

    // MARK: - Dependencies
    let store: ReservationStore

    init(store: ReservationStore) {
        self.store = store
        self.tables = store.tables
    }

    // MARK: - Dragging Helpers

    func updateDraggingPosition(table: TableModel, offset: CGSize) {
        draggingTable = table
        draggingOffset = offset
    }

    func handleDropEnded() {
        draggingTable = nil
        draggingOffset = .zero
        let date = Date() // Replace with the selected date
        let category: Reservation.ReservationCategory = .lunch // Replace with the selected category
        store.layoutManager.saveCurrentLayout(for: date, category: category)
    }

    func attemptMove(table: TableModel, to newPosition: (row: Int, col: Int)) {
        let newTable = TableModel(
            id: table.id,
            name: table.name,
            maxCapacity: table.maxCapacity,
            row: newPosition.row,
            column: newPosition.col
        )

        if store.canPlaceTable(newTable) {
            store.unmarkTable(table) // Unmark current position
            store.markTable(newTable, occupied: true) // Mark new position

            if let index = store.tables.firstIndex(where: { $0.id == table.id }) {
                store.tables[index] = newTable
            }

            print("attemptMove: Successfully moved \(table.name) to (\(newPosition.row), \(newPosition.col))")
        } else {
            print("attemptMove: Move failed for \(table.name) to (\(newPosition.row), \(newPosition.col))")
            showInvalidMoveFeedback()
        }
    }

    // MARK: - Validation and Feedback

    func showInvalidMoveFeedback() {
        alertMessage = "Impossibile posizionare il tavolo in questa posizione (fuori griglia o sovrapposto)."
        showAlert = true
    }

    // MARK: - Geometry

    func combinedRect(for reservation: Reservation) -> CGRect {
        let tables = reservation.tables
        guard let firstTable = tables.first else { return .zero }

        let minRow = tables.map(\.row).min() ?? firstTable.row
        let minCol = tables.map(\.column).min() ?? firstTable.column
        let maxRow = tables.map { $0.row + $0.height }.max() ?? (firstTable.row + firstTable.height)
        let maxCol = tables.map { $0.column + $0.width }.max() ?? (firstTable.column + firstTable.width)

        let width = CGFloat(maxCol - minCol) * cellSize
        let height = CGFloat(maxRow - minRow) * cellSize

        return CGRect(x: CGFloat(minCol) * cellSize, y: CGFloat(minRow) * cellSize, width: width, height: height)
    }

    func calculateTableRect(for table: TableModel) -> CGRect {
        let x = CGFloat(table.column) * cellSize
        let y = CGFloat(table.row) * cellSize
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
