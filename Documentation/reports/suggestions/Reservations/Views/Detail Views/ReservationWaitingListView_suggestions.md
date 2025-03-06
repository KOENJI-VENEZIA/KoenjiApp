Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationWaitingListView.swift...
# Documentation Suggestions for ReservationWaitingListView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationWaitingListView.swift
Total suggestions: 63

## Class Documentation (1)

### ReservationWaitingListView (Line 12)

**Context:**

```swift
import SwipeActions
import FirebaseFirestore

struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
```

**Suggested Documentation:**

```swift
/// ReservationWaitingListView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (3)

### loadWaitingListReservations (Line 125)

**Context:**

```swift
        }
    }
    
    private func loadWaitingListReservations() {
        isLoading = true
        Task {
            do {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadWaitingListReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByCategory (Line 244)

**Context:**

```swift
        )
    }
    
    private func groupByCategory(_ reservations: [Reservation]) -> [String: [Reservation]] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            var category: Reservation.ReservationCategory = .lunch
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByCategory method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleConfirm (Line 257)

**Context:**

```swift
        return grouped
    }
    
    private func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
        switch assignmentResult {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleConfirm method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (59)

### env (Line 13)

**Context:**

```swift
import FirebaseFirestore

struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 14)

**Context:**

```swift

struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = Set<UUID>()
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### colorScheme (Line 15)

**Context:**

```swift
struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = Set<UUID>()
    @State private var isLoading = false
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### selection (Line 17)

**Context:**

```swift
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = Set<UUID>()
    @State private var isLoading = false
    @State private var waitingListReservations: [Reservation] = []
    
```

**Suggested Documentation:**

```swift
/// [Description of the selection property]
```

### isLoading (Line 18)

**Context:**

```swift
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = Set<UUID>()
    @State private var isLoading = false
    @State private var waitingListReservations: [Reservation] = []
    
    var onClose: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the isLoading property]
```

### waitingListReservations (Line 19)

**Context:**

```swift
    
    @State private var selection = Set<UUID>()
    @State private var isLoading = false
    @State private var waitingListReservations: [Reservation] = []
    
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the waitingListReservations property]
```

### onClose (Line 21)

**Context:**

```swift
    @State private var isLoading = false
    @State private var waitingListReservations: [Reservation] = []
    
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
```

**Suggested Documentation:**

```swift
/// [Description of the onClose property]
```

### onEdit (Line 22)

**Context:**

```swift
    @State private var waitingListReservations: [Reservation] = []
    
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the onEdit property]
```

### onConfirm (Line 23)

**Context:**

```swift
    
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
        VStack {
```

**Suggested Documentation:**

```swift
/// [Description of the onConfirm property]
```

### body (Line 25)

**Context:**

```swift
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading waiting list...")
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### filtered (Line 32)

**Context:**

```swift
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    let filtered = waitingListReservations
                    let grouped = groupByCategory(filtered)
                    
                    if !grouped.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the filtered property]
```

### grouped (Line 33)

**Context:**

```swift
            } else {
                List(selection: $selection) {
                    let filtered = waitingListReservations
                    let grouped = groupByCategory(filtered)
                    
                    if !grouped.isEmpty {
                        ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### targetDateString (Line 130)

**Context:**

```swift
        Task {
            do {
                // Fetch all waiting list reservations for the date directly from Firebase
                let targetDateString = DateHelper.formatDate(appState.selectedDate)
                let db = Firestore.firestore()
                
                #if DEBUG
```

**Suggested Documentation:**

```swift
/// [Description of the targetDateString property]
```

### db (Line 131)

**Context:**

```swift
            do {
                // Fetch all waiting list reservations for the date directly from Firebase
                let targetDateString = DateHelper.formatDate(appState.selectedDate)
                let db = Firestore.firestore()
                
                #if DEBUG
                let reservationsRef = db.collection("reservations")
```

**Suggested Documentation:**

```swift
/// [Description of the db property]
```

### reservationsRef (Line 134)

**Context:**

```swift
                let db = Firestore.firestore()
                
                #if DEBUG
                let reservationsRef = db.collection("reservations")
                #else
                let reservationsRef = db.collection("reservations_release")
                #endif
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsRef property]
```

### reservationsRef (Line 136)

**Context:**

```swift
                #if DEBUG
                let reservationsRef = db.collection("reservations")
                #else
                let reservationsRef = db.collection("reservations_release")
                #endif
                
                let snapshot = try await reservationsRef
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsRef property]
```

### snapshot (Line 139)

**Context:**

```swift
                let reservationsRef = db.collection("reservations_release")
                #endif
                
                let snapshot = try await reservationsRef
                    .whereField("dateString", isEqualTo: targetDateString)
                    .whereField("reservationType", isEqualTo: "waitingList")
                    .getDocuments()
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### results (Line 144)

**Context:**

```swift
                    .whereField("reservationType", isEqualTo: "waitingList")
                    .getDocuments()
                
                var results: [Reservation] = []
                
                for document in snapshot.documents {
                    let data = document.data()
```

**Suggested Documentation:**

```swift
/// [Description of the results property]
```

### data (Line 147)

**Context:**

```swift
                var results: [Reservation] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    if let reservation = try? reservationFromFirebaseData(data) {
                        results.append(reservation)
                    } else {
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### reservation (Line 148)

**Context:**

```swift
                
                for document in snapshot.documents {
                    let data = document.data()
                    if let reservation = try? reservationFromFirebaseData(data) {
                        results.append(reservation)
                    } else {
                        print("Failed to decode reservation from document: \(document.documentID)")
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### idString (Line 171)

**Context:**

```swift
    /// Converts Firebase document data to a Reservation object
    private func reservationFromFirebaseData(_ data: [String: Any]) throws -> Reservation {
        // Extract basic fields
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the idString property]
```

### id (Line 172)

**Context:**

```swift
    private func reservationFromFirebaseData(_ data: [String: Any]) throws -> Reservation {
        // Extract basic fields
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### name (Line 173)

**Context:**

```swift
        // Extract basic fields
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### phone (Line 174)

**Context:**

```swift
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the phone property]
```

### numberOfPersons (Line 175)

**Context:**

```swift
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### dateString (Line 176)

**Context:**

```swift
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### categoryString (Line 177)

**Context:**

```swift
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the categoryString property]
```

### category (Line 178)

**Context:**

```swift
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### startTime (Line 179)

**Context:**

```swift
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 180)

**Context:**

```swift
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### acceptanceString (Line 181)

**Context:**

```swift
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
```

**Suggested Documentation:**

```swift
/// [Description of the acceptanceString property]
```

### acceptance (Line 182)

**Context:**

```swift
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### statusString (Line 183)

**Context:**

```swift
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
```

**Suggested Documentation:**

```swift
/// [Description of the statusString property]
```

### status (Line 184)

**Context:**

```swift
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationTypeString (Line 185)

**Context:**

```swift
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
```

**Suggested Documentation:**

```swift
/// [Description of the reservationTypeString property]
```

### reservationType (Line 186)

**Context:**

```swift
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### group (Line 187)

**Context:**

```swift
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
```

**Suggested Documentation:**

```swift
/// [Description of the group property]
```

### creationTimeInterval (Line 188)

**Context:**

```swift
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
```

**Suggested Documentation:**

```swift
/// [Description of the creationTimeInterval property]
```

### lastEditedTimeInterval (Line 189)

**Context:**

```swift
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
```

**Suggested Documentation:**

```swift
/// [Description of the lastEditedTimeInterval property]
```

### isMock (Line 190)

**Context:**

```swift
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the isMock property]
```

### tables (Line 195)

**Context:**

```swift
        }
        
        // Extract tables
        var tables: [TableModel] = []
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### tablesData (Line 196)

**Context:**

```swift
        
        // Extract tables
        var tables: [TableModel] = []
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the tablesData property]
```

### tableId (Line 198)

**Context:**

```swift
        var tables: [TableModel] = []
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
```

**Suggested Documentation:**

```swift
/// [Description of the tableId property]
```

### tableName (Line 199)

**Context:**

```swift
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
                    tables.append(table)
```

**Suggested Documentation:**

```swift
/// [Description of the tableName property]
```

### maxCapacity (Line 200)

**Context:**

```swift
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
                    tables.append(table)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the maxCapacity property]
```

### table (Line 201)

**Context:**

```swift
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
                    tables.append(table)
                }
            }
