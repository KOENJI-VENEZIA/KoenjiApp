//
//  ReservationCache.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 24/1/25.
//

import SwiftUI

class ReservationCache {
    private var startDateCache: [UUID: Date] = [:]
    private var endDateCache: [UUID: Date] = [:]

    func startTimeDate(for reservation: Reservation, dayStart: Date) -> Date? {
        if let cachedDate = startDateCache[reservation.id] {
            return cachedDate
        }

        if let date = DateHelper.combineDateAndTime(date: dayStart, timeString: reservation.startTime) {
            startDateCache[reservation.id] = date
            return date
        }

        return nil
    }

    func endTimeDate(for reservation: Reservation, dayStart: Date) -> Date? {
        if let cachedDate = endDateCache[reservation.id] {
            return cachedDate
        }

        if let date = DateHelper.combineDateAndTime(date: dayStart, timeString: reservation.endTime) {
            endDateCache[reservation.id] = date
            return date
        }

        return nil
    }
}
