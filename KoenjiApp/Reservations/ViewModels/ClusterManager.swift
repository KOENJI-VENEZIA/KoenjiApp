//
//  ClusterManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

import SwiftUI

/// Manages UI-related state and interactions for table layout.
@Observable
class ClusterManager {

    // MARK: - Dependencies
    private var store: ReservationStore?
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices
    private var layoutServices: LayoutServices
    private var resCache: CurrentReservationsCache

    private var date: Date
    private var category: Reservation.ReservationCategory

    var clusters: [CachedCluster] = []
    var activeReservationsCount: Int = 0
    var lastLayoutSignature: String = ""

    var isConfigured: Bool = false
    var statusChanged: Int = 0

    // MARK: - Initializer
    @MainActor
    init(
        clusterServices: ClusterServices, layoutServices: LayoutServices,
        resCache: CurrentReservationsCache, date: Date, category: Reservation.ReservationCategory
    ) {
        self.clusterServices = clusterServices
        self.layoutServices = layoutServices
        self.resCache = resCache
        self.date = date
        self.category = category
    }

    // MARK: - Loading Methods
    @MainActor
    func loadClusters() {
        clusters = clusterServices.loadClusters(for: date, category: category)
        //        print("Clusters: \(clusters.count)")
    }

    // MARK: - Computational Methods
    private func clusters(for reservation: Reservation, tables: [TableModel], cellSize: CGFloat)
        -> [CachedCluster]
    {
        //        print("Called clusters()")
        // Step 1: Gather all tables that belong to `reservation`.
        // (table.id is in reservation.tables)
        let reservationTableIDs = Set(reservation.tables.map { $0.id })
        let relevantTables = tables.filter { reservationTableIDs.contains($0.id) }

        // If it's only 1 table, decide if you want to show a cluster or skip.
        guard relevantTables.count >= 2 else {
            return []
        }

        // Step 2: Find connected components in `relevantTables`,
        // where "connected" means physically adjacent under your rules.
        let connectedComponents = findConnectedComponents(tables: relevantTables)

        // Step 3: Convert each connected component into a `CachedCluster`.
        // (One reservation can have multiple separate sub-clusters if tables are not physically adjacent to each other.)
        let clusters = connectedComponents.map { component -> CachedCluster in
            // Example: The date here uses reservation.date or your selectedDate
            CachedCluster(
                id: UUID(),
                reservationID: reservation,
                tableIDs: component.map { $0.id },
                date: reservation.normalizedDate ?? Date(),
                category: reservation.category,
                frame: calculateClusterFrame(component, cellSize: cellSize)
            )
        }

        //        print("Retrieved clusters: \(clusters)")
        return clusters
    }

    /// BFS (or Union-Find) to find connected subsets among the given tables.
    private func findConnectedComponents(tables: [TableModel]) -> [[TableModel]] {
        var visited = Set<Int>()
        var result = [[TableModel]]()

        for table in tables {
            if visited.contains(table.id) {
                continue
            }
            // BFS
            var queue = [table]
            var component = [TableModel]()

            while !queue.isEmpty {
                let current = queue.removeFirst()
                if visited.contains(current.id) {
                    continue
                }
                visited.insert(current.id)
                component.append(current)

                let neighbors = tables.filter { neighbor in
                    neighbor.id != current.id && !visited.contains(neighbor.id)
                        && areTablesPhysicallyAdjacent(table1: current, table2: neighbor)
                }
                queue.append(contentsOf: neighbors)
            }

            // **Add this line**:
            if component.count >= 2 {
                result.append(component)
            }
        }

        return result
    }

    private func shouldRecalculateClusters(
        for activeReservations: [Reservation],
        tables: [TableModel]
    ) -> Bool {

        // 2) Have the tables physically moved?
        //        print("Old signature: \(self.lastLayoutSignature)")
        let currentSignature = layoutServices.computeLayoutSignature(tables: tables)
        //        print("New signature: \(currentSignature)")
        if currentSignature == self.lastLayoutSignature {
            // No physical changes => No adjacency changes => Skip
            return false
        }

        // 3) Otherwise, we do have a change => recalc
        return true
    }

