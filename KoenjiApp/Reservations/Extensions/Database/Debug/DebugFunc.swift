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
        logger.debug("Generating debug reservations data")
        Task {
            await env.reservationService.generateReservations(daysToSimulate: daysToSimulate)
        }
    }
    
    func saveDebugData() {
        logger.info("Debug data saved to disk")
    }
    
    func resetData() {
        logger.notice("Initiating complete data reset")
        env.store.setReservations([])
        env.reservationService.clearAllData()
        flushCaches()
        env.layoutServices.unlockAllTables()
        logger.info("All data has been reset successfully")
    }
    
    func parseReservations() {
        let reservations = env.store.reservations
        logger.debug("Parsing reservations: \(reservations.count) found")
    }
    
    func flushCaches() {
        logger.debug("Initiating cache flush")
        env.reservationService.flushAllCaches()
        logger.info("Cache flush completed")
    }
}
