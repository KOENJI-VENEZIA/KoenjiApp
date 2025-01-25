//
//  ClusterManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

import SwiftUI

/// Manages UI-related state and interactions for table layout.
class ClusterManager: ObservableObject {
    
    // MARK: - Dependencies
    private var store: ReservationStore?
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices?
    private var layoutServices: LayoutServices?
    
    private var date: Date
    private var category: Reservation.ReservationCategory
        
    @Published var clusters: [CachedCluster] = [] {
        didSet {
            objectWillChange.send() // Notify SwiftUI of changes
        }
    }
    
    @State var lastLayoutSignature: String = ""

    @Published var isConfigured: Bool = false
    @State private var statusChanged: Int = 0

    
    // MARK: - Initializer
    init(date: Date, category: Reservation.ReservationCategory) {
        self.date = date
        self.category = category
    }
    
    func configure(store: ReservationStore, reservationService: ReservationService, clusterServices: ClusterServices, layoutServices: LayoutServices) {
        self.store = store
        self.reservationService = reservationService
        self.clusterServices = clusterServices
        self.layoutServices = layoutServices
        // methods to load clusters
        // methods to load clusters
        isConfigured = true
    }
    
    // MARK: - Loading Methods
    func loadClusters() {
        guard let clusterServices = clusterServices else { return }
        clusters = clusterServices.loadClusters(for: date, category: category)
    }
    
    private func loadClustersFromCache() {
        guard let clusterServices = clusterServices else { return }
        let cached = clusterServices.loadClusters(for: date, category: category)
        self.clusters = cached
    }
    
    // MARK: - Computational Methods
    private func clusters(for reservation: Reservation, tables: [TableModel], cellSize: CGFloat) -> [CachedCluster] {
        print("Called clusters()")
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
                date: reservation.cachedNormalizedDate ?? Date(),
                category: reservation.category,
                frame: calculateClusterFrame(component, cellSize: cellSize)
            )
        }
        
        print("Retrieved clusters: \(clusters)")
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
                    neighbor.id != current.id &&
                    !visited.contains(neighbor.id) &&
                    areTablesPhysicallyAdjacent(table1: current, table2: neighbor)
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
        // 1) Are there any relevant reservations active?
        guard !activeReservations.isEmpty else { return false }
        
        // 2) Have the tables physically moved?
        let currentSignature = layoutServices?.computeLayoutSignature(tables: tables)
        if currentSignature == self.lastLayoutSignature {
            // No physical changes => No adjacency changes => Skip
            return false
        }

        // 3) Otherwise, we do have a change => recalc
        return true
    }
    
    private func calculateClusters(for activeReservations: [Reservation], tables: [TableModel], combinedDate: Date, cellSize: CGFloat) -> [CachedCluster] {
        print("Calculating clusters at \(combinedDate)...")
        var allClusters: [CachedCluster] = []

        // Filter out reservations that ended or haven't started
        let validReservations = activeReservations.filter { reservation in
            print("\nDEBUG: Checking reservation: \(reservation.name)")
            print("Start Time: \(String(describing: reservation.startTimeDate))")
            print("End Time: \(String(describing: reservation.endTimeDate))")

            // Parse startTime and endTime of the reservation
            guard let startTime = reservation.startTimeDate,
                  let endTime = reservation.endTimeDate,
                  let normalizedStartTime = DateHelper.normalizedTime(time: startTime, date: combinedDate),
                  let normalizedEndTime = DateHelper.normalizedTime(time: endTime, date: combinedDate)
                else {
                print("DEBUG: Failed to parse and normalize startTime, endTime, or input time.")
                return false
            }
            
            print("Normalized Start Time: \(normalizedStartTime)")
            print("Normalized End Time: \(normalizedEndTime)")
            let isValid = combinedDate >= normalizedStartTime && combinedDate < normalizedEndTime
            print("Is Valid: \(isValid)")
            return isValid
        }

        print("Valid Reservations Count: \(validReservations.count)")

        for reservation in validReservations {
            print("Processing reservation: \(reservation.name)")
            // For each reservation, gather the clusters
            let resClusters = clusters(for: reservation, tables: tables, cellSize: cellSize)
            allClusters.append(contentsOf: resClusters)
        }

        print("Total Clusters Calculated: \(allClusters.count)")
        return allClusters
    }
    

    private func calculateClusterFrame(_ tables: [TableModel], cellSize: CGFloat) -> CGRect {
        print("Calculating cluster frame... [calculateClusterFrame() in LayoutPageView]")

        if tables.isEmpty {
            print("No tables provided for cluster frame calculation. Returning CGRect.zero.")
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
        
        print("Cluster Bounds - minX: \(minX), maxX: \(maxX), minY: \(minY), maxY: \(maxY)")
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    private func areTablesPhysicallyAdjacent(table1: TableModel, table2: TableModel) -> Bool {
        let rowDifference = abs(table1.row - table2.row)
        let columnDifference = abs(table1.column - table2.column)

        // Check for direct adjacency (horizontally, vertically, or diagonally)
        return (rowDifference == 3 && columnDifference == 0) || // Vertical adjacency
               (rowDifference == 0 && columnDifference == 3) // Horizontal adjacency
    }
    
    // MARK: - Callable Method
    func recalculateClustersIfNeeded(for activeReservations: [Reservation], tables: [TableModel], combinedDate: Date, oldCategory: Reservation.ReservationCategory, selectedCategory: Reservation.ReservationCategory, cellSize: CGFloat) {
        print("Recalculating clusters... [recalculateClustersIfNeeded()]")
        guard let layoutServices = layoutServices else { return }
        guard let clusterServices = clusterServices else { return }
        // Grab the current layout from store / layoutUI
        let currentTables = tables
        
        // 1) Early-exit if no adjacency changes
        if oldCategory == selectedCategory {
            guard shouldRecalculateClusters(for: activeReservations, tables: currentTables) else {
                print("Skipping recalc: no physical adjacency change or no active reservations.")
                return
            }
        }

        let cachedClusters = clusterServices.loadClusters(for: date, category: category)

        // 2) Attempt to load cached clusters for the date+time
        
        if !cachedClusters.isEmpty && lastLayoutSignature == layoutServices.computeLayoutSignature(tables: currentTables) {
                self.clusters = cachedClusters
                return
            }

        // 3) Not in cache => recalc clusters
        Task {
            let newClusters = calculateClusters(for: activeReservations, tables: currentTables, combinedDate: combinedDate, cellSize: cellSize)
            await MainActor.run {
                self.clusters = newClusters
            }
            self.lastLayoutSignature = layoutServices.computeLayoutSignature(tables: currentTables)
            clusterServices.saveClusters(newClusters, for: combinedDate, category: selectedCategory)
        }
    }

}
