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
}

// MARK: - Getters and Setters
extension ReservationStore {
    func getReservations() -> [Reservation] {
        logger.debug("Fetching all reservations. Count: \(self.reservations.count)")
        return self.reservations
    }
    
    func setReservations(_ reservations: [Reservation]) {
        logger.info("Updating reservations store with \(reservations.count) reservations")
        self.reservations = reservations
    }
}

extension ReservationStore {
    // MARK: - Locking Assignment
    func finalizeReservation(_ reservation: Reservation) {
        if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservations[index] = reservation
            logger.info("Updated existing reservation: \(reservation.id)")
        } else {
            reservations.append(reservation)
            logger.info("Added new reservation: \(reservation.id)")
        }
    }
}


