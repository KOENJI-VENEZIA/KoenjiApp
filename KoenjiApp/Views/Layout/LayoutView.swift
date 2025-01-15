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
    @Binding  var selectedCategory: Reservation.ReservationCategory?
    
    // Time
    @State private var systemTime: Date = Date()
    @State private var systemDate: Date = Date()
    var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var currentTime: Date = Date()
    @State private var isManuallyOverridden: Bool = false
    @State private var showingTimePickerSheet: Bool = false
    @State private var isInitialized: Bool = false

    
    // Reservation editing
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?

    @State private var showingEditReservation: Bool = false
    @Binding  var showInspector: Bool      // Controls Inspector visibility

    // Add Reservation
    @State private var showingAddReservationSheet: Bool = false
    @State private var tableForNewReservation: TableModel? = nil
    
    // Alerts and locks
    @State private var showingNoBookingAlert: Bool = false
    @State private var isLayoutLocked: Bool = true
    @State private var isZoomLocked: Bool = false
    @State private var showTopControls: Bool = true
    @State private var isLayoutReset: Bool = false
    @State private var showingBottomSheet = false


    // Zoom and pan state
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    @State private var clusters: [CachedCluster] = []

    @State private var sidebarColor: Color = Color.sidebar_lunch // Default color

    
    // Navigation direction
        
        
    @State  var navigationDirection: NavigationDirection = .forward
    
    var onSidebarColorChange: ((Color) -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let selectedDate = dates[safe: selectedIndex] ?? Date()
            var adjustedWidth = showInspector ? geometry.size.width - 300 : geometry.size.width // Adjust for sidebar width

            
            ZStack {
            
                // Current Layout Page View
                LayoutPageView(
                    selectedDate: selectedDate,
                    selectedCategory: selectedCategory ?? .lunch,
                    currentTime: $currentTime,
                    isManuallyOverridden: $isManuallyOverridden,
                    showingTimePickerSheet: $showingTimePickerSheet,
                    selectedReservation: $selectedReservation,
                    showInspector: $showInspector,
                    showingEditReservation: $showingEditReservation,
                    showingAddReservationSheet: $showingAddReservationSheet,
                    tableForNewReservation: $tableForNewReservation,
                    showingNoBookingAlert: $showingNoBookingAlert,
                    isLayoutLocked: $isLayoutLocked,
                    isLayoutReset: $isLayoutReset,
                    scale: $scale,
                    offset: $offset,
                    clusters: clusters,
                    adjustedWidth: adjustedWidth
                )

                
                .environmentObject(store)
                .environmentObject(reservationService)
                .environmentObject(gridData)
                .id(selectedIndex) // Force view refresh on index change
                //.matchedGeometryEffect(id: "layoutPageView\(selectedIndex)", in: animationNamespace) // Removed
                

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
            
            
            //.ignoresSafeArea(.all, edges: .top)
            .navigationTitle("Layout Tavoli")
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
                            showingBottomSheet = true
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Show Controls")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showInspector.toggle()
                        }
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Toggle Inspector")
                }
            }
            .inspector(isPresented: $showInspector) {// Show Inspector if a reservation is selected
                ZStack {
                    Color (
                        sidebarColor
                    )
                        .ignoresSafeArea()

                    
                    if let reservation = selectedReservation {
                        ReservationInfoCard(
                            reservationID: reservation.id,
                            onClose: {
                                dismissInfoCard()
                            },
                            onEdit: {
                                currentReservation = reservation
                            }
                        )
                        .background(.clear)

                        
                    } else {
                        Text("(Nessuna prenotazione selezionata)")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .sheet(item: $currentReservation) { reservation in
                EditReservationView(reservation: reservation)
                    .environmentObject(store)
                    .environmentObject(reservationService)
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
                    startTime: $currentTime)
                    .environmentObject(store)
                    .environmentObject(reservationService)
            }
            .sheet(isPresented: $showingBottomSheet) {
                BottomSheetControls(
                    dates: $dates,
                    selectedIndex: $selectedIndex,
                    selectedCategory: $selectedCategory,
                    currentTime: $currentTime,
                    systemTime: $systemTime,
                    systemDate: $systemDate,
                    isManuallyOverridden: $isManuallyOverridden,
                    sidebarColor: $sidebarColor,
                    updateDatesAroundSelectedDate: { newDate in
                                updateDatesAroundSelectedDate(newDate) // Call the external method
                            },
                    onSidebarColorChange: onSidebarColorChange
                )
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
            .onChange(of: selectedIndex) {
                adjustedWidth = showInspector ? geometry.size.width - 300 : geometry.size.width
                handleSelectedIndexChange()
            }
            .onChange(of: selectedCategory) { oldCategory, newCategory in
                handleSelectedCategoryChange(newCategory)
                if let category = newCategory {
                    sidebarColor = category.sidebarColor
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
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
       // .background(selectedCategory == .lunch ? Color.background_lunch : Color.background_dinner)
    }
    
    // MARK: - Navigation Methods
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            showInspector = false
            selectedReservation = nil
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
    
    private func resetLayout() {
        // Ensure the selected date and category are valid
        guard let currentCategory = selectedCategory else {
            print("Invalid category for reset.")
            return
        }
        
        let currentDate = Calendar.current.startOfDay(for: dates[safe: selectedIndex] ?? Date())
        
        print("Resetting layout for date: \(DateHelper.formatFullDate(currentDate)) and category: \(currentCategory.rawValue)")
        
        // Perform layout reset
        let combinedDate = DateHelper.combine(date: currentDate, time: currentTime)
        store.resetTables(for: currentDate, category: currentCategory)
        store.tables = store.loadTables(for: combinedDate, category: currentCategory)
        
        // Clear clusters
        store.resetClusters(for: combinedDate, category: currentCategory)
        store.saveClusters([], for: combinedDate, category: currentCategory)
        
        // Ensure layout flags are updated after reset completes
        DispatchQueue.main.async {
            self.isLayoutLocked = true
            self.isLayoutReset = true
            print("Layout successfully reset and reservations checked.")
        }
    }
    
    private func initializeView() {
        // Initialize default date/time configuration
        if !isManuallyOverridden {
            currentTime = systemTime
        }
        
        // Generate date array
        dates = generateInitialDates()
        
        print("Initialized with currentTime: \(currentTime), selectedCategory: \(selectedCategory?.rawValue ?? "None")")
        
        // Set initial sidebar color based on selectedCategory
        if let initialCategory = selectedCategory {
            onSidebarColorChange?(initialCategory.sidebarColor)
        }
        
        handleCurrentTimeChange(currentTime)
        
    }

    
    private func handleSelectedIndexChange() {
        
        // Explicitly set and log current time
        let newDate = dates[safe: selectedIndex] ?? Date()
        guard let combinedTime = DateHelper.normalizedTime(time: currentTime, date: newDate) else { return }
        currentTime = combinedTime
                
        print("Selected index changed to \(selectedIndex), date: \(DateHelper.formatFullDate(newDate))")
        
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
        guard let combinedTime = DateHelper.normalizedTime(time: currentTime, date: newDate) else { return }
        currentTime = combinedTime

        // checkActiveReservations(for: newDate, category: newCategory, from: "handleSelectedCategoryChange() in LayoutView")
        print("Loaded tables for \(newCategory.rawValue) on \(DateHelper.formatFullDate(newDate))")
        
        // Update sidebar color
        onSidebarColorChange?(newCategory.sidebarColor)
    }
    
    private func handleCurrentTimeChange(_ newTime: Date) {
        print("Time updated to \(newTime)")

        // Combine selectedDate with the new time
        let currentDate = dates[safe: selectedIndex] ?? Date()
        guard let combinedTime = DateHelper.normalizedTime(time: newTime, date: currentDate) else { return }
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
        if newTime >= lunchStart && newTime <= lunchEnd {
            determinedCategory = .lunch
        } else if newTime >= dinnerStart && newTime <= dinnerEnd {
            determinedCategory = .dinner
        } else {
            determinedCategory = .noBookingZone
        }
            
            selectedCategory = determinedCategory
    }
    
    // MARK: - Helper Methods
    struct BottomSheetControls: View {
        @Binding var dates: [Date]
        @Binding var selectedIndex: Int
        @Binding var selectedCategory: Reservation.ReservationCategory?
        @Binding var currentTime: Date
        @Binding var systemTime: Date
        @Binding var systemDate: Date
        @Binding var isManuallyOverridden: Bool
        @Binding var sidebarColor: Color
        
        let updateDatesAroundSelectedDate: (Date) -> Void // Closure for the method


        var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        var onSidebarColorChange: ((Color) -> Void)?

        var body: some View {
            ZStack {
                sidebarColor
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    Text("Controls")
                        .font(.title2)
                        .bold()
                        .padding(.top)
                        .padding(.horizontal)
                    
                    Divider()
                    
                    datePicker
                    
                    Divider()
                    
                    categoryPicker
                    
                    Divider()
                    
                    timePicker
                        .padding(.bottom)
                    
                    Spacer()
                }
                
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            
        }

        // MARK: - Date Picker
        private var datePicker: some View {
            VStack(alignment: .leading) {
                Text("Seleziona Giorno")
                    .font(.caption)
                HStack(alignment: .center, spacing: 8) {
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
                    
                    // Reset to Default or System Time
                    Button("Torna a oggi") {
                        withAnimation {
                            let today = Calendar.current.startOfDay(for: systemTime) // Get today's date with no time component
                            print("Today: \(today)")
                            guard let currentTimeOnly = DateHelper.extractTime(time: currentTime) else { return } // Extract time components
                            currentTime = DateHelper.normalizedInputTime(time: currentTimeOnly, date: today) ?? Date()
                            updateDatesAroundSelectedDate(currentTime)
                            print("New currentTime: \(currentTime)")
                            isManuallyOverridden = false
                        }
                    }
                    .font(.caption)
                    .opacity(Calendar.current.isDate(currentTime, inSameDayAs: systemTime) ? 0 : 1)
                    .animation(.easeInOut, value: currentTime)
                }
            }
        }

        // MARK: - Category Picker
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
                .onChange(of: selectedCategory) { oldCategory, newCategory in
                    if let newCategory = newCategory {
                        onSidebarColorChange?(newCategory.sidebarColor)
                    }
                }
            }
        }

        // MARK: - Time Picker
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
                                currentTime = DateHelper.combine(date: systemDate, time: newTime)
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
                    .opacity(DateHelper.compareTimes(firstTime: currentTime, secondTime: systemTime, interval: 60) ? 0 : 1)
                    .animation(.easeInOut, value: currentTime)
                }
            }
            .onReceive(timer) { currentDate in
                systemTime = currentDate
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
