import SwiftUI
import SQLite

class CurrentReservationsCache: ObservableObject {
    @Published var cache: [Date: [Reservation]] = [:]  // Cache now uses Date as the key
    var preloadedDates: Set<Date> = []
    var dateFormatter: DateFormatter = DateFormatter()
    var activeReservationsByMinute: [Date: [Date: [Reservation]]] = [:]
    var timer: Timer?
    let calendar = Calendar.current
    @Published var activeReservations: [Reservation] = []
    let reservationsTable = Table("reservations")

    let idColumn = Expression<String>("id")
    let categoryColumn = Expression<String>("category")
    let dateStringColumn = Expression<String>("dateString")
    let startTimeColumn = Expression<String>("startTime")
    let endTimeColumn = Expression<String>("endTime")
    let tablesColumn = Expression<String>("tables") // JSON text

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

        print(
            "DEBUG: successfully preloaded dates (\(preloadedDates.count) dates) around selected date \(DateHelper.formatDate(selectedDate)) with \(reservations.count) reservations!"
        )
    }

    /// Populates cache for a list of dates
    func populateCache(for dates: [Date], reservations: [Reservation]) {
        for date in dates {
            let dateString = DateHelper.formatDate(date)
            let reservationsForDate = reservations.filter { $0.dateString == dateString }
            cache[date] = reservationsForDate
        }
        print(
            "DEBUG: successfully populated cache for selected dates (\(dates.count) dates) and reservations (\(reservations.count) reservations)!"
        )
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

    // MARK: - Precompute Active Reservations

    /// Precomputes active reservations for every minute of a day
    func precomputeActiveReservations(for date: Date) {
        guard let reservationsForDate = cache[date] else { return }

        var activeReservations: [Date: [Reservation]] = [:]

        for reservation in reservationsForDate {
            var current = reservation.startTimeDate ?? Date()
            while current < reservation.endTimeDate ?? Date() {
                let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: current)!
                if activeReservations[normalizedMinute] == nil {
                    activeReservations[normalizedMinute] = []
                }
                activeReservations[normalizedMinute]?.append(reservation)
                current.addTimeInterval(60)  // Advance by 1 minute
            }
        }

        activeReservationsByMinute[date] = activeReservations
    }

    /// Retrieves active reservations for a specific time
    func activeReservations(for date: Date, at time: Date) -> [Reservation] {
        let normalizedMinute = calendar.date(bySetting: .second, value: 0, of: time)!
        return activeReservationsByMinute[date]?[normalizedMinute] ?? []
    }

    // MARK: - Monitoring Significant Changes

    /// Starts monitoring for significant changes for a specific date
    func startMonitoring(for date: Date) {
        stopMonitoring()  // Stop existing timer if any
        print("DEBUG: stopped monitoring...")
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForSignificantChanges(date: date)
        }
        print("DEBUG: started monitoring for date \(date)...")

    }

    /// Stops the timer monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// Checks for significant changes in reservations
    private func checkForSignificantChanges(date: Date) {
        let currentTime = Date()
        let activeReservations = activeReservations(for: date, at: currentTime)

        // Check for significant events
        let reservationsEndingSoon = activeReservations.filter {
            $0.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
        }

        let reservationsLate = activeReservations.filter {
            $0.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
                && $0.status != .showedUp
        }

        // Notify the UI if there are changes
        if !reservationsEndingSoon.isEmpty || !reservationsLate.isEmpty {
                print("DEBUG: significant changes have been detected!")
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
    
    @MainActor
    func fetchReservations(for date: Date) -> [Reservation] {
        // Format the target date in the same format as stored.
        let targetDateString = DateHelper.formatDate(date)
        
        // Build the query filtering by dateString.
        let query = reservationsTable.filter(Expression<String>("dateString") == targetDateString)
        
        var results: [Reservation] = []
        do {
            for row in try SQLiteManager.shared.db.prepare(query) {
                if let reservation = ReservationMapper.reservation(from: row) {
                    results.append(reservation)
                }
            }
        } catch {
            print("Error fetching reservations for \(targetDateString): \(error)")
        }
        return results
    }


    /// Retrieves reservations for a specific table, date, and time
    /// Retrieves a single reservation for a specific table, date, and time
    @MainActor
    func reservation(forTable tableID: Int, datetime: Date, category: Reservation.ReservationCategory) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: datetime)  // Normalize to start of the day
        guard let normalizedTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: datetime),
            minute: calendar.component(.minute, from: datetime),
            second: 0,
            of: datetime
        ) else {
            print("DEBUG: Failed to normalize datetime: \(datetime)")
            return nil
        }
        // Normalize time to the nearest minute

        // Retrieve reservations for the given date
        let reservationsForDate = fetchReservations(for: datetime)

        // Find the current active reservation with the specified category
        let currentReservation = reservationsForDate.first { reservation in
            reservation.tables.contains { $0.id == tableID }
            && normalizedTime >= (reservation.startTimeDate ?? Date())
            && normalizedTime <= (reservation.endTimeDate ?? Date())
            && (reservation.category == category)  // **Include category in the filter**
        }

        if let reservation = currentReservation {
            print("DEBUG: retrieved reservation \(reservation.name) at table \(tableID) on \(datetime)")
            return reservation
        } else {
            print("DEBUG: no reservation found at table \(tableID) on \(datetime)")
            return nil
        }
    }

    /// Adds or updates a reservation
    func addOrUpdateReservation(_ reservation: Reservation) {
        let normalizedDate = calendar.startOfDay(for: reservation.startTimeDate ?? Date())
        if var reservationsForDate = cache[normalizedDate] {
            if let index = reservationsForDate.firstIndex(where: { $0.id == reservation.id }) {
                reservationsForDate[index] = reservation
            } else {
                reservationsForDate.append(reservation)
            }
            print("DEBUG: found some new reservations to add to cache. Adding...")
            cache[normalizedDate] = reservationsForDate
        } else {
            print("DEBUG: found ALL new reservations to add. Adding...")
            cache[normalizedDate] = [reservation]
        }

        // Recompute active reservations for the updated day
        precomputeActiveReservations(for: normalizedDate)
    }

    /// Removes a specific reservation
    func removeReservation(_ reservation: Reservation) {
        let normalizedDate = Calendar.current.startOfDay(for: reservation.startTimeDate ?? Date())
        cache[normalizedDate]?.removeAll(where: { $0.id == reservation.id })
        print("DEBUG: successfully removed reservation \(reservation.name) from cache!")
        // Recompute active reservations for the updated day
        precomputeActiveReservations(for: normalizedDate)
    }

    /// Removes a reservation by its ID
    func removeReservation(byId id: UUID, for date: Date) {
        cache[date]?.removeAll(where: { $0.id == id })
        print("DEBUG: successfully removed reservation from cache!")

        // Recompute active reservations for the updated day
        precomputeActiveReservations(for: date)
    }

    /// Clears cache for a specific date
    func clearCache(for date: Date) {
        cache.removeValue(forKey: date)
        activeReservationsByMinute.removeValue(forKey: date)
        print("DEBUG: successfully cleared all cache for date \(date)!")
    }

    func clearAllCache() {
        cache.removeAll()
        activeReservationsByMinute.removeAll()
        print("DEBUG: successfully cleared all cache!")
    }

    // MARK: - Minute-Level Precision Checks

    /// Retrieves reservations that are late
    func lateReservations(currentTime: Date) -> [Reservation] {
        let lateReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.startTimeDate?.addingTimeInterval(15 * 60) ?? Date() < currentTime
            && reservation.status != .showedUp
        }
        print("DEBUG: found \(lateReservations.count) late reservations!")
        return lateReservations
    }

    /// Retrieves reservations nearing their end
    func nearingEndReservations(currentTime: Date) -> [Reservation] {
        let nearingEndReservations = cache.flatMap { $0.value }.filter { reservation in
            reservation.endTimeDate?.timeIntervalSince(currentTime) ?? 0 <= 30 * 60
                && reservation.endTimeDate ?? Date() > currentTime
        }
        print("DEBUG: found \(nearingEndReservations.count) reservations nearing their end!")
        return nearingEndReservations
    }

    /// Retrieves the first upcoming reservation for a specific table, date, time, and category
    func firstUpcomingReservation(
        forTable tableID: Int,
        date: Date,
        time: Date,
        category: Reservation.ReservationCategory
    ) -> Reservation? {
        let normalizedDate = calendar.startOfDay(for: date)  // Normalize to start of the day
        let normalizedTime = calendar.date(bySetting: .second, value: 0, of: time) ?? time  // Normalize time to the nearest minute

        // Define category-specific time windows
        let lunchStartTime = calendar.date(
            bySettingHour: 12, minute: 0, second: 0, of: normalizedDate)!
        let lunchEndTime = calendar.date(
            bySettingHour: 15, minute: 0, second: 0, of: normalizedDate)!
        let dinnerStartTime = calendar.date(
            bySettingHour: 18, minute: 0, second: 0, of: normalizedDate)!
        let dinnerEndTime = calendar.date(
            bySettingHour: 23, minute: 45, second: 0, of: normalizedDate)!

        // Determine the time window for the given category
        let (startTime, endTime): (Date, Date) = {
            switch category {
            case .lunch:
                return (lunchStartTime, lunchEndTime)
            case .dinner:
                return (dinnerStartTime, dinnerEndTime)
            default:
                return (normalizedTime, normalizedTime)  // Invalid category
            }
        }()

        // Retrieve reservations for the given date
        let reservationsForDate = cache[normalizedDate] ?? []
        print("Reservations for date \(normalizedDate): \(reservationsForDate.count)")

        // Find the first upcoming reservation
        let firstUp =
            reservationsForDate
            .filter { reservation in
                reservation.tables.contains { $0.id == tableID }
                    && (reservation.startTimeDate ?? Date()) > normalizedTime
                    && (reservation.startTimeDate ?? Date()) > startTime
                    && (reservation.startTimeDate ?? Date()) <= endTime
                    && normalizedTime <= (reservation.endTimeDate ?? Date())
                    
            }
            .sorted { $0.startTimeDate ?? Date() < $1.startTimeDate ?? Date() }
            .first
        if firstUp != nil {

            return firstUp
        } else {
            print("DEBUG: no upcoming reservations found.")
            return nil
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
