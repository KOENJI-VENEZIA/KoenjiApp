import Foundation
import SwiftUI
import SwipeActions

struct ReservationListView: View {
    
    
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState  // Access AppState
    @EnvironmentObject var backupService: FirebaseBackupService
    @Environment(\.scenePhase) private var scenePhase
    @State var listView: ListViewModel
    
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    let store: ReservationStore
    let reservationService: ReservationService
    let layoutServices: LayoutServices
    
    // MARK: - State
    @State private var searchDate = Date()
    @State private var filterPeople: Int = 1
    @State private var filterStartDate: Date = Date()
    @State private var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State private var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero

    private var isSorted: Bool {
        listView.sortOption != .removeSorting
    }
 
    init(
        store: ReservationStore,
        reservationService: ReservationService,
        layoutServices: LayoutServices,
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        listView: ListViewModel
    ) {
        self.store = store
        self.reservationService = reservationService
        self.layoutServices = layoutServices
        self._columnVisibility = columnVisibility
        self._listView = State(wrappedValue: listView)
    }
    

    // MARK: - Body
    var body: some View {
        // Reservation List
        
        
            reservationsList
            .onAppear {
                listView.currentReservations = store.reservations
            }
            .onChange(of: store.reservations) {
                listView.currentReservations = store.reservations
            }
        
        .sheet(item: $listView.activeSheet) { sheet in
            switch sheet {
            case .inspector(let id):
                ReservationInfoCard(
                    reservationID: id,
                    onClose: { listView.activeSheet = nil },
                    onEdit: { reservation in
                        listView.handleEditTap(reservation)
                        dismissInfoCard()
                    },
                    isShowingFullImage: $listView.isShowingFullImage
                )
               .presentationBackground(.thinMaterial)

                
            case .addReservation:
                AddReservationView(passedTable: nil)
                    .environmentObject(appState)
                    .environmentObject(store)
                    .environmentObject(resCache)
                    .environmentObject(reservationService)
                    .environmentObject(layoutServices)
                    .presentationBackground(.thinMaterial)
            case .debugConfig:
                    DebugConfigView(
                        daysToSimulate: $daysToSimulate,
                        onGenerate: {
                            generateDebugData()
                            saveDebugData()
                        },
                        onResetData: {
                            listView.showingResetConfirmation = true
                            listView.shouldReopenDebugConfig = true
                        },
                        onSaveDebugData: { saveDebugData() },
                        onFlushCaches: { flushCaches() },
                        onParse: { parseReservations() }
                    )
                    .environmentObject(reservationService)
                    .environmentObject(store)
                    .presentationBackground(.thinMaterial)
            }
        }
//        .animation(nil, value: listView.showInspector)
        .alert(item: $listView.activeAlert) { alertType  in
            switch alertType {
            case .mondayConfirmation:
                return Alert(
                    title: Text("Nothing"), message: Text("Nothing"),
                    dismissButton: .default(Text("OK")))  // to modify in the future
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
            toolbarContent
        }
        .sheet(isPresented: $listView.showRestoreSheet) {
            BackupListView(showRestoreSheet: $listView.showRestoreSheet)

                .environmentObject(backupService)
                .environmentObject(store)
                .environmentObject(reservationService)
                .environmentObject(resCache)
                .presentationBackground(.thinMaterial)
        }
        
        .sheet(item: $listView.currentReservation) { (reservation: Reservation) in
            EditReservationView(reservation: reservation, onClose: {},
                                onChanged: { reservation in })

                .environmentObject(store)
                .environmentObject(resCache)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
                .presentationBackground(.thinMaterial)
        }
        .onChange(of: listView.hasSelectedPeople) {
            if listView.hasSelectedPeople {
                listView.updatePeopleFilter()
            }
        }
        .onChange(of: listView.hasSelectedStartDate) {
            listView.updateDateFilter()
        }
        .onChange(of: listView.hasSelectedEndDate) {
            listView.updateDateFilter()
        }
        .alert(isPresented: $listView.showingResetConfirmation) {
            Alert(
                title: Text("Reset di Tutti i Dati"),
                message: Text(
                    "Sei sicuro di voler eliminare tutte le prenotazioni e i dati salvati? Questa operazione non può essere annullata."
                ),
                primaryButton: .destructive(Text("Reset")) {
                    resetData()
                    listView.shouldReopenDebugConfig = false  // Ensure the sheet doesn't reopen after reset
                },
                secondaryButton: .cancel(Text("Annulla")) {
                    if listView.shouldReopenDebugConfig {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            listView.activeSheet = .debugConfig
                        }
                    }
                }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                Label(
                    "Toggle Full Screen",
                    systemImage: appState.isFullScreen
                        ? "arrow.down.right.and.arrow.up.left"
                        : "arrow.up.left.and.arrow.down.right")
            }
//            .id(listView.refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                withAnimation {
                    listView.showRestoreSheet = true
                }
            }) {
                Label("Show Restore Sheet", systemImage: "externaldrive.fill.badge.timemachine")
            }
