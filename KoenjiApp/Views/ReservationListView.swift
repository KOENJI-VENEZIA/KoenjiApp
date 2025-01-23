import SwiftUI

struct ReservationListView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var appState: AppState // Access AppState

    // MARK: - State
    @State private var searchDate = Date()
    @State private var filterPeople: Int? = nil
    @State private var filterStartDate: Date? = nil
    @State private var filterEndDate: Date? = nil
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
    @State private var currentTime: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: Reservation.ReservationCategory? =
        .lunch

    @State private var showInspector: Bool = false  // Controls Inspector visibility
    @State private var showingFilters = false

    @State private var sidebarDefault: Color = Color.sidebar_dinner  // Default color

    @State private var sortOption: SortOption? = .removeSorting  // Default to nil (not sorted)
    private var isSorted: Bool {
        sortOption != .removeSorting
    }

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

    @State private var groupOption: GroupOption = .none

    // MARK: - Body
    var body: some View {

        // Reservation List

        List(selection: $selection) {
            let filtered = getFilteredReservations()
            // Then group
            let grouped = groupReservations(filtered)
            
            ForEach(grouped.keys.sorted(), id: \.self) { groupKey in
                Section(
                    header: HStack(spacing: 25) {
                        Text(groupKey)
                            .font(.headline)
                        let reservationsLunch = reservationsCount(for: grouped[groupKey] ?? [], within: "12:00", and: "15:00")
                        let reservationsDinner = reservationsCount(for: grouped[groupKey] ?? [], within: "18:00", and: "23:00")
                        Text("\(grouped[groupKey]?.count ?? 0) prenotazioni (\(reservationsLunch) per pranzo, \(reservationsDinner) per cena)")
                            .font(.headline)
                    }

                    .padding(.vertical, 4)
                ) {
                    ForEach(grouped[groupKey] ?? []) { reservation in
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
                            onEdit: {
                                currentReservation = reservation
                            },
                            onInfoTap: {
                                selectedReservationID = reservation.id
                                withAnimation {
                                    isAnimating = true
                                    showInspector = true
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)  // Make the row fill the width
                        .contentShape(Rectangle())  // Make the entire row tappable
                        .background(
                                RoundedRectangle(cornerRadius: 12) // Add a rounded rectangle
                                    .fill(
                                        selectedReservationID == reservation.id && showInspector
                                        ? Color.accentColor.opacity(0.4) // Highlight for selected row
                                            : Color.clear             // Default transparent background
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
                    .onDelete { offsets in
                        handleDeleteFromGroup(
                            groupKey: groupKey, offsets: offsets)
                    }
                }
            }
        }
        .listStyle(.plain)
        //                .safeAreaInset(edge: .top) {
        //                    Color.clear.frame(height: 16) // Adds scrolling padding at the top
        //                }

        // .frame(maxWidth: selectedReservation == nil ? .infinity : UIScreen.main.bounds.width * 0.6) // Resize list dynamically

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
                        }
                    )
                    .environmentObject(store)  // So inside InfoCard, we can access the updated reservations
                    .padding()
                }
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

                Button(action: {
                    showingFilters = true
                }) {
                    Image(
                        systemName: isFiltered
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                    )
                    .id(UUID())
                    .imageScale(.large)
                }
                .sheet(isPresented: $showingFilters) {
                    VStack(spacing: 16) {
                        Text("Filters")
                            .font(.title2)
                            .bold()
                            .padding(.top)

                        // Guest Number Filter
                        if let unwrappedFilterPeople = filterPeople {
                            Stepper(
                                value: Binding(
                                    get: { unwrappedFilterPeople },
                                    set: { newValue in
                                        filterPeople = newValue
                                    }
                                ), in: 1...14, step: 1
                            ) {
                                let label =
                                    (unwrappedFilterPeople < 14)
                                    ? "Numero Ospiti: da \(unwrappedFilterPeople) in su"
                                    : "Numero Ospiti: \(unwrappedFilterPeople)"
                                Text(label)
                                    .font(.headline)
                            }

                            Button("Rimuovi Filtro Numero Ospiti") {
                                withAnimation {
                                    filterPeople = nil
                                    if filterStartDate == nil
                                        && filterEndDate == nil
                                    {
                                        isFiltered = false
                                    }
                                }
                            }
                            .foregroundStyle(.red)
                        } else {
                            Button("Filtra per Numero Ospiti...") {
                                withAnimation {
                                    filterPeople = 1
                                    isFiltered = true
                                }
                            }
                            .font(.headline)
                        }

                        Divider()
                            .padding(.vertical)

                        // Date Interval Filter
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Da data:")
                                    .font(.headline)
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { filterStartDate ?? Date() },
                                        set: { newValue in
                                            filterStartDate = newValue
                                        }
                                    ),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }

                            VStack(alignment: .leading) {
                                Text("A data:")
                                    .font(.headline)
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { filterEndDate ?? Date() },
                                        set: { newValue in
                                            filterEndDate = newValue
                                        }
                                    ),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                        }

                        if filterStartDate != nil && filterEndDate != nil {
                            Button("Rimuovi Filtro Data") {
                                withAnimation {
                                    filterStartDate = nil
                                    filterEndDate = nil
                                    if filterPeople == nil {
                                        isFiltered = false
                                    }
                                }
                            }
                            .foregroundStyle(.red)
                        }

                        Button("Applica") {
                            showingFilters = false
                            isFiltered = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)

                    }
                    .padding(.horizontal)
                    .presentationDetents([.medium, .large])  // Medium and large detents for flexibility
                    .presentationDragIndicator(.visible)
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
                category: $selectedCategory, selectedDate: $selectedDate,
                startTime: $currentTime
            )
            .environmentObject(store)
            .environmentObject(reservationService)  // For the new service
            .environmentObject(layoutServices)
        }
        .sheet(item: $currentReservation) { reservation in
            EditReservationView(reservation: reservation, onClose: {})
                .environmentObject(store)
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
        }
        .onAppear {
            sidebarDefault = appState.sidebarColor
            
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

    func dismissInfoCard() {
        withAnimation {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {  // Match animation duration
            selectedReservation = nil
        }
    }
    
    func reservationsCount(for reservations: [Reservation], within startTime: String, and endTime: String) -> Int {
        reservations.filter { reservation in
            guard let reservationTime = DateHelper.parseTime(reservation.startTime),
                  let startTime = DateHelper.parseTime(startTime),
                  let endTime = DateHelper.parseTime(endTime) else {
                return false // Skip reservations with invalid times
            }
            return reservationTime >= startTime && reservationTime <= endTime
        }.count
    }

    private func handleDeleteFromGroup(groupKey: String, offsets: IndexSet) {
        // 1) Access the grouped reservations
        var grouped = groupReservations(getFilteredReservations())
        // 2) The reservations in this group
        if var reservationsInGroup = grouped[groupKey] {
            // 3) Get the items to delete
            let toDelete = offsets.map { reservationsInGroup[$0] }
            // 4) Actually remove them from your store
            for reservation in toDelete {
                if let idx = store.reservations.firstIndex(where: {
                    $0.id == reservation.id
                }) {
                    reservationService.deleteReservations(
                        at: IndexSet(integer: idx))
                }
            }
            // 5) Optionally remove them from `grouped[groupKey]` if you want to keep a local copy
            offsets.forEach { reservationsInGroup.remove(at: $0) }
            grouped[groupKey] = reservationsInGroup
        }
    }

    struct DebugConfigView: View {
        @Binding var daysToSimulate: Int
        var onGenerate: () -> Void
        var onResetData: () -> Void
        var onSaveDebugData: () -> Void
        var onFlushCaches: () -> Void
        var onParse: () -> Void

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

    }

    // MARK: - Grouping

    private func groupReservations(_ reservations: [Reservation]) -> [String:
        [Reservation]]
    {
        switch groupOption {
        case .none:
            return ["Tutte": reservations]
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

    private func groupByTable(_ reservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
            let assignedTables = reservation.tables

            // If no tables assigned, put in a "No Table" group
            if assignedTables.isEmpty {
                grouped["(Nessun tavolo assegnato)", default: []].append(reservation)
            } else {
                // For each table, add the reservation to that section
                for table in assignedTables {
                    let key = "Tavolo \(table.id)"
                    grouped[key, default: []].append(reservation)
                }
            }
        }
        return grouped
    }

    private func groupByDay(_ reservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]

        for reservation in reservations {
            guard let date = DateHelper.parseDate(reservation.dateString) else {
                // If parsing fails, optionally group under "Invalid Date"
                grouped["Data Non Valida", default: []].append(reservation)
                continue
            }

            let dayKey = localizedDayLabel(for: date)
            grouped[dayKey, default: []].append(reservation)

        }
        return grouped
    }

    private func groupByWeek(_ reservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]

        for reservation in reservations {
            guard let date = DateHelper.parseDate(reservation.dateString) else {
                grouped["Data Non Valida", default: []].append(reservation)
                continue
            }

            let label = partialWeekLabelSkippingMonday(for: date)
            grouped[label, default: []].append(reservation)
        }
        return grouped
    }

    private func groupByMonth(_ reservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]

        for reservation in reservations {
            guard let date = DateHelper.parseDate(reservation.dateString) else {
                grouped["Invalid Date", default: []].append(reservation)
                continue
            }

            let key = monthLabel(for: date)
            grouped[key, default: []].append(reservation)

        }
        return grouped
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

            if let start = filterStartDate, let end = filterEndDate {
                guard
                    let reservationDate = DateHelper.parseDate(
                        reservation.dateString)
                else {
                    return false
                }
                matchesFilter =
                    matchesFilter
                    && (reservationDate >= start && reservationDate <= end)
            }

            if let filterP = filterPeople {
                matchesFilter =
                    matchesFilter && (reservation.numberOfPersons == filterP)
            }

            return matchesFilter
        }

        return sortReservations(filtered)
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
                DateHelper.combineDateAndTimeStrings(
                    dateString: $0.dateString,
                    timeString: $0.startTime
                )
                    < DateHelper.combineDateAndTimeStrings(
                        dateString: $1.dateString,
                        timeString: $1.startTime
                    )
            }
        case .byNumberOfPeople:
            return reservations.sorted {
                $0.numberOfPersons < $1.numberOfPersons
            }

        case .removeSorting:
            return reservations
        }
    }

    // MARK: - Delete
    private func delete(at offsets: IndexSet) {
        reservationService.deleteReservations(at: offsets)
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
        }) {
            reservationService.deleteReservations(at: IndexSet(integer: idx))
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
    var onEdit: () -> Void
    var onInfoTap: () -> Void  // Added here

    var body: some View {
        // Make a local variable for table names
        let duration = TimeHelpers.availableTimeString(
            endTime: reservation.endTime, startTime: reservation.startTime)

        VStack(alignment: .leading) {
            Text("\(reservation.name) - \(reservation.numberOfPersons) p.")
                .font(.headline)
            Text("Data: \(reservation.dateString)")
                .font(.subheadline)
            Text("Orario: \(reservation.startTime) - \(reservation.endTime)")
                .font(.subheadline)
            Text("Durata: \(duration ?? "Errore")")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }

        //            GeometryReader { geo in
        //                Button {
        //                    // Trigger onInfoTap and post button position
        //                    onInfoTap()
        //                    DispatchQueue.main.async {
        //                        NotificationCenter.default.post(
        //                            name: .buttonPositionChanged,
        //                            object: nil,
        //                            userInfo: ["frame": geo.frame(in: .global)] // Pass the button's global frame
        //                        )
        //                    }
        //                } label: {
        //                    Image(systemName: "info.circle")
        //                        .resizable()
        //                        .scaledToFit()
        //                        .frame(width: 25, height: 25)
        //                        .padding(8)
        //                }
        //                .buttonStyle(.plain)
        //            }
        //            .frame(width: 40, height: 40) // Add a frame to ensure GeometryReader works as intended
        .padding()
        //        .background(Color.gray.opacity(0.3))
        //        .cornerRadius(8)
        //
        //        .onTapGesture(count: 1) {
        //            onTap()
        //        }
        .contextMenu {
            Button("Modifica") {
                onEdit()
            }
            Button("Elimina", role: .destructive) {
                onDelete()
            }
        }
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

