//
//  ReservationService.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation

/// A service class responsible for high-level operations on reservations.
/// This class interacts with the `ReservationStore` for managing reservation data.
class ReservationService: ObservableObject {
    // MARK: - Dependencies
    private let store: ReservationStore         
    private let clusterStore: ClusterStore
    private let clusterServices: ClusterServices
    private let tableStore: TableStore
    private let layoutServices: LayoutServices

    private let tableAssignmentService: TableAssignmentService

    // MARK: - Initializer
    init(store: ReservationStore, clusterStore: ClusterStore, clusterServices: ClusterServices, tableStore: TableStore, layoutServices: LayoutServices, tableAssignmentService: TableAssignmentService) {
        self.store = store
        self.clusterStore = clusterStore
        self.clusterServices = clusterServices
        self.tableStore = tableStore
        self.layoutServices = layoutServices
        self.tableAssignmentService = tableAssignmentService

        self.layoutServices.loadFromDisk()
        self.clusterServices.loadClustersFromDisk()
        self.loadReservationsFromDisk()
        
        let today = Calendar.current.startOfDay(for: Date())
        self.store.cachePreloadedFrom = today
        self.preloadActiveReservationCache(around: today, forDaysBefore: 5, afterDays: 5)
    }
    
    // MARK: - Placeholder Methods for CRUD Operations

    
    /// Adds a new reservation.
    /// Assumes the reservation's `tables` have already been assigned
    /// (manually or automatically). If not, it will be unassigned.
    /// This method simply appends it and marks its tables as occupied.
    func addReservation(_ reservation: Reservation) {
           DispatchQueue.main.async {
               self.store.reservations.append(reservation)
               reservation.tables.forEach { self.layoutServices.markTable($0, occupied: true) }
               self.invalidateClusterCache(for: reservation)
               self.saveReservationsToDisk()
               print("Added reservation \(reservation.id).")
           }
       }
    
    /// Updates an existing reservation, refreshes the cache, and reassigns tables if needed.
       func updateReservation(_ updatedReservation: Reservation, at index: Int? = nil) {
           removeReservationFromActiveCache(updatedReservation)
           invalidateActiveReservationCache(for: updatedReservation)

           DispatchQueue.main.async {
               let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == updatedReservation.id })

               guard let reservationIndex else {
                   print("Error: Reservation with ID \(updatedReservation.id) not found.")
                   return
               }

               let oldReservation = self.store.reservations[reservationIndex]
               oldReservation.tables.forEach { self.layoutServices.unmarkTable($0) }

               self.store.reservations[reservationIndex] = updatedReservation
               updatedReservation.tables.forEach { self.layoutServices.markTable($0, occupied: true) }
               self.invalidateClusterCache(for: updatedReservation)
               self.store.reservations = self.store.reservations

               
               
