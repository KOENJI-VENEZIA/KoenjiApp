//
//  ClusterStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

import Foundation
import SwiftUI
import OSLog

class ClusterStore: ObservableObject {
    nonisolated(unsafe) static let shared = ClusterStore(store: ReservationStore.shared, tableStore: TableStore.shared, layoutServices: LayoutServices(store: ReservationStore.shared, tableStore: TableStore.shared, tableAssignmentService: TableAssignmentService()))
    private let store: ReservationStore
    private let tableStore: TableStore
    private let layoutServices: LayoutServices
    private let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ClusterStore"
    )

    
    struct ClusterCacheEntry {
            var clusters: [CachedCluster]
            var lastAccessed: Date
        }

    @Published var clusterCache: [String: ClusterCacheEntry] = [:]
    let maxCacheEntries = 100
    
    init(store: ReservationStore, tableStore: TableStore, layoutServices: LayoutServices)
    {
        self.store = store
        self.tableStore = tableStore
        self.layoutServices = layoutServices
    }
    // MARK: Caching
    func setClusterCache(_ clusters: [String: [CachedCluster]]) {
        clusterCache = clusters.mapValues { clusters in
            ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        }
        logger.info("Cluster cache updated with \(clusters.count) entries")
    }
    
    func invalidateClusterCache(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterCache.removeValue(forKey: key)
        logger.debug("Cluster cache invalidated for key: \(key)")
    }
    
    func invalidateAllClusterCaches() {
        clusterCache.removeAll()
        logger.notice("All cluster caches invalidated")
    }
    
}
