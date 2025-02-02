//
//  ReservationStore.swift
//  KoenjiApp
//
//  Updated to manage cached layouts per date and category.
//

import Foundation
import SwiftUI

class ReservationStore: ObservableObject {
    nonisolated(unsafe) static let shared = ReservationStore()
       
       // MARK: - Properties
    // Constants
    let reservationsFileName = "reservations.json"
    
    // Locking mechanism for tables
    var lockedTableIDs: Set<Int> = []

    
    // Published Variables
    @Published var reservations: [Reservation] = []
    @Published var activeReservations: [Reservation] = []

    var activeReservationCache: [ActiveReservationCacheKey: Reservation] = [:]
    var cachePreloadedFrom: Date?
    
    // Private Variables
    var grid: [[Int?]] = []
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


