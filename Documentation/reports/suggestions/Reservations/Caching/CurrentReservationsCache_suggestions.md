Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Caching/CurrentReservationsCache.swift...
# Documentation Suggestions for CurrentReservationsCache.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Caching/CurrentReservationsCache.swift
Total suggestions: 109

## Class Documentation (2)

### CurrentReservationsCache (Line 5)

**Context:**

```swift
import FirebaseFirestore
import OSLog

class CurrentReservationsCache: ObservableObject {
    // MARK: - Private Properties
    let logger = Logger(subsystem: "com.koenjiapp", category: "CurrentReservationsCache")
    // MARK: - Published Properties
```

**Suggested Documentation:**

```swift
/// CurrentReservationsCache class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ActiveReservationCacheKey (Line 506)

**Context:**

```swift

}

struct ActiveReservationCacheKey: Hashable, Codable {
    let date: Date
    let time: Date
    let tableID: Int
```

**Suggested Documentation:**

```swift
/// ActiveReservationCacheKey class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (9)

### preloadDates (Line 21)

**Context:**

```swift
    private let db = Firestore.firestore()
    
    // MARK: - Cache Management
    func preloadDates(around selectedDate: Date, range: Int, reservations: [Reservation]) {
        let newDates = calculateDateRange(around: selectedDate, range: range)
        let datesToAdd = newDates.subtracting(preloadedDates)
        let datesToRemove = preloadedDates.subtracting(newDates)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the preloadDates method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### populateCache (Line 51)

**Context:**

```swift
        activeReservationsByMinute.removeAll()
    }

    func populateCache(for dates: [Date], reservations: [Reservation]) {
        for date in dates {
            let dateString = DateHelper.formatDate(date)
            let reservationsForDate = reservations.filter { $0.dateString == dateString }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the populateCache method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### precomputeActiveReservations (Line 72)

**Context:**

```swift
    }

    // MARK: - Active Reservations Management
    func precomputeActiveReservations(for date: Date) {
        guard let reservationsForDate = cache[date] else {
            logger.warning("No reservations found for date: \(DateHelper.formatDate(date))")
            return
```

**Suggested Documentation:**

```swift
/// [Add a description of what the precomputeActiveReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### startMonitoring (Line 108)

**Context:**

```swift
    }

    // MARK: - Monitoring
    func startMonitoring(for date: Date) {
        logger.debug("Stopped previous monitoring")
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
```

**Suggested Documentation:**

```swift
/// [Add a description of what the startMonitoring method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### checkForSignificantChanges (Line 117)

**Context:**

```swift
        logger.info("Started monitoring for date: \(DateHelper.formatDate(date))")
    }

    private func checkForSignificantChanges(date: Date) {
        let currentTime = Date()
        let activeReservations = activeReservations(for: date, at: currentTime)

```

**Suggested Documentation:**

```swift
/// [Add a description of what the checkForSignificantChanges method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### fetchReservations (Line 167)

**Context:**

```swift
    
    /// Fetches reservations for a specific date directly from Firebase
    @MainActor
    func fetchReservations(for date: Date) async throws -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date)
        logger.info("Fetching reservations from Firebase for date: \(targetDateString)")
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the fetchReservations method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### reservation (Line 290)

**Context:**

```swift
    /// Retrieves reservations for a specific table, date, and time
    /// Retrieves a single reservation for a specific table, date, and time
    @MainActor
    func reservation(forTable tableID: Int, datetime: Date, category: Reservation.ReservationCategory) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: datetime)
        guard let normalizedTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: datetime),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the reservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### clearAllCache (Line 372)

**Context:**

```swift
        logger.notice("Cleared cache for date: \(DateHelper.formatDate(date))")
    }

    func clearAllCache() {
        cache.removeAll()
        activeReservationsByMinute.removeAll()
        logger.notice("Cleared all cache data")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the clearAllCache method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### hash (Line 511)

**Context:**

```swift
    let time: Date
    let tableID: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(tableID)
        hasher.combine(date)
        hasher.combine(time)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the hash method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (98)

### logger (Line 7)

**Context:**

```swift

class CurrentReservationsCache: ObservableObject {
    // MARK: - Private Properties
    let logger = Logger(subsystem: "com.koenjiapp", category: "CurrentReservationsCache")
    // MARK: - Published Properties
    @Published var cache: [Date: [Reservation]] = [:]
    @Published var activeReservations: [Reservation] = []
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### cache (Line 9)

**Context:**

```swift
    // MARK: - Private Properties
    let logger = Logger(subsystem: "com.koenjiapp", category: "CurrentReservationsCache")
    // MARK: - Published Properties
    @Published var cache: [Date: [Reservation]] = [:]
    @Published var activeReservations: [Reservation] = []
    
    // MARK: - Properties
```

**Suggested Documentation:**

```swift
/// [Description of the cache property]
```

### activeReservations (Line 10)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "CurrentReservationsCache")
    // MARK: - Published Properties
    @Published var cache: [Date: [Reservation]] = [:]
    @Published var activeReservations: [Reservation] = []
    
    // MARK: - Properties
    private var preloadedDates: Set<Date> = []
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservations property]
```

### preloadedDates (Line 13)

**Context:**

```swift
    @Published var activeReservations: [Reservation] = []
    
    // MARK: - Properties
    private var preloadedDates: Set<Date> = []
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
```

**Suggested Documentation:**

```swift
/// [Description of the preloadedDates property]
```

### dateFormatter (Line 14)

**Context:**

```swift
    
    // MARK: - Properties
    private var preloadedDates: Set<Date> = []
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### activeReservationsByMinute (Line 15)

**Context:**

```swift
    // MARK: - Properties
    private var preloadedDates: Set<Date> = []
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
    private let db = Firestore.firestore()
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservationsByMinute property]
```

### timer (Line 16)

**Context:**

```swift
    private var preloadedDates: Set<Date> = []
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
    private let db = Firestore.firestore()
    
```

**Suggested Documentation:**

```swift
/// [Description of the timer property]
```

### calendar (Line 17)

**Context:**

```swift
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
    private let db = Firestore.firestore()
    
    // MARK: - Cache Management
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### db (Line 18)

**Context:**

```swift
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
    private let db = Firestore.firestore()
    
    // MARK: - Cache Management
    func preloadDates(around selectedDate: Date, range: Int, reservations: [Reservation]) {
```

**Suggested Documentation:**

```swift
/// [Description of the db property]
```

### newDates (Line 22)

**Context:**

```swift
    
    // MARK: - Cache Management
    func preloadDates(around selectedDate: Date, range: Int, reservations: [Reservation]) {
        let newDates = calculateDateRange(around: selectedDate, range: range)
        let datesToAdd = newDates.subtracting(preloadedDates)
        let datesToRemove = preloadedDates.subtracting(newDates)

```

**Suggested Documentation:**

```swift
/// [Description of the newDates property]
```

### datesToAdd (Line 23)

**Context:**

```swift
    // MARK: - Cache Management
    func preloadDates(around selectedDate: Date, range: Int, reservations: [Reservation]) {
        let newDates = calculateDateRange(around: selectedDate, range: range)
        let datesToAdd = newDates.subtracting(preloadedDates)
        let datesToRemove = preloadedDates.subtracting(newDates)

        // Remove outdated dates
```

**Suggested Documentation:**

```swift
/// [Description of the datesToAdd property]
```

### datesToRemove (Line 24)

**Context:**

```swift
    func preloadDates(around selectedDate: Date, range: Int, reservations: [Reservation]) {
        let newDates = calculateDateRange(around: selectedDate, range: range)
        let datesToAdd = newDates.subtracting(preloadedDates)
        let datesToRemove = preloadedDates.subtracting(newDates)

        // Remove outdated dates
        for date in datesToRemove {
```

**Suggested Documentation:**

```swift
/// [Description of the datesToRemove property]
```

### dateString (Line 33)

**Context:**

```swift

        // Add new dates
        for date in datesToAdd {
            let dateString = DateHelper.formatDate(date)
            cache[date] = reservations.filter { $0.dateString == dateString }
        }

```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### dateString (Line 53)

**Context:**

```swift

    func populateCache(for dates: [Date], reservations: [Reservation]) {
        for date in dates {
            let dateString = DateHelper.formatDate(date)
            let reservationsForDate = reservations.filter { $0.dateString == dateString }
            cache[date] = reservationsForDate
        }
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### reservationsForDate (Line 54)

**Context:**

```swift
    func populateCache(for dates: [Date], reservations: [Reservation]) {
        for date in dates {
            let dateString = DateHelper.formatDate(date)
            let reservationsForDate = reservations.filter { $0.dateString == dateString }
            cache[date] = reservationsForDate
        }
        logger.info("Populated cache for \(dates.count) dates with \(reservations.count) reservations")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsForDate property]
```

### dateSet (Line 62)

**Context:**

```swift

    /// Calculates a range of dates around a selected date
    private func calculateDateRange(around date: Date, range: Int) -> Set<Date> {
        var dateSet: Set<Date> = []
        for offset in -range...range {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                dateSet.insert(calendar.startOfDay(for: newDate))  // Normalize to start of the day
```

**Suggested Documentation:**

```swift
/// [Description of the dateSet property]
```

### newDate (Line 64)

**Context:**

```swift
    private func calculateDateRange(around date: Date, range: Int) -> Set<Date> {
        var dateSet: Set<Date> = []
        for offset in -range...range {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                dateSet.insert(calendar.startOfDay(for: newDate))  // Normalize to start of the day
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the newDate property]
```

### reservationsForDate (Line 73)

**Context:**

```swift

    // MARK: - Active Reservations Management
    func precomputeActiveReservations(for date: Date) {
        guard let reservationsForDate = cache[date] else {
            logger.warning("No reservations found for date: \(DateHelper.formatDate(date))")
            return
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsForDate property]
```

### activeReservations (Line 78)

**Context:**

```swift
            return
        }

        var activeReservations: [Date: [Reservation]] = [:]
        for reservation in reservationsForDate {
            guard let startTime = reservation.startTimeDate,
                  let endTime = reservation.endTimeDate else {
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservations property]
```

### startTime (Line 80)

**Context:**

```swift

        var activeReservations: [Date: [Reservation]] = [:]
        for reservation in reservationsForDate {
            guard let startTime = reservation.startTimeDate,
                  let endTime = reservation.endTimeDate else {
                logger.error("Invalid time data for reservation: \(reservation.id)")
                continue
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 81)

**Context:**

```swift
        var activeReservations: [Date: [Reservation]] = [:]
        for reservation in reservationsForDate {
            guard let startTime = reservation.startTimeDate,
                  let endTime = reservation.endTimeDate else {
                logger.error("Invalid time data for reservation: \(reservation.id)")
                continue
            }
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### current (Line 86)

**Context:**

```swift
                continue
            }
            
            var current = startTime
            while current < endTime {
                let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: current)!
                if activeReservations[normalizedMinute] == nil {
```

**Suggested Documentation:**

```swift
/// [Description of the current property]
```

### normalizedMinute (Line 88)

**Context:**

```swift
            
            var current = startTime
            while current < endTime {
                let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: current)!
                if activeReservations[normalizedMinute] == nil {
                    activeReservations[normalizedMinute] = []
                }
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedMinute property]
```

### normalizedMinute (Line 103)

**Context:**

```swift

    /// Retrieves active reservations for a specific time
    func activeReservations(for date: Date, at time: Date) -> [Reservation] {
        let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: time)!
        return activeReservationsByMinute[date]?[normalizedMinute] ?? []
    }

```

**Suggested Documentation:**

```swift
/// [Description of the normalizedMinute property]
```

### currentTime (Line 118)

**Context:**

```swift
    }

    private func checkForSignificantChanges(date: Date) {
        let currentTime = Date()
        let activeReservations = activeReservations(for: date, at: currentTime)

        let reservationsEndingSoon = activeReservations.filter {
```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```

### activeReservations (Line 119)

**Context:**

```swift

    private func checkForSignificantChanges(date: Date) {
        let currentTime = Date()
        let activeReservations = activeReservations(for: date, at: currentTime)

        let reservationsEndingSoon = activeReservations.filter {
            $0.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
```

**Suggested Documentation:**

```swift
/// [Description of the activeReservations property]
```

### reservationsEndingSoon (Line 121)

**Context:**

```swift
        let currentTime = Date()
        let activeReservations = activeReservations(for: date, at: currentTime)

        let reservationsEndingSoon = activeReservations.filter {
            $0.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
        }

```

**Suggested Documentation:**

```swift
/// [Description of the reservationsEndingSoon property]
```

### reservationsLate (Line 125)

**Context:**

```swift
            $0.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
        }

        let reservationsLate = activeReservations.filter {
            $0.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
                && $0.status != .showedUp
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsLate property]
```

### startDate (Line 142)

**Context:**

```swift
    func generateCacheKey(for reservation: Reservation, at time: Date, tableID: Int)
        -> ActiveReservationCacheKey?
    {
        guard let startDate = reservation.startTimeDate,
            let endDate = reservation.endTimeDate
        else {
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### endDate (Line 143)

**Context:**

```swift
        -> ActiveReservationCacheKey?
    {
        guard let startDate = reservation.startTimeDate,
            let endDate = reservation.endTimeDate
        else {
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the endDate property]
```

### normalizedDate (Line 154)

**Context:**

```swift
        }

        // Normalize the date to the start of the day
        let normalizedDate = calendar.startOfDay(for: startDate)

        return ActiveReservationCacheKey(date: normalizedDate, time: time, tableID: tableID)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### normalizedDate (Line 161)

**Context:**

```swift

    /// Retrieves all reservations for a specific date
    func reservations(for date: Date) -> [Reservation] {
        let normalizedDate = calendar.startOfDay(for: date)  // Normalize to start of the day
        return cache[normalizedDate] ?? []
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### targetDateString (Line 168)

**Context:**

```swift
    /// Fetches reservations for a specific date directly from Firebase
    @MainActor
    func fetchReservations(for date: Date) async throws -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date)
        logger.info("Fetching reservations from Firebase for date: \(targetDateString)")
        
        #if DEBUG
```

**Suggested Documentation:**

```swift
/// [Description of the targetDateString property]
```

### reservationsRef (Line 172)

**Context:**

```swift
        logger.info("Fetching reservations from Firebase for date: \(targetDateString)")
        
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

### reservationsRef (Line 174)

**Context:**

```swift
        #if DEBUG
        let reservationsRef = db.collection("reservations")
        #else
        let reservationsRef = db.collection("reservations_release")
        #endif
        
        do {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsRef property]
```

### snapshot (Line 178)

**Context:**

```swift
        #endif
        
        do {
            let snapshot = try await reservationsRef
                .whereField("dateString", isEqualTo: targetDateString)
                .getDocuments()
            
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### results (Line 182)

**Context:**

```swift
                .whereField("dateString", isEqualTo: targetDateString)
                .getDocuments()
            
            var results: [Reservation] = []
            
            for document in snapshot.documents {
                if let reservation = try? reservationFromFirebaseDocument(document) {
```

**Suggested Documentation:**

```swift
/// [Description of the results property]
```

### reservation (Line 185)

**Context:**

```swift
            var results: [Reservation] = []
            
            for document in snapshot.documents {
                if let reservation = try? reservationFromFirebaseDocument(document) {
                    results.append(reservation)
                } else {
                    logger.error("Failed to decode reservation from document: \(document.documentID)")
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### data (Line 209)

**Context:**

```swift
    
    /// Converts a Firebase document to a Reservation object
    private func reservationFromFirebaseDocument(_ document: DocumentSnapshot) throws -> Reservation {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### idString (Line 214)

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

### id (Line 215)

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

### name (Line 216)

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

### phone (Line 217)

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

### numberOfPersons (Line 218)

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

### dateString (Line 219)

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

### categoryString (Line 220)

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

### category (Line 221)

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

### startTime (Line 222)

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

### endTime (Line 223)

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

### acceptanceString (Line 224)

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

### acceptance (Line 225)

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

### statusString (Line 226)

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

### status (Line 227)

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

### reservationTypeString (Line 228)

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

### reservationType (Line 229)

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

### group (Line 230)

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

### creationTimeInterval (Line 231)

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

### lastEditedTimeInterval (Line 232)

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

### isMock (Line 233)

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

### tables (Line 238)

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

### tablesData (Line 239)

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

### tableId (Line 241)

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

### tableName (Line 242)

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

### maxCapacity (Line 243)

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

### table (Line 244)

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

### tableIds (Line 248)

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

### notes (Line 256)

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

### assignedEmoji (Line 257)

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

### imageData (Line 258)

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

### preferredLanguage (Line 259)

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

### colorHue (Line 260)

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

### normalizedDate (Line 291)

**Context:**

```swift
    /// Retrieves a single reservation for a specific table, date, and time
    @MainActor
    func reservation(forTable tableID: Int, datetime: Date, category: Reservation.ReservationCategory) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: datetime)
        guard let normalizedTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: datetime),
            minute: calendar.component(.minute, from: datetime),
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### normalizedTime (Line 292)

**Context:**

```swift
    @MainActor
    func reservation(forTable tableID: Int, datetime: Date, category: Reservation.ReservationCategory) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: datetime)
        guard let normalizedTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: datetime),
            minute: calendar.component(.minute, from: datetime),
            second: 0,
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedTime property]
```

### reservationsForDate (Line 302)

**Context:**

```swift
            return nil
        }

        let reservationsForDate = cache[normalizedDate] ?? []
        let currentReservation = reservationsForDate.first { reservation in
            reservation.tables.contains { $0.id == tableID }
            && normalizedTime >= (reservation.startTimeDate ?? Date())
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsForDate property]
```

### currentReservation (Line 303)

**Context:**

```swift
        }

        let reservationsForDate = cache[normalizedDate] ?? []
        let currentReservation = reservationsForDate.first { reservation in
            reservation.tables.contains { $0.id == tableID }
            && normalizedTime >= (reservation.startTimeDate ?? Date())
            && normalizedTime <= (reservation.endTimeDate ?? Date())
```

**Suggested Documentation:**

```swift
/// [Description of the currentReservation property]
```

### reservation (Line 310)

**Context:**

```swift
            && (reservation.category == category)
        }

        if let reservation = currentReservation {
            logger.debug("Found reservation '\(reservation.name)' at table \(tableID) for \(datetime)")
        } else {
            logger.debug("No reservation found at table \(tableID) for \(datetime)")
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### normalizedDate (Line 332)

**Context:**

```swift
            return
        }
        
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        if var reservationsForDate = cache[normalizedDate] {
            if let index = reservationsForDate.firstIndex(where: { $0.id == reservation.id }) {
                reservationsForDate[index] = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### reservationsForDate (Line 333)

**Context:**

```swift
        }
        
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        if var reservationsForDate = cache[normalizedDate] {
            if let index = reservationsForDate.firstIndex(where: { $0.id == reservation.id }) {
                reservationsForDate[index] = reservation
                logger.info("Updated existing reservation: \(reservation.id)")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsForDate property]
```

### index (Line 334)

**Context:**

```swift
        
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        if var reservationsForDate = cache[normalizedDate] {
            if let index = reservationsForDate.firstIndex(where: { $0.id == reservation.id }) {
                reservationsForDate[index] = reservation
                logger.info("Updated existing reservation: \(reservation.id)")
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### normalizedDate (Line 352)

**Context:**

```swift

    /// Removes a specific reservation
    func removeReservation(_ reservation: Reservation) {
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        cache[normalizedDate]?.removeAll(where: { $0.id == reservation.id })
        logger.info("Removed reservation: \(reservation.id) from cache")
        precomputeActiveReservations(for: normalizedDate)
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### lateReservations (Line 382)

**Context:**

```swift

    /// Retrieves reservations that are late
    func lateReservations(currentTime: Date) -> [Reservation] {
        let lateReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
            && reservation.status != .showedUp
        }
```

**Suggested Documentation:**

```swift
/// [Description of the lateReservations property]
```

### nearingEndReservations (Line 392)

**Context:**

```swift

    /// Retrieves reservations nearing their end
    func nearingEndReservations(currentTime: Date) -> [Reservation] {
        let nearingEndReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
                && reservation.endTimeDate ?? Date() > currentTime
        }
```

**Suggested Documentation:**

```swift
/// [Description of the nearingEndReservations property]
```

### normalizedDate (Line 407)

**Context:**

```swift
        time: Date,
        category: Reservation.ReservationCategory
    ) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedTime = calendar.date(bySetting: .second, value: 0, of: time) ?? time

        // Define category-specific time windows
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### normalizedTime (Line 408)

**Context:**

```swift
        category: Reservation.ReservationCategory
    ) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedTime = calendar.date(bySetting: .second, value: 0, of: time) ?? time

        // Define category-specific time windows
        let lunchStartTime = calendar.date(
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedTime property]
```

### lunchStartTime (Line 411)

**Context:**

```swift
        let normalizedTime = calendar.date(bySetting: .second, value: 0, of: time) ?? time

        // Define category-specific time windows
        let lunchStartTime = calendar.date(
            bySettingHour: 12, minute: 0, second: 0, of: normalizedDate)!
        let lunchEndTime = calendar.date(
            bySettingHour: 15, minute: 0, second: 0, of: normalizedDate)!
```

**Suggested Documentation:**

```swift
/// [Description of the lunchStartTime property]
```

### lunchEndTime (Line 413)

**Context:**

```swift
        // Define category-specific time windows
        let lunchStartTime = calendar.date(
            bySettingHour: 12, minute: 0, second: 0, of: normalizedDate)!
        let lunchEndTime = calendar.date(
            bySettingHour: 15, minute: 0, second: 0, of: normalizedDate)!
        let dinnerStartTime = calendar.date(
            bySettingHour: 18, minute: 0, second: 0, of: normalizedDate)!
```

**Suggested Documentation:**

```swift
/// [Description of the lunchEndTime property]
```

### dinnerStartTime (Line 415)

**Context:**

```swift
            bySettingHour: 12, minute: 0, second: 0, of: normalizedDate)!
        let lunchEndTime = calendar.date(
            bySettingHour: 15, minute: 0, second: 0, of: normalizedDate)!
        let dinnerStartTime = calendar.date(
            bySettingHour: 18, minute: 0, second: 0, of: normalizedDate)!
        let dinnerEndTime = calendar.date(
            bySettingHour: 23, minute: 45, second: 0, of: normalizedDate)!
```

**Suggested Documentation:**

```swift
/// [Description of the dinnerStartTime property]
```

### dinnerEndTime (Line 417)

**Context:**

```swift
            bySettingHour: 15, minute: 0, second: 0, of: normalizedDate)!
        let dinnerStartTime = calendar.date(
            bySettingHour: 18, minute: 0, second: 0, of: normalizedDate)!
        let dinnerEndTime = calendar.date(
            bySettingHour: 23, minute: 45, second: 0, of: normalizedDate)!

        let categoryCopy: Reservation.ReservationCategory = category
```

**Suggested Documentation:**

```swift
/// [Description of the dinnerEndTime property]
```

### categoryCopy (Line 420)

**Context:**

```swift
        let dinnerEndTime = calendar.date(
            bySettingHour: 23, minute: 45, second: 0, of: normalizedDate)!

        let categoryCopy: Reservation.ReservationCategory = category
        
        let (startTime, endTime): (Date, Date) = {
            switch category {
```

**Suggested Documentation:**

```swift
/// [Description of the categoryCopy property]
```

### reservationsForDate (Line 434)

**Context:**

```swift
            }
        }()

        let reservationsForDate = cache[normalizedDate] ?? []
        logger.debug("Searching upcoming reservations for table \(tableID) on \(DateHelper.formatDate(date)). Found \(reservationsForDate.count) total reservations")

        let firstUpcoming = reservationsForDate
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsForDate property]
```

### firstUpcoming (Line 437)

**Context:**

```swift
        let reservationsForDate = cache[normalizedDate] ?? []
        logger.debug("Searching upcoming reservations for table \(tableID) on \(DateHelper.formatDate(date)). Found \(reservationsForDate.count) total reservations")

        let firstUpcoming = reservationsForDate
            .filter { reservation in
                // Check if the reservation is for this table
                reservation.tables.contains { $0.id == tableID } &&
```

**Suggested Documentation:**

```swift
/// [Description of the firstUpcoming property]
```

### reservation (Line 460)

**Context:**

```swift
            .sorted { $0.startTimeDate ?? Date() < $1.startTimeDate ?? Date() }
            .first

        if let reservation = firstUpcoming {
            logger.debug("Found upcoming reservation: \(reservation.name) at \(reservation.startTime)")
        } else {
            logger.debug("No upcoming reservations found for table \(tableID, privacy: .public) in \(category.localized) period")
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### totalRemoved (Line 472)

**Context:**

```swift
    /// Validates the cache and removes any invalid reservations
    func validateCache() {
        logger.info("Validating reservation cache")
        var totalRemoved = 0
        
        // Note: Cancelled and waiting list reservations are intentionally filtered out of the cache.
        // Special views like ReservationCancelledView and ReservationWaitingListView need to fetch
```

**Suggested Documentation:**

```swift
/// [Description of the totalRemoved property]
```

### validReservations (Line 478)

**Context:**

```swift
        // Special views like ReservationCancelledView and ReservationWaitingListView need to fetch
        // these types of reservations directly from Firebase.
        for (date, reservations) in cache {
            let validReservations = reservations.filter { reservation in
                let isValid = reservation.status != .canceled && 
                              reservation.status != .deleted && 
                              reservation.status != .toHandle &&
```

**Suggested Documentation:**

```swift
/// [Description of the validReservations property]
```

### isValid (Line 479)

**Context:**

```swift
        // these types of reservations directly from Firebase.
        for (date, reservations) in cache {
            let validReservations = reservations.filter { reservation in
                let isValid = reservation.status != .canceled && 
                              reservation.status != .deleted && 
                              reservation.status != .toHandle &&
                              reservation.reservationType != .waitingList
```

**Suggested Documentation:**

```swift
/// [Description of the isValid property]
```

### date (Line 507)

**Context:**

```swift
}

struct ActiveReservationCacheKey: Hashable, Codable {
    let date: Date
    let time: Date
    let tableID: Int

```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### time (Line 508)

**Context:**

```swift

struct ActiveReservationCacheKey: Hashable, Codable {
    let date: Date
    let time: Date
    let tableID: Int

    func hash(into hasher: inout Hasher) {
```

**Suggested Documentation:**

```swift
/// [Description of the time property]
```

### tableID (Line 509)

**Context:**

```swift
struct ActiveReservationCacheKey: Hashable, Codable {
    let date: Date
    let time: Date
    let tableID: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(tableID)
```

**Suggested Documentation:**

```swift
/// [Description of the tableID property]
```


Total documentation suggestions: 109

