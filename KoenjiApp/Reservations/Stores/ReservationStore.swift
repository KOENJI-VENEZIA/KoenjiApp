//
//  ReservationStore.swift
//  KoenjiApp
//
//  Updated to manage cached layouts per date and category.
//

import Foundation
import SwiftUI
import OSLog

class ReservationStore: ObservableObject {
    // MARK: - Private Properties
    private let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ReservationStore"
    )
    
    // MARK: - Static Properties
    nonisolated(unsafe) static let shared = ReservationStore()
    
    // MARK: - Constants
    let reservationsFileName = "reservations.json"
    
    // MARK: - Properties
    var lockedTableIDs: Set<Int> = []
    @Published var reservations: [Reservation] = []
    @Published var activeReservations: [Reservation] = []
    var activeReservationCache: [ActiveReservationCacheKey: Reservation] = [:]
    var cachePreloadedFrom: Date?
    var grid: [[Int?]] = []
    
    /// The SQLite store for persisting reservations
    var sqliteStore: (any FirestoreDataStoreProtocol)?
    
    init() {
        // Try to initialize the SQLite store
        do {
            self.sqliteStore = try SQLiteReservationStore()
            Task { @MainActor in
                AppLog.info("SQLite reservation store initialized")
            }
        } catch {
            Task { @MainActor in
                AppLog.error("Failed to initialize SQLite store: \(error)")
            }
        }
    }
}

// MARK: - Getters and Setters
extension ReservationStore {
    func getReservations() -> [Reservation] {
        // Capture the count before using it in the Task to avoid data races
        let count = self.reservations.count
        Task { @MainActor in
            AppLog.debug("Fetching all reservations. Count: \(count)")
        }
        return self.reservations
    }
    
    func setReservations(_ reservations: [Reservation]) {
        let count = reservations.count
        Task { @MainActor in
            AppLog.info("Updating reservations store with \(count) reservations")
        }
        self.reservations = reservations
    }
}

extension ReservationStore {
    // MARK: - Locking Assignment
    func finalizeReservation(_ reservation: Reservation) {
        let id: UUID = reservation.id
        if let index: Array<Reservation>.Index = reservations.firstIndex(where: { $0.id == id }) {
            reservations[index] = reservation
            Task { @MainActor in
                AppLog.info("Updated existing reservation: \(id)")
            }
        } else {
            reservations.append(reservation)
            Task { @MainActor in
                AppLog.info("Added new reservation: \(id)")
            }
        }
    }
}


