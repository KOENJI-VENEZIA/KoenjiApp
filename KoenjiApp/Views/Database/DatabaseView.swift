import Foundation
import SwiftUI
import SwipeActions

// MARK: - Main Reservation List View

struct DatabaseView: View {
    
    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var backupService: FirebaseBackupService
    @Environment(\.scenePhase) private var scenePhase

    let store: ReservationStore
    let reservationService: ReservationService
    let layoutServices: LayoutServices

    // MARK: View Model & Bindings
    @State var listView: ListViewModel
    @Binding var columnVisibility: NavigationSplitViewVisibility

    // MARK: Local State (Filters, Debug, etc.)
    @State private var searchDate = Date()
    @State private var filterPeople: Int = 1
    @State private var filterStartDate: Date = Date()
    @State private var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State private var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero

    private var isSorted: Bool { listView.sortOption != .removeSorting }
    
    // MARK: - Initializer

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

        mainContent
            .navigationTitle("Tutte le prenotazioni")
            .toolbar { toolbarContent }
            .sheet(item: $listView.activeSheet, content: sheetContent)
            .sheet(isPresented: $listView.showRestoreSheet) {
                BackupListView(showRestoreSheet: $listView.showRestoreSheet)
                    .presentationBackground(.thinMaterial)
            }
            .sheet(item: $listView.currentReservation, content: editReservationSheet)
            .alert(item: $listView.activeAlert, content: activeAlertContent)
            .alert(isPresented: $listView.showingResetConfirmation, content: resetConfirmationAlert)
            .onAppear {
                listView.currentReservations = store.reservations
            }
            .onChange(of: store.reservations) {
                listView.currentReservations = store.reservations
            }
            .onChange(of: listView.changedReservation) {
                listView.currentReservations = store.reservations
            }
            .onChange(of: listView.hasSelectedPeople) { _, newValue in
                if newValue { listView.updatePeopleFilter() }
            }
            .onChange(of: listView.hasSelectedStartDate) {
                listView.updateDateFilter()
            }
            .onChange(of: listView.hasSelectedEndDate) {
                listView.updateDateFilter()
            }
    }
}

// MARK: - Main Content & Toolbar

extension DatabaseView {
    
