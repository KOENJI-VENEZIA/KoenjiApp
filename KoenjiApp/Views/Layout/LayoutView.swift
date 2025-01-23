import PencilKit
import SwiftUI
import UIKit
import ScreenshotSwiftUI

struct LayoutView: View {
    @EnvironmentObject var store: ReservationStore
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

    // Dynamic Arrays
    @State private var dates: [Date] = []
    @State private var selectedIndex: Int = 15  // Start in the middle of the dates array
    @State private var selectedDate: Date = Date()
    @State var activeReservations: [Reservation] = []

    // Filters
    @Binding var selectedCategory: Reservation.ReservationCategory?

    // Time
    @State private var systemTime: Date = Date()
    @StateObject private var timerManager = TimerManager()
    @State private var currentTime: Date = Date()
    @State private var isManuallyOverridden: Bool = false

    // Reservation editing
    @Binding var selectedReservation: Reservation?
    @Binding var currentReservation: Reservation?

    @State private var showingEditReservation: Bool = false
    @State private var showInspector: Bool = false  // Controls Inspector visibility
    @State private var showingDatePicker: Bool = false
    @State private var changedReservation: Reservation? = nil

    // Add Reservation
    @State private var showingAddReservationSheet: Bool = false
    @State private var tableForNewReservation: TableModel? = nil

    // Alerts and locks
    @State private var showingNoBookingAlert: Bool = false
    @State private var isLayoutLocked: Bool = true
    @State private var isZoomLocked: Bool = false
    @State private var isLayoutReset: Bool = false

    // Sidebar Color

    @State var navigationDirection: NavigationDirection = .forward

    // Toolbar
    @State private var toolbarState: ToolbarState = .pinnedLeft
    @State private var dragAmount: CGPoint? = nil
    @State private var initialOverlayOffset: CGSize? = nil
    @State private var sideDragOffset: CGFloat = 0
    @State private var bottomDragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isToolbarVisible: Bool = true
    @State private var lastPinnedPosition: CGPoint = .zero
    @State private var overlayOrientation: OverlayOrientation = .horizontal
    var lastPinnedSide: ToolbarState = .pinnedLeft  // track last pinned

    // Drawing mode
    @State private var isScribbleModeEnabled: Bool = false
    @State private var drawings: [String: PKDrawing] = [:]
    @StateObject private var currentDrawing = DrawingModel()
    @StateObject private var zoomableState = ZoomableScrollViewState()
    @State private var toolPickerShows = false
    @StateObject var sharedToolPicker = SharedToolPicker()
    
    @State private var capturedImage: UIImage? = nil
    @State private var cachedScreenshot: ScreenshotMaker?

    
    @State private var isSharing: Bool = false
    @State private var isPresented: Bool = false

    
    @Environment(\.scenePhase) private var scenePhase
    @State var refreshID = UUID()

    @State private var scale: CGFloat = 1

