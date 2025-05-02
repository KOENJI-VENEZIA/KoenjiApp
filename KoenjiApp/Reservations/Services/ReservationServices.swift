//
//  ReservationService.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation
import SwiftUI
import OSLog

/// Primary service for managing reservations
/// Acts as a coordinator for more specialized services
class ReservationService: ObservableObject {        
    // Core stores
    let resCache: CurrentReservationsCache
        
    // Layout services
    let clusterServices: ClusterServices
    let layoutServices: LayoutServices
    let tableAssignmentService: TableAssignmentService
    
    // Notifications
    let pushAlerts: PushAlerts
    
    // MARK: - Initialization
    
    /// Initializes a new ReservationService with all required dependencies
    init( 
         resCache: CurrentReservationsCache, 
         clusterServices: ClusterServices, 
         layoutServices: LayoutServices, 
         tableAssignmentService: TableAssignmentService, 
         pushAlerts: PushAlerts, 
         isPreview: Bool = false) {
        
        self.resCache = resCache
        self.clusterServices = clusterServices
        self.layoutServices = layoutServices
        self.tableAssignmentService = tableAssignmentService
        self.pushAlerts = pushAlerts
        
        
        self.clusterServices.loadClustersFromDisk()
        
        // In preview mode, use mock data instead of Firebase
        if isPreview {
            Task { @MainActor in
                AppLog.debug("Preview mode: Using mock data for ReservationService")
            }
        }
        
        // The cache is already initialized and loaded elsewhere (in AppDependencies)
    }
    
    /// Removes Firebase listeners when the service is deallocated
    deinit { }
    
    // MARK: - Reservation Management
    
