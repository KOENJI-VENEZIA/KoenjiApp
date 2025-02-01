//
//  LayoutPageView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 01/01/2025.
//
import PencilKit
import ScreenshotSwiftUI
import SwiftUI

struct LayoutPageView: View {
    // MARK: - Dependencies
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var scribbleService: ScribbleService
    @EnvironmentObject var currentDrawing: DrawingModel
    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(ClusterManager.self) var clusterManager

    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Namespace private var animationNamespace

    // MARK: - Filters and Properties
    var selectedDate: Date
    var selectedCategory: Reservation.ReservationCategory

    // MARK: - Bindings
    @Binding var selectedIndex: Int
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var scale: CGFloat
    @Binding var selectedReservation: Reservation?
    @Binding var changedReservation: Reservation?
    @Binding var showInspector: Bool
    @Binding var showingEditReservation: Bool
    @Binding var showingAddReservationSheet: Bool
    @Binding var tableForNewReservation: TableModel?
    @Binding var isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    @Binding var isScribbleModeEnabled: Bool
    @Binding var toolPickerShows: Bool
    @Binding var isSharing: Bool
    @Binding var isPresented: Bool
    @Binding var cachedScreenshot: ScreenshotMaker?

    // MARK: - States
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var statusChanged: Int = 0
    @State private var debounceWorkItem: DispatchWorkItem?

