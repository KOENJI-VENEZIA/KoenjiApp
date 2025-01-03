//
//  ReservationStore.swift
//  KoenjiApp
//

import Foundation
import SwiftUI

class ReservationStore: ObservableObject {
    
    // MARK: - Properties
    
    // Lazy Initialization
    lazy var layoutManager: TableLayoutManager = TableLayoutManager(reservationStore: self)
    
    // Constants
    let reservationsFileName = "reservations.json"
    let baseTables = [
        TableModel(id: 1, name: "T1", maxCapacity: 2, row: 1, column: 14),
        TableModel(id: 2, name: "T2", maxCapacity: 2, row: 1, column: 10),
        TableModel(id: 3, name: "T3", maxCapacity: 2, row: 1, column: 6),
        TableModel(id: 4, name: "T4", maxCapacity: 2, row: 1, column: 1),
        TableModel(id: 5, name: "T5", maxCapacity: 2, row: 8, column: 7),
        TableModel(id: 6, name: "T6", maxCapacity: 2, row: 6, column: 1),
        TableModel(id: 7, name: "T7", maxCapacity: 2, row: 11, column: 1)
    ]
    
    // Layout Dimensions
    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var tables: [TableModel] = [] {
        didSet {
            objectWillChange.send() // Notify SwiftUI about table updates
        }
    }
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    
    // Private Variables
    var grid: [[Int?]] = []
    
    // MARK: - Initializers
    
    init() {
        layoutManager.loadFromDisk()        // Load cached layouts
        loadReservationsFromDisk()         // Load reservation data
        
        if reservations.isEmpty {
            print("No saved reservations found. Loading mock data.")
            mockData()                      // Load mock data if no reservations are found
        }
        
        layoutManager.markTablesInGrid()    // Initialize the grid with table positions
    }
}

extension ReservationStore {
    // MARK: - CRUD Operations
    /// Handles adding, updating, and deleting reservations.
    
    func addReservation(
        name: String,
        phone: String,
        numberOfPersons: Int,
        date: String,
        category: Reservation.ReservationCategory,
        startTime: String,
        endTime: String,
        notes: String? = nil,
        forcedTable: TableModel? = nil
    ) {
        let newReservation = Reservation(
            id: UUID(),
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: date,
            category: category,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            tables: [],
            creationDate: Date()
        )
        
        reservations.append(newReservation)
        
        guard let addedReservation = reservations.last else {
            print("Debug: Failed to add reservation.")
            return
        }
        
        let startingTable = forcedTable ?? tables.first(where: {
            !isTableOccupied($0, date: addedReservation.date ?? Date(), startTimeString: startTime, endTimeString: endTime)
        }) ?? tables.first!
        
        print("Debug: Assigning tables for reservation \(addedReservation.id). Starting from table: \(startingTable.name)")
        
        assignTables(
            for: addedReservation.id,
            startingFrom: startingTable,
            numberOfPersons: numberOfPersons,
            dateString: date,
            startTimeString: startTime,
            endTimeString: endTime
        )
        
        saveReservationsToDisk()
    }
    
    func updateReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            let oldTables = reservations[index].tables
            oldTables.forEach { unmarkTable($0) }
            
            reservations[index] = reservation
            reservation.tables.forEach { markTable($0, occupied: true) }
            saveReservationsToDisk()
        }
    }
    
    func deleteReservations(at offsets: IndexSet) {
        offsets.forEach { index in
            let reservation = reservations[index]
            reservation.tables.forEach { unmarkTable($0) }
        }
        reservations.remove(atOffsets: offsets)
        saveReservationsToDisk()
    }
}

extension ReservationStore {
    // MARK: - Mock Data
    private func mockData() {
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
            dateString: "28/12/2024",
            category: .lunch,
            startTime: "12:00",
            endTime: "13:45",
            notes: "Birthday",
            isMock: true
        )
        let mockReservation2 = Reservation(
            name: "Bob",
            phone: "+33 98765432101",
            numberOfPersons: 4,
            dateString: "28/12/2024",
            category: .dinner,
            startTime: "19:30",
            endTime: "21:45",
            notes: "Allergic to peanuts",
            isMock: true
        )
        
        reservations.append(contentsOf: [mockReservation1, mockReservation2])
        
