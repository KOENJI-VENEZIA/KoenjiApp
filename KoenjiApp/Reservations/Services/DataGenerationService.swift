import Foundation
import SwiftUI

/// Service for generating mock and test data
class DataGenerationService: ObservableObject {
    private let store: ReservationStore
    private let layoutServices: LayoutServices
    private let tableStore: TableStore
    private let resCache: CurrentReservationsCache
    private let layoutCache: LayoutCache
    
    init(store: ReservationStore, layoutServices: LayoutServices, tableStore: TableStore, resCache: CurrentReservationsCache, layoutCache: LayoutCache) {
        self.store = store
        self.layoutServices = layoutServices
        self.tableStore = tableStore
        self.resCache = resCache
        self.layoutCache = layoutCache
    }
    
    /// Creates sample mock reservations for demonstration
    @MainActor
    func createMockData() {
        layoutServices.setTables(tableStore.baseTables)
        
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
            dateString: DateHelper.formatFullDate(Date()),
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
            dateString: DateHelper.formatFullDate(Date()),
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
        
        // Add the reservations to SQLite
        SQLiteManager.shared.insertReservation(mockReservation1)
        SQLiteManager.shared.insertReservation(mockReservation2)
        
        // Update memory stores
        DispatchQueue.main.async {
            self.resCache.addOrUpdateReservation(mockReservation1)
            self.resCache.addOrUpdateReservation(mockReservation2)
            self.store.reservations.append(contentsOf: [mockReservation1, mockReservation2])
        }
    }
    
    /// Generates realistic reservation data for a specified number of days
    @MainActor
    func generateReservations(daysToSimulate: Int, force: Bool = false, startFromLastSaved: Bool = true) async {
        // 1. Determine start date
        var startDate = Calendar.current.startOfDay(for: Date())

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                guard let lhsDate = lhs.startTimeDate, let rhsDate = rhs.startTimeDate else {
                    return false
                }
                return lhsDate < rhsDate
            }) {
                if let lastReservationDate = maxReservation.startTimeDate,
                   let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastReservationDate) {
                    startDate = nextDay
                }
            }
        }

        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
            AppLog.warning("Required resources are missing. Reservation generation aborted.")
            return
        }

        AppLog.info("Generating reservations for \(daysToSimulate) days with realistic variance (closed on Mondays).")

        // 3. Perform parallel reservation generation
        for dayOffset in 0..<daysToSimulate {
            await self.generateReservationsForDay(
                dayOffset: dayOffset,
                startDate: startDate,
                names: names,
                phoneNumbers: phoneNumbers,
                notes: notes
            )
        }

        // 4. Save data to disk after all tasks complete
        self.resCache.preloadDates(around: startDate, range: daysToSimulate, reservations: store.reservations)
        self.layoutServices.saveToDisk()
        AppLog.info("Finished generating reservations.")
    }
    
    /// Generates reservations for a specific day
    @MainActor
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
            AppLog.info("Skipping Monday: \(reservationDate)")
            return
        }

        let maxDailyReservations = Int.random(in: 10...30)
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 14)))
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 22)))

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
                isMock: false
            )

            await MainActor.run {
                let assignmentResult = self.layoutServices.assignTables(for: reservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    var updatedReservation = reservation
                    updatedReservation.tables = assignedTables
                    
                    let key = self.layoutServices.keyFor(date: reservationDate, category: category)
                    
                    if self.layoutCache.cachedLayouts[key] == nil {
                        self.layoutCache.cachedLayouts[key] = self.tableStore.baseTables
                    }
                    
                    guard let reservationStart = reservation.startTimeDate,
                          let reservationEnd = reservation.endTimeDate else { break }
                    
                    assignedTables.forEach { self.layoutServices.unlockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                    self.store.finalizeReservation(updatedReservation)

                    if !self.store.reservations.contains(where: { $0.id == updatedReservation.id }) {
                        self.resCache.addOrUpdateReservation(updatedReservation)
                        self.store.reservations.append(updatedReservation)
                        
                        // Update in SQLite
                        SQLiteManager.shared.insertReservation(updatedReservation)
                    }
                case .failure(let error):
                    AppLog.error("Failed to assign tables: \(error)")
                }
            }
            
            totalGeneratedReservations += 1
        }
    }
    
    /// Helper methods
    
    /// Generates time slots for a specific date and hour range
    private func generateTimeSlots(for date: Date, range: (Int, Int)) -> [Date] {
        var slots: [Date] = []
        for hour in range.0..<range.1 {
            for minute in stride(from: 0, to: 60, by: 5) {
                if let slot = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    slots.append(slot)
                }
            }
        }
        return slots
    }
    
    /// Rounds a date to the nearest 5-minute interval
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }
    
    /// Generates a realistic party size with weighted distribution
    private func generateWeightedGroupSize() -> Int {
        let random = Double.random(in: 0...1)
        switch random {
        case 0..<0.5: return Int.random(in: 2...3) // 50% chance for groups of 2-3
        case 0.5..<0.7: return Int.random(in: 4...5) // 20% chance for groups of 4-5
        case 0.7..<0.8: return Int.random(in: 6...7) // 10% chance for groups of 6-7
        case 0.8..<0.95: return Int.random(in: 8...9) // 15% chance for groups of 8-9
        case 0.95..<0.99: return Int.random(in: 9...12) // 4% chance for groups of 9-12
        default: return Int.random(in: 13...14) // 1% chance for groups of 13-14
        }
    }
    
    /// Loads strings from a text file in the app bundle
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(String(describing: folder))/\(fileName)" : fileName
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "txt") else {
            Task { @MainActor in
                AppLog.warning("Failed to load \(fileName) from folder \(String(describing: folder)).")
            }
            return []
        }
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            return lines
        } catch {
            Task { @MainActor in
                AppLog.error("Error reading \(fileName): \(error)")
            }
            return []
        }
    }
    
    /// Simulates user actions for testing purposes
    @MainActor
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000))
                    
                    let randomTable = self.layoutServices.tables.randomElement()!
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
                    let layoutServices = self.layoutServices
                    Task {
                        let result = layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        AppLog.debug("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(String(describing: result))")
                    }
                }
            } catch {
                AppLog.error("Task.sleep encountered an error: \(error)")
            }
        }
    }
} 