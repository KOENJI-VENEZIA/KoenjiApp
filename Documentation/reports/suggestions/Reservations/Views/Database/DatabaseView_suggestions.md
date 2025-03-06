Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Database/DatabaseView.swift...
# Documentation Suggestions for DatabaseView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Database/DatabaseView.swift
Total suggestions: 113

## Class Documentation (3)

### DatabaseView (Line 8)

**Context:**

```swift

// MARK: - Main Reservation List View

struct DatabaseView: View {
    let logger = Logger(subsystem: "com.koenjiapp", category: "DatabaseView")

    // MARK: Environment Objects & Dependencies
```

**Suggested Documentation:**

```swift
/// DatabaseView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### DatabaseView (Line 139)

**Context:**

```swift

// MARK: - Main Content & Toolbar

extension DatabaseView {
    
    /// The main content: a searchable reservations list.
    private var mainContent: some View {
```

**Suggested Documentation:**

```swift
/// DatabaseView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### DatabaseView (Line 529)

**Context:**

```swift

// MARK: - Filtering & Grouping Helpers

extension DatabaseView {
    
    private func filterForCategory(
        _ reservations: [Reservation], _ category: Reservation.ReservationCategory
```

**Suggested Documentation:**

```swift
/// DatabaseView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (14)

### refreshReservations (Line 131)

**Context:**

```swift
    // MARK: - Helper Methods
    
    @MainActor
    private func refreshReservations() async {
        logger.info("Manually refreshing reservations from Firebase")
        await env.reservationService.loadReservationsFromFirebase()
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the refreshReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### filterForCategory (Line 531)

**Context:**

```swift

extension DatabaseView {
    
    private func filterForCategory(
        _ reservations: [Reservation], _ category: Reservation.ReservationCategory
    ) -> [Reservation] {
        reservations.filter { $0.category == category }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the filterForCategory method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### filterReservations (Line 537)

**Context:**

```swift
        reservations.filter { $0.category == category }
    }
    
    private func filterReservations(
        filters: Set<FilterOption>,
        searchText: String,
        currentReservations: [Reservation]
```

**Suggested Documentation:**

```swift
/// [Add a description of what the filterReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupReservations (Line 589)

**Context:**

```swift
        return filtered
    }
    
    private func groupReservations(
        reservations: [Reservation],
        by option: GroupOption,
        sortOption: SortOption?
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### sortGroupedReservations (Line 612)

**Context:**

```swift
        }
    }
    
    private func sortGroupedReservations(
        groups: [GroupedReservations],
        by groupOption: GroupOption
    ) -> [GroupedReservations] {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the sortGroupedReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupSortingFunction (Line 621)

**Context:**

```swift
        }
    }
    
    private func groupSortingFunction(
        lhs: GroupedReservations,
        rhs: GroupedReservations,
        by groupOption: GroupOption
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupSortingFunction method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByTable (Line 642)

**Context:**

```swift
        }
    }
    
    private func groupByTable(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            let assignedTables = reservation.tables
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByDay (Line 677)

**Context:**

```swift
        return groupedReservations
    }
    
    private func groupByDay(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByDay method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByWeek (Line 705)

**Context:**

```swift
        return groupedReservations
    }
    
    private func groupByWeek(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByWeek method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByMonth (Line 739)

**Context:**

```swift
        return groupedReservations
    }
    
    private func groupByMonth(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByMonth method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### monthLabel (Line 772)

**Context:**

```swift
        return groupedReservations
    }
    
    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the monthLabel method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### partialWeekLabelSkippingMonday (Line 779)

**Context:**

```swift
        return formatter.string(from: date)
    }
    
    private func partialWeekLabelSkippingMonday(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
```

**Suggested Documentation:**

```swift
/// [Add a description of what the partialWeekLabelSkippingMonday method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### localizedDayLabel (Line 792)

**Context:**

```swift
        return "\(formatter.string(from: startOfPartialWeek)) – \(formatter.string(from: endOfPartialWeek))"
    }
    
    private func localizedDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM y")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the localizedDayLabel method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### sortReservations (Line 799)

**Context:**

