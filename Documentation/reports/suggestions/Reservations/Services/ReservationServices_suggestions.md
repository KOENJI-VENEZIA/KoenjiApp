Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/ReservationServices.swift...
# Documentation Suggestions for ReservationServices.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/ReservationServices.swift
Total suggestions: 226

## Class Documentation (7)

### ReservationService (Line 961)

**Context:**

```swift
}

// MARK: - Mock Data
extension ReservationService {
    /// Loads two sample reservations for demonstration purposes
    ///
    /// This method creates and adds mock reservations to the system
```

**Suggested Documentation:**

```swift
/// ReservationService service.
///
/// [Add a description of what this service does and its responsibilities]
```

### ReservationService (Line 1009)

**Context:**

```swift
    }
}

extension ReservationService {
    // MARK: - Test Data
    
    /// Generates realistic reservation data for a specified number of days
```

**Suggested Documentation:**

```swift
/// ReservationService service.
///
/// [Add a description of what this service does and its responsibilities]
```

### ReservationService (Line 1349)

**Context:**

```swift
    
}

extension ReservationService {
    /// Clears all caches in the store and resets layouts and clusters
    ///
    /// This method removes all cached data from memory and persists
```

**Suggested Documentation:**

```swift
/// ReservationService service.
///
/// [Add a description of what this service does and its responsibilities]
```

### ReservationService (Line 1375)

**Context:**

```swift


// MARK: - Conflict Manager
extension ReservationService {

    
    // MARK: - Helper Method
```

**Suggested Documentation:**

```swift
/// ReservationService service.
///
/// [Add a description of what this service does and its responsibilities]
```

### Date (Line 1468)

**Context:**

```swift
    }
}

extension Date {
    /// Returns the start of the next minute for the current date.
    func startOfNextMinute() -> Date {
        let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: self)!
```

**Suggested Documentation:**

```swift
/// Date class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Date (Line 1476)

**Context:**

```swift
    }
}

