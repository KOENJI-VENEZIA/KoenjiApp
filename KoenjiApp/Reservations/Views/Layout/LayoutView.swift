import PencilKit
import ScreenshotSwiftUI
import SwiftUI
import UIKit
import OSLog

struct LayoutView: View {
    // MARK: - Private Properties
    static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "LayoutView"
    )

    // MARK: - Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState


    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State, Bindings & Local Variables
    @State var unitView = LayoutUnitViewModel()
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
    @StateObject var timerManager = TimerManager()
    @State var layoutUI: LayoutUIManager


    @Binding var selectedReservation: Reservation?
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // MARK: - Initializer
    init(
        appState: AppState,
        store: ReservationStore,
        reservationService: ReservationService,
        clusterServices: ClusterServices,
        layoutServices: LayoutServices,
        resCache: CurrentReservationsCache,
        selectedReservation: Binding<Reservation?>,
        columnVisibility: Binding<NavigationSplitViewVisibility>
    ) {
        self._selectedReservation = selectedReservation
        self._columnVisibility = columnVisibility

        _clusterManager = State(initialValue: ClusterManager(
            clusterServices: clusterServices,
            layoutServices: layoutServices,
            resCache: resCache,
            date: appState.selectedDate,
            category: appState.selectedCategory
        ))
        _layoutUI = State(initialValue: LayoutUIManager(
            store: store,
            reservationService: reservationService,
            layoutServices: layoutServices
        ))
    }

    // MARK: - Computed Properties
    var currentLayoutKey: String {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        return env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)
    }

    private var gridWidth: CGFloat {
        CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize
    }

    private var gridHeight: CGFloat {
        CGFloat(env.tableStore.totalRows) * env.gridData.cellSize
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundTapGestureView
                mainLayoutView
                additionalCanvasLayers(in: geometry)
                toolbarOverlay(in: geometry)
                overlays(in: geometry)
            }
            .ignoresSafeArea(edges: .bottom)
//            .navigationTitle("Layout Tavoli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { topBarToolbar }
            .sheet(isPresented: $unitView.showInspector, content: inspectorSheet)
            .sheet(item: $appState.currentReservation, content: editReservationSheet)
            .sheet(isPresented: $unitView.showingAddReservationSheet, content: addReservationSheet)
            .sheet(isPresented: $unitView.isPresented, content: shareSheet) // to edit name
            .sheet(isPresented: $unitView.showNotifsCenter) {
                NotificationCenterView()
                    .environmentObject(env)
                    .environment(unitView)
                    .presentationBackground(.thinMaterial)
            }
            .onAppear { initializeView() }
            .onChange(of: scenePhase) { unitView.refreshID = UUID() }
            .onChange(of: unitView.selectedIndex) { handleSelectedIndexChange() }
            .onChange(of: appState.selectedCategory) { old, new in handleSelectedCategoryChange(old, new) }
            .onChange(of: appState.selectedDate) { _, new in
                handleCurrentTimeChange(new)
                updateDatesAroundSelectedDate(new)
            }
            .onChange(of: unitView.showInspector) { _, new in if !new { selectedReservation = nil } }
            .onChange(of: unitView.isScribbleModeEnabled) {
                DispatchQueue.main.async {
                    env.scribbleService.saveScribbleForCurrentLayout(currentDrawing, currentLayoutKey)
                }
            }
            .onReceive(timerManager.$currentDate) { newTime in
                if !unitView.isManuallyOverridden { appState.selectedDate = newTime }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Subviews
extension LayoutView {
    private var backgroundTapGestureView: some View {
        Color.clear
            .gesture(
                TapGesture(count: 3)
                    .onEnded {
                        withAnimation {
                            appState.isFullScreen.toggle()
                            columnVisibility = appState.isFullScreen ? .detailOnly : .all
                        }
                    }
            )
    }
    
    private var mainLayoutView: some View {
        LayoutPageView(
            columnVisibility: $columnVisibility,
            selectedReservation: $selectedReservation
        )
        .environment(clusterManager)
        .environmentObject(currentDrawing)
        .environment(layoutUI)
        .environment(unitView)
    }
    
    private func additionalCanvasLayers(in geometry: GeometryProxy) -> some View {
        Group {
            if unitView.scale <= 1 {
                PencilKitCanvas(
                    layer: .layer1
                )
                .environmentObject(currentDrawing)
                .environment(unitView)
                .frame(width: abs(geometry.size.width - gridWidth), height: geometry.size.height)
                .position(x: geometry.size.width, y: geometry.size.height / 2)
                
                PencilKitCanvas(
                    layer: .layer3
                )
                .environmentObject(currentDrawing)
                .environment(unitView)
                .frame(width: abs(geometry.size.width - gridWidth), height: geometry.size.height)
                .position(x: 0, y: geometry.size.height / 2)
            }
        }
    }
    
    private func toolbarOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            ToolbarExtended(geometry: geometry, toolbarState: $toolbarManager.toolbarState, small: false)
            toolbarContent(in: geometry, selectedDate: appState.selectedDate)
        }
        .opacity(toolbarManager.isToolbarVisible && !unitView.isScribbleModeEnabled ? 1 : 0)
        .ignoresSafeArea(.keyboard)
        .position(
            toolbarManager.isDragging ? toolbarManager.dragAmount : toolbarManager.calculatePosition(geometry: geometry, isPhone: isPhone)
        )
        .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
        .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
        .gesture(toolbarManager.toolbarGesture(geometry: geometry))
    }
    
    private func overlays(in geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottomLeading) {
            ToolbarMinimized()
                .opacity(!toolbarManager.isToolbarVisible && !unitView.isScribbleModeEnabled ? 1 : 0)
                .ignoresSafeArea(.keyboard)
                .position(toolbarManager.isDragging ? toolbarManager.dragAmount : toolbarManager.calculatePosition(geometry: geometry, isPhone: isPhone))
                .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
                .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
                .gesture(
                    TapGesture()
                        .onEnded { withAnimation { toolbarManager.isToolbarVisible = true } }
                )
                .simultaneousGesture(toolbarManager.toolbarGesture(geometry: geometry))
            
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .opacity(unitView.isPresented ? (unitView.isSharing ? 0.0 : 1.0) : 0.0)
                .animation(.easeInOut(duration: 0.3), value: unitView.isPresented)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .opacity(unitView.isSharing ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: unitView.isSharing)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            LoadingOverlay()
                .opacity(env.backupService.isWritingToFirebase ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: env.backupService.isWritingToFirebase)
                .allowsHitTesting(env.backupService.isWritingToFirebase)
            
            
        }
    }
}

