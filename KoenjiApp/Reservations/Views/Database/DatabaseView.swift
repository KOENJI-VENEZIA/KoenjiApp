import Foundation
import SwiftUI
import SwipeActions
import OSLog

// MARK: - Main Reservation List View

struct DatabaseView: View {
    let logger = Logger(subsystem: "com.koenjiapp", category: "DatabaseView")

    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: View Model & Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State var unitView = LayoutUnitViewModel()

    // MARK: Local State (Filters, Debug, etc.)
    @State private var searchDate = Date()
    @State var filterPeople: Int = 1
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
    @State var refreshID: UUID = UUID()
    @State private var isExpandedToolbar: Bool = false
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavigationBarCompact: Bool = false
    
    private var isSorted: Bool { env.listView.sortOption != .removeSorting }
    private var isCompact: Bool { sizeClass == .compact }

    private var filtered: [Reservation] {
        filterReservationsExpanded(
            filters: env.listView.selectedFilters,
            searchText: env.listView.searchText,
            currentReservations: env.listView.currentReservations)
    }
    
    // MARK: - Initializer
    init(columnVisibility: Binding<NavigationSplitViewVisibility>) {
        self._columnVisibility = columnVisibility
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            mainContent
                .ignoresSafeArea(edges: .bottom)
                .id(refreshID)
                .searchable(text: $env.listView.searchText,
                          placement: .navigationBarDrawer(displayMode: .automatic),
                          prompt: "Cerca prenotazioni")
                .autocapitalization(.none)
                .toolbar {
                    if !isCompact {
                        regularToolbarContent
                    }
                }
            
            
            
            // Position the dropdown toolbar precisely
            if isCompact {
                GeometryReader { geometry in
                    dropdownToolbar
                        .offset(y: geometry.safeAreaInsets.top) // Position right after safe area
                        .edgesIgnoringSafeArea(.top)
                        .zIndex(1)
                }
            }
        }
        .sheet(item: $env.listView.activeSheet, content: sheetContent)
        .sheet(item: $env.listView.currentReservation, content: editReservationSheet)
        .sheet(isPresented: $unitView.showNotifsCenter) {
            NotificationCenterView()
                .environmentObject(env)
                .environment(unitView)
                .presentationBackground(.thinMaterial)
        }
        .alert(item: $env.listView.activeAlert, content: activeAlertContent)
        .alert(isPresented: $env.listView.showingResetConfirmation, content: resetConfirmationAlert)
        .onAppear {
            env.listView.currentReservations = env.store.reservations
        }
        .onReceive(env.store.$reservations) { new in
            env.listView.currentReservations = new
            refreshID = UUID()
        }
        .onChange(of: env.reservationService.changedReservation) {
            env.listView.currentReservations = env.store.reservations
            refreshID = UUID()
        }
        .onChange(of: env.listView.hasSelectedPeople) { _, newValue in
            if newValue { env.listView.updatePeopleFilter() }
        }
        .onChange(of: env.listView.hasSelectedStartDate) {
            env.listView.updateDateFilter()
        }
        .onChange(of: env.listView.hasSelectedEndDate) {
            env.listView.updateDateFilter()
        }
        .onChange(of: env.listView.sortOption) { old, new in
            if new == .byCreationDate {
                env.listView.groupOption = .none
            }
        }
    }
}

// MARK: - Main Content & Toolbar

extension DatabaseView {
    