    /// The main content: a searchable reservations list.
    private var mainContent: some View {
        reservationsList
            .searchable(text: $listView.searchText,
                        placement: .toolbar,
                        prompt: "Cerca prenotazioni")
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
    
    /// The reservations list with sections based on grouping.
    private var reservationsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                let filtered = filterReservations(
                    filters: listView.selectedFilters,
                    searchText: listView.searchText,
                    currentReservations: listView.currentReservations)
                
                let grouped = groupReservations(
                    reservations: filtered,
                    by: listView.groupOption,
                    sortOption: listView.sortOption)
                
                let sortedGrouped = sortGroupedReservations(groups: grouped,
                                                            by: listView.groupOption)
                
                ForEach(sortedGrouped, id: \.id) { group in
                    Section(header: groupHeader(for: group)) {
                        ForEach(group.reservations) { reservation in
                            row(for: reservation, group: group)
                        }
                    }
                }
            }
        }
    }
    
    /// A header view for each section.
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
                Text("\(group.reservations.count) \(TextHelper.pluralized("prenotazione", "prenotazioni", group.reservations.count)) (\(reservationsLunch.count) per pranzo, \(reservationsDinner.count) per cena)")
                    .font(.headline)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 60)
    }
    
    /// A row view for an individual reservation.
    private func row(for reservation: Reservation, group: GroupedReservations) -> some View {
        ZStack {
            reservation.assignedColor.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            ReservationRowView(
                reservation: reservation,
                notesAlertShown: $listView.showingNotesAlert,
                notesToShow: $listView.notesToShow,
                currentReservation: $listView.currentReservation,
                onTap: { listView.handleEditTap(reservation) },
                onDelete: { listView.handleDelete(reservation) },
                onRecover: { listView.handleRecover(reservation) },
                onEdit: { listView.currentReservation = reservation },
                searchText: listView.searchText
            )
            .id(reservation.id)
            .onTapGesture {
                listView.selectedReservationID = reservation.id
                listView.activeSheet = .inspector(reservation.id)
            }
        }
    }
    
    /// Toolbar content with buttons, menus, and popovers.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: toggleFullScreen) {
                Label("Toggle Full Screen",
                      systemImage: appState.isFullScreen
                        ? "arrow.down.right.and.arrow.up.left"
                        : "arrow.up.left.and.arrow.down.right")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                withAnimation { listView.showRestoreSheet = true }
            } label: {
                Label("Show Restore Sheet", systemImage: "externaldrive.fill.badge.timemachine")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Text("Raggruppa per...").font(.headline)
                Picker("Group By", selection: $listView.groupOption) {
                    ForEach(GroupOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "rectangle.grid.2x2")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Text("Ordina per...")
                    .font(.headline)
                    .padding(.bottom, 4)
                Picker("Ordina Per", selection: $listView.sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: isSorted
                      ? "arrow.up.arrow.down.circle.fill"
                      : "arrow.up.arrow.down.circle")
                    .imageScale(.large)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Text("Filtra per...")
                    .font(.headline)
                    .padding(.bottom, 4)
                ForEach([FilterOption.none, FilterOption.canceled], id: \.self) { option in
                    Button(action: { listView.toggleFilter(option) }) {
                        HStack {
                            Text(option.rawValue)
                            if listView.selectedFilters.contains(option) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Button {
                    listView.showPeoplePopover = true
                } label: {
                    HStack {
                        Text("Numero di persone")
                        if listView.selectedFilters.contains(.people) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button {
                    listView.showStartDatePopover = true
                } label: {
                    HStack {
                        if !listView.selectedFilters.contains(.date) {
                            Text("Da data...")
                        } else {
                            Text("Dal '\(DateHelper.formatFullDate(filterStartDate))'...")
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button {
                    listView.showEndDatePopover = true
                } label: {
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
                Image(systemName: (!listView.selectedFilters.isEmpty &&
                                    listView.selectedFilters != [.none])
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle")
            }
            .popover(isPresented: $listView.showPeoplePopover) {
                PeoplePickerView(filterPeople: $filterPeople,
                                 hasSelectedPeople: $listView.hasSelectedPeople)
            }
            .popover(isPresented: $listView.showStartDatePopover) {
                DatePickerView(filteredDate: $filterStartDate,
                               hasSelectedStartDate: $listView.hasSelectedStartDate)
                    .environmentObject(appState)
                    .frame(width: 300)
            }
            .popover(isPresented: $listView.showEndDatePopover) {
                DatePickerView(filteredDate: $filterEndDate,
                               hasSelectedEndDate: $listView.hasSelectedEndDate)
                    .environmentObject(appState)
                    .frame(width: 300)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                listView.activeSheet = .addReservation
            } label: {
                Image(systemName: "plus")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Debug Config") {
                listView.activeSheet = .debugConfig
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            EditButton()
        }
    }
    
    // MARK: - Sheets & Alerts
    
    /// Returns the view for the active sheet.
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .inspector(let id):
            return AnyView(
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
            )
        case .addReservation:
            return AnyView(
                AddReservationView(passedTable: nil)
                    .presentationBackground(.thinMaterial)
            )
        case .debugConfig:
            return AnyView(
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
                .presentationBackground(.thinMaterial)
            )
        }
    }
    
    /// Returns the view for editing a reservation.
    private func editReservationSheet(for reservation: Reservation) -> some View {
        EditReservationView(
            reservation: reservation,
            onClose: {},
            onChanged: { updatedReservation in
                listView.changedReservation = updatedReservation
            }
        )
        .presentationBackground(.thinMaterial)
    }
    
    /// Returns the appropriate alert based on the active alert type.
    private func activeAlertContent(for alertType: AddReservationAlertType) -> Alert {
        switch alertType {
        case .mondayConfirmation:
            return Alert(
                title: Text("Nothing"),
                message: Text("Nothing"),
                dismissButton: .default(Text("OK"))
            )
        case .error(let message):
            return Alert(
                title: Text("Errore:"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Alert for confirming a reset of all data.
    private func resetConfirmationAlert() -> Alert {
        Alert(
            title: Text("Reset di Tutti i Dati"),
            message: Text("Sei sicuro di voler eliminare tutte le prenotazioni e i dati salvati? Questa operazione non può essere annullata."),
            primaryButton: .destructive(Text("Reset")) {
                resetData()
                listView.shouldReopenDebugConfig = false
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
    
    /// Dismisses the inspector sheet with a short delay.
    private func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            listView.selectedReservation = nil
            listView.activeSheet = .none
        }
    }
    
    /// Toggles full-screen mode.
    private func toggleFullScreen() {
        withAnimation {
            appState.isFullScreen.toggle()
            columnVisibility = appState.isFullScreen ? .detailOnly : .all
        }
    }
    
    // MARK: - Debug Actions
    
    private func generateDebugData(force: Bool = false) {
        Task {
            await reservationService.generateReservations(daysToSimulate: daysToSimulate)
        }
    }
    
    private func saveDebugData() {
        reservationService.saveReservationsToDisk(includeMock: true)
        print("Debug data saved to disk.")
    }
    
    private func resetData() {
        store.setReservations([])
        reservationService.clearAllData()
        flushCaches()
        layoutServices.unlockAllTables()
        print("All data has been reset.")
    }
    
    private func parseReservations() {
        let reservations = store.reservations
        print("\(reservations)")
    }
    
    private func flushCaches() {
        reservationService.flushAllCaches()
        print("Debug: Cache flush triggered.")
    }
}

// MARK: - Filtering & Grouping Helpers

extension DatabaseView {
    
    private func filterForCategory(
        _ reservations: [Reservation], _ category: Reservation.ReservationCategory
    ) -> [Reservation] {
        reservations.filter { $0.category == category }
    }
    
    private func filterReservations(
        filters: Set<FilterOption>,
        searchText: String,
        currentReservations: [Reservation]
    ) -> [Reservation] {
        var filtered = currentReservations
        if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
                if filters.contains(.people) {
                    matches = matches && (reservation.numberOfPersons == filterPeople)
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
            filtered = filtered.filter { $0.status != .canceled }
        }
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                return nameMatch || tableMatch || notesMatch
            }
        }
        return filtered
    }
    
    private func groupReservations(
        reservations: [Reservation],
        by option: GroupOption,
        sortOption: SortOption?
    ) -> [GroupedReservations] {
        switch option {
        case .none:
            let sortedReservations = sortReservations(reservations, sortOption: sortOption)
            return [GroupedReservations(label: "Tutte",
                                         reservations: sortedReservations,
                                         sortDate: nil,
                                         sortString: "Tutte")]
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
    
    private func sortGroupedReservations(
        groups: [GroupedReservations],
        by groupOption: GroupOption
    ) -> [GroupedReservations] {
        groups.sorted { lhs, rhs in
            groupSortingFunction(lhs: lhs, rhs: rhs, by: groupOption)
        }
    }
    
    private func groupSortingFunction(
        lhs: GroupedReservations,
        rhs: GroupedReservations,
        by groupOption: GroupOption
    ) -> Bool {
        switch groupOption {
        case .day, .week, .month:
            if let lhsDate = lhs.sortDate, let rhsDate = rhs.sortDate {
                return lhsDate < rhsDate
            } else if lhs.sortDate != nil {
                return true
            } else if rhs.sortDate != nil {
                return false
            } else {
                return lhs.label < rhs.label
            }
        case .table, .none:
            return (lhs.sortString ?? lhs.label) < (rhs.sortString ?? rhs.label)
        }
    }
    
    private func groupByTable(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            let assignedTables = reservation.tables
            if assignedTables.isEmpty {
                grouped["Nessun tavolo assegnato", default: []].append(reservation)
            } else {
                for table in assignedTables {
                    let key = "Tavolo \(table.id)"
                    grouped[key, default: []].append(reservation)
                }
            }
        }
        let sortedKeys = grouped.keys.sorted {
            let num1 = Int($0.components(separatedBy: " ").last ?? "") ?? 0
            let num2 = Int($1.components(separatedBy: " ").last ?? "") ?? 0
            return num1 < num2
        }
        var groupedReservations = sortedKeys.map { key in
            GroupedReservations(label: key,
                                reservations: grouped[key] ?? [],
                                sortDate: nil,
                                sortString: key)
        }
        if let noTableReservations = grouped["Nessun tavolo assegnato"],
           !noTableReservations.isEmpty {
            let noTableGroup = GroupedReservations(label: "Nessun tavolo assegnato",
                                                    reservations: noTableReservations,
                                                    sortDate: nil,
                                                    sortString: "Nessun tavolo assegnato")
            groupedReservations.append(noTableGroup)
        }
        return groupedReservations
    }
    
    private func groupByDay(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let startOfDay = calendar.startOfDay(for: date)
            grouped[startOfDay, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = localizedDayLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: "Data Non Valida",
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: "Data Non Valida")
            groupedReservations.append(invalidGroup)
        }
        return groupedReservations
    }
    
    private func groupByWeek(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let weekday = calendar.component(.weekday, from: date)
            let offsetToTuesday = ((weekday - 3) + 7) % 7
            guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let normalizedStart = calendar.startOfDay(for: startOfPartialWeek)
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = partialWeekLabelSkippingMonday(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: "Data Non Valida",
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: "Data Non Valida")
            groupedReservations.append(invalidGroup)
        }
        return groupedReservations
    }
    
    private func groupByMonth(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let startOfMonth = calendar.date(from: components) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let normalizedStart = calendar.startOfDay(for: startOfMonth)
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = monthLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: "Data Non Valida",
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: "Data Non Valida")
            groupedReservations.append(invalidGroup)
        }
        return groupedReservations
    }
    
    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func partialWeekLabelSkippingMonday(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
              let endOfPartialWeek = calendar.date(byAdding: .day, value: 5, to: startOfPartialWeek)
        else { return "Data non valida" }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")
        return "\(formatter.string(from: startOfPartialWeek)) – \(formatter.string(from: endOfPartialWeek))"
    }
    
    private func localizedDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM y")
        return formatter.string(from: date)
    }
    
    private func sortReservations(_ reservations: [Reservation], sortOption: SortOption?) -> [Reservation] {
        guard let sortOption = sortOption else { return reservations }
        switch sortOption {
        case .alphabetically:
            return reservations.sorted { $0.name < $1.name }
        case .chronologically:
            return reservations.sorted {
                ($0.startTimeDate ?? Date()) < ($1.endTimeDate ?? Date())
            }
        case .byNumberOfPeople:
            return reservations.sorted { $0.numberOfPersons < $1.numberOfPersons }
        case .removeSorting:
            return reservations
        }
    }
}

