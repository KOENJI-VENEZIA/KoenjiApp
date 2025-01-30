import PencilKit
import ScreenshotSwiftUI
import SwiftUI
import UIKit

struct LayoutView: View {
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

    @State var clusterManager: ClusterManager
    
    @State var toolbarManager = ToolbarStateManager()
    @StateObject private var currentDrawing = DrawingModel()
    @StateObject private var zoomableState = ZoomableScrollViewState()
    @StateObject private var timerManager = TimerManager()

    @State private var dates: [Date] = []
    @State private var selectedIndex: Int = 15  // Start in the middle of the dates array

    // Time
    @State private var systemTime: Date = Date()

    // Reservation editing
    @Binding var selectedReservation: Reservation?
    @Binding var currentReservation: Reservation?
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    @State private var isManuallyOverridden: Bool = false
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

    // Drawing mode
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
    



    init(
        appState: AppState,
        clusterServices: ClusterServices,
        layoutServices: LayoutServices,
        resCache: CurrentReservationsCache,
        selectedReservation: Binding<Reservation?>,
        currentReservation: Binding<Reservation?>,
        columnVisibility: Binding<NavigationSplitViewVisibility>
    ) {
        
        self._selectedReservation = selectedReservation
        self._currentReservation = currentReservation
        self._columnVisibility = columnVisibility
        
        _clusterManager = State(
            initialValue: ClusterManager(
                clusterServices: clusterServices, layoutServices: layoutServices,
                resCache: resCache,
                date: appState.selectedDate,
                category: appState.selectedCategory
            )
        )
        
    }
    
    // MARK: - Computed variables
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
    
    var body: some View {

        GeometryReader { geometry in

            ZStack {
                
                
                
//                CardSwapView(
//                        selectedIndex: $selectedIndex,
//                        navigationDirection: toolbarManager.navigationDirection,
//                        rotationAngle: $appState.rotationAngle,  // Pass as binding
//                        isContentReady: $appState.isContentReady  // Track content readiness
//                    ) {
                    LayoutPageView(
                        selectedIndex: $selectedIndex,
                        columnVisibility: $columnVisibility,
                        scale: $scale,
                        selectedDate: appState.selectedDate,
                        selectedCategory: appState.selectedCategory,
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
                        cachedScreenshot: $cachedScreenshot
                    )
                    .environment(clusterManager)
                    .environmentObject(store)
                    .environmentObject(appState)
                    .environmentObject(resCache)
                    .environmentObject(tableStore)
                    .environmentObject(reservationService)  // For the new service
                    .environmentObject(clusterServices)
                    .environmentObject(layoutServices)
                    .environmentObject(gridData)
                    .environmentObject(scribbleService)
                    .environmentObject(currentDrawing)
                    .id(selectedIndex)  // Force view refresh on index change
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: selectedIndex)

//                }
                
//                .animation(.easeInOut(duration: 0.3), value: appState.isFullScreen)
                .gesture(
                    TapGesture(count: 2) // Double-tap to exit full-screen
                        .onEnded {
                                withAnimation {
                                    appState.isFullScreen.toggle()
                                    if appState.isFullScreen {
                                        columnVisibility = .detailOnly
                                    } else {
                                        columnVisibility = .all
                                    }
                            }
                        }
                )

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
                    .frame(
                        width: abs(geometry.size.width - gridWidth), height: geometry.size.height
                    )
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
                    .frame(
                        width: abs(geometry.size.width - gridWidth), height: geometry.size.height
                    )
                    .position(x: 0, y: geometry.size.height / 2)
                }

                ZStack {
                    ToolbarExtended(geometry: geometry, toolbarState: $toolbarManager.toolbarState)

                    // MARK: Toolbar Content
                    toolbarContent(in: geometry, selectedDate: appState.selectedDate)
                }
                .opacity(toolbarManager.isToolbarVisible && !isScribbleModeEnabled ? 1 : 0)
                .ignoresSafeArea(.keyboard)
                .position(
                    toolbarManager.isDragging
                    ? toolbarManager.dragAmount
                    : toolbarManager.calculatePosition(geometry: geometry)
                )
                .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
                .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
                .gesture(
                    toolbarManager.toolbarGesture(geometry: geometry)
                )

                ToolbarMinimized()
                    .opacity(!toolbarManager.isToolbarVisible && !isScribbleModeEnabled ? 1 : 0)
                    .ignoresSafeArea(.keyboard)
                    .position(
                        toolbarManager.isDragging
                        ? toolbarManager.dragAmount
                        : toolbarManager.calculatePosition(geometry: geometry)
                    )  // depends on pinned side
                    .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
                    .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
                    .gesture(
                        TapGesture()
                            .onEnded {
                                withAnimation {
                                    toolbarManager.isToolbarVisible = true
                                }
                            }
                    )
                    .simultaneousGesture(
                        toolbarManager.toolbarGesture(geometry: geometry)
                    )

                VisualEffectView(effect: UIBlurEffect(style: .dark))
                    .opacity(isPresented ? (isSharing ? 0.0 : 1.0) : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isPresented)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)  // Fade in/out transition

