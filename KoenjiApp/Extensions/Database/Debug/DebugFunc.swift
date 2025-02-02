//
//  DebugFunc.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//
import SwiftUI

extension DatabaseView {
    
    func generateDebugData(force: Bool = false) {
        Task {
            await env.reservationService.generateReservations(daysToSimulate: daysToSimulate)
        }
    }
    
    func saveDebugData() {
        env.reservationService.saveReservationsToDisk(includeMock: true)
        print("Debug data saved to disk.")
    }
    
    func resetData() {
        env.store.setReservations([])
        env.reservationService.clearAllData()
        flushCaches()
        env.layoutServices.unlockAllTables()
        print("All data has been reset.")
    }
    
    func parseReservations() {
        let reservations = env.store.reservations
        print("\(reservations)")
    }
    
    func flushCaches() {
        env.reservationService.flushAllCaches()
        print("Debug: Cache flush triggered.")
    }
    
}