extension Date {
    /// Returns the start of the day for the current date
    func normalizedToDayStart() -> Date {
        return Calendar.current.startOfDay(for: self)
```

**Suggested Documentation:**

```swift
/// Date class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationService (Line 1485)

**Context:**

```swift

/// Ensures all confirmed reservations in the database have tables assigned

extension ReservationService {
    /// Detects and removes duplicate reservations, prioritizing those with tables assigned
    ///
    /// This method identifies reservations with the same ID, keeps the best one
```

**Suggested Documentation:**

```swift
/// ReservationService service.
///
/// [Add a description of what this service does and its responsibilities]
```

## Method Documentation (23)

### migrateDatabaseIfNeeded (Line 146)

**Context:**

```swift
    /// - Note: When making schema changes, increment the `targetVersion` and add
    ///         the migration code for each version step.
    @MainActor
    func migrateDatabaseIfNeeded() {
        do {
            // Get the current database version.
            let currentVersion = try SQLiteManager.shared.db.scalar("PRAGMA user_version") as? Int64 ?? 0
```

**Suggested Documentation:**

```swift
/// [Add a description of what the migrateDatabaseIfNeeded method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### upsertSession (Line 177)

**Context:**

```swift
    ///
    /// - Parameter session: The session to insert or update
    @MainActor
    func upsertSession(_ session: Session) {
        SQLiteManager.shared.insertSession(session)
        
        DispatchQueue.main.async {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the upsertSession method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### addReservation (Line 215)

**Context:**

```swift
    ///
    /// - Parameter reservation: The reservation to add
    @MainActor
    func addReservation(_ reservation: Reservation) {
        // Update Database
        SQLiteManager.shared.insertReservation(reservation)

```

**Suggested Documentation:**

```swift
/// [Add a description of what the addReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### addReservations (Line 255)

**Context:**

```swift
    ///
    /// - Parameter reservations: An array of reservations to add
    @MainActor
    func addReservations(_ reservations: [Reservation]) {
        for reservation in reservations {
            SQLiteManager.shared.insertReservation(reservation)
        }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the addReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### convertSessionToDictionary (Line 266)

**Context:**

```swift
    /// - Parameter session: The session to convert
    /// - Returns: A dictionary representation of the session
    @MainActor
    private func convertSessionToDictionary(session: Session) -> [String: Any] {
        return [
            "id": session.id,
            "uuid": session.uuid,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the convertSessionToDictionary method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### convertReservationToDictionary (Line 285)

**Context:**

```swift
    /// - Parameter reservation: The reservation to convert
    /// - Returns: A dictionary representation of the reservation
    @MainActor
    private func convertReservationToDictionary(reservation: Reservation) -> [String: Any] {
        var updatedReservation = reservation
        
        // Check if this is a confirmed reservation with no tables
```

**Suggested Documentation:**

```swift
/// [Add a description of what the convertReservationToDictionary method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateReservation (Line 377)

**Context:**

```swift
    ///   - shouldPersist: Whether to persist changes to Firebase (defaults to true)
    ///   - completion: Closure to call when the update is complete
    @MainActor
    func updateReservation(_ oldReservation: Reservation, newReservation: Reservation? = nil, at index: Int? = nil, shouldPersist: Bool = true, completion: @escaping () -> Void) {
        // Remove from active cache
        self.invalidateClusterCache(for: oldReservation)
        resCache.removeReservation(oldReservation)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateAllReservationsInFirestore (Line 467)

**Context:**

```swift
    ///
    /// - Note: This operation can be resource-intensive for large datasets.
    @MainActor
    func updateAllReservationsInFirestore() async {
        logger.info("Beginning update of all reservations in Firestore...")
        
        let allReservations = self.store.reservations
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateAllReservationsInFirestore method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleConfirm (Line 510)

**Context:**

```swift
    ///
    /// - Parameter reservation: The reservation to confirm
    @MainActor
    func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleConfirm method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### clearAllDataFromFirestore (Line 551)

**Context:**

```swift
    ///
    /// - Parameter completion: Closure called when the operation completes, with an optional error
    @MainActor
    func clearAllDataFromFirestore(completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        #if DEBUG
        let reservationsRef = db.collection("reservations")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the clearAllDataFromFirestore method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### clearAllData (Line 596)

**Context:**

```swift
    ///
    /// Use with extreme caution as this operation cannot be undone.
    @MainActor 
    func clearAllData() {
        store.reservations.removeAll() // Clear in-memory reservations
        
        SQLiteManager.shared.deleteAllReservations()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the clearAllData method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### loadReservationsFromFirebase (Line 672)

**Context:**

```swift
    /// and updates the local database and caches with the retrieved data.
    /// It also ensures that confirmed reservations have tables assigned.
    @MainActor
    func loadReservationsFromFirebase() {
        logger.info("Loading reservations directly from Firebase...")
        
        withAnimation {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadReservationsFromFirebase method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### loadSessionsFromFirebase (Line 757)

**Context:**

```swift
    /// This method fetches all session data from Firebase, processes it,
    /// and updates the session store with the retrieved data.
    @MainActor
    func loadSessionsFromFirebase() {
        logger.info("Loading sessions directly from Firebase...")
        
        withAnimation {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadSessionsFromFirebase method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### convertDictionaryToSession (Line 893)

**Context:**

```swift
    /// - Parameter data: Dictionary containing session data from Firebase
    /// - Returns: A Session object if conversion is successful, nil otherwise
    @MainActor
    private func convertDictionaryToSession(data: [String: Any]) -> Session? {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the convertDictionaryToSession method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### mockData (Line 967)

**Context:**

```swift
    /// This method creates and adds mock reservations to the system
    /// for testing and demonstration purposes.
    @MainActor
    private func mockData() {
        layoutServices.setTables(tableStore.baseTables)
        self.logger.debug("Tables populated in mockData: \(self.layoutServices.tables.map { $0.name })")
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the mockData method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateReservations (Line 1022)

**Context:**

```swift
    ///   - force: Whether to force generation even if data already exists
    ///   - startFromLastSaved: Whether to start from the last saved reservation date
    @MainActor
    func generateReservations(
        daysToSimulate: Int,
        force: Bool = false,
        startFromLastSaved: Bool = true
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### generateReservationsForDay (Line 1085)

**Context:**

```swift
    ///   - phoneNumbers: Array of phone numbers to use for reservations
    ///   - notes: Array of notes to use for reservations
    @MainActor
    private func generateReservationsForDay(
        dayOffset: Int,
        startDate: Date,
        names: [String],
```

**Suggested Documentation:**

```swift
/// [Add a description of what the generateReservationsForDay method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### simulateUserActions (Line 1283)

**Context:**

```swift
    ///
    /// - Parameter actionCount: Number of actions to simulate
    @MainActor
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the simulateUserActions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### flushAllCaches (Line 1355)

**Context:**

```swift
    /// This method removes all cached data from memory and persists
    /// the changes to disk to ensure a clean state.
    @MainActor
    func flushAllCaches() {
        DispatchQueue.main.async {
            // Clear cached layouts
            self.layoutServices.cachedLayouts.removeAll()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the flushAllCaches method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### separateReservation (Line 1390)

**Context:**

```swift
    ///   - notesToAdd: Optional notes to add to the reservation
    /// - Returns: The updated reservation
    @MainActor
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        var updatedReservation = reservation  // Create a mutable copy
        let finalNotes = notesToAdd == "" ? "" : "\(notesToAdd)\n\n"
        updatedReservation.status = .pending
```

**Suggested Documentation:**

```swift
/// [Add a description of what the separateReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteReservation (Line 1405)

**Context:**

```swift
    ///
    /// - Parameter reservation: The reservation to delete
    @MainActor
    func deleteReservation(_ reservation: Reservation) {
        var updatedReservation = reservation  // Create a mutable copy
        updatedReservation.reservationType = .na
        updatedReservation.status = .deleted
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### ensureConfirmedReservationsHaveTables (Line 1423)

**Context:**

```swift
    /// This method scans the database for confirmed reservations without
    /// tables and attempts to assign tables to them.
    @MainActor
    func ensureConfirmedReservationsHaveTables() {
        logger.info("Scanning database for confirmed reservations without tables...")
        
        var updatedCount = 0
```

**Suggested Documentation:**

```swift
/// [Add a description of what the ensureConfirmedReservationsHaveTables method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### removeDuplicateReservations (Line 1491)

**Context:**

```swift
    /// This method identifies reservations with the same ID, keeps the best one
    /// (prioritizing those with tables or the most recently edited), and removes the others.
    @MainActor
    func removeDuplicateReservations() {
        logger.info("Checking for duplicate reservations...")
        
        // Group reservations by ID
```

**Suggested Documentation:**

```swift
/// [Add a description of what the removeDuplicateReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (196)

### today (Line 127)

**Context:**

```swift
        self.loadReservationsFromFirebase()
        self.loadSessionsFromFirebase()
        
        let today = Calendar.current.startOfDay(for: Date())
        self.resCache.preloadDates(around: today, range: 5, reservations: self.store.reservations)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the today property]
```

### currentVersion (Line 149)

**Context:**

```swift
    func migrateDatabaseIfNeeded() {
        do {
            // Get the current database version.
            let currentVersion = try SQLiteManager.shared.db.scalar("PRAGMA user_version") as? Int64 ?? 0
            let targetVersion: Int64 = 2  // Increment this whenever you change your schema
            
            if currentVersion < targetVersion {
```

**Suggested Documentation:**

```swift
/// [Description of the currentVersion property]
```

### targetVersion (Line 150)

**Context:**

```swift
        do {
            // Get the current database version.
            let currentVersion = try SQLiteManager.shared.db.scalar("PRAGMA user_version") as? Int64 ?? 0
            let targetVersion: Int64 = 2  // Increment this whenever you change your schema
            
            if currentVersion < targetVersion {
                // Example: For version 2, add the sessionUUID column to sessions table.
```

**Suggested Documentation:**

```swift
/// [Description of the targetVersion property]
```

### dbRef (Line 187)

**Context:**

```swift
        
        // Push changes to Firestore
        #if DEBUG
        let dbRef = backupService.db.collection("sessions")
        #else
        let dbRef = backupService.db.collection("sessions_release")
        #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 189)

**Context:**

```swift
        #if DEBUG
        let dbRef = backupService.db.collection("sessions")
        #else
        let dbRef = backupService.db.collection("sessions_release")
        #endif
        let data = convertSessionToDictionary(session: session)
            // Using the reservation's UUID string as the document ID:
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### data (Line 191)

**Context:**

```swift
        #else
        let dbRef = backupService.db.collection("sessions_release")
        #endif
        let data = convertSessionToDictionary(session: session)
            // Using the reservation's UUID string as the document ID:
        dbRef.document(session.uuid).setData(data) { [self] error in
                if let error = error {
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### error (Line 194)

**Context:**

```swift
        let data = convertSessionToDictionary(session: session)
            // Using the reservation's UUID string as the document ID:
        dbRef.document(session.uuid).setData(data) { [self] error in
                if let error = error {
                    self.logger.error("Error pushing session to Firebase: \(error)")
                } else {
                    self.logger.debug("Session pushed to Firebase successfully.")
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### dbRef (Line 232)

**Context:**

```swift
        
        // Push changes to Firestore with the improved dictionary conversion
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 234)

**Context:**

```swift
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        let data = convertReservationToDictionary(reservation: reservation)
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### data (Line 237)

**Context:**

```swift
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        let data = convertReservationToDictionary(reservation: reservation)
        
        // Using the reservation's UUID string as the document ID:
        dbRef.document(reservation.id.uuidString).setData(data) { error in
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### error (Line 241)

**Context:**

```swift
        
        // Using the reservation's UUID string as the document ID:
        dbRef.document(reservation.id.uuidString).setData(data) { error in
            if let error = error {
                self.logger.error("Error pushing reservation to Firebase: \(error)")
            } else {
                self.logger.debug("Reservation pushed to Firebase successfully.")
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### updatedReservation (Line 286)

**Context:**

```swift
    /// - Returns: A dictionary representation of the reservation
    @MainActor
    private func convertReservationToDictionary(reservation: Reservation) -> [String: Any] {
        var updatedReservation = reservation
        
        // Check if this is a confirmed reservation with no tables
        if updatedReservation.acceptance == .confirmed && updatedReservation.tables.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### layoutServices (Line 294)

**Context:**

```swift
            logger.warning("⚠️ Found confirmed reservation with no tables: \(updatedReservation.name)")
            
            // Try to assign tables automatically
                let layoutServices = self.layoutServices
                let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
```

**Suggested Documentation:**

```swift
/// [Description of the layoutServices property]
```

### assignmentResult (Line 295)

**Context:**

```swift
            
            // Try to assign tables automatically
                let layoutServices = self.layoutServices
                let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    logger.info("✅ Auto-assigned \(assignedTables.count) tables to reservation: \(updatedReservation.name)")
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 297)

**Context:**

```swift
                let layoutServices = self.layoutServices
                let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    logger.info("✅ Auto-assigned \(assignedTables.count) tables to reservation: \(updatedReservation.name)")
                    updatedReservation.tables = assignedTables
                case .failure(let error):
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 300)

**Context:**

```swift
                case .success(let assignedTables):
                    logger.info("✅ Auto-assigned \(assignedTables.count) tables to reservation: \(updatedReservation.name)")
                    updatedReservation.tables = assignedTables
                case .failure(let error):
                    logger.error("❌ Failed to auto-assign tables: \(error.localizedDescription)")
                }
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### tableIds (Line 309)

**Context:**

```swift
        
        
        // Convert tables to a simpler format that Firestore can handle better
        let tableIds = updatedReservation.tables.map { $0.id }
        
        // Create a thread-safe copy for Firestore
        var dict: [String: Any] = [
```

**Suggested Documentation:**

```swift
/// [Description of the tableIds property]
```

### dict (Line 312)

**Context:**

```swift
        let tableIds = updatedReservation.tables.map { $0.id }
        
        // Create a thread-safe copy for Firestore
        var dict: [String: Any] = [
            "id": updatedReservation.id.uuidString,
            "name": updatedReservation.name,
            "phone": updatedReservation.phone,
```

**Suggested Documentation:**

```swift
/// [Description of the dict property]
```

### notes (Line 341)

**Context:**

```swift
        ]
        
        // Handle optional values separately and safely
        if let notes = updatedReservation.notes {
            dict["notes"] = notes
        } else {
            dict["notes"] = NSNull()
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### assignedEmoji (Line 347)

**Context:**

```swift
            dict["notes"] = NSNull()
        }
        
        if let assignedEmoji = updatedReservation.assignedEmoji {
            dict["assignedEmoji"] = assignedEmoji
        } else {
            dict["assignedEmoji"] = NSNull()
```

**Suggested Documentation:**

```swift
/// [Description of the assignedEmoji property]
```

### imageData (Line 353)

**Context:**

```swift
            dict["assignedEmoji"] = NSNull()
        }
        
        if let imageData = updatedReservation.imageData {
            dict["imageData"] = imageData
        } else {
            dict["imageData"] = NSNull()
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### updatedReservation (Line 382)

**Context:**

```swift
        self.invalidateClusterCache(for: oldReservation)
        resCache.removeReservation(oldReservation)
        
        let updatedReservation = newReservation ?? oldReservation

        DispatchQueue.main.async {
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == oldReservation.id })
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### reservationIndex (Line 385)

**Context:**

```swift
        let updatedReservation = newReservation ?? oldReservation

        DispatchQueue.main.async {
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == oldReservation.id })

            guard let reservationIndex else {
                self.logger.error("Error: Reservation with ID \(oldReservation.id) not found.")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationIndex property]
```

### reservationIndex (Line 387)

**Context:**

```swift
        DispatchQueue.main.async {
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == oldReservation.id })

            guard let reservationIndex else {
                self.logger.error("Error: Reservation with ID \(oldReservation.id) not found.")
                return
            }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationIndex property]
```

### oldReservation (Line 399)

**Context:**

```swift
            self.changedReservation = updatedReservation
            self.logger.info("Changed changedReservation, should update UI...")

            let oldReservation = self.store.reservations[reservationIndex]
            
            // 🔹 Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables.map { $0.id })
```

**Suggested Documentation:**

```swift
/// [Description of the oldReservation property]
```

### oldTableIDs (Line 402)

**Context:**

```swift
            let oldReservation = self.store.reservations[reservationIndex]
            
            // 🔹 Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables.map { $0.id })
            let newTableIDs = Set(updatedReservation.tables.map { $0.id })
            
            if oldTableIDs != newTableIDs {
```

**Suggested Documentation:**

```swift
/// [Description of the oldTableIDs property]
```

### newTableIDs (Line 403)

**Context:**

```swift
            
            // 🔹 Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables.map { $0.id })
            let newTableIDs = Set(updatedReservation.tables.map { $0.id })
            
            if oldTableIDs != newTableIDs {
                self.logger.debug("Table change detected for reservation \(updatedReservation.id). Updating tables...")
```

**Suggested Documentation:**

```swift
/// [Description of the newTableIDs property]
```

### table (Line 410)

**Context:**

```swift

                // Unmark only if tables have changed
                for tableID in oldTableIDs.subtracting(newTableIDs) {
                    if let table = oldReservation.tables.first(where: { $0.id == tableID }) {
                        self.layoutServices.unmarkTable(table)
                    }
                }
```

**Suggested Documentation:**

```swift
/// [Description of the table property]
```

### table (Line 417)

**Context:**

```swift

                // Mark only new tables that weren't already assigned
                for tableID in newTableIDs.subtracting(oldTableIDs) {
                    if let table = updatedReservation.tables.first(where: { $0.id == tableID }) {
                        self.layoutServices.markTable(table, occupied: true)
                    }
                }
```

**Suggested Documentation:**

```swift
/// [Description of the table property]
```

### dbRef (Line 437)

**Context:**

```swift
                // Update database
                // Pushes to Firestore with the improved dictionary conversion
                #if DEBUG
                let dbRef = self.backupService.db.collection("reservations")
                #else
                let dbRef = self.backupService.db.collection("reservations_release")
                #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 439)

**Context:**

```swift
                #if DEBUG
                let dbRef = self.backupService.db.collection("reservations")
                #else
                let dbRef = self.backupService.db.collection("reservations_release")
                #endif
                
                let data = self.convertReservationToDictionary(reservation: updatedReservation)
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### data (Line 442)

**Context:**

```swift
                let dbRef = self.backupService.db.collection("reservations_release")
                #endif
                
                let data = self.convertReservationToDictionary(reservation: updatedReservation)
                
                // Using the reservation's UUID string as the document ID:
                dbRef.document(updatedReservation.id.uuidString).setData(data) { error in
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### error (Line 446)

**Context:**

```swift
                
                // Using the reservation's UUID string as the document ID:
                dbRef.document(updatedReservation.id.uuidString).setData(data) { error in
                    if let error = error {
                        self.logger.error("Error pushing reservation to Firebase: \(error)")
                    } else {
                        self.logger.debug("Reservation pushed to Firebase successfully.")
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### allReservations (Line 470)

**Context:**

```swift
    func updateAllReservationsInFirestore() async {
        logger.info("Beginning update of all reservations in Firestore...")
        
        let allReservations = self.store.reservations
        
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
```

**Suggested Documentation:**

```swift
/// [Description of the allReservations property]
```

### dbRef (Line 473)

**Context:**

```swift
        let allReservations = self.store.reservations
        
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 475)

**Context:**

```swift
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        var successCount = 0
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### successCount (Line 478)

**Context:**

```swift
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        var successCount = 0
        var errorCount = 0
        
        for reservation in allReservations {
```

**Suggested Documentation:**

```swift
/// [Description of the successCount property]
```

### errorCount (Line 479)

**Context:**

```swift
        #endif
        
        var successCount = 0
        var errorCount = 0
        
        for reservation in allReservations {
            do {
```

**Suggested Documentation:**

```swift
/// [Description of the errorCount property]
```

### data (Line 484)

**Context:**

```swift
        for reservation in allReservations {
            do {
                // Since convertReservationToDictionary is also @MainActor, we're staying on the same actor
                let data = convertReservationToDictionary(reservation: reservation)
                
                // Create a properly isolated copy of the dictionary for Firestore
                try await Task {
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### updatedReservation (Line 511)

**Context:**

```swift
    /// - Parameter reservation: The reservation to confirm
    @MainActor
    func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### assignmentResult (Line 513)

**Context:**

```swift
    func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 515)

**Context:**

```swift
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
                    // do actual saving logic here
                    updatedReservation.tables = assignedTables
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 526)

**Context:**

```swift
                    }

                }
            case .failure(let error):
                switch error {
                    case .noTablesLeft:
                    pushAlerts.alertMessage = String(localized: "Non ci sono tavoli disponibili.")
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### db (Line 552)

**Context:**

```swift
    /// - Parameter completion: Closure called when the operation completes, with an optional error
    @MainActor
    func clearAllDataFromFirestore(completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        #if DEBUG
        let reservationsRef = db.collection("reservations")
        #else
```

**Suggested Documentation:**

```swift
/// [Description of the db property]
```

### reservationsRef (Line 554)

**Context:**

```swift
    func clearAllDataFromFirestore(completion: @escaping (Error?) -> Void) {
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

### reservationsRef (Line 556)

**Context:**

```swift
        #if DEBUG
        let reservationsRef = db.collection("reservations")
        #else
        let reservationsRef = db.collection("reservations_release")
        #endif
        reservationsRef.getDocuments { snapshot, error in
            if let error = error {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsRef property]
```

### error (Line 559)

**Context:**

```swift
        let reservationsRef = db.collection("reservations_release")
        #endif
        reservationsRef.getDocuments { snapshot, error in
            if let error = error {
                self.logger.error("Error fetching documents for deletion: \(error)")
                completion(error)
                return
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### snapshot (Line 565)

**Context:**

```swift
                return
            }
            
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### batch (Line 570)

**Context:**

```swift
                return
            }
            
            let batch = db.batch()
            snapshot.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the batch property]
```

### error (Line 576)

**Context:**

```swift
            }
            
            batch.commit { error in
                if let error = error {
                    self.logger.error("Error committing batch deletion: \(error)")
                } else {
                    self.logger.debug("Successfully deleted all reservations from Firestore.")
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### error (Line 603)

**Context:**

```swift
        flushAllCaches() // Clear any cached layouts or data
        
        clearAllDataFromFirestore { error in
               if let error = error {
                   self.logger.error("Error clearing Firestore data: \(error)")
               } else {
                   self.logger.debug("All Firestore data cleared successfully.")
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### targetDateString (Line 617)

**Context:**

```swift
    /// - Parameter date: The date for which to fetch reservations.
    /// - Returns: A list of reservations for the given date.
    func fetchReservations(on date: Date) -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date) // Use centralized helper
        return store.reservations.filter { $0.dateString == targetDateString }
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the targetDateString property]
```

### reservationDate (Line 640)

**Context:**

```swift
    ///
    /// - Parameter reservation: The reservation to invalidate cache for
    private func invalidateClusterCache(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate else {
            self.logger.error("Failed to parse dateString \(reservation.normalizedDate ?? Date()). Cache invalidation skipped.")
            return
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### allReservations (Line 655)

**Context:**

```swift
    /// - Returns: A list of reservations matching the category.
    func getReservations(by category: Reservation.ReservationCategory) -> [Reservation] {
        // Retrieve all reservations from the ReservationStore
        let allReservations = store.getReservations()
        
        // Filter reservations matching the specified category
        let filteredReservations = allReservations.filter { $0.category == category }
```

**Suggested Documentation:**

```swift
/// [Description of the allReservations property]
```

### filteredReservations (Line 658)

**Context:**

```swift
        let allReservations = store.getReservations()
        
        // Filter reservations matching the specified category
        let filteredReservations = allReservations.filter { $0.category == category }
        
        // Return the filtered list
        return filteredReservations
```

**Suggested Documentation:**

```swift
/// [Description of the filteredReservations property]
```

### reservationsRef (Line 680)

**Context:**

```swift
        }
        
        #if DEBUG
        let reservationsRef = backupService.db.collection("reservations")
        #else
        let reservationsRef = backupService.db.collection("reservations_release")
        #endif
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsRef property]
```

### reservationsRef (Line 682)

**Context:**

```swift
        #if DEBUG
        let reservationsRef = backupService.db.collection("reservations")
        #else
        let reservationsRef = backupService.db.collection("reservations_release")
        #endif
        
        Task {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsRef property]
```

### snapshot (Line 687)

**Context:**

```swift
        
        Task {
            do {
                let snapshot = try await reservationsRef.getDocuments()
                logger.info("Retrieved \(snapshot.documents.count) reservation documents from Firebase")
                
                var loadedReservations: [Reservation] = []
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### loadedReservations (Line 690)

**Context:**

```swift
                let snapshot = try await reservationsRef.getDocuments()
                logger.info("Retrieved \(snapshot.documents.count) reservation documents from Firebase")
                
                var loadedReservations: [Reservation] = []
                var failedCount = 0
                
                for document in snapshot.documents {
```

**Suggested Documentation:**

```swift
/// [Description of the loadedReservations property]
```

### failedCount (Line 691)

**Context:**

```swift
                logger.info("Retrieved \(snapshot.documents.count) reservation documents from Firebase")
                
                var loadedReservations: [Reservation] = []
                var failedCount = 0
                
                for document in snapshot.documents {
                    do {
```

**Suggested Documentation:**

```swift
/// [Description of the failedCount property]
```

### reservation (Line 695)

**Context:**

```swift
                
                for document in snapshot.documents {
                    do {
                        let reservation = try self.reservationFromFirebaseDocument(document)
                        
                        // Ensure confirmed reservations have tables
                        if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### assignmentResult (Line 701)

**Context:**

```swift
                        if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
                            logger.warning("⚠️ Found confirmed reservation with no tables: \(reservation.name)")
                            
                            let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                            if case .success(let assignedTables) = assignmentResult {
                                var updatedReservation = reservation
                                updatedReservation.tables = assignedTables
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 702)

**Context:**

```swift
                            logger.warning("⚠️ Found confirmed reservation with no tables: \(reservation.name)")
                            
                            let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                            if case .success(let assignedTables) = assignmentResult {
                                var updatedReservation = reservation
                                updatedReservation.tables = assignedTables
                                loadedReservations.append(updatedReservation)
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### updatedReservation (Line 703)

**Context:**

```swift
                            
                            let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                            if case .success(let assignedTables) = assignmentResult {
                                var updatedReservation = reservation
                                updatedReservation.tables = assignedTables
                                loadedReservations.append(updatedReservation)
                                logger.info("✅ Auto-assigned \(assignedTables.count) tables to reservation: \(updatedReservation.name)")
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### today (Line 734)

**Context:**

```swift
                    }
                    
                    // Preload dates for the cache
                    let today = Calendar.current.startOfDay(for: Date())
                    self.resCache.preloadDates(around: today, range: 5, reservations: loadedReservations)
                    
                    logger.info("Successfully loaded \(loadedReservations.count) reservations from Firebase")
```

**Suggested Documentation:**

```swift
/// [Description of the today property]
```

### sessionsRef (Line 765)

**Context:**

```swift
        }
        
        #if DEBUG
        let sessionsRef = backupService.db.collection("sessions")
        #else
        let sessionsRef = backupService.db.collection("sessions_release")
        #endif
```

**Suggested Documentation:**

```swift
/// [Description of the sessionsRef property]
```

### sessionsRef (Line 767)

**Context:**

```swift
        #if DEBUG
        let sessionsRef = backupService.db.collection("sessions")
        #else
        let sessionsRef = backupService.db.collection("sessions_release")
        #endif
        
        Task {
```

**Suggested Documentation:**

```swift
/// [Description of the sessionsRef property]
```

### snapshot (Line 772)

**Context:**

```swift
        
        Task {
            do {
                let snapshot = try await sessionsRef.getDocuments()
                var loadedSessions: [Session] = []
                
                for document in snapshot.documents {
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### loadedSessions (Line 773)

**Context:**

```swift
        Task {
            do {
                let snapshot = try await sessionsRef.getDocuments()
                var loadedSessions: [Session] = []
                
                for document in snapshot.documents {
                    if let session = try? self.sessionFromFirebaseDocument(document) {
```

**Suggested Documentation:**

```swift
/// [Description of the loadedSessions property]
```

### session (Line 776)

**Context:**

```swift
                var loadedSessions: [Session] = []
                
                for document in snapshot.documents {
                    if let session = try? self.sessionFromFirebaseDocument(document) {
                        loadedSessions.append(session)
                    } else {
                        logger.error("Failed to decode session from document: \(document.documentID)")
```

**Suggested Documentation:**

```swift
/// [Description of the session property]
```

### data (Line 810)

**Context:**

```swift
    /// - Returns: A Reservation object
    /// - Throws: An error if required fields are missing or invalid
    func reservationFromFirebaseDocument(_ document: DocumentSnapshot) throws -> Reservation {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### idString (Line 815)

**Context:**

```swift
        }
        
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

### id (Line 816)

**Context:**

```swift
        
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

### name (Line 817)

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

### phone (Line 818)

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

### numberOfPersons (Line 819)

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

### dateString (Line 820)

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

### categoryString (Line 821)

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

### category (Line 822)

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

### startTime (Line 823)

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

### endTime (Line 824)

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

### acceptanceString (Line 825)

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

### acceptance (Line 826)

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

### statusString (Line 827)

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

### status (Line 828)

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

### reservationTypeString (Line 829)

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

### reservationType (Line 830)

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

### group (Line 831)

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

### creationTimeInterval (Line 832)

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

### lastEditedTimeInterval (Line 833)

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

### isMock (Line 834)

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

### tables (Line 839)

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

### tablesData (Line 840)

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

### tableId (Line 842)

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

### tableName (Line 843)

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

### maxCapacity (Line 844)

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

### table (Line 845)

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

### tableIds (Line 849)

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

### notes (Line 857)

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

### assignedEmoji (Line 858)

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

### imageData (Line 859)

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

### preferredLanguage (Line 860)

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

### colorHue (Line 861)

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

### id (Line 894)

**Context:**

```swift
    /// - Returns: A Session object if conversion is successful, nil otherwise
    @MainActor
    private func convertDictionaryToSession(data: [String: Any]) -> Session? {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### userName (Line 895)

**Context:**

```swift
    @MainActor
    private func convertDictionaryToSession(data: [String: Any]) -> Session? {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
```

**Suggested Documentation:**

```swift
/// [Description of the userName property]
```

### isEditing (Line 896)

**Context:**

```swift
    private func convertDictionaryToSession(data: [String: Any]) -> Session? {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            logger.error("Missing required fields in session data")
```

**Suggested Documentation:**

```swift
/// [Description of the isEditing property]
```

### lastUpdateTimestamp (Line 897)

**Context:**

```swift
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            logger.error("Missing required fields in session data")
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the lastUpdateTimestamp property]
```

### isActive (Line 898)

**Context:**

```swift
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            logger.error("Missing required fields in session data")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the isActive property]
```

### lastUpdate (Line 903)

**Context:**

```swift
            return nil
        }
        
        let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
        let uuid = data["uuid"] as? String ?? UUID().uuidString
        
        return Session(
```

**Suggested Documentation:**

```swift
/// [Description of the lastUpdate property]
```

### uuid (Line 904)

**Context:**

```swift
        }
        
        let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
        let uuid = data["uuid"] as? String ?? UUID().uuidString
        
        return Session(
            id: id,
```

**Suggested Documentation:**

```swift
/// [Description of the uuid property]
```

### data (Line 925)

**Context:**

```swift
    /// - Returns: A Session object
    /// - Throws: An error if required fields are missing or invalid
    private func sessionFromFirebaseDocument(_ document: DocumentSnapshot) throws -> Session {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### id (Line 930)

**Context:**

```swift
        }
        
        // Extract fields
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimeInterval = data["lastUpdate"] as? TimeInterval,
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### userName (Line 931)

**Context:**

```swift
        
        // Extract fields
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimeInterval = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
```

**Suggested Documentation:**

```swift
/// [Description of the userName property]
```

### isEditing (Line 932)

**Context:**

```swift
        // Extract fields
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimeInterval = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
```

**Suggested Documentation:**

```swift
/// [Description of the isEditing property]
```

### lastUpdateTimeInterval (Line 933)

**Context:**

```swift
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimeInterval = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
```

**Suggested Documentation:**

```swift
/// [Description of the lastUpdateTimeInterval property]
```

### isActive (Line 934)

**Context:**

```swift
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimeInterval = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the isActive property]
```

### uuid (Line 938)

**Context:**

```swift
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        let uuid = data["uuid"] as? String ?? document.documentID
        
        // Create and return the session
        return Session(
```

**Suggested Documentation:**

```swift
/// [Description of the uuid property]
```

### documentDirectory (Line 955)

**Context:**

```swift
    ///
    /// - Returns: URL to the reservations file
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(store.reservationsFileName)
    }
}
```

**Suggested Documentation:**

```swift
/// [Description of the documentDirectory property]
```

### mockReservation1 (Line 971)

**Context:**

```swift
        layoutServices.setTables(tableStore.baseTables)
        self.logger.debug("Tables populated in mockData: \(self.layoutServices.tables.map { $0.name })")
        
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
```

**Suggested Documentation:**

```swift
/// [Description of the mockReservation1 property]
```

### mockReservation2 (Line 987)

**Context:**

```swift
            isMock: true
        )
        
        let mockReservation2 = Reservation(
            name: "Bob",
            phone: "+33 98765432101",
            numberOfPersons: 4,
```

**Suggested Documentation:**

```swift
/// [Description of the mockReservation2 property]
```

### startDate (Line 1028)

**Context:**

```swift
        startFromLastSaved: Bool = true
    ) async {
        // 1. Determine start date
        var startDate = Calendar.current.startOfDay(for: Date())

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### maxReservation (Line 1031)

**Context:**

```swift
        var startDate = Calendar.current.startOfDay(for: Date())

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                guard let lhsDate = lhs.startTimeDate, let rhsDate = rhs.startTimeDate else {
                    return false
                }
```

**Suggested Documentation:**

```swift
/// [Description of the maxReservation property]
```

### lhsDate (Line 1032)

**Context:**

```swift

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                guard let lhsDate = lhs.startTimeDate, let rhsDate = rhs.startTimeDate else {
                    return false
                }
                return lhsDate < rhsDate
```

**Suggested Documentation:**

```swift
/// [Description of the lhsDate property]
```

### rhsDate (Line 1032)

**Context:**

```swift

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                guard let lhsDate = lhs.startTimeDate, let rhsDate = rhs.startTimeDate else {
                    return false
                }
                return lhsDate < rhsDate
```

**Suggested Documentation:**

```swift
/// [Description of the rhsDate property]
```

### lastReservationDate (Line 1037)

**Context:**

```swift
                }
                return lhsDate < rhsDate
            }) {
                if let lastReservationDate = maxReservation.startTimeDate,
                   let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastReservationDate) {
                    startDate = nextDay
                }
```

**Suggested Documentation:**

```swift
/// [Description of the lastReservationDate property]
```

### nextDay (Line 1038)

**Context:**

```swift
                return lhsDate < rhsDate
            }) {
                if let lastReservationDate = maxReservation.startTimeDate,
                   let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastReservationDate) {
                    startDate = nextDay
                }
            }
```

**Suggested Documentation:**

```swift
/// [Description of the nextDay property]
```

### names (Line 1045)

**Context:**

```swift
        }

        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

```

**Suggested Documentation:**

```swift
/// [Description of the names property]
```

### phoneNumbers (Line 1046)

**Context:**

```swift

        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
```

**Suggested Documentation:**

```swift
/// [Description of the phoneNumbers property]
```

### notes (Line 1047)

**Context:**

```swift
        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
            self.logger.warning("Required resources are missing. Reservation generation aborted.")
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### reservationDate (Line 1092)

**Context:**

```swift
        phoneNumbers: [String],
        notes: [String]
    ) async {
        let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)!
        let dayOfWeek = Calendar.current.component(.weekday, from: reservationDate)

        // Skip Mondays
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### dayOfWeek (Line 1093)

**Context:**

```swift
        notes: [String]
    ) async {
        let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)!
        let dayOfWeek = Calendar.current.component(.weekday, from: reservationDate)

        // Skip Mondays
        if dayOfWeek == 2 {
```

**Suggested Documentation:**

```swift
/// [Description of the dayOfWeek property]
```

### maxDailyReservations (Line 1101)

**Context:**

```swift
            return
        }

        let maxDailyReservations = Int.random(in: 10...30)
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
```

**Suggested Documentation:**

```swift
/// [Description of the maxDailyReservations property]
```

### totalGeneratedReservations (Line 1102)

**Context:**

```swift
        }

        let maxDailyReservations = Int.random(in: 10...30)
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 14)))
```

**Suggested Documentation:**

```swift
/// [Description of the totalGeneratedReservations property]
```

### availableTimeSlots (Line 1105)

**Context:**

```swift
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 14)))
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 22)))

        while totalGeneratedReservations < maxDailyReservations && !availableTimeSlots.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the availableTimeSlots property]
```

### startTime (Line 1109)

**Context:**

```swift
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 22)))

        while totalGeneratedReservations < maxDailyReservations && !availableTimeSlots.isEmpty {
            guard let startTime = availableTimeSlots.min() else { break }
            availableTimeSlots.remove(startTime)

            let numberOfPersons = self.generateWeightedGroupSize()
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### numberOfPersons (Line 1112)

**Context:**

```swift
            guard let startTime = availableTimeSlots.min() else { break }
            availableTimeSlots.remove(startTime)

            let numberOfPersons = self.generateWeightedGroupSize()
            let durationMinutes: Int = {
                if numberOfPersons <= 2 { return Int.random(in: 90...105) }
                if numberOfPersons >= 10 { return Int.random(in: 120...150) }
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### durationMinutes (Line 1113)

**Context:**

```swift
            availableTimeSlots.remove(startTime)

            let numberOfPersons = self.generateWeightedGroupSize()
            let durationMinutes: Int = {
                if numberOfPersons <= 2 { return Int.random(in: 90...105) }
                if numberOfPersons >= 10 { return Int.random(in: 120...150) }
                return 105
```

**Suggested Documentation:**

```swift
/// [Description of the durationMinutes property]
```

### endTime (Line 1119)

**Context:**

```swift
                return 105
            }()

            let endTime = self.roundToNearestFiveMinutes(
                Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!
            )

```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### nextSlot (Line 1123)

**Context:**

```swift
                Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!
            )

            if let nextSlot = availableTimeSlots.min(), nextSlot < endTime.addingTimeInterval(600) {
                availableTimeSlots.remove(nextSlot)
            }

```

**Suggested Documentation:**

```swift
/// [Description of the nextSlot property]
```

### category (Line 1127)

**Context:**

```swift
                availableTimeSlots.remove(nextSlot)
            }

            let category: Reservation.ReservationCategory = Calendar.current.component(.hour, from: startTime) < 15 ? .lunch : .dinner
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### dateString (Line 1128)

**Context:**

```swift
            }

            let category: Reservation.ReservationCategory = Calendar.current.component(.hour, from: startTime) < 15 ? .lunch : .dinner
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

            let reservation = Reservation(
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### startTimeString (Line 1129)

**Context:**

```swift

            let category: Reservation.ReservationCategory = Calendar.current.component(.hour, from: startTime) < 15 ? .lunch : .dinner
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

            let reservation = Reservation(
                id: UUID(),
```

**Suggested Documentation:**

```swift
/// [Description of the startTimeString property]
```

### reservation (Line 1131)

**Context:**

```swift
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

            let reservation = Reservation(
                id: UUID(),
                name: names.randomElement()!,
                phone: phoneNumbers.randomElement()!,
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### assignmentResult (Line 1155)

**Context:**

```swift


                await MainActor.run {
                let assignmentResult = self.layoutServices.assignTables(for: reservation, selectedTableID: nil)
                    switch assignmentResult {
                    case .success(let assignedTables):
                        var updatedReservation = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 1157)

**Context:**

```swift
                await MainActor.run {
                let assignmentResult = self.layoutServices.assignTables(for: reservation, selectedTableID: nil)
                    switch assignmentResult {
                    case .success(let assignedTables):
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### updatedReservation (Line 1158)

**Context:**

```swift
                let assignmentResult = self.layoutServices.assignTables(for: reservation, selectedTableID: nil)
                    switch assignmentResult {
                    case .success(let assignedTables):
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        
                    let key = self.layoutServices.keyFor(date: reservationDate, category: category)
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### key (Line 1161)

**Context:**

```swift
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        
                    let key = self.layoutServices.keyFor(date: reservationDate, category: category)
                    
                    if self.layoutServices.cachedLayouts[key] == nil {
                        self.layoutServices.cachedLayouts[key] = self.tableStore.baseTables
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### reservationStart (Line 1166)

**Context:**

```swift
                    if self.layoutServices.cachedLayouts[key] == nil {
                        self.layoutServices.cachedLayouts[key] = self.tableStore.baseTables
                    }
                        guard let reservationStart = reservation.startTimeDate,
                              let reservationEnd = reservation.endTimeDate else { break }
                        
                        assignedTables.forEach { self.layoutServices.unlockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationStart property]
```

### reservationEnd (Line 1167)

**Context:**

```swift
                        self.layoutServices.cachedLayouts[key] = self.tableStore.baseTables
                    }
                        guard let reservationStart = reservation.startTimeDate,
                              let reservationEnd = reservation.endTimeDate else { break }
                        
                        assignedTables.forEach { self.layoutServices.unlockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                        self.store.finalizeReservation(updatedReservation)
```

**Suggested Documentation:**

```swift
/// [Description of the reservationEnd property]
```

### error (Line 1179)

**Context:**

```swift
                                self.logger.info("Generated reservation: \(updatedReservation.name)")
                            }
                        }
                    case .failure(let error):
                        // Show an alert message based on `error`.
                        switch error {
                        case .noTablesLeft:
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### slots (Line 1211)

**Context:**

```swift
    ///   - range: Tuple containing start and end hour (inclusive/exclusive)
    /// - Returns: Array of dates representing time slots at 5-minute intervals
    private func generateTimeSlots(for date: Date, range: (Int, Int)) -> [Date] {
        var slots: [Date] = []
        for hour in range.0..<range.1 {
            for minute in stride(from: 0, to: 60, by: 5) { // Step of 5 minutes
                if let slot = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
```

**Suggested Documentation:**

```swift
/// [Description of the slots property]
```

### slot (Line 1214)

**Context:**

```swift
        var slots: [Date] = []
        for hour in range.0..<range.1 {
            for minute in stride(from: 0, to: 60, by: 5) { // Step of 5 minutes
                if let slot = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    slots.append(slot)
                }
            }
```

**Suggested Documentation:**

```swift
/// [Description of the slot property]
```

### calendar (Line 1227)

**Context:**

```swift
    /// - Parameter date: The date to round
    /// - Returns: The rounded date
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### minute (Line 1228)

**Context:**

```swift
    /// - Returns: The rounded date
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
```

**Suggested Documentation:**

```swift
/// [Description of the minute property]
```

### remainder (Line 1229)

**Context:**

```swift
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }
```

**Suggested Documentation:**

```swift
/// [Description of the remainder property]
```

### adjustment (Line 1230)

**Context:**

```swift
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }

```

**Suggested Documentation:**

```swift
/// [Description of the adjustment property]
```

### random (Line 1241)

**Context:**

```swift
    ///
    /// - Returns: A party size between 2 and 14
    private func generateWeightedGroupSize() -> Int {
        let random = Double.random(in: 0...1)
        switch random {
        case 0..<0.5: return Int.random(in: 2...3) // 50% chance for groups of 2-3
        case 0.5..<0.7: return Int.random(in: 4...5) // 20% chance for groups of 4-5
```

**Suggested Documentation:**

```swift
/// [Description of the random property]
```

### resourceName (Line 1259)

**Context:**

```swift
    ///   - folder: Optional folder containing the file
    /// - Returns: Array of strings from the file
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(String(describing: folder))/\(fileName)" : fileName
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "txt") else {
            self.logger.warning("Failed to load \(fileName) from folder \(String(describing: folder)).")
            return []
```

**Suggested Documentation:**

```swift
/// [Description of the resourceName property]
```

### fileURL (Line 1260)

**Context:**

```swift
    /// - Returns: Array of strings from the file
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(String(describing: folder))/\(fileName)" : fileName
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "txt") else {
            self.logger.warning("Failed to load \(fileName) from folder \(String(describing: folder)).")
            return []
        }
```

**Suggested Documentation:**

```swift
/// [Description of the fileURL property]
```

### content (Line 1266)

**Context:**

```swift
        }
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            self.logger.debug("Loaded \(lines.count) lines from \(fileName) (folder: \(String(describing: folder))).")
            return lines
```

**Suggested Documentation:**

```swift
/// [Description of the content property]
```

### lines (Line 1267)

**Context:**

```swift
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            self.logger.debug("Loaded \(lines.count) lines from \(fileName) (folder: \(String(describing: folder))).")
            return lines
        } catch {
```

**Suggested Documentation:**

```swift
/// [Description of the lines property]
```

### randomTable (Line 1289)

**Context:**

```swift
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    
                    let randomTable = self.layoutServices.tables.randomElement()!
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
```

**Suggested Documentation:**

```swift
/// [Description of the randomTable property]
```

### newRow (Line 1290)

**Context:**

```swift
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    
                    let randomTable = self.layoutServices.tables.randomElement()!
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
                    let layoutServices = self.layoutServices // Capture layoutServices explicitly
```

**Suggested Documentation:**

```swift
/// [Description of the newRow property]
```

### newColumn (Line 1291)

**Context:**

```swift
                    
                    let randomTable = self.layoutServices.tables.randomElement()!
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
                    let layoutServices = self.layoutServices // Capture layoutServices explicitly
                    Task {
```

**Suggested Documentation:**

```swift
/// [Description of the newColumn property]
```

### layoutServices (Line 1293)

**Context:**

```swift
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
                    let layoutServices = self.layoutServices // Capture layoutServices explicitly
                    Task {
                        let result = layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        self.logger.debug("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(String(describing: result))")
```

**Suggested Documentation:**

```swift
/// [Description of the layoutServices property]
```

### result (Line 1295)

**Context:**

```swift
                    
                    let layoutServices = self.layoutServices // Capture layoutServices explicitly
                    Task {
                        let result = layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        self.logger.debug("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(String(describing: result))")
                    }
                }
```

**Suggested Documentation:**

```swift
/// [Description of the result property]
```

### reservationDate (Line 1312)

**Context:**

```swift
    ///
    /// - Parameter reservation: The reservation to update adjacency counts for
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            self.logger.warning("Invalid reservation date or time for updating adjacency counts.")
            return
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### combinedDateTime (Line 1313)

**Context:**

```swift
    /// - Parameter reservation: The reservation to update adjacency counts for
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            self.logger.warning("Invalid reservation date or time for updating adjacency counts.")
            return
        }
```

**Suggested Documentation:**

```swift
/// [Description of the combinedDateTime property]
```

### activeTables (Line 1319)

**Context:**

```swift
        }

        // Get active tables for the reservation's layout
        let activeTables = layoutServices.getTables(for: reservationDate, category: reservation.category)

        // Iterate over all tables in the reservation
        for table in reservation.tables {
```

**Suggested Documentation:**

```swift
/// [Description of the activeTables property]
```

### adjacentTables (Line 1323)

**Context:**

```swift

        // Iterate over all tables in the reservation
        for table in reservation.tables {
            let adjacentTables = layoutServices.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables)
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id}) {
                layoutServices.tables[index].adjacentCount = adjacentTables.adjacentCount
            }
```

**Suggested Documentation:**

```swift
/// [Description of the adjacentTables property]
```

### index (Line 1324)

**Context:**

```swift
        // Iterate over all tables in the reservation
        for table in reservation.tables {
            let adjacentTables = layoutServices.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables)
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id}) {
                layoutServices.tables[index].adjacentCount = adjacentTables.adjacentCount
            }
            // Calculate adjacent tables with shared reservations
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### sharedTables (Line 1328)

**Context:**

```swift
                layoutServices.tables[index].adjacentCount = adjacentTables.adjacentCount
            }
            // Calculate adjacent tables with shared reservations
            let sharedTables = layoutServices.isAdjacentWithSameReservation(for: table, combinedDateTime: combinedDateTime, activeTables: activeTables)

            // Update `activeReservationAdjacentCount` for this table
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id }) {
```

**Suggested Documentation:**

```swift
/// [Description of the sharedTables property]
```

### index (Line 1331)

**Context:**

```swift
            let sharedTables = layoutServices.isAdjacentWithSameReservation(for: table, combinedDateTime: combinedDateTime, activeTables: activeTables)

            // Update `activeReservationAdjacentCount` for this table
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id }) {
                layoutServices.tables[index].activeReservationAdjacentCount = sharedTables.count
            }

```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### key (Line 1336)

**Context:**

```swift
            }

            // Update in the cached layout
            let key = layoutServices.keyFor(date: reservationDate, category: reservation.category)
            if let cachedIndex = layoutServices.cachedLayouts[key]?.firstIndex(where: { $0.id == table.id }) {
                layoutServices.cachedLayouts[key]?[cachedIndex].activeReservationAdjacentCount = sharedTables.count
            }
```

**Suggested Documentation:**

```swift
/// [Description of the key property]
```

### cachedIndex (Line 1337)

**Context:**

```swift

            // Update in the cached layout
            let key = layoutServices.keyFor(date: reservationDate, category: reservation.category)
            if let cachedIndex = layoutServices.cachedLayouts[key]?.firstIndex(where: { $0.id == table.id }) {
                layoutServices.cachedLayouts[key]?[cachedIndex].activeReservationAdjacentCount = sharedTables.count
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the cachedIndex property]
```

### updatedReservation (Line 1391)

**Context:**

```swift
    /// - Returns: The updated reservation
    @MainActor
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        var updatedReservation = reservation  // Create a mutable copy
        let finalNotes = notesToAdd == "" ? "" : "\(notesToAdd)\n\n"
        updatedReservation.status = .pending
        updatedReservation.notes = "\(finalNotes)[da controllare];"
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### finalNotes (Line 1392)

**Context:**

```swift
    @MainActor
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        var updatedReservation = reservation  // Create a mutable copy
        let finalNotes = notesToAdd == "" ? "" : "\(notesToAdd)\n\n"
        updatedReservation.status = .pending
        updatedReservation.notes = "\(finalNotes)[da controllare];"
        return updatedReservation
```

**Suggested Documentation:**

```swift
/// [Description of the finalNotes property]
```

### updatedReservation (Line 1406)

**Context:**

```swift
    /// - Parameter reservation: The reservation to delete
    @MainActor
    func deleteReservation(_ reservation: Reservation) {
        var updatedReservation = reservation  // Create a mutable copy
        updatedReservation.reservationType = .na
        updatedReservation.status = .deleted
        updatedReservation.acceptance = .na
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### updatedCount (Line 1426)

**Context:**

```swift
    func ensureConfirmedReservationsHaveTables() {
        logger.info("Scanning database for confirmed reservations without tables...")
        
        var updatedCount = 0
        var failedCount = 0
        
        // Create a copy to avoid modifying while iterating
```

**Suggested Documentation:**

```swift
/// [Description of the updatedCount property]
```

### failedCount (Line 1427)

**Context:**

```swift
        logger.info("Scanning database for confirmed reservations without tables...")
        
        var updatedCount = 0
        var failedCount = 0
        
        // Create a copy to avoid modifying while iterating
        let reservationsToCheck = store.reservations
```

**Suggested Documentation:**

```swift
/// [Description of the failedCount property]
```

### reservationsToCheck (Line 1430)

**Context:**

```swift
        var failedCount = 0
        
        // Create a copy to avoid modifying while iterating
        let reservationsToCheck = store.reservations
        
        for reservation in reservationsToCheck {
            if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsToCheck property]
```

### assignmentResult (Line 1437)

**Context:**

```swift
                logger.warning("⚠️ Found confirmed reservation in database with no tables: \(reservation.name) (ID: \(reservation.id))")
                
                // Try to assign tables automatically
                let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    var updatedReservation = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 1439)

**Context:**

```swift
                // Try to assign tables automatically
                let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    var updatedReservation = reservation
                    updatedReservation.tables = assignedTables
                    
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### updatedReservation (Line 1440)

**Context:**

```swift
                let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    var updatedReservation = reservation
                    updatedReservation.tables = assignedTables
                    
                    // Update in SQLite
```

**Suggested Documentation:**

```swift
/// [Description of the updatedReservation property]
```

### index (Line 1447)

**Context:**

```swift
                    SQLiteManager.shared.updateReservation(updatedReservation)
                    
                    // Update in memory
                    if let index = store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        store.reservations[index] = updatedReservation
                    }
                    
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### error (Line 1457)

**Context:**

```swift
                    logger.info("✅ Auto-assigned \(assignedTables.count) tables to stored reservation: \(updatedReservation.name)")
                    updatedCount += 1
                    
                case .failure(let error):
                    logger.error("❌ Failed to auto-assign tables to stored reservation: \(error.localizedDescription)")
                    failedCount += 1
                }
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### nextMinute (Line 1471)

**Context:**

```swift
extension Date {
    /// Returns the start of the next minute for the current date.
    func startOfNextMinute() -> Date {
        let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: self)!
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextMinute))!
    }
}
```

**Suggested Documentation:**

```swift
/// [Description of the nextMinute property]
```

### groupedReservations (Line 1495)

**Context:**

```swift
        logger.info("Checking for duplicate reservations...")
        
        // Group reservations by ID
        let groupedReservations = Dictionary(grouping: store.reservations) { $0.id }
        var reservationsToKeep: [UUID: Reservation] = [:]
        var reservationsToRemove: [Reservation] = []
        var duplicatesFound = 0
```

**Suggested Documentation:**

```swift
/// [Description of the groupedReservations property]
```

### reservationsToKeep (Line 1496)

**Context:**

```swift
        
        // Group reservations by ID
        let groupedReservations = Dictionary(grouping: store.reservations) { $0.id }
        var reservationsToKeep: [UUID: Reservation] = [:]
        var reservationsToRemove: [Reservation] = []
        var duplicatesFound = 0
        
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsToKeep property]
```

### reservationsToRemove (Line 1497)

**Context:**

```swift
        // Group reservations by ID
        let groupedReservations = Dictionary(grouping: store.reservations) { $0.id }
        var reservationsToKeep: [UUID: Reservation] = [:]
        var reservationsToRemove: [Reservation] = []
        var duplicatesFound = 0
        
        // Process each group of reservations with the same ID
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsToRemove property]
```

### duplicatesFound (Line 1498)

**Context:**

```swift
        let groupedReservations = Dictionary(grouping: store.reservations) { $0.id }
        var reservationsToKeep: [UUID: Reservation] = [:]
        var reservationsToRemove: [Reservation] = []
        var duplicatesFound = 0
        
        // Process each group of reservations with the same ID
        for (id, duplicates) in groupedReservations where duplicates.count > 1 {
```

**Suggested Documentation:**

```swift
/// [Description of the duplicatesFound property]
```

### reservationsWithTables (Line 1506)

**Context:**

```swift
            logger.warning("Found \(duplicates.count) duplicates for reservation ID: \(id)")
            
            // First, try to find a reservation with tables
            let reservationsWithTables = duplicates.filter { !$0.tables.isEmpty }
            
            if let bestReservation = reservationsWithTables.first {
                // Keep the reservation with tables
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsWithTables property]
```

### bestReservation (Line 1508)

**Context:**

```swift
            // First, try to find a reservation with tables
            let reservationsWithTables = duplicates.filter { !$0.tables.isEmpty }
            
            if let bestReservation = reservationsWithTables.first {
                // Keep the reservation with tables
                reservationsToKeep[id] = bestReservation
                logger.debug("Keeping reservation with \(bestReservation.tables.count) tables for ID: \(id)")
```

**Suggested Documentation:**

```swift
/// [Description of the bestReservation property]
```

### othersToRemove (Line 1514)

**Context:**

```swift
                logger.debug("Keeping reservation with \(bestReservation.tables.count) tables for ID: \(id)")
                
                // Mark others for removal
                let othersToRemove = duplicates.filter { $0.id == id && $0 != bestReservation }
                reservationsToRemove.append(contentsOf: othersToRemove)
            } else {
                // If none have tables, keep the most recently edited one
```

**Suggested Documentation:**

```swift
/// [Description of the othersToRemove property]
```

### mostRecent (Line 1518)

**Context:**

```swift
                reservationsToRemove.append(contentsOf: othersToRemove)
            } else {
                // If none have tables, keep the most recently edited one
                let mostRecent = duplicates.max(by: { $0.lastEditedOn < $1.lastEditedOn })!
                reservationsToKeep[id] = mostRecent
                logger.debug("No reservations with tables found for ID: \(id). Keeping most recent.")
                
```

**Suggested Documentation:**

```swift
/// [Description of the mostRecent property]
```

### othersToRemove (Line 1523)

**Context:**

```swift
                logger.debug("No reservations with tables found for ID: \(id). Keeping most recent.")
                
                // Mark others for removal
                let othersToRemove = duplicates.filter { $0.id == id && $0 != mostRecent }
                reservationsToRemove.append(contentsOf: othersToRemove)
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the othersToRemove property]
```


Total documentation suggestions: 226