```swift
        return formatter.string(from: date)
    }
    
    private func sortReservations(_ reservations: [Reservation], sortOption: SortOption?) -> [Reservation] {
        guard let sortOption = sortOption else { return reservations }
        switch sortOption {
        case .alphabetically:
```

**Suggested Documentation:**

```swift
/// [Add a description of what the sortReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (96)

### logger (Line 9)

**Context:**

```swift
// MARK: - Main Reservation List View

struct DatabaseView: View {
    let logger = Logger(subsystem: "com.koenjiapp", category: "DatabaseView")

    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### env (Line 12)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "DatabaseView")

    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 13)

**Context:**

```swift

    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### scenePhase (Line 14)

**Context:**

```swift
    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: View Model & Bindings
```

**Suggested Documentation:**

```swift
/// [Description of the scenePhase property]
```

### sizeClass (Line 15)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: View Model & Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
```

**Suggested Documentation:**

```swift
/// [Description of the sizeClass property]
```

### columnVisibility (Line 18)

**Context:**

```swift
    @Environment(\.horizontalSizeClass) private var sizeClass

    // MARK: View Model & Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State var unitView = LayoutUnitViewModel()

    // MARK: Local State (Filters, Debug, etc.)
```

**Suggested Documentation:**

```swift
/// [Description of the columnVisibility property]
```

### unitView (Line 19)

**Context:**

```swift

    // MARK: View Model & Bindings
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State var unitView = LayoutUnitViewModel()

    // MARK: Local State (Filters, Debug, etc.)
    @State private var searchDate = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the unitView property]
```

### searchDate (Line 22)

**Context:**

```swift
    @State var unitView = LayoutUnitViewModel()

    // MARK: Local State (Filters, Debug, etc.)
    @State private var searchDate = Date()
    @State var filterPeople: Int = 1
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the searchDate property]
```

### filterPeople (Line 23)

**Context:**

```swift

    // MARK: Local State (Filters, Debug, etc.)
    @State private var searchDate = Date()
    @State var filterPeople: Int = 1
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
```

**Suggested Documentation:**

```swift
/// [Description of the filterPeople property]
```

### filterStartDate (Line 24)

**Context:**

```swift
    // MARK: Local State (Filters, Debug, etc.)
    @State private var searchDate = Date()
    @State var filterPeople: Int = 1
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
```

**Suggested Documentation:**

```swift
/// [Description of the filterStartDate property]
```

### filterEndDate (Line 25)

**Context:**

```swift
    @State private var searchDate = Date()
    @State var filterPeople: Int = 1
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
```

**Suggested Documentation:**

```swift
/// [Description of the filterEndDate property]
```

### filterCancelled (Line 26)

**Context:**

```swift
    @State var filterPeople: Int = 1
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
    @State var refreshID: UUID = UUID()
```

**Suggested Documentation:**

```swift
/// [Description of the filterCancelled property]
```

### daysToSimulate (Line 27)

**Context:**

```swift
    @State var filterStartDate: Date = Date()
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
    @State var refreshID: UUID = UUID()
    @State private var isExpandedToolbar: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the daysToSimulate property]
```

### popoverPosition (Line 28)

**Context:**

```swift
    @State var filterEndDate: Date = Date()
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
    @State var refreshID: UUID = UUID()
    @State private var isExpandedToolbar: Bool = false
    
```

**Suggested Documentation:**

```swift
/// [Description of the popoverPosition property]
```

### refreshID (Line 29)

**Context:**

```swift
    @State private var filterCancelled: Reservation.ReservationStatus = .canceled
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
    @State var refreshID: UUID = UUID()
    @State private var isExpandedToolbar: Bool = false
    
    @State private var scrollOffset: CGFloat = 0
```

**Suggested Documentation:**

```swift
/// [Description of the refreshID property]
```

### isExpandedToolbar (Line 30)

**Context:**

```swift
    @State var daysToSimulate: Int = 5
    @State private var popoverPosition: CGRect = .zero
    @State var refreshID: UUID = UUID()
    @State private var isExpandedToolbar: Bool = false
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavigationBarCompact: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the isExpandedToolbar property]
```

### scrollOffset (Line 32)

**Context:**

