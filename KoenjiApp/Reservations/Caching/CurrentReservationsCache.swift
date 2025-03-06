import SwiftUI
import FirebaseFirestore
import OSLog

class CurrentReservationsCache: ObservableObject {
    // MARK: - Private Properties
    let logger = Logger(subsystem: "com.koenjiapp", category: "CurrentReservationsCache")
    // MARK: - Published Properties
    @Published var cache: [Date: [Reservation]] = [:]
    @Published var activeReservations: [Reservation] = []
    
    // MARK: - Properties
    private var preloadedDates: Set<Date> = []
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
    private let db = Firestore.firestore()
    
    // MARK: - Cache Management
    func preloadDates(around selectedDate: Date, range: Int, reservations: [Reservation]) {
        let newDates = calculateDateRange(around: selectedDate, range: range)
        let datesToAdd = newDates.subtracting(preloadedDates)
        let datesToRemove = preloadedDates.subtracting(newDates)

        // Remove outdated dates
        for date in datesToRemove {
            cache.removeValue(forKey: date)
        }

        // Add new dates
        for date in datesToAdd {
            let dateString = DateHelper.formatDate(date)
            cache[date] = reservations.filter { $0.dateString == dateString }
        }

        preloadedDates = newDates
        populateCache(for: Array(newDates), reservations: reservations)

        logger.info("Preloaded \(self.preloadedDates.count) dates around \(DateHelper.formatDate(selectedDate)) with \(reservations.count) reservations")
    }
    
    /// Clears the entire cache and resets preloaded dates
    func clearCache() {
        logger.info("Clearing reservation cache")
        cache.removeAll()
        preloadedDates.removeAll()
        activeReservationsByMinute.removeAll()
    }

    func populateCache(for dates: [Date], reservations: [Reservation]) {
        for date in dates {
            let dateString = DateHelper.formatDate(date)
            let reservationsForDate = reservations.filter { $0.dateString == dateString }
            cache[date] = reservationsForDate
        }
        logger.info("Populated cache for \(dates.count) dates with \(reservations.count) reservations")
    }

    /// Calculates a range of dates around a selected date
    private func calculateDateRange(around date: Date, range: Int) -> Set<Date> {
        var dateSet: Set<Date> = []
        for offset in -range...range {
            if let newDate = calendar.date(byAdding: .day, value: offset, to: date) {
                dateSet.insert(calendar.startOfDay(for: newDate))  // Normalize to start of the day
            }
        }
        return dateSet
    }

    // MARK: - Active Reservations Management
    func precomputeActiveReservations(for date: Date) {
        guard let reservationsForDate = cache[date] else {
            logger.warning("No reservations found for date: \(DateHelper.formatDate(date))")
            return
        }

        var activeReservations: [Date: [Reservation]] = [:]
        for reservation in reservationsForDate {
            guard let startTime = reservation.startTimeDate,
                  let endTime = reservation.endTimeDate else {
                logger.error("Invalid time data for reservation: \(reservation.id)")
                continue
            }
            
            var current = startTime
            while current < endTime {
                let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: current)!
                if activeReservations[normalizedMinute] == nil {
                    activeReservations[normalizedMinute] = []
                }
                activeReservations[normalizedMinute]?.append(reservation)
                current.addTimeInterval(60)
            }
        }