    // MARK: - Computed Properties
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var gridWidth: CGFloat { CGFloat(store.totalColumns) * gridData.cellSize }
    private var gridHeight: CGFloat { CGFloat(store.totalRows) * gridData.cellSize }
    private var isLunch: Bool { selectedCategory == .lunch }
    private var backgroundColor: Color { selectedCategory.backgroundColor }
    private var cacheKey: String { layoutServices.keyFor(date: appState.selectedDate, category: selectedCategory) }
    private var dayOfWeek: String { DateHelper.dayOfWeek(for: appState.selectedDate) }
    private var fullDateString: String { DateHelper.formatFullDate(appState.selectedDate) }
    private var categoryString: String { selectedCategory.localized.uppercased() }
    private var timeString: String { DateHelper.formatTime(appState.selectedDate) }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            contentWithOnChangeHandlers(geometry: geometry)
        }
    }
    
    private func contentWithOnChangeHandlers(geometry: GeometryProxy) -> some View {
        
        ZoomableScrollView(scale: $scale) {
            headerView
            contentView(geometry: geometry)
                .frame(width: gridWidth, height: gridHeight)
                .screenshotMaker { screenshotMaker in
                    if !isSharing { cachedScreenshot = screenshotMaker }
                }
                .animation(.easeInOut(duration: 0.5), value: isLoading)
                .transition(.opacity)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: isLoading)
        .onAppear(perform: setupLayout)
        .onChange(of: selectedIndex) {
            debounce {
                resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: store.reservations)
                updateCachedReservation(appState.selectedDate)
                reloadLayout(appState.selectedCategory, resCache.activeReservations)
                resCache.startMonitoring(for: appState.selectedDate)
            }
        }
        .onChange(of: isLayoutReset) { _, reset in
            if reset {
                isLoading = true
                resetCurrentLayout()
                updateCachedReservation(appState.selectedDate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoading = false
                        isLayoutReset = false
                    }
                }
            }
        }
        .onChange(of: selectedReservation) {
            updateCachedReservation(appState.selectedDate)
        }
        .onChange(of: appState.selectedCategory) { _, newCategory in
            debounce {
                updateCachedReservation(appState.selectedDate)
                reloadLayout(newCategory, resCache.activeReservations)
            }
        }
        .onChange(of: appState.selectedDate) { _, newDate in
            debounce {
                resCache.preloadDates(around: newDate, range: 5, reservations: store.reservations)
                updateCachedReservation(newDate)
                reloadLayout(appState.selectedCategory, resCache.activeReservations)
                resCache.startMonitoring(for: newDate)
            }
        }
        .onChange(of: showingEditReservation) {
            debounce { updateCachedReservation(appState.selectedDate) }
        }
        .onChange(of: changedReservation) {
            debounce {
                print("Detected cancelled Reservation [LayoutPageView]")
                updateCachedReservation(appState.selectedDate)
                reloadLayout(appState.selectedCategory, resCache.activeReservations)
            }
        }
        .onChange(of: statusChanged) {
            debounce { updateCachedReservation(appState.selectedDate) }
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
        gridData.gridBackground(selectedCategory: selectedCategory)
            .background(backgroundColor.opacity(0.2))
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
            // Individual tables overlay
            ForEach(layoutUI.tables, id: \.id) { table in
                TableView(
                    selectedIndex: $selectedIndex,
                    table: table,
                    selectedDate: appState.selectedDate,
                    onTapEmpty: { handleEmptyTableTap(for: $0) },
                    onStatusChange: { statusChanged += 1 },
                    onEditReservation: { selectedReservation = $0 },
                    isLayoutLocked: isLayoutLocked,
                    animationNamespace: animationNamespace,
                    onTableUpdated: { updatedTable in
                        debounce { onTableUpdated(updatedTable) }
                    },
                    changedReservation: $changedReservation,
                    isEditing: $showingEditReservation,
                    isLayoutReset: $isLayoutReset,
                    showInspector: $showInspector,
                    statusChanged: $statusChanged
                )
                .zIndex(1)
            }

            // Clusters overlay (if present)
            if !clusterManager.clusters.isEmpty || isLoadingClusters {
                clustersOverlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: isLoading)
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
                    isLayoutLocked: $isLayoutLocked,
                    statusChanged: $statusChanged,
                    showInspector: $showInspector,
                    selectedReservation: $selectedReservation,
                    isLunch: isLunch
                )
                .zIndex(2)
                .allowsHitTesting(false)
                .opacity(isLayoutLocked ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isLayoutLocked)
                .onAppear { updateTableVisibility(for: clusterTables) }
                .onChange(of: isLayoutLocked) { updateTableVisibility(for: clusterTables) }

                ClusterOverlayView(
                    cluster: cluster,
                    selectedCategory: selectedCategory,
                    overlayFrame: overlayFrame,
                    statusChanged: $statusChanged,
                    showInspector: $showInspector,
                    selectedReservation: $selectedReservation
                )
                .zIndex(3)
                .opacity(isLayoutLocked ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isLayoutLocked)
            }
        }
    }

    /// The canvas for PencilKit drawings.
    private var pencilKitCanvasView: some View {
        PencilKitCanvas(
            toolPickerShows: $toolPickerShows,
            layer: .layer2,
            gridWidth: gridWidth,
            gridHeight: gridHeight,
            canvasSize: CGSize(width: gridWidth, height: gridHeight),
            isEditable: isScribbleModeEnabled
        )
        .background(Color.clear)
        .zIndex(2)
    }

    /// Updates table visibility based on the layout lock.
    private func updateTableVisibility(for tables: [TableModel]) {
        for table in tables {
            if !isLayoutLocked {
                layoutUI.setTableVisible(table)
            } else {
                layoutUI.setTableInvisible(table)
            }
        }
    }

    /// Toggles the full-screen mode.
    private func toggleFullScreen() {
        appState.isFullScreen.toggle()
        columnVisibility = (columnVisibility == .all) ? .detailOnly : .all
    }

    /// Handles tapping on an empty table to add a reservation.
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }

    /// Performs initial setup on appear.
    private func setupLayout() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoadingClusters = true
            isLoading = true
        }
        DispatchQueue.main.async {
            loadCurrentLayout()
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoadingClusters = false
                isLoading = false
                appState.isContentReady = true
            }
        }
    }
}

// MARK: - UI Update & Helper Methods
extension LayoutPageView {