```swift
    @State var refreshID: UUID = UUID()
    @State private var isExpandedToolbar: Bool = false
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavigationBarCompact: Bool = false
    
    private var isSorted: Bool { env.listView.sortOption != .removeSorting }
```

**Suggested Documentation:**

```swift
/// [Description of the scrollOffset property]
```

### isNavigationBarCompact (Line 33)

**Context:**

```swift
    @State private var isExpandedToolbar: Bool = false
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavigationBarCompact: Bool = false
    
    private var isSorted: Bool { env.listView.sortOption != .removeSorting }
    private var isCompact: Bool { sizeClass == .compact }
```

**Suggested Documentation:**

```swift
/// [Description of the isNavigationBarCompact property]
```

### isSorted (Line 35)

**Context:**

```swift
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavigationBarCompact: Bool = false
    
    private var isSorted: Bool { env.listView.sortOption != .removeSorting }
    private var isCompact: Bool { sizeClass == .compact }

    private var filtered: [Reservation] {
```

**Suggested Documentation:**

```swift
/// [Description of the isSorted property]
```

### isCompact (Line 36)

**Context:**

```swift
    @State private var isNavigationBarCompact: Bool = false
    
    private var isSorted: Bool { env.listView.sortOption != .removeSorting }
    private var isCompact: Bool { sizeClass == .compact }

    private var filtered: [Reservation] {
        filterReservationsExpanded(
```

**Suggested Documentation:**

```swift
/// [Description of the isCompact property]
```

### filtered (Line 38)

**Context:**

```swift
    private var isSorted: Bool { env.listView.sortOption != .removeSorting }
    private var isCompact: Bool { sizeClass == .compact }

    private var filtered: [Reservation] {
        filterReservationsExpanded(
            filters: env.listView.selectedFilters,
            searchText: env.listView.searchText,
```

**Suggested Documentation:**

```swift
/// [Description of the filtered property]
```

### body (Line 51)

**Context:**

```swift
    }
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            mainContent
                .ignoresSafeArea(edges: .bottom)
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### grouped (Line 160)

**Context:**

```swift
    private var reservationsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: .sectionHeaders) {
                let grouped = groupReservations(
                    reservations: filtered,
                    by: env.listView.groupOption,
                    sortOption: env.listView.sortOption)
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### sortedGrouped (Line 165)

**Context:**

```swift
                    by: env.listView.groupOption,
                    sortOption: env.listView.sortOption)
                
                let sortedGrouped = sortGroupedReservations(groups: grouped,
                                                            by: env.listView.groupOption)
                
                ForEach(sortedGrouped, id: \.id) { group in
```

**Suggested Documentation:**

```swift
/// [Description of the sortedGrouped property]
```

### columns (Line 170)

**Context:**

```swift
                
                ForEach(sortedGrouped, id: \.id) { group in
                    Section(header: groupHeader(for: group)) {
                        let columns = [
                            GridItem(.adaptive(minimum: isCompact ? 250 : 300, maximum: 400), spacing: 12)
                        ]
                        
```

**Suggested Documentation:**

```swift
/// [Description of the columns property]
```

### reservationsLunch (Line 211)

**Context:**

```swift
                Text(group.label)
                    .font(.title3)
                    .fontWeight(.bold)
                let reservationsLunch = filterForCategory(group.reservations, .lunch)
                let reservationsDinner = filterForCategory(group.reservations, .dinner)
                Text("Tot. \(group.reservations.count) (\(reservationsLunch.count) pranzo, \(reservationsDinner.count) cena)")
                    .font(.subheadline)
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsLunch property]
```

### reservationsDinner (Line 212)

**Context:**

```swift
                    .font(.title3)
                    .fontWeight(.bold)
                let reservationsLunch = filterForCategory(group.reservations, .lunch)
                let reservationsDinner = filterForCategory(group.reservations, .dinner)
                Text("Tot. \(group.reservations.count) (\(reservationsLunch.count) pranzo, \(reservationsDinner.count) cena)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsDinner property]
```

### regularToolbarContent (Line 334)

**Context:**

```swift
    
/// Regular toolbar content for iPad
    @ToolbarContentBuilder
    private var regularToolbarContent: some ToolbarContent {
        // Left side items
        ToolbarItem(placement: .topBarLeading) {
            Button(action: toggleFullScreen) {
```

**Suggested Documentation:**

```swift
/// [Description of the regularToolbarContent property]
```

### id (Line 413)

**Context:**

```swift
    /// Returns the view for the active sheet.
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .inspector(let id):
            return AnyView(
                ReservationInfoCard(
                    reservationID: id,
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### message (Line 482)

**Context:**

```swift
                message: Text("Nothing"),
                dismissButton: .default(Text("OK"))
            )
        case .error(let message):
            return Alert(
                title: Text("Errore:"),
                message: Text(message),
```

**Suggested Documentation:**

```swift
/// [Description of the message property]
```

### filtered (Line 543)

**Context:**

```swift
        currentReservations: [Reservation]
    ) -> [Reservation] {
        print("Executing filtering logic... (should reflect in the UI)")
        var filtered = currentReservations
        if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
```

**Suggested Documentation:**

```swift
/// [Description of the filtered property]
```

### matches (Line 546)

**Context:**

```swift
        var filtered = currentReservations
        if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the matches property]