        activeReservationsByMinute[date] = activeReservations
        logger.debug("Precomputed active reservations for \(DateHelper.formatDate(date))")
    }

    /// Retrieves active reservations for a specific time
    func activeReservations(for date: Date, at time: Date) -> [Reservation] {
        let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: time)!
        return activeReservationsByMinute[date]?[normalizedMinute] ?? []
    }

    // MARK: - Monitoring
    func startMonitoring(for date: Date) {
        logger.debug("Stopped previous monitoring")
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForSignificantChanges(date: date)
        }
        logger.info("Started monitoring for date: \(DateHelper.formatDate(date))")
    }

    private func checkForSignificantChanges(date: Date) {
        let currentTime = Date()
        let activeReservations = activeReservations(for: date, at: currentTime)

        let reservationsEndingSoon = activeReservations.filter {
            $0.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
        }

        let reservationsLate = activeReservations.filter {
            $0.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
                && $0.status != .showedUp
        }

        if !reservationsEndingSoon.isEmpty || !reservationsLate.isEmpty {
            logger.notice("Significant changes detected - Late: \(reservationsLate.count), Ending Soon: \(reservationsEndingSoon.count)")
            objectWillChange.send()
        }
    }

    // MARK: - Cache Operations

    /// Generates an `ActiveReservationCacheKey` for a specific date, time, and table ID
    func generateCacheKey(for reservation: Reservation, at time: Date, tableID: Int)
        -> ActiveReservationCacheKey?
    {
        guard let startDate = reservation.startTimeDate,
            let endDate = reservation.endTimeDate
        else {
            return nil
        }

        // Ensure the provided time is within the reservation's time range
        guard time >= startDate && time < endDate else {
            return nil
        }

        // Normalize the date to the start of the day
        let normalizedDate = calendar.startOfDay(for: startDate)

        return ActiveReservationCacheKey(date: normalizedDate, time: time, tableID: tableID)
    }

    /// Retrieves all reservations for a specific date
    func reservations(for date: Date) -> [Reservation] {
        let normalizedDate = calendar.startOfDay(for: date)  // Normalize to start of the day
        return cache[normalizedDate] ?? []
    }
    
    /// Fetches reservations for a specific date directly from Firebase
    @MainActor
    func fetchReservations(for date: Date) async throws -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date)
        logger.info("Fetching reservations from Firebase for date: \(targetDateString)")
        
        #if DEBUG
        let reservationsRef = db.collection("reservations")
        #else
        let reservationsRef = db.collection("reservations_release")
        #endif
        
        do {
            let snapshot = try await reservationsRef
                .whereField("dateString", isEqualTo: targetDateString)
                .getDocuments()
            
            var results: [Reservation] = []
            
            for document in snapshot.documents {
                if let reservation = try? reservationFromFirebaseDocument(document) {
                    results.append(reservation)
                } else {
                    logger.error("Failed to decode reservation from document: \(document.documentID)")
                }
            }
            
            // Update the cache with the fetched reservations
            cache[date] = results
            precomputeActiveReservations(for: date)
            
            // Validate the cache to remove any invalid reservations
            validateCache()
            
            logger.debug("Fetched \(results.count) reservations for \(targetDateString) from Firebase")
            return results
        } catch {
            logger.error("Failed to fetch reservations for \(targetDateString) from Firebase: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Converts a Firebase document to a Reservation object
    private func reservationFromFirebaseDocument(_ document: DocumentSnapshot) throws -> Reservation {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
        // Extract basic fields
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        // Extract tables
        var tables: [TableModel] = []
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
                    tables.append(table)
                }
            }
        } else if let tableIds = data["tableIds"] as? [Int] {
            // Fallback to tableIds if tables array is not available
            tables = tableIds.map { id in
                TableModel(id: id, name: "Table \(id)", maxCapacity: 4, row: 0, column: 0)
            }
        }
        
        // Extract optional fields
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        let colorHue = data["colorHue"] as? Double ?? 0.0
        
        // Create and return the reservation
        return Reservation(
            id: id,
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes,
            tables: tables,
            creationDate: Date(timeIntervalSince1970: creationTimeInterval),
            lastEditedOn: Date(timeIntervalSince1970: lastEditedTimeInterval),
            isMock: isMock,
            assignedEmoji: assignedEmoji ?? "",
            imageData: imageData,
            preferredLanguage: preferredLanguage
        )
    }

    /// Retrieves reservations for a specific table, date, and time
    /// Retrieves a single reservation for a specific table, date, and time
    @MainActor
    func reservation(forTable tableID: Int, datetime: Date, category: Reservation.ReservationCategory) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: datetime)
        guard let normalizedTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: datetime),
            minute: calendar.component(.minute, from: datetime),
            second: 0,
            of: datetime
        ) else {
            logger.error("Failed to normalize datetime: \(datetime)")
            return nil
        }

        let reservationsForDate = cache[normalizedDate] ?? []
        let currentReservation = reservationsForDate.first { reservation in
            reservation.tables.contains { $0.id == tableID }
            && normalizedTime >= (reservation.startTimeDate ?? Date())
            && normalizedTime <= (reservation.endTimeDate ?? Date())
            && (reservation.category == category)
        }

        if let reservation = currentReservation {
            logger.debug("Found reservation '\(reservation.name)' at table \(tableID) for \(datetime)")
        } else {
            logger.debug("No reservation found at table \(tableID) for \(datetime)")
        }
        return currentReservation
    }

    /// Adds or updates a reservation
    func addOrUpdateReservation(_ reservation: Reservation) {
        // Skip invalid reservations
        // Note: Cancelled and waiting list reservations are intentionally filtered out of the cache.
        // Special views like ReservationCancelledView and ReservationWaitingListView need to fetch
        // these types of reservations directly from Firebase.
        if reservation.status == .canceled || 
           reservation.status == .deleted || 
           reservation.status == .toHandle ||
           reservation.reservationType == .waitingList {
            logger.debug("Skipping invalid reservation: \(reservation.name) (status: \(reservation.status.rawValue), type: \(reservation.reservationType.rawValue))")
            return
        }
        
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        if var reservationsForDate = cache[normalizedDate] {
            if let index = reservationsForDate.firstIndex(where: { $0.id == reservation.id }) {
                reservationsForDate[index] = reservation
                logger.info("Updated existing reservation: \(reservation.id)")
            } else {
                reservationsForDate.append(reservation)
                logger.info("Added new reservation: \(reservation.id)")
            }
            cache[normalizedDate] = reservationsForDate
        } else {
            cache[normalizedDate] = [reservation]
            logger.info("Created new cache entry for date with reservation: \(reservation.id)")
        }

        precomputeActiveReservations(for: normalizedDate)
    }

    /// Removes a specific reservation
    func removeReservation(_ reservation: Reservation) {
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        cache[normalizedDate]?.removeAll(where: { $0.id == reservation.id })
        logger.info("Removed reservation: \(reservation.id) from cache")
        precomputeActiveReservations(for: normalizedDate)
    }

    /// Removes a reservation by its ID
    func removeReservation(byId id: UUID, for date: Date) {
        cache[date]?.removeAll(where: { $0.id == id })
        logger.info("Removed reservation ID: \(id) from cache")
        precomputeActiveReservations(for: date)
    }

    /// Clears cache for a specific date
    func clearCache(for date: Date) {
        cache.removeValue(forKey: date)
        activeReservationsByMinute.removeValue(forKey: date)
        logger.notice("Cleared cache for date: \(DateHelper.formatDate(date))")
    }

    func clearAllCache() {
        cache.removeAll()
        activeReservationsByMinute.removeAll()
        logger.notice("Cleared all cache data")
    }

    // MARK: - Minute-Level Precision Checks

    /// Retrieves reservations that are late
    func lateReservations(currentTime: Date) -> [Reservation] {
        let lateReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
            && reservation.status != .showedUp
        }
        logger.info("Found \(lateReservations.count) late reservations")
        return lateReservations
    }

    /// Retrieves reservations nearing their end
    func nearingEndReservations(currentTime: Date) -> [Reservation] {
        let nearingEndReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
                && reservation.endTimeDate ?? Date() > currentTime
        }
        logger.info("Found \(nearingEndReservations.count) reservations nearing end")
        return nearingEndReservations
    }

    /// Retrieves the first upcoming reservation for a specific table, date, time, and category
    func firstUpcomingReservation(
        forTable tableID: Int,
        date: Date,
        time: Date,
        category: Reservation.ReservationCategory
    ) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: date)
        let normalizedTime = calendar.date(bySetting: .second, value: 0, of: time) ?? time

        // Define category-specific time windows
        let lunchStartTime = calendar.date(
            bySettingHour: 12, minute: 0, second: 0, of: normalizedDate)!
        let lunchEndTime = calendar.date(
            bySettingHour: 15, minute: 0, second: 0, of: normalizedDate)!
        let dinnerStartTime = calendar.date(
            bySettingHour: 18, minute: 0, second: 0, of: normalizedDate)!
        let dinnerEndTime = calendar.date(
            bySettingHour: 23, minute: 45, second: 0, of: normalizedDate)!

        let categoryCopy: Reservation.ReservationCategory = category
        
        let (startTime, endTime): (Date, Date) = {
            switch category {
            case .lunch:
                return (lunchStartTime, lunchEndTime)
            case .dinner:
                return (dinnerStartTime, dinnerEndTime)
            default:
                logger.warning("Invalid category specified: \(categoryCopy.localized)")
                return (normalizedTime, normalizedTime)
            }
        }()

        let reservationsForDate = cache[normalizedDate] ?? []
        logger.debug("Searching upcoming reservations for table \(tableID) on \(DateHelper.formatDate(date)). Found \(reservationsForDate.count) total reservations")

        let firstUpcoming = reservationsForDate
            .filter { reservation in
                // Check if the reservation is for this table
                reservation.tables.contains { $0.id == tableID } &&
                // Check if the reservation starts after the current time
                (reservation.startTimeDate ?? Date()) > normalizedTime &&
                // Check if the reservation starts within the category time window
                (reservation.startTimeDate ?? Date()) > startTime &&
                (reservation.startTimeDate ?? Date()) <= endTime &&
                // Check if the current time is before the reservation ends
                normalizedTime <= (reservation.endTimeDate ?? Date()) &&
                // Check if the reservation is not canceled, deleted, or to handle
                reservation.status != .canceled &&
                reservation.status != .deleted &&
                reservation.status != .toHandle &&
                // Check if the reservation is not a waiting list reservation
                reservation.reservationType != .waitingList &&
                // Check if the reservation is confirmed
                reservation.acceptance == .confirmed
            }
            .sorted { $0.startTimeDate ?? Date() < $1.startTimeDate ?? Date() }
            .first

        if let reservation = firstUpcoming {
            logger.debug("Found upcoming reservation: \(reservation.name) at \(reservation.startTime)")
        } else {
            logger.debug("No upcoming reservations found for table \(tableID, privacy: .public) in \(category.localized) period")
        }
        
        return firstUpcoming
    }

    /// Validates the cache and removes any invalid reservations
    func validateCache() {
        logger.info("Validating reservation cache")
        var totalRemoved = 0
        
        // Note: Cancelled and waiting list reservations are intentionally filtered out of the cache.
        // Special views like ReservationCancelledView and ReservationWaitingListView need to fetch
        // these types of reservations directly from Firebase.
        for (date, reservations) in cache {
            let validReservations = reservations.filter { reservation in
                let isValid = reservation.status != .canceled && 
                              reservation.status != .deleted && 
                              reservation.status != .toHandle &&
                              reservation.reservationType != .waitingList
                
                if !isValid {
                    logger.debug("Removing invalid reservation from cache: \(reservation.name) (status: \(reservation.status.rawValue), type: \(reservation.reservationType.rawValue))")
                    totalRemoved += 1
                }
                
                return isValid
            }
            
            if validReservations.count != reservations.count {
                cache[date] = validReservations
                // Recompute active reservations for this date
                precomputeActiveReservations(for: date)
            }
        }
        
        if totalRemoved > 0 {
            logger.info("Removed \(totalRemoved) invalid reservations from cache")
        }
    }

}

struct ActiveReservationCacheKey: Hashable, Codable {
    let date: Date
    let time: Date
    let tableID: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(tableID)
        hasher.combine(date)
        hasher.combine(time)
    }

    static func == (lhs: ActiveReservationCacheKey, rhs: ActiveReservationCacheKey) -> Bool {
        return lhs.tableID == rhs.tableID && lhs.date == rhs.date && lhs.time == rhs.time
    }
}
