Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Layout/LayoutPageView.swift...
# Documentation Suggestions for LayoutPageView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Layout/LayoutPageView.swift
Total suggestions: 63

## Class Documentation (4)

### LayoutPageView (Line 12)

**Context:**

```swift
import SwiftUI
import os

struct LayoutPageView: View {
    // MARK: - Dependencies
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
```

**Suggested Documentation:**

```swift
/// LayoutPageView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### LayoutPageView (Line 177)

**Context:**

```swift
}

// MARK: - Subviews & Helper Methods
extension LayoutPageView {

    /// The header text displayed at the top of the layout.
    private var headerView: some View {
```

**Suggested Documentation:**

```swift
/// LayoutPageView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### LayoutPageView (Line 485)

**Context:**

```swift
}

// MARK: - Custom onChange Handlers
extension LayoutPageView {
    /// A simple debounce helper.
    private func debounce(action: @escaping () -> Void, delay: TimeInterval = 0.1) {
        debounceWorkItem?.cancel()
```

**Suggested Documentation:**

```swift
/// LayoutPageView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### Reservation (Line 512)

**Context:**

```swift
}

// MARK: - Reservation.ReservationCategory Background Color
extension Reservation.ReservationCategory {
    var backgroundColor: Color {
        switch self {
        case .lunch: return Color.grid_background_lunch
```

**Suggested Documentation:**

```swift
/// Reservation class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (9)

### contentWithOnChangeHandlers (Line 67)

**Context:**

```swift
        }
    }
    
    private func contentWithOnChangeHandlers(geometry: GeometryProxy) -> some View {
        
        ZoomableScrollView() {
            headerView
```

**Suggested Documentation:**

```swift
/// [Add a description of what the contentWithOnChangeHandlers method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### loadCurrentLayout (Line 331)

**Context:**

```swift
        }
    }

