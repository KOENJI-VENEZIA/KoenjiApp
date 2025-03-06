//
//  LayoutPageView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 01/01/2025.
//
import PencilKit
import ScreenshotSwiftUI
import SwiftUI
import os

struct LayoutPageView: View {
    // MARK: - Dependencies
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "LayoutPageView"
    )
    
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(ClusterManager.self) var clusterManager
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var animationNamespace

    // MARK: - Filters and Properties

    // MARK: - Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var selectedReservation: Reservation?

    // MARK: - States
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?
    private var clustersForTables: [CachedCluster] {
        clusterManager.clusters
    }
    // MARK: - Computed Properties
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var gridWidth: CGFloat { CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(env.tableStore.totalRows) * env.gridData.cellSize }
    private var isLunch: Bool { appState.selectedCategory == .lunch }
    private var backgroundColor: Color { appState.selectedCategory.backgroundColor }
    private var cacheKey: String { env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { appState.selectedCategory.localized.uppercased() }
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            contentWithOnChangeHandlers(geometry: geometry)
        }
    }
    
    private func contentWithOnChangeHandlers(geometry: GeometryProxy) -> some View {
        
        ZoomableScrollView() {
            headerView
            contentView(geometry: geometry)
                .frame(width: gridWidth, height: gridHeight)
                .screenshotMaker { screenshotMaker in
                    if !unitView.isSharing { unitView.cachedScreenshot = screenshotMaker }
                }
                .animation(.easeInOut(duration: 0.5), value: isLoading)
                .transition(.opacity)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: isLoading)
        .onAppear(perform: setupLayout)
        .onChange(of: unitView.selectedIndex) { _, _ in
            Task {
                do {
                    // Fetch reservations asynchronously for the selected date
                    let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                    
                    await MainActor.run {
                        env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
                        reloadLayout(appState.selectedCategory, reservations)
                        env.resCache.startMonitoring(for: appState.selectedDate)
                    }
                } catch {
                    Self.logger.error("Error in async action: \(error.localizedDescription)")
                }
            }
        }
        .onChange(of: unitView.isLayoutReset) { _, reset in
            if reset {
                isLoading = true
                resetCurrentLayout()
                
                Task {
                    do {
                        // Fetch reservations asynchronously
                        let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                        
                        await MainActor.run {
                            env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isLoading = false
                                    unitView.isLayoutReset = false
                                }
                            }
                        }
                    } catch {
                        Self.logger.error("Error fetching reservations during reset: \(error.localizedDescription)")
                        
                        await MainActor.run {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isLoading = false
                                    unitView.isLayoutReset = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: appState.selectedCategory) { _, newCategory in
            debounceAsync {
                // Fetch reservations asynchronously for the selected date with the new category
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
                    reloadLayout(newCategory, reservations)
                }
            }
        }
        .onChange(of: appState.selectedDate) { _, newDate in
            debounceAsync {
                // Fetch reservations asynchronously for the new date
                let reservations = try await env.resCache.fetchReservations(for: newDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: newDate, range: 5, reservations: reservations)
                    reloadLayout(appState.selectedCategory, reservations)
                    env.resCache.startMonitoring(for: newDate)
                }
            }
        }
        .onChange(of: appState.showingEditReservation) {
            debounceAsync {
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservations)
                }
            }
        }
        .onReceive(env.store.$reservations) { new in
            debounceAsync {
                await MainActor.run {
                    env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: new)
                    reloadLayout(appState.selectedCategory, env.store.reservations, force: true)
                }
            }
        }
    }
}

// MARK: - Subviews & Helper Methods
extension LayoutPageView {

    /// The header text displayed at the top of the layout.
    private var headerView: some View {
        Text("\(dayOfWeek), \(fullDateString) - \(categoryString) - \(timeString)")
            .font(.system(size: 28, weight: .bold))
            .padding(.top, 16)
            .padding(.horizontal, 16)
    }

    /// The main content including the grid background, table views, clusters overlay, and canvas.
    private func contentView(geometry: GeometryProxy) -> some View {
        ZStack {
            gridBackgroundView
            tablesAndClustersOverlay
            pencilKitCanvasView
        }
    }

    /// The grid background with a tap gesture to toggle full-screen.
    private var gridBackgroundView: some View {
        env.gridData.gridBackground(selectedCategory: appState.selectedCategory)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .gesture(
                TapGesture(count: 3)
                    .onEnded { withAnimation { toggleFullScreen() } }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12.0)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
    }

