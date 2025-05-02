import Foundation
import SwiftUI

extension Notification.Name {
    static let clusterCacheInvalidation = Notification.Name("clusterCacheInvalidation")
    static let tableUpdated = Notification.Name("tableUpdated")
    static let tableCreated = Notification.Name("tableCreated")
    static let tableDeleted = Notification.Name("tableDeleted")
}
/// Service for managing table-related operations
class TableService: ObservableObject {
    private let layoutServices: LayoutServices
    private let clusterStore: ClusterStore
    private let clusterServices: ClusterServices
    private let tableStore: TableStore
    private let layoutCache: LayoutCache
    
    init(layoutServices: LayoutServices, clusterStore: ClusterStore, clusterServices: ClusterServices, tableStore: TableStore = TableStore.shared, layoutCache: LayoutCache) {
        self.layoutServices = layoutServices
        self.clusterStore = clusterStore
        self.clusterServices = clusterServices
        self.tableStore = tableStore
        self.layoutCache = layoutCache

        setupNotificationObservers()
    }
    
    // MARK: - Observer Setup
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClusterCacheInvalidation),
            name: .clusterCacheInvalidation,
            object: nil
        )
    }

    @objc func handleClusterCacheInvalidation(_ notification: Notification) {
        if let reservation = notification.object as? Reservation {
            invalidateClusterCache(for: reservation)
        }
    }

    // MARK: - Table Management
    /// Toggles the visibility of a table
    func toggleTableVisibility(tableId: Int) -> TableModel? {
        guard var table = tableStore.findTable(withId: tableId) else {
            Task { @MainActor in
                AppLog.warning("Attempted to toggle visibility of non-existent table with ID: \(tableId)")
            }
            return nil
        }
        
        table = TableModel(
            id: table.id,
            name: table.name,
            maxCapacity: table.maxCapacity,
            row: table.row,
            column: table.column,
            adjacentCount: table.adjacentCount,
            activeReservationAdjacentCount: table.activeReservationAdjacentCount,
            isVisible: !table.isVisible
        )
        
        tableStore.addOrUpdateTable(table)
        
        // Notify about the update
        NotificationCenter.default.post(
            name: .tableUpdated,
            object: table
        )
        
        Task { @MainActor in
            AppLog.info("Toggled visibility of table \(table.name) (ID: \(table.id)) to \(table.isVisible)")
        }
        
        return table
    }
    
    /// Reset tables to base tables
    func resetTables() async {
        await tableStore.resetToBaseTables()
        
        // Reinitialize the grid with the base tables
        layoutServices.initializeGrid(with: tableStore.baseTables)
    }
    
    /// Fetch all tables
    func getAllTables() -> [TableModel] {
        return tableStore.tables
    }
    
    func getTableById(id: Int) -> TableModel? {
        return tableStore.findTable(withId: id)
    }
    
    /// Find tables that can accommodate a specific party size
    func findTablesForPartySize(partySize: Int) -> [TableModel] {
        let suitableTables = tableStore.tables.filter { $0.maxCapacity >= partySize && $0.isVisible }
        
        return suitableTables.sorted { $0.maxCapacity < $1.maxCapacity }
    }

    // MARK: - Existing Methods
    
    /// Invalidates the cluster cache for the given reservation
    func invalidateClusterCache(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate else {
            Task { @MainActor in
                AppLog.error("Failed to parse dateString \(reservation.normalizedDate ?? Date()). Cache invalidation skipped.")
            }
            return
        }
        self.clusterStore.invalidateClusterCache(for: reservationDate, category: reservation.category)
    }
    
    /// Ensures all confirmed reservations have tables assigned
    func ensureConfirmedReservationsHaveTables(resCache: CurrentReservationsCache) {
        Task { @MainActor in
            AppLog.info("Scanning database for confirmed reservations without tables...")
        }
        
        var updatedCount = 0
        var failedCount = 0
        
        let reservationsToCheck = resCache.getAllReservations()
        
        for reservation in reservationsToCheck {
            if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
                Task { @MainActor in
                    AppLog.warning("⚠️ Found confirmed reservation with no tables: \(reservation.name) (ID: \(reservation.id))")
                }
                
                let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    var updatedReservation = reservation
                    updatedReservation.tables = assignedTables
                    
                    SQLiteManager.shared.updateReservation(updatedReservation)
                    
                    resCache.addOrUpdateReservation(updatedReservation)
                    
                    Task { @MainActor in
                        AppLog.info("✅ Auto-assigned \(assignedTables.count) tables to stored reservation: \(updatedReservation.name)")
                    }
                    updatedCount += 1
                    
                case .failure(let error):
                    Task { @MainActor in
                        AppLog.error("❌ Failed to auto-assign tables to stored reservation: \(error.localizedDescription)")
                    }
                    failedCount += 1
                }
            }
        }
        
        Task { @MainActor in
            AppLog.info("Database scan complete. Updated \(updatedCount) reservations, failed to update \(failedCount) reservations.")
        }
    }
    
    /// Updates adjacency counts for tables in a reservation
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            Task { @MainActor in
                AppLog.warning("Invalid reservation date or time for updating adjacency counts.")
            }
            return
        }

        let activeTables = layoutServices.getTables(for: reservationDate, category: reservation.category)

        for table in reservation.tables {
            let adjacentTables = layoutServices.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables)
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id}) {
                layoutServices.tables[index].adjacentCount = adjacentTables.adjacentCount
            }
            
            let sharedTables = layoutServices.isAdjacentWithSameReservation(for: table, combinedDateTime: combinedDateTime, activeTables: activeTables)

            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id }) {
                layoutServices.tables[index].activeReservationAdjacentCount = sharedTables.count
            }

            layoutCache.addOrUpdateLayout(for: reservationDate, category: reservation.category, tables: layoutServices.tables)
        }

        layoutServices.saveToDisk()
        Task { @MainActor in
            AppLog.info("Updated activeReservationAdjacentCount for tables in reservation \(reservation.id).")
        }
    }
} 