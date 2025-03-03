//
//  ReservationCache.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 24/1/25.
//

import SwiftUI
import OSLog

class ReservationCache {
    let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationCache")

    private var startDateCache: [UUID: Date] = [:]
    private var endDateCache: [UUID: Date] = [:]

    func startTimeDate(for reservation: Reservation, dayStart: Date) -> Date? {
        if let cachedDate = startDateCache[reservation.id] {
            logger.debug("Using cached start date for reservation: \(reservation.id)")
            return cachedDate
        }

        if let date = DateHelper.combineDateAndTime(date: dayStart, timeString: reservation.startTime) {
            startDateCache[reservation.id] = date
            logger.debug("Cached new start date for reservation: \(reservation.id)")
            return date
        }

        logger.warning("Failed to parse start time for reservation: \(reservation.id)")
        return nil
    }

    func endTimeDate(for reservation: Reservation, dayStart: Date) -> Date? {
        if let cachedDate = endDateCache[reservation.id] {
            logger.debug("Using cached end date for reservation: \(reservation.id)")
            return cachedDate
        }

        if let date = DateHelper.combineDateAndTime(date: dayStart, timeString: reservation.endTime) {
            endDateCache[reservation.id] = date
            logger.debug("Cached new end date for reservation: \(reservation.id)")
            return date
        }

        logger.warning("Failed to parse end time for reservation: \(reservation.id)")
        return nil
    }
}
