import SwiftUI

/// A view model that handles layout geometry computations for manual dragging.
class LayoutViewModel: ObservableObject {
    // MARK: - Dragging State
    @Published var draggingTable: TableModel? = nil
    @Published var draggingOffset: CGSize = .zero

    // MARK: - Pop-up / Alert
    @Published var showAlert = false
    @Published var alertMessage = ""

    @Published var isDragging: Bool = false

    // MARK: - Grid / Cell size
    /// The cell size in our grid. You can adjust this for spacing and layout dimensions.
    let cellSize: CGFloat = 40

    /// The set of tables that the view should display
    @Published var tables: [TableModel] = [] {
        didSet {
            objectWillChange.send() // Notify SwiftUI of changes
        }
    }

    let store: ReservationStore

    // MARK: - Initialization
    init(store: ReservationStore) {
        self.store = store
        self.tables = store.tables
    }

    func syncToStore(in store: ReservationStore) {
        store.tables = self.tables
    }

    // MARK: - Dragging Helpers

    /// Called while user drags. Updates the dragging state.
    func updateDraggingPosition(table: TableModel, offset: CGSize) {
        draggingTable = table
        draggingOffset = offset
    }

    /// Called when user drops the table at some location.
    /// store.moveTable returns false if out of bounds or overlap → we show an alert.
    func attemptMove(table: TableModel, to newPosition: (row: Int, col: Int), in store: ReservationStore) {
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




    /// Resets the drag state and saves the layout.
    func handleDropEnded() {
        draggingTable = nil
        draggingOffset = .zero
        saveCurrentLayout()
    }

    /// Saves the current layout to the store and disk.
    private func saveCurrentLayout() {
        let date = Date() // Replace with the selected date
        let category: Reservation.ReservationCategory = .lunch // Replace with the selected category
        store.saveLayout(for: date, category: category)
        store.saveToDisk()
        print("handleDropEnded: Layout saved for \(category.rawValue) on \(date).")
    }

    func resetLayout(for date: Date, category: Reservation.ReservationCategory, in store: ReservationStore) {
        // Reset tables to the default layout
        self.tables = store.loadDefaultLayout(for: date, category: category)

        // Clear any invalid or cached grid state
        store.loadTables() // Ensure the grid is reset properly

        // Save the reset layout to the store and persist it to disk
        store.saveLayout(for: date, category: category)
        store.saveToDisk()

        // Debugging logs
        print("resetLayout: Layout reset for \(category.rawValue) on \(date).")
    }

    // MARK: - Validation and Feedback

    func showInvalidMoveFeedback() {
        alertMessage = "Impossibile posizionare il tavolo in questa posizione (fuori griglia o sovrapposto)."
        showAlert = true
    }

    func isPositionValid(table: TableModel, newRow: Int, newCol: Int, store: ReservationStore) -> Bool {
        let totalRows = store.totalRows
        let totalColumns = store.totalColumns

        print("Debug: Validating position for table \(table.name) to (\(newRow), \(newCol))")

        // Check bounds
        guard newRow >= 0, newCol >= 0,
              newRow + table.height <= totalRows,
              newCol + table.width <= totalColumns else {
            print("Debug: Out of bounds for (\(newRow), \(newCol)).")
            return false
        }

        // Check overlap for the full rectangle
        let hypotheticalTable = TableModel(
            id: table.id,
            name: table.name,
            maxCapacity: table.maxCapacity,
            row: newRow,
            column: newCol
        )
        let canPlace = store.canPlaceTable(hypotheticalTable)
        print("Debug: Can place at (\(newRow), \(newCol)): \(canPlace)")

        return canPlace
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



    /// Calculates the rectangle for a table based on its grid position.
    func calculateTableRect(for table: TableModel) -> CGRect {
        let x = CGFloat(table.column) * cellSize
        let y = CGFloat(table.row) * cellSize
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
