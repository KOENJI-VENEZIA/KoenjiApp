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

    
    
    var activeReservationCache: [ActiveReservationCacheKey: Reservation] = [:]
    var cachePreloadedFrom: Date?

    
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
        let formattedDateTime = DateHelper.formatDate(date) // Ensure the date includes both date and time
        return "\(formattedDateTime)-\(category.rawValue)"
    }
    
    /// Loads tables for a specific date and category.
    func loadTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let fullKey = keyFor(date: date, category: category)
        print("Loading tables for key: \(fullKey)")

        // Check if the exact layout exists
        if let tables = cachedLayouts[fullKey] {
            // Assign to self.tables *on the main thread*
            DispatchQueue.main.async {
                self.tables = tables
                print("Loaded exact layout for key: \(fullKey)")
            }
            return tables
        }

        // Fallback: Use the closest prior configuration
        let fallbackKey = findClosestPriorKey(for: date, category: category)
        if let fallbackTables = fallbackKey.flatMap({ cachedLayouts[$0] }) {
            // Copy the fallback layout for this specific timeslot
            cachedLayouts[fullKey] = fallbackTables
            
            DispatchQueue.main.async {
                self.tables = fallbackTables
                print("Copied fallback layout from key: \(fallbackKey ?? "none") to key: \(fullKey)")
            }
            return fallbackTables
        }

        // Final fallback: Initialize with base tables

        
        DispatchQueue.main.async {
            self.cachedLayouts[fullKey] = self.baseTables
            self.tables = self.baseTables
            print("Initialized new layout for key: \(fullKey) with base tables")
        }
        return baseTables
    }
    
    private func findClosestPriorKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = cachedLayouts.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Sort keys chronologically
        return sortedKeys.last { $0 < "\(formattedDate)-\(category.rawValue)" }
    }
    
    func loadClusters(for date: Date, category: Reservation.ReservationCategory) -> [CachedCluster] {
        let key = keyFor(date: date, category: category)
        print("Loading clusters for key: \(key)")

        // Attempt to load from the cache
        if let entry = clusterCache[key] {
            clusterCache[key]?.lastAccessed = Date() // Update access timestamp
            print("Loaded clusters from cache for key: \(key)")
            return entry.clusters
        }

        // Fallback: Use the closest prior key
        let fallbackKey = findClosestPriorClusterKey(for: date, category: category)
        if let fallbackClusters = fallbackKey.flatMap({ clusterCache[$0]?.clusters }) {
            clusterCache[key] = ClusterCacheEntry(clusters: fallbackClusters, lastAccessed: Date()) // Copy clusters
            print("Copied clusters from fallback key: \(fallbackKey ?? "none") to key: \(key)")
            return fallbackClusters
        }

        // Final fallback: Return empty clusters
        print("No clusters found for key: \(key). Returning empty list.")
        return []
    }
    
    private func findClosestPriorClusterKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = clusterCache.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Chronologically sort keys
        return sortedKeys.last { $0 < keyFor(date: date, category: category) }
    }
    
    /// Saves tables for a specific date and category.
    func saveTables(_ tables: [TableModel], for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)
        cachedLayouts[fullKey] = tables
        print("Saved tables for key: \(fullKey)")

        // Propagate changes to future timeslots
        propagateLayoutChange(from: fullKey, tables: tables)
        saveToDisk()
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
    
    private func propagateLayoutChange(from key: String, tables: [TableModel]) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = tables
            print("Propagated layout to future key: \(futureKey)")
        }
    }
    
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let fullKey = keyFor(date: date, category: category)

        // Reset the layout for this specific key
        cachedLayouts[fullKey] = baseTables
        tables = baseTables
        print("Reset tables for key: \(fullKey) to base tables.")

        // Propagate reset to future timeslots
        propagateLayoutReset(from: fullKey)
        saveToDisk()
    }

    private func propagateLayoutReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = cachedLayouts.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where cachedLayouts[futureKey] == nil {
            cachedLayouts[futureKey] = baseTables
            print("Reset future key: \(futureKey) to base tables.")
        }
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
        clusterCache[key] = ClusterCacheEntry(clusters: [], lastAccessed: Date())
        print("Reset clusters for key: \(key)")

        // Propagate reset to future timeslots
        propagateClusterReset(from: key)
        saveClustersToDisk()
    }

    private func propagateClusterReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterCache[futureKey] == nil {
            clusterCache[futureKey] = ClusterCacheEntry(clusters: [], lastAccessed: Date())
            print("Reset clusters for future key: \(futureKey)")
        }
    }
    
    

    func updateClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        clusterCache[key] = ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        print("Updated clusters for key: \(key)")

        // Propagate changes to future timeslots
        propagateClusterChange(from: key, clusters: clusters)
        enforceLRUCacheLimit()
        saveClustersToDisk()
    }

    private func propagateClusterChange(from key: String, clusters: [CachedCluster]) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterCache[futureKey] == nil {
            clusterCache[futureKey] = ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            print("Propagated clusters to future key: \(futureKey)")
        }
    }
    
    func saveClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        clusterCache[key] = ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        print("Clusters saved for key: \(key)")

        // Propagate changes to future timeslots
        propagateClusterChange(from: key, clusters: clusters)
        enforceLRUCacheLimit()
        saveClustersToDisk()
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
            let reservationDate = DateHelper.combineDateAndTimeStrings(dateString: reservation.dateString, timeString: reservation.startTime)
           
            let layoutKey = keyFor(date: reservationDate, category: reservation.category)
            print("Generated layout key: \(layoutKey) for date: \(reservationDate) and category: \(reservation.category)")

            print("Available cachedLayouts keys: \(cachedLayouts.keys)")
            
            // Retrieve cached tables
            guard let tables = cachedLayouts[layoutKey] ?? generateAndCacheLayout(for: layoutKey, date: reservationDate, category: reservation.category) else {
                print("Failed to retrieve or generate layout for key: \(layoutKey). No tables available.")
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
        
        func generateAndCacheLayout(for layoutKey: String, date: Date, category: Reservation.ReservationCategory) -> [TableModel]? {
            print("Generating layout for key: \(layoutKey)")
            let layout = loadTables(for: date, category: category) // Your layout generation logic
            
            if !layout.isEmpty {
                cachedLayouts[layoutKey] = layout
                print("Layout cached for key: \(layoutKey)")
            } else {
                print("Failed to generate layout for key: \(layoutKey)")
            }
            return layout
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

//    /// Initializes a new layout if it doesn't already exist.
//    func initializeLayoutIfNeeded(for date: Date, category: Reservation.ReservationCategory) {
//        let key = keyFor(date: date, category: category)
//        if cachedLayouts[key] == nil {
//            cachedLayouts[key] = baseTables
//            print("Initialized new layout for \(key)")
//        } else {
//            print("Layout already exists for \(key)")
//        }
//    }
}

extension ReservationStore {
    // MARK: - Locking Assignment

    

    func lockTable(_ tableID: Int) {
        lockedTableIDs.insert(tableID)
    }

    func unlockTable(_ tableID: Int) {
        lockedTableIDs.remove(tableID)
    }

    func unlockAllTables() {
        lockedTableIDs.removeAll()
    }
    
    func isTableLocked(_ tableID: Int) -> Bool {
        lockedTableIDs.contains(tableID)
    }
    
    func finalizeReservation(_ reservation: Reservation) {
        // Mark tables as reserved in persistent storage, if needed
        // Unlock tables after finalization
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index] = reservation // Update the reservation
        } else {
            // If the reservation is new, append it
            reservations.append(reservation)
        }
        
        populateActiveCache(for: reservation)

    }
    
    func populateActiveCache(for reservation: Reservation) {
        let start = DateHelper.combineDateAndTimeStrings(dateString: reservation.dateString, timeString: reservation.startTime)
        let end   = DateHelper.combineDateAndTimeStrings(dateString: reservation.dateString, timeString: reservation.endTime)

        print("Populating active reservation cache with: \(reservation.name)...")
        
        var current = start
        while current < end {
            for table in reservation.tables {
                let cacheKey = ActiveReservationCacheKey(
                    tableID: table.id,
                    date: Calendar.current.startOfDay(for: current),
                    time: current
                )
                
                activeReservationCache[cacheKey] = reservation
            }
            current.addTimeInterval(60) // next minute
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

extension ReservationStore {
    func invalidateActiveReservationCache(for reservation: Reservation) {
        // Reconstruct the full date range for this reservation
        let start = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.startTime
        )
        let end   = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.endTime
        )
        
        // Bail out if times are invalid or reversed
        guard start < end else {
            print("Cannot invalidate active cache: start >= end for reservation \(reservation.id)")
            return
        }

        var current = start
        while current < end {
            for table in reservation.tables {
                // Each minute + each table -> remove from cache
                let cacheKey = ActiveReservationCacheKey(
                    tableID: table.id,
                    date: Calendar.current.startOfDay(for: current),
                    time: current
                )
                activeReservationCache.removeValue(forKey: cacheKey)
            }
            current.addTimeInterval(60) // Move to next minute
        }

        print("Invalidated active reservation cache for reservation \(reservation.id).")
    }
}
