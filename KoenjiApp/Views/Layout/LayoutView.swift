import PencilKit
import ScreenshotSwiftUI
import SwiftUI
import UIKit

struct LayoutView: View {
    // MARK: - Environment Objects & Dependencies
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var scribbleService: ScribbleService
    @EnvironmentObject var appState: AppState

    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State, Bindings & Local Variables
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject private var currentDrawing = DrawingModel()
    @StateObject private var timerManager = TimerManager()
    @State var layoutUI: LayoutUIManager

    @State private var dates: [Date] = []
    @State private var selectedIndex: Int = 15

    @State private var systemTime: Date = Date()

    @Binding var selectedReservation: Reservation?
    @Binding var columnVisibility: NavigationSplitViewVisibility

    @State private var isManuallyOverridden: Bool = false
    @State private var showInspector: Bool = false
    @State private var showingDatePicker: Bool = false

    @State private var showingAddReservationSheet: Bool = false
    @State private var tableForNewReservation: TableModel? = nil

    @State private var showingNoBookingAlert: Bool = false
    @State private var isLayoutLocked: Bool = true
    @State private var isZoomLocked: Bool = false
    @State private var isLayoutReset: Bool = false

    @State private var isScribbleModeEnabled: Bool = false
    @State private var drawings: [String: PKDrawing] = [:]

    @State private var toolPickerShows = false

    @State private var capturedImage: UIImage? = nil
    @State private var cachedScreenshot: ScreenshotMaker?
    @State private var isSharing: Bool = false
    @State private var isPresented: Bool = false

