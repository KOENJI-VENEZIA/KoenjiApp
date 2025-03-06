Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/ListViewModel.swift...
# Documentation Suggestions for ListViewModel.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/ListViewModel.swift
Total suggestions: 51

## Class Documentation (2)

### ActiveSheet (Line 10)

**Context:**

```swift

import SwiftUI

enum ActiveSheet: Identifiable {
    case inspector(UUID)
    case addReservation
    case debugConfig
```

**Suggested Documentation:**

```swift
/// ActiveSheet class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ListViewModel (Line 28)

**Context:**

```swift
}

@Observable
class ListViewModel {
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
```

**Suggested Documentation:**

```swift
/// ListViewModel view model.
///
/// [Add a description of what this view model does and its responsibilities]
```

## Method Documentation (7)

### handleEditTap (Line 74)

**Context:**

```swift
    
    
    
    func handleEditTap(_ reservation: Reservation) {
            withAnimation {
                currentReservation = reservation
            }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleEditTap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleCancel (Line 81)

**Context:**

```swift
        
    }
    
    @MainActor func handleCancel(_ reservation: Reservation) {

        if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .canceled
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleCancel method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleDelete (Line 94)

**Context:**

```swift
        }
    }
    
    @MainActor func handleDelete(_ reservation: Reservation) {
            reservationService.deleteReservation(reservation)
            changedReservation = reservation
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleDelete method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleRecover (Line 100)

**Context:**

```swift
    }

    @MainActor
    func handleRecover(_ reservation: Reservation) {
           if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .pending
            let assignmentResult = layoutServices.assignTables(
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleRecover method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updatePeopleFilter (Line 132)

**Context:**

```swift
        }
    }
    
    func updatePeopleFilter() {
        selectedFilters.insert(.people)
        selectedFilters.remove(.none)  // Ensure `.none` is deselected
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updatePeopleFilter method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateDateFilter (Line 138)

**Context:**

```swift
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
    }

    func updateDateFilter() {
        selectedFilters.insert(.date)
        selectedFilters.remove(.none)  // Ensure `.none` is deselected
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateDateFilter method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### toggleFilter (Line 144)

**Context:**

```swift
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
    }
    
    func toggleFilter(_ option: FilterOption) {
        switch option {
        case .none, .canceled, .toHandle, .deleted, .waitingList, .webPending:
            // If selecting .none or .canceled, clear all and only add the selected one
```

**Suggested Documentation:**

```swift
/// [Add a description of what the toggleFilter method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (42)

### id (Line 15)

**Context:**

```swift
    case addReservation
    case debugConfig

    var id: String {
        switch self {
        case .inspector(let id):
            return "inspector-\(id)"
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### id (Line 17)

**Context:**

```swift

    var id: String {
        switch self {
        case .inspector(let id):
            return "inspector-\(id)"
        case .addReservation:
            return "addReservation"
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### searchText (Line 29)

**Context:**

```swift

@Observable
class ListViewModel {
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
```

**Suggested Documentation:**

```swift
/// [Description of the searchText property]
```

### selectedFilters (Line 30)

**Context:**

```swift
@Observable
class ListViewModel {
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
```

**Suggested Documentation:**

```swift
/// [Description of the selectedFilters property]
```

### sortOption (Line 31)

**Context:**

```swift
class ListViewModel {
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the sortOption property]
```

### groupOption (Line 32)

**Context:**

```swift
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the groupOption property]
```

### selectedReservationID (Line 33)

**Context:**

```swift
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedReservationID property]
```

### showingNotesAlert (Line 34)

**Context:**

```swift
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the showingNotesAlert property]
```

### showingFilters (Line 35)

**Context:**

```swift
    var groupOption: GroupOption = .day
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showingFilters property]
```

### showRestoreSheet (Line 36)

**Context:**

```swift
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
```

**Suggested Documentation:**

```swift
/// [Description of the showRestoreSheet property]
```

### activeSheet (Line 37)

**Context:**

```swift
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
```

**Suggested Documentation:**

```swift
/// [Description of the activeSheet property]
```

### showingResetConfirmation (Line 38)

**Context:**

```swift
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the showingResetConfirmation property]
```

### currentReservations (Line 39)

**Context:**

```swift
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservations property]
```

### reservations (Line 40)

**Context:**

```swift
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### currentReservation (Line 41)

**Context:**

```swift
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservation property]
```

### activeAlert (Line 42)

**Context:**

```swift
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the activeAlert property]
```

### showPeoplePopover (Line 43)

**Context:**

```swift
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
```

**Suggested Documentation:**

```swift
/// [Description of the showPeoplePopover property]
```

### showStartDatePopover (Line 44)

**Context:**

```swift
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showStartDatePopover property]
```

### showEndDatePopover (Line 45)

**Context:**

```swift
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the showEndDatePopover property]
```

### notesToShow (Line 46)

**Context:**

```swift
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
```

**Suggested Documentation:**

```swift
/// [Description of the notesToShow property]
```

### showTopControls (Line 47)

**Context:**

```swift
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the showTopControls property]
```

### isFiltered (Line 48)

**Context:**

```swift
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
```

**Suggested Documentation:**

```swift
/// [Description of the isFiltered property]
```

### shouldReopenDebugConfig (Line 49)

**Context:**

```swift
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
```

**Suggested Documentation:**

```swift
/// [Description of the shouldReopenDebugConfig property]
```

### selectedReservation (Line 50)

**Context:**

```swift
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedReservation property]
```

### isShowingFullImage (Line 51)

**Context:**

```swift
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the isShowingFullImage property]
```

### refreshID (Line 52)

**Context:**

```swift
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the refreshID property]
```

### hasSelectedPeople (Line 53)

**Context:**

```swift
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
```

**Suggested Documentation:**

```swift
/// [Description of the hasSelectedPeople property]
```

### hasSelectedStartDate (Line 54)

**Context:**

```swift
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the hasSelectedStartDate property]
```

### hasSelectedEndDate (Line 55)

**Context:**

```swift
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
```

**Suggested Documentation:**

```swift
/// [Description of the hasSelectedEndDate property]
```

### changedReservation (Line 56)

**Context:**

```swift
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the changedReservation property]
```

### showFilterPopover (Line 57)

**Context:**

```swift
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the showFilterPopover property]
```

### filterPeople (Line 58)

**Context:**

```swift
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()