    private func loadCurrentLayout() async throws {
        // Load drawings synchronously (this doesn't need to change)
        let newDrawingModel = env.scribbleService.reloadDrawings(
            for: appState.selectedDate, category: appState.selectedCategory
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadCurrentLayout method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### onTableUpdated (Line 380)

**Context:**

```swift
        }
    }

    private func onTableUpdated(_ updatedTable: TableModel) {
        updateAdjacencyCounts(for: updatedTable)
        updateClustersIfNeeded(for: env.store.reservations, tables: layoutUI.tables)
        env.layoutServices.saveTables(layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the onTableUpdated method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateAdjacencyCounts (Line 386)

**Context:**

```swift
        env.layoutServices.saveTables(layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)
    }

    private func updateAdjacencyCounts(for updatedTable: TableModel) {
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        var affectedTableIDs = Set<Int>([updatedTable.id])
        let adjacencyResult = env.layoutServices.isTableAdjacent(updatedTable,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateAdjacencyCounts method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateClustersIfNeeded (Line 417)

**Context:**

```swift
        env.layoutServices.saveToDisk()
    }

    private func updateClustersIfNeeded(for activeReservations: [Reservation], tables: [TableModel]) {
        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations,
            tables: tables,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateClustersIfNeeded method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateDrawingLayersIfNeeded (Line 428)

**Context:**

```swift
        )
    }

    private func updateDrawingLayersIfNeeded(for selectedCategory: Reservation.ReservationCategory) {
        let currentDrawingModel = env.scribbleService.reloadDrawings(
            for: appState.selectedDate, category: selectedCategory
        )
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateDrawingLayersIfNeeded method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### reloadLayout (Line 444)

**Context:**

```swift
        Self.logger.debug("Drawing layers updated for category: \(selectedCategory.rawValue)")
    }

    private func reloadLayout(_ selectedCategory: Reservation.ReservationCategory, _ activeReservations: [Reservation], force: Bool = false)  {
        
            updateTablesIfNeeded(for: appState.selectedCategory, force: force)
            updateClustersIfNeeded(for: activeReservations, tables: layoutUI.tables)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the reloadLayout method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateTablesIfNeeded (Line 452)

**Context:**

```swift
        
    }

    private func updateTablesIfNeeded(for selectedCategory: Reservation.ReservationCategory, force: Bool = false) {
        let currentTables = layoutUI.tables
        let newTables = env.layoutServices.loadTables(
            for: appState.selectedDate, category: selectedCategory
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateTablesIfNeeded method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### resetCurrentLayout (Line 463)

**Context:**

```swift
        withAnimation { layoutUI.tables = newTables }
    }

    private func resetCurrentLayout() {
        Self.logger.notice("Resetting current layout...")
        resetInProgress = true
        let key = env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the resetCurrentLayout method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (50)

### logger (Line 14)

**Context:**

```swift

struct LayoutPageView: View {
    // MARK: - Dependencies
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "LayoutPageView"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### env (Line 19)

**Context:**

```swift
        category: "LayoutPageView"
    )
    
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @EnvironmentObject var currentDrawing: DrawingModel
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 20)

**Context:**

```swift
    )
    
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### currentDrawing (Line 22)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(ClusterManager.self) var clusterManager
    @Environment(LayoutUnitViewModel.self) var unitView
```

**Suggested Documentation:**

```swift
/// [Description of the currentDrawing property]
```

### layoutUI (Line 23)

**Context:**

```swift
    @EnvironmentObject var appState: AppState

    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(ClusterManager.self) var clusterManager
    @Environment(LayoutUnitViewModel.self) var unitView
    
```

**Suggested Documentation:**

```swift
/// [Description of the layoutUI property]
```

### clusterManager (Line 24)

**Context:**

```swift

    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(ClusterManager.self) var clusterManager
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Environment(\.locale) var locale
```

**Suggested Documentation:**

```swift
/// [Description of the clusterManager property]
```

### unitView (Line 25)

**Context:**

```swift
    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(ClusterManager.self) var clusterManager
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### locale (Line 27)

**Context:**

```swift
    @Environment(ClusterManager.self) var clusterManager
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

```

**Suggested Documentation:**

```swift
/// [Description of the locale property]
```

### colorScheme (Line 28)

**Context:**

```swift
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var animationNamespace
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### horizontalSizeClass (Line 29)

**Context:**

```swift
    
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var animationNamespace

```

**Suggested Documentation:**

```swift
/// [Description of the horizontalSizeClass property]
```

### animationNamespace (Line 31)

**Context:**

```swift
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var animationNamespace

    // MARK: - Filters and Properties

```

**Suggested Documentation:**

```swift
/// [Description of the animationNamespace property]
```

### columnVisibility (Line 36)

**Context:**

```swift
    // MARK: - Filters and Properties

    // MARK: - Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var selectedReservation: Reservation?

    // MARK: - States
```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```

### selectedReservation (Line 37)

**Context:**

```swift

    // MARK: - Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var selectedReservation: Reservation?

    // MARK: - States
    @State private var isLoadingClusters: Bool = true
```

**Suggested Documentation:**

```swift
/// [Description of the selectedReservation property]
```

### isLoadingClusters (Line 40)

**Context:**

```swift
    @Binding var selectedReservation: Reservation?

    // MARK: - States
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
```

**Suggested Documentation:**

```swift
/// [Description of the isLoadingClusters property]
```

### isLoading (Line 41)

**Context:**

```swift

    // MARK: - States
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?
```

**Suggested Documentation:**

```swift
/// [Description of the isLoading property]
```

### resetInProgress (Line 42)

**Context:**

```swift
    // MARK: - States
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?
    private var clustersForTables: [CachedCluster] {
```

**Suggested Documentation:**

```swift
/// [Description of the resetInProgress property]
```

### statusChanged (Line 43)

**Context:**

```swift
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?
    private var clustersForTables: [CachedCluster] {
        clusterManager.clusters
```

**Suggested Documentation:**

```swift
/// [Description of the statusChanged property]
```

### debounceWorkItem (Line 44)

**Context:**

```swift
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?
    private var clustersForTables: [CachedCluster] {
        clusterManager.clusters
    }
```

**Suggested Documentation:**

```swift
/// [Description of the debounceWorkItem property]
```

### clustersForTables (Line 45)

**Context:**

```swift
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?
    private var clustersForTables: [CachedCluster] {
        clusterManager.clusters
    }
    // MARK: - Computed Properties
```

**Suggested Documentation:**

```swift
/// [Description of the clustersForTables property]
```

### isCompact (Line 49)

**Context:**

```swift
        clusterManager.clusters
    }
    // MARK: - Computed Properties
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var gridWidth: CGFloat { CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
```

**Suggested Documentation:**

```swift
/// [Description of the isCompact property]
```

### gridWidth (Line 50)

**Context:**

```swift
    }
    // MARK: - Computed Properties
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var gridWidth: CGFloat { CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
```

**Suggested Documentation:**

```swift
/// [Description of the gridWidth property]
```

### gridHeight (Line 51)

**Context:**

```swift
    // MARK: - Computed Properties
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var gridWidth: CGFloat { CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
```

**Suggested Documentation:**

```swift
/// [Description of the gridHeight property]
```

### isLunch (Line 52)

**Context:**

```swift
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var gridWidth: CGFloat { CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
```

**Suggested Documentation:**

```swift
/// [Description of the isLunch property]
```

### backgroundColor (Line 53)

**Context:**

```swift
    private var gridWidth: CGFloat { CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
```

**Suggested Documentation:**

```swift
/// [Description of the backgroundColor property]
```

### cacheKey (Line 54)

**Context:**

```swift
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { appState.selectedCategory.localized.uppercased() }
```

**Suggested Documentation:**

```swift
/// [Description of the cacheKey property]
```

### dayOfWeek (Line 55)

**Context:**

```swift
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { appState.selectedCategory.localized.uppercased() }
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }
```

**Suggested Documentation:**

```swift
/// [Description of the dayOfWeek property]
```

### fullDateString (Line 56)

**Context:**

```swift
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { appState.selectedCategory.localized.uppercased() }
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }

```

**Suggested Documentation:**

```swift
/// [Description of the fullDateString property]
```

### categoryString (Line 57)

**Context:**

```swift
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { appState.selectedCategory.localized.uppercased() }
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }

    // MARK: - Body
```

**Suggested Documentation:**

```swift
/// [Description of the categoryString property]
```

### timeString (Line 58)

**Context:**

```swift
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { appState.selectedCategory.localized.uppercased() }
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }

    // MARK: - Body
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the timeString property]
```

### body (Line 61)

**Context:**

```swift
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            contentWithOnChangeHandlers(geometry: geometry)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### reservations (Line 86)

**Context:**

```swift
            Task {
                do {
                    // Fetch reservations asynchronously for the selected date
                    let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                    
                    await MainActor.run {
                        env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservations (Line 106)

**Context:**

```swift
                Task {
                    do {
                        // Fetch reservations asynchronously
                        let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                        
                        await MainActor.run {
                            env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservations (Line 136)

**Context:**

```swift
        .onChange(of: appState.selectedCategory) { _, newCategory in
            debounceAsync {
                // Fetch reservations asynchronously for the selected date with the new category
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservations (Line 147)

**Context:**

```swift
        .onChange(of: appState.selectedDate) { _, newDate in
            debounceAsync {
                // Fetch reservations asynchronously for the new date
                let reservations = try await env.resCache.fetchReservations(for: newDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: newDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservations (Line 158)

**Context:**

```swift
        }
        .onChange(of: appState.showingEditReservation) {
            debounceAsync {
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### newDrawingModel (Line 333)

**Context:**

```swift

    private func loadCurrentLayout() async throws {
        // Load drawings synchronously (this doesn't need to change)
        let newDrawingModel = env.scribbleService.reloadDrawings(
            for: appState.selectedDate, category: appState.selectedCategory
        )
        
```

**Suggested Documentation:**

```swift
/// [Description of the newDrawingModel property]
```

### reservationsForDate (Line 347)

**Context:**

```swift
        }
        
        // Fetch reservations asynchronously from Firebase
        let reservationsForDate: [Reservation]
        do {
            reservationsForDate = try await env.resCache.fetchReservations(for: appState.selectedDate)
        } catch {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsForDate property]
```

### previousAdjacentTables (Line 387)

**Context:**

```swift
    }

    private func updateAdjacencyCounts(for updatedTable: TableModel) {
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        var affectedTableIDs = Set<Int>([updatedTable.id])
        let adjacencyResult = env.layoutServices.isTableAdjacent(updatedTable,
                                                                 combinedDateTime: appState.selectedDate,
```

**Suggested Documentation:**

```swift
/// [Description of the previousAdjacentTables property]
```

### affectedTableIDs (Line 388)

**Context:**

```swift

    private func updateAdjacencyCounts(for updatedTable: TableModel) {
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        var affectedTableIDs = Set<Int>([updatedTable.id])
        let adjacencyResult = env.layoutServices.isTableAdjacent(updatedTable,
                                                                 combinedDateTime: appState.selectedDate,
                                                             activeTables: layoutUI.tables)
```

**Suggested Documentation:**

```swift
/// [Description of the affectedTableIDs property]
```

### adjacencyResult (Line 389)

**Context:**

```swift
    private func updateAdjacencyCounts(for updatedTable: TableModel) {
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        var affectedTableIDs = Set<Int>([updatedTable.id])
        let adjacencyResult = env.layoutServices.isTableAdjacent(updatedTable,
                                                                 combinedDateTime: appState.selectedDate,
                                                             activeTables: layoutUI.tables)
        for neighbor in adjacencyResult.adjacentDetails.values {
```

**Suggested Documentation:**

```swift
/// [Description of the adjacencyResult property]
```

### index (Line 398)

**Context:**

```swift
        affectedTableIDs.formUnion(previousAdjacentTables)

        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = env.layoutServices.isTableAdjacent(table,
                                                                   combinedDateTime: appState.selectedDate,
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### table (Line 399)

**Context:**

```swift

        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = env.layoutServices.isTableAdjacent(table,
                                                                   combinedDateTime: appState.selectedDate,
                                                               activeTables: layoutUI.tables)
```

**Suggested Documentation:**

```swift
/// [Description of the table property]
```

### adjacency (Line 400)

**Context:**

```swift
        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = env.layoutServices.isTableAdjacent(table,
                                                                   combinedDateTime: appState.selectedDate,
                                                               activeTables: layoutUI.tables)
                layoutUI.tables[index].adjacentCount = adjacency.adjacentCount
```

**Suggested Documentation:**

```swift
/// [Description of the adjacency property]
```

### layoutKey (Line 412)

**Context:**

```swift
            }
        }

        let layoutKey = env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory)
        env.layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        env.layoutServices.saveToDisk()
    }
```

**Suggested Documentation:**

```swift
/// [Description of the layoutKey property]
```

### currentDrawingModel (Line 429)

**Context:**

```swift
    }

    private func updateDrawingLayersIfNeeded(for selectedCategory: Reservation.ReservationCategory) {
        let currentDrawingModel = env.scribbleService.reloadDrawings(
            for: appState.selectedDate, category: selectedCategory
        )
        if currentDrawing.layer1 != currentDrawingModel.layer1 {
```

**Suggested Documentation:**

```swift
/// [Description of the currentDrawingModel property]
```

### currentTables (Line 453)

**Context:**

```swift
    }

    private func updateTablesIfNeeded(for selectedCategory: Reservation.ReservationCategory, force: Bool = false) {
        let currentTables = layoutUI.tables
        let newTables = env.layoutServices.loadTables(
            for: appState.selectedDate, category: selectedCategory
        )
```

**Suggested Documentation:**

```swift
/// [Description of the currentTables property]
```

### newTables (Line 454)

**Context:**

```swift

    private func updateTablesIfNeeded(for selectedCategory: Reservation.ReservationCategory, force: Bool = false) {
        let currentTables = layoutUI.tables
        let newTables = env.layoutServices.loadTables(
            for: appState.selectedDate, category: selectedCategory
        )
        if !force {
```

**Suggested Documentation:**

```swift
/// [Description of the newTables property]
```

### key (Line 466)

**Context:**

```swift
    private func resetCurrentLayout() {
        Self.logger.notice("Resetting current layout...")
        resetInProgress = true
        let key = env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory)
        withAnimation {
            if let baseTables = env.layoutServices.cachedLayouts[key] {
                layoutUI.tables = baseTables
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### baseTables (Line 468)

**Context:**

```swift
        resetInProgress = true
        let key = env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory)
        withAnimation {
            if let baseTables = env.layoutServices.cachedLayouts[key] {
                layoutUI.tables = baseTables
            } else {
                layoutUI.tables = []
```

**Suggested Documentation:**

```swift
/// [Description of the baseTables property]
```

### backgroundColor (Line 513)

**Context:**

```swift

// MARK: - Reservation.ReservationCategory Background Color
extension Reservation.ReservationCategory {
    var backgroundColor: Color {
        switch self {
        case .lunch: return Color.grid_background_lunch
        case .dinner: return Color.grid_background_dinner
```

**Suggested Documentation:**

```swift
/// [Description of the backgroundColor property]
```


Total documentation suggestions: 63

