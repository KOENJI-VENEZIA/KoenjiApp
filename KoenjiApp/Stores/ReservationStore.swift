//
//  ReservationStore.swift
//  KoenjiApp
//
//  Updated to manage cached layouts per date and category.
//

import Foundation
import SwiftUI

class ReservationStore: ObservableObject {
    static let shared = ReservationStore(tableAssignmentService: TableAssignmentService())
       
       // MARK: - Properties
       
       let tableAssignmentService: TableAssignmentService
    // Constants
    let reservationsFileName = "reservations.json"
    let baseTables = [
        TableModel(id: 1, name: "T1", maxCapacity: 2, row: 1, column: 14),
        TableModel(id: 2, name: "T2", maxCapacity: 2, row: 1, column: 10),
        TableModel(id: 3, name: "T3", maxCapacity: 2, row: 1, column: 6),
        TableModel(id: 4, name: "T4", maxCapacity: 2, row: 1, column: 1),
        TableModel(id: 5, name: "T5", maxCapacity: 2, row: 8, column: 7),
        TableModel(id: 6, name: "T6", maxCapacity: 2, row: 6, column: 1),
        TableModel(id: 7, name: "T7", maxCapacity: 2, row: 11, column: 1)
    ]
    
    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    // Locking mechanism for tables
    var lockedTableIDs: Set<Int> = []


    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var activeReservations: [Reservation] = []


    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false

    struct ActiveReservationCacheKey: Hashable, Codable {
        let tableID: Int
        let date: Date
        let time: Date

        func hash(into hasher: inout Hasher) {
            hasher.combine(tableID)
            hasher.combine(date)
            hasher.combine(time)
        }

        static func == (lhs: ActiveReservationCacheKey, rhs: ActiveReservationCacheKey) -> Bool {
            return lhs.tableID == rhs.tableID &&
                   lhs.date == rhs.date &&
                   lhs.time == rhs.time
        }
    }
    
    var activeReservationCache: [ActiveReservationCacheKey: Reservation] = [:]
    
    struct ClusterCacheEntry {
            var clusters: [CachedCluster]
            var lastAccessed: Date
        }

    @Published var clusterCache: [String: ClusterCacheEntry] = [:]
    private let maxCacheEntries = 100


    
    // Private Variables
    var grid: [[Int?]] = []
    @Published var tables: [TableModel] = []

    
    // MARK: - Initializers
    init(tableAssignmentService: TableAssignmentService) {
            self.tableAssignmentService = tableAssignmentService
            // Initialize cachedLayouts with base tables for today and default category
            let today = Calendar.current.startOfDay(for: Date())
            let defaultCategory: Reservation.ReservationCategory = .lunch
            let key = keyFor(date: today, category: defaultCategory)
            if cachedLayouts[key] == nil {
                cachedLayouts[key] = baseTables
                self.tables = baseTables

            }
        }
    
    // MARK: - Layout Management
    
    /// Generates a unique key based on date and category.
    func keyFor(date: Date, category: Reservation.ReservationCategory) -> String {
        let normalizedDate = Calendar.current.startOfDay(for: date) // Normalize date
        let dateString = DateHelper.formatDate(normalizedDate)
        print("Generated layout key: \(dateString)-\(category.rawValue) for date: \(date) and category: \(category.rawValue)")
        return "\(dateString)-\(category.rawValue)"
    }
    
