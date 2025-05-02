//
//  ClusterStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

import Foundation
import SwiftUI

class ClusterStore: ObservableObject {
    nonisolated(unsafe) static let shared = ClusterStore(layoutCache: LayoutCache())

    private let layoutCache: LayoutCache

    init(layoutCache: LayoutCache) {
        self.layoutCache = layoutCache
    }

    struct ClusterCacheEntry {
            var clusters: [CachedCluster]
            var lastAccessed: Date
        }

    @Published var clusterCache: [String: ClusterCacheEntry] = [:]
    let maxCacheEntries = 100

    // MARK: Caching
    func setClusterCache(_ clusters: [String: [CachedCluster]]) {
        clusterCache = clusters.mapValues { clusters in
            ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        }
        Task { @MainActor in
            AppLog.info("Cluster cache updated with \(clusters.count) entries")
        }
    }
    
    func invalidateClusterCache(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutCache.keyFor(date: date, category: category)
        clusterCache.removeValue(forKey: key)
        Task { @MainActor in
            AppLog.debug("Cluster cache invalidated for key: \(key)")
        }
    }
    
    func invalidateAllClusterCaches() {
        clusterCache.removeAll()
        Task { @MainActor in
            AppLog.info("All cluster caches invalidated")
        }
    }
    
}
