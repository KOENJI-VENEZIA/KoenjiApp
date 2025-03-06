Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/ClusterServices.swift...
# Documentation Suggestions for ClusterServices.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/ClusterServices.swift
Total suggestions: 40

## Class Documentation (1)

### ClusterServices (Line 11)

**Context:**

```swift
import Foundation
import OSLog

class ClusterServices: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "ClusterServices")
    private let store: ReservationStore
    let clusterStore: ClusterStore          // single source of truth
```

**Suggested Documentation:**

```swift
/// ClusterServices class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (10)

### loadClusters (Line 30)

**Context:**

```swift
    
    // MARK: - Read/Write
    @MainActor
    func loadClusters(for date: Date, category: Reservation.ReservationCategory) -> [CachedCluster] {
        let key = layoutServices.keyFor(date: date, category: category)
        logger.info("Loading clusters for key: \(key)")

```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### saveClusters (Line 57)

**Context:**

```swift
        return []
    }
    
    func saveClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
            self.clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            logger.info("Clusters saved for key: \(key)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the saveClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateClusters (Line 71)

**Context:**

```swift
        saveClustersToDisk()
    }
    
    func updateClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        logger.info("Updated clusters for key: \(key)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### resetClusters (Line 82)

**Context:**

```swift
        saveClustersToDisk()
    }
    
    func resetClusters(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: [], lastAccessed: Date())
        logger.info("Reset clusters for key: \(key)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the resetClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### saveClustersToDisk (Line 93)

**Context:**

```swift
    }
    
    // MARK: - Cluster Permanence
    func saveClustersToDisk() {
            let encoder = JSONEncoder()
        let cachedClusters = clusterStore.clusterCache.mapValues { entry in
                entry.clusters
```

**Suggested Documentation:**

```swift
/// [Add a description of what the saveClustersToDisk method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### loadClustersFromDisk (Line 106)

**Context:**

```swift
            }
        }
    
    func loadClustersFromDisk() {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: "clusterCache"),
               let cachedClusters = try? decoder.decode([String: [CachedCluster]].self, from: data) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadClustersFromDisk method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### propagateClusterReset (Line 124)

**Context:**

```swift
    


    private func propagateClusterReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the propagateClusterReset method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### propagateClusterChange (Line 135)

**Context:**

```swift
        }
    }

    private func propagateClusterChange(from key: String, clusters: [CachedCluster]) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the propagateClusterChange method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### findClosestPriorClusterKey (Line 146)

**Context:**

```swift
        }
    }
    
    private func findClosestPriorClusterKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = clusterStore.clusterCache.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the findClosestPriorClusterKey method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### enforceLRUCacheLimit (Line 154)

**Context:**

```swift
        return sortedKeys.last { $0 < layoutServices.keyFor(date: date, category: category) }
    }
    
    private func enforceLRUCacheLimit() {
            // Remove least recently used entries if cache size exceeds the limit
        guard clusterStore.clusterCache.count > clusterStore.maxCacheEntries else { return }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the enforceLRUCacheLimit method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (29)

### logger (Line 12)

**Context:**

```swift
import OSLog

class ClusterServices: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "ClusterServices")
    private let store: ReservationStore
    let clusterStore: ClusterStore          // single source of truth
    private let tableStore: TableStore
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### store (Line 13)

**Context:**

```swift

class ClusterServices: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "ClusterServices")
    private let store: ReservationStore
    let clusterStore: ClusterStore          // single source of truth
    private let tableStore: TableStore
    private let layoutServices: LayoutServices
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### clusterStore (Line 14)

**Context:**

```swift
class ClusterServices: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "ClusterServices")
    private let store: ReservationStore
    let clusterStore: ClusterStore          // single source of truth
    private let tableStore: TableStore
    private let layoutServices: LayoutServices

```

**Suggested Documentation:**

```swift
/// [Description of the clusterStore property]
```

### tableStore (Line 15)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "ClusterServices")
    private let store: ReservationStore
    let clusterStore: ClusterStore          // single source of truth
    private let tableStore: TableStore
    private let layoutServices: LayoutServices

    // MARK: - Initializer
