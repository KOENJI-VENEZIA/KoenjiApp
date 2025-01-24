//
//  ActiveReservationsCache.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 24/1/25.
//
import SwiftUI

class CurrentReservationsCache: ObservableObject {
    private var cache: [Date: [Reservation]] = [:] // Cache keyed by date
    private var lastFetchedCount: Int = 0
    private var lastFetchedTime: Date? = nil

    func getCachedReservations(
        for date: Date, 
        currentTime: Date, 
        reservationsCount: Int
    ) -> [Reservation]? {
        // Check if cache is valid
        if let lastTime = lastFetchedTime,
           Calendar.current.isDate(date, inSameDayAs: lastTime),
           abs(currentTime.timeIntervalSince(lastTime)) < 60,
           reservationsCount == lastFetchedCount {
            return cache[date]
        }
        return nil
    }

    func updateCache(
        for date: Date,
        reservations: [Reservation],
        currentTime: Date,
        reservationsCount: Int
    ) {
        cache[date] = reservations
        lastFetchedTime = currentTime
        lastFetchedCount = reservationsCount
    }
}
