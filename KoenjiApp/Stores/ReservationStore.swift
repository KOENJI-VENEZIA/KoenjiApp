//
//  ReservationStore.swift
//  KoenjiApp
//
//  Updated to manage cached layouts per date and category.
//

import Foundation
import SwiftUI

class ReservationStore: ObservableObject {
    static let shared = ReservationStore(tableAssignmentService: TableAssignmentService())
    
    // MARK: - Properties
    
    let tableAssignmentService: TableAssignmentService
    
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
    
    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    // Published Variables
    @Published var reservations: [Reservation] = []
    // Remove the global 'tables' and use cachedLayouts instead
    // @Published var tables: [TableModel] = [] {
    //     didSet {
    //         print("Tables updated: \(tables.map { $0.name })")
    //         objectWillChange.send() // Notify SwiftUI about table updates
    //     }
    // }
    @Published var tableAnimationState: [Int: Bool] = [:]
    @Published var currentlyDraggedTableID: Int? = nil
    @Published var isSidebarVisible = true
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()
    var lastSavedKey: String? = nil
    var isUpdatingLayout: Bool = false

    struct ActiveReservationCacheKey: Hashable {
        let tableID: Int
        let date: Date
        let time: Date

        func hash(into hasher: inout Hasher) {
            hasher.combine(tableID)
            hasher.combine(date)
            hasher.combine(time)
        }

        static func == (lhs: ActiveReservationCacheKey, rhs: ActiveReservationCacheKey) -> Bool {
            return lhs.tableID == rhs.tableID &&
                   lhs.date == rhs.date &&
                   lhs.time == rhs.time
        }
    }
    
    var activeReservationCache: [ActiveReservationCacheKey: Reservation] = [:]
    
    // Private Variables
    var grid: [[Int?]] = []
    @Published var tables: [TableModel] = []

    
    // MARK: - Initializers
    
    init(tableAssignmentService: TableAssignmentService) {
        self.tableAssignmentService = tableAssignmentService
        // Initialize cachedLayouts with base tables for today and default category
        let today = Calendar.current.startOfDay(for: Date())
        let defaultCategory: Reservation.ReservationCategory = .lunch
        let key = keyFor(date: today, category: defaultCategory)
        if cachedLayouts[key] == nil {
            cachedLayouts[key] = baseTables
            self.tables = baseTables

        }
    }
    
    // MARK: - Layout Management
    
    /// Generates a unique key based on date and category.
    func keyFor(date: Date, category: Reservation.ReservationCategory) -> String {
        let normalizedDate = Calendar.current.startOfDay(for: date) // Normalize date
        let dateString = DateHelper.formatDate(normalizedDate)
        print("Generated layout key: \(dateString)-\(category.rawValue) for date: \(date) and category: \(category.rawValue)")
        return "\(dateString)-\(category.rawValue)"
    }
    
    /// Loads tables for a specific date and category.
    func loadTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        let key = keyFor(date: date, category: category)
        if let tables = cachedLayouts[key] {
            self.tables = tables // Update the state
            print("Loaded tables for key: \(key)")
            loadFromDisk()
            preloadActiveReservationCache(for: date)
            return tables
        } else {
            // If no cached layout exists, initialize with base tables
            cachedLayouts[key] = baseTables
            self.tables = baseTables
            preloadActiveReservationCache(for: date)
            print("Initialized new tables for key: \(key)")
            return baseTables
        }
        
        
    }
    
    /// Saves tables for a specific date and category.
    func saveTables(_ tables: [TableModel], for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        cachedLayouts[key] = tables
        saveToDisk()
        print("Layout saved for key: \(key)")
    }
    
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            print("Layouts saved successfully.")
        } else {
            print("Failed to encode cached layouts.")
        }
    }
    
    func resetTables(for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        
        // Reset the layout for the key
        cachedLayouts[key] = baseTables
        tables = baseTables // Update the published `tables` property to trigger UI updates
        
        // Save the layout to disk
        saveToDisk()
        
        print("Reset layout for key: \(key) to base tables and saved to disk.")
    }
    
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
               setCachedLayouts(decoded)
            print("Cached layouts loaded successfully: \(cachedLayouts.keys)")
        } else {
            print("No cached layouts found.")
        }
    }
}

    // MARK: - Queries
    extension ReservationStore {
        /// Updates the category (lunch, dinner, or noBookingZone) based on time
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
        
        /// Called when time changes (e.g. user picks a new time).
        func handleTimeUpdate(_ newTime: Date) {
            currentTime = newTime
            updateCategory(for: newTime)
            print("Time updated to \(newTime), category set to \(selectedCategory?.rawValue ?? "none")")
        }
    }
    
    // MARK: - Getters and Setters
