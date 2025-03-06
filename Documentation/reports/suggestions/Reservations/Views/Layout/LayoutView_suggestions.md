Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Layout/LayoutView.swift...
# Documentation Suggestions for LayoutView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Layout/LayoutView.swift
Total suggestions: 95

## Class Documentation (4)

### LayoutView (Line 7)

**Context:**

```swift
import UIKit
import OSLog

struct LayoutView: View {
    // MARK: - Private Properties
    static let logger = Logger(
        subsystem: "com.koenjiapp",
```

**Suggested Documentation:**

```swift
/// LayoutView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### LayoutView (Line 130)

**Context:**

```swift
}

// MARK: - Subviews
extension LayoutView {
    private var backgroundTapGestureView: some View {
        Color.clear
            .gesture(
```

**Suggested Documentation:**

```swift
/// LayoutView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### LayoutView (Line 239)

**Context:**

```swift
}

// MARK: - Helper Methods & Date Navigation
extension LayoutView {
    func debugCache() {
        if let cached = env.resCache.cache[appState.selectedDate] {
            for res in cached {
```

**Suggested Documentation:**

```swift
/// LayoutView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### Array (Line 480)

**Context:**

```swift
}

// MARK: - Array Extension for Safe Indexing
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
```

**Suggested Documentation:**

```swift
/// Array class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (24)

### additionalCanvasLayers (Line 155)

**Context:**

```swift
        .environment(unitView)
    }
    
    private func additionalCanvasLayers(in geometry: GeometryProxy) -> some View {
        Group {
            if unitView.scale <= 1 {
                PencilKitCanvas(
```

**Suggested Documentation:**

```swift
/// [Add a description of what the additionalCanvasLayers method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### toolbarOverlay (Line 177)

**Context:**

```swift
        }
    }
    
    private func toolbarOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            ToolbarExtended(geometry: geometry, toolbarState: $toolbarManager.toolbarState, small: false)
            toolbarContent(in: geometry, selectedDate: appState.selectedDate)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the toolbarOverlay method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### overlays (Line 192)

**Context:**

```swift
        .gesture(toolbarManager.toolbarGesture(geometry: geometry))
    }
    
    private func overlays(in geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottomLeading) {
            ToolbarMinimized()
                .opacity(!toolbarManager.isToolbarVisible && !unitView.isScribbleModeEnabled ? 1 : 0)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the overlays method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### debugCache (Line 240)

**Context:**

```swift

