//
//  LayoutPageView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 01/01/2025.
//

import CoreGraphics
import SwiftUI

struct LayoutPageView: View {
    // MARK: - Dependencies
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData

    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Managers
    @StateObject private var layoutUI: LayoutUIManager
    @StateObject private var clusterManager: ClusterManager

    @Namespace private var animationNamespace

    // MARK: - Filters and Properties
    var selectedDate: Date
    var selectedCategory: Reservation.ReservationCategory

    // MARK: - Bindings
    @Binding var currentTime: Date
    @Binding var isManuallyOverridden: Bool
    @Binding var selectedReservation: Reservation?
    @Binding var changedReservation: Reservation?
    @Binding var showInspector: Bool
    @Binding var showingEditReservation: Bool
    @Binding var showingAddReservationSheet: Bool
    @Binding var tableForNewReservation: TableModel?
    @Binding var isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    var onFetchedReservations: ([Reservation]) -> Void

    // MARK: - States
    @State private var scale: CGFloat = 1
    @State private var isLoadingClusters: Bool = true
    @State private var isLoading: Bool = true
    @State private var resetInProgress: Bool = false
    @State private var cachedActiveReservations: [Reservation] = []
    @State private var lastFetchedDate: Date?
    @State private var lastFetchedTime: Date?
    @State private var lastFetchedCount: Int = 0
    @State private var pendingClusterUpdate: DispatchWorkItem?
    @State private var statusChanged: Int = 0

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

    private var activeReservations: [Reservation] {
        fetchActiveReservationsIfNeeded()
    }

    private var combinedDate: Date {
        DateHelper.combine(date: selectedDate, time: currentTime)
    }

    private var cacheKey: String {
        layoutServices.keyFor(date: combinedDate, category: selectedCategory)
    }

    // MARK: - Initializer
    init(
        selectedDate: Date,
        selectedCategory: Reservation.ReservationCategory,
        currentTime: Binding<Date>,
        isManuallyOverridden: Binding<Bool>,
        selectedReservation: Binding<Reservation?>,
        changedReservation: Binding<Reservation?>,
        showInspector: Binding<Bool>,
        showingEditReservation: Binding<Bool>,
        showingAddReservationSheet: Binding<Bool>,
        tableForNewReservation: Binding<TableModel?>,
        isLayoutLocked: Binding<Bool>,
        isLayoutReset: Binding<Bool>,
        onFetchedReservations: @escaping ([Reservation]) -> Void
    ) {
        // Assign parameters to properties
        self.selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._currentTime = currentTime
        self._isManuallyOverridden = isManuallyOverridden
        self._selectedReservation = selectedReservation
        self._changedReservation = changedReservation
        self._showInspector = showInspector
        self._showingEditReservation = showingEditReservation
        self._showingAddReservationSheet = showingAddReservationSheet
        self._tableForNewReservation = tableForNewReservation
        self._isLayoutLocked = isLayoutLocked
        self._isLayoutReset = isLayoutReset
        self.onFetchedReservations = onFetchedReservations

        // Initialize StateObjects
        _layoutUI = StateObject(
            wrappedValue: LayoutUIManager(date: selectedDate, category: selectedCategory))
        _clusterManager = StateObject(
            wrappedValue: ClusterManager(date: selectedDate, category: selectedCategory))
    }