    /// Loads tables for a specific date and category.
    func loadTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            self.tables = tables // Update the state
            print("Loaded tables for key: \(key)")
            loadFromDisk()
            loadClustersFromDisk()
            preloadActiveReservationCache(for: date)
            return tables
        } else {
            // If no cached layout exists, initialize with base tables
            cachedLayouts[key] = baseTables
            self.tables = baseTables
            preloadActiveReservationCache(for: date)
            print("Initialized new tables for key: \(key)")
            return baseTables
        }
        
        
    }
    
    func loadClusters(for date: Date, category: Reservation.ReservationCategory) -> [CachedCluster] {
            let key = keyFor(date: date, category: category)

            // Update last accessed timestamp if cached
            if let entry = clusterCache[key] {
                clusterCache[key]?.lastAccessed = Date()
                print("Loaded clusters from cache for key: \(key)")
                return entry.clusters
            }

            // Fallback to load clusters from disk
            print("Cache miss for key: \(key). Loading from disk...")
            loadClustersFromDisk()
            if let entry = clusterCache[key] {
                return entry.clusters
            }

            return []
        }
    
    /// Saves tables for a specific date and category.
    func saveTables(_ tables: [TableModel], for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        cachedLayouts[key] = tables
        saveToDisk()
        print("Layout saved for key: \(key)")
    }
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            print("Layouts saved successfully.")
        } else {
            print("Failed to encode cached layouts.")
        }
    }
    
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        
        // Reset the layout for the key
        cachedLayouts[key] = baseTables
        tables = baseTables // Update the published `tables` property to trigger UI updates
        
        // Save the layout to disk
        saveToDisk()
        
        print("Reset layout for key: \(key) to base tables and saved to disk.")
    }
    
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
            print("Cached layouts loaded successfully: \(cachedLayouts.keys)")
        } else {
            print("No cached layouts found.")
        }
    }
    
    // MARK: - Clusters Permanence
    
    func saveClustersToDisk() {
            let encoder = JSONEncoder()
            let cachedClusters = clusterCache.mapValues { entry in
                entry.clusters
            }
            if let data = try? encoder.encode(cachedClusters) {
                UserDefaults.standard.set(data, forKey: "clusterCache")
                print("Cluster cache saved successfully.")
            } else {
                print("Failed to encode cluster cache.")
            }
        }
    
    func loadClustersFromDisk() {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: "clusterCache"),
               let cachedClusters = try? decoder.decode([String: [CachedCluster]].self, from: data) {
                clusterCache = cachedClusters.mapValues { clusters in
                    ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
                }
                print("Cluster cache loaded successfully.")
            } else {
                print("No cluster cache found.")
            }
        }
    
    func updateClusterFrame(for date: Date, category: Reservation.ReservationCategory, clusterID: UUID, newFrame: CGRect) {
        let key = keyFor(date: date, category: category)

        guard var cacheEntry = clusterCache[key] else {
            print("No clusters found for key: \(key)")
            return
        }

        // Find the cluster by ID
        guard let index = cacheEntry.clusters.firstIndex(where: { $0.id == clusterID }) else {
            print("Cluster with ID \(clusterID) not found in \(key)")
            return
        }

        // Update the frame
        var updatedCluster = cacheEntry.clusters[index]
        updatedCluster.frame = newFrame
        cacheEntry.clusters[index] = updatedCluster

        // Update the cache with the modified cluster and update the last accessed timestamp
        clusterCache[key] = ClusterCacheEntry(clusters: cacheEntry.clusters, lastAccessed: Date())
        saveClustersToDisk() // Persist the updated cluster
        print("Updated frame for cluster \(clusterID) in \(key)")
    }
    
    func resetClusters(for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        
        // Remove clusters from the cache and save changes
        clusterCache[key] = ClusterCacheEntry(clusters: [], lastAccessed: Date())
        saveClustersToDisk()
        print("Reset clusters for key: \(key)")
    }
    
    

    func updateClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)

        // Update the cache entry with new clusters and refresh the timestamp
        clusterCache[key] = ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        enforceLRUCacheLimit() // Ensure cache size remains within the limit
        saveClustersToDisk() // Save changes to disk for persistence
        print("Updated clusters for key: \(key)")
    }
    
    func saveClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
            let key = keyFor(date: date, category: category)

            // Save clusters and update last accessed timestamp
            clusterCache[key] = ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            enforceLRUCacheLimit()
            saveClustersToDisk()
            print("Clusters saved for key: \(key)")
        }
    
    private func enforceLRUCacheLimit() {
            // Remove least recently used entries if cache size exceeds the limit
            guard clusterCache.count > maxCacheEntries else { return }

            let sortedKeys = clusterCache
                .sorted { $0.value.lastAccessed < $1.value.lastAccessed }
                .map { $0.key }

            let keysToRemove = sortedKeys.prefix(clusterCache.count - maxCacheEntries)
            keysToRemove.forEach { key in
                clusterCache.removeValue(forKey: key)
                print("Removed LRU cache entry for key: \(key)")
            }
        }
    
}

    // MARK: - Queries
    extension ReservationStore {
        /// Updates the category (lunch, dinner, or noBookingZone) based on time
        func updateCategory(for time: Date) {
            let hour = Calendar.current.component(.hour, from: time)
            switch hour {
            case 12...15:
                selectedCategory = .lunch
            case 18...23:
                selectedCategory = .dinner
            default:
                selectedCategory = .noBookingZone
            }
            
            print("Category updated to \(selectedCategory?.rawValue ?? "none") based on time.")
        }
        
        /// Called when time changes (e.g. user picks a new time).
        func handleTimeUpdate(_ newTime: Date) {
            currentTime = newTime
            updateCategory(for: newTime)
            print("Time updated to \(newTime), category set to \(selectedCategory?.rawValue ?? "none")")
        }
    }
    
    // MARK: - Getters and Setters