```

**Suggested Documentation:**

```swift
/// [Description of the filterPeople property]
```

### filterStartDate (Line 59)

**Context:**

```swift
    var changedReservation: Reservation?
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()

    private var reservationService: ReservationService
```

**Suggested Documentation:**

```swift
/// [Description of the filterStartDate property]
```

### filterEndDate (Line 60)

**Context:**

```swift
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()

    private var reservationService: ReservationService
    @ObservationIgnored private var store: ReservationStore
```

**Suggested Documentation:**

```swift
/// [Description of the filterEndDate property]
```

### reservationService (Line 62)

**Context:**

```swift
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()

    private var reservationService: ReservationService
    @ObservationIgnored private var store: ReservationStore
    @ObservationIgnored private var layoutServices: LayoutServices

```

**Suggested Documentation:**

```swift
/// [Description of the reservationService property]
```

### store (Line 63)

**Context:**

```swift
    var filterEndDate: Date = Date()

    private var reservationService: ReservationService
    @ObservationIgnored private var store: ReservationStore
    @ObservationIgnored private var layoutServices: LayoutServices

    init(reservationService: ReservationService, store: ReservationStore, layoutServices: LayoutServices) {
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### layoutServices (Line 64)

**Context:**

```swift

    private var reservationService: ReservationService
    @ObservationIgnored private var store: ReservationStore
    @ObservationIgnored private var layoutServices: LayoutServices

    init(reservationService: ReservationService, store: ReservationStore, layoutServices: LayoutServices) {
        self.reservationService = reservationService
```

**Suggested Documentation:**

```swift
/// [Description of the layoutServices property]
```

### reservation (Line 83)

**Context:**

```swift
    
    @MainActor func handleCancel(_ reservation: Reservation) {

        if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .canceled
            reservation.tables = []
            reservationService.updateReservation(
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### reservation (Line 101)

**Context:**

```swift

    @MainActor
    func handleRecover(_ reservation: Reservation) {
           if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .pending
            let assignmentResult = layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### assignmentResult (Line 103)

**Context:**

```swift
    func handleRecover(_ reservation: Reservation) {
           if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .pending
            let assignmentResult = layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 106)

**Context:**

```swift
            let assignmentResult = layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                // Direct assignment on the main thread without async dispatch.
                reservation.tables = assignedTables
            case .failure(let error):
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 109)

**Context:**

```swift
            case .success(let assignedTables):
                // Direct assignment on the main thread without async dispatch.
                reservation.tables = assignedTables
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    activeAlert = .error(String(localized: "Non ci sono tavoli disponibili."))
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```


Total documentation suggestions: 51