        if let table1 = tables.first, let table2 = tables.dropFirst().first {
            assignTables(for: mockReservation1.id, startingFrom: table1, numberOfPersons: mockReservation1.numberOfPersons, dateString: mockReservation1.dateString, startTimeString: mockReservation1.startTime, endTimeString: mockReservation1.endTime)
            assignTables(for: mockReservation2.id, startingFrom: table2, numberOfPersons: mockReservation2.numberOfPersons, dateString: mockReservation2.dateString, startTimeString: mockReservation2.startTime, endTimeString: mockReservation2.endTime)
        }
    }
}

extension ReservationStore {
    // MARK: - Queries
    
    func updateCategory(for time: Date) {
        let hour = Calendar.current.component(.hour, from: time)
        
        switch hour {
        case 12...15:
            selectedCategory = .lunch
        case 18...23:
            selectedCategory = .dinner
        default:
            selectedCategory = .noBookingZone
        }
        
        print("Category updated to \(selectedCategory?.rawValue ?? "none") based on time.")
    }
    
    func reservations(on date: Date) -> [Reservation] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        
        let targetDateString = formatter.string(from: date)
        
        return reservations.filter { $0.dateString == targetDateString }
    }
    
    func activeReservation(for table: TableModel, date: Date, time: Date) -> Reservation? {
        let calendar = Calendar.current
        let queryDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        for reservation in reservations {
            guard let reservationDate = TimeHelpers.date(from: reservation.dateString, on: date),
                  calendar.isDate(reservationDate, equalTo: date, toGranularity: .day),
                  reservation.isActive(queryDate: reservationDate, queryTime: time) else {
                continue
            }
            
            if reservation.tables.contains(where: { $0.id == table.id }) {
                print("Debug: Active reservation found: \(reservation.id)")
                return reservation
            }
        }
        return nil
    }
    
    func handleTimeUpdate(_ newTime: Date) {
        currentTime = newTime
        updateCategory(for: newTime)
        print("Time updated to \(newTime), category set to \(selectedCategory?.rawValue ?? "none")")
    }
}

extension ReservationStore {
    // MARK: - Reservation Persistence
    
    func saveReservationsToDisk() {
        let filteredReservations = reservations.filter { !$0.isMock }
        let fileURL = getReservationsFileURL()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(filteredReservations)
            try data.write(to: fileURL, options: .atomic)
            print("Reservations saved successfully: \(filteredReservations)")
        } catch {
            print("Error saving reservations to disk: \(error)")
        }
    }
    
    func loadReservationsFromDisk() {
        let fileURL = getReservationsFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No reservation file found at: \(fileURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            reservations = try decoder.decode([Reservation].self, from: data)
            print("Reservations loaded successfully.")
        } catch {
            print("Error loading reservations from disk: \(error)")
        }
    }
    
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(reservationsFileName)
    }
}

extension ReservationStore {
    // MARK: - Reservation Layout
    
    func assignTables(
        for reservationID: UUID,
        startingFrom forcedTable: TableModel,
        numberOfPersons: Int,
        dateString: String,
        startTimeString: String,
        endTimeString: String
    ) {
        guard let resIndex = reservations.firstIndex(where: { $0.id == reservationID }) else { return }
        
        let reservationDate = TimeHelpers.date(from: dateString, on: Date())!
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        
        if !isTableOccupied(forcedTable, date: reservationDate, startTimeString: startTimeString, endTimeString: endTimeString) {
            assignedTables.append(forcedTable)
            assignedCapacity += forcedTable.maxCapacity
        }
        
        let neededCapacity = numberOfPersons - assignedCapacity
        let availableTables = tables.filter {
            !isTableOccupied($0, date: reservationDate, startTimeString: startTimeString, endTimeString: endTimeString)
        }
        
        for table in availableTables {
            if assignedCapacity >= numberOfPersons { break }
            assignedTables.append(table)
            assignedCapacity += table.maxCapacity
        }
        
        reservations[resIndex].tables = assignedTables
        assignedTables.forEach { markTable($0, occupied: true) }
    }
}

extension ReservationStore {
    // MARK: - Helper Functions
    
    func formattedDate(date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

extension ReservationStore {
    func triggerFlashAnimation(for tableID: Int) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.tableAnimationState[tableID] = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.tableAnimationState[tableID] = false
                }
            }
        }
    }
}