extension ReservationStore {
    func getReservations() -> [Reservation] {
        return self.reservations
    }

    func getTables() -> [TableModel] {
        return self.tables
    }
    
    func setReservations(_ reservations: [Reservation]) {
            self.reservations = reservations
    }
    
    func setTables(_ newTables: [TableModel]) {
            self.tables = newTables
    }
    
    func setCachedLayouts(_ layouts: [String: [TableModel]]) {
            self.cachedLayouts = layouts
    }
    
    func setClusterCache(_ clusters: [String: [CachedCluster]]) {
        clusterCache = clusters.mapValues { clusters in
            ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        }
        print("Cluster cache updated with \(clusters.count) entries.")
    }
}


    
    // MARK: - Table Assignment
    extension ReservationStore {
    
        /// Decides if manual or auto/contiguous assignment based on `selectedTableID`.
        /// Returns the tables assigned or `nil` if assignment fails.
        func assignTables(
            for reservation: Reservation,
            selectedTableID: Int?
        ) -> [TableModel]? {
            // Generate the layout key once
            let layoutKey = keyFor(date: reservation.date!, category: reservation.category)
            print("Generated layout key: \(layoutKey) for date: \(reservation.date!) and category: \(reservation.category)")

            // Retrieve cached tables
            guard let tables = cachedLayouts[layoutKey] else {
                print("Failed to retrieve layout for key: \(layoutKey). No tables available.")
                return nil
            }

            if let tableID = selectedTableID {
                // MANUAL CASE: Assign a specific table
                guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                    print("Failed to assign table \(tableID): Table not found in layout for key \(layoutKey).")
                    return nil
                }

                if isTableLocked(selectedTable.id) {
                    print("Table \(selectedTable.id) is currently locked and cannot be reserved.")
                    return nil
                }

                // Lock the table temporarily
                lockTable(selectedTable.id)

                // Attempt manual assignment
                let assignedTables = tableAssignmentService.assignTablesManually(
                    for: reservation,
                    tables: tables,
                    reservations: reservations, // Pass the array
                    startingFrom: selectedTable
                )

                if let assignedTables = assignedTables {
                    print("Successfully assigned tables manually for reservation \(reservation.id).")

                    // Update or append the reservation in the array on the main thread
                    DispatchQueue.main.async {
                        if let index = self.reservations.firstIndex(where: { $0.id == reservation.id }) {
                            self.reservations[index].tables = assignedTables
                        } else {
                            var updatedReservation = reservation
                            updatedReservation.tables = assignedTables
                            self.reservations.append(updatedReservation)
                        }
                    }

                    return assignedTables
                } else {
                    // Unlock the table on failure
                    unlockTable(selectedTable.id)
                    print("Failed to assign tables manually for reservation \(reservation.id).")
                    return nil
                }

            } else {
                // AUTO CASE: Find and assign tables automatically
                let unlockedTables = tables.filter { !isTableLocked($0.id) }
                if unlockedTables.isEmpty {
                    print("Failed to assign tables: No unlocked tables available for layout key \(layoutKey).")
                    return nil
                }

                // Attempt automatic assignment
                let assignedTables = tableAssignmentService.assignTablesPreferContiguous(
                    for: reservation,
                    reservations: reservations, // Pass the array
                    tables: unlockedTables
                )

                if let assignedTables = assignedTables {
                    // Lock all assigned tables
                    assignedTables.forEach { lockTable($0.id) }
                    print("Successfully assigned tables automatically for reservation \(reservation.id).")

                    // Update or append the reservation in the array on the main thread
                    DispatchQueue.main.async {
                        if let index = self.reservations.firstIndex(where: { $0.id == reservation.id }) {
                            self.reservations[index].tables = assignedTables
                        } else {
                            var updatedReservation = reservation
                            updatedReservation.tables = assignedTables
                            self.reservations.append(updatedReservation)
                        }
                    }

                    return assignedTables
                } else {
                    print("Failed to assign tables automatically for reservation \(reservation.id).")
                    return nil
                }
            }
        }
    }
    
    // MARK: - Misc Helpers
    extension ReservationStore {
        func formattedDate(date: Date, locale: Locale) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateFormat = "EEEE, dd/MM/yyyy"
            return formatter.string(from: date)
        }
        
        func triggerFlashAnimation(for tableID: Int) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.tableAnimationState[tableID] = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.tableAnimationState[tableID] = false
                    }
                }
            }
        }
    }

