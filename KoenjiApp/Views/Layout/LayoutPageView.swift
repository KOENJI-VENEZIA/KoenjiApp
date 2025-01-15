//
//  LayoutPageView.swift
//  KoenjiApp
//
//  Refactored to maintain separate layouts per date and category.
//
import SwiftUI
import CoreGraphics


struct LayoutPageView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData
    
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme

    
    @Namespace private var animationNamespace
    
    // Each LayoutPageView has its own LayoutUIManager
    @StateObject private var layoutUI: LayoutUIManager
    
    // Filters
    var selectedDate: Date
    var selectedCategory: Reservation.ReservationCategory
    
    // Time
    @Binding var currentTime: Date
    @Binding var isManuallyOverridden: Bool
    @Binding var showingTimePickerSheet: Bool
    
    // Reservation editing
    @Binding var selectedReservation: Reservation?
    @Binding var showInspector: Bool
    @Binding var showingEditReservation: Bool
    
    // Add Reservation
    @Binding var showingAddReservationSheet: Bool
    @Binding var tableForNewReservation: TableModel?
    
    // Alerts and locks
    @Binding var showingNoBookingAlert: Bool
    @Binding var isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    
    // Zoom and pan state
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    var adjustedWidth: CGFloat

    var clusters: [CachedCluster]
    
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    
    @State private var navigationBarHeight: CGFloat = 0
    
    @State private var resetInProgress: Bool = false
    @State private var cachedActiveReservations: [Reservation] = []
    @State private var lastFetchedDate: Date? = nil
    @State private var lastFetchedTime: Date? = nil
    @State private var lastFetchedCount: Int = 0

    
    @State private var pendingClusterUpdate: DispatchWorkItem?
    
    private var backgroundColor: Color {
            return selectedCategory.backgroundColor
    }


    
    // Initialize LayoutUIManager with date and category
    init(selectedDate: Date,
         selectedCategory: Reservation.ReservationCategory,
         currentTime: Binding<Date>,
         isManuallyOverridden: Binding<Bool>,
         showingTimePickerSheet: Binding<Bool>,
         selectedReservation: Binding<Reservation?>,
         showInspector: Binding<Bool>,
         showingEditReservation: Binding<Bool>,
         showingAddReservationSheet: Binding<Bool>,
         tableForNewReservation: Binding<TableModel?>,
         showingNoBookingAlert: Binding<Bool>,
         isLayoutLocked: Binding<Bool>,
         isLayoutReset: Binding<Bool>,
         scale: Binding<CGFloat>,
         offset: Binding<CGSize>,
         clusters: [CachedCluster],
         adjustedWidth: CGFloat)
       

    {
        
        self.selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._currentTime = currentTime
        self._isManuallyOverridden = isManuallyOverridden
        self._showingTimePickerSheet = showingTimePickerSheet
        self._selectedReservation = selectedReservation
        self._showInspector = showInspector
        self._showingEditReservation = showingEditReservation
        self._showingAddReservationSheet = showingAddReservationSheet
        self._tableForNewReservation = tableForNewReservation
        self._showingNoBookingAlert = showingNoBookingAlert
        self._isLayoutLocked = isLayoutLocked
        self._isLayoutReset = isLayoutReset
        self._scale = scale
        self._offset = offset
        self.clusters = clusters
        self.adjustedWidth = adjustedWidth

        
        // Initialize LayoutUIManager with date and category
        _layoutUI = StateObject(wrappedValue: LayoutUIManager(date: selectedDate, category: selectedCategory))
    }
    
    
    
    var body: some View {
        GeometryReader { parentGeometry in
            let viewportWidth = parentGeometry.size.width
            let viewportHeight = parentGeometry.size.height
            
            let gridWidth = CGFloat(store.totalColumns) * layoutUI.cellSize
            let gridHeight = CGFloat(store.totalRows) * layoutUI.cellSize
            
            let isLunch = {
                if case .lunch = selectedCategory { return true }
                return false
            }()
            
            let activeReservations = fetchActiveReservationsIfNeeded() // Fetch once for the entire loop
            
            
            
            LazyView(
                ZoomableScrollView(availableSize: CGSize(
                    width: adjustedWidth,
                    height: viewportHeight - 100
                ), category: .constant(selectedCategory), scale: $scale) {
                        VStack {
                            Text("\(dayOfWeek(for: selectedDate)), \(DateHelper.fullDateFormatter.string(from: selectedDate)) (\(selectedCategory.rawValue)) - \(DateHelper.timeFormatter.string(from: currentTime))")
                                .font(.system(size: 28, weight: .bold))
                            //.foregroundColor(selectedCategory == .lunch ? Color.title_color_lunch : Color.title_color_dinner)
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                        }
                            ZStack {
                                // Background color and grid
                                //Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA"))
                                Rectangle()
                                    //.frame(width: gridWidth, height: gridHeight)
                                //.background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                                Rectangle()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    //.frame(width: gridWidth, height: gridHeight)
                                //\.background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                                gridData.gridBackground(selectedCategory: selectedCategory)
                                    //.frame(width: gridWidth, height: gridHeight)
                                    .background(backgroundColor)
                                
                                if isLoading {
                                    ForEach(store.baseTables, id: \.id) { table in
                                        let tableWidth = CGFloat(table.width) * layoutUI.cellSize
                                        let tableHeight = CGFloat(table.height) * layoutUI.cellSize
                                        let xPos = CGFloat(table.column) * layoutUI.cellSize + tableWidth / 2
                                        let yPos = CGFloat(table.row) * layoutUI.cellSize + tableHeight / 2
                                        
                                        RoundedRectangle(cornerRadius: 8.0)
                                            .fill(Color.gray.opacity(0.3)) // Placeholder color
                                            .frame(width: tableWidth, height: tableHeight)
                                            .position(x: xPos, y: yPos)
                                        RoundedRectangle(cornerRadius: 8.0)
                                            .stroke(Color.gray.opacity(0.7), lineWidth: 3) // Placeholder color
                                            .frame(width: tableWidth, height: tableHeight)
                                            .position(x: xPos, y: yPos)
                                        
                                    }
                                    
                                    Text("Caricamento...")
                                        .foregroundColor(Color.gray.opacity(0.8))
                                        .font(.headline)
                                        .padding(20)
                                        .background(Color.white.opacity(0.3))
                                        .cornerRadius(8)
                                        .frame(width: gridWidth / 2, height: gridHeight / 2)
                                        .position(x: gridWidth / 2, y: gridHeight / 2 - layoutUI.cellSize)
                                        .animation(.spring(duration: 0.3), value: 3)
                                    
                                } else {
                                    // Individual tables
                                    ForEach(layoutUI.tables, id: \.id) { table in
                                        TableView(
                                            table: table,
                                            selectedDate: selectedDate,
                                            selectedCategory: selectedCategory,
                                            currentTime: currentTime,
                                            activeReservations: activeReservations,
                                            layoutUI: layoutUI,
                                            showingNoBookingAlert: $showingNoBookingAlert,
                                            onTapEmpty: { handleEmptyTableTap(for: table) },
                                            showInspector: $showInspector,
                                            onEditReservation: { reservation in
                                                selectedReservation = reservation
                                            },
                                            isLayoutLocked: isLayoutLocked,
                                            isLayoutReset: $isLayoutReset,
                                            animationNamespace: animationNamespace,
                                            onTableUpdated: { updatedTable in
                                                self.updateAdjacencyCountsForLayout(updatedTable)
                                                layoutUI.clusters = self.calculateClusters(for: activeReservations)
                                                let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
                                                store.saveClusters(layoutUI.clusters, for: combinedDate, category: selectedCategory)
                                                layoutUI.saveLayout()
                                                store.saveTables(layoutUI.tables, for: combinedDate, category: selectedCategory)
                                            }
                                        )
                                        .environmentObject(store)
                                        .environmentObject(reservationService)
                                        .environmentObject(gridData)
                                        .animation(.spring(duration: 0.3), value: adjustedWidth)
                                        
                                        
                                        
                                        
                                        if layoutUI.clusters.isEmpty && !isLoadingClusters {
                                        } else if isLoadingClusters {
                                            ProgressView("Loading Clusters...")
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        } else {
                                            // Reservation clusters overlay
                                            ForEach(layoutUI.clusters) { cluster in
                                                let overlayFrame = cluster.frame
                                                
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8.0)
                                                        .fill(isLunch ? Color.active_table_lunch : Color.active_table_dinner)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8.0)
                                                                .stroke(isLayoutLocked ? (isLunch ? Color.layout_locked_lunch : Color.layout_locked_dinner) : (isLunch ? Color.layout_unlocked_lunch : Color.layout_unlocked_dinner), lineWidth: isLayoutLocked ? 3 : 2))
                                                        .frame(width: overlayFrame.width, height: overlayFrame.height)
                                                        .position(x: overlayFrame.midX, y: overlayFrame.midY)
                                                        .zIndex(1)
                                                        .allowsHitTesting(false) // Ignore touch input
                                                    // Reservation label (centered on the cluster)
                                                    if cluster.tableIDs.first != nil {
                                                        let overlayFrame = cluster.frame
                                                        VStack(spacing: 4) {
                                                            Text(cluster.reservationID.name)
                                                                .bold()
                                                                .font(.headline)
                                                                .foregroundColor(.white)
                                                            Text("\(cluster.reservationID.numberOfPersons) pers.")
                                                                .font(.footnote)
                                                                .opacity(0.8)
                                                            Text(cluster.reservationID.phone)
                                                                .font(.footnote)
                                                                .opacity(0.8)
                                                            if let remaining = TimeHelpers.remainingTimeString(endTime: cluster.reservationID.endTime, currentTime: currentTime) {
                                                                Text("Rimasto: \(remaining)")
                                                                    .foregroundColor(Color(hex: "#B4231F"))
                                                                    .font(.footnote)
                                                            }
                                                            if let duration = TimeHelpers.availableTimeString(endTime: cluster.reservationID.endTime, startTime: cluster.reservationID.startTime) {
                                                                Text("\(duration)")
                                                                    .foregroundColor(Color(hex: "#B4231F"))
                                                                    .font(.footnote)
                                                            }
                                                        }
                                                        .position(x: overlayFrame.midX, y: overlayFrame.midY)
                                                        .zIndex(2)
                                                    }
                                                    
                                                }
                                                .allowsHitTesting(false)
                                            }
                                        }
                                    }
                                }
                            }
                            .drawingGroup()
                            .frame(width: gridWidth, height: gridHeight)
                            .compositingGroup()
                            // .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)

                }
                    .frame(width: viewportWidth, height: viewportHeight)
                
                    .onAppear {
                        isLoadingClusters = true
                        isLoading = true
                        Task {
                            DispatchQueue.main.async {
                                loadCurrentLayout()
                                let activeReservations = fetchActiveReservationsIfNeeded()
                                debounceClusterUpdate(for: activeReservations)
                                isLoadingClusters = false
                                isLoading = false
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scale = 1.0 // Reset scale to ensure re-centering
                            offset = .zero // Reset offset for correct alignment
                        }
                    }
                    .onChange(of: isLayoutReset) { old, reset in
                        if reset {
                            isLoading = true
                            resetCurrentLayout()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                isLoading = false
                                isLayoutReset = false // Clear reset state
                            }
                        }
                    }
                    .onChange(of: selectedCategory) { old, newCategory in
                        // Load tables for the new category and date
                        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
                        layoutUI.tables = store.loadTables(for: combinedDate, category: newCategory)
                        let activeReservations = fetchActiveReservationsIfNeeded()
                        debounceClusterUpdate(for: activeReservations)
                        
                    }
                    .onChange(of: selectedDate) { old, newDate in
                        let combinedDate = DateHelper.combine(date: newDate, time: currentTime)
                        
                        layoutUI.tables = store.loadTables(for: combinedDate, category: selectedCategory)
                        let activeReservations = fetchActiveReservationsIfNeeded()
                        debounceClusterUpdate(for: activeReservations)
                        
                        
                        
                    }
                    .onChange(of: currentTime) { old, newTime in
                        let combinedDate = DateHelper.combine(date: selectedDate, time: newTime)
                        
                        // 1) Get active reservations
                        let activeReservations = fetchActiveReservationsIfNeeded()
                        
                        // 2) If we have a cached cluster for (selectedDate, newTime, selectedCategory) and
                        //    the table layout hasn't changed, skip recalculation.
                        let cacheKey = store.keyFor(date: combinedDate, category: selectedCategory)
                        let cachedClusters = store.loadClusters(for: combinedDate, category: selectedCategory)
                        
                        // 3) If we already have clusters for this minute in the store, just use them:
                        if !cachedClusters.isEmpty {
                            layoutUI.clusters = cachedClusters
                            print("Using cached clusters for \(cacheKey), skipping recalculation.")
                        } else {
                            print("No cached clusters found for \(cacheKey), recalculating...")
                            debounceClusterUpdate(for: activeReservations)
                        }
                        
                    }
                    .onChange(of: store.reservations) { oldValue, newValue in
                        print("reservations changed from \(oldValue.count) to \(newValue.count)")
                        // Force the active-reservations fetch (since store.reservations changed)
                        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
                        layoutUI.tables = store.loadTables(for: combinedDate, category: selectedCategory)
                        
                        let activeReservations = fetchActiveReservationsIfNeeded()
                        
                        // Recalculate clusters or force-update them:
                        // e.g. either a 'debounceClusterUpdate(for:)' or 'forceUpdateClusterCache(for:)'
                        debounceClusterUpdate(for: activeReservations)
                    }
                    .alert(isPresented: $layoutUI.showAlert) {
                        Alert(
                            title: Text("Posizionamento non valido"),
                            message: Text(layoutUI.alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                //.background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)
            )
            
            
        }
        //.frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
    
    // Handle tapping an empty table to add a reservation
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }
    
    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter
    }()
    
    private func dayOfWeek(for date: Date) -> String {
        Self.dayOfWeekFormatter.locale = locale
        return Self.dayOfWeekFormatter.string(from: date)
    }
    
    
    private func updateLayoutResetState() {
        isLayoutReset = (layoutUI.tables == store.baseTables)
    }
    
    private func updateAdjacencyCountsForLayout(_ updatedTable: TableModel) {
        
        let combinedDateTime = DateHelper.combine(date: selectedDate, time: currentTime) 
        
        // Identify tables with adjacentCount > 0 before the move
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        
        // Identify affected tables (dragged table + neighbors)
        var affectedTableIDs = Set<Int>()
        affectedTableIDs.insert(updatedTable.id)
        
        let adjacencyResult = store.isTableAdjacent(updatedTable, combinedDateTime: combinedDateTime, activeTables: layoutUI.tables)
        for neighbor in adjacencyResult.adjacentDetails.values {
            affectedTableIDs.insert(neighbor.id)
        }
        
        // Include all previously adjacent tables in the affected list
        affectedTableIDs.formUnion(previousAdjacentTables)
        
        // Recalculate adjacency counts for affected tables only
        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = store.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: layoutUI.tables)
                layoutUI.tables[index].adjacentCount = adjacency.adjacentCount
                
                layoutUI.tables[index].activeReservationAdjacentCount = store.isAdjacentWithSameReservation(
                    for: table,
                    combinedDateTime: combinedDateTime,
                    activeTables: layoutUI.tables
                ).count
            }
        }
        
        // Update cached layout and save
        let layoutKey = store.keyFor(date: combinedDateTime, category: selectedCategory)
        store.cachedLayouts[layoutKey] = layoutUI.tables
        store.saveToDisk()
    }
    

    
    private func loadCurrentLayout() {
        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
        
        
        if !layoutUI.isConfigured {
            layoutUI.configure(store: store, reservationService: reservationService)
            
            layoutUI.tables = store.loadTables(for: combinedDate, category: selectedCategory)
        }
        
        layoutUI.clusters = store.loadClusters(for: combinedDate, category: selectedCategory)
        
        
    }
    private func resetCurrentLayout() {
        print("Resetting layout... [resetCurrentLayout()]")
        resetInProgress = true
        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
        let key = store.keyFor(date: combinedDate, category: selectedCategory)
        
        if let baseTables = store.cachedLayouts[key] {
            layoutUI.tables = baseTables
        } else {
            layoutUI.tables = []
        }
        
        layoutUI.clusters = []
        store.saveClusters([], for: combinedDate, category: selectedCategory)
        store.cachedLayouts[key] = nil
        
        // Ensure flag is cleared after reset completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInProgress = false
        }
    }
    
    /// Return all clusters for a single Reservation.
    private func clusters(for reservation: Reservation) -> [CachedCluster] {
        print("Called clusters()")
        // Step 1: Gather all tables that belong to `reservation`.
        // (table.id is in reservation.tables)
        let reservationTableIDs = Set(reservation.tables.map { $0.id })
        let relevantTables = layoutUI.tables.filter { reservationTableIDs.contains($0.id) }

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
                date: reservation.date ?? Date(),
                category: reservation.category,
                frame: calculateClusterFrame(component)
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

    private func calculateClusters(for activeReservations: [Reservation]) -> [CachedCluster] {
        print("Calculating clusters...")
        var allClusters: [CachedCluster] = []

        // Filter out reservations that ended or haven't started
        let validReservations = activeReservations.filter { reservation in
            print("\nDEBUG: Checking reservation: \(reservation)")

            // Parse startTime and endTime of the reservation
            guard let startTime = DateHelper.parseTime(reservation.startTime),
                  let endTime = DateHelper.parseTime(reservation.endTime),
                  let normalizedStartTime = DateHelper.normalizedTime(time: startTime, date: selectedDate),
                  let normalizedEndTime = DateHelper.normalizedTime(time: endTime, date: selectedDate)
                else {
                print("DEBUG: Failed to parse and normalize startTime, endTime, or input time.")
                return false
            }
            
            return currentTime >= normalizedStartTime && currentTime < normalizedEndTime
        }

        for reservation in validReservations {
            // For each reservation, gather the clusters
            let resClusters = clusters(for: reservation)
            allClusters.append(contentsOf: resClusters)
        }

        return allClusters
    }
    
    private func recalculateClusters(for activeReservations: [Reservation]) {
        print("Recalculating clusters... [recalculateClusters() in LayoutPageView]")
        
        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
        let cacheKey = store.keyFor(date: combinedDate, category: selectedCategory)
        
        // Check if clusters are already cached
        let cachedClusters = store.loadClusters(for: combinedDate, category: selectedCategory)
        if !cachedClusters.isEmpty {
            print("Using cached clusters for key: \(cacheKey)")
            layoutUI.clusters = cachedClusters
            return
        }
        
        // Calculate and cache clusters
        let newClusters = calculateClusters(for: activeReservations)
        layoutUI.clusters = newClusters
        
        // Save clusters in the LRU cache
        store.saveClusters(newClusters, for: combinedDate, category: selectedCategory)
    }

    private func calculateClusterFrame(_ tables: [TableModel]) -> CGRect {
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
        let originX = CGFloat(minX) * layoutUI.cellSize
        let originY = CGFloat(minY) * layoutUI.cellSize
        let width = CGFloat(maxX - minX) * layoutUI.cellSize
        let height = CGFloat(maxY - minY) * layoutUI.cellSize
        
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
    

}

  
// MARK: - Cluster Management
extension LayoutPageView {
    /// Asynchronously recalculates clusters for the current layout.
    private func recalculateClustersAsync(for activeReservations: [Reservation]) {
        guard !resetInProgress else {
            print("Recalculation skipped: reset in progress.")
            return
        }
        
        Task {
            print("Recalculating clusters asynchronously... [recalculateClustersAsync()]")

            let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
            let cacheKey = store.keyFor(date: combinedDate, category: selectedCategory)

            // Load cached clusters if available
            let cachedClusters = store.loadClusters(for: combinedDate, category: selectedCategory)
            if !cachedClusters.isEmpty {
                print("Using cached clusters for key: \(cacheKey)")
                await MainActor.run {
                    layoutUI.clusters = cachedClusters
                }
                return
            }

            // Calculate clusters if not cached
            let newClusters = calculateClusters(for: activeReservations)
            await MainActor.run {
                layoutUI.clusters = newClusters
            }

            // Save calculated clusters to cache
            store.saveClusters(newClusters, for: combinedDate, category: selectedCategory)
        }
    }
    
    private func recalculateClustersIfNeeded(for activeReservations: [Reservation]) {
        print("Recalculating clusters... [recalculateClustersIfNeeded()]")
        
        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
        let cacheKey = store.keyFor(date: combinedDate, category: selectedCategory)
        
        // Check if clusters are already cached
        let cachedClusters = store.loadClusters(for: combinedDate, category: selectedCategory)
        print("Using cached clusters for key: \(cacheKey)")
        layoutUI.clusters = cachedClusters

        
        // Calculate and cache clusters
        Task {
            let newClusters = calculateClusters(for: activeReservations)
            await MainActor.run {
                layoutUI.clusters = newClusters
            }
            store.saveClusters(newClusters, for: combinedDate, category: selectedCategory)
        }
    }
    
    private func debounceClusterUpdate(for activeReservations: [Reservation]) {
        pendingClusterUpdate?.cancel()
        pendingClusterUpdate = DispatchWorkItem {
            recalculateClustersIfNeeded(for: activeReservations)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: pendingClusterUpdate!)
    }

    /// Forces an update to the cluster cache.
    private func forceUpdateClusterCache(for activeReservations: [Reservation]) {
        Task {
            print("Force updating cluster cache... [forceUpdateClusterCache()]")
            
            let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)

            let newClusters = calculateClusters(for: activeReservations)
            await MainActor.run {
                layoutUI.clusters = newClusters
            }

            store.saveClusters(newClusters, for: combinedDate, category: selectedCategory)
        }
    }
    
    private func fetchActiveReservationsIfNeeded() -> [Reservation] {
        // Check if the fetch is redundant
        if lastFetchedCount == store.reservations.count {
            if let lastDate = lastFetchedDate,
               let lastTime = lastFetchedTime,
               Calendar.current.isDate(selectedDate, inSameDayAs: lastDate),
               abs(currentTime.timeIntervalSince(lastTime)) < 60 {
                    return cachedActiveReservations
            }
        }
        
        print("Called fetchActiveReservations!")
        
        // Use a set to avoid duplicates
        var uniqueReservations = Set<Reservation>()
        
        let calendar = Calendar.current
        let preloadDate = calendar.startOfDay(for: selectedDate)
        
        for (key, reservation) in store.activeReservationCache {
            
            guard key.date == preloadDate,
                  
                  key.time >= currentTime,
                  key.time < currentTime.addingTimeInterval(3600)
            else {
                continue
            }
            
            uniqueReservations.insert(reservation)
        }
        
        let activeReservations = Array(uniqueReservations)
        
        print("DEBUG: Found \(activeReservations.count) unique active reservations.")
        
        // Cache them for next call
        DispatchQueue.main.async {
            cachedActiveReservations = activeReservations
            lastFetchedCount = store.reservations.count
            lastFetchedDate = selectedDate
            lastFetchedTime = currentTime
        }
        
        return activeReservations
    }
}

extension Reservation.ReservationCategory {
    var backgroundColor: Color {
        switch self {
        case .lunch: return Color.grid_background_lunch
        case .dinner: return Color.grid_background_dinner
        case .noBookingZone: return Color.sidebar_generic
        }
    }
}