                VisualEffectView(effect: UIBlurEffect(style: .dark))
                    .opacity(isSharing ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isSharing)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)  // Fade in/out transition

                LoadingOverlay()
                    .opacity(appState.isWritingToFirebase ? 1.0 : 0.0)  // Smoothly fade in and out
                    .animation(.easeInOut(duration: 0.3), value: appState.isWritingToFirebase)
                    .allowsHitTesting(appState.isWritingToFirebase)  // Disable interaction when invisible
                
                LockOverlay(isLayoutLocked: isLayoutLocked)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.04)
                    .animation(.easeInOut(duration: 0.3), value: isLayoutLocked)

            }
            .ignoresSafeArea(edges: .bottom)  // Ignore only the bottom safe area
            .navigationTitle("Layout Tavoli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation {
                            appState.isFullScreen.toggle()
                            if appState.isFullScreen {
                                columnVisibility = .detailOnly
                            } else {
                                columnVisibility = .all
                            }
                        }
                    }) {
                        Label("Toggle Full Screen", systemImage: appState.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        debugCache()
                    }) {
                        Label("Debug Cache", systemImage: "ladybug.slash.fill")
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .topBarLeading) {

                    Button(action: {
                        withAnimation {
                            isPresented.toggle()
                        }
                    }) {
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
                        Label(
                            isScribbleModeEnabled ? "Exit Scribble Mode" : "Enable Scribble",
                            systemImage: isScribbleModeEnabled ? "pencil.slash" : "pencil"
                        )
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // Lock/Unlock Layout Button
                    Button(action: {
                        withAnimation {
                            isLayoutLocked.toggle()
                        }
                        isZoomLocked.toggle()
                    }) {
                        Label(
                            isLayoutLocked ? "Unlock Layout" : "Lock Layout",
                            systemImage: isLayoutLocked ? "lock.fill" : "lock.open.fill")
                    }
                    .tint(isLayoutLocked ? .red : .accentColor)
                    .id(refreshID)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // Reset Layout Button
                    Button(action: {
                        resetLayout()
                    }) {
                        Label("Reset Layout", systemImage: "arrow.counterclockwise.circle")
                    }
                    .id(refreshID)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    addReservationButton
                        .id(refreshID)
                }
                ToolbarItem(placement: .topBarTrailing) {
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
            .sheet(isPresented: $showInspector) {  // Show Inspector if a reservation is selected
                InspectorSideView(
                    selectedReservation: $selectedReservation,
                    currentReservation: $currentReservation,
                    showInspector: $showInspector,
                    showingEditReservation: $showingEditReservation,
                    changedReservation: $changedReservation,
                    isShowingFullImage: $isShowingFullImage
                )
                .environmentObject(resCache)
                .environmentObject(appState)
                .environmentObject(store)
                .environmentObject(reservationService)
                .environmentObject(layoutServices)
                .presentationBackground(.thinMaterial)
            }
            .sheet(item: $currentReservation) { reservation in
                EditReservationView(
                    reservation: reservation,
                    onClose: {
                        showingEditReservation = false
                    }
                )
                .environmentObject(store)
                .environmentObject(resCache)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
                .presentationBackground(.thinMaterial)
            }
            .sheet(isPresented: $showingAddReservationSheet) {
                AddReservationView(
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
                    passedTable: tableForNewReservation
                )
                .environmentObject(store)
                .environmentObject(appState)
                .environmentObject(resCache)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
                .presentationBackground(.thinMaterial)
            }
            .sheet(isPresented: $isPresented) {
                ShareModal(
                    cachedScreenshot: cachedScreenshot, isPresented: $isPresented,
                    isSharing: $isSharing)

            }
            .onAppear {
                initializeView()
                print("Current time as LayoutView appears: \(appState.selectedDate)")
            }
            .onChange(of: scenePhase) { _, newPhase in
                refreshID = UUID()
            }
            .onChange(of: selectedIndex) {
                handleSelectedIndexChange()
            }
            .onChange(of: appState.selectedCategory) { oldCategory, newCategory in
                handleSelectedCategoryChange(oldCategory, newCategory)
            }
            .onChange(of: appState.selectedDate) { oldTime, newTime in
                handleCurrentTimeChange(newTime)
                updateDatesAroundSelectedDate(newTime)
            }
            .onChange(of: showInspector) { oldValue, newValue in
                if !newValue {
                    selectedReservation = nil
                }
            }
            .onChange(of: isScribbleModeEnabled) {
                DispatchQueue.main.async {
                    scribbleService.saveScribbleForCurrentLayout(currentDrawing, currentLayoutKey)
                }
            }
            .onReceive(timerManager.$currentDate) { newTime in
                if !isManuallyOverridden {
                    systemTime = newTime
                }
            }
//            .toolbarBackground(Material.ultraThin, for: .navigationBar)
//            .toolbarBackground(.visible, for: .navigationBar)
        }
        .ignoresSafeArea(.keyboard)

    }

    // MARK: - Helper Views
    
    
    
    // Toolbar Views
    @ViewBuilder
    private func toolbarContent(in geometry: GeometryProxy, selectedDate: Date)
        -> some View
    {
        switch toolbarManager.toolbarState {
        case .pinnedLeft, .pinnedRight:
            // Vertical layout:
            VStack {

                resetDate
                    .padding(.bottom, 2)
                    .padding(.top, 2)
                dateBackward
                    .padding(.bottom, 2)
                dateForward
                    .padding(.bottom, 2)
                datePicker(selectedDate: selectedDate)
                    .padding(.bottom, 2)
                resetTime
                    .padding(.bottom, 2)
                timeBackward
                    .padding(.bottom, 2)
                timeForward
                    .padding(.bottom, 2)
                lunchButton
                    .padding(.bottom, 2)
                dinnerButton
                    .padding(.bottom, 2)
            }

        case .pinnedBottom:
            // Horizontal layout:
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
                appState.selectedCategory = .lunch
                let lunchTime = "12:00"
                let day = appState.selectedDate
                guard
                    let combinedTime = DateHelper.combineDateAndTime(
                        date: day, timeString: lunchTime)
                else { return }
                appState.selectedDate = combinedTime
                //            currentTime = combinedTime
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
                appState.selectedCategory = .dinner
                let dinnerTime = "18:00"
                let day = appState.selectedDate
                guard
                    let combinedTime = DateHelper.combineDateAndTime(
                        date: day, timeString: dinnerTime)
                else { return }
                appState.selectedDate = combinedTime
                //            currentTime = combinedTime
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
                    //                currentTime = DateHelper.combine(date: currentTime, time: currentSystemTime)
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

    func debugCache() {
        if let currentCachedRes = resCache.cache[appState.selectedDate] {
            for res in currentCachedRes {
                print(
                    "DEBUG: reservation in cache \(res.name), start time: \(res.startTime), end time: \(res.endTime)"
                )
            }
        } else {
            print("DEBUG: reservations in cache at \(appState.selectedDate): 0")
        }
    }

    func presentShareLink() {

        guard let image = capturedImage else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        let scene =
            UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive }
            as? UIWindowScene
        scene?.keyWindow?.rootViewController?.present(vc, animated: true)
    }


    // MARK: - View Specific Methods
    private func initializeView() {

        dates = generateInitialDates()

        print(
            "Initialized with appState.selectedDate: \(appState.selectedDate), selectedCategory: \(appState.selectedCategory.localized)"
        )

        clusterManager.loadClusters()
        resCache.startMonitoring(for: appState.selectedDate)
    }

    private func handleSelectedIndexChange() {

        // Explicitly set and log current time
        if let newDate = dates[safe: selectedIndex],
            let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate)
        {
            appState.selectedDate = combinedTime
            //            currentTime = combinedTime

        }

        handleCurrentTimeChange(appState.selectedDate)

        print(
            "Selected index changed to \(selectedIndex), date: \(DateHelper.formatFullDate(appState.selectedDate))"
        )

        // Handle progressive date loading
        if selectedIndex >= dates.count - 5 { appendMoreDates() }
        if selectedIndex <= 5 { prependMoreDates() }
        trimDatesAround(selectedIndex)
    }

    private func handleSelectedCategoryChange(
        _ oldCategory: Reservation.ReservationCategory,
        _ newCategory: Reservation.ReservationCategory
    ) {
        guard isManuallyOverridden else { return }
        guard oldCategory != newCategory else { return }
        print("Old category: \(oldCategory.rawValue)")
        print("Category changed to \(newCategory.rawValue)")
    }

    private func handleCurrentTimeChange(_ newTime: Date) {
        print("Time updated to \(newTime)")

        appState.selectedDate = newTime
        // Combine selectedDate with the new time
        let currentDate = appState.selectedDate

        // Determine the appropriate category based on time
        let calendar = Calendar.current

        // Define time ranges
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: currentDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: currentDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: currentDate)!

        // Compare newTime against the ranges
        let determinedCategory: Reservation.ReservationCategory
        if appState.selectedDate >= lunchStart && appState.selectedDate <= lunchEnd {
            determinedCategory = .lunch
        } else if appState.selectedDate >= dinnerStart && appState.selectedDate <= dinnerEnd {
            determinedCategory = .dinner
        } else {
            determinedCategory = .noBookingZone
        }

        appState.selectedCategory = determinedCategory
    }
    
    private func resetLayout() {
        // Ensure the selected date and category are valid

        let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())

        print(
            "Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(appState.selectedCategory.localized)"
        )

        // Perform layout reset
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        layoutServices.resetTables(for: currentDate, category: appState.selectedCategory)
        layoutServices.tables = layoutServices.loadTables(
            for: combinedDate, category: appState.selectedCategory)

        // Clear clusters
        clusterServices.resetClusters(for: combinedDate, category: appState.selectedCategory)
        clusterServices.saveClusters([], for: combinedDate, category: appState.selectedCategory)

        // Ensure layout flags are updated after reset completes
        DispatchQueue.main.async {
            withAnimation {
                self.isLayoutLocked = true
                self.isLayoutReset = true
            }
            print("Layout successfully reset and reservations checked.")
        }
    }

    // MARK: - Dates and Time methods

    private func navigateToPreviousDate() {
        guard selectedIndex > 0 else { return }
        toolbarManager.navigationDirection = .backward
        selectedIndex -= 1
        if let newDate = dates[safe: selectedIndex],
            let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate)
        {
            appState.selectedDate = combinedTime
        }
    }

    private func navigateToNextDate() {
        guard selectedIndex < dates.count - 1 else { return }
        toolbarManager.navigationDirection = .forward
        selectedIndex += 1
        if let newDate = dates[safe: selectedIndex],
            let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate)
        {
            appState.selectedDate = combinedTime
        }

    }

    private func navigateToNextTime() {
        let calendar = Calendar.current

        // 1) Round down to nearest 15-min boundary
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        // 2) From that boundary, add 15 minutes
        let newTime = calendar.date(byAdding: .minute, value: 15, to: roundedDown)!

        appState.selectedDate = newTime
        //        currentTime = newTime
        isManuallyOverridden = true
    }

    private func navigateToPreviousTime() {
        let calendar = Calendar.current

        // 1) Round down to nearest 15-min boundary
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        // 2) From that boundary, subtract 15 minutes
        let newTime = calendar.date(byAdding: .minute, value: -15, to: roundedDown)!

        appState.selectedDate = newTime
        //        currentTime = newTime
        isManuallyOverridden = true
    }

    /// Generates the initial set of dates centered around today.
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: appState.selectedDate)
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
            appState.selectedDate =
                Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                ?? appState.selectedDate
        case .dinner:
            appState.selectedDate =
                Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())
                ?? appState.selectedDate
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