// MARK: - Helper Methods & Date Navigation
extension LayoutView {
    func debugCache() {
        if let cached = env.resCache.cache[appState.selectedDate] {
            for res in cached {
                Self.logger.debug("Reservation in cache: \(res.name), start time: \(res.startTime), end time: \(res.endTime)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the debugCache method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### toggleFullScreen (Line 250)

**Context:**

```swift
        }
    }
    
    func toggleFullScreen() {
    withAnimation {
        appState.isFullScreen.toggle()
        columnVisibility = appState.isFullScreen ? .detailOnly : .all
```

**Suggested Documentation:**

```swift
/// [Add a description of what the toggleFullScreen method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### initializeView (Line 257)

**Context:**

```swift
    }
}
    
    private func initializeView() {
        unitView.dates = generateInitialDates()
        Self.logger.info("Initialized with date: \(DateHelper.formatDate(appState.selectedDate)), category: \(appState.selectedCategory.localized)")
        clusterManager.loadClusters()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the initializeView method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleSelectedIndexChange (Line 264)

**Context:**

```swift
        env.resCache.startMonitoring(for: appState.selectedDate)
    }
    
    private func handleSelectedIndexChange() {
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            withAnimation { appState.selectedDate = combinedTime }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleSelectedIndexChange method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleSelectedCategoryChange (Line 276)

**Context:**

```swift
        trimDatesAround(unitView.selectedIndex)
    }
    
    private func handleSelectedCategoryChange(_ oldCategory: Reservation.ReservationCategory,
                                                _ newCategory: Reservation.ReservationCategory) {
        guard unitView.isManuallyOverridden, oldCategory != newCategory else { return }
        Self.logger.info("Category changed from \(oldCategory.rawValue) to \(newCategory.rawValue)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleSelectedCategoryChange method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleCurrentTimeChange (Line 282)

**Context:**

```swift
        Self.logger.info("Category changed from \(oldCategory.rawValue) to \(newCategory.rawValue)")
    }
    
    func handleCurrentTimeChange(_ newTime: Date) {
        Self.logger.debug("Time updated to \(DateHelper.formatFullDate(newTime))")
        withAnimation { appState.selectedDate = newTime }
        let calendar = Calendar.current
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleCurrentTimeChange method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### resetLayout (Line 301)

**Context:**

```swift
        withAnimation { appState.selectedCategory = determinedCategory }
    }
    
    func resetLayout() {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        Self.logger.notice("Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(appState.selectedCategory.localized)")
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the resetLayout method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### navigateToPreviousDate (Line 320)

**Context:**

```swift
        }
    }
    
    func navigateToPreviousDate() {
        guard unitView.selectedIndex > 0 else { return }
        toolbarManager.navigationDirection = .backward
        unitView.selectedIndex -= 1
```

**Suggested Documentation:**

```swift
/// [Add a description of what the navigateToPreviousDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### navigateToNextDate (Line 331)

**Context:**

```swift
        }
    }
    
    func navigateToNextDate() {
        guard unitView.selectedIndex < unitView.dates.count - 1 else { return }
        toolbarManager.navigationDirection = .forward
        unitView.selectedIndex += 1
```

**Suggested Documentation:**

```swift
/// [Add a description of what the navigateToNextDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### navigateToNextTime (Line 342)

**Context:**

```swift
        }
    }
    
    func navigateToNextTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let maxAllowedTime: Date?
```

**Suggested Documentation:**

```swift
/// [Add a description of what the navigateToNextTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### navigateToPreviousTime (Line 363)

**Context:**

```swift
        }
    }
    
    func navigateToPreviousTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let minAllowedTime: Date?
```

**Suggested Documentation:**

```swift
/// [Add a description of what the navigateToPreviousTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateInitialDates (Line 384)

**Context:**

```swift
        }
    }
    
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: appState.selectedDate)
        var dates = [Date]()
        for offset in -15...14 {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateInitialDates method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### appendMoreDates (Line 395)

**Context:**

```swift
        return dates
    }
    
    private func appendMoreDates() {
        guard let lastDate = unitView.dates.last else { return }
        let newDates = generateSequentialDates(from: lastDate, count: 5)
        unitView.dates.append(contentsOf: newDates)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the appendMoreDates method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### prependMoreDates (Line 402)

**Context:**

```swift
        Self.logger.debug("Appended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
    }
    
    private func prependMoreDates() {
        guard let firstDate = unitView.dates.first else { return }
        let newDates = generateSequentialDates(before: firstDate, count: 5)
        unitView.dates.insert(contentsOf: newDates, at: 0)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the prependMoreDates method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateSequentialDates (Line 410)

**Context:**

```swift
        Self.logger.debug("Prepended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
    }
    
    private func generateSequentialDates(from startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateSequentialDates method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateDatesAroundSelectedDate (Line 420)

**Context:**

```swift
        return dates
    }
    
    func updateDatesAroundSelectedDate(_ newDate: Date) {
    if let newIndex = unitView.dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
        withAnimation { unitView.selectedIndex = newIndex }
        handleSelectedIndexChange()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateDatesAroundSelectedDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateDatesCenteredAround (Line 433)

**Context:**

```swift
    }
}
    
    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else {
            return unitView.dates
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateDatesCenteredAround method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateSequentialDates (Line 441)

**Context:**

```swift
        return (0...(range * 2)).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }
    
    private func generateSequentialDates(before startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateSequentialDates method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleEmptyTableTap (Line 451)

**Context:**

```swift
        return dates
    }
    
