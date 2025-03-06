Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/App Database/SQLiteManager.swift...
# Documentation Suggestions for SQLiteManager.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/App Database/SQLiteManager.swift
Total suggestions: 61

## Class Documentation (1)

### SQLiteManager (Line 16)

**Context:**

```swift
typealias Expression = SQLite.Expression

@MainActor
class SQLiteManager {
    let logger = Logger(subsystem: "com.koenjiapp", category: "SQLiteManager")
    // MARK: - Static Properties
    static let shared = SQLiteManager()
```

**Suggested Documentation:**

```swift
/// SQLiteManager manager.
///
/// [Add a description of what this manager does and its responsibilities]
```

## Method Documentation (7)

### createReservationsTable (Line 75)

**Context:**

```swift
    }
    
    
    private func createReservationsTable() {
        do {
            // First, check if the table exists
            let tableExists = try db.scalar("SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'reservations')") as? Int64 == 1
```

**Suggested Documentation:**

```swift
/// [Add a description of what the createReservationsTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### createSessionsTable (Line 122)

**Context:**

```swift
    }
    
    
    private func createSessionsTable() {
        do {
            try db.run(sessionsTable.create(ifNotExists: true) { table in
                table.column(sessionId, primaryKey: true)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the createSessionsTable method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### insertSession (Line 176)

**Context:**

```swift
       }
    }
    
    func insertSession(_ session: Session) {
        do {
            let insert = sessionsTable.insert(or: .replace,
                sessionId <- session.id,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the insertSession method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteSession (Line 240)

**Context:**

```swift
        }
    }
    
    func deleteSession(withID sessionID: String) {
        do {
            let row = sessionsTable.filter(id == sessionID)
            try db.run(row.delete())
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteSession method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteAllReservations (Line 249)

**Context:**

```swift
        }
    }
    
    func deleteAllReservations() {
        do {
            // This deletes all rows in the table.
            try db.run(reservationsTable.delete())
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteAllReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteAllSessions (Line 259)

**Context:**

```swift
        }
    }
    
    func deleteAllSessions() {
        do {
            try db.run(sessionsTable.delete())
            logger.notice("All sessions deleted from database")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteAllSessions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### fetchSessions (Line 288)

**Context:**

```swift
        return uniqueReservations
    }
    
    func fetchSessions() -> [Session] {
        var sessions: [Session] = []
        do {
            for row in try db.prepare(sessionsTable) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the fetchSessions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (53)

### logger (Line 17)

**Context:**

```swift

@MainActor
class SQLiteManager {
    let logger = Logger(subsystem: "com.koenjiapp", category: "SQLiteManager")
    // MARK: - Static Properties
    static let shared = SQLiteManager()
    
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### shared (Line 19)

**Context:**

```swift
class SQLiteManager {
    let logger = Logger(subsystem: "com.koenjiapp", category: "SQLiteManager")
    // MARK: - Static Properties
    static let shared = SQLiteManager()
    
    // MARK: - Database Properties
    var db: Connection!
```

**Suggested Documentation:**

```swift
/// [Description of the shared property]
```

### db (Line 22)

**Context:**

```swift
    static let shared = SQLiteManager()
    
    // MARK: - Database Properties
    var db: Connection!
    
    // Define the table and columns. (We convert UUID to String.)
    let reservationsTable = Table("reservations")
```

**Suggested Documentation:**

```swift
/// [Description of the db property]
```

### reservationsTable (Line 25)

**Context:**

```swift
    var db: Connection!
    
    // Define the table and columns. (We convert UUID to String.)
    let reservationsTable = Table("reservations")
    let id = Expression<String>("id")
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsTable property]
```

### id (Line 26)

**Context:**

```swift
    
    // Define the table and columns. (We convert UUID to String.)
    let reservationsTable = Table("reservations")
    let id = Expression<String>("id")
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### name (Line 27)

**Context:**

```swift
    // Define the table and columns. (We convert UUID to String.)
    let reservationsTable = Table("reservations")
    let id = Expression<String>("id")
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### phone (Line 28)

**Context:**

```swift
    let reservationsTable = Table("reservations")
    let id = Expression<String>("id")
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
```

**Suggested Documentation:**

```swift
/// [Description of the phone property]
```

### numberOfPersons (Line 29)

**Context:**

```swift
    let id = Expression<String>("id")
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### dateString (Line 30)

**Context:**

```swift
    let name = Expression<String>("name")
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### category (Line 31)

**Context:**

```swift
    let phone = Expression<String>("phone")
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### startTime (Line 32)

**Context:**

```swift
    let numberOfPersons = Expression<Int>("numberOfPersons")
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 33)

**Context:**

```swift
    let dateString = Expression<String>("dateString")
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### acceptance (Line 34)

**Context:**

```swift
    let category = Expression<String>("category")
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### status (Line 35)

**Context:**

```swift
    let startTime = Expression<String>("startTime")
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationType (Line 36)

**Context:**

```swift
    let endTime = Expression<String>("endTime")
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### group (Line 37)

**Context:**

```swift
    let acceptance = Expression<String>("acceptance")
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
```

**Suggested Documentation:**

```swift
/// [Description of the group property]
```

### notes (Line 38)

**Context:**

```swift
    let status = Expression<String>("status")
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### tables (Line 39)

**Context:**

```swift
    let reservationType = Expression<String>("reservationType")
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### creationDate (Line 40)

**Context:**

```swift
    let group = Expression<Bool>("group")
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
```

**Suggested Documentation:**

```swift
/// [Description of the creationDate property]
```

### lastEditedOn (Line 41)

**Context:**

```swift
    let notes = Expression<String?>("notes")
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
```

**Suggested Documentation:**

```swift
/// [Description of the lastEditedOn property]
```

### isMock (Line 42)

**Context:**

```swift
    let tables = Expression<String?>("tables")
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
    let colorHue = Expression<Double>("colorHue")
```

**Suggested Documentation:**

```swift
/// [Description of the isMock property]
```

### assignedEmoji (Line 43)

**Context:**

```swift
    let creationDate = Expression<Date>("creationDate")
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
    let colorHue = Expression<Double>("colorHue")
    let preferredLanguage = Expression<String?>("preferredLanguage")
```

**Suggested Documentation:**

```swift
/// [Description of the assignedEmoji property]
```

### imageData (Line 44)

**Context:**

```swift
    let lastEditedOn = Expression<Date>("lastEditedOn")
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
    let colorHue = Expression<Double>("colorHue")
    let preferredLanguage = Expression<String?>("preferredLanguage")
    // You can add additional columns (or serialize complex types like `tables` into JSON)
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### colorHue (Line 45)

**Context:**

```swift
    let isMock = Expression<Bool>("isMock")
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
    let colorHue = Expression<Double>("colorHue")
    let preferredLanguage = Expression<String?>("preferredLanguage")
    // You can add additional columns (or serialize complex types like `tables` into JSON)
    
```

**Suggested Documentation:**

```swift
/// [Description of the colorHue property]
```

### preferredLanguage (Line 46)

**Context:**

```swift
    let assignedEmoji = Expression<String?>("assignedEmoji")
    let imageData = Expression<Data?>("imageData")
    let colorHue = Expression<Double>("colorHue")
    let preferredLanguage = Expression<String?>("preferredLanguage")
    // You can add additional columns (or serialize complex types like `tables` into JSON)
    
    
```

**Suggested Documentation:**

```swift
/// [Description of the preferredLanguage property]
```

### sessionsTable (Line 50)

**Context:**

```swift
    // You can add additional columns (or serialize complex types like `tables` into JSON)
    
    
    let sessionsTable = Table("sessions")
    let sessionId = Expression<String>("id")
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
```

**Suggested Documentation:**

```swift
/// [Description of the sessionsTable property]
```

### sessionId (Line 51)

**Context:**

```swift
    
    
    let sessionsTable = Table("sessions")
    let sessionId = Expression<String>("id")
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
```

**Suggested Documentation:**

```swift
/// [Description of the sessionId property]
```

### sessionUUID (Line 52)

**Context:**

```swift
    
    let sessionsTable = Table("sessions")
    let sessionId = Expression<String>("id")
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
    let sessionLastUpdate = Expression<Date>("lastUpdate")
```

**Suggested Documentation:**

```swift
/// [Description of the sessionUUID property]
```

### sessionUserName (Line 53)

**Context:**

```swift
    let sessionsTable = Table("sessions")
    let sessionId = Expression<String>("id")
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
    let sessionLastUpdate = Expression<Date>("lastUpdate")
    let sessionIsActive = Expression<Bool>("isActive")
```

**Suggested Documentation:**

```swift
/// [Description of the sessionUserName property]
```

### sessionIsEditing (Line 54)

**Context:**

```swift
    let sessionId = Expression<String>("id")
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
    let sessionLastUpdate = Expression<Date>("lastUpdate")
    let sessionIsActive = Expression<Bool>("isActive")
    
```

**Suggested Documentation:**

```swift
/// [Description of the sessionIsEditing property]
```

### sessionLastUpdate (Line 55)

**Context:**

```swift
    let sessionUUID = Expression<String?>("uuid")
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
    let sessionLastUpdate = Expression<Date>("lastUpdate")
    let sessionIsActive = Expression<Bool>("isActive")
    
    private init() {
```

**Suggested Documentation:**

```swift
/// [Description of the sessionLastUpdate property]
```

### sessionIsActive (Line 56)

**Context:**

```swift
    let sessionUserName = Expression<String>("userName")
    let sessionIsEditing = Expression<Bool>("isEditing")
    let sessionLastUpdate = Expression<Date>("lastUpdate")
    let sessionIsActive = Expression<Bool>("isActive")
    
    private init() {
        do {
```

**Suggested Documentation:**

```swift
/// [Description of the sessionIsActive property]
```

### documentDirectory (Line 60)

**Context:**

```swift
    
    private init() {
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory,
                                                              in: .userDomainMask,
                                                              appropriateFor: nil,
                                                              create: true)
```

**Suggested Documentation:**

```swift
/// [Description of the documentDirectory property]
```

### dbURL (Line 64)

**Context:**

```swift
                                                              in: .userDomainMask,
                                                              appropriateFor: nil,
                                                              create: true)
            let dbURL = documentDirectory.appendingPathComponent("reservations.sqlite3")
            db = try Connection(dbURL.path)
            createReservationsTable()
            createSessionsTable()
```

**Suggested Documentation:**

```swift
/// [Description of the dbURL property]
```

### tableExists (Line 78)

**Context:**

```swift
    private func createReservationsTable() {
        do {
            // First, check if the table exists
            let tableExists = try db.scalar("SELECT EXISTS (SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'reservations')") as? Int64 == 1
            
            if !tableExists {
                // Create the table if it doesn't exist
```

**Suggested Documentation:**

```swift
/// [Description of the tableExists property]
```

### hasPreferredLanguage (Line 108)

**Context:**

```swift
                logger.debug("Reservations table created")
            } else {
                // Check if the preferredLanguage column exists
                let hasPreferredLanguage = try db.scalar("SELECT COUNT(*) FROM pragma_table_info('reservations') WHERE name='preferredLanguage'") as? Int64 == 1
                
                if !hasPreferredLanguage {
                    // Add the new column if it doesn't exist
```

**Suggested Documentation:**

```swift
/// [Description of the hasPreferredLanguage property]
```

### encoder (Line 142)

**Context:**

```swift
    /// Inserts a Reservation into the database.
    func insertReservation(_ reservation: Reservation) {
        do {
           let encoder = JSONEncoder()
           let tablesData = try encoder.encode(reservation.tables)
           let tablesString = String(data: tablesData, encoding: .utf8)
           
```

**Suggested Documentation:**

```swift
/// [Description of the encoder property]
```

### tablesData (Line 143)

**Context:**

```swift
    func insertReservation(_ reservation: Reservation) {
        do {
           let encoder = JSONEncoder()
           let tablesData = try encoder.encode(reservation.tables)
           let tablesString = String(data: tablesData, encoding: .utf8)
           
           let insert = reservationsTable.insert(or: .replace,
```

**Suggested Documentation:**

```swift
/// [Description of the tablesData property]
```

### tablesString (Line 144)

**Context:**

```swift
        do {
           let encoder = JSONEncoder()
           let tablesData = try encoder.encode(reservation.tables)
           let tablesString = String(data: tablesData, encoding: .utf8)
           
           let insert = reservationsTable.insert(or: .replace,
               id <- reservation.id.uuidString,
```

**Suggested Documentation:**

```swift
/// [Description of the tablesString property]
```

### insert (Line 146)

**Context:**

```swift
           let tablesData = try encoder.encode(reservation.tables)
           let tablesString = String(data: tablesData, encoding: .utf8)
           
           let insert = reservationsTable.insert(or: .replace,
               id <- reservation.id.uuidString,
               name <- reservation.name,
               phone <- reservation.phone,
```

**Suggested Documentation:**

```swift
/// [Description of the insert property]
```

### insert (Line 178)

**Context:**

```swift
    
    func insertSession(_ session: Session) {
        do {
            let insert = sessionsTable.insert(or: .replace,
                sessionId <- session.id,
                sessionUUID <- session.uuid,
                sessionUserName <- session.userName,
```

**Suggested Documentation:**

```swift
/// [Description of the insert property]
```

### encoder (Line 196)

**Context:**

```swift
    /// Updates an existing Reservation in the database.
    func updateReservation(_ reservation: Reservation) {
        do {
            let encoder = JSONEncoder()
            // Optionally set any encoder settings you use (e.g., dateEncodingStrategy)
            let tablesData = try encoder.encode(reservation.tables)
            let tablesString = String(data: tablesData, encoding: .utf8)
```

**Suggested Documentation:**

```swift
/// [Description of the encoder property]
```

### tablesData (Line 198)

**Context:**

```swift
        do {
            let encoder = JSONEncoder()
            // Optionally set any encoder settings you use (e.g., dateEncodingStrategy)
            let tablesData = try encoder.encode(reservation.tables)
            let tablesString = String(data: tablesData, encoding: .utf8)
            let row = reservationsTable.filter(id == reservation.id.uuidString)
            let update = row.update(
```

**Suggested Documentation:**

```swift
/// [Description of the tablesData property]
```

### tablesString (Line 199)

**Context:**

```swift
            let encoder = JSONEncoder()
            // Optionally set any encoder settings you use (e.g., dateEncodingStrategy)
            let tablesData = try encoder.encode(reservation.tables)
            let tablesString = String(data: tablesData, encoding: .utf8)
            let row = reservationsTable.filter(id == reservation.id.uuidString)
            let update = row.update(
                name <- reservation.name,
```

**Suggested Documentation:**

```swift
/// [Description of the tablesString property]
```

### row (Line 200)

**Context:**

```swift
            // Optionally set any encoder settings you use (e.g., dateEncodingStrategy)
            let tablesData = try encoder.encode(reservation.tables)
            let tablesString = String(data: tablesData, encoding: .utf8)
            let row = reservationsTable.filter(id == reservation.id.uuidString)
            let update = row.update(
                name <- reservation.name,
                phone <- reservation.phone,
```

**Suggested Documentation:**

```swift
/// [Description of the row property]
```

### update (Line 201)

**Context:**

```swift
            let tablesData = try encoder.encode(reservation.tables)
            let tablesString = String(data: tablesData, encoding: .utf8)
            let row = reservationsTable.filter(id == reservation.id.uuidString)
            let update = row.update(
                name <- reservation.name,
                phone <- reservation.phone,
                numberOfPersons <- reservation.numberOfPersons,
```

**Suggested Documentation:**

```swift
/// [Description of the update property]
```

### row (Line 232)

**Context:**

```swift
    /// Deletes a Reservation from the database.
    func deleteReservation(withID reservationID: UUID) {
        do {
            let row = reservationsTable.filter(id == reservationID.uuidString)
            try db.run(row.delete())
            logger.info("Deleted reservation: \(reservationID)")
        } catch {
```

**Suggested Documentation:**

```swift
/// [Description of the row property]
```

### row (Line 242)

**Context:**

```swift
    
    func deleteSession(withID sessionID: String) {
        do {
            let row = sessionsTable.filter(id == sessionID)
            try db.run(row.delete())
        } catch {
            logger.error("SQLite Delete error: \(error)")
```

**Suggested Documentation:**

```swift
/// [Description of the row property]
```

### reservations (Line 271)

**Context:**

```swift
    
    /// Fetches all Reservations from the database.
    func fetchReservations() -> [Reservation] {
        var reservations: [Reservation] = []
        do {
            for row in try db.prepare(reservationsTable) {
                logger.debug("Processing row for reservation")
```

**Suggested Documentation:**

```swift
/// [Description of the reservations property]
```

### reservation (Line 275)

**Context:**

```swift
        do {
            for row in try db.prepare(reservationsTable) {
                logger.debug("Processing row for reservation")
                if let reservation = ReservationMapper.reservation(from: row) {
                    logger.debug("Successfully mapped reservation: \(reservation.name)")
                    reservations.append(reservation)
                }
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### uniqueReservations (Line 283)

**Context:**

```swift
        } catch {
            logger.error("Failed to fetch reservations: \(error.localizedDescription)")
        }
        let uniqueReservations = Dictionary(grouping: reservations, by: { $0.id }).compactMap { $0.value.first }
        logger.info("Fetched \(uniqueReservations.count) unique reservations")
        return uniqueReservations
    }
```

**Suggested Documentation:**

```swift
/// [Description of the uniqueReservations property]
```

### sessions (Line 289)

**Context:**

```swift
    }
    
    func fetchSessions() -> [Session] {
        var sessions: [Session] = []
        do {
            for row in try db.prepare(sessionsTable) {
                logger.debug("Processing row for session")
```

**Suggested Documentation:**

```swift
/// [Description of the sessions property]
```

### session (Line 293)

**Context:**

```swift
        do {
            for row in try db.prepare(sessionsTable) {
                logger.debug("Processing row for session")
                if let session = SessionMapper.session(from: row) {
                    sessions.append(session)
                }
            }
```

**Suggested Documentation:**

```swift
/// [Description of the session property]
```


Total documentation suggestions: 61