    @State var refreshID = UUID()
    @State private var scale: CGFloat = 1
    @State private var isShowingFullImage = false

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
        let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        return layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)
    }

    private var gridWidth: CGFloat {
        CGFloat(store.totalColumns) * gridData.cellSize
    }

    private var gridHeight: CGFloat {
        CGFloat(store.totalRows) * gridData.cellSize
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
            .navigationTitle("Layout Tavoli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { topBarToolbar }
            .sheet(isPresented: $showInspector, content: inspectorSheet)
            .sheet(item: $appState.currentReservation, content: editReservationSheet)
            .sheet(isPresented: $showingAddReservationSheet, content: addReservationSheet)
            .sheet(isPresented: $isPresented, content: shareSheet)
            .onAppear { initializeView() }
            .onChange(of: scenePhase) { _, _ in refreshID = UUID() }
            .onChange(of: selectedIndex) { _ in handleSelectedIndexChange() }
            .onChange(of: appState.selectedCategory) { old, new in handleSelectedCategoryChange(old, new) }
            .onChange(of: appState.selectedDate) { _, new in
                handleCurrentTimeChange(new)
                updateDatesAroundSelectedDate(new)
            }
            .onChange(of: showInspector) { _, new in if !new { selectedReservation = nil } }
            .onChange(of: isScribbleModeEnabled) {
                DispatchQueue.main.async {
                    scribbleService.saveScribbleForCurrentLayout(currentDrawing, currentLayoutKey)
                }
            }
            .onReceive(timerManager.$currentDate) { newTime in
                if !isManuallyOverridden { appState.selectedDate = newTime }
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
            selectedDate: appState.selectedDate,
            selectedCategory: appState.selectedCategory,
            selectedIndex: $selectedIndex,
            columnVisibility: $columnVisibility,
            scale: $scale,
            selectedReservation: $selectedReservation,
            changedReservation: $appState.changedReservation,
            showInspector: $showInspector,
            showingEditReservation: $appState.showingEditReservation,
            showingAddReservationSheet: $showingAddReservationSheet,
            tableForNewReservation: $tableForNewReservation,
            isLayoutLocked: $isLayoutLocked,
            isLayoutReset: $isLayoutReset,
            isScribbleModeEnabled: $isScribbleModeEnabled,
            toolPickerShows: $toolPickerShows,
            isSharing: $isSharing,
            isPresented: $isPresented,
            cachedScreenshot: $cachedScreenshot
        )
        .environment(clusterManager)
        .environmentObject(currentDrawing)
        .environment(layoutUI)
    }
    
    private func additionalCanvasLayers(in geometry: GeometryProxy) -> some View {
        Group {
            if scale <= 1 {
                PencilKitCanvas(
                    toolPickerShows: $toolPickerShows,
                    layer: .layer1,
                    gridWidth: nil,
                    gridHeight: nil,
                    canvasSize: nil,
                    isEditable: isScribbleModeEnabled
                )
                .environmentObject(currentDrawing)
                .frame(width: abs(geometry.size.width - gridWidth), height: geometry.size.height)
                .position(x: geometry.size.width, y: geometry.size.height / 2)
                
                PencilKitCanvas(
                    toolPickerShows: $toolPickerShows,
                    layer: .layer3,
                    gridWidth: nil,
                    gridHeight: nil,
                    canvasSize: nil,
                    isEditable: isScribbleModeEnabled
                )
                .environmentObject(currentDrawing)
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
        .opacity(toolbarManager.isToolbarVisible && !isScribbleModeEnabled ? 1 : 0)
        .ignoresSafeArea(.keyboard)
        .position(
            toolbarManager.isDragging ? toolbarManager.dragAmount : toolbarManager.calculatePosition(geometry: geometry)
        )
        .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
        .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
        .gesture(toolbarManager.toolbarGesture(geometry: geometry))
    }
    
    private func overlays(in geometry: GeometryProxy) -> some View {
        ZStack {
            ToolbarMinimized()
                .opacity(!toolbarManager.isToolbarVisible && !isScribbleModeEnabled ? 1 : 0)
                .ignoresSafeArea(.keyboard)
                .position(toolbarManager.isDragging ? toolbarManager.dragAmount : toolbarManager.calculatePosition(geometry: geometry))
                .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
                .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
                .gesture(
                    TapGesture()
                        .onEnded { withAnimation { toolbarManager.isToolbarVisible = true } }
                )
                .simultaneousGesture(toolbarManager.toolbarGesture(geometry: geometry))
            
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .opacity(isPresented ? (isSharing ? 0.0 : 1.0) : 0.0)
                .animation(.easeInOut(duration: 0.3), value: isPresented)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            VisualEffectView(effect: UIBlurEffect(style: .dark))
                .opacity(isSharing ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: isSharing)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            LoadingOverlay()
                .opacity(appState.isWritingToFirebase ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: appState.isWritingToFirebase)
                .allowsHitTesting(appState.isWritingToFirebase)
            
            LockOverlay(isLayoutLocked: isLayoutLocked)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.04)
                .animation(.easeInOut(duration: 0.3), value: isLayoutLocked)
        }
    }
}

// MARK: - Toolbar Content (Date/Time Controls)
extension LayoutView {
    @ViewBuilder
    private func toolbarContent(in geometry: GeometryProxy, selectedDate: Date) -> some View {
        switch toolbarManager.toolbarState {
        case .pinnedLeft, .pinnedRight:
            VStack {
                resetDate.padding(.vertical, 2)
                dateBackward.padding(.bottom, 2)
                dateForward.padding(.bottom, 2)
                datePicker(selectedDate: selectedDate).padding(.bottom, 2)
                resetTime.padding(.bottom, 2)
                timeBackward.padding(.bottom, 2)
                timeForward.padding(.bottom, 2)
                lunchButton.padding(.bottom, 2)
                dinnerButton.padding(.bottom, 2)
            }
        case .pinnedBottom:
            HStack(spacing: 25) {
                resetDate
                dateBackward
                dateForward
                datePicker(selectedDate: selectedDate)
                resetTime
                timeBackward
                timeForward
                lunchButton
                dinnerButton
            }
        }
    }
}

// MARK: - Sheets & Modals
extension LayoutView {
    private func inspectorSheet() -> some View {
        InspectorSideView(
            selectedReservation: $selectedReservation,
            currentReservation: $appState.currentReservation,
            showInspector: $showInspector,
            showingEditReservation: $appState.showingEditReservation,
            changedReservation: $appState.changedReservation,
            isShowingFullImage: $isShowingFullImage
        )
        .presentationBackground(.thinMaterial)
    }
    
    private func editReservationSheet(for reservation: Reservation) -> some View {
        EditReservationView(
            reservation: reservation,
            onClose: {
                appState.showingEditReservation = false
                showInspector = true
            },
            onChanged: { updatedReservation in
                appState.changedReservation = updatedReservation
            }
        )
        .presentationBackground(.thinMaterial)
    }
    
    private func addReservationSheet() -> some View {
        AddReservationView(passedTable: tableForNewReservation)
            .presentationBackground(.thinMaterial)
    }
    
    private func shareSheet() -> some View {
        ShareModal(
            cachedScreenshot: cachedScreenshot,
            isPresented: $isPresented,
            isSharing: $isSharing
        )
    }
}

// MARK: - Top Bar Toolbar
extension LayoutView {
    @ToolbarContentBuilder
    private var topBarToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: toggleFullScreen) {
                Label("Toggle Full Screen", systemImage: appState.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: debugCache) {
                Label("Debug Cache", systemImage: "ladybug.slash.fill")
            }
            .id(refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { withAnimation { isPresented.toggle() } }) {
                Label("Share Layout", systemImage: "square.and.arrow.up")
            }
            .id(refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                withAnimation {
                    scribbleService.deleteAllScribbles()
                    UserDefaults.standard.removeObject(forKey: "cachedScribbles")
                    currentDrawing.layer1 = PKDrawing()
                    currentDrawing.layer2 = PKDrawing()
                    currentDrawing.layer3 = PKDrawing()
                }
            }) {
                Label("Delete Current Scribble", systemImage: "trash")
            }
            .id(refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                withAnimation {
                    isScribbleModeEnabled.toggle()
                    toolPickerShows.toggle()
                }
            }) {
                Label(isScribbleModeEnabled ? "Exit Scribble Mode" : "Enable Scribble",
                      systemImage: isScribbleModeEnabled ? "pencil.slash" : "pencil")
            }
            .id(refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation {
                    isLayoutLocked.toggle()
                }
                isZoomLocked.toggle()
            }) {
                Label(isLayoutLocked ? "Unlock Layout" : "Lock Layout",
                      systemImage: isLayoutLocked ? "lock.fill" : "lock.open.fill")
            }
            .tint(isLayoutLocked ? .red : .accentColor)
            .id(refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: resetLayout) {
                Label("Reset Layout", systemImage: "arrow.counterclockwise.circle")
            }
            .id(refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            addReservationButton.id(refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { withAnimation { showInspector.toggle() } }) {
                Label("Toggle Inspector", systemImage: "info.circle")
            }
            .id(refreshID)
        }
    }
    
    private var addReservationButton: some View {
        Button {
            tableForNewReservation = nil
            showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(appState.selectedCategory == .noBookingZone)
        .foregroundColor(appState.selectedCategory == .noBookingZone ? .gray : .accentColor)
    }
}

