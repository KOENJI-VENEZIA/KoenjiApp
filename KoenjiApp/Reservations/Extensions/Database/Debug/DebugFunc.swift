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
            await env.dataGenerationService.generateReservations(daysToSimulate: daysToSimulate)
        }
    }
    
    func saveDebugData() {
        AppLog.info("Debug data saved to disk")
    }
    
    func resetData() {
        AppLog.info("Initiating complete data reset")
        env.resCache.clearAllCache()
        env.store.setReservations([])
        env.reservationService.clearAllData()
        flushCaches()
        env.layoutServices.unlockAllTables()
        AppLog.info("All data has been reset successfully")
    }
    
    func parseReservations() {
        let reservations = env.resCache.getAllReservations()
        AppLog.debug("Parsing reservations: \(reservations.count) found")
        
        let dates = Array(env.resCache.cache.keys)
        let dateStrings = dates.map { DateHelper.formatDate($0) }
        AppLog.debug("Cached dates: \(dateStrings.joined(separator: ", "))")
    }
    
    func flushCaches() {
        AppLog.debug("Initiating cache flush")
        env.resCache.clearAllCache()
        updateReservationsFromCache()
        AppLog.info("Cache flush completed")
    }
}