```

**Suggested Documentation:**

```swift
/// [Description of the tableStore property]
```

### layoutServices (Line 16)

**Context:**

```swift
    private let store: ReservationStore
    let clusterStore: ClusterStore          // single source of truth
    private let tableStore: TableStore
    private let layoutServices: LayoutServices

    // MARK: - Initializer
    init(store: ReservationStore, clusterStore: ClusterStore, tableStore: TableStore, layoutServices: LayoutServices) {
```

**Suggested Documentation:**

```swift
/// [Description of the layoutServices property]
```

### key (Line 31)

**Context:**

```swift
    // MARK: - Read/Write
    @MainActor
    func loadClusters(for date: Date, category: Reservation.ReservationCategory) -> [CachedCluster] {
        let key = layoutServices.keyFor(date: date, category: category)
        logger.info("Loading clusters for key: \(key)")

        // Attempt to load from the cache
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### entry (Line 35)

**Context:**

```swift
        logger.info("Loading clusters for key: \(key)")

        // Attempt to load from the cache
        if let entry = clusterStore.clusterCache[key] {
            DispatchQueue.main.async {
                self.clusterStore.clusterCache[key]?.lastAccessed = Date() // Update access timestamp
                self.logger.info("Loaded clusters from cache for key: \(key)")
```

**Suggested Documentation:**

```swift
/// [Description of the entry property]
```

### fallbackKey (Line 45)

**Context:**

```swift
        }

        // Fallback: Use the closest prior key
        let fallbackKey = findClosestPriorClusterKey(for: date, category: category)
        if let fallbackClusters = fallbackKey.flatMap({ clusterStore.clusterCache[$0]?.clusters }) {
            clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: fallbackClusters, lastAccessed: Date()) // Copy clusters
            logger.debug("Copied clusters from fallback key: \(fallbackKey ?? "none") to key: \(key)")
```

**Suggested Documentation:**

```swift
/// [Description of the fallbackKey property]
```

### fallbackClusters (Line 46)

**Context:**

```swift

        // Fallback: Use the closest prior key
        let fallbackKey = findClosestPriorClusterKey(for: date, category: category)
        if let fallbackClusters = fallbackKey.flatMap({ clusterStore.clusterCache[$0]?.clusters }) {
            clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: fallbackClusters, lastAccessed: Date()) // Copy clusters
            logger.debug("Copied clusters from fallback key: \(fallbackKey ?? "none") to key: \(key)")
            return fallbackClusters
```

**Suggested Documentation:**

```swift
/// [Description of the fallbackClusters property]
```

### key (Line 58)

**Context:**

```swift
    }
    
    func saveClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
            self.clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            logger.info("Clusters saved for key: \(key)")
            self.propagateClusterChange(from: key, clusters: clusters)
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### key (Line 72)

**Context:**

```swift
    }
    
    func updateClusters(_ clusters: [CachedCluster], for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
        logger.info("Updated clusters for key: \(key)")

```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### key (Line 83)

**Context:**

```swift
    }
    
    func resetClusters(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutServices.keyFor(date: date, category: category)
        clusterStore.clusterCache[key] = ClusterStore.ClusterCacheEntry(clusters: [], lastAccessed: Date())
        logger.info("Reset clusters for key: \(key)")

```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### encoder (Line 94)

**Context:**

```swift
    
    // MARK: - Cluster Permanence
    func saveClustersToDisk() {
            let encoder = JSONEncoder()
        let cachedClusters = clusterStore.clusterCache.mapValues { entry in
                entry.clusters
            }
```

**Suggested Documentation:**

```swift
/// [Description of the encoder property]
```

### cachedClusters (Line 95)

**Context:**

```swift
    // MARK: - Cluster Permanence
    func saveClustersToDisk() {
            let encoder = JSONEncoder()
        let cachedClusters = clusterStore.clusterCache.mapValues { entry in
                entry.clusters
            }
            if let data = try? encoder.encode(cachedClusters) {
```

**Suggested Documentation:**

```swift
/// [Description of the cachedClusters property]
```

### data (Line 98)

**Context:**

```swift
        let cachedClusters = clusterStore.clusterCache.mapValues { entry in
                entry.clusters
            }
            if let data = try? encoder.encode(cachedClusters) {
                UserDefaults.standard.set(data, forKey: "clusterCache")
                logger.debug("Cluster cache saved successfully.")
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### decoder (Line 107)

**Context:**

```swift
        }
    
    func loadClustersFromDisk() {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: "clusterCache"),
               let cachedClusters = try? decoder.decode([String: [CachedCluster]].self, from: data) {
                clusterStore.clusterCache = cachedClusters.mapValues { clusters in
```

**Suggested Documentation:**

```swift
/// [Description of the decoder property]
```

### data (Line 108)

**Context:**

```swift
    
    func loadClustersFromDisk() {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: "clusterCache"),
               let cachedClusters = try? decoder.decode([String: [CachedCluster]].self, from: data) {
                clusterStore.clusterCache = cachedClusters.mapValues { clusters in
                    ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### cachedClusters (Line 109)

**Context:**

```swift
    func loadClustersFromDisk() {
            let decoder = JSONDecoder()
            if let data = UserDefaults.standard.data(forKey: "clusterCache"),
               let cachedClusters = try? decoder.decode([String: [CachedCluster]].self, from: data) {
                clusterStore.clusterCache = cachedClusters.mapValues { clusters in
                    ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
                }
```

**Suggested Documentation:**

```swift
/// [Description of the cachedClusters property]
```

### category (Line 125)

**Context:**

```swift


    private func propagateClusterReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### allKeys (Line 126)

**Context:**

```swift

    private func propagateClusterReset(from key: String) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterStore.clusterCache[futureKey] == nil {
```

**Suggested Documentation:**

```swift
/// [Description of the allKeys property]
```

### futureKeys (Line 128)

**Context:**

```swift
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterStore.clusterCache[futureKey] == nil {
            clusterStore.clusterCache[futureKey] = ClusterStore.ClusterCacheEntry(clusters: [], lastAccessed: Date())
            logger.info("Reset clusters for future key: \(futureKey)")
```

**Suggested Documentation:**

```swift
/// [Description of the futureKeys property]
```

### category (Line 136)

**Context:**

```swift
    }

    private func propagateClusterChange(from key: String, clusters: [CachedCluster]) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### allKeys (Line 137)

**Context:**

```swift

    private func propagateClusterChange(from key: String, clusters: [CachedCluster]) {
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterStore.clusterCache[futureKey] == nil {
```

**Suggested Documentation:**

```swift
/// [Description of the allKeys property]
```

### futureKeys (Line 139)

**Context:**

```swift
        let category = key.split(separator: "-").last!
        let allKeys = clusterStore.clusterCache.keys.filter { $0.hasSuffix("-\(category)") }

        let futureKeys = allKeys.sorted().filter { $0 > key }
        for futureKey in futureKeys where clusterStore.clusterCache[futureKey] == nil {
            clusterStore.clusterCache[futureKey] = ClusterStore.ClusterCacheEntry(clusters: clusters, lastAccessed: Date())
            logger.info("Propagated clusters to future key: \(futureKey)")
```

**Suggested Documentation:**

```swift
/// [Description of the futureKeys property]
```

### formattedDate (Line 147)

**Context:**

```swift
    }
    
    private func findClosestPriorClusterKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = clusterStore.clusterCache.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Chronologically sort keys
```

**Suggested Documentation:**

```swift
/// [Description of the formattedDate property]
```

### allKeys (Line 148)

**Context:**

```swift
    
    private func findClosestPriorClusterKey(for date: Date, category: Reservation.ReservationCategory) -> String? {
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = clusterStore.clusterCache.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Chronologically sort keys
        return sortedKeys.last { $0 < layoutServices.keyFor(date: date, category: category) }
```

**Suggested Documentation:**

```swift
/// [Description of the allKeys property]
```

### sortedKeys (Line 150)

**Context:**

```swift
        let formattedDate = DateHelper.formatDate(date)
        let allKeys = clusterStore.clusterCache.keys.filter { $0.starts(with: "\(formattedDate)-\(category.rawValue)") }

        let sortedKeys = allKeys.sorted(by: { $0 < $1 }) // Chronologically sort keys
        return sortedKeys.last { $0 < layoutServices.keyFor(date: date, category: category) }
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the sortedKeys property]
```

### sortedKeys (Line 158)

**Context:**

```swift
            // Remove least recently used entries if cache size exceeds the limit
        guard clusterStore.clusterCache.count > clusterStore.maxCacheEntries else { return }

        let sortedKeys = clusterStore.clusterCache
                .sorted { $0.value.lastAccessed < $1.value.lastAccessed }
                .map { $0.key }

```

**Suggested Documentation:**

```swift
/// [Description of the sortedKeys property]
```

### keysToRemove (Line 162)

**Context:**

```swift
                .sorted { $0.value.lastAccessed < $1.value.lastAccessed }
                .map { $0.key }

        let keysToRemove = sortedKeys.prefix(clusterStore.clusterCache.count - clusterStore.maxCacheEntries)
            keysToRemove.forEach { key in
                clusterStore.clusterCache.removeValue(forKey: key)
                logger.info("Removed LRU cache entry for key: \(key)")
```

**Suggested Documentation:**

```swift
/// [Description of the keysToRemove property]
```


Total documentation suggestions: 40

