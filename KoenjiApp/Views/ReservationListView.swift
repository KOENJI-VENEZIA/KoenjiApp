import SwiftUI

struct GroupedReservations: Identifiable {
    let id = UUID()
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?      // Used for date-based groupings
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
}

struct ReservationListView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var appState: AppState  // Access AppState

    // MARK: - State
    @State private var searchDate = Date()
    @State private var filterPeople: Int = 1
    @State private var filterStartDate: Date = Date()
    @State private var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State private var selection = Set<UUID>()  // Multi-select
    @State private var showingAddReservation = false
    @State private var showingNotesAlert = false  // Controls visibility
    @State private var isAnimating = false  // Controls animation
    @State private var notesToShow: String = ""
    @State private var currentReservation: Reservation? = nil
    @State private var selectedReservationID: UUID? = nil
    @State private var showTopControls: Bool = false
    @State private var isFiltered: Bool = false
    @State private var daysToSimulate: Int = 5
    @State private var showingDebugConfig: Bool = false
    @State private var showingResetConfirmation = false
    @State private var shouldReopenDebugConfig = false
    @State private var selectedReservation: Reservation?
    @State private var popoverPosition: CGRect = .zero
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: Reservation.ReservationCategory? =
        .lunch

    @State private var showInspector: Bool = false  // Controls Inspector visibility
    @State private var showingFilters = false
    @State private var activeAlert: AddReservationAlertType? = nil


    @State private var sortOption: SortOption? = .removeSorting  // Default to nil (not sorted)
    private var isSorted: Bool {
        sortOption != .removeSorting
    }
    @State private var isShowingFullImage = false

    enum SortOption: String, CaseIterable {
        case alphabetically = "A-Z"
        case chronologically = "Per data"
        case byNumberOfPeople = "Per numero di persone"
        case removeSorting = "Nessuno"
    }

    enum GroupOption: String, CaseIterable {
        case none = "Nessuno"
        case table = "Per tavolo"
        case day = "Per giorno"
        case week = "Per settimana"
        case month = "Per mese"
    }

    enum FilterOption: String, CaseIterable {
        case none = "Nessuno"
        case people = "Per numero ospiti"
        case date = "Per data"
        case canceled = "Cancellazioni"
    }

    @State private var selectedFilters: Set<FilterOption> = [.none]  // Default to .none
    @State private var groupOption: GroupOption = .none
    
    @State private var searchText: String = ""

    @State private var showPeoplePopover: Bool = false
    @State private var showStartDatePopover: Bool = false
    @State private var showEndDatePopover: Bool = false
    @State private var hasSelectedPeople: Bool = false
    @State private var hasSelectedStartDate: Bool = false
    @State private var hasSelectedEndDate: Bool = false

    // MARK: - Body
    var body: some View {

        // Reservation List
        ZStack {
            Color.clear
            
            List(selection: $selection) {
                let filtered = filterReservationsBy(selectedFilters, searchText: searchText)
                // Then group
                let grouped = groupReservations(filtered, by: groupOption)
                
                ForEach(grouped.sorted(by: groupSortingFunction), id: \.id) { group in
                    Section(
                        header: HStack(spacing: 25) {
                            Text(group.label)
                                .font(.headline)
                            let reservationsLunch = filterForCategory(group.reservations, .lunch)
                            let reservationsDinner = filterForCategory(group.reservations, .dinner)
                            Text(
                                "\(group.reservations.count) prenotazioni (\(reservationsLunch.count) per pranzo, \(reservationsDinner.count) per cena)"
                            )
                            .font(.headline)
                        }
                        
                            .padding(.vertical, 4)
                    ) {
                        ForEach(group.reservations) { reservation in
                            ReservationRowView(
                                reservation: reservation,
                                notesAlertShown: $showingNotesAlert,
                                notesToShow: $notesToShow,
                                selectedReservationID: $selectedReservationID,
                                currentReservation: $currentReservation,
                                onTap: {
                                    handleEditTap(reservation)
                                },
                                onDelete: {
                                    handleDelete(reservation)
                                },
                                onRecover: {
                                    handleRecover(reservation)
                                },
                                onEdit: {
                                    currentReservation = reservation
                                },
                                onInfoTap: {
                                    selectedReservationID = reservation.id
                                    withAnimation {
                                        isAnimating = true
                                        showInspector = true
                                    }
                                },
                                searchText: searchText
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)  // Make the row fill the width
                            .contentShape(Rectangle())  // Make the entire row tappable
                            .background(
                                RoundedRectangle(cornerRadius: 12)  // Add a rounded rectangle
                                    .fill(
                                        selectedReservationID == reservation.id && showInspector
                                        ? Color.accentColor.opacity(0.4)  // Highlight for selected row
                                        : Color.clear  // Default transparent background
                                    )
                            )
                            .onTapGesture {
                                selectedReservationID = reservation.id
                                withAnimation {
                                    isAnimating = true
                                    showInspector = true
                                }
                            }
                            //                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.visible)
                        }
//                        .onDelete { offsets in
//                            handleDeleteFromGroup(
//                                groupKey: groupKey, offsets: offsets)
//                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca prenotazioni")
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            LoadingOverlay()
                    .opacity(appState.isWritingToFirebase ? 1.0 : 0.0) // Smoothly fade in and out
                    .animation(.easeInOut(duration: 0.3), value: appState.isWritingToFirebase)
                    .allowsHitTesting(appState.isWritingToFirebase) // Disable interaction when invisible
        }
        .listStyle(.plain)
        .inspector(isPresented: $showInspector) {  // Show Inspector if a reservation is selected
            if let selectedID = selectedReservationID {

                ZStack {

                    ReservationInfoCard(
                        reservationID: selectedID,
                        onClose: {
                            showInspector = false
                            selectedReservationID = nil
                        },
                        onEdit: {
                            // If you want to open Edit Reservation, pass the ID
                            // or fetch from the store.
                            if let reservation = store.reservations.first(
                                where: { $0.id == selectedID })
                            {
                                handleEditTap(reservation)
                            }
                        },
                        isShowingFullImage: $isShowingFullImage
                    )
                    .environmentObject(store)  // So inside InfoCard, we can access the updated reservations
                    .padding()
                }
            }

        }
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .mondayConfirmation:
                return Alert(title: Text("Nothing"), message: Text("Nothing"), dismissButton: .default(Text("OK"))) // to modify in the future
            case .error(let message):
                return Alert(
                    title: Text("Errore:"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationTitle("Tutte le prenotazioni")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Text("Raggruppa per...").font(.headline)

                    Picker("Group By", selection: $groupOption) {
                        ForEach(GroupOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)

                } label: {
                    // Some icon or label
                    Image(systemName: "rectangle.grid.2x2")
                }
                .id(UUID())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {

                    Text("Ordina per...")  // Add a title here
                        .font(.headline)  // Optional: Make the title stand out
                        .padding(.bottom, 4)  // Optional: Add spacing below the title

                    Picker("Ordina Per", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)  // Optional: Use inline style for better layout

                } label: {
                    Image(
                        systemName: isSorted
                            ? "arrow.up.arrow.down.circle.fill"
                            : "arrow.up.arrow.down.circle"
                    )
                    .imageScale(.large)
                }
                .id(UUID())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Text("Filtra per...")
                        .font(.headline)
                        .padding(.bottom, 4)

                    // Simple buttons for .none and .canceled
                    ForEach([FilterOption.none, FilterOption.canceled], id: \.self) { option in
                        Button(action: {
                            toggleFilter(option)  // Toggles these options
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if selectedFilters.contains(option) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    // Submenu for .people
                    Button(action: {
                        showPeoplePopover = true
                    }) {
                        HStack {
                            Text("Numero di persone")
                            if selectedFilters.contains(.people) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button(action: {
                        showStartDatePopover = true
                    }) {
                        HStack {
                            if !selectedFilters.contains(.date) {
                                Text("Da data...")
                            }
                            else {
                                Text("Dal '\(DateHelper.formatFullDate(filterStartDate))'...")
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button(action: {
                        showEndDatePopover = true
                    }) {
                        HStack {
                            
                            if !selectedFilters.contains(.date) {
                                Text("A data...")
                            }
                            else {
                                Text("Al '\(DateHelper.formatFullDate(filterEndDate))'...")
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                } label: {
                    Image(
                        systemName: !selectedFilters.isEmpty && selectedFilters != [.none]
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                    )
                }
                .popover(isPresented: $showPeoplePopover) {
                    PeoplePickerView(
                        filterPeople: $filterPeople, hasSelectedPeople: $hasSelectedPeople)
                }
                .popover(isPresented: $showStartDatePopover) {
                    DatePickerView(filteredDate: $filterStartDate,hasSelectedStartDate: $hasSelectedStartDate)
                        .environmentObject(appState)
                    .frame(width: 300)
                }
                .popover(isPresented: $showEndDatePopover) {
                    DatePickerView(filteredDate: $filterEndDate, hasSelectedEndDate: $hasSelectedEndDate)
                    .environmentObject(appState)
                    .frame(width: 300)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddReservation = true
                } label: {
                    Image(systemName: "plus")
                }
                .id(UUID())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Debug Config") {
                    showingDebugConfig = true
                }
                .id(UUID())
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
                    .id(UUID())
            }
        }
        .sheet(isPresented: $showingAddReservation) {
            AddReservationView(
                selectedDate: $selectedDate
            )
            .environmentObject(appState)
            .environmentObject(store)
            .environmentObject(resCache)
            .environmentObject(reservationService)  // For the new service
            .environmentObject(layoutServices)
        }
        .sheet(item: $currentReservation) { reservation in
            EditReservationView(reservation: reservation, onClose: {})
                .environmentObject(store)
                .environmentObject(resCache)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
        }
        .sheet(isPresented: $showingDebugConfig) {
            DebugConfigView(
                daysToSimulate: $daysToSimulate,
                onGenerate: {
                    generateDebugData()
                    saveDebugData()
                },
                onResetData: {
                    showingResetConfirmation = true  // Show the alert first
                    shouldReopenDebugConfig = true  // Mark for reopening if canceled
                },
                onSaveDebugData: {
                    saveDebugData()
                },
                onFlushCaches: {
                    flushCaches()
                },
                onParse: {
                    parseReservations()
                }
            )
            .environmentObject(reservationService)
            .environmentObject(store)

        }
        .onAppear {

            appState.selectedCategory = .noBookingZone
            NotificationCenter.default.addObserver(
                forName: .buttonPositionChanged,
                object: nil,
                queue: .main
            ) { notification in
                if let frame = notification.userInfo?["frame"] as? CGRect {
                    self.popoverPosition = frame
                }
            }
        }
        .onChange(of: hasSelectedPeople) {
            if hasSelectedPeople {
                updatePeopleFilter()
            }
        }
        .onChange(of: hasSelectedStartDate) {
                updateDateFilter()
        }
        .onChange(of: hasSelectedEndDate) {
                updateDateFilter()
        }
        
        .onDisappear {
            NotificationCenter.default.removeObserver(
                self, name: .buttonPositionChanged, object: nil)
        }
        .alert(isPresented: $showingResetConfirmation) {
            Alert(
                title: Text("Reset di Tutti i Dati"),
                message: Text(
                    "Sei sicuro di voler eliminare tutte le prenotazioni e i dati salvati? Questa operazione non può essere annullata."
                ),
                primaryButton: .destructive(Text("Reset")) {
                    resetData()
                    shouldReopenDebugConfig = false  // Ensure the sheet doesn't reopen after reset
                },
                secondaryButton: .cancel(Text("Annulla")) {
                    if shouldReopenDebugConfig {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingDebugConfig = true
                        }
                    }
                }
            )
        }
        .toolbarBackground(Material.ultraThin, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    func formattedDateRange() -> String {
        let start = DateHelper.formatFullDate(filterStartDate)
        let end = DateHelper.formatFullDate(filterEndDate)
        return "\(start) - \(end)"
    }

    func dismissInfoCard() {
        withAnimation {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {  // Match animation duration
            selectedReservation = nil
        }
    }

    func reservationsCount(
        for reservations: [Reservation], within startTime: String, and endTime: String
    ) -> Int {
        reservations.filter { reservation in
            guard let reservationTime = DateHelper.parseDate(reservation.startTime),
                let startTime = DateHelper.parseTime(startTime),
                let endTime = DateHelper.parseTime(endTime)
            else {
                return false  // Skip reservations with invalid times
            }
            return reservationTime >= startTime && reservationTime <= endTime
        }.count
    }


    struct DebugConfigView: View {
        @Binding var daysToSimulate: Int
        var onGenerate: () -> Void
        var onResetData: () -> Void
        var onSaveDebugData: () -> Void
        var onFlushCaches: () -> Void
        var onParse: () -> Void

        @State private var isExporting = false
        @State private var document: ReservationsDocument?
        @State private var isImporting = false
        @State private var importedDocument: ReservationsDocument?

        @EnvironmentObject var store: ReservationStore
        @EnvironmentObject var reservationService: ReservationService
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Parametri Simulazione")) {
                        Stepper(
                            "Giorni da Simulare: \(daysToSimulate)",
                            value: $daysToSimulate, in: 1...365)
                        Button("Genera Dati di Debug") {
                            onGenerate()
                            dismissView()
                        }
                    }

                    Section(header: Text("Debug Tools")) {
                        Button(role: .destructive) {
                            onResetData()
                            dismissView()
                        } label: {
                            Label("Resetta Dati", systemImage: "trash")
                        }

                        Button {
                            onSaveDebugData()
                            dismissView()
                        } label: {
                            Label(
                                "Salva Dati Debug",
                                systemImage: "square.and.arrow.down")
                        }

                        Button {
                            dismissView()
                            onFlushCaches()
                        } label: {
                            Label(
                                "Azzera Cache", systemImage: "arrow.clockwise")
                        }

                        Button {
                            onParse()
                        } label: {
                            Label(
                                "Log Prenotazioni Salvate",
                                systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button("Export Reservations") {
                            prepareExport()

                            isExporting = true
                        }.fileExporter(
                            isPresented: $isExporting,
                            document: document,
                            contentType: .json,
                            defaultFilename: "ReservationsBackup"
                        ) { result in
                            switch result {
                            case .success(let url):
                                print("File exported successfully to \(url).")
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }

                        Button("Import Reservations") {
                            isImporting = true
                        }.fileImporter(
                            isPresented: $isImporting,
                            allowedContentTypes: [.json],
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                if let url = urls.first {
                                    importReservations(from: url)
                                } else {
                                    print("No file selected.")
                                }
                            case .failure(let error):
                                print("Import failed: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                //                .sheet(isPresented: $isExporting) {
                //                    if let exportURL = exportURL {
                //                        ExportReservationsView(fileURL: exportURL)
                //                    }
                //                }
                .sheet(isPresented: $isImporting) {
                    ImportReservationsView { selectedURL in
                        importReservations(from: selectedURL)
                    }
                }
                .navigationBarTitle("Debug Config", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Annulla") {
                        dismissView()
                    }
                )
            }
        }

        private func dismissView() {
            guard
                let windowScene = UIApplication.shared.connectedScenes.first
                    as? UIWindowScene
            else { return }
            windowScene.windows.first?.rootViewController?.dismiss(
                animated: true)
        }

        private func prepareExport() {
            do {
                // Generate the ReservationsDocument with current reservations
                let reservations = getReservations()  // Replace with your actual reservations
                document = try ReservationsDocument(reservations: reservations)
                isExporting = true
            } catch {
                print("Failed to prepare export: \(error.localizedDescription)")
            }
        }

        private func getReservations() -> [Reservation] {
            // Replace this with your actual reservations from ReservationService
            return store.reservations

        }

        private func importReservations(from url: URL) {
            print("Attempting to import file at URL: \(url)")

            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Failed to access the security-scoped resource.")
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            do {
                // Read the file's data
                let data = try Data(contentsOf: url)
                print("File data loaded successfully.")

                // Decode the JSON data
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let reservations = try decoder.decode([Reservation].self, from: data)
                print("Reservations decoded successfully.")

                // Handle the imported reservations
                handleImportedReservations(reservations)
            } catch {
                print("Failed to import reservations: \(error.localizedDescription)")
            }
        }

        private func handleImportedReservations(_ reservations: [Reservation]) {
            // Integrate the imported reservations into your app's data
            print("Imported \(reservations.count) reservations:")
            reservations.forEach { print($0) }

            // Example: Save them to your ReservationService
            store.reservations.append(contentsOf: reservations)
        }

    }

    // MARK: - Grouping

    func groupReservations(_ reservations: [Reservation], by option: GroupOption) -> [GroupedReservations] {
        switch option {
        case .none:
            // All reservations in a single group with sorting
            let sortedReservations = sortReservations(reservations)
            return [GroupedReservations(
                label: "Tutte",
                reservations: sortedReservations,
                sortDate: nil,
                sortString: "Tutte"
            )]
        case .table:
            return groupByTable(reservations)
        case .day:
            return groupByDay(reservations)
        case .week:
            return groupByWeek(reservations)
        case .month:
            return groupByMonth(reservations)
        }
    }

    private func groupSortingFunction(lhs: GroupedReservations, rhs: GroupedReservations) -> Bool {
        switch groupOption {
        case .day, .week, .month:
            // Date-based sorting
            if let lhsDate = lhs.sortDate, let rhsDate = rhs.sortDate {
                return lhsDate < rhsDate
            } else if lhs.sortDate != nil {
                return true
            } else if rhs.sortDate != nil {
                return false
            } else {
                return lhs.label < rhs.label // Fallback to alphabetical
            }
        case .table, .none:
            // String-based sorting
            return (lhs.sortString ?? lhs.label) < (rhs.sortString ?? rhs.label)
        }
    }
    
    func toggleFilter(_ option: FilterOption) {
        switch option {
        case .none, .canceled:
            // If selecting .none or .canceled, clear all and only add the selected one
            selectedFilters = [option]
        case .people, .date:
            // Allow multiselect for .people and .date
            selectedFilters.remove(.none)
            selectedFilters.remove(.canceled)
            if selectedFilters.contains(option) {
                selectedFilters.remove(option)
            } else {
                selectedFilters.insert(option)
            }
        }
    }

    func updatePeopleFilter() {
        selectedFilters.insert(.people)
        selectedFilters.remove(.none)  // Ensure `.none` is deselected
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
    }

    func updateDateFilter() {
        selectedFilters.insert(.date)
        selectedFilters.remove(.none)  // Ensure `.none` is deselected
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
    }

    private func filterReservationsBy(_ selectedFilters: Set<FilterOption>, searchText: String) -> [Reservation] {
        var filtered = store.reservations
        
        // Apply existing filters
        if !selectedFilters.isEmpty && !selectedFilters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                
                // Check for each selected filter
                if selectedFilters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
                
                if selectedFilters.contains(.people) {
                    matches = matches && (reservation.numberOfPersons == filterPeople) // Use the selectedPeople variable
                }
                
                if selectedFilters.contains(.date) {
                    if let date = reservation.normalizedDate {
                        matches = matches && (date >= filterStartDate && date <= filterEndDate)
                    } else {
                        matches = false
                    }
                }
                
                return matches
            }
        } else {
            // If only `.none` is selected, exclude canceled reservations
            filtered = filtered.filter { reservation in
                reservation.status != .canceled
            }
        }
        
        // Apply search filtering
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                // Define what fields you want to search. For example:
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                // Add other fields as necessary
        
                return nameMatch || tableMatch || notesMatch
            }
        }
        
        return filtered
    }

    private func groupByTable(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [String: [Reservation]] = [:]

        for reservation in reservations {
            let assignedTables = reservation.tables

            if assignedTables.isEmpty {
                grouped["Nessun tavolo assegnato", default: []].append(reservation)
            } else {
                for table in assignedTables {
                    let key = "Tavolo \(table.id)" // Assuming `table.id` uniquely identifies a table
                    grouped[key, default: []].append(reservation)
                }
            }
        }

        // Sort the table keys numerically if possible
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            // Extract table numbers assuming format "Tavolo X"
            let num1 = Int(key1.components(separatedBy: " ").last ?? "") ?? 0
            let num2 = Int(key2.components(separatedBy: " ").last ?? "") ?? 0
            return num1 < num2
        }

        // Create GroupedReservations
        var groupedReservations: [GroupedReservations] = sortedKeys.map { key in
            let reservations = grouped[key] ?? []
            return GroupedReservations(label: key, reservations: reservations, sortDate: nil, sortString: key)
        }

        // Handle "Nessun tavolo assegnato" group if present
        if let noTableReservations = grouped["Nessun tavolo assegnato"], !noTableReservations.isEmpty {
            let noTableGroup = GroupedReservations(
                label: "Nessun tavolo assegnato",
                reservations: noTableReservations,
                sortDate: nil,
                sortString: "Nessun tavolo assegnato"
            )
            groupedReservations.append(noTableGroup) // Append at the end or desired position
        }

        return groupedReservations
    }

    private func groupByDay(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current

        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                // Group invalid dates under a special key
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }

            // Normalize to start of day for consistent grouping
            let startOfDay = calendar.startOfDay(for: date)
            grouped[startOfDay, default: []].append(reservation)
        }

        // Sort the valid dates chronologically
        let sortedDates = grouped.keys
            .filter { $0 != Date.distantFuture }
            .sorted()

        // Create the grouped reservations with labels and sorted reservations
        var groupedReservations: [GroupedReservations] = sortedDates.map { date in
            let label = localizedDayLabel(for: date)
            let unsortedReservations = grouped[date] ?? []
            let sortedGroupReservations = sortReservations(unsortedReservations) // Apply sorting
            return GroupedReservations(
                label: label,
                reservations: sortedGroupReservations,
                sortDate: date,
                sortString: nil
            )
        }

        // Handle invalid dates, if any
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalidReservations = sortReservations(invalidReservations) // Optionally sort invalid reservations
            let invalidGroup = GroupedReservations(
                label: "Data Non Valida",
                reservations: sortedInvalidReservations,
                sortDate: nil,
                sortString: "Data Non Valida"
            )
            groupedReservations.append(invalidGroup) // Append invalid dates at the end
        }

        return groupedReservations
    }
    
    private func groupByWeek(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current

        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                // Group invalid dates under a special key
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }

            // Determine the start of the partial week (Tuesday)
            let weekday = calendar.component(.weekday, from: date)
            let offsetToTuesday = ((weekday - 3) + 7) % 7
            guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }

            // Normalize to start of day for consistent grouping
            let normalizedStart = calendar.startOfDay(for: startOfPartialWeek)
            grouped[normalizedStart, default: []].append(reservation)
        }

        // Sort the valid dates chronologically
        let sortedDates = grouped.keys
            .filter { $0 != Date.distantFuture }
            .sorted()

        // Create the grouped reservations with labels and sorted reservations
        var groupedReservations: [GroupedReservations] = sortedDates.map { date in
            let label = partialWeekLabelSkippingMonday(for: date)
            let unsortedReservations = grouped[date] ?? []
            let sortedGroupReservations = sortReservations(unsortedReservations) // Apply sorting
            return GroupedReservations(
                label: label,
                reservations: sortedGroupReservations,
                sortDate: date,
                sortString: nil
            )
        }

        // Handle invalid dates, if any
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalidReservations = sortReservations(invalidReservations) // Optionally sort invalid reservations
            let invalidGroup = GroupedReservations(
                label: "Data Non Valida",
                reservations: sortedInvalidReservations,
                sortDate: nil,
                sortString: "Data Non Valida"
            )
            groupedReservations.append(invalidGroup) // Append invalid dates at the end
        }

        return groupedReservations
    }
    private func groupByMonth(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current

        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                // Group invalid dates under a special key
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }

            // Normalize to the start of the month
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let startOfMonth = calendar.date(from: components) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }

            // Normalize to start of day for consistent grouping
            let normalizedStart = calendar.startOfDay(for: startOfMonth)
            grouped[normalizedStart, default: []].append(reservation)
        }

        // Sort the valid dates chronologically
        let sortedDates = grouped.keys
            .filter { $0 != Date.distantFuture }
            .sorted()

        // Create the grouped reservations with labels and sorted reservations
        var groupedReservations: [GroupedReservations] = sortedDates.map { date in
            let label = monthLabel(for: date)
            let unsortedReservations = grouped[date] ?? []
            let sortedGroupReservations = sortReservations(unsortedReservations) // Apply sorting
            return GroupedReservations(
                label: label,
                reservations: sortedGroupReservations,
                sortDate: date,
                sortString: nil
            )
        }

        // Handle invalid dates, if any
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalidReservations = sortReservations(invalidReservations) // Optionally sort invalid reservations
            let invalidGroup = GroupedReservations(
                label: "Data Non Valida",
                reservations: sortedInvalidReservations,
                sortDate: nil,
                sortString: "Data Non Valida"
            )
            groupedReservations.append(invalidGroup) // Append invalid dates at the end
        }

        return groupedReservations
    }
    func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // "LLLL" = long month name, "MMM" = short name, "M" = numeric
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    func partialWeekLabelSkippingMonday(for date: Date) -> String {
        let calendar = Calendar.current
        // Sunday=1, Monday=2, Tuesday=3, ... Saturday=7 in Swift's default weekday system
        let weekday = calendar.component(.weekday, from: date)

        // How many days to go *backwards* to get to that week's Tuesday
        // (weekday - 3) is difference from Tuesday.
        // +7 ensures it's positive, % 7 ensures it wraps in [0..6].
        let offsetToTuesday = ((weekday - 3) + 7) % 7

        // 'startOfPartialWeek' = the Tuesday of this "week" that includes 'date'
        guard
            let startOfPartialWeek = calendar.date(
                byAdding: .day, value: -offsetToTuesday, to: date)
        else {
            return "Data non valida"
        }

        // Then 'endOfPartialWeek' is 5 days after Tuesday => Sunday
        guard
            let endOfPartialWeek = calendar.date(
                byAdding: .day, value: 5, to: startOfPartialWeek)
        else {
            return "Data non valida"
        }

        // Format each boundary with localized tokens.
        // "EEEE" => full weekday name, "d" => day-of-month, "MMM" => short month name
        // iOS will reorder them for the user’s locale (and translate day/month names).
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")

        let startString = formatter.string(from: startOfPartialWeek)
        let endString = formatter.string(from: endOfPartialWeek)

        // Combine them: "Tuesday, 16 Jan – Sunday, 21 Jan"
        return "\(startString) – \(endString)"
    }

    func localizedDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        // "EEEE" (day name), "d" (day number), "MMM" (short month), "y" (year)
        // iOS rearranges them based on the locale's conventions
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM y")
        return formatter.string(from: date)
    }

    // MARK: - Generate Debug Data
    private func generateDebugData(force: Bool = false) {

        Task {
            await reservationService.generateReservations(
                daysToSimulate: daysToSimulate
            )
            // breservationService.simulateUserActions(actionCount: 1000)
        }
    }

    private func saveDebugData() {

        reservationService.saveReservationsToDisk(includeMock: true)
        print("Debug data saved to disk.")
    }

    private func resetData() {
        store.setReservations([])  // Clear all reservations
        reservationService.clearAllData()  // Custom method to reset any cached or stored data
        flushCaches()
        layoutServices.unlockAllTables()
        print("All data has been reset.")
    }

    private func parseReservations() {
        let reservations = store.reservations
        print("\(reservations)")
    }

    // MARK: - Filtering Logic
    private func getFilteredReservations() -> [Reservation] {
        let filtered = store.getReservations().filter { reservation in
            var matchesFilter = true

            matchesFilter = matchesFilter && (reservation.status != filterCancelled)

            let start = filterStartDate
            let end = filterEndDate
            guard
                let reservationDate = reservation.normalizedDate
            else {
                return false
            }
            matchesFilter =
                matchesFilter
                && (reservationDate >= start && reservationDate <= end)

            let filterP = filterPeople
            matchesFilter =
                matchesFilter && (reservation.numberOfPersons == filterP)

            return matchesFilter
        }

        return sortReservations(filtered)
    }

    private func filterForCategory(
        _ reservations: [Reservation], _ category: Reservation.ReservationCategory
    ) -> [Reservation] {
        reservations.filter { $0.category == category }
    }

    private func sortReservations(_ reservations: [Reservation])
        -> [Reservation]
    {
        guard let sortOption = sortOption else {
            // Return unsorted reservations if sortOption is nil
            return reservations
        }

        switch sortOption {
        case .alphabetically:
            return reservations.sorted { $0.name < $1.name }
        case .chronologically:
            return reservations.sorted {
                $0.startTimeDate ?? Date()
                    < $1.endTimeDate ?? Date()
            }
        case .byNumberOfPeople:
            return reservations.sorted {
                $0.numberOfPersons < $1.numberOfPersons
            }

        case .removeSorting:
            return reservations
        }
    }


    // MARK: - Row Tap Handler
    private func handleEditTap(_ reservation: Reservation) {
        withAnimation {
            currentReservation = reservation
        }
    }

    // MARK: - Delete Handler from Context Menu
    private func handleDelete(_ reservation: Reservation) {

        if let idx = store.reservations.firstIndex(where: {
            $0.id == reservation.id
        }), var reservation = store.reservations.first(where: { $0.id == reservation.id}) {
            reservation.status = .canceled
            reservation.tables = []
            reservationService.updateReservation(reservation,
                at: idx)
        }
    }
    
    private func handleRecover(_ reservation: Reservation) {

        if let idx = store.reservations.firstIndex(where: {
            $0.id == reservation.id
        }), var reservation = store.reservations.first(where: { $0.id == reservation.id}) {
            reservation.status = .pending
            let assignmentResult = layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
                    // do actual saving logic here
                    reservation.tables = assignedTables
                }
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    activeAlert = .error("Non ci sono tavoli disponibili.")
                case .insufficientTables:
                    activeAlert = .error("Non ci sono abbastanza tavoli per la prenotazione.")
                case .tableNotFound:
                    activeAlert = .error("Tavolo selezionato non trovato.")
                case .tableLocked:
                    activeAlert = .error("Il tavolo scelto è occupato o bloccato.")
                case .unknown:
                    activeAlert = .error("Errore sconosciuto.")
                }
                return
            }
            reservationService.updateReservation(reservation,
                at: idx)
        }

    }

    // MARK: - Flush Caches
    private func flushCaches() {

        reservationService.flushAllCaches()
        print("Debug: Cache flush triggered.")

    }

}

