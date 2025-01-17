//
//  ClusterStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

import Foundation
import SwiftUI

class ClusterStore: ObservableObject {
    static let shared = ClusterStore(store: ReservationStore.shared)
    private let store: ReservationStore

    
    struct ClusterCacheEntry {
            var clusters: [CachedCluster]
            var lastAccessed: Date
        }

    @Published var clusterCache: [String: ClusterCacheEntry] = [:]
    let maxCacheEntries = 100
    
    init(store: ReservationStore)
    {
        self.store = store
    }
    // MARK: Caching
    func setClusterCache(_ clusters: [String: [CachedCluster]]) {
        clusterCache = clusters.mapValues { clusters in
            ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        }
        print("Cluster cache updated with \(clusters.count) entries.")
    }
    
    func invalidateClusterCache(for date: Date, category: Reservation.ReservationCategory) {
        let key = store.keyFor(date: date, category: category)
        clusterCache.removeValue(forKey: key)
        print("Cluster cache invalidated for key: \(key)")
    }
    
    func invalidateAllClusterCaches() {
        clusterCache.removeAll()
        print("All cluster caches invalidated.")
    }
    
}