// MARK: - Helper Methods & Date Navigation
extension LayoutView {
    func debugCache() {
        if let cached = env.resCache.cache[appState.selectedDate] {
            for res in cached {
                AppLog.debug("Reservation in cache: \(res.name), start time: \(res.startTime), end time: \(res.endTime)")
            }
        } else {
            AppLog.debug("No reservations in cache at \(DateHelper.formatDate(appState.selectedDate))")
        }
    }
    
    func toggleFullScreen() {
    withAnimation {
        appState.isFullScreen.toggle()
        columnVisibility = appState.isFullScreen ? .detailOnly : .all
    }
}
    
    private func initializeView() {
        columnVisibility = .detailOnly
        unitView.dates = generateInitialDates()
        AppLog.info("Initialized with date: \(DateHelper.formatDate(appState.selectedDate)), category: \(appState.selectedCategory.localized)")
        clusterManager.loadClusters()
        env.resCache.startMonitoring(for: appState.selectedDate)
    }
    
    private func handleSelectedIndexChange() {
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            withAnimation { appState.selectedDate = combinedTime }
        }
        handleCurrentTimeChange(appState.selectedDate)
        AppLog.debug("Selected index changed to \(unitView.selectedIndex), date: \(DateHelper.formatFullDate(appState.selectedDate))")
        if unitView.selectedIndex >= unitView.dates.count - 5 { appendMoreDates() }
        if unitView.selectedIndex <= 5 { prependMoreDates() }
        trimDatesAround(unitView.selectedIndex)
    }
    
    private func handleSelectedCategoryChange(_ oldCategory: Reservation.ReservationCategory,
                                                _ newCategory: Reservation.ReservationCategory) {
        guard unitView.isManuallyOverridden, oldCategory != newCategory else { return }
        AppLog.info("Category changed from \(oldCategory.rawValue) to \(newCategory.rawValue)")
    }
    
    func handleCurrentTimeChange(_ newTime: Date) {
        AppLog.debug("Time updated to \(DateHelper.formatFullDate(newTime))")
        withAnimation { appState.selectedDate = newTime }
        let calendar = Calendar.current
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)!
        let determinedCategory: Reservation.ReservationCategory
        if appState.selectedDate >= lunchStart && appState.selectedDate <= lunchEnd {
            determinedCategory = .lunch
        } else if appState.selectedDate >= dinnerStart && appState.selectedDate <= dinnerEnd {
            determinedCategory = .dinner
        } else {
            determinedCategory = .noBookingZone
        }
        withAnimation { appState.selectedCategory = determinedCategory }
    }
    
    func resetLayout() {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        AppLog.info("Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(appState.selectedCategory.localized)")
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        env.layoutServices.resetTables(for: currentDate, category: appState.selectedCategory)
        withAnimation {
            env.layoutServices.tables = env.layoutServices.loadTables(for: combinedDate, category: appState.selectedCategory)
        }
        env.clusterServices.resetClusters(for: combinedDate, category: appState.selectedCategory)
        env.clusterServices.saveClusters([], for: combinedDate, category: appState.selectedCategory)
        DispatchQueue.main.async {
            withAnimation {
                self.unitView.isLayoutLocked = true
                self.unitView.isLayoutReset = true
            }
            AppLog.info("Layout successfully reset and reservations checked")
        }
    }
    
    func navigateToPreviousDate() {
        guard unitView.selectedIndex > 0 else { return }
        toolbarManager.navigationDirection = .backward
        unitView.selectedIndex -= 1
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            unitView.isManuallyOverridden = true
        }
    }
    
    func navigateToNextDate() {
        guard unitView.selectedIndex < unitView.dates.count - 1 else { return }
        toolbarManager.navigationDirection = .forward
        unitView.selectedIndex += 1
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            unitView.isManuallyOverridden = true
        }
    }
    
    func navigateToNextTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let maxAllowedTime: Date?
        switch appState.selectedCategory {
        case .lunch:
            maxAllowedTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)
        case .dinner:
            maxAllowedTime = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)
        case .noBookingZone:
            return
        }
        if let maxAllowedTime = maxAllowedTime {
            let newTime = calendar.date(byAdding: .minute, value: 15, to: roundedDown)!
            if newTime <= maxAllowedTime {
                appState.selectedDate = newTime
                unitView.isManuallyOverridden = true
            }
        }
    }
    
    func navigateToPreviousTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let minAllowedTime: Date?
        switch appState.selectedCategory {
        case .lunch:
            minAllowedTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)
        case .dinner:
            minAllowedTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)
        case .noBookingZone:
            return
        }
        if let minAllowedTime = minAllowedTime {
            let newTime = calendar.date(byAdding: .minute, value: -15, to: roundedDown)!
            if newTime >= minAllowedTime {
                appState.selectedDate = newTime
                unitView.isManuallyOverridden = true
            }
        }
    }
    
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: appState.selectedDate)
        var dates = [Date]()
        for offset in -15...14 {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    private func appendMoreDates() {
        guard let lastDate = unitView.dates.last else { return }
        let newDates = generateSequentialDates(from: lastDate, count: 5)
        unitView.dates.append(contentsOf: newDates)
        AppLog.debug("Appended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
    }
    
    private func prependMoreDates() {
        guard let firstDate = unitView.dates.first else { return }
        let newDates = generateSequentialDates(before: firstDate, count: 5)
        unitView.dates.insert(contentsOf: newDates, at: 0)
        unitView.selectedIndex += newDates.count
        AppLog.debug("Prepended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
    }
    
    private func generateSequentialDates(from startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
        return dates
    }
    
    func updateDatesAroundSelectedDate(_ newDate: Date) {
    if let newIndex = unitView.dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
        withAnimation { unitView.selectedIndex = newIndex }
        handleSelectedIndexChange()
    } else {
        unitView.dates = generateDatesCenteredAround(newDate)
        if let newIndex = unitView.dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
            withAnimation { unitView.selectedIndex = newIndex }
            handleSelectedIndexChange()
        }
    }
}
    
    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else {
            return unitView.dates
        }
        return (0...(range * 2)).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
    
    private func generateSequentialDates(before startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) {
                dates.insert(date, at: 0)
            }
        }
        return dates
    }
    
    private func handleEmptyTableTap(for table: TableModel) {
        unitView.tableForNewReservation = table
        unitView.showingAddReservationSheet = true
    }
    
    private func adjustTime(for category: Reservation.ReservationCategory) {
        switch category {
        case .lunch:
            appState.selectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? appState.selectedDate
        case .dinner:
            appState.selectedDate = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? appState.selectedDate
        case .noBookingZone:
            break
        }
    }
    
    private func trimDatesAround(_ index: Int) {
        let bufferSize = 30
        if unitView.dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(unitView.dates.count, index + bufferSize / 2)
            unitView.dates = Array(unitView.dates[startIndex..<endIndex])
            unitView.selectedIndex = index - startIndex
            AppLog.debug("Trimmed dates around index \(index). New selectedIndex: \(unitView.selectedIndex)")
        }
    }
}

// MARK: - Array Extension for Safe Indexing
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
