//
//  ReservationStore.swift
//  KoenjiApp
//
//  An updated version of ReservationStore without forcedTable logic.
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
    
    /// Defines the order of tables for assignment (used in auto-assign).
    
    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var tables: [TableModel] = [] {
        didSet {
            print("Tables updated: \(tables.map { $0.name })")
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
    
    init(
        tableAssignmentService: TableAssignmentService
) {
        self.tableAssignmentService = tableAssignmentService
                 // Load reservation data
        // Ensure tables are populated
        if tables.isEmpty {
            print("No tables loaded. Populating base tables.")
            self.tables = baseTables
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
            guard let selectedTable = tables.first(where: { $0.id == tableID }) else {
                return nil // table not found
            }
            return tableAssignmentService.assignTablesManually(for: reservation, tables: self.tables, reservations: self.reservations, startingFrom: selectedTable)

        } else {
            // AUTO CASE
            // user selected "Auto" => prefer contiguous block if you want, or just do auto
            return tableAssignmentService.assignTablesPreferContiguous(for: reservation, reservations: self.reservations, tables: self.tables)

            // or if you only want the old auto, do:
            // return assignTablesAutomatically(for: reservation)
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