    /// Adds a new reservation to the system
    func addReservation(_ reservation: Reservation) {
        // Update Database
        SQLiteManager.shared.insertReservation(reservation)

        // Manage in-store memory and update Firebase via the cache
        self.resCache.addOrUpdateReservation(reservation)
        reservation.tables.forEach { self.layoutServices.markTablePosition($0) }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .clusterCacheInvalidation, object: reservation)
            AppLog.debug("Added reservation \(reservation.id) with tables \(reservation.tables)")
        }
    }
    
    /// Adds multiple reservations to the system
    func addReservations(_ reservations: [Reservation]) {
        for reservation in reservations {
            // Update SQLite
            SQLiteManager.shared.insertReservation(reservation)
            
            // Update cache and Firebase
            self.resCache.addOrUpdateReservation(reservation)
            
            // Update table marking if needed
            reservation.tables.forEach { self.layoutServices.markTablePosition($0) }
        }
        
        Task { @MainActor in
            AppLog.info("Added batch of \(reservations.count) reservations")
        }
    }
    
    /// Updates an existing reservation
    func updateReservation(_ oldReservation: Reservation, newReservation: Reservation? = nil, at index: Int? = nil, shouldPersist: Bool = true, completion: @escaping () -> Void) {
        // Capture services and stores in local variables to avoid self in closures
        let layoutServices = self.layoutServices
        let localResCache = self.resCache
        
        // Remove from active cache
        NotificationCenter.default.post(name: .clusterCacheInvalidation, object: oldReservation)
        localResCache.removeReservation(oldReservation)
        
        let updatedReservation = newReservation ?? oldReservation
            
            SQLiteManager.shared.insertReservation(updatedReservation)

            
            // Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables.map { $0.id })
            let newTableIDs = Set(updatedReservation.tables.map { $0.id })
            
            if oldTableIDs != newTableIDs {
                Task { @MainActor in
                    AppLog.debug("Table change detected for reservation \(updatedReservation.id). Updating tables...")
                }
                
                // Unmark only if tables have changed
                for tableID in oldTableIDs.subtracting(newTableIDs) {
                    if let table = oldReservation.tables.first(where: { $0.id == tableID }) {
                        layoutServices.clearTablePosition(table)
                    }
                }
                
                // Mark only new tables that weren't already assigned
                for tableID in newTableIDs.subtracting(oldTableIDs) {
                    if let table = updatedReservation.tables.first(where: { $0.id == tableID }) {
                        layoutServices.markTablePosition(table)
                    }
                }
                
                // Invalidate cluster cache only if tables changed
                NotificationCenter.default.post(name: .clusterCacheInvalidation, object: updatedReservation)
            } else if newTableIDs.isEmpty {
                oldReservation.tables.forEach { layoutServices.clearTablePosition($0) }
            }
            
            // Update the reservation in the store
            localResCache.addOrUpdateReservation(updatedReservation, updateFirebase: shouldPersist)
            
            // Finalize and save
            completion()
    }
    
    /// Handles the confirmation of a reservation
    func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                    updatedReservation.tables = assignedTables
                    updatedReservation.reservationType = .inAdvance
                    updatedReservation.status = .pending
                    self.updateReservation(updatedReservation) {
                        Task { @MainActor in
                            AppLog.info("Updated reservations.")
                        }
                    }
            case .failure(let error):
                handleTableAssignmentError(error)
            }
        }
    }
    
    /// Handles table assignment errors with user feedback
    private func handleTableAssignmentError(_ error: TableAssignmentError) {
        switch error {
        case .noTablesLeft:
            pushAlerts.alertMessage = String(localized: "Non ci sono tavoli disponibili.")
        case .insufficientTables:
            pushAlerts.alertMessage = String(localized: "Non ci sono abbastanza tavoli per la prenotazione.")
        case .tableNotFound:
            pushAlerts.alertMessage = String(localized: "Tavolo selezionato non trovato.")
        case .tableLocked:
            pushAlerts.alertMessage = String(localized: "Il tavolo scelto è occupato o bloccato.")
        case .unknown:
            pushAlerts.alertMessage = String(localized: "Errore sconosciuto.")
        }
        pushAlerts.showAlert = true
    }
    
    // MARK: - Data Querying
    
    /// Fetches reservations for a specific date.
    func fetchReservations(on date: Date) -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date)
        return resCache.getAllReservations().filter { $0.dateString == targetDateString }
    }
    
    /// Retrieves reservations for a specific category on a given date.
    func fetchReservations(on date: Date, for category: Reservation.ReservationCategory) -> [Reservation] {
        fetchReservations(on: date).filter { $0.category == category }
    }
    
    /// Retrieves reservations by category.
    func getReservations(by category: Reservation.ReservationCategory) -> [Reservation] {
        return resCache.getAllReservations().filter { $0.category == category }
    }
    
    // MARK: - Cache and Data Management
    
    /// Clears all data from all sources (cache, SQLite, and Firebase)
    func clearAllData() {
        // Use the centralized method in the cache to clear all data
        resCache.clearAllData { result in
            switch result {
            case .success(let count):
                Task { @MainActor in
                    AppLog.info("Successfully cleared all reservation data (\(count) reservations)")
                }
            case .failure(let error):
                Task { @MainActor in
                    AppLog.error("Error while clearing reservation data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Reservation Management
    
    /// "Deletes" a reservation by marking it with "NA" values
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        var updatedReservation = reservation
        let finalNotes = notesToAdd == "" ? "" : "\(notesToAdd)\n\n"
        updatedReservation.status = .pending
        updatedReservation.notes = "\(finalNotes)[da controllare];"
        return updatedReservation
    }
    
    /// Marks a reservation as deleted
    func deleteReservation(_ reservation: Reservation) {
        var updatedReservation = reservation
        updatedReservation.reservationType = .na
        updatedReservation.status = .deleted
        updatedReservation.acceptance = .na
        updatedReservation.tables = []
        updatedReservation.notes = "[eliminata];"
        
        updateReservation(updatedReservation) {
            Task { @MainActor in
                AppLog.info("Updated reservation")
            }
        }
    }

}