    var body: some View {
        
        GeometryReader { geometry in

            ZStack {
                
                CardSwapView(
                    selectedIndex: $selectedIndex, navigationDirection: navigationDirection
                ) {
                    LayoutPageView(
                        scale: $scale,
                        selectedDate: selectedDate,
                        selectedCategory: selectedCategory ?? .lunch,
                        currentTime: $currentTime,
                        isManuallyOverridden: $isManuallyOverridden,
                        selectedReservation: $selectedReservation,
                        changedReservation: $changedReservation,
                        showInspector: $showInspector,
                        showingEditReservation: $showingEditReservation,
                        showingAddReservationSheet: $showingAddReservationSheet,
                        tableForNewReservation: $tableForNewReservation,
                        isLayoutLocked: $isLayoutLocked,
                        isLayoutReset: $isLayoutReset,
                        isScribbleModeEnabled: $isScribbleModeEnabled,
                        toolPickerShows: $toolPickerShows,
                        isSharing: $isSharing,
                        isPresented: $isPresented,
                        cachedScreenshot: $cachedScreenshot,
                        onFetchedReservations: { newActiveReservations in
                            activeReservations = newActiveReservations
                        }
                    )
                    .environmentObject(store)
                    .environmentObject(tableStore)
                    .environmentObject(reservationService)  // For the new service
                    .environmentObject(clusterServices)
                    .environmentObject(layoutServices)
                    .environmentObject(gridData)
                    .environmentObject(scribbleService)
                    .environmentObject(currentDrawing)
                    .environmentObject(sharedToolPicker)
                    .id(selectedIndex)  // Force view refresh on index change
                }
                
                if scale <= 1 {
                    PencilKitCanvas(
                        zoomableState: zoomableState,
                        toolPickerShows: $toolPickerShows,
                        layer: .layer1,
                        gridWidth: nil,
                        gridHeight: nil,
                        canvasSize: nil,
                        isEditable: isScribbleModeEnabled
                    )
                    .environmentObject(currentDrawing)
                    .environmentObject(sharedToolPicker)
                    .frame(width: abs(geometry.size.width - gridWidth), height: geometry.size.height)
                    .position(x: geometry.size.width, y: geometry.size.height / 2)
                    
                    PencilKitCanvas(
                        zoomableState: zoomableState,
                        toolPickerShows: $toolPickerShows,
                        layer: .layer3,
                        gridWidth: nil,
                        gridHeight: nil,
                        canvasSize: nil,
                        isEditable: isScribbleModeEnabled
                    )
                    .environmentObject(currentDrawing)
                    .environmentObject(sharedToolPicker)
                    .frame(width: abs(geometry.size.width - gridWidth), height: geometry.size.height)
                    .position(x: 0, y: geometry.size.height / 2)
                }
                
                
                if !isScribbleModeEnabled {
                    if isToolbarVisible {
                        ZStack {
                            // MARK: Background (RoundedRectangle)
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .frame(
                                    width: toolbarState != .pinnedBottom
                                    ? 80  // 20% of the available width (you can tweak the factor)
                                    : geometry.size.width * 0.9,  // 90% of the available width when pinned bottom
                                    height: toolbarState != .pinnedBottom
                                    ? geometry.size.height * 0.9  // 90% of the available height when vertical
                                    : 80  // 15% of the available height when horizontal
                                )
                                .scaleEffect(toolbarState == .overlay ? 1.25 : 1.0, anchor: .center)
                                .opacity(toolbarState == .overlay ? 0.5 : 1.0)
                            
                            // MARK: Toolbar Content
                            toolbarContent(in: geometry, selectedDate: $selectedDate)
                        }
                        .ignoresSafeArea(.keyboard)
                        .position(
                            isDragging
                            ? dragAmount ?? calculatePosition(geometry: geometry)
                            : calculatePosition(geometry: geometry)
                        )
                        .animation(isDragging ? .none : .spring(), value: isDragging)
                        .transition(transitionForCurrentState(geometry: geometry))
                        .gesture(
                            toolbarGesture(in: geometry)
                        )
                        
                    } else {
                        // 2) Show a handle if hidden, positioned based on the last pinned side
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(
                                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                                )
                                .frame(width: 50, height: 50)
                        }
                        .ignoresSafeArea(.keyboard)
                        .position(
                            isDragging
                            ? dragAmount ?? calculatePosition(geometry: geometry)
                            : calculatePosition(geometry: geometry)
                        )  // depends on pinned side
                        .animation(isDragging ? .none : .spring(), value: isDragging)
                        .transition(transitionForCurrentState(geometry: geometry))
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    withAnimation {
                                        isToolbarVisible = true
                                    }
                                }
                        )
                        .simultaneousGesture(
                            toolbarGesture(in: geometry)
                        )
                    }
                }
                
