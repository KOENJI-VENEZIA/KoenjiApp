




import SwiftUI

struct LayoutView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData
    
    @Environment(\.locale) var locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace private var animationNamespace
    
    // Dynamic Dates Array
    @State private var dates: [Date] = []
    @State private var selectedIndex: Int = 15 // Start in the middle of the dates array
    
    // Filters
    @State private var selectedDate: Date = Date()
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
    @State private var isLayoutReset : Bool = false

    
    // Zoom and pan state
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    @State private var debounceWorkItem: DispatchWorkItem?
    var onSidebarColorChange: ((Color) -> Void)?


    
    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        
        TabView(selection: $selectedIndex) {
            ForEach(dates.indices, id: \.self) { index in
                let date = dates[index]
                LayoutPageView(
                    selectedDate: date,
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
                    offset: $offset
                )
                .environmentObject(store)
                .environmentObject(reservationService)
                .environmentObject(gridData)
                .tag(index)
                .matchedGeometryEffect(id: "layoutPageView\(index)", in: animationNamespace)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)),
                        removal: .opacity.combined(with: .scale(scale: 1.05, anchor: .center))
                    )
                )
                .animation(.easeInOut(duration: 0.5), value: selectedIndex)
                }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
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
                    // Ensure the selected date and category are valid
                    if let currentCategory = selectedCategory {
                        let currentDate = Calendar.current.startOfDay(for: selectedDate)
                        store.resetTables(for: currentDate, category: currentCategory)
                        isLayoutLocked = true
                        isLayoutReset = true
                        store.tables = store.loadTables(for: currentDate, category: currentCategory)
                        checkActiveReservations(for: currentDate, category: currentCategory)
                    }
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
            // Initialize default date/time configuration
            if !isManuallyOverridden {
                currentTime = defaultTimeForCategory(selectedCategory ?? .lunch)
            }
            
            

            // Generate date array
            dates = generateInitialDates()

            print("Initialized with currentTime: \(currentTime), selectedCategory: \(selectedCategory?.rawValue ?? "None")")
        }
        .onAppear {
            // Set initial sidebar color based on selectedCategory
            if let initialCategory = selectedCategory {
                onSidebarColorChange?(initialCategory.sidebarColor)
            }
        }
        .onChange(of: selectedIndex) { newIndex in
            guard let newDate = dates[safe: newIndex] else { return }

            // Cancel any pending updates
            debounceWorkItem?.cancel()

            // Schedule a new update
            debounceWorkItem = DispatchWorkItem {
                if selectedDate != newDate {
                    selectedDate = newDate

                    print("Debounced: Selected date updated to \(DateHelper.formatFullDate(newDate))")

                    // Load tables for the new date
                    if let currentCategory = selectedCategory {
                        store.tables = store.loadTables(for: newDate, category: currentCategory)
                        checkActiveReservations(for: newDate, category: currentCategory)

                        // Check if the layout for the current date and category matches the base tables
                        let key = store.keyFor(date: newDate, category: currentCategory)
                        if let currentTables = store.cachedLayouts[key] {
                            isLayoutReset = (currentTables == store.baseTables)
                        } else {
                            isLayoutReset = false
                        }
                    }
                }

                // Handle progressive date loading
                if newIndex >= dates.count - 5 { appendMoreDates() }
                if newIndex <= 5 { prependMoreDates() }
                trimDatesAround(newIndex)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: debounceWorkItem!)
        }
        .onChange(of: selectedDate) { newDate in
            guard let currentCategory = selectedCategory else { return }

            print("Updating for new date: \(DateHelper.formatFullDate(newDate)), keeping time: \(currentTime)")


            
            // Combine selectedDate with the time component of currentTime
            if !isManuallyOverridden {
                currentTime = Calendar.current.date(
                    bySettingHour: Calendar.current.component(.hour, from: currentTime),
                    minute: Calendar.current.component(.minute, from: currentTime),
                    second: 0,
                    of: newDate
                ) ?? currentTime
            }

            // Load the layout and check reservations
            store.tables = store.loadTables(for: newDate, category: currentCategory)
            checkActiveReservations(for: newDate, category: currentCategory)
        }
        .onChange(of: selectedCategory) { newCategory in
            guard let newCategory = newCategory else { return }

            print("Category changed to \(newCategory.rawValue)")


            
            // Only adjust time if it's not manually overridden
            if !isManuallyOverridden {
                currentTime = defaultTimeForCategory(newCategory)
                print("Adjusted time for category to: \(currentTime)")
            }

            checkActiveReservations(for: selectedDate, category: newCategory)
        }
        .onChange(of: currentTime) { newTime in
            print("Time updated to \(newTime)")

        
            
            // Combine selectedDate with the new time
            currentTime = Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: newTime),
                minute: Calendar.current.component(.minute, from: newTime),
                second: 0,
                of: selectedDate
            ) ?? newTime

            print("Final currentTime after combination: \(currentTime)")

            checkActiveReservations(for: selectedDate, category: selectedCategory ?? .lunch)
        }
        .toolbarBackground(Material.ultraThin, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

    // MARK: - Helper Methods

    extension LayoutView {
        
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
                        get: { selectedDate },
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
                .onChange(of: selectedCategory) { newCategory in
                    guard let newCategory = newCategory else { return }
                    
                    print("Category changed to \(newCategory.rawValue)")

                    // Adjust time only if not manually overridden
                    if !isManuallyOverridden {
                        let newTime = defaultTimeForCategory(newCategory)
                        print("Updating time to \(newTime)")
                        currentTime = newTime
                    }

                    // Update reservations and layout
                    checkActiveReservations(for: selectedDate, category: newCategory)
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
            // Save the current layout before switching

            // Rebuild the dates array centered on the new date
            dates = generateDatesCenteredAround(newDate)
            selectedIndex = dates.firstIndex(of: newDate) ?? 15 // Default to center index if not found
            selectedDate = newDate

            // Ensure layout exists for the new date and load it
            if let currentCategory = selectedCategory {
                store.initializeLayoutIfNeeded(for: selectedDate, category: currentCategory)
                store.tables = store.loadTables(for: selectedDate, category: currentCategory)
                print("Loaded tables for \(currentCategory.rawValue) on \(DateHelper.formatFullDate(selectedDate))")
            }
        }
        
        private func generateDatesCenteredAround(_ centerDate: Date, range: Int = 15) -> [Date] {
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .day, value: -range, to: centerDate)!
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
        
        private func checkActiveReservations(for date: Date, category: Reservation.ReservationCategory) {
            // Combine selected date with the current time for proper comparisons
            let combinedDate = Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: currentTime),
                minute: Calendar.current.component(.minute, from: currentTime),
                second: 0,
                of: date
            ) ?? currentTime

            for table in store.cachedLayouts[store.keyFor(date: date, category: category)] ?? [] {
                print("Checking table \(table.id), Combined Date: \(combinedDate), Current Time: \(time)")

                if let activeReservation = reservationService.findActiveReservation(
                    for: table,
                    date: date, // Use selectedDate, not combinedDate
                    time: currentTime // Pass correct time
                ) {
                    print("Active reservation found for table \(table.id): \(activeReservation)")
                } else {
                    print("No active reservation for table \(table.id)")
                }
            }
        }
        
        private func trimDatesAround(_ index: Int) {
            let bufferSize = 30 // Total number of dates to keep
            if dates.count > bufferSize {
                let startIndex = max(0, index - bufferSize / 2)
                let endIndex = min(dates.count, index + bufferSize / 2)
                dates = Array(dates[startIndex..<endIndex])
                selectedIndex = index - startIndex // Adjust index relative to the trimmed array
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

extension Date {
    func toDate(on date: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        return calendar.date(byAdding: components, to: date)
    }
}


    // MARK: - Array Extension for Safe Indexing

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
