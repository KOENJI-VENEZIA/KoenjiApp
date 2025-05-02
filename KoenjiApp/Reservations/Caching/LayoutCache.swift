import Foundation
import SwiftUI
import os

/// LayoutCache: Responsible for caching layout data and synchronizing with Firestore
class LayoutCache: ObservableObject {
    // MARK: - Properties
    
    /// Cache of table layouts indexed by date-category keys
    @Published var cachedLayouts: [String: [TableModel]] = [:]
    
    /// Firestore data store for layouts
    
    // MARK: - Public Methods
    private func updateLayoutInFirebase(_ layout: LayoutData) {
        Task {
            do {
                let layoutStore = FirestoreDataStore<LayoutData>(collectionName: "layouts")
                try await layoutStore.upsert(layout)
                
                await MainActor.run {
                    AppLog.info("Updated layout \(layout.id) in Firebase")
                }
            } catch {
                await MainActor.run {
                    AppLog.error("Failed to update layout in Firebase: \(error.localizedDescription)")
                }
            }
        }
    }
    /// Adds or updates a layout in the cache and optionally in Firestore
    /// - Parameters:
    ///   - date: The date for the layout
    ///   - category: The reservation category
    ///   - tables: The tables in the layout
    ///   - updateFirebase: Whether to update Firestore
    func addOrUpdateLayout(for date: Date, category: Reservation.ReservationCategory, 
                          tables: [TableModel], updateFirebase: Bool = true) {
            let key = keyFor(date: date, category: category)
            
            // Update local cache
            cachedLayouts[key] = tables
            
            Task { @MainActor in
                AppLog.debug("Cache updated for layout: \(key)")
            }
            
            // Update Firebase if requested
            if updateFirebase {
                updateLayoutInFirebase(LayoutData(id: key, tables: tables))
            }
    }
    
    /// Loads layouts from Firestore
    func loadLayouts() async {
        do {
            let layoutStore = FirestoreDataStore<LayoutData>(collectionName: "layouts")
            let layouts = try await layoutStore.getAll()
            
            for layout in layouts {
                cachedLayouts[layout.id] = layout.tables
            }
            
            Task { @MainActor in
                AppLog.info("Loaded \(layouts.count) layouts from Firebase")
            }
        } catch {
            Task { @MainActor in
                AppLog.error("Failed to load layouts: \(error)")
            }
        }
    }
    
    /// Deletes a layout from the cache and optionally from Firestore
    /// - Parameters:
    ///   - date: The date for the layout
    ///   - category: The reservation category
    ///   - updateFirebase: Whether to update Firestore
    func removeLayout(for date: Date, category: Reservation.ReservationCategory, updateFirebase: Bool = true) async {
        let key = keyFor(date: date, category: category)
        
        // Remove from local cache
        cachedLayouts.removeValue(forKey: key)
        
        // Remove from Firebase if requested
        if updateFirebase {
                do {
                    let layoutStore = FirestoreDataStore<LayoutData>(collectionName: "layouts")
                    try await layoutStore.delete(id: key)
                    Task { @MainActor in
                        AppLog.info("Layout \(key) removed from Firebase")
                    }
                } catch {
                    Task { @MainActor in
                        AppLog.error("Firebase layout deletion failed: \(error)")
                    }
                }
            }
    }
    
    /// Clears all layouts from the cache and optionally from Firestore
    /// - Parameter clearFirebase: Whether to clear layouts from Firestore
    func clearAllLayouts(clearFirebase: Bool = false) async {
        cachedLayouts.removeAll()
        
        if clearFirebase {
            do {
                let layoutStore = FirestoreDataStore<LayoutData>(collectionName: "layouts")
                let count = try await layoutStore.deleteAllDocuments()
                Task { @MainActor in
                    AppLog.info("Cleared \(count) layouts from Firebase")
                }
            } catch {
                Task { @MainActor in
                    AppLog.error("Failed to clear layouts from Firebase: \(error)")
                }
            }
        }
    }
    
    /// Generates a key for the layout based on date and category
    /// - Parameters:
    ///   - date: The date for the layout
    ///   - category: The reservation category
    /// - Returns: A string key in the format "YYYY-MM-DD-category"
    func keyFor(date: Date, category: Reservation.ReservationCategory) -> String {
        let formattedDate = DateHelper.formatDate(date)
        return "\(formattedDate)-\(category.rawValue)"
    }
} 