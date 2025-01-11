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

    var clusters: [CachedCluster]
    
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    
    @State private var navigationBarHeight: CGFloat = 0
    
    @State private var resetInProgress: Bool = false

    
    
    // Initialize LayoutUIManager with date and category
    init(selectedDate: Date,
         selectedCategory: Reservation.ReservationCategory,
         currentTime: Binding<Date>,
         isManuallyOverridden: Binding<Bool>,
         showingTimePickerSheet: Binding<Bool>,
         selectedReservation: Binding<Reservation?>,
         showingEditReservation: Binding<Bool>,
         showingAddReservationSheet: Binding<Bool>,
         tableForNewReservation: Binding<TableModel?>,
         showingNoBookingAlert: Binding<Bool>,
         isLayoutLocked: Binding<Bool>,
         isLayoutReset: Binding<Bool>,
         scale: Binding<CGFloat>,
         offset: Binding<CGSize>,
         clusters: [CachedCluster])
       

    {
        
        self.selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._currentTime = currentTime
        self._isManuallyOverridden = isManuallyOverridden
        self._showingTimePickerSheet = showingTimePickerSheet
        self._selectedReservation = selectedReservation
        self._showingEditReservation = showingEditReservation
        self._showingAddReservationSheet = showingAddReservationSheet
        self._tableForNewReservation = tableForNewReservation
        self._showingNoBookingAlert = showingNoBookingAlert
        self._isLayoutLocked = isLayoutLocked
        self._isLayoutReset = isLayoutReset
        self._scale = scale
        self._offset = offset
        self.clusters = clusters

        
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
            
            let activeReservations: [Reservation] = Array(Set(
                layoutUI.tables.compactMap { table in
                    reservationService.findActiveReservation(for: table, date: selectedDate, time: currentTime)
                }
            ))
            
            
            LazyView(
                    ZoomableScrollView(availableSize: CGSize(
                        width: viewportWidth,
                        height: viewportHeight
                    ), category: .constant(selectedCategory), scale: $scale) {
                        
                        VStack {
                            Text("\(dayOfWeek(for: selectedDate)), \(DateHelper.fullDateFormatter.string(from: selectedDate)) (\(selectedCategory.rawValue)) - \(DateHelper.timeFormatter.string(from: currentTime))")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(selectedCategory == .lunch ? Color.title_color_lunch : Color.title_color_dinner)
                                .padding(.top, 16)
                                .background(Color.clear) // Slightly opaque background for better visibility
                                .padding(.horizontal, 16)
                        }
                        
                        
                        ZStack {
                            // Background color and grid
                            Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA"))
                            Rectangle()
                                .frame(width: gridWidth, height: gridHeight)
                                .background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                            Rectangle()
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .frame(width: gridWidth, height: gridHeight)
                                .background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                            gridData.gridBackground(selectedCategory: selectedCategory)
                                .frame(width: gridWidth, height: gridHeight)
                                .background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                            
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
                                    .animation(.easeInOut(duration: 0.3), value: 3)
                                
                            } else {
                                // Individual tables
                                ForEach(layoutUI.tables, id: \.id) { table in
                                    TableView(
                                        table: table,
                                        selectedDate: selectedDate,
                                        selectedCategory: selectedCategory,
                                        currentTime: currentTime,
                                        layoutUI: layoutUI,
                                        showingNoBookingAlert: $showingNoBookingAlert,
                                        onTapEmpty: { handleEmptyTableTap(for: table) },
                                        onEditReservation: { reservation in
                                            selectedReservation = reservation
                                            showingEditReservation = true
                                        },
                                        isLayoutLocked: isLayoutLocked,
                                        isLayoutReset: $isLayoutReset,
                                        animationNamespace: animationNamespace,
                                        onTableUpdated: { updatedTable in
                                            self.updateAdjacencyCountsForLayout(updatedTable)
                                            layoutUI.clusters = self.calculateClusters(for: activeReservations)
                                            store.saveClusters(layoutUI.clusters, for: selectedDate, category: selectedCategory)
                                        }
                                    )
                                    .environmentObject(store)
                                    .environmentObject(reservationService)
                                    .environmentObject(gridData)
                                    .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
                                    
                                    
                                    
                                    
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
                        .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)

                    }
                    .ignoresSafeArea(.all, edges: .top)
                    .frame(width: viewportWidth, height: viewportHeight)
                    
                    .onAppear {
                        isLoadingClusters = true
                        isLoading = true
                        Task {
                            DispatchQueue.main.async {
                                loadCurrentLayout()
                                recalculateClustersAsync()
                                isLoadingClusters = false
                                isLoading = false
                            }
                        }
                    }
                        .onChange(of: isLayoutReset) { reset in
                            if reset {
                                isLoading = true
                                resetCurrentLayout()

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    isLoading = false
                                    isLayoutReset = false // Clear reset state
                                }
                            }
                        }
                    .onChange(of: selectedCategory) { newCategory in
                        // Load tables for the new category and date
                        layoutUI.tables = store.loadTables(for: selectedDate, category: newCategory)
                        recalculateClustersAsync()

                    }
                    .onChange(of: selectedDate) { newDate in
                        layoutUI.tables = store.loadTables(for: newDate, category: selectedCategory)
                        recalculateClustersAsync()



                    }
                    .onChange(of: currentTime) { newTime in
                        layoutUI.clusters = self.calculateClusters(for: activeReservations)
                        store.saveClusters(layoutUI.clusters, for: selectedDate, category: selectedCategory)

                    }

                    .onReceive(store.$activeReservations) { _ in
                        recalculateClustersAsync()

                    }
                    .alert(isPresented: $layoutUI.showAlert) {
                        Alert(
                            title: Text("Posizionamento non valido"),
                            message: Text(layoutUI.alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                        .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)
            )
        }
        .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)    }
    
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
        
        guard let combinedDateTime = DateHelper.combine(date: selectedDate, time: currentTime) else {
            print("Failed to combine date and time.")
            return
        }
        
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
        let layoutKey = store.keyFor(date: selectedDate, category: selectedCategory)
        store.cachedLayouts[layoutKey] = layoutUI.tables
        store.saveToDisk()
    }
    

    
    private func loadCurrentLayout() {
        if !layoutUI.isConfigured {
            layoutUI.configure(store: store, reservationService: reservationService)
            layoutUI.tables = store.loadTables(for: selectedDate, category: selectedCategory)
        }
        
        layoutUI.clusters = store.loadClusters(for: selectedDate, category: selectedCategory)
        recalculateClusters()
        
    }
    private func resetCurrentLayout() {
        print("Resetting layout... [resetCurrentLayout()]")
        resetInProgress = true

        let key = store.keyFor(date: selectedDate, category: selectedCategory)
        
        if let baseTables = store.cachedLayouts[key] {
            layoutUI.tables = baseTables
        } else {
            layoutUI.tables = []
        }
        
        layoutUI.clusters = []
        store.saveClusters([], for: selectedDate, category: selectedCategory)
        store.cachedLayouts[key] = nil
        
        // Ensure flag is cleared after reset completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInProgress = false
        }
    }
    

    private func calculateClusters(for activeReservations: [Reservation]) -> [CachedCluster] {
        print("Calculating clusters.... [calculatingClusters() in LayoutPageView]")
        var visitedTables = Set<Int>() // Track visited table IDs
        var clusters: [CachedCluster] = [] // Store resulting clusters

        for table in layoutUI.tables {
            // Skip already visited tables or those without an active reservation
            

            print("Fetching clusters.... [calculatingClusters() in LayoutPageView]")

            // Fetch the cluster for this table
            let cluster = getCluster(for: table, activeReservations: activeReservations)

            // Add clusters to the list
            clusters.append(contentsOf: cluster)

            // Mark all tables in the cluster as visited
            cluster.forEach { cachedCluster in
                visitedTables.formUnion(cachedCluster.tableIDs)
            }
        }

        return clusters
    }
    
    private func recalculateClusters() {
        print("Recalculating clusters... [recalculateClusters() in LayoutPageView]")
        
        let cacheKey = store.keyFor(date: selectedDate, category: selectedCategory)
        
        // Check if clusters are already cached
        let cachedClusters = store.loadClusters(for: selectedDate, category: selectedCategory)
        if !cachedClusters.isEmpty {
            print("Using cached clusters for key: \(cacheKey)")
            layoutUI.clusters = cachedClusters
            return
        }

        // If not cached, calculate clusters
        let activeReservations: [Reservation] = Array(Set(
            layoutUI.tables.compactMap { table in
                reservationService.findActiveReservation(for: table, date: selectedDate, time: currentTime)
            }
        ))
        
        // Calculate and cache clusters
        let newClusters = calculateClusters(for: activeReservations)
        layoutUI.clusters = newClusters
        
        // Save clusters in the LRU cache
        store.saveClusters(newClusters, for: selectedDate, category: selectedCategory)
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
    
    private func getCluster(for table: TableModel, activeReservations: [Reservation]) -> [CachedCluster] {
        print("Getting cluster... [getCluster() in LayoutPageView]")

        var clusterTables: [TableModel] = [] // Tables in the cluster
        var visited = Set<Int>()            // Track visited table IDs
        var toVisit = [table]               // Stack for tables to process

        // Filter active reservations to exclude ones that have already ended
        let validReservations = activeReservations.filter { reservation in
            guard let reservationStart = reservation.startDate,
                  let reservationEnd = reservation.endDate else { return false }

            // Adjust end time to exclude overlap at the exact end time
            return currentTime >= reservationStart && currentTime < reservationEnd.addingTimeInterval(-1)
        }

        while let current = toVisit.popLast() {
            guard !visited.contains(current.id) else { continue }
            print("Inserting table in visited... [getCluster() in LayoutPageView]")
            visited.insert(current.id)

            // Check all valid active reservations for the current table
            for activeReservation in validReservations {
                // Ensure the reservation is associated with at least two tables
                guard activeReservation.tables.count >= 2 else { continue }

                // Check if the current table satisfies the conditions
                if current.adjacentCount > 0 &&
                   current.activeReservationAdjacentCount > 0 &&
                   activeReservation.tables.contains(where: { $0.id == current.id }) {
                    print("Inserting table in cluster... [getCluster() in LayoutPageView]")
                    clusterTables.append(current)
                }

                // Find physically adjacent tables that satisfy all conditions
                let physicallyAdjacentTables = layoutUI.tables.filter { neighbor in
                    neighbor.id != current.id &&
                    neighbor.adjacentCount > 0 &&
                    neighbor.activeReservationAdjacentCount > 0 &&
                    activeReservation.tables.contains(where: { $0.id == neighbor.id }) &&
                    !visited.contains(neighbor.id) &&
                    areTablesPhysicallyAdjacent(table1: current, table2: neighbor)
                }

                print("Finding next table to visit... [getCluster() in LayoutPageView]")
                toVisit.append(contentsOf: physicallyAdjacentTables)
            }
        }

        // Create a cluster for each valid active reservation with valid cluster tables
        let clusters = validReservations.compactMap { activeReservation -> CachedCluster? in
            let clusterTablesForReservation = clusterTables.filter { table in
                activeReservation.tables.contains(where: { $0.id == table.id })
            }

            // Ensure the cluster is valid
            guard clusterTablesForReservation.count >= 2 else { return nil }

            return CachedCluster(
                id: UUID(),
                reservationID: activeReservation,
                tableIDs: clusterTablesForReservation.map { $0.id },
                date: activeReservation.date ?? Date(),
                category: activeReservation.category,
                frame: calculateClusterFrame(clusterTablesForReservation)
            )
        }

        return clusters
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
    private func recalculateClustersAsync() {
        guard !resetInProgress else {
            print("Recalculation skipped: reset in progress.")
            return
        }
        
        Task {
            print("Recalculating clusters asynchronously... [recalculateClustersAsync()]")

            let cacheKey = store.keyFor(date: selectedDate, category: selectedCategory)
            
            // Load cached clusters if available
            let cachedClusters = store.loadClusters(for: selectedDate, category: selectedCategory)
            if !cachedClusters.isEmpty {
                print("Using cached clusters for key: \(cacheKey)")
                await MainActor.run {
                    layoutUI.clusters = cachedClusters
                }
                return
            }

            // Calculate clusters if not cached
            let activeReservations: [Reservation] = Array(Set(
                layoutUI.tables.compactMap { table in
                    reservationService.findActiveReservation(for: table, date: selectedDate, time: currentTime)
                }
            ))

            let newClusters = calculateClusters(for: activeReservations)
            await MainActor.run {
                layoutUI.clusters = newClusters
            }

            // Save calculated clusters to cache
            store.saveClusters(newClusters, for: selectedDate, category: selectedCategory)
        }
    }

    /// Forces an update to the cluster cache.
    private func forceUpdateClusterCache() {
        Task {
            print("Force updating cluster cache... [forceUpdateClusterCache()]")
            let activeReservations: [Reservation] = Array(Set(
                layoutUI.tables.compactMap { table in
                    reservationService.findActiveReservation(for: table, date: selectedDate, time: currentTime)
                }
            ))

            let newClusters = calculateClusters(for: activeReservations)
            await MainActor.run {
                layoutUI.clusters = newClusters
            }

            store.saveClusters(newClusters, for: selectedDate, category: selectedCategory)
        }
    }
}