                if isPresented && !isSharing {
                    VisualEffectView(effect: UIBlurEffect(style: .dark))
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)  // Fade in/out transition

                }
                
                if isSharing {
                    VisualEffectView(effect: UIBlurEffect(style: .dark))
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)  // Fade in/out transition

                }

            }
            .environmentObject(sharedToolPicker)
            .ignoresSafeArea(edges: .bottom)  // Ignore only the bottom safe area
            .navigationTitle("Layout Tavoli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button(action: {
                        withAnimation {
                            isPresented.toggle()
                        }
                    }) {
                        Label("Share Layout", systemImage: "square.and.arrow.up")
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            isScribbleModeEnabled.toggle()
                            toolPickerShows.toggle()
                        }
                    }) {
                        Label(
                            isScribbleModeEnabled ? "Exit Scribble Mode" : "Enable Scribble",
                            systemImage: isScribbleModeEnabled ? "pencil.slash" : "pencil"
                        )
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Lock/Unlock Layout Button
                    Button(action: {
                        isLayoutLocked.toggle()
                        isZoomLocked.toggle()
                    }) {
                        Label(isLayoutLocked ? "Unlock Layout" : "Lock Layout", systemImage: isLayoutLocked ? "lock.fill" : "lock.open.fill")
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Reset Layout Button
                    Button(action: {
                        resetLayout()
                    }) {
                            Label("Reset Layout", systemImage: "arrow.counterclockwise.circle")
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addReservationButton
                        .id(refreshID)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showInspector.toggle()
                        }
                    }) {
                        Label("Toggle Inspector", systemImage: "info.circle")
                    }
                    .id(refreshID)
                }
            }
            .inspector(isPresented: $showInspector) {  // Show Inspector if a reservation is selected
                InspectorSideView(
                    selectedReservation: $selectedReservation,
                    currentReservation: $currentReservation,
                    showInspector: $showInspector,
                    showingEditReservation: $showingEditReservation,
                    sidebarColor: $appState.sidebarColor,
                    changedReservation: $changedReservation,
                    activeReservations: activeReservations,
                    currentTime: $currentTime,
                    selectedCategory: selectedCategory ?? .lunch
                )
            }
            .sheet(item: $currentReservation) { reservation in
                EditReservationView(
                    reservation: reservation,
                    onClose: {
                        showingEditReservation = false
                    }
                )
                .environmentObject(store)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
            }
            .sheet(isPresented: $showingAddReservationSheet) {
                AddReservationView(
                    category: $selectedCategory,
                    selectedDate: Binding<Date>(
                        get: {
                            // Force-unwrap or handle out-of-range more gracefully
                            dates[selectedIndex]
                        },
                        set: { newVal in
                            // Update the array in the parent
                            dates[selectedIndex] = newVal
                        }
                    ),
                    startTime: $currentTime,
                    passedTable: tableForNewReservation
                )
                .environmentObject(store)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
            }
            .sheet(isPresented: $isPresented) {
                ShareModal(cachedScreenshot: cachedScreenshot, isPresented: $isPresented, isSharing: $isSharing)

            }
            .onAppear {
                initializeView()
                print("Current time as LayoutView appears: \(currentTime)")
            }
            .onChange(of: scenePhase) { _, newPhase in
                refreshID = UUID()
            }
            .onChange(of: selectedIndex) {
                handleSelectedIndexChange()
            }
            .onChange(of: selectedCategory) { oldCategory, newCategory in
                handleSelectedCategoryChange(oldCategory, newCategory)
                print(
                    "Called handleSelectedCategoryChange() from LayoutView [onChange of selectedCategory]"
                )
                if let category = newCategory {
                    appState.sidebarColor = category.sidebarColor
                }
            }
            .onChange(of: currentTime) { oldTime, newTime in
                handleCurrentTimeChange(newTime)
            }
            .onChange(of: showInspector) { oldValue, newValue in
                if !newValue {
                    selectedReservation = nil
                }
            }
            .onChange(of: selectedDate) { old, newDate in
                // This is your existing logic to handle expansions
                updateDatesAroundSelectedDate(newDate)
            }
            .onChange(of: isScribbleModeEnabled) {
                DispatchQueue.main.async {
                    saveScribbleForCurrentLayout()
                }
            }
            .onReceive(timerManager.$currentDate) { newTime in
                if !isManuallyOverridden {

                    let combinedTime = DateHelper.combine(date: currentTime, time: newTime)
                    currentTime = combinedTime
                }
            }
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .ignoresSafeArea(.keyboard)

    }

    var customShareLinkButton: some View {
        Button {
            isSharing.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                presentShareLink()
            }
        } label: {
            Label("share", systemImage: "square.and.arrow.up")
        }
    }
    
    func presentShareLink() {
        
        
        guard let image = capturedImage else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        scene?.keyWindow?.rootViewController?.present(vc, animated: true)
    }

    var currentLayoutKey: String {
        let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())
        let combinedDate = DateHelper.combine(date: currentDate, time: currentTime)
        return layoutServices.keyFor(date: combinedDate, category: selectedCategory ?? .lunch)
    }

    private var gridWidth: CGFloat {
        CGFloat(store.totalColumns) * gridData.cellSize
    }

    private var gridHeight: CGFloat {
        CGFloat(store.totalRows) * gridData.cellSize
    }

    func saveScribbleForCurrentLayout() {
        print("Generated currentLayoutKey: \(currentLayoutKey)")
        
        scribbleService.saveDrawing(currentDrawing.layer1, for: currentLayoutKey, layer: "layer1")
        scribbleService.saveDrawing(currentDrawing.layer2, for: currentLayoutKey, layer: "layer2")
        scribbleService.saveDrawing(currentDrawing.layer3, for: currentLayoutKey, layer: "layer3")

        print("Scribbles saved successfully for key: \(currentLayoutKey)")
    }

    private func transitionForCurrentState(geometry: GeometryProxy) -> AnyTransition {
        switch toolbarState {
        case .overlay:
            // No special transition on overlay
            return .opacity
        case .pinnedLeft:
            return .move(edge: .leading)
        case .pinnedRight:
            return .move(edge: .trailing)
        case .pinnedBottom:
            return .move(edge: .bottom)
        }
    }

    // MARK: - Toolbar Content
    @ViewBuilder
    private func toolbarContent(in geometry: GeometryProxy, selectedDate: Binding<Date>)
        -> some View
    {
        switch toolbarState {
        case .pinnedLeft, .pinnedRight:
            // Vertical layout:
            VStack(spacing: 25) {
                resetDate
                timeBackward
                dateBackward
                lunchButton
                datePicker(selectedDate: selectedDate)
                dinnerButton
                dateForward
                timeForward
                resetTime
            }

        case .pinnedBottom:
            // Horizontal layout:
            HStack(spacing: 25) {
                resetDate
                timeBackward
                dateBackward
                lunchButton
                datePicker(selectedDate: selectedDate)
                dinnerButton
                dateForward
                timeForward
                resetTime

            }

        case .overlay:
            // *Decide* if you want a vertical or horizontal layout
            // depending on the user’s drag or your thresholds.
            // If you want to replicate “vertical if near sides, horizontal if near bottom,”
            // you can do a quick check on overlayOffset.
            switch overlayOrientation {
            case .horizontal:
                // Horizontal
                HStack(spacing: 25) {
                    dateForward
                    lunchButton
                    dinnerButton
                    dateBackward
                    timeBackward
                    timeForward
                    resetTime
                }

            case .vertical:
                // Vertical
                VStack(spacing: 25) {
                    dateForward
                    lunchButton
                    dinnerButton
                    dateBackward
                    timeBackward
                    timeForward
                    resetTime
                }
            }
        }
    }

    private func toolbarGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in

                isDragging = true

                var currentLocation = value.location
                let currentOffset = value.translation

                if toolbarState != .pinnedBottom {
                    currentLocation.y = (geometry.size.height / 2) + currentOffset.height

                } else {
                    currentLocation.x = (geometry.size.height / 2) + currentOffset.width
                }

                dragAmount = currentLocation

            }
            .onEnded { value in
                var currentLocation = value.location
                let currentOffset = value.translation

                if toolbarState == .pinnedBottom {
                    if currentOffset.height > 0 {
                        withAnimation {
                            isToolbarVisible = false
                        }
                    }
                } else if toolbarState == .pinnedLeft {
                    if currentOffset.width < 0 {
                        withAnimation {
                            isToolbarVisible = false
                        }
                    }
                } else if toolbarState == .pinnedRight {
                    if currentOffset.width > 0 {
                        withAnimation {
                            isToolbarVisible = false
                        }
                    }
                }

                if currentLocation.y > geometry.size.height / 2 && currentOffset.height > 0
                    && (currentLocation.x > geometry.size.width / 2 && currentOffset.width < 0
                        || currentLocation.x < geometry.size.width / 2 && currentOffset.width > 0)
                {
                    withAnimation {
                        toolbarState = .pinnedBottom
                    }
                } else if currentLocation.x < geometry.size.width / 2 && currentOffset.width < 0
                    && currentOffset.height < 0
                {
                    toolbarState = .pinnedLeft
                } else if currentLocation.x > geometry.size.width / 2 && currentOffset.width > 0
                    && currentOffset.height < 0
                {
                    toolbarState = .pinnedRight
                }

                print("ToolbarState: \(toolbarState)")

                if toolbarState == .pinnedLeft {
                    currentLocation.x = 60
                    currentLocation.y = geometry.size.height / 2
                    withAnimation {
                        dragAmount = currentLocation
                    }
                } else if toolbarState == .pinnedRight {
                    currentLocation.x = geometry.size.width - 60
                    currentLocation.y = geometry.size.height / 2
                    withAnimation {
                        dragAmount = currentLocation
                    }
                } else if toolbarState == .pinnedBottom {
                    currentLocation.x = geometry.size.width / 2
                    currentLocation.y = geometry.size.height - 30
                    withAnimation {
                        dragAmount = currentLocation
                    }
                }

                isDragging = false
            }
    }

    private func calculatePosition(geometry: GeometryProxy) -> CGPoint {
        if toolbarState == .pinnedLeft {
            return CGPoint(x: 90, y: geometry.size.height / 2)
        } else if toolbarState == .pinnedRight {
            return CGPoint(x: geometry.size.width - 90, y: geometry.size.height / 2)
        } else if toolbarState == .pinnedBottom {
            return CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 90)
        } else {
            return lastPinnedPosition
        }
    }

    struct CardSwapView<Content: View>: View {
        @Binding var selectedIndex: Int
        let navigationDirection: NavigationDirection
        let content: () -> Content

        @State private var rotationAngle: Double = 0

        var body: some View {
            ZStack {
                content()
                    .id(selectedIndex)  // Ensure content refresh
                    .flipEffect(
                        rotation: rotationAngle,
                        axis: navigationDirection == .backward
                            ? (x: 0, y: -30, z: 0) : (x: 0, y: 30, z: 0))
            }
            .onChange(of: selectedIndex) {
                // Animate flip out
                withAnimation(.spring(duration: 0.3)) {
                    rotationAngle = 15
                }
                // Swap content once half-flipped (after animation delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(duration: 0.5)) {
                        rotationAngle = 0
                    }
                }
            }
        }
    }

    private func navigateToPreviousDate() {
        guard selectedIndex > 0 else { return }
        navigationDirection = .backward
        selectedIndex -= 1
        handleSelectedIndexChange()
    }

    private func navigateToNextDate() {
        guard selectedIndex < dates.count - 1 else { return }
        navigationDirection = .forward
        selectedIndex += 1
        handleSelectedIndexChange()

    }

    private func navigateToNextTime() {
        let calendar = Calendar.current

        // 1) Round down to nearest 15-min boundary
        let roundedDown = calendar.roundedDownToNearest15(currentTime)
        // 2) From that boundary, add 15 minutes
        let newTime = calendar.date(byAdding: .minute, value: 15, to: roundedDown)!

        currentTime = newTime
        isManuallyOverridden = true
    }

    private func navigateToPreviousTime() {
        let calendar = Calendar.current

        // 1) Round down to nearest 15-min boundary
        let roundedDown = calendar.roundedDownToNearest15(currentTime)
        // 2) From that boundary, subtract 15 minutes
        let newTime = calendar.date(byAdding: .minute, value: -15, to: roundedDown)!

        currentTime = newTime
        isManuallyOverridden = true
    }

    private func resetLayout() {
        // Ensure the selected date and category are valid
        guard let currentCategory = selectedCategory else {
            print("Invalid category for reset.")
            return
        }

        let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())

        print(
            "Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(currentCategory.rawValue)"
        )

        // Perform layout reset
        let combinedDate = DateHelper.combine(date: currentDate, time: currentTime)
        layoutServices.resetTables(for: currentDate, category: currentCategory)
        layoutServices.tables = layoutServices.loadTables(
            for: combinedDate, category: currentCategory)

        // Clear clusters
        clusterServices.resetClusters(for: combinedDate, category: currentCategory)
        clusterServices.saveClusters([], for: combinedDate, category: currentCategory)

        // Ensure layout flags are updated after reset completes
        DispatchQueue.main.async {
            self.isLayoutLocked = true
            self.isLayoutReset = true
            print("Layout successfully reset and reservations checked.")
        }
    }

    private func initializeView() {
        // Initialize default date/time configuration
        currentTime = Date()

//        loadScribbleForCurrentLayout()
        // Generate date array
        dates = generateInitialDates()

        if let defaultDate = dates[safe: selectedIndex] {
            selectedDate = defaultDate
        } else {
            selectedDate = Date()
        }

        print(
            "Initialized with currentTime: \(currentTime), selectedCategory: \(selectedCategory?.rawValue ?? "None")"
        )

        // Set initial sidebar color based on selectedCategory
        if let initialCategory = selectedCategory {
            appState.sidebarColor = initialCategory.sidebarColor
        }

        handleCurrentTimeChange(currentTime)

    }

    private func handleSelectedIndexChange() {

        // Explicitly set and log current time
        if let newDate = dates[safe: selectedIndex],
            let combinedTime = DateHelper.normalizedTime(time: currentTime, date: newDate)
        {
            selectedDate = newDate
            currentTime = combinedTime

        }

        print(
            "Selected index changed to \(selectedIndex), date: \(DateHelper.formatFullDate(selectedDate))"
        )

        // Handle progressive date loading
        if selectedIndex >= dates.count - 5 { appendMoreDates() }
        if selectedIndex <= 5 { prependMoreDates() }
        trimDatesAround(selectedIndex)
    }

    private func handleSelectedCategoryChange(
        _ oldCategory: Reservation.ReservationCategory?,
        _ newCategory: Reservation.ReservationCategory?
    ) {
        guard let newCategory = newCategory else { return }
        guard let oldCategory = oldCategory else { return }
        guard oldCategory != newCategory else { return }
        print("Old category: \(oldCategory.rawValue)")
        print("Category changed to \(newCategory.rawValue)")

        // Only adjust time if it's not manually overridden
        currentTime = defaultTimeForCategory(newCategory)
        print("Adjusted time for category to: \(currentTime)")

        // Update reservations and layout for the current selected date
        let newDate = dates[safe: selectedIndex] ?? Date()
        guard let combinedTime = DateHelper.normalizedTime(time: currentTime, date: newDate) else {
            return
        }
        currentTime = combinedTime

        // checkActiveReservations(for: newDate, category: newCategory, from: "handleSelectedCategoryChange() in LayoutView")
        print("Loaded tables for \(newCategory.rawValue) on \(DateHelper.formatFullDate(newDate))")

        // Update sidebar color
        appState.sidebarColor = newCategory.sidebarColor
    }

    private func handleCurrentTimeChange(_ newTime: Date) {
        print("Time updated to \(newTime)")

        // Combine selectedDate with the new time
        let currentDate = dates[safe: selectedIndex] ?? Date()
        guard let combinedTime = DateHelper.normalizedTime(time: newTime, date: currentDate) else {
            return
        }
        currentTime = combinedTime

        print("Final currentTime after combination: \(currentTime)")

        // Mark as manually overridden

        // Determine the appropriate category based on time
        let calendar = Calendar.current

        // Define time ranges
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: currentDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: currentDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: currentDate)!

        // Compare newTime against the ranges
        let determinedCategory: Reservation.ReservationCategory
        if currentTime >= lunchStart && currentTime <= lunchEnd {
            determinedCategory = .lunch
        } else if currentTime >= dinnerStart && currentTime <= dinnerEnd {
            determinedCategory = .dinner
        } else {
            determinedCategory = .noBookingZone
        }

        selectedCategory = determinedCategory
    }

    // MARK: - Helper Methods

    private var dateBackward: some View {

        Button(action: {

            navigateToPreviousDate()

        }) {
            Image(systemName: "chevron.left.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                .foregroundColor(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468"))
                .shadow(radius: 2)
        }
    }

    private var dateForward: some View {

        Button(action: {
            navigateToNextDate()

        }) {
            Image(systemName: "chevron.right.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                .foregroundColor(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468"))
                .shadow(radius: 2)
        }

    }

    private var timeForward: some View {

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

    private var timeBackward: some View {

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

    private var lunchButton: some View {

        Button(action: {
            isManuallyOverridden = true
            selectedCategory = .lunch
            let lunchTime = "12:00"
            let day = currentTime
            guard let combinedTime = DateHelper.combineDateAndTime(date: day, timeString: lunchTime)
            else { return }
            currentTime = combinedTime
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

    private var dinnerButton: some View {

        Button(action: {
            isManuallyOverridden = true
            selectedCategory = .dinner
            let dinnerTime = "18:00"
            let day = currentTime
            guard
                let combinedTime = DateHelper.combineDateAndTime(date: day, timeString: dinnerTime)
            else { return }
            currentTime = combinedTime
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

    private var resetTime: some View {

        // Reset to Default or System Time
        Button(action: {
            withAnimation {
                let currentSystemTime = Date()  // Reset to system time
                currentTime = DateHelper.combine(date: currentTime, time: currentSystemTime)
                print("Time reset to \(currentTime)")
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
        .opacity(
            DateHelper.compareTimes(
                firstTime: currentTime, secondTime: timerManager.currentDate, interval: 60)
                ? 0 : 1
        )
        .animation(.easeInOut, value: currentTime)
    }

    @ViewBuilder
    private func datePicker(selectedDate: Binding<Date>) -> some View {

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
        .popover(isPresented: $showingDatePicker) {
            DatePickerView(
                selectedDate: selectedDate
            )
            .frame(width: 300, height: 350)  // Adjust as needed

        }

    }

    private var resetDate: some View {
        Button(action: {
            withAnimation {
                let today = Calendar.current.startOfDay(for: systemTime)  // Get today's date with no time component
                guard let currentTimeOnly = DateHelper.extractTime(time: currentTime) else {
                    return
                }  // Extract time components
                currentTime =
                    DateHelper.normalizedInputTime(time: currentTimeOnly, date: today) ?? Date()
                updateDatesAroundSelectedDate(currentTime)
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
        .opacity(Calendar.current.isDate(currentTime, inSameDayAs: systemTime) ? 0 : 1)
        .animation(.easeInOut, value: currentTime)
    }

    private var addReservationButton: some View {
        Button {
            tableForNewReservation = nil
            showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(selectedCategory == .noBookingZone)
        .foregroundColor(selectedCategory == .noBookingZone ? .gray : .accentColor)
    }

    /// Generates the initial set of dates centered around today.
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        var dates = [Date]()
        let range = -15...14  // 15 days before and 14 days after today
        for offset in range {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                dates.append(date)
            }
        }
        return dates
    }

    /// Appends more dates to the end of the dates array.
    private func appendMoreDates() {
        guard let lastDate = dates.last else { return }
        let newDates = generateSequentialDates(from: lastDate, count: 5)
        dates.append(contentsOf: newDates)
        print("Appended more dates. Total dates: \(dates.count)")
    }

    /// Prepends more dates to the beginning of the dates array.
    private func prependMoreDates() {
        guard let firstDate = dates.first else { return }
        let newDates = generateSequentialDates(before: firstDate, count: 5)
        dates.insert(contentsOf: newDates, at: 0)
        selectedIndex += newDates.count  // Adjust the selected index to account for prepended dates
        print("Prepended more dates. Total dates: \(dates.count)")
    }

    /// Generates a list of sequential dates starting from a given date.
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
        // If newDate is in the array, pick that index
        if let newIndex = dates.firstIndex(where: {
            Calendar.current.isDate($0, inSameDayAs: newDate)
        }) {
            withAnimation {
                selectedIndex = newIndex
            }
            // Possibly call handleSelectedIndexChange
            handleSelectedIndexChange()
        } else {
            // Re-generate the array around newDate
            dates = generateDatesCenteredAround(newDate)
            // Now find the newIndex
            if let newIndex = dates.firstIndex(where: {
                Calendar.current.isDate($0, inSameDayAs: newDate)
            }) {
                withAnimation {
                    selectedIndex = newIndex
                }
                handleSelectedIndexChange()
            }
        }
    }

    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else {
            return dates
        }
        return (0...(range * 2)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }
    }

    /// Generates a list of sequential dates before a given date.
    private func generateSequentialDates(before startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) {
                dates.insert(date, at: 0)  // Insert at the beginning
            }
        }
        return dates
    }

    /// Handles tapping an empty table to add a reservation.
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }

    private func adjustTime(for category: Reservation.ReservationCategory) {
        switch category {
        case .lunch:
            currentTime =
                Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                ?? currentTime
        case .dinner:
            currentTime =
                Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())
                ?? currentTime
        case .noBookingZone:
            break
        }
    }

    private func trimDatesAround(_ index: Int) {
        let bufferSize = 30  // Total number of dates to keep
        if dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(dates.count, index + bufferSize / 2)
            dates = Array(dates[startIndex..<endIndex])
            selectedIndex = index - startIndex  // Adjust index relative to the trimmed array
            print("Trimmed dates around index \(index). New selectedIndex: \(selectedIndex)")
        }
    }

    private func defaultTimeForCategory(_ category: Reservation.ReservationCategory) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: systemTime)
        switch category {
        case .lunch:
            components.hour = 12
            components.minute = 0
            return Calendar.current.date(from: components) ?? systemTime
        case .dinner:
            components.hour = 18
            components.minute = 0
            return Calendar.current.date(from: components) ?? systemTime
        case .noBookingZone:
            return systemTime
        }
    }

}

// MARK: - Extensions

extension Date {
    func toDate(on date: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        return calendar.date(byAdding: components, to: date)
    }
}

extension Array {
    /// Safely returns the element at the given index, if it exists.
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

enum NavigationDirection {
    case forward
    case backward
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
