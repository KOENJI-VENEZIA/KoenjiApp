//
//  DebugFunc.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//
import SwiftUI
import os

extension DatabaseView {
    
    func generateDebugData(force: Bool = false) {
        AppLog.debug("Generating debug reservations data")
        Task {
            await env.reservationService.generateReservations(daysToSimulate: daysToSimulate)
        }
    }
    
    func saveDebugData() {
        AppLog.info("Debug data saved to disk")
    }
    
    func resetData() {
        AppLog.info("Initiating complete data reset")
        env.store.setReservations([])
        env.reservationService.clearAllData()
        flushCaches()
        env.layoutServices.unlockAllTables()
        AppLog.info("All data has been reset successfully")
    }
    
    func parseReservations() {
        let reservations = env.store.reservations
        AppLog.debug("Parsing reservations: \(reservations.count) found")
    }
    
    func flushCaches() {
        AppLog.debug("Initiating cache flush")
        env.reservationService.flushAllCaches()
        AppLog.info("Cache flush completed")
    }
}