```

**Suggested Documentation:**

```swift
/// [Description of the table property]
```

### tableIds (Line 205)

**Context:**

```swift
                    tables.append(table)
                }
            }
        } else if let tableIds = data["tableIds"] as? [Int] {
            // Fallback to tableIds if tables array is not available
            tables = tableIds.map { id in
                TableModel(id: id, name: "Table \(id)", maxCapacity: 4, row: 0, column: 0)
```

**Suggested Documentation:**

```swift
/// [Description of the tableIds property]
```

### notes (Line 213)

**Context:**

```swift
        }
        
        // Extract optional fields
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### assignedEmoji (Line 214)

**Context:**

```swift
        
        // Extract optional fields
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        let colorHue = data["colorHue"] as? Double ?? 0.0
```

**Suggested Documentation:**

```swift
/// [Description of the assignedEmoji property]
```

### imageData (Line 215)

**Context:**

```swift
        // Extract optional fields
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        let colorHue = data["colorHue"] as? Double ?? 0.0
        
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### preferredLanguage (Line 216)

**Context:**

```swift
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        let colorHue = data["colorHue"] as? Double ?? 0.0
        
        // Create and return the reservation
```

**Suggested Documentation:**

```swift
/// [Description of the preferredLanguage property]
```

### colorHue (Line 217)

**Context:**

```swift
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        let colorHue = data["colorHue"] as? Double ?? 0.0
        
        // Create and return the reservation
        return Reservation(
```

**Suggested Documentation:**

```swift
/// [Description of the colorHue property]
```

### grouped (Line 245)

**Context:**

```swift
    }
    
    private func groupByCategory(_ reservations: [Reservation]) -> [String: [Reservation]] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            var category: Reservation.ReservationCategory = .lunch
            if reservation.category == .dinner {
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### category (Line 247)

**Context:**

```swift
    private func groupByCategory(_ reservations: [Reservation]) -> [String: [Reservation]] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            var category: Reservation.ReservationCategory = .lunch
            if reservation.category == .dinner {
                category = .dinner
            }
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### key (Line 251)

**Context:**

```swift
            if reservation.category == .dinner {
                category = .dinner
            }
            let key = "\(category.localized.capitalized)"
            grouped[key, default: []].append(reservation)
        }
        return grouped
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### updatedReservation (Line 258)

**Context:**

```swift
    }
    
    private func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### assignmentResult (Line 259)

**Context:**

```swift
    
    private func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            withAnimation {
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 261)

**Context:**

```swift
        var updatedReservation = reservation
        let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            withAnimation {
                updatedReservation.tables = assignedTables
                updatedReservation.reservationType = .inAdvance
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 280)

**Context:**

```swift
                    print("Error confirming waiting list reservation: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            withAnimation {
                updatedReservation.notes = (updatedReservation.notes ?? "") + String(localized: "\n[Non è stato possibile assegnare tavoli automaticamente - ") + "\(error)]"
            }
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```


Total documentation suggestions: 63