    private func loadCurrentLayout() {
        let newDrawingModel = scribbleService.reloadDrawings(
            for: appState.selectedDate, category: selectedCategory
        )
        withAnimation {
            layoutUI.tables = layoutServices.loadTables(
                for: appState.selectedDate, category: selectedCategory
            )
        }
        resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: store.reservations)
        updateCachedReservation(appState.selectedDate)
        resCache.startMonitoring(for: appState.selectedDate)
        currentDrawing.layer1 = newDrawingModel.layer1
        currentDrawing.layer2 = newDrawingModel.layer2
        currentDrawing.layer3 = newDrawingModel.layer3
    }

    private func updateCachedReservation(_ date: Date) {
        resCache.activeReservations = resCache.reservations(for: date)
            .filter { $0.status != .canceled || $0.reservationType != .waitingList }
    }

    private func onTableUpdated(_ updatedTable: TableModel) {
        updateAdjacencyCounts(for: updatedTable)
        updateClustersIfNeeded(for: resCache.activeReservations, tables: layoutUI.tables)
        layoutServices.saveTables(layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)
    }

    private func updateAdjacencyCounts(for updatedTable: TableModel) {
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }
        var affectedTableIDs = Set<Int>([updatedTable.id])
        let adjacencyResult = layoutServices.isTableAdjacent(updatedTable,
                                                             combinedDateTime: appState.selectedDate,
                                                             activeTables: layoutUI.tables)
        for neighbor in adjacencyResult.adjacentDetails.values {
            affectedTableIDs.insert(neighbor.id)
        }
        affectedTableIDs.formUnion(previousAdjacentTables)

        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = layoutServices.isTableAdjacent(table,
                                                               combinedDateTime: appState.selectedDate,
                                                               activeTables: layoutUI.tables)
                layoutUI.tables[index].adjacentCount = adjacency.adjacentCount
                layoutUI.tables[index].activeReservationAdjacentCount = layoutServices.isAdjacentWithSameReservation(
                    for: table,
                    combinedDateTime: appState.selectedDate,
                    activeTables: layoutUI.tables
                ).count
            }
        }

        let layoutKey = layoutServices.keyFor(date: appState.selectedDate, category: selectedCategory)
        layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        layoutServices.saveToDisk()
    }

    private func updateClustersIfNeeded(for activeReservations: [Reservation], tables: [TableModel]) {
        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations,
            tables: tables,
            combinedDate: appState.selectedDate,
            oldCategory: selectedCategory,
            selectedCategory: selectedCategory,
            cellSize: gridData.cellSize
        )
    }

    private func updateDrawingLayersIfNeeded(for selectedCategory: Reservation.ReservationCategory) {
        let currentDrawingModel = scribbleService.reloadDrawings(
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
        print("Drawing layers updated for category: \(selectedCategory).")
    }

    private func reloadLayout(_ selectedCategory: Reservation.ReservationCategory, _ activeReservations: [Reservation]) {
        Task {
            DispatchQueue.main.async {
                updateCachedReservation(appState.selectedDate)
                updateTablesIfNeeded(for: appState.selectedCategory)
                updateClustersIfNeeded(for: activeReservations, tables: layoutUI.tables)
                updateDrawingLayersIfNeeded(for: selectedCategory)
            }
        }
    }

    private func updateTablesIfNeeded(for selectedCategory: Reservation.ReservationCategory) {
        let currentTables = layoutUI.tables
        let newTables = layoutServices.loadTables(
            for: appState.selectedDate, category: selectedCategory
        )
        guard currentTables != newTables else { return }
        withAnimation { layoutUI.tables = newTables }
    }

    private func resetCurrentLayout() {
        print("Resetting layout... [resetCurrentLayout()]")
        resetInProgress = true
        let key = layoutServices.keyFor(date: appState.selectedDate, category: selectedCategory)
        withAnimation {
            if let baseTables = layoutServices.cachedLayouts[key] {
                layoutUI.tables = baseTables
            } else {
                layoutUI.tables = []
            }
            clusterManager.clusters = []
        }
        clusterServices.saveClusters([], for: appState.selectedDate, category: selectedCategory)
        layoutServices.cachedLayouts[key] = nil
        layoutServices.saveTables(layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)
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