               print("Updated reservation \(updatedReservation.id).")
           }
           
           store.finalizeReservation(updatedReservation)
           saveReservationsToDisk()
       }
    
    /// Deletes reservations and invalidates the associated cluster cache.
    func deleteReservations(at offsets: IndexSet) {
        DispatchQueue.main.async {
            offsets.forEach { index in
                let reservation = self.store.reservations[index]

                // 1) Remove from activeReservationCache
                self.removeReservationFromActiveCache(reservation)
                self.invalidateActiveReservationCache(for: reservation)

                // 2) Unlock the tables, invalidate cluster cache, etc.
                reservation.tables.forEach { self.layoutServices.unmarkTable($0) }
                self.invalidateClusterCache(for: reservation)
            }

            // 3) Remove from the reservations array
            self.store.reservations.remove(atOffsets: offsets)

            // 4) Save changes to disk
            self.saveReservationsToDisk()
        }
    }
    
    
    func removeReservationFromActiveCache(_ reservation: Reservation) {
        let start = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.startTime
        )
        let end   = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.endTime
        )

        var current = start
        while current < end {
            for table in reservation.tables {
                let cacheKey = ActiveReservationCacheKey(
                    tableID: table.id,
                    date: Calendar.current.startOfDay(for: current),
                    time: current
                )
                store.activeReservationCache.removeValue(forKey: cacheKey)
            }
            current.addTimeInterval(60) // next minute
        }
    }
    
    func clearAllData() {
        store.reservations.removeAll() // Clear in-memory reservations
        
        saveReservationsToDisk(includeMock: true) // Overwrite stored data
        flushAllCaches() // Clear any cached layouts or data
        print("ReservationService: All data has been cleared.")
    }
    
    /// Fetches reservations for a specific date.
    /// - Parameter date: The date for which to fetch reservations.
    /// - Returns: A list of reservations for the given date.
    func fetchReservations(on date: Date) -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date) // Use centralized helper
        return store.reservations.filter { $0.dateString == targetDateString }
    }
    
    /// Retrieves reservations for a specific category on a given date.
    func fetchReservations(on date: Date, for category: Reservation.ReservationCategory) -> [Reservation] {
        fetchReservations(on: date).filter { $0.category == category }
    }
    
    // MARK: - Cluster Cache Invalidation

       /// Invalidates the cluster cache for the given reservation.
       private func invalidateClusterCache(for reservation: Reservation) {
           guard let reservationDate = DateHelper.parseDate(reservation.dateString) else {
               print("Failed to parse dateString \(reservation.dateString). Cache invalidation skipped.")
               return
           }
           self.clusterStore.invalidateClusterCache(for: reservationDate, category: reservation.category)
       }
    
    // MARK: - Placeholder Methods for Queries
    
    /// Finds an active reservation for a specific table and time.
    /// - Parameters:
    ///   - table: The table model.
    ///   - date: The date to check for reservations.
    ///   - time: The time to check for reservations.
    /// - Returns: The active reservation if found, else nil.
    func findActiveReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {
        print("Called findActiveReservation!")
        let calendar = Calendar.current

        // Create cache key
        let cacheKey = ActiveReservationCacheKey(tableID: table.id, date: calendar.startOfDay(for: date), time: time)

        // Check the cache in the store
        if let cachedReservation = store.activeReservationCache[cacheKey] {
            print("DEBUG: Cache hit for \(cacheKey). Returning cached reservation.")
            return cachedReservation
        }

        print("DEBUG: Cache miss for \(cacheKey). Searching store reservations.")

        // Ensure cache is preloaded for the requested date
        let requestedDate = calendar.startOfDay(for: date)
        if let cachePreloadedFrom = store.cachePreloadedFrom, requestedDate > cachePreloadedFrom {
            print("DEBUG: Cache is missing data for date \(requestedDate). Preloading one more day.")
            preloadActiveReservationCache(around: cachePreloadedFrom.addingTimeInterval(86400), forDaysBefore: 2, afterDays: 2)
        }

        // Fetch reservations for the specific date
        let reservationsForDate = fetchReservations(on: date)
        print("DEBUG: Fetched \(reservationsForDate.count) reservations for date \(date).")

        // Extract hour and minute from the input time
        
        guard let inputTimeComponents = DateHelper.extractTime(time: time)
            else {
            print("DEBUG: Failed to extract time components")
            return nil
        }
        
        print("DEBUG: Input time components: \(inputTimeComponents)")
              
        for reservation in reservationsForDate {
            print("\nDEBUG: Checking reservation: \(reservation)")

            // Parse startTime and endTime of the reservation
            guard let startTime = DateHelper.parseTime(reservation.startTime),
                  let endTime = DateHelper.parseTime(reservation.endTime),
                  let normalizedStartTime = DateHelper.normalizedTime(time: startTime, date: requestedDate),
                  let normalizedEndTime = DateHelper.normalizedTime(time: endTime, date: requestedDate),
                  let normalizedInputTime = DateHelper.normalizedInputTime(time: inputTimeComponents, date: requestedDate) else {
                print("DEBUG: Failed to parse and normalize startTime, endTime, or input time.")
                continue
            }

            print("DEBUG: Normalized startTime: \(normalizedStartTime), endTime: \(normalizedEndTime)")
            print("DEBUG: Normalized input time: \(normalizedInputTime)")

            // Check if the input time falls within the reservation's time range
            if normalizedInputTime >= normalizedStartTime && normalizedInputTime < normalizedEndTime {
                print("DEBUG: Time matches the reservation's time interval.")

                // Check if the table is assigned to this reservation
                if reservation.tables.contains(where: { $0.id == table.id }) {
                    print("DEBUG: Table \(table.id) is assigned to this reservation.")
                    print("DEBUG: Found matching reservation: \(reservation)")

                    // Cache the result in the store's cache
                    store.activeReservationCache[cacheKey] = reservation
                    return reservation
                } else {
                    print("DEBUG: Table \(table.id) is NOT assigned to this reservation.")
                }
            } else {
                print("DEBUG: Time \(normalizedInputTime) is not within the range \(normalizedStartTime) to \(normalizedEndTime).")
            }
        }

        print("DEBUG: No matching reservation found.")
        return nil
    }
    
    /// Retrieves reservations by category.
    /// - Parameter category: The reservation category.
    /// - Returns: A list of reservations matching the category.
    func getReservations(by category: Reservation.ReservationCategory) -> [Reservation] {
        // Retrieve all reservations from the ReservationStore
        let allReservations = store.getReservations()
        
        // Filter reservations matching the specified category
        let filteredReservations = allReservations.filter { $0.category == category }
        
        // Return the filtered list
        return filteredReservations
    }
    
    // MARK: - Placeholder Methods for Persistence
    
    /// Loads reservations from persistent storage.
    func loadReservationsFromDisk() {
        let fileURL = getReservationsFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No reservation file found at: \(fileURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Ensure ISO 8601 consistency
            
            let decodedReservations = try decoder.decode([Reservation].self, from: data)
            store.setReservations(decodedReservations) // Update store
            print("Reservations loaded successfully.")
        } catch {
            print("Error loading reservations from disk: \(error)")
        }
    }

    func saveReservationsToDisk(includeMock: Bool = false) {
        let fileURL = getReservationsFileURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Ensure ISO 8601 consistency
        
        do {
            let filteredReservations = includeMock
                ? store.reservations // Include mocks if specified
                : store.reservations.filter { !$0.isMock }
            
            let data = try encoder.encode(filteredReservations)
            try data.write(to: fileURL, options: .atomic)
            print("Reservations saved successfully.")
        } catch {
            print("Error saving reservations to disk: \(error)")
        }
    }
    
    // MARK: - Helper Methods (Optional)
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(store.reservationsFileName)
    }
}

