//
//  TableStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

// PLACEHOLDER: - TableStore.Swift


import Foundation
import SwiftUI
import OSLog
import FirebaseFirestore

/// The TableStore manages the data layer for individual tables,
/// coordinating between in-memory cache and Firestore persistence.
class TableStore: ObservableObject {
    
    // MARK: - Static Properties
    nonisolated(unsafe) static let shared = TableStore()

    // MARK: - Published Properties
    /// The tables currently loaded in memory
    @Published var tables: [TableModel] = []
    
    /// The base set of tables available in the restaurant
    let baseTables = [
        TableModel(id: 1, name: "T1", maxCapacity: 2, row: 1, column: 14),
        TableModel(id: 2, name: "T2", maxCapacity: 2, row: 1, column: 10),
        TableModel(id: 3, name: "T3", maxCapacity: 2, row: 1, column: 6),
        TableModel(id: 4, name: "T4", maxCapacity: 2, row: 1, column: 1),
        TableModel(id: 5, name: "T5", maxCapacity: 2, row: 8, column: 7),
        TableModel(id: 6, name: "T6", maxCapacity: 2, row: 6, column: 1),
        TableModel(id: 7, name: "T7", maxCapacity: 2, row: 11, column: 1)
    ]
    
    // MARK: - Properties
    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    // MARK: - Private Properties
    private var isInitialized = false
    private var tablesListener: Task<Void, Never>? = nil

    // MARK: - Initialization
    init() {
        let count = baseTables.count
        tables = baseTables
        
        Task { @MainActor in
            AppLog.debug("TableStore initialized with \(count) base tables")
        }
    }
    
    deinit {
        // Cancel the listener when the store is deallocated
        tablesListener?.cancel()
    }
    
    // MARK: - Firebase Synchronization Methods
    
    /// Add or update a table in both local cache and Firestore
    /// - Parameters:
    ///   - table: The table to add or update
    ///   - updateFirebase: Whether to also update the table in Firestore
    func addOrUpdateTable(_ table: TableModel, updateFirebase: Bool = true) {
        let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")

        // Update local cache
        if let index = tables.firstIndex(where: { $0.id == table.id }) {
            // Update table
            tables[index] = table
        } else {
            tables.append(table)
        }
        
        Task { @MainActor in
            AppLog.debug("Table \(table.name) (ID: \(table.id)) updated in cache")
        }
        
        // Update Firestore if requested
        if updateFirebase {
            Task {
                do {
                    try await tableFirestore.upsert(table)
                    
                    await MainActor.run {
                        AppLog.info("Table \(table.name) (ID: \(table.id)) updated in Firestore")
                    }
                } catch {
                    await MainActor.run {
                        AppLog.error("Failed to update table in Firestore: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Remove a table from both local cache and Firestore
    func removeTable(withId tableId: Int, updateFirebase: Bool = true) {
        let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")

        guard let index = tables.firstIndex(where: { $0.id == tableId }) else {
            Task { @MainActor in
                AppLog.warning("Attempted to remove table with ID \(tableId) but it wasn't found")
            }
            return
        }
        
        // Remove from local cache
        tables.remove(at: index)
        
        Task { @MainActor in
            AppLog.debug("Table with ID \(tableId) removed from cache")
        }
        
        // Remove from Firestore if requested
        if updateFirebase {
            Task {
                do {
                    try await tableFirestore.delete(id: "\(tableId)")
                    
                    await MainActor.run {
                        AppLog.info("Table with ID \(tableId) removed from Firestore")
                    }
                } catch {
                    await MainActor.run {
                        AppLog.error("Failed to remove table from Firestore: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Load all tables from Firestore
    /// - Returns: An async task that loads tables from Firestore
    @discardableResult
    func loadTablesFromFirestore() async -> Bool {
        let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")

        do {
            let loadedTables = try await tableFirestore.getAll()
            
                if loadedTables.isEmpty {
                    // If no tables in Firestore, use base tables
                    if tables.isEmpty {
                        tables = baseTables
                    }
                    
                    Task { @MainActor in
                        AppLog.info("No tables found in Firestore, using base tables")
                    }
                } else {
                    // Update tables
                    tables = loadedTables
                    
                    Task { @MainActor in
                        AppLog.info("Loaded \(loadedTables.count) tables from Firestore")
                    }
                }
                
                isInitialized = true
            
            return true
        } catch {
            Task { @MainActor in
                AppLog.error("Failed to load tables from Firestore: \(error.localizedDescription)")
            }
                // If failed to load and tables are empty, use base tables
                if tables.isEmpty {
                    tables = baseTables
                }
                
                isInitialized = true
            
            return false
        }
    }
    
    /// Clear all tables from Firestore
    /// - Returns: The number of tables deleted
    func clearAllTablesFromFirestore() async -> Int {
        let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")

        do {
            let count = try await tableFirestore.deleteAllDocuments()
            
            await MainActor.run {
                AppLog.info("Deleted \(count) tables from Firestore")
            }
            
            return count
        } catch {
            await MainActor.run {
                AppLog.error("Failed to clear tables from Firestore: \(error.localizedDescription)")
            }
            
            return 0
        }
    }
    
    /// Reset to base tables in both local cache and Firestore
    func resetToBaseTables(updateFirestore: Bool = true) async {
        let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")
            tables = baseTables
            
            let count = tables.count
            Task { @MainActor in
                AppLog.info("Reset to \(count) base tables")
            }
        
        if updateFirestore {
            // First clear all tables
            let _ = await clearAllTablesFromFirestore()
            
            // Then add base tables
            for table in baseTables {
                do {
                    try await tableFirestore.upsert(table)
                } catch {
                    await MainActor.run {
                        AppLog.error("Failed to add base table to Firestore: \(error.localizedDescription)")
                    }
                }
            }
            
            await MainActor.run {
                AppLog.info("Reset Firestore tables to base tables")
            }
        }
    }
    
    
    /// Find a table by its ID
    func findTable(withId id: Int) -> TableModel? {
        return tables.first { $0.id == id }
    }
    
    /// Get the next available table ID
    func getNextTableId() -> Int {
        return (tables.map { $0.id }.max() ?? 0) + 1
    }
}