    // MARK: - Body
    var body: some View {

        ZoomableScrollView(

            category: .constant(selectedCategory),
            scale: $scale
        ) {

            Text(
                "\(DateHelper.dayOfWeek(for: selectedDate)), \(DateHelper.formatFullDate(selectedDate)) - \(selectedCategory.localized.uppercased()) - \(DateHelper.formatTime(currentTime))"
            )
            .font(.system(size: 28, weight: .bold))
            .padding(.top, 16)
            .padding(.horizontal, 16)

            ZStack {
                gridData.gridBackground(selectedCategory: selectedCategory)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                RoundedRectangle(cornerRadius: 12.0)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))

                if isLoading {
                    ZStack {
                        loadingView

                        Text("Caricamento...")
                            .foregroundColor(Color.gray.opacity(0.8))
                            .font(.headline)
                            .padding(20)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(12)
                            .frame(width: gridWidth / 2, height: gridHeight / 2)
                            .position(x: gridWidth / 2, y: gridHeight / 2 - gridData.cellSize)
                    }

                } else {
                    // Individual tables
                    ForEach(layoutUI.tables, id: \.id) { table in
                        TableView(
                            table: table,
                            selectedDate: selectedDate,
                            selectedCategory: selectedCategory,
                            currentTime: currentTime,
                            activeReservations: activeReservations,
                            changedReservation: $changedReservation,
                            isEditing: $showingEditReservation,
                            layoutUI: layoutUI,
                            onTapEmpty: { table in
                                handleEmptyTableTap(for: table)
                            },
                            onStatusChange: {
                                statusChanged += 1
                            },
                            showInspector: $showInspector,
                            onEditReservation: { reservation in
                                selectedReservation = reservation
                            },
                            isLayoutLocked: isLayoutLocked,
                            isLayoutReset: $isLayoutReset,
                            animationNamespace: animationNamespace,
                            onTableUpdated: { updatedTable in
                                self.onTableUpdated(updatedTable)
                            }
                        )
                        .environmentObject(store)
                        .environmentObject(tableStore)
                        .environmentObject(reservationService)  // For the new service
                        .environmentObject(clusterServices)
                        .environmentObject(layoutServices)
                        .environmentObject(gridData)
                        .transition(.opacity)  // Fade in/out transition

                        if clusterManager.clusters.isEmpty && !isLoadingClusters {
                        } else if isLoadingClusters {
                            ProgressView("Loading Clusters...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Reservation clusters overlay
                            ForEach(clusterManager.clusters) { cluster in
                                let overlayFrame = cluster.frame

                                ClusterView(
                                    cluster: cluster,
                                    overlayFrame: overlayFrame,
                                    currentTime: $currentTime,
                                    isLayoutLocked: $isLayoutLocked,
                                    isLunch: isLunch
                                )
                            }
                        }
                    }

                    ForEach(clusterManager.clusters) { cluster in
                        ClusterOverlayView(cluster: cluster, currentTime: currentTime)
                            .zIndex(2)
                            .gesture(
                                TapGesture(count: 1).onEnded {
                                    handleTap(activeReservations, cluster.reservationID)
                                }
                            )
                    }
                }
            }
            //.ignoresSafeArea()
            .transition(.opacity)  // Fade in/out transition

            .drawingGroup()
            .frame(width: gridWidth, height: gridHeight)
            .compositingGroup()

        }

        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoadingClusters = true
                isLoading = true
            }
            Task {
                DispatchQueue.main.async {
                    loadCurrentLayout()
                    print("Current time as LayoutPageView appears: \(currentTime)")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoadingClusters = false
                        isLoading = false
                    }
                }
            }
        }
        .onChange(of: isLayoutReset) { old, reset in
            if reset {
                isLoading = true
                resetCurrentLayout()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 0.5)) {

                        isLoading = false
                    }
                    isLayoutReset = false  // Clear reset state
                }
            }
        }
        .onChange(of: selectedCategory) { old, newCategory in
            // Load tables for the new category and date
            reloadLayout(newCategory, activeReservations)
            let activeReservations = fetchActiveReservationsIfNeeded(forceTrigger: true)
            clusterManager.recalculateClustersIfNeeded(
                for: activeReservations, tables: layoutUI.tables, combinedDate: combinedDate,
                oldCategory: old,
                selectedCategory: selectedCategory, cellSize: gridData.cellSize)

        }
        .onChange(of: selectedDate) { old, newDate in
            reloadLayout(selectedCategory, activeReservations)
            let activeReservations = fetchActiveReservationsIfNeeded(forceTrigger: true)
            clusterManager.recalculateClustersIfNeeded(
                for: activeReservations, tables: layoutUI.tables, combinedDate: newDate,
                oldCategory: selectedCategory,
                selectedCategory: selectedCategory, cellSize: gridData.cellSize)

        }
        .onChange(of: showingEditReservation) { old, newValue in
            print("Triggered onChange of showingEditReservation")
            let activeReservations = fetchActiveReservationsIfNeeded(forceTrigger: true)
            reloadLayout(selectedCategory, activeReservations)
        }
        .onChange(of: currentTime) { old, newTime in
            print("New current time: \(newTime)")
            let activeReservations = fetchActiveReservationsIfNeeded(forceTrigger: true)
            clusterManager.recalculateClustersIfNeeded(
                for: activeReservations, tables: layoutUI.tables, combinedDate: combinedDate,
                oldCategory: selectedCategory,
                selectedCategory: selectedCategory, cellSize: gridData.cellSize)

        }
        .onChange(of: store.reservations) { oldValue, newValue in
            print("reservations changed from \(oldValue.count) to \(newValue.count)")
            // Force the active-reservations fetch (since store.reservations changed)
            reloadLayout(selectedCategory, activeReservations)
        }
        .onChange(of: changedReservation) {
            let activeReservations = fetchActiveReservationsIfNeeded(forceTrigger: true)
            print("Detected cancelled Reservation [LayoutPageView]")
            reloadLayout(selectedCategory, activeReservations)
        }
        .onChange(of: statusChanged) {
            let activeReservations = fetchActiveReservationsIfNeeded(forceTrigger: true)
            onFetchedReservations(activeReservations)
            reloadLayout(selectedCategory, activeReservations)
        }

        .alert(isPresented: $layoutUI.showAlert) {
            Alert(
                title: Text("Posizionamento non valido"),
                message: Text(layoutUI.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Helper Views
    private var loadingView: some View {

        ForEach(tableStore.baseTables, id: \.id) { table in
            let tableWidth = CGFloat(table.width) * gridData.cellSize
            let tableHeight = CGFloat(table.height) * gridData.cellSize
            let xPos = CGFloat(table.column) * gridData.cellSize + tableWidth / 2
            let yPos = CGFloat(table.row) * gridData.cellSize + tableHeight / 2

            RoundedRectangle(cornerRadius: 8.0)
                .fill(Color.gray.opacity(0.3))  // Placeholder color
                .frame(width: tableWidth, height: tableHeight)
                .position(x: xPos, y: yPos)
            RoundedRectangle(cornerRadius: 8.0)
                .stroke(Color.gray.opacity(0.7), lineWidth: 3)  // Placeholder color
                .frame(width: tableWidth, height: tableHeight)
                .position(x: xPos, y: yPos)
        }

    }

    // MARK: - Gesture Methods

    private func handleTap(_ activeReservations: [Reservation], _ activeReservation: Reservation?) {
        if let index = activeReservations.firstIndex(where: { $0.id == activeReservation?.id }) {
            var currentReservation = activeReservations[index]
            if currentReservation.status == .pending || currentReservation.status == .late {

                currentReservation.status = .showedUp
                reservationService.updateReservation(currentReservation)  // Ensure the data store is updated
                statusChanged += 1

            } else {
                if let reservationStart = DateHelper.parseTime(currentReservation.startTime),
                   currentTime.timeIntervalSince(reservationStart) >= 60 * 15 {
                    currentReservation.status = .late
                } else {
                    currentReservation.status = .pending
                }
                reservationService.updateReservation(currentReservation)  // Ensure the data store is updated
                statusChanged += 1
            }
        }
    }

    // Handle tapping an empty table to add a reservation
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }

    // MARK: - UI Update Methods

    private func reloadLayout(
        _ selectedCategory: Reservation.ReservationCategory, _ activeReservations: [Reservation]
    ) {
        layoutUI.tables = layoutServices.loadTables(for: combinedDate, category: selectedCategory)
        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations, tables: layoutUI.tables, combinedDate: combinedDate,
            oldCategory: selectedCategory,
            selectedCategory: selectedCategory, cellSize: gridData.cellSize)
    }

    private func onTableUpdated(_ updatedTable: TableModel) {

        self.updateAdjacencyCountsForLayout(updatedTable)
        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations, tables: layoutUI.tables, combinedDate: combinedDate,
            oldCategory: selectedCategory,
            selectedCategory: selectedCategory, cellSize: gridData.cellSize)
        clusterServices.saveClusters(
            clusterManager.clusters, for: combinedDate, category: selectedCategory)
        layoutUI.saveLayout()
        layoutServices.saveTables(layoutUI.tables, for: combinedDate, category: selectedCategory)

        let newSignature = layoutServices.computeLayoutSignature(tables: layoutUI.tables)
        if newSignature != clusterManager.lastLayoutSignature {
            // We have a real adjacency change, so we might need to recalc clusters
            clusterManager.lastLayoutSignature = newSignature
            statusChanged += 1  // or some equivalent trigger
        }
    }

    private func updateLayoutResetState() {
        isLayoutReset = (layoutUI.tables == tableStore.baseTables)
    }

    private func loadCurrentLayout() {

        
        let calendar = Calendar.current

        // Define time ranges
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: selectedDate)!

        // Compare newTime against the ranges
        let determinedCategory: Reservation.ReservationCategory
        if currentTime >= lunchStart && currentTime <= lunchEnd {
            determinedCategory = .lunch
        } else if currentTime >= dinnerStart && currentTime <= dinnerEnd {
            determinedCategory = .dinner
        } else {
            determinedCategory = .noBookingZone
        }

        if !layoutUI.isConfigured {
            layoutUI.configure(
                store: store, reservationService: reservationService,
                layoutServices: layoutServices)
            layoutUI.tables = layoutServices.loadTables(
                for: combinedDate, category: determinedCategory)
        }

        if !clusterManager.isConfigured {
            clusterManager.configure(
                store: store, reservationService: reservationService,
                clusterServices: clusterServices,
                layoutServices: layoutServices)
            clusterManager.clusters = clusterServices.loadClusters(
                for: combinedDate, category: determinedCategory)
        }

        onFetchedReservations(activeReservations)

        clusterManager.recalculateClustersIfNeeded(
            for: activeReservations, tables: layoutUI.tables, combinedDate: combinedDate,
            oldCategory: determinedCategory,
            selectedCategory: determinedCategory, cellSize: gridData.cellSize)

    }

    private func resetCurrentLayout() {
        print("Resetting layout... [resetCurrentLayout()]")
        resetInProgress = true
        let key = layoutServices.keyFor(date: combinedDate, category: selectedCategory)

        if let baseTables = layoutServices.cachedLayouts[key] {
            layoutUI.tables = baseTables
        } else {
            layoutUI.tables = []
        }

        clusterManager.clusters = []
        clusterServices.saveClusters([], for: combinedDate, category: selectedCategory)
        layoutServices.cachedLayouts[key] = nil

        // Ensure flag is cleared after reset completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetInProgress = false
        }
    }

    // MARK: - Cache and UI Update Methods
    private func fetchActiveReservationsIfNeeded(forceTrigger: Bool = false) -> [Reservation] {
        // Check if the fetch is redundant
        if lastFetchedCount == store.reservations.count && forceTrigger == false {
            if let lastDate = lastFetchedDate,
                let lastTime = lastFetchedTime,
                Calendar.current.isDate(selectedDate, inSameDayAs: lastDate),
                abs(currentTime.timeIntervalSince(lastTime)) < 60
            {
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
                key.time < currentTime.addingTimeInterval(14400)
            else {
                continue
            }
            
            guard reservation.reservationType != .waitingList else {
                print("Skipped \(reservation.name) since is in waiting list")
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

    private func updateAdjacencyCountsForLayout(_ updatedTable: TableModel) {
        // Identify tables with adjacentCount > 0 before the move
        let previousAdjacentTables = layoutUI.tables.filter { $0.adjacentCount > 0 }.map { $0.id }

        // Identify affected tables (dragged table + neighbors)
        var affectedTableIDs = Set<Int>()
        affectedTableIDs.insert(updatedTable.id)

        let adjacencyResult = layoutServices.isTableAdjacent(
            updatedTable, combinedDateTime: combinedDate, activeTables: layoutUI.tables)
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
                    table, combinedDateTime: combinedDate, activeTables: layoutUI.tables)
                layoutUI.tables[index].adjacentCount = adjacency.adjacentCount

                layoutUI.tables[index].activeReservationAdjacentCount =
                    layoutServices.isAdjacentWithSameReservation(
                        for: table,
                        combinedDateTime: combinedDate,
                        activeTables: layoutUI.tables
                    ).count
            }
        }

        // Update cached layout and save
        let layoutKey = layoutServices.keyFor(date: combinedDate, category: selectedCategory)
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
