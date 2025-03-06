Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationCancelledView.swift...
# Documentation Suggestions for ReservationCancelledView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Views/Detail Views/ReservationCancelledView.swift
Total suggestions: 65

## Class Documentation (1)

### ReservationCancelledView (Line 12)

**Context:**

```swift
import SwipeActions
import FirebaseFirestore

struct ReservationCancelledView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

```

**Suggested Documentation:**

```swift
/// ReservationCancelledView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (3)

### loadCancelledReservations (Line 118)

**Context:**

```swift
        }
    }
    
    private func loadCancelledReservations() {
        isLoading = true
        Task {
            do {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadCancelledReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### groupByCategory (Line 237)

**Context:**

```swift
        )
    }
    
    private func groupByCategory(_ activeReservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
```

**Suggested Documentation:**

```swift
/// [Add a description of what the groupByCategory method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleRestore (Line 257)

**Context:**

```swift
        return grouped
    }
    
    private func handleRestore(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .canceled {
            let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleRestore method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (61)

### env (Line 13)

**Context:**

```swift
import FirebaseFirestore

struct ReservationCancelledView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 14)

**Context:**

```swift

struct ReservationCancelledView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### selection (Line 16)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @State private var cancelledReservations: [Reservation] = []
    @Environment(\.colorScheme) var colorScheme
```

**Suggested Documentation:**

```swift
/// [Description of the selection property]
```

### isLoading (Line 17)

**Context:**

```swift
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @State private var cancelledReservations: [Reservation] = []
    @Environment(\.colorScheme) var colorScheme

```

**Suggested Documentation:**

```swift
/// [Description of the isLoading property]
```

### cancelledReservations (Line 18)

**Context:**

```swift

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @State private var cancelledReservations: [Reservation] = []
    @Environment(\.colorScheme) var colorScheme

    let activeReservations: [Reservation]
```

**Suggested Documentation:**

```swift
/// [Description of the cancelledReservations property]
```

### colorScheme (Line 19)

**Context:**

```swift
    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @State private var cancelledReservations: [Reservation] = []
    @Environment(\.colorScheme) var colorScheme

    let activeReservations: [Reservation]
    var currentTime: Date
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### activeReservations (Line 21)

**Context:**

```swift
    @State private var cancelledReservations: [Reservation] = []
    @Environment(\.colorScheme) var colorScheme

    let activeReservations: [Reservation]
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservations property]
```

### currentTime (Line 22)

**Context:**

```swift
    @Environment(\.colorScheme) var colorScheme

    let activeReservations: [Reservation]
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```

### onClose (Line 23)

**Context:**

```swift

    let activeReservations: [Reservation]
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
    
```

**Suggested Documentation:**

```swift
/// [Description of the onClose property]
```

### onEdit (Line 24)

**Context:**

```swift
    let activeReservations: [Reservation]
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
    
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the onEdit property]
```

### onRestore (Line 25)

**Context:**

```swift
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
    
    var body: some View {
        VStack {
```

**Suggested Documentation:**

```swift
/// [Description of the onRestore property]
```

### body (Line 27)

**Context:**

```swift
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading cancelled reservations...")
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### filtered (Line 34)

**Context:**

```swift
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    let filtered = cancelledReservations
                    let grouped = groupByCategory(filtered)
                    if !grouped.isEmpty {
                        ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
```

**Suggested Documentation:**

```swift
/// [Description of the filtered property]
```

### grouped (Line 35)

**Context:**

```swift
            } else {
                List(selection: $selection) {
                    let filtered = cancelledReservations
                    let grouped = groupByCategory(filtered)
                    if !grouped.isEmpty {
                        ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                            Section(
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### targetDateString (Line 123)

**Context:**

```swift
        Task {
            do {
                // Fetch all reservations for the date directly from Firebase
                let targetDateString = DateHelper.formatDate(currentTime)
                let db = Firestore.firestore()
                
                #if DEBUG
```

**Suggested Documentation:**

```swift
/// [Description of the targetDateString property]
```

### db (Line 124)

**Context:**

```swift
            do {
                // Fetch all reservations for the date directly from Firebase
                let targetDateString = DateHelper.formatDate(currentTime)
                let db = Firestore.firestore()
                
                #if DEBUG
                let reservationsRef = db.collection("reservations")
```

**Suggested Documentation:**

```swift
/// [Description of the db property]
```

### reservationsRef (Line 127)

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

### reservationsRef (Line 129)

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

### snapshot (Line 132)

**Context:**

```swift
                let reservationsRef = db.collection("reservations_release")
                #endif
                
                let snapshot = try await reservationsRef
                    .whereField("dateString", isEqualTo: targetDateString)
                    .whereField("status", isEqualTo: "canceled")
                    .getDocuments()
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### results (Line 137)

**Context:**

```swift
                    .whereField("status", isEqualTo: "canceled")
                    .getDocuments()
                
                var results: [Reservation] = []
                
                for document in snapshot.documents {
                    let data = document.data()
```

**Suggested Documentation:**

```swift
/// [Description of the results property]
```

### data (Line 140)

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

### reservation (Line 141)

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

### idString (Line 164)

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

### id (Line 165)

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

### name (Line 166)

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

### phone (Line 167)

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

### numberOfPersons (Line 168)

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

### dateString (Line 169)

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

### categoryString (Line 170)

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

### category (Line 171)

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

### startTime (Line 172)

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

### endTime (Line 173)

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

### acceptanceString (Line 174)

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

### acceptance (Line 175)

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

### statusString (Line 176)

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

### status (Line 177)

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

### reservationTypeString (Line 178)

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

### reservationType (Line 179)

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

### group (Line 180)

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

### creationTimeInterval (Line 181)

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

### lastEditedTimeInterval (Line 182)

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

### isMock (Line 183)

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

### tables (Line 188)

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

### tablesData (Line 189)

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

### tableId (Line 191)

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

### tableName (Line 192)

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

### maxCapacity (Line 193)

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

### table (Line 194)

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

### tableIds (Line 198)

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

### notes (Line 206)

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

### assignedEmoji (Line 207)

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

### imageData (Line 208)

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

### preferredLanguage (Line 209)

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

### colorHue (Line 210)

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

### grouped (Line 240)

**Context:**

```swift
    private func groupByCategory(_ activeReservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
        for reservation in activeReservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
```

**Suggested Documentation:**

```swift
/// [Description of the grouped property]
```

### category (Line 244)

**Context:**

```swift
        for reservation in activeReservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
            var category: Reservation.ReservationCategory = .lunch
           
            if reservation.category == .dinner {
                category = .dinner
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### key (Line 250)

**Context:**

```swift
                category = .dinner
            }

            let key = "\(category.localized.capitalized)"
            grouped[key, default: []].append(reservation)
        }

```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### updatedReservation (Line 258)

**Context:**

```swift
    }
    
    private func handleRestore(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .canceled {
            let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### assignmentResult (Line 260)

**Context:**

```swift
    private func handleRestore(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .canceled {
            let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                withAnimation {
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 262)

**Context:**

```swift
        if updatedReservation.status == .canceled {
            let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                withAnimation {
                    updatedReservation.tables = assignedTables
                    updatedReservation.status = .pending
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 280)

**Context:**

```swift
                        print("Error restoring reservation: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                // If table assignment fails, still restore but without tables
                withAnimation {
                    updatedReservation.status = .pending
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```


Total documentation suggestions: 65

