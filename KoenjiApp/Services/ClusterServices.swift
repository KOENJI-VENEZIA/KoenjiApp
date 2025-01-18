//
//  ClusterServices.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

import Foundation

class ClusterServices: ObservableObject {
    private let store: ReservationStore
    private let clusterStore: ClusterStore          // single source of truth
    private let tableStore: TableStore
    private let layoutServices: LayoutServices

    // MARK: - Initializer
    init(store: ReservationStore, clusterStore: ClusterStore, tableStore: TableStore, layoutServices: LayoutServices) {
        self.store = store
        self.clusterStore = clusterStore
        self.tableStore = tableStore
        self.layoutServices = layoutServices

        self.loadClustersFromDisk()
    }
    
    // MARK: - Read/Write
    func loadClusters(for date: Date, category: Reservation.ReservationCategory) -> [CachedCluster] {
        let key = layoutServices.keyFor(date: date, category: category)
        print("Loading clusters for key: \(key)")

        // Attempt to load from the cache
        if let entry = clusterStore.clusterCache[key] {
            clusterStore.clusterCache[key]?.lastAccessed = Date() // Update access timestamp
            print("Loaded clusters from cache for key: \(key)")
            return entry.clusters
        }

        // Fallback: Use the closest prior key
        let fallbackKey = findClosestPriorClusterKey(for: date, category: category)
        if let fallbackClusters = fallbackKey.flatMap({ clusterStore.clusterCache[$0]?.clusters }) {
            clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: fallbackClusters, lastAccessed: Date()) // Copy clusters
            print("Copied clusters from fallback key: \(fallbackKey ?? "none") to key: \(key)")
            return fallbackClusters
        }

        // Final fallback: Return empty clusters
        print("No clusters found for key: \(key). Returning empty list.")
        return []
    }
    
    func saveClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        DispatchQueue.main.async {
            self.clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            print("Clusters saved for key: \(key)")
            self.propagateClusterChange(from: key, clusters: clusters)
            self.enforceLRUCacheLimit()
            self.saveClustersToDisk()
        }
        // Propagate changes to future timeslots
        propagateClusterChange(from: key, clusters: clusters)
        enforceLRUCacheLimit()
        saveClustersToDisk()
    }
    
    func updateClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        print("Updated clusters for key: \(key)")

        // Propagate changes to future timeslots
        propagateClusterChange(from: key, clusters: clusters)
        enforceLRUCacheLimit()
        saveClustersToDisk()
    }
    
    func resetClusters(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: [], lastAccessed: Date())
        print("Reset clusters for key: \(key)")

        // Propagate reset to future timeslots
        propagateClusterReset(from: key)
        saveClustersToDisk()
    }
    
    // MARK: - Cluster Permanence
    func saveClustersToDisk() {
            let encoder = JSONEncoder()
        let cachedClusters = clusterStore.clusterCache.mapValues { entry in
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
                clusterStore.clusterCache = cachedClusters.mapValues { clusters in
                    ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
                }
                print("Cluster cache loaded successfully.")
            } else {
                print("No cluster cache found.")
            }
        }
    
    
    // MARK: - Helper Methods
    


    private func propagateClusterReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterStore.clusterCache[futureKey] == nil {
            clusterStore.clusterCache[futureKey] = ClusterStore.ClusterCacheEntry(clusters: [], lastAccessed: Date())
            print("Reset clusters for future key: \(futureKey)")
        }
    }

    private func propagateClusterChange(from key: String, clusters: [CachedCluster]) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterStore.clusterCache[futureKey] == nil {
            clusterStore.clusterCache[futureKey] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            print("Propagated clusters to future key: \(futureKey)")
        }
    }
    
    private func findClosestPriorClusterKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = clusterStore.clusterCache.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Chronologically sort keys
        return sortedKeys.last { $0 < layoutServices.keyFor(date: date, category: category) }
    }
    
    private func enforceLRUCacheLimit() {
            // Remove least recently used entries if cache size exceeds the limit
        guard clusterStore.clusterCache.count > clusterStore.maxCacheEntries else { return }

        let sortedKeys = clusterStore.clusterCache
                .sorted { $0.value.lastAccessed < $1.value.lastAccessed }
                .map { $0.key }

        let keysToRemove = sortedKeys.prefix(clusterStore.clusterCache.count - clusterStore.maxCacheEntries)
            keysToRemove.forEach { key in
                clusterStore.clusterCache.removeValue(forKey: key)
                print("Removed LRU cache entry for key: \(key)")
            }
        }
    
    
}
