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
    
    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    // Locking mechanism for tables
    var lockedTableIDs: Set<Int> = []

    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var activeReservations: [Reservation] = []


    @Published var isSidebarVisible = true
    @Published var selectedCategory: Reservation.ReservationCategory? = .lunch
    @Published var currentTime: Date = Date()


    
    
    var activeReservationCache: [ActiveReservationCacheKey: Reservation] = [:]
    var cachePreloadedFrom: Date?
    
    // Private Variables
    var grid: [[Int?]] = []
    
    // MARK: - Initializers
    init(tableAssignmentService: TableAssignmentService) {
            self.tableAssignmentService = tableAssignmentService
            // Initialize cachedLayouts with base tables for today and default category

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
    
    func setReservations(_ reservations: [Reservation]) {
            self.reservations = reservations
    }
    
   

}

    // MARK: - Table Assignment
    extension ReservationStore {
    
   
    }

// MARK: - Table Placement Helpers
extension LayoutServices {
    /// Checks if a table can be placed at a new position for a given date and category.
    func canPlaceTable(_ table: TableModel, for date: Date, category: Reservation.ReservationCategory, activeTables: [TableModel]) -> Bool {
        print("Checking placement for table: \(table.name) at row: \(table.row), column: \(table.column), width: \(table.width), height: \(table.height)")
        
        // Ensure the table is within grid bounds
        guard table.row >= 0, table.column >= 0,
              table.row + table.height <= tableStore.totalRows,
              table.column + table.width <= tableStore.totalColumns else {
            print("Table \(table.name) is out of bounds.")
            return false
        }
                
        // Check for overlap with existing tables
        for existingTable in activeTables where existingTable.id != table.id {
            print("Comparing with existing table: \(existingTable.name) at row: \(existingTable.row), column: \(existingTable.column), width: \(existingTable.width), height: \(existingTable.height)")
            if tablesIntersect(existingTable, table) {
                print("Table \(table.name) intersects with \(existingTable.name). Cannot place.")
                return false
            }
        }
        
        print("Table \(table.name) can be placed.")
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
    
}

extension ReservationStore {
    // MARK: - Locking Assignment

    

    
    
    func finalizeReservation(_ reservation: Reservation) {
        // Mark tables as reserved in persistent storage, if needed
        // Unlock tables after finalization
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index] = reservation // Update the reservation
        } else {
            // If the reservation is new, append it
            reservations.append(reservation)
        }
        
    }
    
   
  
}


