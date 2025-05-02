import SwiftUI
import FirebaseFirestore
import OSLog

class CurrentReservationsCache: ObservableObject {
    // MARK: - Published Properties
    @Published var cache: [Date: [Reservation]] = [:]
    @Published var activeReservations: [Reservation] = []
    
    // MARK: - Properties
    private var preloadedDates: Set<Date> = []
    private var dateFormatter: DateFormatter = DateFormatter()
    private var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    private var timer: Timer?
    private let calendar = Calendar.current
    private let db: Firestore?
    
    init() {
        // Use the safe Firebase initialization method
        self.db = AppDependencies.getFirestore()
    }
    
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

        let preloadedDatesCount = self.preloadedDates.count
        let reservationsCount = reservations.count
        Task { @MainActor in
            AppLog.info("Preloaded \(preloadedDatesCount) dates around \(DateHelper.formatDate(selectedDate)) with \(reservationsCount) reservations")
        }
    }
    
    /// Clears the entire cache and resets preloaded dates
    func clearCache() {
        Task { @MainActor in
            AppLog.info("Clearing reservation cache")
        }
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
        Task { @MainActor in
            AppLog.info("Populated cache for \(dates.count) dates with \(reservations.count) reservations")
        }
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
            Task { @MainActor in
                AppLog.warning("No reservations found for date: \(DateHelper.formatDate(date))")
            }
            return
        }

        var activeReservations: [Date: [Reservation]] = [:]
        for reservation in reservationsForDate {
            guard let startTime = reservation.startTimeDate,
                  let endTime = reservation.endTimeDate else {
                Task { @MainActor in
                    AppLog.error("Invalid time data for reservation: \(reservation.id)")
                }
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
        Task { @MainActor in
            AppLog.debug("Precomputed active reservations for \(DateHelper.formatDate(date))")
        }
    }

    /// Retrieves active reservations for a specific time
    func activeReservations(for date: Date, at time: Date) -> [Reservation] {
        let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: time)!
        return activeReservationsByMinute[date]?[normalizedMinute] ?? []
    }

    // MARK: - Monitoring
    func startMonitoring(for date: Date) {
        Task { @MainActor in
            AppLog.debug("Stopped previous monitoring")
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForSignificantChanges(date: date)
        }
        Task { @MainActor in
            AppLog.info("Started monitoring for date: \(DateHelper.formatDate(date))")
        }
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
            Task { @MainActor in
                AppLog.info("Significant changes detected - Late: \(reservationsLate.count), Ending Soon: \(reservationsEndingSoon.count)")
            }
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

    
    /// Fetches reservations for a specific date from the cache
    @MainActor
    func fetchReservations(for date: Date) async throws -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date)
        let normalizedDate = calendar.startOfDay(for: date)
        
        AppLog.info("Fetching reservations from cache for date: \(targetDateString)")
        
        // Check if we have the data in the cache
        if let cachedReservations = cache[normalizedDate] {
            AppLog.debug("Retrieved \(cachedReservations.count) reservations for \(targetDateString) from cache")
            return cachedReservations
        }
        
        // If we don't have the data in the cache, return an empty array
        // The caller should ensure the cache is properly populated before using this method
        AppLog.warning("No reservations found in cache for date: \(targetDateString)")
        return []
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
            AppLog.error("Failed to normalize datetime: \(datetime)")
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
            Task { @MainActor in
                AppLog.debug("Found reservation '\(reservation.name)' at table \(tableID) for \(datetime)")
            }
        } else {
            Task { @MainActor in
                AppLog.debug("No reservation found at table \(tableID) for \(datetime)")
            }
        }
        return currentReservation
    }

    /// Adds or updates a reservation in both the cache and Firebase
    /// - Parameter reservation: The reservation to add or update
    /// - Parameter updateFirebase: Whether to also update Firebase (default: true)
    func addOrUpdateReservation(_ reservation: Reservation, updateFirebase: Bool = true) {
        // Skip invalid reservations
        // Note: Cancelled and waiting list reservations are intentionally filtered out of the cache.
        // Special views like ReservationCancelledView and ReservationWaitingListView need to fetch
        // these types of reservations directly from Firebase.
        if reservation.status == .canceled || 
           reservation.status == .deleted || 
           reservation.status == .toHandle ||
           reservation.reservationType == .waitingList {
            Task { @MainActor in
                AppLog.debug("Skipping invalid reservation: \(reservation.name) (status: \(reservation.status.rawValue), type: \(reservation.reservationType.rawValue))")
            }
            return
        }
        
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        if var reservationsForDate = cache[normalizedDate] {
            if let index = reservationsForDate.firstIndex(where: { $0.id == reservation.id }) {
                reservationsForDate[index] = reservation
                Task { @MainActor in
                    AppLog.info("Updated existing reservation: \(reservation.id)")
                }
            } else {
                reservationsForDate.append(reservation)
                Task { @MainActor in
                    AppLog.info("Added new reservation: \(reservation.id)")
                }
            }
            cache[normalizedDate] = reservationsForDate
        } else {
            cache[normalizedDate] = [reservation]
            Task { @MainActor in
                AppLog.info("Created new cache entry for date with reservation: \(reservation.id)")
            }
        }

        precomputeActiveReservations(for: normalizedDate)
        
        // Update Firebase if requested
        if updateFirebase {
            updateReservationInFirebase(reservation)
        }
    }
    
    /// Updates a reservation in Firebase
    /// - Parameter reservation: The reservation to update
    private func updateReservationInFirebase(_ reservation: Reservation) {
        Task {
            do {
                let reservationStore = FirestoreDataStore<Reservation>(collectionName: "reservations")
                
                // Directly update the document in Firebase to avoid triggering listeners
                // that would reparse all reservations
                let docRef = await reservationStore.collection.document(reservation.id.uuidString)
                let data = ReservationMapper.encode(reservation)
                try await docRef.setData(data)
                
                await MainActor.run {
                    AppLog.info("Updated reservation \(reservation.id) in Firebase")
                }
            } catch {
                await MainActor.run {
                    AppLog.error("Failed to update reservation in Firebase: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Removes a specific reservation
    func removeReservation(_ reservation: Reservation) {
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        cache[normalizedDate]?.removeAll(where: { $0.id == reservation.id })
        Task { @MainActor in
            AppLog.info("Removed reservation: \(reservation.id) from cache")
        }
        precomputeActiveReservations(for: normalizedDate)
    }

    /// Removes a reservation by its ID
    func removeReservation(byId id: UUID, for date: Date) {
        cache[date]?.removeAll(where: { $0.id == id })
        Task { @MainActor in
            AppLog.info("Removed reservation ID: \(id) from cache")
        }
        precomputeActiveReservations(for: date)
    }

    /// Clears cache for a specific date
    func clearCache(for date: Date) {
        cache.removeValue(forKey: date)
        activeReservationsByMinute.removeValue(forKey: date)
        Task { @MainActor in
            AppLog.info("Cleared cache for date: \(DateHelper.formatDate(date))")
        }
    }

    func clearAllCache() {
        cache.removeAll()
        activeReservationsByMinute.removeAll()
        Task { @MainActor in
            AppLog.info("Cleared all cache data")
        }
    }

    /// Clears all reservations from the cache, SQLite, and Firebase
    /// - Parameter completion: Callback with result (deleted count or error)
    func clearAllData(completion: @escaping (Result<Int, Error>) -> Void) {
        // First clear the local cache
        clearAllCache()
        
        // Clear SQLite data
        SQLiteManager.shared.deleteAllReservations()
        
        var result: Result<Int, Error> = .success(0)
        // Then clear the Firestore data
        Task {
            do {
                let reservationStore = FirestoreDataStore<Reservation>(collectionName: "reservations")
                let deletedCount = try await reservationStore.deleteAllDocuments()
                
                await MainActor.run {
                    AppLog.info("Deleted \(deletedCount) reservations from Firebase and SQLite")
                    result = .success(deletedCount)
                }
            } catch {
                await MainActor.run {
                    AppLog.error("Failed to delete reservations from Firebase: \(error.localizedDescription)")
                    result = .failure(error)
                }
            }
        }
        
        // Return the result to the caller
        completion(result)
    }

    // MARK: - Minute-Level Precision Checks

    /// Retrieves reservations that are late
    func lateReservations(currentTime: Date) -> [Reservation] {
        let lateReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
            && reservation.status != .showedUp
        }
        Task { @MainActor in
            AppLog.info("Found \(lateReservations.count) late reservations")
        }
        return lateReservations
    }

    /// Retrieves reservations nearing their end
    func nearingEndReservations(currentTime: Date) -> [Reservation] {
        let nearingEndReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
                && reservation.endTimeDate ?? Date() > currentTime
        }
        Task { @MainActor in
            AppLog.info("Found \(nearingEndReservations.count) reservations nearing end")
        }
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
                Task { @MainActor in
                    AppLog.warning("Invalid category specified: \(categoryCopy.localized)")
                }
                return (normalizedTime, normalizedTime)
            }
        }()

        let reservationsForDate = cache[normalizedDate] ?? []
        Task { @MainActor in
            AppLog.debug("Searching upcoming reservations for table \(tableID) on \(DateHelper.formatDate(date)). Found \(reservationsForDate.count) total reservations")
        }

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
            Task { @MainActor in
                AppLog.debug("Found upcoming reservation: \(reservation.name) at \(reservation.startTime)")
            }
        } else {
            Task { @MainActor in
                AppLog.debug("No upcoming reservations found for table \(tableID) in \(category.localized) period")
            }
        }
        
        return firstUpcoming
    }

    /// Validates the cache and removes any invalid reservations
    func validateCache() {
        Task { @MainActor in
            AppLog.info("Validating reservation cache")
        }
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
                    Task { @MainActor in
                        AppLog.debug("Removing invalid reservation from cache: \(reservation.name) (status: \(reservation.status.rawValue), type: \(reservation.reservationType.rawValue))")
                    }
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
            Task { @MainActor in
                AppLog.info("Removed \(totalRemoved) invalid reservations from cache")
            }
        }
    }

    /// Returns all reservations from all dates in the cache
    func getAllReservations() -> [Reservation] {
        return cache.flatMap { $0.value }
    }
    
    /// Loads all reservations directly from Firebase and populates the cache, with optional table assignment
    func loadReservationsFromFirebase(layoutServices: LayoutServices? = nil) async {
        Task { @MainActor in
            AppLog.info("Loading reservations directly from Firebase...")
        }
        
        do {
            let reservationStore = FirestoreDataStore<Reservation>(collectionName: "reservations")
            // Use FirestoreDataStore to get all reservations
            let loadedReservations: [Reservation]
            do {
                loadedReservations = try await reservationStore.getAll()
            } catch {
                Task { @MainActor in
                    AppLog.error("Failed to load reservations from Firebase: \(error)")
                }
                return
            }
            
            // Process the reservations (with table assignment if layoutServices is provided)
            var processedReservations = loadedReservations
            // Only perform table assignment if layout services are provided and there are reservations to process
            if let layoutServices = layoutServices, !loadedReservations.isEmpty {
                processedReservations = await assignTablesIfNeeded(loadedReservations, using: layoutServices)
            }
            
            // Clear and rebuild the cache with processed reservations
            rebuildCache(with: processedReservations)
            
            Task { @MainActor in
                AppLog.info("Successfully loaded \(processedReservations.count) reservations from Firebase")
            }
        }
    }
    
    /// Assigns tables to reservations that need them
    private func assignTablesIfNeeded(_ reservations: [Reservation], using layoutServices: LayoutServices) async -> [Reservation] {
        var updatedReservations: [Reservation] = []
        
        for reservation in reservations {
            // Only assign tables to confirmed reservations that don't have tables yet
            if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
                await MainActor.run {
                    AppLog.warning("⚠️ Found confirmed reservation with no tables: \(reservation.name)")
                }
                
                let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                if case .success(let assignedTables) = assignmentResult {
                    var updatedReservation = reservation
                    updatedReservation.tables = assignedTables
                    updatedReservations.append(updatedReservation)
                    await MainActor.run {
                        AppLog.info("✅ Auto-assigned tables to reservation: \(updatedReservation.name)")
                    }
                } else {
                    updatedReservations.append(reservation)
                    await MainActor.run {
                        AppLog.error("❌ Failed to auto-assign tables to reservation: \(reservation.name)")
                    }
                }
            } else {
                updatedReservations.append(reservation)
            }
        }
        
        return updatedReservations
    }
    
    /// Rebuilds the cache with the given reservations
    private func rebuildCache(with reservations: [Reservation]) {
        // Clear existing cache
        self.clearCache()
        
        // Add all reservations to the cache
        for reservation in reservations {
            self.addOrUpdateReservation(reservation)
        }
        
        // Preload dates around today
        let today = Calendar.current.startOfDay(for: Date())
        self.preloadDates(around: today, range: 5, reservations: reservations)
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