    /// The main content: a searchable reservations list.
    private var mainContent: some View {
        ZStack(alignment: .bottomLeading) {
            reservationsList
                .padding(.top, isCompact ? (isExpandedToolbar ? 130 : 50) : 0)
            
            SessionsView()
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: SessionStore.shared.sessions)
                .padding(.leading, 16)
                .padding(.bottom, 16)
                .environmentObject(env)
        }
    }
    
    /// The reservations list with sections based on grouping.
    private var reservationsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                let grouped = groupReservations(
                    reservations: filtered,
                    by: env.listView.groupOption,
                    sortOption: env.listView.sortOption)
                
                let sortedGrouped = sortGroupedReservations(groups: grouped,
                                                            by: env.listView.groupOption)
                
                ForEach(sortedGrouped, id: \.id) { group in
                    Section(header: groupHeader(for: group)) {
                        let columns = [
                            GridItem(.adaptive(minimum: isCompact ? 250 : 300, maximum: 400), spacing: 12)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(group.reservations) { reservation in
                                ReservationCard(
                                    reservation: reservation,
                                    notesAlertShown: $env.listView.showingNotesAlert,
                                    notesToShow: $env.listView.notesToShow,
                                    currentReservation: $env.listView.currentReservation,
                                    onTap: { env.listView.handleEditTap(reservation) },
                                    onCancel: { env.listView.handleCancel(reservation) },
                                    onRecover: { env.listView.handleRecover(reservation) },
                                    onDelete: { env.listView.handleDelete(reservation) },
                                    onEdit: { env.listView.currentReservation = reservation },
                                    searchText: env.listView.searchText
                                )
                                .onTapGesture {
                                    env.listView.selectedReservationID = reservation.id
                                    env.listView.activeSheet = .inspector(reservation.id)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
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
                    .font(.title3)
                    .fontWeight(.bold)
                let reservationsLunch = filterForCategory(group.reservations, .lunch)
                let reservationsDinner = filterForCategory(group.reservations, .dinner)
                Text("Tot. \(group.reservations.count) (\(reservationsLunch.count) pranzo, \(reservationsDinner.count) cena)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 60)
    }
    
    // MARK: - Dropdown Toolbar for iPhone
    
    /// Custom dropdown toolbar for iPhone
    private var dropdownToolbar: some View {
        VStack(spacing: 0) {
            // Main toolbar row - always visible
            HStack(spacing: 8) {
                // Left side buttons
                HStack(spacing: 12) {
                    Button(action: toggleFullScreen) {
                        Image(systemName: appState.isFullScreen
                              ? "arrow.down.right.and.arrow.up.left"
                              : "arrow.up.left.and.arrow.down.right")
                    }
                    
                    Button {
                        unitView.showNotifsCenter.toggle()
                    } label: {
                        Image(systemName: "app.badge")
                    }
                    
                    Button {
                        env.listView.activeSheet = .debugConfig
                    } label: {
                        Image(systemName: "ladybug.slash.fill")
                    }
                }
                
                Spacer()
                
                // Right side - essential controls
                HStack(spacing: 8) {
                    // State filter
                    ReservationStateFilter(
                        filterOption: $env.listView.selectedFilters,
                        onFilterChange: {
                        refreshID = UUID()
                    })
                    
                    // Expand/collapse button
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpandedToolbar.toggle()
                        }
                    } label: {
                        Image(systemName: isExpandedToolbar ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Add button
                    Button {
                        env.listView.activeSheet = .addReservation
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar) // Use system bar material backdrop
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
            
            // Expandable section - additional filters
            if isExpandedToolbar {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Group option
                        GroupOptionTag(groupOption: $env.listView.groupOption, sortOption: $env.listView.sortOption, onGroupChange: {
                            refreshID = UUID()
                        })
                        
                        Spacer()
                        
                        // Sort option
                        SortOptionTag(sortOption: $env.listView.sortOption, onSortChange: {
                            refreshID = UUID()
                        })
                    }
                    
                    HStack {
                        // Other filters
                        OtherFiltersTag(
                            showPeoplePopover: $env.listView.showPeoplePopover,
                            showStartDatePopover: $env.listView.showStartDatePopover,
                            showEndDatePopover: $env.listView.showEndDatePopover,
                            filterPeople: $filterPeople,
                            filterStartDate: $filterStartDate,
                            filterEndDate: $filterEndDate,
                            selectedFilters: $env.listView.selectedFilters,
                            onFilterChange: {
                                refreshID = UUID()
                            }
                        )
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar) // Use system bar material backdrop
                .transition(.move(edge: .top).combined(with: .opacity))
                .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
            }
        }
    }
    
/// Regular toolbar content for iPad
    @ToolbarContentBuilder
    private var regularToolbarContent: some ToolbarContent {
        // Left side items
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
                unitView.showNotifsCenter.toggle()
            }
            label: {
               Image(systemName: "app.badge")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button {
                env.listView.activeSheet = .debugConfig
            } label: {
                Image(systemName: "ladybug.slash.fill")
            }
        }
        
        // Right side items
        ToolbarItem(placement: .topBarTrailing) {
            ReservationStateFilter(
                filterOption: $env.listView.selectedFilters,
                onFilterChange: {
                refreshID = UUID()
            })
        }
        ToolbarItem(placement: .topBarTrailing) {
            GroupOptionTag(groupOption: $env.listView.groupOption, sortOption: $env.listView.sortOption, onGroupChange: {
                refreshID = UUID()
            })
            .environmentObject(env)
        }
        ToolbarItem(placement: .topBarTrailing) {
            SortOptionTag(sortOption: $env.listView.sortOption, onSortChange: {
                refreshID = UUID()
            })
            .environmentObject(env)
        }
        ToolbarItem(placement: .topBarTrailing) {
            OtherFiltersTag(
                showPeoplePopover: $env.listView.showPeoplePopover,
                showStartDatePopover: $env.listView.showStartDatePopover,
                showEndDatePopover: $env.listView.showEndDatePopover,
                filterPeople: $filterPeople,
                filterStartDate: $filterStartDate,
                filterEndDate: $filterEndDate,
                selectedFilters: $env.listView.selectedFilters,
                onFilterChange: {
                    refreshID = UUID()
                }
            )
            .environmentObject(env)
        }
        ToolbarItem(placement: .topBarTrailing) {
            webReservationFilter
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                env.listView.activeSheet = .addReservation
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
            }
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
                    onClose: { env.listView.activeSheet = nil },
                    onEdit: { reservation in
                        env.listView.handleEditTap(reservation)
                        dismissInfoCard()
                    }
                )
                .environment(unitView)
                .presentationBackground(.thinMaterial)
            )
        case .addReservation:
            return AnyView(
                AddReservationView(passedTable: nil, onAdded: { newReservation in
                    appState.changedReservation = newReservation})
                .environmentObject(appState)
                .environmentObject(env)
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
                        env.listView.showingResetConfirmation = true
                        env.listView.shouldReopenDebugConfig = true
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
                env.listView.changedReservation = updatedReservation
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
        case .editing:
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
                env.listView.shouldReopenDebugConfig = false
            },
            secondaryButton: .cancel(Text("Annulla")) {
                if env.listView.shouldReopenDebugConfig {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        env.listView.activeSheet = .debugConfig
                    }
                }
            }
        )
    }
    
    /// Dismisses the inspector sheet with a short delay.
    private func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            env.listView.selectedReservation = nil
            env.listView.activeSheet = .none
        }
    }
    
    /// Toggles full-screen mode.
    private func toggleFullScreen() {
        withAnimation {
            appState.isFullScreen.toggle()
            columnVisibility = appState.isFullScreen ? .detailOnly : .all
        }
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
        print("Executing filtering logic... (should reflect in the UI)")
        var filtered = currentReservations
        if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
                if filters.contains(.toHandle) {
                    matches = matches && (reservation.status == .toHandle)
                }
                if filters.contains(.deleted) {
                    matches = matches && (reservation.status == .deleted)
                }
                if filters.contains(.waitingList) {
                    matches = matches && (reservation.reservationType == .waitingList)
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
            filtered = filtered.filter { $0.status != .canceled && $0.status != .deleted && $0.status != .toHandle && $0.reservationType != .waitingList }
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
            return [GroupedReservations(label: String(localized: "Tutte"),
                                         reservations: sortedReservations,
                                         sortDate: nil,
                                         sortString: String(localized: "Tutte"))]
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
                grouped[String(localized: "Nessun tavolo assegnato"), default: []].append(reservation)
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
        if let noTableReservations = grouped[String(localized: "Nessun tavolo assegnato")],
           !noTableReservations.isEmpty {
            let noTableGroup = GroupedReservations(label: String(localized: "Nessun tavolo assegnato"),
                                                    reservations: noTableReservations,
                                                    sortDate: nil,
                                                    sortString: String(localized: "Nessun tavolo assegnato"))
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
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: String(localized: "Data Non Valida"))
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
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: String(localized: "Data Non Valida"))
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
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: String(localized: "Data Non Valida"))
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
        else { return String(localized: "Data non valida") }
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
        
        case .byCreationDate:
            return reservations.sorted { $0.creationDate > $1.creationDate }
        case .removeSorting:
            return reservations
        }
    }
}