    private func handleEmptyTableTap(for table: TableModel) {
        unitView.tableForNewReservation = table
        unitView.showingAddReservationSheet = true
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleEmptyTableTap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### adjustTime (Line 456)

**Context:**

```swift
        unitView.showingAddReservationSheet = true
    }
    
    private func adjustTime(for category: Reservation.ReservationCategory) {
        switch category {
        case .lunch:
            appState.selectedDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? appState.selectedDate
```

**Suggested Documentation:**

```swift
/// [Add a description of what the adjustTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### trimDatesAround (Line 467)

**Context:**

```swift
        }
    }
    
    private func trimDatesAround(_ index: Int) {
        let bufferSize = 30
        if unitView.dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the trimDatesAround method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (67)

### logger (Line 9)

**Context:**

```swift

struct LayoutView: View {
    // MARK: - Private Properties
    static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "LayoutView"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### env (Line 15)

**Context:**

```swift
    )

    // MARK: - Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState


```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 16)

**Context:**

```swift

    // MARK: - Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState


    @Environment(\.locale) var locale
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### locale (Line 19)

**Context:**

```swift
    @EnvironmentObject var appState: AppState


    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase
```

**Suggested Documentation:**

```swift
/// [Description of the locale property]
```

### horizontalSizeClass (Line 20)

**Context:**

```swift


    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

```

**Suggested Documentation:**

```swift
/// [Description of the horizontalSizeClass property]
```

### colorScheme (Line 21)

**Context:**

```swift

    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State, Bindings & Local Variables
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### scenePhase (Line 22)

**Context:**

```swift
    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State, Bindings & Local Variables
    @State var unitView = LayoutUnitViewModel()
```

**Suggested Documentation:**

```swift
/// [Description of the scenePhase property]
```

### unitView (Line 25)

**Context:**

```swift
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State, Bindings & Local Variables
    @State var unitView = LayoutUnitViewModel()
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### clusterManager (Line 26)

**Context:**

```swift

    // MARK: - State, Bindings & Local Variables
    @State var unitView = LayoutUnitViewModel()
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
    @StateObject var timerManager = TimerManager()
```

**Suggested Documentation:**

```swift
/// [Description of the clusterManager property]
```

### toolbarManager (Line 27)

**Context:**

```swift
    // MARK: - State, Bindings & Local Variables
    @State var unitView = LayoutUnitViewModel()
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
    @StateObject var timerManager = TimerManager()
    @State var layoutUI: LayoutUIManager
```

**Suggested Documentation:**

```swift
/// [Description of the toolbarManager property]
```

### currentDrawing (Line 28)

**Context:**

```swift
    @State var unitView = LayoutUnitViewModel()
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
    @StateObject var timerManager = TimerManager()
    @State var layoutUI: LayoutUIManager

```

**Suggested Documentation:**

```swift
/// [Description of the currentDrawing property]
```

### timerManager (Line 29)

**Context:**

```swift
    @State var clusterManager: ClusterManager
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
    @StateObject var timerManager = TimerManager()
    @State var layoutUI: LayoutUIManager


```

**Suggested Documentation:**

```swift
/// [Description of the timerManager property]
```

### layoutUI (Line 30)

**Context:**

```swift
    @State var toolbarManager = ToolbarStateManager()
    @StateObject var currentDrawing = DrawingModel()
    @StateObject var timerManager = TimerManager()
    @State var layoutUI: LayoutUIManager


    @Binding var selectedReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the layoutUI property]
```

### selectedReservation (Line 33)

**Context:**

```swift
    @State var layoutUI: LayoutUIManager


    @Binding var selectedReservation: Reservation?
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var isPhone: Bool {
```

**Suggested Documentation:**

```swift
/// [Description of the selectedReservation property]
```

### columnVisibility (Line 34)

**Context:**

```swift


    @Binding var selectedReservation: Reservation?
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```

### isPhone (Line 36)

**Context:**

```swift
    @Binding var selectedReservation: Reservation?
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the isPhone property]
```

### currentLayoutKey (Line 69)

**Context:**

```swift
    }

    // MARK: - Computed Properties
    var currentLayoutKey: String {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        return env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)
```