// MARK: - Toolbar Buttons
extension LayoutView {
    private var dateBackward: some View {
        VStack {
            Text("-1 gg.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
    
                navigateToPreviousDate()
    
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    private var dateForward: some View {
        VStack {
            Text("+1 gg.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                navigateToNextDate()
    
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468")
                    )
                    .shadow(radius: 2)
            }
        }
    
    }
    
    private var timeForward: some View {
    
        VStack {
            Text("+15 min.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                navigateToNextTime()
    
            }) {
                Image(systemName: "15.arrow.trianglehead.clockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    private var timeBackward: some View {
    
        VStack {
            Text("-15 min.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                navigateToPreviousTime()
    
            }) {
                Image(systemName: "15.arrow.trianglehead.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    private var lunchButton: some View {
    
        VStack {
            Text("Pranzo")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                isManuallyOverridden = true
                let lunchTime = "12:00"
                let day = appState.selectedDate
                guard
                    let combinedTime = DateHelper.combineDateAndTime(
                        date: day, timeString: lunchTime)
                else { return }
                print("DEBUG: Returned combined date for new category: \(combinedTime)")
                withAnimation {
                    appState.selectedCategory = .lunch
                    appState.selectedDate = combinedTime
                }
            }) {
                Image(systemName: "sun.max.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    private var dinnerButton: some View {
    
        VStack {
            Text("Cena")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                isManuallyOverridden = true
                let dinnerTime = "18:00"
                let day = appState.selectedDate
                guard
                    let combinedTime = DateHelper.combineDateAndTime(
                        date: day, timeString: dinnerTime)
                else { return }
                withAnimation {
                    appState.selectedCategory = .dinner
                    appState.selectedDate = combinedTime
                }
            }) {
                Image(systemName: "moon.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
    }
    
    private var resetTime: some View {
    
        VStack {
            Text("Adesso")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
            // Reset to Default or System Time
            Button(action: {
                withAnimation {
                    let currentSystemTime = Date()  // Reset to system time
                    appState.selectedDate = DateHelper.combine(
                        date: appState.selectedDate, time: currentSystemTime)
                    print("Time reset to \(appState.selectedDate)")
                    isManuallyOverridden = false
                }
    
            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .opacity(
            DateHelper.compareTimes(
                firstTime: appState.selectedDate, secondTime: timerManager.currentDate, interval: 60
            )
                ? 0 : 1
        )
        .animation(.easeInOut, value: appState.selectedDate)
    }
    
    @ViewBuilder
    private func datePicker(selectedDate: Date) -> some View {
        VStack {
            Text("Data")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
    
            Button(action: {
                showingDatePicker = true
            }) {
                Image(systemName: "calendar.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .popover(isPresented: $showingDatePicker) {
            DatePickerView()
                .environmentObject(appState)
                .frame(width: 300, height: 350)  // Adjust as needed
    
        }
    
    }
    
    private var resetDate: some View {
        VStack {
            Text("Oggi")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                )
                .opacity(
                    Calendar.current.isDate(appState.selectedDate, inSameDayAs: systemTime) ? 0 : 1
                )
                .animation(.easeInOut, value: appState.selectedDate)
    
            Button(action: {
                withAnimation {
                    let today = Calendar.current.startOfDay(for: systemTime)  // Get today's date with no time component
                    guard let currentTimeOnly = DateHelper.extractTime(time: appState.selectedDate)
                    else {
                        return
                    }  // Extract time components
                    appState.selectedDate =
                        DateHelper.combinedInputTime(time: currentTimeOnly, date: today) ?? Date()
                    updateDatesAroundSelectedDate(appState.selectedDate)
                    isManuallyOverridden = false
                }
            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .opacity(Calendar.current.isDate(appState.selectedDate, inSameDayAs: systemTime) ? 0 : 1)
        .animation(.easeInOut, value: appState.selectedDate)
    }

}

// MARK: - Helper Methods & Date Navigation
extension LayoutView {
    private func debugCache() {
        if let cached = resCache.cache[appState.selectedDate] {
            for res in cached {
                print("DEBUG: reservation in cache \(res.name), start time: \(res.startTime), end time: \(res.endTime)")
            }
        } else {
            print("DEBUG: reservations in cache at \(appState.selectedDate): 0")
        }
    }
    
    private func toggleFullScreen() {
        withAnimation {
            appState.isFullScreen.toggle()
            columnVisibility = appState.isFullScreen ? .detailOnly : .all
        }
    }
    
    private func initializeView() {
        dates = generateInitialDates()
        print("Initialized with appState.selectedDate: \(appState.selectedDate), selectedCategory: \(appState.selectedCategory.localized)")
        clusterManager.loadClusters()
        resCache.startMonitoring(for: appState.selectedDate)
    }
    
    private func handleSelectedIndexChange() {
        if let newDate = dates[safe: selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            withAnimation { appState.selectedDate = combinedTime }
        }
        handleCurrentTimeChange(appState.selectedDate)
        print("Selected index changed to \(selectedIndex), date: \(DateHelper.formatFullDate(appState.selectedDate))")
        if selectedIndex >= dates.count - 5 { appendMoreDates() }
        if selectedIndex <= 5 { prependMoreDates() }
        trimDatesAround(selectedIndex)
    }
    
    private func handleSelectedCategoryChange(_ oldCategory: Reservation.ReservationCategory,
                                                _ newCategory: Reservation.ReservationCategory) {
        guard isManuallyOverridden, oldCategory != newCategory else { return }
        print("Old category: \(oldCategory.rawValue), New category: \(newCategory.rawValue)")
    }
    
    private func handleCurrentTimeChange(_ newTime: Date) {
        print("Time updated to \(newTime)")
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
    
    private func resetLayout() {
        let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())
        print("Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(appState.selectedCategory.localized)")
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        layoutServices.resetTables(for: currentDate, category: appState.selectedCategory)
        withAnimation {
            layoutServices.tables = layoutServices.loadTables(for: combinedDate, category: appState.selectedCategory)
        }
        clusterServices.resetClusters(for: combinedDate, category: appState.selectedCategory)
        clusterServices.saveClusters([], for: combinedDate, category: appState.selectedCategory)
        DispatchQueue.main.async {
            withAnimation {
                self.isLayoutLocked = true
                self.isLayoutReset = true
            }
            print("Layout successfully reset and reservations checked.")
        }
    }
    
    private func navigateToPreviousDate() {
        guard selectedIndex > 0 else { return }
        toolbarManager.navigationDirection = .backward
        selectedIndex -= 1
        if let newDate = dates[safe: selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            isManuallyOverridden = true
        }
    }
    
    private func navigateToNextDate() {
        guard selectedIndex < dates.count - 1 else { return }
        toolbarManager.navigationDirection = .forward
        selectedIndex += 1
        if let newDate = dates[safe: selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            isManuallyOverridden = true
        }
    }
    
    private func navigateToNextTime() {
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
                isManuallyOverridden = true
            }
        }
    }
    
    private func navigateToPreviousTime() {
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
                isManuallyOverridden = true
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
        guard let lastDate = dates.last else { return }
        let newDates = generateSequentialDates(from: lastDate, count: 5)
        dates.append(contentsOf: newDates)
        print("Appended more dates. Total dates: \(dates.count)")
    }
    
    private func prependMoreDates() {
        guard let firstDate = dates.first else { return }
        let newDates = generateSequentialDates(before: firstDate, count: 5)
        dates.insert(contentsOf: newDates, at: 0)
        selectedIndex += newDates.count
        print("Prepended more dates. Total dates: \(dates.count)")
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
    
    private func updateDatesAroundSelectedDate(_ newDate: Date) {
        if let newIndex = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
            withAnimation { selectedIndex = newIndex }
            handleSelectedIndexChange()
        } else {
            dates = generateDatesCenteredAround(newDate)
            if let newIndex = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
                withAnimation { selectedIndex = newIndex }
                handleSelectedIndexChange()
            }
        }
    }
    
    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else {
            return dates
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
        tableForNewReservation = table
        showingAddReservationSheet = true
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
        if dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(dates.count, index + bufferSize / 2)
            dates = Array(dates[startIndex..<endIndex])
            selectedIndex = index - startIndex
            print("Trimmed dates around index \(index). New selectedIndex: \(selectedIndex)")
        }
    }
}

// MARK: - Array Extension for Safe Indexing
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