```

### date (Line 563)

**Context:**

```swift
                    matches = matches && (reservation.numberOfPersons == filterPeople)
                }
                if filters.contains(.date) {
                    if let date = reservation.normalizedDate {
                        matches = matches && (date >= filterStartDate && date <= filterEndDate)
                    } else {
                        matches = false
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### lowercasedSearchText (Line 575)

**Context:**

```swift
            filtered = filtered.filter { $0.status != .canceled && $0.status != .deleted && $0.status != .toHandle && $0.reservationType != .waitingList }
        }
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
```

**Suggested Documentation:**

```swift
/// [Description of the lowercasedSearchText property]
```

### nameMatch (Line 577)

**Context:**

```swift
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
```

**Suggested Documentation:**

```swift
/// [Description of the nameMatch property]
```

### tableMatch (Line 578)

**Context:**

```swift
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the tableMatch property]
```

### notesMatch (Line 582)

**Context:**

```swift
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                return nameMatch || tableMatch || notesMatch
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the notesMatch property]
```

### sortedReservations (Line 596)

**Context:**

```swift
    ) -> [GroupedReservations] {
        switch option {
        case .none:
            let sortedReservations = sortReservations(reservations, sortOption: sortOption)
            return [GroupedReservations(label: String(localized: "Tutte"),
                                         reservations: sortedReservations,
                                         sortDate: nil,
```

**Suggested Documentation:**

```swift
/// [Description of the sortedReservations property]
```

### lhsDate (Line 628)

**Context:**

```swift
    ) -> Bool {
        switch groupOption {
        case .day, .week, .month:
            if let lhsDate = lhs.sortDate, let rhsDate = rhs.sortDate {
                return lhsDate < rhsDate
            } else if lhs.sortDate != nil {
                return true
```

**Suggested Documentation:**

```swift
/// [Description of the lhsDate property]
```

### rhsDate (Line 628)

**Context:**

```swift
    ) -> Bool {
        switch groupOption {
        case .day, .week, .month:
            if let lhsDate = lhs.sortDate, let rhsDate = rhs.sortDate {
                return lhsDate < rhsDate
            } else if lhs.sortDate != nil {
                return true
```

**Suggested Documentation:**

```swift
/// [Description of the rhsDate property]
```

### grouped (Line 643)

**Context:**

```swift
    }
    
    private func groupByTable(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            let assignedTables = reservation.tables
            if assignedTables.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### assignedTables (Line 645)

**Context:**

```swift
    private func groupByTable(_ reservations: [Reservation]) -> [GroupedReservations] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            let assignedTables = reservation.tables
            if assignedTables.isEmpty {
                grouped[String(localized: "Nessun tavolo assegnato"), default: []].append(reservation)
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### key (Line 650)

**Context:**

```swift
                grouped[String(localized: "Nessun tavolo assegnato"), default: []].append(reservation)
            } else {
                for table in assignedTables {
                    let key = "Tavolo \(table.id)"
                    grouped[key, default: []].append(reservation)
                }
            }
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### sortedKeys (Line 655)

**Context:**

```swift
                }
            }
        }
        let sortedKeys = grouped.keys.sorted {
            let num1 = Int($0.components(separatedBy: " ").last ?? "") ?? 0
            let num2 = Int($1.components(separatedBy: " ").last ?? "") ?? 0
            return num1 < num2
```

**Suggested Documentation:**

```swift
/// [Description of the sortedKeys property]
```

### num1 (Line 656)

**Context:**

```swift
            }
        }
        let sortedKeys = grouped.keys.sorted {
            let num1 = Int($0.components(separatedBy: " ").last ?? "") ?? 0
            let num2 = Int($1.components(separatedBy: " ").last ?? "") ?? 0
            return num1 < num2
        }
