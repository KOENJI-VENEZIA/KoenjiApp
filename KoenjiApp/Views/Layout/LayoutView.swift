import SwiftUI

struct LayoutView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData
    
    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    // Dynamic Dates Array
    @State private var dates: [Date] = []
    @State private var selectedIndex: Int = 15 // Start in the middle of the dates array
    
    // Filters
    @State private var selectedCategory: Reservation.ReservationCategory? = .lunch
    
    // Time
    @State private var systemTime: Date = Date()
    @State private var currentTime: Date = Date()
    @State private var isManuallyOverridden: Bool = false
    @State private var showingTimePickerSheet: Bool = false
    
    // Reservation editing
    @State private var selectedReservation: Reservation? = nil
    @State private var showingEditReservation: Bool = false
    
    // Add Reservation
    @State private var showingAddReservationSheet: Bool = false
    @State private var tableForNewReservation: TableModel? = nil
    
    // Alerts and locks
    @State private var showingNoBookingAlert: Bool = false
    @State private var isLayoutLocked: Bool = true
    @State private var isZoomLocked: Bool = false
    @State private var showTopControls: Bool = true
    @State private var isLayoutReset: Bool = false
    
    // Zoom and pan state
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    @State private var clusters: [CachedCluster] = []

    
    // Navigation direction
        
        
    @State  var navigationDirection: NavigationDirection = .forward
    
    var onSidebarColorChange: ((Color) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let selectedDate = dates[safe: selectedIndex] ?? Date()
            
            ZStack {
            
                // Current Layout Page View
                LayoutPageView(
                    selectedDate: selectedDate,
                    selectedCategory: selectedCategory ?? .lunch,
                    currentTime: $currentTime,
                    isManuallyOverridden: $isManuallyOverridden,
                    showingTimePickerSheet: $showingTimePickerSheet,
                    selectedReservation: $selectedReservation,
                    showingEditReservation: $showingEditReservation,
                    showingAddReservationSheet: $showingAddReservationSheet,
                    tableForNewReservation: $tableForNewReservation,
                    showingNoBookingAlert: $showingNoBookingAlert,
                    isLayoutLocked: $isLayoutLocked,
                    isLayoutReset: $isLayoutReset,
                    scale: $scale,
                    offset: $offset,
                    clusters: clusters
                )
                .environmentObject(store)
                .environmentObject(reservationService)
                .environmentObject(gridData)
                .id(selectedIndex) // Force view refresh on index change
                //.matchedGeometryEffect(id: "layoutPageView\(selectedIndex)", in: animationNamespace) // Removed
                .transition(
                    .asymmetric(
                        insertion: navigationDirection == .forward
                        ? .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 1.5)) // Slides in from the center of the right edge
                            : .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 1.5)), // Slides in from the center of the left edge
                        removal: navigationDirection == .forward
                        ? .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.5)) // Slides out to the center of the left edge
                        : .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.5)) // Slides out to the center of the right edge
                    )
                )
                .animation(.easeInOut(duration: 0.7), value: navigationDirection)

                // Left Arrow Button
                if selectedIndex > 0 {
                    Button(action: {
                        withAnimation {
                            navigateToPreviousDate()
                        }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue.opacity(0.7))
                            .shadow(radius: 2)
                    }
                    .position(x: geometry.size.width * 0.05, y: geometry.size.height / 2)
                    .accessibilityLabel("Previous Date")
                }
                
                // Right Arrow Button
                if selectedIndex < dates.count - 1 {
                    Button(action: {
                        withAnimation {
                            navigateToNextDate()
                        }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue.opacity(0.7))
                            .shadow(radius: 2)
                    }
                    .position(x: geometry.size.width * 0.95, y: geometry.size.height / 2)
                    .accessibilityLabel("Next Date")
                }
            }
            .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)
            .ignoresSafeArea(.all, edges: .top)
            .safeAreaInset(edge: .top) {
                if showTopControls {
                    topControls
                        .background(Material.ultraThin)
                        .frame(height: isCompact ? 175 : 100)
                        .padding(.vertical, 0)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: showTopControls)
                        .offset(y: isCompact ? -10 : -1)
                }
            }
            .navigationTitle("Layout Tavoli")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Lock/Unlock Layout Button
                    Button(action: {
                        isLayoutLocked.toggle()
                        isZoomLocked.toggle()
                    }) {
                        Image(systemName: isLayoutLocked ? "lock.fill" : "lock.open.fill")
                    }
                    .accessibilityLabel(isLayoutLocked ? "Unlock Layout" : "Lock Layout")
                    
                    // Reset Layout Button
                    Button(action: {
                        resetLayout()
                    }) {
                        ZStack {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .foregroundColor(isLayoutReset
                                    ? (colorScheme == .light ? .gray : Color(hex: "#575757"))
                                    : .blue)
                            
                            if isLayoutReset {
                                Image(systemName: "slash.circle")
                                    .foregroundColor(Color(hex: "#575757"))
                            }
                        }
                    }
                    .accessibilityLabel("Reset Layout")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showTopControls.toggle()
                        }
                    }) {
                        Image(systemName: showTopControls ? "chevron.up" : "chevron.down")
                            .imageScale(.large)
                    }
                    .accessibilityLabel(showTopControls ? "Hide Controls" : "Show Controls")
                }
            }
            .sheet(item: $selectedReservation) { reservation in
                EditReservationView(reservation: reservation)
                    .environmentObject(store)
                    .environmentObject(reservationService)
            }
            .sheet(isPresented: $showingAddReservationSheet) {
                AddReservationView()
                    .environmentObject(store)
                    .environmentObject(reservationService)
            }
            .alert(isPresented: $showingNoBookingAlert) {
                Alert(
                    title: Text("Attenzione!"),
                    message: Text("Impossibile inserire prenotazioni fuori da orario pranzo o cena."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                initializeView()

            }
            .onChange(of: selectedIndex) { newIndex in
                handleSelectedIndexChange()
            }
            .onChange(of: selectedCategory) { newCategory in
                handleSelectedCategoryChange(newCategory)
            }
            .onChange(of: currentTime) { newTime in
                
                
                
                handleCurrentTimeChange(newTime)
                
                
            }
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)
    }
    
    // MARK: - Navigation Methods
    
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
    
    private func resetLayout() {
        // Ensure the selected date and category are valid
        if let currentCategory = selectedCategory {
            let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())
            store.resetTables(for: currentDate, category: currentCategory)
            store.resetClusters(for: currentDate, category: currentCategory)
            isLayoutLocked = true
            isLayoutReset = true
            store.tables = store.loadTables(for: currentDate, category: currentCategory)
            clusters = store.loadClusters(for: currentDate, category: currentCategory)
            checkActiveReservations(for: currentDate, category: currentCategory, from: "resetLayout() in LayoutView")
            print("Layout reset for date: \(DateHelper.formatFullDate(currentDate)) and category: \(currentCategory.rawValue)")
        }
    }
    
    private func initializeView() {
        // Initialize default date/time configuration
        if !isManuallyOverridden {
            currentTime = defaultTimeForCategory(selectedCategory ?? .lunch)
        }
        
        // Generate date array
        dates = generateInitialDates()
        
        print("Initialized with currentTime: \(currentTime), selectedCategory: \(selectedCategory?.rawValue ?? "None")")
        
        // Set initial sidebar color based on selectedCategory
        if let initialCategory = selectedCategory {
            onSidebarColorChange?(initialCategory.sidebarColor)
        }
        
        // Load tables for the initial date and category
        if let initialDate = dates[safe: selectedIndex],
           let currentCategory = selectedCategory {
            store.initializeLayoutIfNeeded(for: initialDate, category: currentCategory)
            checkActiveReservations(for: initialDate, category: currentCategory, from: "initializeView() from LayoutView")
            print("Loaded tables for \(currentCategory.rawValue) on \(DateHelper.formatFullDate(initialDate))")
        }
    }
    
    private func updateClusters(for date: Date, category: Reservation.ReservationCategory) {
        DispatchQueue.global(qos: .userInitiated).async {
            let newClusters = store.loadClusters(for: date, category: category)
            DispatchQueue.main.async {
                self.clusters = newClusters
            }
        }
    }
    
    private func handleSelectedIndexChange() {
        
        // Explicitly set and log current time
        let newDate = dates[safe: selectedIndex] ?? Date()
        currentTime = DateHelper.prepareCombinedDate(date: newDate, with: currentTime)

        
        print("Selected index changed to \(selectedIndex), date: \(DateHelper.formatFullDate(newDate))")

        
        // Load tables for the new date
        if let currentCategory = selectedCategory {
            print("Loaded tables for \(currentCategory.rawValue) on \(DateHelper.formatFullDate(newDate))")
            checkActiveReservations(for: newDate, category: currentCategory, from: "handleSelectedIndexChange() from LayoutView")
            
            // Check if the layout for the current date and category matches the base tables
            let key = store.keyFor(date: newDate, category: currentCategory)
            if let currentTables = store.cachedLayouts[key] {
                isLayoutReset = (currentTables == store.baseTables)
                print("Layout is reset: \(isLayoutReset)")
            } else {
                isLayoutReset = false
                print("Layout is not reset.")
            }
        }
        
        // Handle progressive date loading
        if selectedIndex >= dates.count - 5 { appendMoreDates() }
        if selectedIndex <= 5 { prependMoreDates() }
        trimDatesAround(selectedIndex)
    }
    
    private func handleSelectedCategoryChange(_ newCategory: Reservation.ReservationCategory?) {
        guard let newCategory = newCategory else { return }
        
        print("Category changed to \(newCategory.rawValue)")
        
        // Only adjust time if it's not manually overridden
        
        currentTime = defaultTimeForCategory(newCategory)
        print("Adjusted time for category to: \(currentTime)")
        
        
        // Update reservations and layout for the current selected date
        let newDate = dates[safe: selectedIndex] ?? Date()
        currentTime = DateHelper.prepareCombinedDate(date: newDate, with: currentTime)

        checkActiveReservations(for: newDate, category: newCategory, from: "handleSelectedCategoryChange() in LayoutView")
        print("Loaded tables for \(newCategory.rawValue) on \(DateHelper.formatFullDate(newDate))")
        
        // Update sidebar color
        onSidebarColorChange?(newCategory.sidebarColor)
    }
    
    private func handleCurrentTimeChange(_ newTime: Date) {
        print("Time updated to \(newTime)")

        // Combine selectedDate with the new time
        let currentDate = dates[safe: selectedIndex] ?? Date()
        currentTime = DateHelper.prepareCombinedDate(date: currentDate, with: newTime)

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
        if newTime >= lunchStart && newTime <= lunchEnd {
            determinedCategory = .lunch
        } else if newTime >= dinnerStart && newTime <= dinnerEnd {
            determinedCategory = .dinner
        } else {
            determinedCategory = .noBookingZone
        }
            
            selectedCategory = determinedCategory
        

        // Check active reservations using the determined category
        checkActiveReservations(for: currentDate, category: selectedCategory ?? .lunch, from: "handleCurrentTimeChange in LayoutView")

        // Update selectedCategory after checking reservations
        
    }
    
    // MARK: - Helper Methods
    
    private var topControls: some View {
        HStack {
            if horizontalSizeClass == .compact {
                // Compact layout
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        datePicker
                        categoryPicker
                    }
                    HStack(spacing: 8) {
                        timePicker
                            .frame(maxWidth: .infinity, alignment: .leading)
                        addReservationButton
                            .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
            } else {
                // Wide layout
                HStack {
                    datePicker
                    categoryPicker
                    Spacer()
                    timePicker
                    Spacer()
                    addReservationButton
                }
            }
        }
        .padding()
        .clipped()
    }
     
    private var datePicker: some View {
        VStack(alignment: .leading) {
            Text("Seleziona Giorno")
                .font(.caption)
            DatePicker(
                "",
                selection: Binding(
                    get: { dates[safe: selectedIndex] ?? Date() },
                    set: { newDate in
                        
                        updateDatesAroundSelectedDate(newDate)
                    }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .frame(height: 44)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading) {
            Text("Categoria")
                .font(.caption)
            Picker("Categoria", selection: $selectedCategory) {
                Text("Pranzo").tag(Reservation.ReservationCategory?.some(.lunch))
                Text("Cena").tag(Reservation.ReservationCategory?.some(.dinner))
            }
            .pickerStyle(.segmented)
            .frame(width: 200, height: 44)
            .onChange(of: selectedCategory) { newCategory in
                if let newCategory = newCategory {
                    onSidebarColorChange?(newCategory.sidebarColor)
                }
            }
        }
    }

    private var timePicker: some View {
        VStack(alignment: .leading) {
            Text("Orario")
                .font(.caption)
            HStack(alignment: .center, spacing: 8) {
                // Time Picker
                DatePicker(
                    "Scegli orario",
                    selection: Binding(
                        get: { currentTime },
                        set: { newTime in
                            currentTime = newTime
                            isManuallyOverridden = true // Mark as manually overridden
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                
                // Reset to Default or System Time
                Button("Torna all'ora corrente") {
                    withAnimation {
                        currentTime = systemTime // Reset to system time
                        isManuallyOverridden = false
                    }
                }
                .font(.caption)
                .opacity(isManuallyOverridden ? 1 : 0)
                .animation(.easeInOut, value: isManuallyOverridden)
            }
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
        .disabled(selectedCategory == .noBookingZone)
        .foregroundColor(selectedCategory == .noBookingZone ? .gray : .blue)
    }
    
    private func preloadDataForAdjacentDates(currentIndex: Int) {
        let preloadRange = max(0, currentIndex - 2)...min(dates.count - 1, currentIndex + 2)
        for index in preloadRange {
            let date = dates[index]
            if let currentCategory = selectedCategory {
                store.initializeLayoutIfNeeded(for: date, category: currentCategory)
            }
        }
    }
    
    /// Generates the initial set of dates centered around today.
    private func generateInitialDates() -> [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        var dates = [Date]()
        let range = -15...14 // 15 days before and 14 days after today
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
        selectedIndex += newDates.count // Adjust the selected index to account for prepended dates
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
        if let newIndex = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
            withAnimation {
                selectedIndex = newIndex
            }
            handleSelectedIndexChange()
        } else {
            // Regenerate the dates array centered around the newDate
            dates = generateDatesCenteredAround(newDate)
            if let newIndex = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
                withAnimation {
                    selectedIndex = newIndex
                }
                handleSelectedIndexChange()
            }
        }
    }
    
    private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate) else { return dates }
        return (0...(range * 2)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }
    }
    
    /// Generates a list of sequential dates before a given date.
    private func generateSequentialDates(before startDate: Date, count: Int) -> [Date] {
        var dates = [Date]()
        for i in 1...count {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: startDate) {
                dates.insert(date, at: 0) // Insert at the beginning
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
            currentTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? currentTime
        case .dinner:
            currentTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? currentTime
        case .noBookingZone:
            break
        }
    }
    
    func checkActiveReservations(for date: Date, category: Reservation.ReservationCategory, from context: String) {
        print("checkActiveReservations invoked from \(context) for date: \(DateHelper.formatFullDate(date)) and category: \(category.rawValue)")

        let combinedDate = DateHelper.prepareCombinedDate(date: date, with: currentTime)


        guard let tables = store.cachedLayouts[store.keyFor(date: date, category: category)] else {
            print("No cached layout for key: \(store.keyFor(date: date, category: category)).")
            return
        }

        let reservations = tables.compactMap { table in
            reservationService.findActiveReservation(for: table, date: date, time: combinedDate)
        }

        DispatchQueue.main.async {
            self.store.activeReservations = Array(Set(reservations))
            print("Updated active reservations for \(DateHelper.formatFullDate(date)) with count: \(self.store.activeReservations.count)")
        }
    }
    
    private func trimDatesAround(_ index: Int) {
        let bufferSize = 30 // Total number of dates to keep
        if dates.count > bufferSize {
            let startIndex = max(0, index - bufferSize / 2)
            let endIndex = min(dates.count, index + bufferSize / 2)
            dates = Array(dates[startIndex..<endIndex])
            selectedIndex = index - startIndex // Adjust index relative to the trimmed array
            print("Trimmed dates around index \(index). New selectedIndex: \(selectedIndex)")
        }
    }
    
    private func defaultTimeForCategory(_ category: Reservation.ReservationCategory) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: systemTime)
        switch category {
        case .lunch:
            components.hour = 12
            components.minute = 0
        case .dinner:
            components.hour = 18
            components.minute = 0
        case .noBookingZone:
            components.hour = 16
            components.minute = 0
        }
        return Calendar.current.date(from: components) ?? systemTime
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

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

extension AnyTransition {
    static func slideFromSide(navigationDirection: NavigationDirection) -> AnyTransition {
        AnyTransition.modifier(
            active: SlideFromSideModifier(offset: navigationDirection == .forward ? CGSize(width: UIScreen.main.bounds.width, height: 0) : CGSize(width: -UIScreen.main.bounds.width, height: 0)),
            identity: SlideFromSideModifier(offset: .zero)
        )
    }
}

struct SlideFromSideModifier: ViewModifier {
    let offset: CGSize

    func body(content: Content) -> some View {
        content.offset(offset)
    }
}

enum NavigationDirection {
    case forward
    case backward
}