// MARK: - Table Placement Helpers
extension ReservationStore {
    /// Checks if a table can be placed at a new position for a given date and category.
    func canPlaceTable(_ table: TableModel, for date: Date, category: Reservation.ReservationCategory, activeTables: [TableModel]) -> Bool {
        print("Checking placement for table: \(table.name) at row: \(table.row), column: \(table.column), width: \(table.width), height: \(table.height)")
        
        // Ensure the table is within grid bounds
        guard table.row >= 0, table.column >= 0,
              table.row + table.height <= totalRows,
              table.column + table.width <= totalColumns else {
            print("Table \(table.name) is out of bounds.")
            return false
        }
                
        // Check for overlap with existing tables
        for existingTable in activeTables where existingTable.id != table.id {
            print("Comparing with existing table: \(existingTable.name) at row: \(existingTable.row), column: \(existingTable.column), width: \(existingTable.width), height: \(existingTable.height)")
            if tablesIntersect(existingTable, table) {
                print("Table \(table.name) intersects with \(existingTable.name). Cannot place.")
                return false
            }
        }
        
        print("Table \(table.name) can be placed.")
        return true
    }
    
    
    /// Checks if two tables overlap.
    private func tablesOverlap(table1: TableModel, table2: TableModel) -> Bool {
        let table1Rect = CGRect(
            x: table1.column,
            y: table1.row,
            width: table1.width,
            height: table1.height
        )
        let table2Rect = CGRect(
            x: table2.column,
            y: table2.row,
            width: table2.width,
            height: table2.height
        )
        return table1Rect.intersects(table2Rect)
    }
}


extension ReservationStore {
    /// Checks if a layout exists for the given date and category.
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return cachedLayouts[key] != nil
    }

    /// Initializes a new layout if it doesn't already exist.
    func initializeLayoutIfNeeded(for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        if cachedLayouts[key] == nil {
            cachedLayouts[key] = baseTables
            print("Initialized new layout for \(key)")
        } else {
            print("Layout already exists for \(key)")
        }
    }
}

extension ReservationStore {
    // MARK: - Locking Assignment

    

    func lockTable(_ tableID: Int) {
        lockedTableIDs.insert(tableID)
    }

    func unlockTable(_ tableID: Int) {
        lockedTableIDs.remove(tableID)
    }

    func isTableLocked(_ tableID: Int) -> Bool {
        lockedTableIDs.contains(tableID)
    }
    
    func finalizeReservation(_ reservation: Reservation, tables: [TableModel]) {
        // Mark tables as reserved in persistent storage, if needed
        // Unlock tables after finalization
        tables.forEach { unlockTable($0.id) } // Use table.id here, which is an Int
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index] = reservation // Update the reservation
        } else {
            // If the reservation is new, append it
            reservations.append(reservation)
        }

    }
  
}

extension ReservationStore {
    func invalidateClusterCache(for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        clusterCache.removeValue(forKey: key)
        print("Cluster cache invalidated for key: \(key)")
    }
    
    func invalidateAllClusterCaches() {
        clusterCache.removeAll()
        print("All cluster caches invalidated.")
    }
}

