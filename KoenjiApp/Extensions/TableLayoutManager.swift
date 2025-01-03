//
//  TableLayoutManager.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation
import SwiftUI

/// Manages table layout persistence, resets, and initialization.
class TableLayoutManager {
    
    // MARK: - Dependencies
    private let reservationStore: ReservationStore

    // MARK: - Initialization
    init(reservationStore: ReservationStore) {
        self.reservationStore = reservationStore
    }
    
    // MARK: - Layout Persistence
    func saveLayout(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutKey(for: date, category: category)
        reservationStore.cachedLayouts[key] = reservationStore.tables
        saveToDisk()
        print("Layout saved for key: \(key)")
    }
    
    func loadLayout(for date: Date, category: Reservation.ReservationCategory, reset: Bool = false) {
        let key = layoutKey(for: date, category: category)
        
        if reset {
            reservationStore.tables = reservationStore.baseTables
        } else if let layout = reservationStore.cachedLayouts[key] {
            reservationStore.tables = layout
        } else {
            reservationStore.tables = reservationStore.baseTables
        }
        
        markTablesInGrid()
    }
    
    func resetLayout(for date: Date, category: Reservation.ReservationCategory) {
        reservationStore.tables = loadDefaultLayout(for: date, category: category)

        // Reset grid state
        loadTables()
        
        loadLayout(for: date, category: category, reset: true)
        saveLayout(for: date, category: category)
        print("Layout reset for \(date) - \(category.rawValue)")
    }
    
    // MARK: - Disk Storage
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(reservationStore.cachedLayouts) {
            UserDefaults.standard.set(data, forKey: "cachedLayouts")
            print("Layouts saved successfully.")
        } else {
            print("Failed to encode cached layouts.")
        }
    }
    
    func saveCurrentLayout(for date: Date, category: Reservation.ReservationCategory) {
        saveLayout(for: date, category: category)
        saveToDisk()
        print("saveCurrentLayout: Layout saved for \(category.rawValue) on \(date).")
    }
    
    func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedLayouts"),
           let decoded = try? JSONDecoder().decode([String: [TableModel]].self, from: data) {
            reservationStore.cachedLayouts = decoded
            print("Cached layouts loaded successfully: \(reservationStore.cachedLayouts.keys)")
        } else {
            print("No cached layouts found.")
        }
    }
    
    // MARK: - Helpers
    func layoutKey(for date: Date, category: Reservation.ReservationCategory) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return "\(dateString)-\(category.rawValue)"
    }
    
    func markTablesInGrid() {
        reservationStore.grid = Array(
            repeating: Array(repeating: nil, count: reservationStore.totalColumns),
            count: reservationStore.totalRows
        )
        for table in reservationStore.tables {
            reservationStore.markTable(table, occupied: true)
        }
    }
    
    // MARK: - Initialization and Defaults
    func loadTables(initial: Bool = false) {
        guard initial || reservationStore.tables.isEmpty else { return } // Prevent unnecessary overwrites

        reservationStore.grid = Array(
            repeating: Array(repeating: nil, count: reservationStore.totalColumns),
            count: reservationStore.totalRows
        )
        
        reservationStore.tables = reservationStore.baseTables

        for table in reservationStore.tables {
            reservationStore.markTable(table, occupied: true)
        }

        print("loadTables: Grid initialized with \(reservationStore.grid.count) rows and \(reservationStore.grid[0].count) columns, and tables marked.")
    }
    
    func loadDefaultLayout(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        return reservationStore.baseTables
    }
}
