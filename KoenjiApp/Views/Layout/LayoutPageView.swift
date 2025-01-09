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
    
    @State private var clusters: [TableCluster] = []
    
    
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
         offset: Binding<CGSize>) {
        
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
        
        // Initialize LayoutUIManager with date and category
        _layoutUI = StateObject(wrappedValue: LayoutUIManager(date: selectedDate, category: selectedCategory))
    }
    
    var body: some View {
        GeometryReader { parentGeometry in
            let viewportWidth = parentGeometry.size.width
            let viewportHeight = parentGeometry.size.height
            
            let gridWidth = CGFloat(store.totalColumns) * layoutUI.cellSize
            let gridHeight = CGFloat(store.totalRows) * layoutUI.cellSize
            
            Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA")).edgesIgnoringSafeArea([.all])
            LazyView(
                ZoomableScrollView(scale: $scale) {
                    
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
                                }
                            )
                            .environmentObject(store)
                            .environmentObject(reservationService)
                            .environmentObject(gridData)
                            .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
                        }
                        
                        // Reservation clusters overlay
                        // Reservation clusters overlay
                        ForEach(calculateClusters(), id: \.id) { cluster in
                                let overlayFrame = calculateClusterFrame(cluster.tables)

                                ZStack {
                                    RoundedRectangle(cornerRadius: 8.0)
                                        .fill(Color(hex: "#6A798E"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8.0)
                                                .stroke(isLayoutLocked ? Color(hex: "#CB7C1F") : Color(hex: "#3B4A5E"), lineWidth: isLayoutLocked ? 3 : 2)
                                        )
                                        .frame(width: overlayFrame.width, height: overlayFrame.height)
                                        .position(x: overlayFrame.midX, y: overlayFrame.midY)
                                        .zIndex(1)
                                        .allowsHitTesting(false) // Ignore touch input
                                // Reservation label (centered on the cluster)
                                if cluster.tables.first != nil {
                                    let overlayFrame = calculateClusterFrame(cluster.tables)
                                    VStack(spacing: 4) {
                                        Text(cluster.reservation.name)
                                            .bold()
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(cluster.reservation.numberOfPersons) pers.")
                                            .font(.footnote)
                                            .opacity(0.8)
                                        Text(cluster.reservation.phone)
                                            .font(.footnote)
                                            .opacity(0.8)
                                        if let remaining = TimeHelpers.remainingTimeString(endTime: cluster.reservation.endTime, currentTime: currentTime) {
                                            Text("Rimasto: \(remaining)")
                                                .foregroundColor(Color(hex: "#B4231F"))
                                                .font(.footnote)
                                        }
                                        if let duration = TimeHelpers.availableTimeString(endTime: cluster.reservation.endTime, startTime: cluster.reservation.startTime) {
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
                    .drawingGroup()
                    .frame(width: gridWidth, height: gridHeight)
                    .compositingGroup()
                    .background(Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA")))
                    .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
                }
                .onAppear {
                    loadCurrentLayout()
                }
                .onChange(of: isLayoutReset) { reset in
                    if reset {
                        resetCurrentLayout()
                    }
                }
                .onChange(of: selectedCategory) { newCategory in
                    // Load tables for the new category and date
                    layoutUI.tables = store.loadTables(for: selectedDate, category: newCategory)
                    
                }
                .alert(isPresented: $layoutUI.showAlert) {
                    Alert(
                        title: Text("Posizionamento non valido"),
                        message: Text(layoutUI.alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .background(Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA")))
                .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
            )
        }
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
    }
    
    private func resetCurrentLayout() {
            // Reset tables and update layoutUI.tables
            let key = store.keyFor(date: selectedDate, category: selectedCategory)
            if let baseTables = store.cachedLayouts[key] {
                layoutUI.tables = baseTables
                print("Reset layout for \(key) and updated layoutUI.tables.")
            }
    }
    

    private func calculateClusters() -> [TableCluster] {
        var clusters: [TableCluster] = []
        var visitedTables = Set<Int>()
        
        for table in layoutUI.tables {
            guard !visitedTables.contains(table.id),
                  let reservation = reservationService.findActiveReservation(for: table, date: selectedDate, time: currentTime) else {
                continue
            }
            
            // Fetch the cluster for this table
            let clusterTables = getCluster(for: table)
            if clusterTables.count > 1 {
                clusters.append(TableCluster(reservation: reservation, tables: clusterTables))
            }
            
            // Mark tables as visited
            visitedTables.formUnion(clusterTables.map { $0.id })
        }
        
        return clusters
    }
    
    private func calculateClusterFrame(_ tables: [TableModel]) -> CGRect {
        guard let firstTable = tables.first else { return .zero }
        
        // Calculate the min and max rows/columns of the cluster
        let minX = tables.map { $0.column }.min() ?? firstTable.column
        let maxX = tables.map { $0.column + $0.width }.max() ?? firstTable.column + firstTable.width
        let minY = tables.map { $0.row }.min() ?? firstTable.row
        let maxY = tables.map { $0.row + $0.height }.max() ?? firstTable.row + firstTable.height
        
        // Convert grid coordinates to pixel coordinates
        let originX = CGFloat(minX) * layoutUI.cellSize
        let originY = CGFloat(minY) * layoutUI.cellSize
        let width = CGFloat(maxX - minX) * layoutUI.cellSize
        let height = CGFloat(maxY - minY) * layoutUI.cellSize
        print("Cluster Bounds - minX: \(minX), maxX: \(maxX), minY: \(minY), maxY: \(maxY)")
        
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    private func getCluster(for table: TableModel) -> [TableModel] {
        guard let activeReservation = reservationService.findActiveReservation(
            for: table,
            date: selectedDate,
            time: currentTime
        ) else {
            return [] // No cluster for tables without an active reservation
        }

        var cluster: [TableModel] = []
        var visited = Set<Int>()
        var toVisit = [table]

        while let current = toVisit.popLast() {
            guard !visited.contains(current.id) else { continue }
            visited.insert(current.id)
            
            // Ensure the current table satisfies all conditions
            if current.activeReservationAdjacentCount > 0 &&
                reservationService.findActiveReservation(for: current, date: selectedDate, time: currentTime) == activeReservation &&
                current.adjacentCount > 0 {
                cluster.append(current)
            } else {
                continue // Skip if the table does not satisfy the conditions
            }

            // Find adjacent tables that also satisfy all conditions
            let adjacentTables = layoutUI.tables.filter { neighbor in
                neighbor.id != current.id &&
                neighbor.activeReservationAdjacentCount > 0 &&
                reservationService.findActiveReservation(for: neighbor, date: selectedDate, time: currentTime) == activeReservation &&
                neighbor.adjacentCount > 0 &&
                !visited.contains(neighbor.id)
            }

            // Add valid adjacent tables to the visit list
            toVisit.append(contentsOf: adjacentTables)
        }

        return cluster
    }
    
    struct TableCluster {
        let id: UUID = UUID() // Unique ID for each cluster
        let reservation: Reservation
        let tables: [TableModel]
    }
}

  