//            .id(listView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Text("Raggruppa per...").font(.headline)

                Picker("Group By", selection: $listView.groupOption) {
                    ForEach(GroupOption.allCases, id: \.self) { (option: GroupOption) in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.inline)

            } label: {
                // Some icon or label
                Image(systemName: "rectangle.grid.2x2")
            }
//            .id(listView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {

                Text("Ordina per...")  // Add a title here
                    .font(.headline)  // Optional: Make the title stand out
                    .padding(.bottom, 4)  // Optional: Add spacing below the title

                Picker("Ordina Per", selection: $listView.sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { (option: SortOption) in
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
//            .id(listView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Text("Filtra per...")
                    .font(.headline)
                    .padding(.bottom, 4)

                // Simple buttons for .none and .canceled
                ForEach([FilterOption.none, FilterOption.canceled], id: \.self) { (option: FilterOption) in
                    Button(action: {
                        listView.toggleFilter(option)  // Toggles these options
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if listView.selectedFilters.contains(option) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                // Submenu for .people
                Button(action: {
                    listView.showPeoplePopover = true
                }) {
                    HStack {
                        Text("Numero di persone")
                        if listView.selectedFilters.contains(.people) {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button(action: {
                    listView.showStartDatePopover = true
                }) {
                    HStack {
                        if !listView.selectedFilters.contains(.date) {
                            Text("Da data...")
                        } else {
                            Text("Dal '\(DateHelper.formatFullDate(filterStartDate))'...")
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button(action: {
                    listView.showEndDatePopover = true
                }) {
                    HStack {

                        if !listView.selectedFilters.contains(.date) {
                            Text("A data...")
                        } else {
                            Text("Al '\(DateHelper.formatFullDate(filterEndDate))'...")
                            Image(systemName: "checkmark")
                        }
                    }
                }

            } label: {
                Image(
                    systemName: !listView.selectedFilters.isEmpty && listView.selectedFilters != [.none]
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle"
                )
            }
            .popover(isPresented: $listView.showPeoplePopover) {
                PeoplePickerView(
                    filterPeople: $filterPeople, hasSelectedPeople: $listView.hasSelectedPeople)
            }
            .popover(isPresented: $listView.showStartDatePopover) {
                DatePickerView(
                    filteredDate: $filterStartDate, hasSelectedStartDate: $listView.hasSelectedStartDate
                )
                .environmentObject(appState)
                .frame(width: 300)
            }
            .popover(isPresented: $listView.showEndDatePopover) {
                DatePickerView(
                    filteredDate: $filterEndDate, hasSelectedEndDate: $listView.hasSelectedEndDate
                )
                .environmentObject(appState)
                .frame(width: 300)
            }
//            .id(listView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                listView.activeSheet = .addReservation
            } label: {
                Image(systemName: "plus")
            }
//            .id(listView.refreshID)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Debug Config") {
                listView.activeSheet = .debugConfig
            }
//            .id(listView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
//                .id(listView.refreshID)
        }
    }

    private var reservationsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders){
                let filtered: [Reservation] = filterReservationsBy(
                    filters: listView.selectedFilters,
                    searchText: listView.searchText,
                    currentReservations: listView.currentReservations
                )
                
                let grouped: [GroupedReservations] = groupReservations(
                    reservations: filtered,
                    by: listView.groupOption,
                    sortOption: listView.sortOption
                )
                
                let sortedGrouped: [GroupedReservations] = sortGroupedReservations(
                    groups: grouped,
                    by: listView.groupOption
                )
                
                ForEach(sortedGrouped, id: \.id) { (group: GroupedReservations) in
                    Section(header: groupHeader(for: group)) {
                        ForEach(group.reservations) { (reservation: Reservation) in
                            row(for: reservation, group: group)
                        }
                    }
                }
            }
        }

//        .overlay(
//            LoadingOverlay()
//                .opacity(appState.isWritingToFirebase ? 1.0 : 0.0)
//                .animation(.easeInOut(duration: 0.5), value: appState.isWritingToFirebase)
//                .allowsHitTesting(appState.isWritingToFirebase)
//        )
        .searchable(
            text: $listView.searchText,
            placement: .toolbar,
            prompt: "Cerca prenotazioni"
        )
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }

    private func groupHeader(for group: GroupedReservations) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.thinMaterial)
                .frame(maxWidth: .infinity)
            
            HStack(spacing: 25) {
                Text(group.label)
                    .font(.headline)
                let reservationsLunch = filterForCategory(group.reservations, .lunch)
                let reservationsDinner = filterForCategory(group.reservations, .dinner)
                Text(
                    "\(group.reservations.count) \(TextHelper.pluralized("prenotazione", "prenotazioni", group.reservations.count)) (\(reservationsLunch.count) per pranzo, \(reservationsDinner.count) per cena)"
                )
                .font(.headline)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 60) // Adjust height as needed
    }

    private func row(for reservation: Reservation, group: GroupedReservations) -> some View {
        
        ZStack {
            reservation.assignedColor.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            ReservationRowView(
                reservation: reservation,
                notesAlertShown: $listView.showingNotesAlert,
                notesToShow: $listView.notesToShow,
                currentReservation: $listView.currentReservation,
                onTap: {
                    listView.handleEditTap(reservation)
                },
                onDelete: {
                    listView.handleDelete(reservation)
                },
                onRecover: {
                    listView.handleRecover(reservation)
                },
                onEdit: {
                    listView.currentReservation = reservation
                },
                searchText: listView.searchText
            )
            .id(reservation.id)
            //            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            //            .contentShape(Rectangle())
            //            .background(
            //                RoundedRectangle(cornerRadius: 12.0).fill(reservation.assignedColor.opacity(0.8)))
            .onTapGesture {
                listView.selectedReservationID = reservation.id
                listView.activeSheet = .inspector(reservation.id)
            }
        }
        
    }
    
    func formattedDateRange() -> String {
        let start = DateHelper.formatFullDate(filterStartDate)
        let end = DateHelper.formatFullDate(filterEndDate)
        return "\(start) - \(end)"
    }

    func sortGroupedReservations(
        groups: [GroupedReservations],
        by groupOption: GroupOption
    ) -> [GroupedReservations] {
        return (try? groups.sorted(by: { (lhs: GroupedReservations, rhs: GroupedReservations) -> Bool in
            return groupSortingFunction(lhs: lhs, rhs: rhs, by: groupOption)
        })) ?? groups
    }
    
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {  // Match animation duration
            listView.selectedReservation = nil
            listView.activeSheet = .none
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

                    }
                }
                .scrollContentBackground(.hidden)
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

    }

    // MARK: - Grouping

    func groupReservations(reservations: [Reservation], by option: GroupOption, sortOption: SortOption?)
        -> [GroupedReservations]
    {
        switch option {
        case .none:
            // All reservations in a single group with sorting
            let sortedReservations = sortReservations(reservations, sortOption: sortOption)
            return [
                GroupedReservations(
                    label: "Tutte",
                    reservations: sortedReservations,
                    sortDate: nil,
                    sortString: "Tutte"
                )
            ]
        case .table:
            return groupByTable(reservations)
        case .day:
            return groupByDay(reservations, sortOption: sortOption)
        case .week:
            return groupByWeek(reservations, sortOption: sortOption)
        case .month:
            return groupByMonth(reservations, sortOption: sortOption)
        }
    }

    private func groupSortingFunction(lhs: GroupedReservations, rhs: GroupedReservations, by groupOption: GroupOption) -> Bool {
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
                return lhs.label < rhs.label  // Fallback to alphabetical
            }
        case .table, .none:
            // String-based sorting
            return (lhs.sortString ?? lhs.label) < (rhs.sortString ?? rhs.label)
        }
    }

    private func filterReservationsBy(
        filters: Set<FilterOption>,
        searchText: String,
        currentReservations: [Reservation]
    )
        -> [Reservation]
    {
        var filtered = currentReservations

        // Apply existing filters
        if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true

                // Check for each selected filter
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }

                if filters.contains(.people) {
                    matches = matches && (reservation.numberOfPersons == filterPeople)  // Use the selectedPeople variable
                }

                if filters.contains(.date) {
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
                    table.name.lowercased().contains(lowercasedSearchText)
                        || String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch =
                    reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
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
                    let key = "Tavolo \(table.id)"  // Assuming `table.id` uniquely identifies a table
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
            return GroupedReservations(
                label: key, reservations: reservations, sortDate: nil, sortString: key)
        }

        // Handle "Nessun tavolo assegnato" group if present
        if let noTableReservations = grouped["Nessun tavolo assegnato"],
            !noTableReservations.isEmpty
        {
            let noTableGroup = GroupedReservations(
                label: "Nessun tavolo assegnato",
                reservations: noTableReservations,
                sortDate: nil,
                sortString: "Nessun tavolo assegnato"
            )
            groupedReservations.append(noTableGroup)  // Append at the end or desired position
        }

        return groupedReservations
    }

    private func groupByDay(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
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
            let sortedGroupReservations = sortReservations(unsortedReservations, sortOption: sortOption)  // Apply sorting
            return GroupedReservations(
                label: label,
                reservations: sortedGroupReservations,
                sortDate: date,
                sortString: nil
            )
        }

        // Handle invalid dates, if any
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalidReservations = sortReservations(invalidReservations, sortOption: sortOption)  // Optionally sort invalid reservations
            let invalidGroup = GroupedReservations(
                label: "Data Non Valida",
                reservations: sortedInvalidReservations,
                sortDate: nil,
                sortString: "Data Non Valida"
            )
            groupedReservations.append(invalidGroup)  // Append invalid dates at the end
        }

        return groupedReservations
    }

    private func groupByWeek(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
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
            guard
                let startOfPartialWeek = calendar.date(
                    byAdding: .day, value: -offsetToTuesday, to: date)
            else {
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
            let sortedGroupReservations = sortReservations(unsortedReservations, sortOption: sortOption)  // Apply sorting
            return GroupedReservations(
                label: label,
                reservations: sortedGroupReservations,
                sortDate: date,
                sortString: nil
            )
        }

        // Handle invalid dates, if any
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalidReservations = sortReservations(invalidReservations, sortOption: sortOption)  // Optionally sort invalid reservations
            let invalidGroup = GroupedReservations(
                label: "Data Non Valida",
                reservations: sortedInvalidReservations,
                sortDate: nil,
                sortString: "Data Non Valida"
            )
            groupedReservations.append(invalidGroup)  // Append invalid dates at the end
        }

        return groupedReservations
    }
    private func groupByMonth(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
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
            let sortedGroupReservations = sortReservations(unsortedReservations, sortOption: sortOption)  // Apply sorting
            return GroupedReservations(
                label: label,
                reservations: sortedGroupReservations,
                sortDate: date,
                sortString: nil
            )
        }

        // Handle invalid dates, if any
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalidReservations = sortReservations(invalidReservations, sortOption: sortOption)  // Optionally sort invalid reservations
            let invalidGroup = GroupedReservations(
                label: "Data Non Valida",
                reservations: sortedInvalidReservations,
                sortDate: nil,
                sortString: "Data Non Valida"
            )
            groupedReservations.append(invalidGroup)  // Append invalid dates at the end
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

        return sortReservations(filtered, sortOption: listView.sortOption)
    }

    private func filterForCategory(
        _ reservations: [Reservation], _ category: Reservation.ReservationCategory
    ) -> [Reservation] {
        reservations.filter { $0.category == category }
    }

    private func sortReservations(
        _ reservations: [Reservation],
        sortOption: SortOption?
    )
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
    @Binding var currentReservation: Reservation?

    var onTap: () -> Void
    var onDelete: () -> Void
    var onRecover: () -> Void
    var onEdit: () -> Void

    var searchText: String

    var body: some View {
        // Make a local variable for table names
        let duration = reservation.duration

            ZStack(alignment: .leading) {
                
                RoundedRectangle(cornerRadius: 12.0)
                    .fill(.thinMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                SwipeView() {
                VStack(alignment: .leading, spacing: 4) {  // Added spacing for better layout
                    // Name and Number of People
                    if searchText.isEmpty {
                        Text("\(reservation.name) - \(reservation.numberOfPersons) p.")
                            .font(.headline)
                    } else {
                        highlightedText(for: reservation.name, with: searchText)
                        + Text(" - \(reservation.numberOfPersons) p.")
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
                        Text("Durata: \(duration)")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding()
                .contentShape(Rectangle())
            } trailingActions: {_ in
                if reservation.status != .canceled {
                    SwipeAction(systemImage: "x.circle.fill", backgroundColor: Color(hex: "#5c140f")) {
                        onDelete()
                    }
                    .swipeActionLabelHorizontalPadding()

                } else {
                    SwipeAction(systemImage: "arrowshape.turn.up.backward.2.circle.fill", backgroundColor: reservation.assignedColor) {
                        onRecover()
                    }
                    .swipeActionLabelHorizontalPadding()
                    .allowSwipeToTrigger()

                }
                
            }
            .swipeActionCornerRadius(12)
            .swipeMinimumDistance(40)
            .swipeActionsMaskCornerRadius(12)

            }
            .padding()


           
        
        
    }

    /// Function to highlight matched text
    private func highlightedText(for text: String, with searchText: String) -> Text {
        // Ensure searchText is not empty to avoid unnecessary processing
        guard !searchText.isEmpty else { return Text(text) }

        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()

        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex

        while let range = lowercasedText.range(
            of: lowercasedSearchText, range: currentIndex..<lowercasedText.endIndex)
        {
            // Append the text before the match
            let prefixRange = currentIndex..<range.lowerBound
            let prefix = String(text[prefixRange])
            highlighted = highlighted + Text(prefix)

            // Append the matched text with highlight
            let matchRange = range.lowerBound..<range.upperBound
            let match = String(text[matchRange])
            highlighted =
                highlighted
                + Text(match)
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
