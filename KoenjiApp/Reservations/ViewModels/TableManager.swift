//
//  LayoutUIManager.swift
//  KoenjiApp
//
//  Updated to manage separate layouts per LayoutPageView.
//

import SwiftUI

// To update to: TableLayoutManager
/// Manages UI-related state and interactions for table layout.
@Observable
class LayoutUIManager {
    // MARK: - Dragging State
    /// The table currently being dragged by the user.
     var draggingTable: TableModel? = nil
    /// The offset of the dragged table from its original position.
     var draggingOffset: CGSize = .zero
    /// Indicates whether a table is currently being dragged.
     var isDragging: Bool = false

    // MARK: - Pop-up / Alert
    /// Whether an alert is currently visible.
     var showAlert = false
    /// The message displayed in the alert.
     var alertMessage = ""

    // MARK: - Grid / Cell Size
    /// The size of a single grid cell, used for layout calculations.
    let cellSize: CGFloat = 40
    /// The list of tables currently displayed in the layout.
    var tables: [TableModel] = [] 

    // MARK: - Dependencies
    /// A reference to the `ReservationStore` for table data and layout operations.
    private let store: ReservationStore
    private let reservationService: ReservationService
    private let layoutServices: LayoutServices

    @MainActor
    init(store: ReservationStore, reservationService: ReservationService, layoutServices: LayoutServices) {
        self.store = store
        self.reservationService = reservationService
        self.layoutServices = layoutServices
    }
    
    // MARK: - Dragging Helpers

    /// Updates the state for a table currently being dragged.
    func setDraggingState(table: TableModel, offset: CGSize) {
        draggingTable = table
        draggingOffset = offset
    }

    /// Finalizes a drag operation, saving the layout state.

    func setTableVisible(_ table: TableModel) {
        guard let index = tables.firstIndex(where: { $0.id == table.id }) else { return }
        tables[index].isVisible = true
    }
    
    func setTableInvisible(_ table: TableModel) {
        guard let index = tables.firstIndex(where: { $0.id == table.id }) else { return }
        tables[index].isVisible = false
    }

    /// Attempts to move a table to a new position.
    func attemptMove(table: TableModel, to newPosition: (row: Int, col: Int), for date: Date, activeTables: [TableModel], category: Reservation.ReservationCategory) {
//        guard let layoutServices = layoutServices else { return }
        let newTable = TableModel(
            id: table.id,
            name: table.name,
            maxCapacity: table.maxCapacity,
            row: newPosition.row,
            column: newPosition.col
        )

        if layoutServices.canPlaceTable(newTable, for: date, category: category, activeTables: activeTables) {
            updateTablePosition(from: table, to: newTable)
            print("attemptMove: Successfully moved \(table.name) to (\(newPosition.row), \(newPosition.col))")
        } else {
            print("attemptMove: Move failed for \(table.name) to (\(newPosition.row), \(newPosition.col))")
        }
    }

    /// Updates the grid and data for a table's new position.
    private func updateTablePosition(from oldTable: TableModel, to newTable: TableModel) {
        layoutServices.unmarkTable(oldTable)
        layoutServices.markTable(newTable, occupied: true)

       
        if let index = tables.firstIndex(where: { $0.id == oldTable.id }) {
            tables[index] = newTable
        }
    }

    // MARK: - Feedback

    /// Displays feedback for invalid move attempts.
    func showInvalidMoveFeedback() {
        alertMessage = String(localized: "Impossibile posizionare il tavolo in questa posizione (fuori griglia o sovrapposto).")
        showAlert = true
    }

    // MARK: - Geometry

    /// Calculates the combined rectangle for a reservation's tables.
    func combinedRect(for reservation: Reservation) -> CGRect {
        guard let firstTable = reservation.tables.first else { return .zero }

        let minRow = reservation.tables.map(\.row).min() ?? firstTable.row
        let minCol = reservation.tables.map(\.column).min() ?? firstTable.column
        let maxRow = reservation.tables.map { $0.row + $0.height }.max() ?? (firstTable.row + firstTable.height)
        let maxCol = reservation.tables.map { $0.column + $0.width }.max() ?? (firstTable.column + firstTable.width)

        let width = CGFloat(maxCol - minCol) * cellSize
        let height = CGFloat(maxRow - minRow) * cellSize

        return CGRect(x: CGFloat(minCol) * cellSize, y: CGFloat(minRow) * cellSize, width: width, height: height)
    }

    /// Calculates the rectangle for a table based on its grid position.
    func calculateTableRect(for table: TableModel) -> CGRect {
        let x = CGFloat(table.column) * cellSize
        let y = CGFloat(table.row) * cellSize
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        return CGRect(x: x, y: y, width: width, height: height)
    }
}


