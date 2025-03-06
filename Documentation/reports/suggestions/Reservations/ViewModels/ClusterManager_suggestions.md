Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/ClusterManager.swift...
# Documentation Suggestions for ClusterManager.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/ClusterManager.swift
Total suggestions: 45

## Method Documentation (7)

### loadClusters (Line 46)

**Context:**

```swift

    // MARK: - Loading Methods
    @MainActor
    func loadClusters() {
        clusters = clusterServices.loadClusters(for: date, category: category)
        //        print("Clusters: \(clusters.count)")
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### clusters (Line 52)

**Context:**

```swift
    }

    // MARK: - Computational Methods
    private func clusters(for reservation: Reservation, tables: [TableModel], cellSize: CGFloat)
        -> [CachedCluster]
    {
        //        print("Called clusters()")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the clusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### shouldRecalculateClusters (Line 125)

**Context:**

```swift
        return result
    }

    private func shouldRecalculateClusters(
        for activeReservations: [Reservation],
        tables: [TableModel]
    ) -> Bool {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the shouldRecalculateClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateClusters (Line 143)

**Context:**

```swift
        return true
    }

    private func calculateClusters(
        for activeReservations: [Reservation], tables: [TableModel], combinedDate: Date,
        cellSize: CGFloat
    ) -> [CachedCluster] {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateClusters method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateClusterFrame (Line 168)

**Context:**

```swift
        return allClusters
    }

    private func calculateClusterFrame(_ tables: [TableModel], cellSize: CGFloat) -> CGRect {

        if tables.isEmpty {
            return .zero
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateClusterFrame method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### areTablesPhysicallyAdjacent (Line 188)

**Context:**

```swift
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    private func areTablesPhysicallyAdjacent(table1: TableModel, table2: TableModel) -> Bool {
        let rowDifference = abs(table1.row - table2.row)
        let columnDifference = abs(table1.column - table2.column)

```

**Suggested Documentation:**

```swift
/// [Add a description of what the areTablesPhysicallyAdjacent method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### recalculateClustersIfNeeded (Line 199)

**Context:**

```swift

    // MARK: - Callable Method
    @MainActor
    func recalculateClustersIfNeeded(
        for activeReservations: [Reservation], tables: [TableModel], combinedDate: Date,
        oldCategory: Reservation.ReservationCategory,
        selectedCategory: Reservation.ReservationCategory, cellSize: CGFloat
```

**Suggested Documentation:**

```swift
/// [Add a description of what the recalculateClustersIfNeeded method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (38)

### store (Line 15)

**Context:**

```swift
class ClusterManager {

    // MARK: - Dependencies
    private var store: ReservationStore?
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices
    private var layoutServices: LayoutServices
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### reservationService (Line 16)

**Context:**

```swift

    // MARK: - Dependencies
    private var store: ReservationStore?
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices
    private var layoutServices: LayoutServices
    private var resCache: CurrentReservationsCache
```

**Suggested Documentation:**

```swift
/// [Description of the reservationService property]
```

### clusterServices (Line 17)

**Context:**

```swift
    // MARK: - Dependencies
    private var store: ReservationStore?
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices
    private var layoutServices: LayoutServices
    private var resCache: CurrentReservationsCache

```

**Suggested Documentation:**

```swift
/// [Description of the clusterServices property]
```

### layoutServices (Line 18)

**Context:**

```swift
    private var store: ReservationStore?
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices
    private var layoutServices: LayoutServices
    private var resCache: CurrentReservationsCache

    private var date: Date
```

**Suggested Documentation:**

```swift
/// [Description of the layoutServices property]
```

### resCache (Line 19)

**Context:**

```swift
    private var reservationService: ReservationService?
    private var clusterServices: ClusterServices
    private var layoutServices: LayoutServices
    private var resCache: CurrentReservationsCache

    private var date: Date
    private var category: Reservation.ReservationCategory
```

**Suggested Documentation:**

```swift
/// [Description of the resCache property]
```

### date (Line 21)

**Context:**

```swift
    private var layoutServices: LayoutServices
    private var resCache: CurrentReservationsCache

    private var date: Date
    private var category: Reservation.ReservationCategory

    var clusters: [CachedCluster] = []
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### category (Line 22)

**Context:**

```swift
    private var resCache: CurrentReservationsCache

    private var date: Date
    private var category: Reservation.ReservationCategory

    var clusters: [CachedCluster] = []
    var activeReservationsCount: Int = 0
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### clusters (Line 24)

**Context:**

```swift
    private var date: Date
    private var category: Reservation.ReservationCategory

    var clusters: [CachedCluster] = []
    var activeReservationsCount: Int = 0
    var lastLayoutSignature: String = ""

```

**Suggested Documentation:**

```swift
/// [Description of the clusters property]
```

### activeReservationsCount (Line 25)

**Context:**

```swift
    private var category: Reservation.ReservationCategory

    var clusters: [CachedCluster] = []
    var activeReservationsCount: Int = 0
    var lastLayoutSignature: String = ""

    var isConfigured: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservationsCount property]
```

### lastLayoutSignature (Line 26)

**Context:**

```swift

    var clusters: [CachedCluster] = []
    var activeReservationsCount: Int = 0
    var lastLayoutSignature: String = ""

    var isConfigured: Bool = false
    var statusChanged: Int = 0
```

**Suggested Documentation:**

```swift
/// [Description of the lastLayoutSignature property]
```

### isConfigured (Line 28)

**Context:**

```swift
    var activeReservationsCount: Int = 0
    var lastLayoutSignature: String = ""

    var isConfigured: Bool = false
    var statusChanged: Int = 0

    // MARK: - Initializer
```

**Suggested Documentation:**

```swift
/// [Description of the isConfigured property]
```

### statusChanged (Line 29)

**Context:**

```swift
    var lastLayoutSignature: String = ""

    var isConfigured: Bool = false
    var statusChanged: Int = 0

    // MARK: - Initializer
    @MainActor
```

**Suggested Documentation:**

```swift
/// [Description of the statusChanged property]
```

### reservationTableIDs (Line 58)

**Context:**

```swift
        //        print("Called clusters()")
        // Step 1: Gather all tables that belong to `reservation`.
        // (table.id is in reservation.tables)
        let reservationTableIDs = Set(reservation.tables.map { $0.id })
        let relevantTables = tables.filter { reservationTableIDs.contains($0.id) }

        // If it's only 1 table, decide if you want to show a cluster or skip.
```

**Suggested Documentation:**

```swift
/// [Description of the reservationTableIDs property]
```

### relevantTables (Line 59)

**Context:**

```swift
        // Step 1: Gather all tables that belong to `reservation`.
        // (table.id is in reservation.tables)
        let reservationTableIDs = Set(reservation.tables.map { $0.id })
        let relevantTables = tables.filter { reservationTableIDs.contains($0.id) }

        // If it's only 1 table, decide if you want to show a cluster or skip.
        guard relevantTables.count >= 2 else {
```

**Suggested Documentation:**

```swift
/// [Description of the relevantTables property]
```

### connectedComponents (Line 68)

**Context:**

```swift

        // Step 2: Find connected components in `relevantTables`,
        // where "connected" means physically adjacent under your rules.
        let connectedComponents = findConnectedComponents(tables: relevantTables)

        // Step 3: Convert each connected component into a `CachedCluster`.
        // (One reservation can have multiple separate sub-clusters if tables are not physically adjacent to each other.)
```

**Suggested Documentation:**

```swift
/// [Description of the connectedComponents property]
```

### clusters (Line 72)

**Context:**

```swift

        // Step 3: Convert each connected component into a `CachedCluster`.
        // (One reservation can have multiple separate sub-clusters if tables are not physically adjacent to each other.)
        let clusters = connectedComponents.map { component -> CachedCluster in
            // Example: The date here uses reservation.date or your selectedDate
            CachedCluster(
                id: UUID(),
```

**Suggested Documentation:**

```swift
/// [Description of the clusters property]
```

### queue (Line 98)

**Context:**

```swift
                continue
            }
            // BFS
            var queue = [table]
            var component = [TableModel]()

            while !queue.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the queue property]
```

### component (Line 99)

**Context:**

```swift
            }
            // BFS
            var queue = [table]
            var component = [TableModel]()

            while !queue.isEmpty {
                let current = queue.removeFirst()
```

**Suggested Documentation:**

```swift
/// [Description of the component property]
```

### current (Line 102)

**Context:**

```swift
            var component = [TableModel]()

            while !queue.isEmpty {
                let current = queue.removeFirst()
                if visited.contains(current.id) {
                    continue
                }
```

**Suggested Documentation:**

```swift
/// [Description of the current property]
```

### neighbors (Line 109)

**Context:**

```swift
                visited.insert(current.id)
                component.append(current)

                let neighbors = tables.filter { neighbor in
                    neighbor.id != current.id && !visited.contains(neighbor.id)
                        && areTablesPhysicallyAdjacent(table1: current, table2: neighbor)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the neighbors property]
```

### currentSignature (Line 132)

**Context:**

```swift

        // 2) Have the tables physically moved?
        //        print("Old signature: \(self.lastLayoutSignature)")
        let currentSignature = layoutServices.computeLayoutSignature(tables: tables)
        //        print("New signature: \(currentSignature)")
        if currentSignature == self.lastLayoutSignature {
            // No physical changes => No adjacency changes => Skip
```

**Suggested Documentation:**

```swift
/// [Description of the currentSignature property]
```

### allClusters (Line 148)

**Context:**

```swift
        cellSize: CGFloat
    ) -> [CachedCluster] {
        //        print("Calculating clusters at \(combinedDate)...")
        var allClusters: [CachedCluster] = []

        // Filter out reservations that ended or haven't started
        let validReservations = activeReservations.filter { reservation in
```

**Suggested Documentation:**

```swift
/// [Description of the allClusters property]
```

### validReservations (Line 151)

**Context:**

```swift
        var allClusters: [CachedCluster] = []

        // Filter out reservations that ended or haven't started
        let validReservations = activeReservations.filter { reservation in

            let isValid =
                combinedDate >= reservation.startTimeDate ?? Date()
```

**Suggested Documentation:**

```swift
/// [Description of the validReservations property]
```

### isValid (Line 153)

**Context:**

```swift
        // Filter out reservations that ended or haven't started
        let validReservations = activeReservations.filter { reservation in

            let isValid =
                combinedDate >= reservation.startTimeDate ?? Date()
                && combinedDate < reservation.endTimeDate ?? Date()
                && reservation.status != .canceled && reservation.reservationType != .waitingList
```

**Suggested Documentation:**

```swift
/// [Description of the isValid property]
```

### resClusters (Line 162)

**Context:**

```swift

        for reservation in validReservations {
            // For each reservation, gather the clusters
            let resClusters = clusters(for: reservation, tables: tables, cellSize: cellSize)
            allClusters.append(contentsOf: resClusters)
        }
        return allClusters
```

**Suggested Documentation:**

```swift
/// [Description of the resClusters property]
```

### minX (Line 175)

**Context:**

```swift
        }

        // Calculate the min and max rows/columns of the cluster
        let minX = tables.map { $0.column }.min() ?? 0
        let maxX = tables.map { $0.column + $0.width }.max() ?? 0
        let minY = tables.map { $0.row }.min() ?? 0
        let maxY = tables.map { $0.row + $0.height }.max() ?? 0
```

**Suggested Documentation:**

```swift
/// [Description of the minX property]
```

### maxX (Line 176)

**Context:**

```swift

        // Calculate the min and max rows/columns of the cluster
        let minX = tables.map { $0.column }.min() ?? 0
        let maxX = tables.map { $0.column + $0.width }.max() ?? 0
        let minY = tables.map { $0.row }.min() ?? 0
        let maxY = tables.map { $0.row + $0.height }.max() ?? 0

```

**Suggested Documentation:**

```swift
/// [Description of the maxX property]
```

### minY (Line 177)

**Context:**

```swift
        // Calculate the min and max rows/columns of the cluster
        let minX = tables.map { $0.column }.min() ?? 0
        let maxX = tables.map { $0.column + $0.width }.max() ?? 0
        let minY = tables.map { $0.row }.min() ?? 0
        let maxY = tables.map { $0.row + $0.height }.max() ?? 0

        // Convert grid coordinates to pixel coordinates
```

**Suggested Documentation:**

```swift
/// [Description of the minY property]
```

### maxY (Line 178)

**Context:**

```swift
        let minX = tables.map { $0.column }.min() ?? 0
        let maxX = tables.map { $0.column + $0.width }.max() ?? 0
        let minY = tables.map { $0.row }.min() ?? 0
        let maxY = tables.map { $0.row + $0.height }.max() ?? 0

        // Convert grid coordinates to pixel coordinates
        let originX = CGFloat(minX) * cellSize
```

**Suggested Documentation:**

```swift
/// [Description of the maxY property]
```

### originX (Line 181)

**Context:**

```swift
        let maxY = tables.map { $0.row + $0.height }.max() ?? 0

        // Convert grid coordinates to pixel coordinates
        let originX = CGFloat(minX) * cellSize
        let originY = CGFloat(minY) * cellSize
        let width = CGFloat(maxX - minX) * cellSize
        let height = CGFloat(maxY - minY) * cellSize
```

**Suggested Documentation:**

```swift
/// [Description of the originX property]
```

### originY (Line 182)

**Context:**

```swift

        // Convert grid coordinates to pixel coordinates
        let originX = CGFloat(minX) * cellSize
        let originY = CGFloat(minY) * cellSize
        let width = CGFloat(maxX - minX) * cellSize
        let height = CGFloat(maxY - minY) * cellSize
        return CGRect(x: originX, y: originY, width: width, height: height)
```

**Suggested Documentation:**

```swift
/// [Description of the originY property]
```

### width (Line 183)

**Context:**

```swift
        // Convert grid coordinates to pixel coordinates
        let originX = CGFloat(minX) * cellSize
        let originY = CGFloat(minY) * cellSize
        let width = CGFloat(maxX - minX) * cellSize
        let height = CGFloat(maxY - minY) * cellSize
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the width property]
```

### height (Line 184)

**Context:**

```swift
        let originX = CGFloat(minX) * cellSize
        let originY = CGFloat(minY) * cellSize
        let width = CGFloat(maxX - minX) * cellSize
        let height = CGFloat(maxY - minY) * cellSize
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

```

**Suggested Documentation:**

```swift
/// [Description of the height property]
```

### rowDifference (Line 189)

**Context:**

```swift
    }

    private func areTablesPhysicallyAdjacent(table1: TableModel, table2: TableModel) -> Bool {
        let rowDifference = abs(table1.row - table2.row)
        let columnDifference = abs(table1.column - table2.column)

        // Check for direct adjacency (horizontally, vertically, or diagonally)
```

**Suggested Documentation:**

```swift
/// [Description of the rowDifference property]
```

### columnDifference (Line 190)

**Context:**

```swift

    private func areTablesPhysicallyAdjacent(table1: TableModel, table2: TableModel) -> Bool {
        let rowDifference = abs(table1.row - table2.row)
        let columnDifference = abs(table1.column - table2.column)

        // Check for direct adjacency (horizontally, vertically, or diagonally)
        return (rowDifference == 3 && columnDifference == 0)  // Vertical adjacency
```

**Suggested Documentation:**

```swift
/// [Description of the columnDifference property]
```

### currentTables (Line 204)

**Context:**

```swift
        oldCategory: Reservation.ReservationCategory,
        selectedCategory: Reservation.ReservationCategory, cellSize: CGFloat
    ) {
        let currentTables = tables

        // 1. Are there the conditions for new clusters?

```

**Suggested Documentation:**

```swift
/// [Description of the currentTables property]
```

### newReservationsCount (Line 208)

**Context:**

```swift

        // 1. Are there the conditions for new clusters?

        var newReservationsCount = 0
        for table in tables {
            if resCache.reservation(
                forTable: table.id, datetime: combinedDate, category: selectedCategory) != nil
```

**Suggested Documentation:**

```swift
/// [Description of the newReservationsCount property]
```

### newClusters (Line 234)

**Context:**

```swift
        }

        // 3) Not in cache, relevant changes => recalc clusters
        let newClusters = calculateClusters(
            for: activeReservations, tables: currentTables, combinedDate: combinedDate,
            cellSize: cellSize)
        self.clusters = newClusters
```

**Suggested Documentation:**

```swift
/// [Description of the newClusters property]
```


Total documentation suggestions: 45