**Suggested Documentation:**

```swift
/// [Description of the currentLayoutKey property]
```

### currentDate (Line 70)

**Context:**

```swift

    // MARK: - Computed Properties
    var currentLayoutKey: String {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        return env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the currentDate property]
```

### combinedDate (Line 71)

**Context:**

```swift
    // MARK: - Computed Properties
    var currentLayoutKey: String {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        return env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)
    }

```

**Suggested Documentation:**

```swift
/// [Description of the combinedDate property]
```

### gridWidth (Line 75)

**Context:**

```swift
        return env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)
    }

    private var gridWidth: CGFloat {
        CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize
    }

```

**Suggested Documentation:**

```swift
/// [Description of the gridWidth property]
```

### gridHeight (Line 79)

**Context:**

```swift
        CGFloat(env.tableStore.totalColumns) * env.gridData.cellSize
    }

    private var gridHeight: CGFloat {
        CGFloat(env.tableStore.totalRows) * env.gridData.cellSize
    }

```

**Suggested Documentation:**

```swift
/// [Description of the gridHeight property]
```

### body (Line 84)

**Context:**

```swift
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundTapGestureView
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### backgroundTapGestureView (Line 131)

**Context:**

```swift

// MARK: - Subviews
extension LayoutView {
    private var backgroundTapGestureView: some View {
        Color.clear
            .gesture(
                TapGesture(count: 3)
```

**Suggested Documentation:**

```swift
/// [Description of the backgroundTapGestureView property]
```

### mainLayoutView (Line 144)

**Context:**

```swift
            )
    }
    