    private func calculateClusters(
        for activeReservations: [Reservation], tables: [TableModel], combinedDate: Date,
        cellSize: CGFloat
    ) -> [CachedCluster] {
        //        print("Calculating clusters at \(combinedDate)...")
        var allClusters: [CachedCluster] = []

        // Filter out reservations that ended or haven't started
        let validReservations = activeReservations.filter { reservation in

            let isValid =
                combinedDate >= reservation.startTimeDate ?? Date()
                && combinedDate < reservation.endTimeDate ?? Date()
                && reservation.status != .canceled && reservation.reservationType != .waitingList
            return isValid
        }

        for reservation in validReservations {
            // For each reservation, gather the clusters
            let resClusters = clusters(for: reservation, tables: tables, cellSize: cellSize)
            allClusters.append(contentsOf: resClusters)
        }
        return allClusters
    }

    private func calculateClusterFrame(_ tables: [TableModel], cellSize: CGFloat) -> CGRect {

        if tables.isEmpty {
            return .zero
        }

        // Calculate the min and max rows/columns of the cluster
        let minX = tables.map { $0.column }.min() ?? 0
        let maxX = tables.map { $0.column + $0.width }.max() ?? 0
        let minY = tables.map { $0.row }.min() ?? 0
        let maxY = tables.map { $0.row + $0.height }.max() ?? 0

        // Convert grid coordinates to pixel coordinates
        let originX = CGFloat(minX) * cellSize
        let originY = CGFloat(minY) * cellSize
        let width = CGFloat(maxX - minX) * cellSize
        let height = CGFloat(maxY - minY) * cellSize
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    private func areTablesPhysicallyAdjacent(table1: TableModel, table2: TableModel) -> Bool {
        let rowDifference = abs(table1.row - table2.row)
        let columnDifference = abs(table1.column - table2.column)

        // Check for direct adjacency (horizontally, vertically, or diagonally)
        return (rowDifference == 3 && columnDifference == 0)  // Vertical adjacency
            || (rowDifference == 0 && columnDifference == 3)  // Horizontal adjacency
    }

    // MARK: - Callable Method
    @MainActor
    func recalculateClustersIfNeeded(
        for activeReservations: [Reservation], tables: [TableModel], combinedDate: Date,
        oldCategory: Reservation.ReservationCategory,
        selectedCategory: Reservation.ReservationCategory, cellSize: CGFloat
    ) {
        let currentTables = tables

        // 1. Are there the conditions for new clusters?

        var newReservationsCount = 0
        for table in tables {
            if resCache.reservation(
                forTable: table.id, datetime: combinedDate, category: selectedCategory) != nil
            {
                newReservationsCount += 1
            }
        }

        if newReservationsCount == activeReservationsCount {
            guard shouldRecalculateClusters(for: activeReservations, tables: currentTables) else {
                return
            }

            clusters = clusterServices.loadClusters(for: combinedDate, category: selectedCategory)

            // 2. No condition for new clusters: let's check the cache:
            if !clusters.isEmpty
                && lastLayoutSignature == layoutServices.computeLayoutSignature(tables: tables)
            {
                return
            }

        }

        // 3) Not in cache, relevant changes => recalc clusters
        let newClusters = calculateClusters(
            for: activeReservations, tables: currentTables, combinedDate: combinedDate,
            cellSize: cellSize)
        self.clusters = newClusters
        self.lastLayoutSignature = layoutServices.computeLayoutSignature(tables: currentTables)
        self.clusterServices.saveClusters(clusters, for: combinedDate, category: selectedCategory)
        for table in tables {
            if resCache.reservation(
                forTable: table.id, datetime: combinedDate, category: selectedCategory) != nil
            {
                activeReservationsCount += 1
            }
        }
    }

}