// MARK: - Mock Data
extension ReservationService {
    /// Loads two sample reservations for demonstration purposes.
    private func mockData() {
        layoutServices.setTables(tableStore.baseTables)
        print("Debug: Tables populated in mockData: \(layoutServices.tables.map { $0.name })")
        
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
            dateString: DateHelper.formatFullDate(Date()), // Use today
            category: .lunch,
            startTime: "12:00",
            endTime: "13:45",
            acceptance: .confirmed,
            status: .pending,
            reservationType: .inAdvance,
            group: false,
            notes: "Birthday",
            isMock: true
        )
        
        let mockReservation2 = Reservation(
            name: "Bob",
            phone: "+33 98765432101",
            numberOfPersons: 4,
            dateString: DateHelper.formatFullDate(Date()), // Use today
            category: .dinner,
            startTime: "19:30",
            endTime: "21:45",
            acceptance: .confirmed,
            status: .pending,
            reservationType: .inAdvance,
            group: false,
            notes: "Allergic to peanuts",
            isMock: true
        )
        
        addReservation(mockReservation1)
        addReservation(mockReservation2)
        
        saveReservationsToDisk() // Save after mocking
    }
}

extension ReservationService {
    // MARK: - Test Data
    
    func generateReservations(
        daysToSimulate: Int,
        force: Bool = false,
        startFromLastSaved: Bool = true
    ) async {
        // 1. Determine start date
        var startDate = Calendar.current.startOfDay(for: Date())

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                let lhsDate = DateHelper.combineDateAndTimeStrings(
                    dateString: lhs.dateString,
                    timeString: lhs.startTime
                )
                let rhsDate = DateHelper.combineDateAndTimeStrings(
                    dateString: rhs.dateString,
                    timeString: rhs.startTime
                )
                return lhsDate < rhsDate
            }) {
                let lastReservationDate = DateHelper.combineDateAndTimeStrings(
                    dateString: maxReservation.dateString,
                    timeString: maxReservation.startTime
                )
                if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastReservationDate) {
                    startDate = nextDay
                }
            }
        }

        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
            print("Required resources are missing. Reservation generation aborted.")
            return
        }

        print("Generating reservations for \(daysToSimulate) days with realistic variance (closed on Mondays).")

        // 3. Perform parallel reservation generation
        await withTaskGroup(of: Void.self) { group in
            for dayOffset in 0..<daysToSimulate {
                group.addTask {
                    await self.generateReservationsForDay(
                        dayOffset: dayOffset,
                        startDate: startDate,
                        names: names,
                        phoneNumbers: phoneNumbers,
                        notes: notes
                    )
                }
            }
        }

        // 4. Save data to disk after all tasks complete
        DispatchQueue.main.async {
            self.layoutServices.saveToDisk()
            print("Finished generating reservations.")
        }
    }

    private func generateReservationsForDay(
        dayOffset: Int,
        startDate: Date,
        names: [String],
        phoneNumbers: [String],
        notes: [String]
    ) async {
        let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)!
        let dayOfWeek = Calendar.current.component(.weekday, from: reservationDate)

        // Skip Mondays
        if dayOfWeek == 2 {
            print("Skipping Monday: \(reservationDate)")
            return
        }

        let maxDailyReservations = Int.random(in: 10...30)
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 15)))
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 23)))

        while totalGeneratedReservations < maxDailyReservations && !availableTimeSlots.isEmpty {
            guard let startTime = availableTimeSlots.min() else { break }
            availableTimeSlots.remove(startTime)

            let numberOfPersons = self.generateWeightedGroupSize()
            let durationMinutes: Int = {
                if numberOfPersons <= 2 { return Int.random(in: 90...105) }
                if numberOfPersons >= 10 { return Int.random(in: 120...150) }
                return 105
            }()

            let endTime = self.roundToNearestFiveMinutes(
                Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!
            )

            if let nextSlot = availableTimeSlots.min(), nextSlot < endTime.addingTimeInterval(600) {
                availableTimeSlots.remove(nextSlot)
            }

            let category: Reservation.ReservationCategory = Calendar.current.component(.hour, from: startTime) < 15 ? .lunch : .dinner
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

            let reservation = Reservation(
                id: UUID(),
                name: names.randomElement()!,
                phone: phoneNumbers.randomElement()!,
                numberOfPersons: numberOfPersons,
                dateString: dateString,
                category: category,
                startTime: startTimeString,
                endTime: DateHelper.timeFormatter.string(from: endTime),
                acceptance: .confirmed,
                status: .pending,
                reservationType: .inAdvance,
                group: Bool.random(),
                notes: notes.randomElement(),
                tables: [],
                creationDate: Date(),
                isMock: true
            )

            
            // Offload table assignment and reservation updates to the background thread


                await MainActor.run {
                    if let assignedTables = self.layoutServices.assignTables(for: reservation, selectedTableID: nil) {
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        
                    let key = self.layoutServices.keyFor(date: reservationDate, category: category)
                    
                    if self.layoutServices.cachedLayouts[key] == nil {
                        self.layoutServices.cachedLayouts[key] = self.tableStore.baseTables
                    }
                        let reservationStart = DateHelper.combineDateAndTimeStrings(
                            dateString: reservation.dateString,
                            timeString: reservation.startTime
                        )
                        let reservationEnd = DateHelper.combineDateAndTimeStrings(
                            dateString: reservation.dateString,
                            timeString: reservation.endTime
                        )
                        
                        assignedTables.forEach { self.layoutServices.unlockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                        self.store.finalizeReservation(updatedReservation)

                        if !self.store.reservations.contains(where: { $0.id == updatedReservation.id }) {
                            self.store.reservations.append(updatedReservation)
                            print("Generated reservation: \(updatedReservation)")
                        }
                }
                    
                
            }
            
            totalGeneratedReservations += 1

        }
    }

    private func generateTimeSlots(for date: Date, range: (Int, Int)) -> [Date] {
        var slots: [Date] = []
        for hour in range.0..<range.1 {
            for minute in stride(from: 0, to: 60, by: 5) { // Step of 5 minutes
                if let slot = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    slots.append(slot)
                }
            }
        }
        return slots
    }
    
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }

    private func generateWeightedGroupSize() -> Int {
        let random = Double.random(in: 0...1)
        switch random {
        case 0..<0.5: return Int.random(in: 2...3) // 70% chance for groups of 2–5
        case 0.5..<0.7: return Int.random(in: 4...5)
        case 0.7..<0.8: return Int.random(in: 6...7) // 20% chance for groups of 6–8
        case 0.8..<0.95: return Int.random(in: 8...9)
        case 0.95..<0.99: return Int.random(in: 9...12)
        default: return Int.random(in: 13...14) //
        }
    }
    
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(folder)/\(fileName)" : fileName
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "txt") else {
            print("Failed to load \(fileName) from folder \(String(describing: folder)).")
            return []
        }
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            print("Loaded \(lines.count) lines from \(fileName) (folder: \(String(describing: folder))).")
            return lines
        } catch {
            print("Error reading \(fileName): \(error)")
            return []
        }
    }
    
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    Task {
                        let randomTable = self.layoutServices.tables.randomElement()!
                        let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                        let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                        
                        let result = self.layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        print("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(result)")
                    }
                }
            } catch {
                print("Task.sleep encountered an error: \(error)")
            }
        }
    }
    
    func invalidateActiveReservationCache(for reservation: Reservation) {
        // Reconstruct the full date range for this reservation
        let start = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.startTime
        )
        let end   = DateHelper.combineDateAndTimeStrings(
            dateString: reservation.dateString,
            timeString: reservation.endTime
        )
        
        // Bail out if times are invalid or reversed
        guard start < end else {
            print("Cannot invalidate active cache: start >= end for reservation \(reservation.id)")
            return
        }

        var current = start
        while current < end {
            for table in reservation.tables {
                // Each minute + each table -> remove from cache
                let cacheKey = ActiveReservationCacheKey(
                    tableID: table.id,
                    date: Calendar.current.startOfDay(for: current),
                    time: current
                )
                store.activeReservationCache.removeValue(forKey: cacheKey)
            }
            current.addTimeInterval(60) // Move to next minute
        }

        print("Invalidated active reservation cache for reservation \(reservation.id).")
    }
    
    func preloadActiveReservationCache(around date: Date, forDaysBefore beforeDays: Int, afterDays: Int) {
        let calendar = Calendar.current

        // Calculate start and end dates based on the provided date
        let startDate = calendar.date(byAdding: .day, value: -beforeDays, to: date) ?? date
        let endDate = calendar.date(byAdding: .day, value: afterDays, to: date) ?? date

        print("DEBUG: Preloading active reservation cache from \(startDate) to \(endDate)")

        // Iterate through the date range
        for preloadDate in stride(from: startDate, through: endDate, by: 86400) { // 86400 seconds in a day
            
            // Check if any keys for the date already exist in the cache
            let existingKeys = store.activeReservationCache.keys.contains { $0.date == preloadDate }
            guard !existingKeys else {
                print("DEBUG: Cache already contains keys for date: \(preloadDate). Skipping.")
                continue
            }
            
            let reservationsByDate = Dictionary(grouping: store.reservations) { DateHelper.parseDate($0.dateString) }
            
            guard let dateReservations = reservationsByDate[preloadDate] else {
                print("DEBUG: No reservations found for date: \(preloadDate).")
                continue
            }
            
            for reservation in dateReservations {
                for table in reservation.tables {
                    guard let startTime = DateHelper.combineDateAndTime(date: preloadDate, timeString: reservation.startTime),
                          let endTime = DateHelper.combineDateAndTime(date: preloadDate, timeString: reservation.endTime) else {
                        print("DEBUG: Failed to combine date and time for reservation \(reservation).")
                        continue
                    }
                    
                    for currentTime in stride(from: startTime, to: endTime, by: 60) { // Increment by 1 minute
                        let cacheKey = ActiveReservationCacheKey(tableID: table.id, date: preloadDate, time: currentTime)
                        store.activeReservationCache[cacheKey] = reservation
                    }
                }
            }
        }

        store.cachePreloadedFrom = max(store.cachePreloadedFrom ?? startDate, endDate)
        print("DEBUG: Active reservation cache preloaded until \(store.cachePreloadedFrom!).")
    }
    
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = DateHelper.parseDate(reservation.dateString),
              let combinedDateTime = DateHelper.combineDateAndTime(date: reservationDate, timeString: reservation.startTime) else {
            print("Invalid reservation date or time for updating adjacency counts.")
            return
        }

        // Get active tables for the reservation's layout
        let activeTables = layoutServices.getTables(for: reservationDate, category: reservation.category)

        // Iterate over all tables in the reservation
        for table in reservation.tables {
            // Calculate adjacent tables with shared reservations
            let sharedTables = layoutServices.isAdjacentWithSameReservation(for: table, combinedDateTime: combinedDateTime, activeTables: activeTables)

            // Update `activeReservationAdjacentCount` for this table
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id }) {
                layoutServices.tables[index].activeReservationAdjacentCount = sharedTables.count
            }

            // Update in the cached layout
            let key = layoutServices.keyFor(date: reservationDate, category: reservation.category)
            if let cachedIndex = layoutServices.cachedLayouts[key]?.firstIndex(where: { $0.id == table.id }) {
                layoutServices.cachedLayouts[key]?[cachedIndex].activeReservationAdjacentCount = sharedTables.count
            }
        }

        // Save changes to disk
        layoutServices.saveToDisk()
        print("Updated activeReservationAdjacentCount for tables in reservation \(reservation.id).")
    }
    
}

extension ReservationService {
    /// Clears all caches in the store and resets layouts and clusters.
    func flushAllCaches() {
        DispatchQueue.main.async {
            // Clear cached layouts
            self.layoutServices.cachedLayouts.removeAll()
            self.layoutServices.saveToDisk() // Persist changes

            // Clear cluster cache
            self.clusterStore.clusterCache.removeAll()
            self.clusterServices.saveClustersToDisk() // Persist changes

            // Clear active reservation cache
            self.store.activeReservationCache.removeAll()

            print("All caches flushed successfully.")
        }
    }
}

extension Date {
    /// Returns the start of the next minute for the current date.
    func startOfNextMinute() -> Date {
        let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: self)!
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextMinute))!
    }
}
