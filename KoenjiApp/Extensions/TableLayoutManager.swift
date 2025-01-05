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
    let store = ReservationStore.shared
    
    @Published var isLayoutReset : Bool = false
    
    // MARK: - Layout Persistence
    func saveLayout(for date: Date, category: Reservation.ReservationCategory) {
        let key = layoutKey(for: date, category: category)
        store.cachedLayouts[key] = store.tables
        saveToDisk()
        print("Layout saved for key: \(key)")
    }
    
    func loadLayout(for date: Date, category: Reservation.ReservationCategory, reset: Bool = false) {
        let key = layoutKey(for: date, category: category)
        
        if reset {
            store.tables = store.baseTables
        } else if let layout = store.cachedLayouts[key] {
            store.tables = layout
        } else {
            store.tables = store.baseTables
        }
        
        markTablesInGrid()
    }
    
    func resetLayout(for date: Date, category: Reservation.ReservationCategory) {
        store.tables = loadDefaultLayout(for: date, category: category)
        isLayoutReset = true
        // Reset grid state
        loadTables()
        
        loadLayout(for: date, category: category, reset: true)
        saveLayout(for: date, category: category)
        print("Layout reset for \(date) - \(category.rawValue)")
    }
    
    // MARK: - Disk Storage
    func saveToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(store.cachedLayouts) {
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
               store.setCachedLayouts(decoded)
            print("Cached layouts loaded successfully: \(store.cachedLayouts.keys)")
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
        store.grid = Array(
            repeating: Array(repeating: nil, count: store.totalColumns),
            count: store.totalRows
        )
        for table in store.tables {
            store.markTable(table, occupied: true)
        }
    }
    
    // MARK: - Initialization and Defaults
    func loadTables(initial: Bool = false) {
        guard initial || store.tables.isEmpty else { return } // Prevent unnecessary overwrites

        store.grid = Array(
            repeating: Array(repeating: nil, count: store.totalColumns),
            count: store.totalRows
        )
        
        store.tables = store.baseTables

        for table in store.tables {
            store.markTable(table, occupied: true)
        }

        print("loadTables: Grid initialized with \(store.grid.count) rows and \(store.grid[0].count) columns, and tables marked.")
    }
    
    func loadDefaultLayout(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
        return store.baseTables
    }
}