    private var mainLayoutView: some View {
        LayoutPageView(
            columnVisibility: $columnVisibility,
            selectedReservation: $selectedReservation
```

**Suggested Documentation:**

```swift
/// [Description of the mainLayoutView property]
```

### cached (Line 241)

**Context:**

```swift
// MARK: - Helper Methods & Date Navigation
extension LayoutView {
    func debugCache() {
        if let cached = env.resCache.cache[appState.selectedDate] {
            for res in cached {
                Self.logger.debug("Reservation in cache: \(res.name), start time: \(res.startTime), end time: \(res.endTime)")
            }
```

**Suggested Documentation:**

```swift
/// [Description of the cached property]
```

### newDate (Line 265)

**Context:**

```swift
    }
    
    private func handleSelectedIndexChange() {
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            withAnimation { appState.selectedDate = combinedTime }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the newDate property]
```

### combinedTime (Line 266)

**Context:**

```swift
    
    private func handleSelectedIndexChange() {
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            withAnimation { appState.selectedDate = combinedTime }
        }
        handleCurrentTimeChange(appState.selectedDate)
```

**Suggested Documentation:**

```swift
/// [Description of the combinedTime property]
```

### calendar (Line 285)

**Context:**

```swift
    func handleCurrentTimeChange(_ newTime: Date) {
        Self.logger.debug("Time updated to \(DateHelper.formatFullDate(newTime))")
        withAnimation { appState.selectedDate = newTime }
        let calendar = Calendar.current
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### lunchStart (Line 286)

**Context:**

```swift
        Self.logger.debug("Time updated to \(DateHelper.formatFullDate(newTime))")
        withAnimation { appState.selectedDate = newTime }
        let calendar = Calendar.current
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)!
```

**Suggested Documentation:**

```swift
/// [Description of the lunchStart property]
```

### lunchEnd (Line 287)

**Context:**

```swift
        withAnimation { appState.selectedDate = newTime }
        let calendar = Calendar.current
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)!
        let determinedCategory: Reservation.ReservationCategory
```

**Suggested Documentation:**

```swift
/// [Description of the lunchEnd property]
```

### dinnerStart (Line 288)

**Context:**

```swift
        let calendar = Calendar.current
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)!
        let determinedCategory: Reservation.ReservationCategory
        if appState.selectedDate >= lunchStart && appState.selectedDate <= lunchEnd {
```

**Suggested Documentation:**

```swift
/// [Description of the dinnerStart property]
```

### dinnerEnd (Line 289)

**Context:**

```swift
        let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)!
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)!
        let determinedCategory: Reservation.ReservationCategory
        if appState.selectedDate >= lunchStart && appState.selectedDate <= lunchEnd {
            determinedCategory = .lunch
```

**Suggested Documentation:**

```swift
/// [Description of the dinnerEnd property]
```

### determinedCategory (Line 290)

**Context:**

```swift
        let lunchEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: appState.selectedDate)!
        let dinnerEnd = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: appState.selectedDate)!
        let determinedCategory: Reservation.ReservationCategory
        if appState.selectedDate >= lunchStart && appState.selectedDate <= lunchEnd {
            determinedCategory = .lunch
        } else if appState.selectedDate >= dinnerStart && appState.selectedDate <= dinnerEnd {
```

**Suggested Documentation:**

```swift
/// [Description of the determinedCategory property]
```

### currentDate (Line 302)

**Context:**

```swift
    }
    
    func resetLayout() {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        Self.logger.notice("Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(appState.selectedCategory.localized)")
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        env.layoutServices.resetTables(for: currentDate, category: appState.selectedCategory)
```

**Suggested Documentation:**

```swift
/// [Description of the currentDate property]
```

### combinedDate (Line 304)

**Context:**

```swift
    func resetLayout() {
        let currentDate = Calendar.current.startOfDay(for: unitView.dates[safe: unitView.selectedIndex] ?? Date())
        Self.logger.notice("Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(appState.selectedCategory.localized)")
        let combinedDate = DateHelper.combine(date: currentDate, time: appState.selectedDate)
        env.layoutServices.resetTables(for: currentDate, category: appState.selectedCategory)
        withAnimation {
            env.layoutServices.tables = env.layoutServices.loadTables(for: combinedDate, category: appState.selectedCategory)
```

**Suggested Documentation:**

```swift
/// [Description of the combinedDate property]
```

### newDate (Line 324)

**Context:**

```swift
        guard unitView.selectedIndex > 0 else { return }
        toolbarManager.navigationDirection = .backward
        unitView.selectedIndex -= 1
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            unitView.isManuallyOverridden = true
```

**Suggested Documentation:**

```swift
/// [Description of the newDate property]
```

### combinedTime (Line 325)

**Context:**

```swift
        toolbarManager.navigationDirection = .backward
        unitView.selectedIndex -= 1
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            unitView.isManuallyOverridden = true
        }
```

**Suggested Documentation:**

```swift
/// [Description of the combinedTime property]
```

### newDate (Line 335)

**Context:**

```swift
        guard unitView.selectedIndex < unitView.dates.count - 1 else { return }
        toolbarManager.navigationDirection = .forward
        unitView.selectedIndex += 1
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            unitView.isManuallyOverridden = true
```

**Suggested Documentation:**

```swift
/// [Description of the newDate property]
```

### combinedTime (Line 336)

**Context:**

```swift
        toolbarManager.navigationDirection = .forward
        unitView.selectedIndex += 1
        if let newDate = unitView.dates[safe: unitView.selectedIndex],
           let combinedTime = DateHelper.normalizedTime(time: appState.selectedDate, date: newDate) {
            appState.selectedDate = combinedTime
            unitView.isManuallyOverridden = true
        }
```

**Suggested Documentation:**

```swift
/// [Description of the combinedTime property]
```

### calendar (Line 343)

**Context:**

```swift
    }
    
    func navigateToNextTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let maxAllowedTime: Date?
        switch appState.selectedCategory {
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### roundedDown (Line 344)

**Context:**

```swift
    
    func navigateToNextTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let maxAllowedTime: Date?
        switch appState.selectedCategory {
        case .lunch:
```

**Suggested Documentation:**

```swift
/// [Description of the roundedDown property]
```

### maxAllowedTime (Line 345)

**Context:**

```swift
    func navigateToNextTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let maxAllowedTime: Date?
        switch appState.selectedCategory {
        case .lunch:
            maxAllowedTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: appState.selectedDate)
```

**Suggested Documentation:**

```swift
/// [Description of the maxAllowedTime property]
```

### maxAllowedTime (Line 354)

**Context:**

```swift
        case .noBookingZone:
            return
        }
        if let maxAllowedTime = maxAllowedTime {
            let newTime = calendar.date(byAdding: .minute, value: 15, to: roundedDown)!
            if newTime <= maxAllowedTime {
                appState.selectedDate = newTime
```

**Suggested Documentation:**

```swift
/// [Description of the maxAllowedTime property]
```

### newTime (Line 355)

**Context:**

```swift
            return
        }
        if let maxAllowedTime = maxAllowedTime {
            let newTime = calendar.date(byAdding: .minute, value: 15, to: roundedDown)!
            if newTime <= maxAllowedTime {
                appState.selectedDate = newTime
                unitView.isManuallyOverridden = true
```

**Suggested Documentation:**

```swift
/// [Description of the newTime property]
```

### calendar (Line 364)

**Context:**

```swift
    }
    
    func navigateToPreviousTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let minAllowedTime: Date?
        switch appState.selectedCategory {
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### roundedDown (Line 365)

**Context:**

```swift
    
    func navigateToPreviousTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let minAllowedTime: Date?
        switch appState.selectedCategory {
        case .lunch:
```

**Suggested Documentation:**

```swift
/// [Description of the roundedDown property]
```

### minAllowedTime (Line 366)

**Context:**

```swift
    func navigateToPreviousTime() {
        let calendar = Calendar.current
        let roundedDown = calendar.roundedDownToNearest15(appState.selectedDate)
        let minAllowedTime: Date?
        switch appState.selectedCategory {
        case .lunch:
            minAllowedTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: appState.selectedDate)
```

**Suggested Documentation:**

```swift
/// [Description of the minAllowedTime property]
```

### minAllowedTime (Line 375)

**Context:**

```swift
        case .noBookingZone:
            return
        }
        if let minAllowedTime = minAllowedTime {
            let newTime = calendar.date(byAdding: .minute, value: -15, to: roundedDown)!
            if newTime >= minAllowedTime {
                appState.selectedDate = newTime
```

**Suggested Documentation:**

```swift
/// [Description of the minAllowedTime property]
```

### newTime (Line 376)

**Context:**

```swift
            return
        }
        if let minAllowedTime = minAllowedTime {
            let newTime = calendar.date(byAdding: .minute, value: -15, to: roundedDown)!
            if newTime >= minAllowedTime {
                appState.selectedDate = newTime
                unitView.isManuallyOverridden = true
```

**Suggested Documentation:**

```swift
/// [Description of the newTime property]
```

### today (Line 385)

**Context:**

```swift
    }
    
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: appState.selectedDate)
        var dates = [Date]()
        for offset in -15...14 {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: today) {
```

**Suggested Documentation:**

```swift
/// [Description of the today property]
```

### dates (Line 386)

**Context:**

```swift
    
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: appState.selectedDate)
        var dates = [Date]()
        for offset in -15...14 {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                dates.append(date)
```

**Suggested Documentation:**

```swift
/// [Description of the dates property]
```

### date (Line 388)

**Context:**

```swift
        let today = Calendar.current.startOfDay(for: appState.selectedDate)
        var dates = [Date]()
        for offset in -15...14 {
            if let date = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                dates.append(date)
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### lastDate (Line 396)

**Context:**

```swift
    }
    
    private func appendMoreDates() {
        guard let lastDate = unitView.dates.last else { return }
        let newDates = generateSequentialDates(from: lastDate, count: 5)
        unitView.dates.append(contentsOf: newDates)
        Self.logger.debug("Appended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
```

**Suggested Documentation:**

```swift
/// [Description of the lastDate property]
```

### newDates (Line 397)

**Context:**

```swift
    
    private func appendMoreDates() {
        guard let lastDate = unitView.dates.last else { return }
        let newDates = generateSequentialDates(from: lastDate, count: 5)
        unitView.dates.append(contentsOf: newDates)
        Self.logger.debug("Appended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
    }
```

**Suggested Documentation:**

```swift
/// [Description of the newDates property]
```

### firstDate (Line 403)

**Context:**

```swift
    }
    
    private func prependMoreDates() {
        guard let firstDate = unitView.dates.first else { return }
        let newDates = generateSequentialDates(before: firstDate, count: 5)
        unitView.dates.insert(contentsOf: newDates, at: 0)
        unitView.selectedIndex += newDates.count
```

**Suggested Documentation:**

```swift
/// [Description of the firstDate property]
```

### newDates (Line 404)

**Context:**

```swift
    
    private func prependMoreDates() {
        guard let firstDate = unitView.dates.first else { return }
        let newDates = generateSequentialDates(before: firstDate, count: 5)
        unitView.dates.insert(contentsOf: newDates, at: 0)
        unitView.selectedIndex += newDates.count
        Self.logger.debug("Prepended \(newDates.count) more dates. Total dates: \(unitView.dates.count)")
```

**Suggested Documentation:**

```swift
/// [Description of the newDates property]
```

### dates (Line 411)

**Context:**

```swift
    }
    
    private func generateSequentialDates(from startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
```

**Suggested Documentation:**

```swift
/// [Description of the dates property]
```

### date (Line 413)

**Context:**

```swift
    private func generateSequentialDates(from startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                dates.append(date)
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### newIndex (Line 421)

**Context:**

```swift
    }
    
    func updateDatesAroundSelectedDate(_ newDate: Date) {
    if let newIndex = unitView.dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
        withAnimation { unitView.selectedIndex = newIndex }
        handleSelectedIndexChange()
    } else {
```

**Suggested Documentation:**

```swift
/// [Description of the newIndex property]
```

### newIndex (Line 426)

**Context:**

```swift
        handleSelectedIndexChange()
    } else {
        unitView.dates = generateDatesCenteredAround(newDate)
        if let newIndex = unitView.dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
            withAnimation { unitView.selectedIndex = newIndex }
            handleSelectedIndexChange()
        }
```

**Suggested Documentation:**

```swift
/// [Description of the newIndex property]
```

### calendar (Line 434)

**Context:**

```swift
}
    
    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else {
            return unitView.dates
        }
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### startDate (Line 435)

**Context:**

```swift
    
    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else {
            return unitView.dates
        }
        return (0...(range * 2)).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### dates (Line 442)

**Context:**

```swift
    }
    
    private func generateSequentialDates(before startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) {
                dates.insert(date, at: 0)
```

**Suggested Documentation:**

```swift
/// [Description of the dates property]
```

### date (Line 444)

**Context:**

```swift
    private func generateSequentialDates(before startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) {
                dates.insert(date, at: 0)
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### bufferSize (Line 468)

**Context:**

```swift
    }
    
    private func trimDatesAround(_ index: Int) {
        let bufferSize = 30
        if unitView.dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(unitView.dates.count, index + bufferSize / 2)
```

**Suggested Documentation:**

```swift
/// [Description of the bufferSize property]
```

### startIndex (Line 470)

**Context:**

```swift
    private func trimDatesAround(_ index: Int) {
        let bufferSize = 30
        if unitView.dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(unitView.dates.count, index + bufferSize / 2)
            unitView.dates = Array(unitView.dates[startIndex..<endIndex])
            unitView.selectedIndex = index - startIndex
```

**Suggested Documentation:**

```swift
/// [Description of the startIndex property]
```

### endIndex (Line 471)

**Context:**

```swift
        let bufferSize = 30
        if unitView.dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(unitView.dates.count, index + bufferSize / 2)
            unitView.dates = Array(unitView.dates[startIndex..<endIndex])
            unitView.selectedIndex = index - startIndex
            Self.logger.debug("Trimmed dates around index \(index). New selectedIndex: \(unitView.selectedIndex)")
```

**Suggested Documentation:**

```swift
/// [Description of the endIndex property]
```


Total documentation suggestions: 95