```

**Suggested Documentation:**

```swift
/// [Description of the num1 property]
```

### num2 (Line 657)

**Context:**

```swift
        }
        let sortedKeys = grouped.keys.sorted {
            let num1 = Int($0.components(separatedBy: " ").last ?? "") ?? 0
            let num2 = Int($1.components(separatedBy: " ").last ?? "") ?? 0
            return num1 < num2
        }
        var groupedReservations = sortedKeys.map { key in
```

**Suggested Documentation:**

```swift
/// [Description of the num2 property]
```

### groupedReservations (Line 660)

**Context:**

```swift
            let num2 = Int($1.components(separatedBy: " ").last ?? "") ?? 0
            return num1 < num2
        }
        var groupedReservations = sortedKeys.map { key in
            GroupedReservations(label: key,
                                reservations: grouped[key] ?? [],
                                sortDate: nil,
```

**Suggested Documentation:**

```swift
/// [Description of the groupedReservations property]
```

### noTableReservations (Line 666)

**Context:**

```swift
                                sortDate: nil,
                                sortString: key)
        }
        if let noTableReservations = grouped[String(localized: "Nessun tavolo assegnato")],
           !noTableReservations.isEmpty {
            let noTableGroup = GroupedReservations(label: String(localized: "Nessun tavolo assegnato"),
                                                    reservations: noTableReservations,
```

**Suggested Documentation:**

```swift
/// [Description of the noTableReservations property]
```

### noTableGroup (Line 668)

**Context:**

```swift
        }
        if let noTableReservations = grouped[String(localized: "Nessun tavolo assegnato")],
           !noTableReservations.isEmpty {
            let noTableGroup = GroupedReservations(label: String(localized: "Nessun tavolo assegnato"),
                                                    reservations: noTableReservations,
                                                    sortDate: nil,
                                                    sortString: String(localized: "Nessun tavolo assegnato"))
```

**Suggested Documentation:**

```swift
/// [Description of the noTableGroup property]
```

### grouped (Line 678)

**Context:**

```swift
    }
    
    private func groupByDay(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### calendar (Line 679)

**Context:**

```swift
    
    private func groupByDay(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### date (Line 681)

**Context:**

```swift
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### startOfDay (Line 685)

**Context:**

```swift
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let startOfDay = calendar.startOfDay(for: date)
            grouped[startOfDay, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
```

**Suggested Documentation:**

```swift
/// [Description of the startOfDay property]
```

### sortedDates (Line 688)

**Context:**

```swift
            let startOfDay = calendar.startOfDay(for: date)
            grouped[startOfDay, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = localizedDayLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
```

**Suggested Documentation:**

```swift
/// [Description of the sortedDates property]
```

### groupedReservations (Line 689)

**Context:**

```swift
            grouped[startOfDay, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = localizedDayLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
```

**Suggested Documentation:**

```swift
/// [Description of the groupedReservations property]
```

### label (Line 690)

**Context:**

```swift
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = localizedDayLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the label property]
```

### sortedRes (Line 691)

**Context:**

```swift
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = localizedDayLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the sortedRes property]
```

### invalidReservations (Line 694)

**Context:**

```swift
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
```

**Suggested Documentation:**

```swift
/// [Description of the invalidReservations property]
```

### sortedInvalid (Line 695)

**Context:**

```swift
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
```

**Suggested Documentation:**

```swift
/// [Description of the sortedInvalid property]
```

### invalidGroup (Line 696)

**Context:**

```swift
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: String(localized: "Data Non Valida"))
```

**Suggested Documentation:**

```swift
/// [Description of the invalidGroup property]
```

### grouped (Line 706)

**Context:**

```swift
    }
    
    private func groupByWeek(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### calendar (Line 707)

**Context:**

```swift
    
    private func groupByWeek(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### date (Line 709)

**Context:**

```swift
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### weekday (Line 713)

**Context:**

```swift
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let weekday = calendar.component(.weekday, from: date)
            let offsetToTuesday = ((weekday - 3) + 7) % 7
            guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date) else {
                grouped[Date.distantFuture, default: []].append(reservation)
```

**Suggested Documentation:**

```swift
/// [Description of the weekday property]
```

### offsetToTuesday (Line 714)

**Context:**

```swift
                continue
            }
            let weekday = calendar.component(.weekday, from: date)
            let offsetToTuesday = ((weekday - 3) + 7) % 7
            guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
```

**Suggested Documentation:**

```swift
/// [Description of the offsetToTuesday property]
```

### startOfPartialWeek (Line 715)

**Context:**

```swift
            }
            let weekday = calendar.component(.weekday, from: date)
            let offsetToTuesday = ((weekday - 3) + 7) % 7
            guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
```

**Suggested Documentation:**

```swift
/// [Description of the startOfPartialWeek property]
```

### normalizedStart (Line 719)

**Context:**

```swift
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let normalizedStart = calendar.startOfDay(for: startOfPartialWeek)
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedStart property]
```

### sortedDates (Line 722)

**Context:**

```swift
            let normalizedStart = calendar.startOfDay(for: startOfPartialWeek)
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = partialWeekLabelSkippingMonday(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
```

**Suggested Documentation:**

```swift
/// [Description of the sortedDates property]
```

### groupedReservations (Line 723)

**Context:**

```swift
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = partialWeekLabelSkippingMonday(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
```

**Suggested Documentation:**

```swift
/// [Description of the groupedReservations property]
```

### label (Line 724)

**Context:**

```swift
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = partialWeekLabelSkippingMonday(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the label property]
```

### sortedRes (Line 725)

**Context:**

```swift
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = partialWeekLabelSkippingMonday(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the sortedRes property]
```

### invalidReservations (Line 728)

**Context:**

```swift
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
```

**Suggested Documentation:**

```swift
/// [Description of the invalidReservations property]
```

### sortedInvalid (Line 729)

**Context:**

```swift
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
```

**Suggested Documentation:**

```swift
/// [Description of the sortedInvalid property]
```

### invalidGroup (Line 730)

**Context:**

```swift
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: String(localized: "Data Non Valida"))
```

**Suggested Documentation:**

```swift
/// [Description of the invalidGroup property]
```

### grouped (Line 740)

**Context:**

```swift
    }
    
    private func groupByMonth(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### calendar (Line 741)

**Context:**

```swift
    
    private func groupByMonth(_ reservations: [Reservation], sortOption: SortOption?) -> [GroupedReservations] {
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### date (Line 743)

**Context:**

```swift
        var grouped: [Date: [Reservation]] = [:]
        let calendar = Calendar.current
        for reservation in reservations {
            guard let date = reservation.normalizedDate else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### components (Line 747)

**Context:**

```swift
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let startOfMonth = calendar.date(from: components) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
```

**Suggested Documentation:**

```swift
/// [Description of the components property]
```

### startOfMonth (Line 748)

**Context:**

```swift
                continue
            }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let startOfMonth = calendar.date(from: components) else {
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
```

**Suggested Documentation:**

```swift
/// [Description of the startOfMonth property]
```

### normalizedStart (Line 752)

**Context:**

```swift
                grouped[Date.distantFuture, default: []].append(reservation)
                continue
            }
            let normalizedStart = calendar.startOfDay(for: startOfMonth)
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedStart property]
```

### sortedDates (Line 755)

**Context:**

```swift
            let normalizedStart = calendar.startOfDay(for: startOfMonth)
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = monthLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
```

**Suggested Documentation:**

```swift
/// [Description of the sortedDates property]
```

### groupedReservations (Line 756)

**Context:**

```swift
            grouped[normalizedStart, default: []].append(reservation)
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = monthLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
```

**Suggested Documentation:**

```swift
/// [Description of the groupedReservations property]
```

### label (Line 757)

**Context:**

```swift
        }
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = monthLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the label property]
```

### sortedRes (Line 758)

**Context:**

```swift
        let sortedDates = grouped.keys.filter { $0 != Date.distantFuture }.sorted()
        var groupedReservations = sortedDates.map { date in
            let label = monthLabel(for: date)
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the sortedRes property]
```

### invalidReservations (Line 761)

**Context:**

```swift
            let sortedRes = sortReservations(grouped[date] ?? [], sortOption: sortOption)
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
```

**Suggested Documentation:**

```swift
/// [Description of the invalidReservations property]
```

### sortedInvalid (Line 762)

**Context:**

```swift
            return GroupedReservations(label: label, reservations: sortedRes, sortDate: date, sortString: nil)
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
```

**Suggested Documentation:**

```swift
/// [Description of the sortedInvalid property]
```

### invalidGroup (Line 763)

**Context:**

```swift
        }
        if let invalidReservations = grouped[Date.distantFuture], !invalidReservations.isEmpty {
            let sortedInvalid = sortReservations(invalidReservations, sortOption: sortOption)
            let invalidGroup = GroupedReservations(label: String(localized: "Data Non Valida"),
                                                   reservations: sortedInvalid,
                                                   sortDate: nil,
                                                   sortString: String(localized: "Data Non Valida"))
```

**Suggested Documentation:**

```swift
/// [Description of the invalidGroup property]
```

### formatter (Line 773)

**Context:**

```swift
    }
    
    private func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### calendar (Line 780)

**Context:**

```swift
    }
    
    private func partialWeekLabelSkippingMonday(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### weekday (Line 781)

**Context:**

```swift
    
    private func partialWeekLabelSkippingMonday(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
              let endOfPartialWeek = calendar.date(byAdding: .day, value: 5, to: startOfPartialWeek)
```

**Suggested Documentation:**

```swift
/// [Description of the weekday property]
```

### offsetToTuesday (Line 782)

**Context:**

```swift
    private func partialWeekLabelSkippingMonday(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
              let endOfPartialWeek = calendar.date(byAdding: .day, value: 5, to: startOfPartialWeek)
        else { return String(localized: "Data non valida") }
```

**Suggested Documentation:**

```swift
/// [Description of the offsetToTuesday property]
```

### startOfPartialWeek (Line 783)

**Context:**

```swift
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
              let endOfPartialWeek = calendar.date(byAdding: .day, value: 5, to: startOfPartialWeek)
        else { return String(localized: "Data non valida") }
        let formatter = DateFormatter()
```

**Suggested Documentation:**

```swift
/// [Description of the startOfPartialWeek property]
```

### endOfPartialWeek (Line 784)

**Context:**

```swift
        let weekday = calendar.component(.weekday, from: date)
        let offsetToTuesday = ((weekday - 3) + 7) % 7
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
              let endOfPartialWeek = calendar.date(byAdding: .day, value: 5, to: startOfPartialWeek)
        else { return String(localized: "Data non valida") }
        let formatter = DateFormatter()
        formatter.locale = .current
```

**Suggested Documentation:**

```swift
/// [Description of the endOfPartialWeek property]
```

### formatter (Line 786)

**Context:**

```swift
        guard let startOfPartialWeek = calendar.date(byAdding: .day, value: -offsetToTuesday, to: date),
              let endOfPartialWeek = calendar.date(byAdding: .day, value: 5, to: startOfPartialWeek)
        else { return String(localized: "Data non valida") }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM")
        return "\(formatter.string(from: startOfPartialWeek)) – \(formatter.string(from: endOfPartialWeek))"
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### formatter (Line 793)

**Context:**

```swift
    }
    
    private func localizedDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE d MMM y")
        return formatter.string(from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### sortOption (Line 800)

**Context:**

```swift
    }
    
    private func sortReservations(_ reservations: [Reservation], sortOption: SortOption?) -> [Reservation] {
        guard let sortOption = sortOption else { return reservations }
        switch sortOption {
        case .alphabetically:
            return reservations.sorted { $0.name < $1.name }
```

**Suggested Documentation:**

```swift
/// [Description of the sortOption property]
```


Total documentation suggestions: 113