// MARK: - ReservationRowView
/// A smaller subview that displays a single reservation row. This often helps reduce Swift's type-checking overhead.
struct ReservationRowView: View {
    let reservation: Reservation

    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var selectedReservationID: UUID?
    @Binding var currentReservation: Reservation?

    var onTap: () -> Void
    var onDelete: () -> Void
    var onRecover: () -> Void
    var onEdit: () -> Void
    var onInfoTap: () -> Void  // Added here

    var searchText: String


    var body: some View {
        // Make a local variable for table names
        let duration = TimeHelpers.availableTimeString(
            endTime: reservation.endTime, startTime: reservation.startTime)

        VStack(alignment: .leading, spacing: 4) { // Added spacing for better layout
            // Name and Number of People
            if searchText.isEmpty {
                Text("\(reservation.name) - \(reservation.numberOfPersons) p.")
                    .font(.headline)
            } else {
                highlightedText(for: reservation.name, with: searchText) +
                Text(" - \(reservation.numberOfPersons) p.")
                    .font(.headline)
            }
            
            // Date
            Text("Data: \(reservation.dateString)")
                .font(.subheadline)
            
            // Time
            Text("Orario: \(reservation.startTime) - \(reservation.endTime)")
                .font(.subheadline)
            
            if !searchText.isEmpty {
                // Notes Section
                if let notes = reservation.notes, !notes.isEmpty {
                    Text("Note:")
                        .font(.subheadline)
                        .bold()
                    highlightedText(for: notes, with: searchText)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                // Duration
                Text("Durata: \(duration ?? "Errore")")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .contextMenu {
            Button("Modifica") {
                onEdit()
            }
            Button("Elimina", role: .destructive) {
                onDelete()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if reservation.status != .canceled {
                Button {
                    onDelete()
                } label: {
                    Label("Cancella", systemImage: "x.circle.fill")
                }
                .tint(Color(hex: "#5c140f"))
                
            } else {
                Button {
                    onRecover()
                } label: {
                    Label("Ripristina", systemImage: "arrowshape.turn.up.backward.2.circle.fill")
                }
                .tint(.blue)
            }
        
            Button {
                onEdit()
            } label: {
                Label("Modifica", systemImage: "square.and.pencil")
            }
            .tint(.orange)

            Button {
                onInfoTap()
            } label: {
                Label("Info", systemImage: "info.circle")
            }
            .tint(.green)
        }
    }
    
    /// Function to highlight matched text
    private func highlightedText(for text: String, with searchText: String) -> Text {
        // Ensure searchText is not empty to avoid unnecessary processing
        guard !searchText.isEmpty else { return Text(text) }
        
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedSearchText, range: currentIndex..<lowercasedText.endIndex) {
            // Append the text before the match
            let prefixRange = currentIndex..<range.lowerBound
            let prefix = String(text[prefixRange])
            highlighted = highlighted + Text(prefix)
            
            // Append the matched text with highlight
            let matchRange = range.lowerBound..<range.upperBound
            let match = String(text[matchRange])
            highlighted = highlighted + Text(match)
                .foregroundColor(.yellow)
            
            // Update the current index to continue searching
            currentIndex = range.upperBound
        }
        
        // Append the remaining text after the last match
        let suffixRange = currentIndex..<lowercasedText.endIndex
        let suffix = String(text[suffixRange])
        highlighted = highlighted + Text(suffix)
        
        return highlighted
    }

}
struct ButtonPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension Notification.Name {
    static let buttonPositionChanged = Notification.Name(
        "buttonPositionChanged")
}
