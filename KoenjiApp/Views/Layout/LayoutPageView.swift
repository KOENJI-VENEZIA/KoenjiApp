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
    @Environment(ClusterManager.self) var clusterManager

    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Managers
    @StateObject private var layoutUI: LayoutUIManager
    @StateObject private var zoomableState: ZoomableScrollViewState

    @Namespace private var animationNamespace

    // MARK: - Filters and Properties
    var selectedDate: Date
    var selectedCategory: Reservation.ReservationCategory

    // MARK: - Bindings
    @Binding var selectedIndex: Int
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var scale: CGFloat
    @Binding var isManuallyOverridden: Bool
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
    @State private var cachedActiveReservations: [Reservation] = []
    @State private var lastFetchedDate: Date?
    @State private var lastFetchedTime: Date?
    @State private var lastFetchedCount: Int = 0
    @State private var pendingClusterUpdate: DispatchWorkItem?
    @State private var statusChanged: Int = 0
    @State private var clusterOverlayUpdateID = UUID()

    @State private var frame: CGRect = .zero
    @State private var catchedImage: UIImage?

    @State private var debounceWorkItem: DispatchWorkItem?

    // MARK: - Computed Properties
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var gridWidth: CGFloat {
        CGFloat(store.totalColumns) * gridData.cellSize
    }

    private var gridHeight: CGFloat {
        CGFloat(store.totalRows) * gridData.cellSize
    }

    private var isLunch: Bool {
        selectedCategory == .lunch
    }

    private var backgroundColor: Color {
        selectedCategory.backgroundColor
    }

    private var cacheKey: String {
        layoutServices.keyFor(date: appState.selectedDate, category: selectedCategory)
    }

    // MARK: - Initializer
    init(
        selectedIndex: Binding<Int>,
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        scale: Binding<CGFloat>,
        selectedDate: Date,
        selectedCategory: Reservation.ReservationCategory,
        isManuallyOverridden: Binding<Bool>,
        selectedReservation: Binding<Reservation?>,
        changedReservation: Binding<Reservation?>,
        showInspector: Binding<Bool>,
        showingEditReservation: Binding<Bool>,
        showingAddReservationSheet: Binding<Bool>,
        tableForNewReservation: Binding<TableModel?>,
        isLayoutLocked: Binding<Bool>,
        isLayoutReset: Binding<Bool>,
        isScribbleModeEnabled: Binding<Bool>,
        toolPickerShows: Binding<Bool>,
        isSharing: Binding<Bool>,
        isPresented: Binding<Bool>,
        cachedScreenshot: Binding<ScreenshotMaker?>
    ) {
        // Assign parameters to properties
        self._selectedIndex = selectedIndex
        self._columnVisibility = columnVisibility
        self._scale = scale
        self.selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._isManuallyOverridden = isManuallyOverridden
        self._selectedReservation = selectedReservation
        self._changedReservation = changedReservation
        self._showInspector = showInspector
        self._showingEditReservation = showingEditReservation
        self._showingAddReservationSheet = showingAddReservationSheet
        self._tableForNewReservation = tableForNewReservation
        self._isLayoutLocked = isLayoutLocked
        self._isLayoutReset = isLayoutReset
        self._isScribbleModeEnabled = isScribbleModeEnabled
        self._toolPickerShows = toolPickerShows
        self._isSharing = isSharing
        self._isPresented = isPresented
        self._cachedScreenshot = cachedScreenshot

        // Initialize StateObjects
        _layoutUI = StateObject(
            wrappedValue: LayoutUIManager(date: selectedDate, category: selectedCategory))

        _zoomableState = StateObject(wrappedValue: ZoomableScrollViewState())
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            
            ZoomableScrollView(
                state: zoomableState,
                category: .constant(selectedCategory),
                scale: $scale
            ) {
                Text(
                    "\(DateHelper.dayOfWeek(for: appState.selectedDate)), \(DateHelper.formatFullDate(appState.selectedDate)) - \(selectedCategory.localized.uppercased()) - \(DateHelper.formatTime(appState.selectedDate))"
                )
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 16)
                .padding(.horizontal, 16)
//                .transition(.opacity)
//                .opacity(!isLoading ? 1 : 0)
//                .animation(.easeInOut(duration: 0.5), value: !isLoading)
                
                ZStack {
                    
                    gridData.gridBackground(selectedCategory: selectedCategory)
                        .background(backgroundColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .gesture(
                            TapGesture(count: 3)  // Double-tap to exit full-screen
                                .onEnded {
                                    withAnimation {
                                        appState.isFullScreen.toggle()
                                        columnVisibility =
                                        columnVisibility == .all ? .detailOnly : .all
                                    }
                                }
                        )
//                        .transition(.opacity)
//                        .opacity(!isLoading ? 1 : 0)
//                        .animation(.easeInOut(duration: 0.5), value: isLoading)
                    
                    RoundedRectangle(cornerRadius: 12.0)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
//                        .transition(.opacity)
//                        .opacity(!isLoading ? 1 : 1)
//                        .animation(.easeInOut(duration: 0.5), value: isLoading)
                    
//                    ZStack {
//                        gridData.gridBackground(selectedCategory: selectedCategory)
//                            .background(backgroundColor.opacity(0.2))
//                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                            .transition(.opacity)
//                            .opacity(isLoading ? 0.3 : 0)
//                            .animation(.easeInOut(duration: 0.5), value: isLoading)
//                        
//                        RoundedRectangle(cornerRadius: 12.0)
//                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
//                            .transition(.opacity)
//                            .opacity(isLoading ? 0.3 : 0)
//                            .animation(.easeInOut(duration: 0.5), value: isLoading)
//                        
//                        loadingView
//                            .opacity(isLoading ? 0.3 : 0)
//                        
//                        Text("Caricamento...")
//                            .foregroundColor(Color.gray.opacity(0.8))
//                            .font(.headline)
//                            .padding(20)
//                            .background(Color.white.opacity(0.3))
//                            .cornerRadius(12)
//                            .frame(width: gridWidth / 2, height: gridHeight / 2)
//                            .position(
//                                x: gridWidth / 2, y: gridHeight / 2 - gridData.cellSize)
//                        
//                    }
//                    .transition(.opacity)
//                    .opacity(isLoading ? 1 : 0)
//                    .animation(.easeInOut(duration: 0.5), value: isLoading)
                    
                    ZStack {
                        // Individual tables
                        
                        ForEach(layoutUI.tables, id: \.id) { table in
                            TableView(
                                layoutUI: layoutUI,
                                selectedIndex: $selectedIndex,
                                table: table,
                                selectedDate: appState.selectedDate,
                                selectedCategory: selectedCategory,
                                onTapEmpty: { table in
                                    handleEmptyTableTap(for: table)
                                },
                                onStatusChange: {
                                    statusChanged += 1
                                },
                                onEditReservation: { reservation in
                                    selectedReservation = reservation
                                },
                                isLayoutLocked: isLayoutLocked,
                                animationNamespace: animationNamespace,
                                onTableUpdated: { updatedTable in
                                    debounce {
                                        onTableUpdated(updatedTable)
                                        updateClustersIfNeeded(
                                            for: resCache.activeReservations,
                                            tables: layoutUI.tables)
                                        layoutServices.saveTables(
                                            layoutUI.tables, for: appState.selectedDate,
                                            category: appState.selectedCategory)
                                    }
                                },
                                changedReservation: $changedReservation,
                                isEditing: $showingEditReservation,
                                isLayoutReset: $isLayoutReset,
                                showInspector: $showInspector,
                                statusChanged: $statusChanged
                            )
                            .onAppear {
                                print("DEBUG: loading \(layoutUI.tables.count) tables...")
                            }
                            .zIndex(1)
                            .environment(clusterManager)
                            .environmentObject(store)
                            .environmentObject(appState)
                            .environmentObject(resCache)
                            .environmentObject(tableStore)
                            .environmentObject(reservationService)
                            .environmentObject(clusterServices)
                            .environmentObject(layoutServices)
                            .environmentObject(gridData)
//                            .opacity(!isLoading ? 1 : 1)
//                            .transition(.opacity)
//                            .animation(.easeInOut(duration: 0.5), value: !isLoading)
                            
                        }
                        
                        if clusterManager.clusters.isEmpty && !isLoadingClusters {
                        } else {
                            // Reservation clusters overlay
                            ForEach(clusterManager.clusters) { cluster in
                                
                                let clusterTables = layoutUI.tables.filter {
                                    cluster.tableIDs.contains($0.id)
                                }
                                let overlayFrame = cluster.frame
                                
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
                                //                                .frame(width: overlayFrame.width, height: overlayFrame.height)
                                .zIndex(2)
                                .allowsHitTesting(false)
                                .opacity(isLayoutLocked ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: isLayoutLocked)
                                .environmentObject(resCache)
                                .environmentObject(appState)
                                .environmentObject(reservationService)
                                .transition(.opacity)
                                .onAppear {
                                    if !isLayoutLocked {
                                        for table in clusterTables {
                                            layoutUI.setTableVisible(table)
                                        }
                                    } else {
                                        for table in clusterTables {
                                            layoutUI.setTableInvisible(table)
                                        }
                                    }
                                }
                                .onChange(of: isLayoutLocked) {
                                    if !isLayoutLocked {
                                        for table in clusterTables {
                                            layoutUI.setTableVisible(table)
                                        }
                                    } else {
                                        for table in clusterTables {
                                            layoutUI.setTableInvisible(table)
                                        }
                                    }
                                }
                                
                                ClusterOverlayView(
                                    cluster: cluster,
                                    selectedCategory: selectedCategory,
                                    overlayFrame: overlayFrame,
                                    statusChanged: $statusChanged,
                                    showInspector: $showInspector,
                                    selectedReservation: $selectedReservation
                                )
                                .environmentObject(resCache)
                                .environmentObject(appState)
                                .environmentObject(reservationService)
                                .opacity(isLayoutLocked ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: isLayoutLocked)
                                .zIndex(3)
                            }
                            .transition(.opacity)
                            .opacity(!isLoading ? 1 : 1)
                            .animation(.easeInOut(duration: 0.5), value: !isLoading)
                        }
                        
                    }
                    
                    PencilKitCanvas(
                        zoomableState: zoomableState,
                        toolPickerShows: $toolPickerShows,
                        layer: .layer2,
                        gridWidth: gridWidth,
                        gridHeight: gridHeight,
                        canvasSize: CGSize(width: gridWidth, height: gridHeight),
                        isEditable: isScribbleModeEnabled
                    )
                    .environmentObject(currentDrawing)
                    .background(Color.clear)
                    
                    .zIndex(2)
                }
                .frame(width: gridWidth, height: gridHeight)
                .screenshotMaker { screenshotMaker in
                    if !isSharing {
                        cachedScreenshot = screenshotMaker
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: isLoading)
                .transition(.opacity)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: isLoading)
        }
        .onAppear {
            Task {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoadingClusters = true
                    isLoading = true
                }
                
                DispatchQueue.main.async {
                    
                    loadCurrentLayout()
                    debounce {
                        resCache.preloadDates(
                            around: appState.selectedDate, range: 5,
                            reservations: store.reservations)
                        updateCachedReservation(appState.selectedDate)
                        reloadLayout(appState.selectedCategory, resCache.activeReservations)
                        resCache.startMonitoring(for: appState.selectedDate)
                    }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLoadingClusters = false
                        isLoading = false
                        appState.isContentReady = true
                    }
                }
            }
        }
        .onChange(of: selectedIndex) {
            debounce {
                resCache.preloadDates(
                    around: appState.selectedDate, range: 5, reservations: store.reservations)
                updateCachedReservation(appState.selectedDate)
                reloadLayout(appState.selectedCategory, resCache.activeReservations)
                resCache.startMonitoring(for: appState.selectedDate)
            }
        }
        .onChange(of: isLayoutReset) { old, reset in
            if reset {
                isLoading = true
                resetCurrentLayout()
                updateCachedReservation(appState.selectedDate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        
                        isLoading = false
                        isLayoutReset = false  // Clear reset state
                    }
                }
            }
        }
        .onChange(of: selectedReservation) {
            updateCachedReservation(appState.selectedDate)
        }
        .onChange(of: appState.selectedCategory) { old, newCategory in
            // Load tables for the new category and date
            debounce {
                updateCachedReservation(appState.selectedDate)
                reloadLayout(newCategory, resCache.activeReservations)
                withAnimation {
                    layoutUI.tables = layoutServices.loadTables(
                        for: appState.selectedDate, category: newCategory)
                }
            }
                
            }
            .onChange(of: appState.selectedDate) { old, newDate in
                debounce {
                    resCache.preloadDates(around: newDate, range: 5, reservations: store.reservations)
                    updateCachedReservation(newDate)
                    reloadLayout(appState.selectedCategory, resCache.activeReservations)
                    resCache.startMonitoring(for: newDate)
                }
                
            }
            .onChange(of: showingEditReservation) { old, newValue in
                //            print("Triggered onChange of showingEditReservation")
                debounce {
                    updateCachedReservation(appState.selectedDate)
                    //                reloadLayout(appState.selectedCategory, resCache.activeReservations)
                }
            }
            //        .onChange(of: store.reservations) { oldValue, newValue in
            //            print("reservations changed from \(oldValue.count) to \(newValue.count)")
            //            // Force the active-reservations fetch (since store.reservations changed)
            //            debounce {
            //                updateCachedReservation(appState.selectedDate)
            ////                reloadLayout(appState.selectedCategory, resCache.activeReservations)
            //            }
            //        }
            .onChange(of: changedReservation) {
                debounce {
                    print("Detected cancelled Reservation [LayoutPageView]")
                    updateCachedReservation(appState.selectedDate)
                    reloadLayout(appState.selectedCategory, resCache.activeReservations)
                    
                }
            }
            .onChange(of: statusChanged) {
                debounce {
                    updateCachedReservation(appState.selectedDate)
                    //                updateClustersIfNeeded(for: resCache.activeReservations, tables: layoutUI.tables)
                    
                }
            }
        }
    

    // MARK: - Helper Views

    private func updateCachedReservation(_ date: Date) {
        resCache.activeReservations = resCache.reservations(for: date).filter {
            reservation in
            reservation.status != .canceled || reservation.reservationType != .waitingList
        }
    }

    private func debounce(action: @escaping () -> Void, delay: TimeInterval = 0.1) {
        debounceWorkItem?.cancel()
        let newWorkItem = DispatchWorkItem {
            action()
        }
        debounceWorkItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }

    private var loadingView: some View {

        withAnimation {
            ForEach(tableStore.baseTables, id: \.id) { table in
                let tableWidth = CGFloat(table.width) * gridData.cellSize
                let tableHeight = CGFloat(table.height) * gridData.cellSize
                let xPos = CGFloat(table.column) * gridData.cellSize + tableWidth / 2
                let yPos = CGFloat(table.row) * gridData.cellSize + tableHeight / 2

                RoundedRectangle(cornerRadius: 12.0)
                    .fill(Color.gray.opacity(0.3))  // Placeholder color
                    .frame(width: tableWidth, height: tableHeight)
                    .position(x: xPos, y: yPos)
                RoundedRectangle(cornerRadius: 12.0)
                    .stroke(Color.gray.opacity(0.7), lineWidth: 3)  // Placeholder color
                    .frame(width: tableWidth, height: tableHeight)
                    .position(x: xPos, y: yPos)
            }
        }

    }

    // MARK: - Gesture Methods

    // Handle tapping an empty table to add a reservation
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }

    // MARK: - UI Update Methods

    private func reloadLayout(
        _ selectedCategory: Reservation.ReservationCategory,
        _ activeReservations: [Reservation]
    ) {
        Task {
            DispatchQueue.main.async {
                // Update only the necessary parts of the layout
                updateCachedReservation(appState.selectedDate)
                updateTablesIfNeeded(for: appState.selectedCategory)
                updateClustersIfNeeded(for: activeReservations, tables: layoutUI.tables)
                updateDrawingLayersIfNeeded(for: selectedCategory)
            }
        }
    }

    private func updateTablesIfNeeded(for selectedCategory: Reservation.ReservationCategory) {
        // Check if a reload is required
        let currentTables = layoutUI.tables
        let newTables = layoutServices.loadTables(
            for: appState.selectedDate, category: selectedCategory)

        guard currentTables != newTables else {
            return
        }

        withAnimation {
            layoutUI.tables = newTables
        }
    }

    private func updateClustersIfNeeded(for activeReservations: [Reservation], tables: [TableModel])
    {

        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations,
            tables: tables,
            combinedDate: appState.selectedDate,
            oldCategory: selectedCategory,
            selectedCategory: selectedCategory,
            cellSize: gridData.cellSize
        )

    }

    private func updateDrawingLayersIfNeeded(for selectedCategory: Reservation.ReservationCategory)
    {
        let currentDrawingModel = scribbleService.reloadDrawings(
            for: appState.selectedDate, category: selectedCategory)

        // Only update the layers if they are different
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

    private func onTableUpdated(_ updatedTable: TableModel) {

        updateAdjacencyCountsForLayout(updatedTable)
        //        layoutUI.tables = layoutServices.loadTables(for: combinedDate, category: appState.selectedCategory)
        //        let newSignature = layoutServices.computeLayoutSignature(tables: layoutUI.tables)
        //        print("New layout signature: \(newSignature)")
        //        print("Last layout signature: \(clusterManager.lastLayoutSignature)")
        //
        //        if newSignature != clusterManager.lastLayoutSignature {
        //            // We have a real adjacency change, so we might need to recalc clusters
        //            clusterManager.lastLayoutSignature = newSignature
        //            statusChanged += 1  // or some equivalent trigger
        //        }
    }

    private func updateLayoutResetState() {
        isLayoutReset = (layoutUI.tables == tableStore.baseTables)
    }

    private func loadCurrentLayout() {

        let newDrawingModel = scribbleService.reloadDrawings(
            for: appState.selectedDate, category: appState.selectedCategory)

        if !layoutUI.isConfigured {
            layoutUI.configure(
                store: store, reservationService: reservationService,
                layoutServices: layoutServices)
            withAnimation {
                layoutUI.tables = layoutServices.loadTables(
                    for: appState.selectedDate, category: appState.selectedCategory)
            }
        }

        //        withAnimation {
        //            clusterManager.clusters = clusterServices.loadClusters(
        //                for: appState.selectedDate, category: appState.selectedCategory)
        //        }

        //        resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: store.reservations)
        //        updateCachedReservation(appState.selectedDate)
        //        reloadLayout(appState.selectedCategory, resCache.activeReservations)
        //        resCache.startMonitoring(for: appState.selectedDate)

        currentDrawing.layer1 = newDrawingModel.layer1
        currentDrawing.layer2 = newDrawingModel.layer2
        currentDrawing.layer3 = newDrawingModel.layer3

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
        layoutServices.saveTables(
            layoutUI.tables, for: appState.selectedDate, category: appState.selectedCategory)

        // Ensure flag is cleared after reset completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInProgress = false
        }
    }

    // MARK: - Cache and UI Update Methods

    private func updateAdjacencyCountsForLayout(_ updatedTable: TableModel) {
        // Identify tables with adjacentCount > 0 before the move
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }

        // Identify affected tables (dragged table + neighbors)
        var affectedTableIDs = Set<Int>()
        affectedTableIDs.insert(updatedTable.id)

        let adjacencyResult = layoutServices.isTableAdjacent(
            updatedTable, combinedDateTime: appState.selectedDate, activeTables: layoutUI.tables)
        for neighbor in adjacencyResult.adjacentDetails.values {
            affectedTableIDs.insert(neighbor.id)
        }

        // Include all previously adjacent tables in the affected list
        affectedTableIDs.formUnion(previousAdjacentTables)

        // Recalculate adjacency counts for affected tables only
        for tableID in affectedTableIDs {
            if let index = layoutUI.tables.firstIndex(where: { $0.id == tableID }) {
                let table = layoutUI.tables[index]
                let adjacency = layoutServices.isTableAdjacent(
                    table, combinedDateTime: appState.selectedDate, activeTables: layoutUI.tables)
                layoutUI.tables[index].adjacentCount = adjacency.adjacentCount

                layoutUI.tables[index].activeReservationAdjacentCount =
                    layoutServices.isAdjacentWithSameReservation(
                        for: table,
                        combinedDateTime: appState.selectedDate,
                        activeTables: layoutUI.tables
                    ).count
            }
        }

        // Update cached layout and save
        let layoutKey = layoutServices.keyFor(
            date: appState.selectedDate, category: selectedCategory)
        layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        layoutServices.saveToDisk()
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

extension View {
    func asImage(rect: CGRect) -> UIImage? {
        let hostingController = UIHostingController(rootView: self)
        let view = hostingController.view

        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { context in
            view?.layer.render(in: context.cgContext)
        }
    }
}