extension ReservationStore {
    func getReservations() -> [Reservation] {
        return self.reservations
    }

    func getTables() -> [TableModel] {
        return self.tables
    }
    
    func setReservations(_ reservations: [Reservation]) {
            self.reservations = reservations
    }
    
    func setTables(_ newTables: [TableModel]) {
            self.tables = newTables
    }
    
    func setCachedLayouts(_ layouts: [String: [TableModel]]) {
            self.cachedLayouts = layouts
    }
}
    
    // MARK: - Table Assignment
    extension ReservationStore {
    
        /// Decides if manual or auto/contiguous assignment based on `selectedTableID`.
        /// Returns the tables assigned or `nil` if assignment fails.
        func assignTables(
            for reservation: Reservation,
            selectedTableID: Int?
        ) -> [TableModel]? {
            if let tableID = selectedTableID {
                // MANUAL CASE
                // user forcibly picked a specific table => do "manual with contiguous first" approach
                guard let selectedTable = cachedLayouts[keyFor(date: reservation.date!, category: reservation.category)]?.first(where: { $0.id == tableID }) else {
                    return nil // table not found
                }
                return tableAssignmentService.assignTablesManually(for: reservation, tables: cachedLayouts[keyFor(date: reservation.date!, category: reservation.category)] ?? [], reservations: self.reservations, startingFrom: selectedTable)
    
            } else {
                // AUTO CASE
                // user selected "Auto" => prefer contiguous block if you want, or just do auto
                return tableAssignmentService.assignTablesPreferContiguous(for: reservation, reservations: self.reservations, tables: cachedLayouts[keyFor(date: reservation.date!, category: reservation.category)] ?? [])
            }
        }
    }
    
    // MARK: - Misc Helpers
    extension ReservationStore {
        func formattedDate(date: Date, locale: Locale) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateFormat = "EEEE, dd/MM/yyyy"
            return formatter.string(from: date)
        }
        
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

// MARK: - Table Placement Helpers
extension ReservationStore {
    /// Checks if a table can be placed at a new position for a given date and category.
    func canPlaceTable(_ table: TableModel, for date: Date, category: Reservation.ReservationCategory) -> Bool {
        // Ensure the table is within grid bounds
        guard table.row >= 0, table.column >= 0,
              table.row + table.height <= totalRows,
              table.column + table.width <= totalColumns else {
            return false
        }
        
        // Check for overlap with existing tables
        let key = keyFor(date: date, category: category)
        guard let existingTables = cachedLayouts[key] else { return true } // No tables yet
        
        for existingTable in existingTables where existingTable.id != table.id {
            if tablesOverlap(table1: existingTable, table2: table) {
                return false
            }
        }
        
        return true
    }
    
    
    /// Checks if two tables overlap.
    private func tablesOverlap(table1: TableModel, table2: TableModel) -> Bool {
        let table1Rect = CGRect(
            x: table1.column,
            y: table1.row,
            width: table1.width,
            height: table1.height
        )
        let table2Rect = CGRect(
            x: table2.column,
            y: table2.row,
            width: table2.width,
            height: table2.height
        )
        return table1Rect.intersects(table2Rect)
    }
}


extension ReservationStore {
    /// Checks if a layout exists for the given date and category.
    func layoutExists(for date: Date, category: Reservation.ReservationCategory) -> Bool {
        let key = keyFor(date: date, category: category)
        return cachedLayouts[key] != nil
    }

    /// Initializes a new layout if it doesn't already exist.
    func initializeLayoutIfNeeded(for date: Date, category: Reservation.ReservationCategory) {
        let key = keyFor(date: date, category: category)
        if cachedLayouts[key] == nil {
            cachedLayouts[key] = baseTables
            print("Initialized new layout for \(key)")
        } else {
            print("Layout already exists for \(key)")
        }
    }
}