    /// The overlay that shows all the tables and, if applicable, clusters.
    private var tablesAndClustersOverlay: some View {
        ZStack {
            // Clusters overlay (if present)
            if !clusterManager.clusters.isEmpty || isLoadingClusters {
                clustersOverlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: isLoading)
            }
            // Individual tables overlay
            ForEach(layoutUI.tables, id: \.id) { table in
                TableView(
                    table: table,
                    clusters: clustersForTables,
                    onTapEmpty: { handleEmptyTableTap(for: $0) },
                    onStatusChange: { statusChanged += 1 },
                    onEditReservation: { selectedReservation = $0 },
                    isLayoutLocked: unitView.isLayoutLocked,
                    animationNamespace: animationNamespace,
                    onTableUpdated: { updatedTable in
                        debounce { onTableUpdated(updatedTable) }
                    },
                    statusChanged: $statusChanged
                )
                .zIndex(1)
            }

           
        }
    }

    /// The clusters overlay views.
    private var clustersOverlay: some View {
        ForEach(clusterManager.clusters) { cluster in
            let clusterTables = layoutUI.tables.filter { cluster.tableIDs.contains($0.id) }
            let overlayFrame = cluster.frame

            return Group {
                ClusterView(
                    cluster: cluster,
                    tables: clusterTables,
                    overlayFrame: overlayFrame,
                    statusChanged: $statusChanged,
                    selectedReservation: $selectedReservation,
                    isLunch: isLunch
                )
                .zIndex(2)
                .allowsHitTesting(false)
                .opacity(unitView.isLayoutLocked ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: unitView.isLayoutLocked)

                ClusterOverlayView(
                    cluster: cluster,
                    selectedCategory: appState.selectedCategory,
                    overlayFrame: overlayFrame,
                    statusChanged: $statusChanged,
                    selectedReservation: $selectedReservation
                )
                .zIndex(3)
                .opacity(unitView.isLayoutLocked ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: unitView.isLayoutLocked)
            }
        }
    }

    /// The canvas for PencilKit drawings.
    private var pencilKitCanvasView: some View {
        PencilKitCanvas(
            layer: .layer2
        )
        .background(Color.clear)
        .zIndex(2)
    }

    /// Toggles the full-screen mode.
    private func toggleFullScreen() {
        appState.isFullScreen.toggle()
        columnVisibility = (columnVisibility == .all) ? .detailOnly : .all
    }

    /// Handles tapping on an empty table to add a reservation.
    private func handleEmptyTableTap(for table: TableModel) {
        unitView.tableForNewReservation = table
        unitView.showingAddReservationSheet = true
    }

    /// Performs initial setup on appear.
    private func setupLayout() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoadingClusters = true
            isLoading = true
        }
        
        // Use Task for async loading
        Task {
            do {
                try await loadCurrentLayout()
                
                // Update UI on the main thread after async operations complete
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoadingClusters = false
                        isLoading = false
                        appState.isContentReady = true
                    }
                }
            } catch {
                Self.logger.error("Error loading layout: \(error.localizedDescription)")
                
                // Handle error and update UI on the main thread
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoadingClusters = false
                        isLoading = false
                        appState.isContentReady = true
                    }
                }
            }
        }
    }

    private func loadCurrentLayout() async throws {
        // Load drawings synchronously (this doesn't need to change)
        let newDrawingModel = env.scribbleService.reloadDrawings(
            for: appState.selectedDate, category: appState.selectedCategory
        )
        
        // Load tables synchronously
        await MainActor.run {
            withAnimation {
                layoutUI.tables = env.layoutServices.loadTables(
                    for: appState.selectedDate, category: appState.selectedCategory
                )
            }
        }
        
        // Fetch reservations asynchronously from Firebase
        let reservationsForDate: [Reservation]
        do {
            reservationsForDate = try await env.resCache.fetchReservations(for: appState.selectedDate)
        } catch {
            Self.logger.error("Failed to fetch reservations: \(error.localizedDescription)")
            throw error
        }
        
        await MainActor.run {
            // Update the store with the fetched reservations
            env.store.reservations = reservationsForDate
            
            // Preload dates and update cache
            env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: reservationsForDate)
            
            // Reload layout with the fetched reservations
            Task {
                await reloadLayout(appState.selectedCategory, reservationsForDate)
            }
            
            // Load clusters and start monitoring
            clusterManager.loadClusters()
            env.resCache.startMonitoring(for: appState.selectedDate)
            
            // Update drawing model
            currentDrawing.layer1 = newDrawingModel.layer1
            currentDrawing.layer2 = newDrawingModel.layer2
            currentDrawing.layer3 = newDrawingModel.layer3
            
            Self.logger.info("Successfully loaded layout with \(reservationsForDate.count) reservations from Firebase")
        }
    }

    private func onTableUpdated(_ updatedTable: TableModel) {
        updateAdjacencyCounts(for: updatedTable)
        updateClustersIfNeeded(for: env.store.reservations, tables: layoutUI.tables)
        env.layoutServices.saveTables(layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)
    }

    private func updateAdjacencyCounts(for updatedTable: TableModel) {
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        var affectedTableIDs = Set<Int>([updatedTable.id])
        let adjacencyResult = env.layoutServices.isTableAdjacent(updatedTable,
                                                                 combinedDateTime: appState.selectedDate,
                                                             activeTables: layoutUI.tables)
        for neighbor in adjacencyResult.adjacentDetails.values {
            affectedTableIDs.insert(neighbor.id)
        }
        affectedTableIDs.formUnion(previousAdjacentTables)

        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = env.layoutServices.isTableAdjacent(table,
                                                                   combinedDateTime: appState.selectedDate,
                                                               activeTables: layoutUI.tables)
                layoutUI.tables[index].adjacentCount = adjacency.adjacentCount
                layoutUI.tables[index].activeReservationAdjacentCount = env.layoutServices.isAdjacentWithSameReservation(
                    for: table,
                    combinedDateTime: appState.selectedDate,
                    activeTables: layoutUI.tables
                ).count
            }
        }

        let layoutKey = env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory)
        env.layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        env.layoutServices.saveToDisk()
    }

    private func updateClustersIfNeeded(for activeReservations: [Reservation], tables: [TableModel]) {
        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations,
            tables: tables,
            combinedDate: appState.selectedDate,
            oldCategory: appState.selectedCategory,
            selectedCategory: appState.selectedCategory,
            cellSize: env.gridData.cellSize
        )
    }

    private func updateDrawingLayersIfNeeded(for selectedCategory: Reservation.ReservationCategory) {
        let currentDrawingModel = env.scribbleService.reloadDrawings(
            for: appState.selectedDate, category: selectedCategory
        )
        if currentDrawing.layer1 != currentDrawingModel.layer1 {
            currentDrawing.layer1 = currentDrawingModel.layer1
        }
        if currentDrawing.layer2 != currentDrawingModel.layer2 {
            currentDrawing.layer2 = currentDrawingModel.layer2
        }
        if currentDrawing.layer3 != currentDrawingModel.layer3 {
            currentDrawing.layer3 = currentDrawingModel.layer3
        }
        Self.logger.debug("Drawing layers updated for category: \(selectedCategory.rawValue)")
    }

    private func reloadLayout(_ selectedCategory: Reservation.ReservationCategory, _ activeReservations: [Reservation], force: Bool = false)  {
        
            updateTablesIfNeeded(for: appState.selectedCategory, force: force)
            updateClustersIfNeeded(for: activeReservations, tables: layoutUI.tables)
            updateDrawingLayersIfNeeded(for: selectedCategory)
        
    }

    private func updateTablesIfNeeded(for selectedCategory: Reservation.ReservationCategory, force: Bool = false) {
        let currentTables = layoutUI.tables
        let newTables = env.layoutServices.loadTables(
            for: appState.selectedDate, category: selectedCategory
        )
        if !force {
            guard currentTables != newTables else { return }
        }
        withAnimation { layoutUI.tables = newTables }
    }

    private func resetCurrentLayout() {
        Self.logger.notice("Resetting current layout...")
        resetInProgress = true
        let key = env.layoutServices.keyFor(date: appState.selectedDate, category: appState.selectedCategory)
        withAnimation {
            if let baseTables = env.layoutServices.cachedLayouts[key] {
                layoutUI.tables = baseTables
            } else {
                layoutUI.tables = []
            }
            clusterManager.clusters = []
        }
        env.clusterServices.saveClusters([], for: appState.selectedDate, category: appState.selectedCategory)
        env.layoutServices.cachedLayouts[key] = nil
        env.layoutServices.saveTables(layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInProgress = false
        }
    }
}

// MARK: - Custom onChange Handlers
extension LayoutPageView {
    /// A simple debounce helper.
    private func debounce(action: @escaping () -> Void, delay: TimeInterval = 0.1) {
        debounceWorkItem?.cancel()
        let newWorkItem = DispatchWorkItem { action() }
        debounceWorkItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    /// A debounce helper for async actions with error handling.
    private func debounceAsync(action: @escaping () async throws -> Void, delay: TimeInterval = 0.1) {
        debounceWorkItem?.cancel()
        let newWorkItem = DispatchWorkItem {
            Task {
                do {
                    try await action()
                } catch {
                    Self.logger.error("Error in debounced async action: \(error.localizedDescription)")
                }
            }
        }
        debounceWorkItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
}

// MARK: - Reservation.ReservationCategory Background Color
extension Reservation.ReservationCategory {
    var backgroundColor: Color {
        switch self {
        case .lunch: return Color.grid_background_lunch
        case .dinner: return Color.grid_background_dinner
        case .noBookingZone: return Color.sidebar_generic
        }
    }
}
