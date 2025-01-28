//
//  TimeHelpers.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation

struct TimeHelpers {
    static func calculateEndTime(startTime: String, category: Reservation.ReservationCategory) -> String {
        guard let start = DateHelper.parseTime(startTime) else {
            return startTime
        }

        // Define category-specific time constraints
        let lastLunchTime = DateHelper.parseTime("15:00")!
        let lastDinnerTime = DateHelper.parseTime("23:45")!
        let maxEndTime = category == .lunch ? lastLunchTime : lastDinnerTime

        // Adjust end time based on start time
        var end = Calendar.current.date(byAdding: .minute, value: 105, to: start) ?? start

        // Ensure the calculated end time does not exceed the maximum allowed time
        end = min(end, maxEndTime)

        return DateHelper.formatTime(end)
    }

    static func remainingTimeString(endTime: String, currentTime: Date) -> String? {
        guard let end = DateHelper.parseTime(endTime) else { return nil }

        // Merge today's date with the `endTime`'s time-of-day
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: end)
        guard let todayEnd = calendar.date(bySettingHour: components.hour ?? 0,
                                           minute: components.minute ?? 0,
                                           second: 0,
                                           of: currentTime) else {
            return nil
        }

        if todayEnd <= currentTime {
            return nil // Reservation expired
        }

        let diff = calendar.dateComponents([.hour, .minute], from: currentTime, to: todayEnd)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

        if hours > 0 || minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        return nil
    }

    static func availableTimeString(endTime: String, startTime: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let start = formatter.date(from: startTime) else { return nil }
        guard let end = formatter.date(from: endTime) else { return nil }


        let delta = start.distance(to: end)
        let tformatter = DateComponentsFormatter()

        tformatter.unitsStyle = .abbreviated
        tformatter.allowedUnits = [.hour, .minute]

        return "\(tformatter.string(from: delta)!)"
    
    }

    /// Returns `true` if the provided time ranges overlap.
    static func timeRangesOverlap(
        start1: Date,
        end1: Date,
        start2: Date,
        end2: Date
    ) -> Bool {
        return start1 < end2 && start2 < end1
    }

    nonisolated(unsafe) private static var dateCache: [String: Date] = [:]
    
    static func parseFullDate(from dateString: String) -> Date? {
        if let cachedDate = dateCache[dateString] {
            return cachedDate
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current

        if let parsedDate = formatter.date(from: dateString) {
            dateCache[dateString] = parsedDate
            print("Debug: Successfully parsed full date: \(parsedDate) from \(dateString)")
            return parsedDate
        } else {
            print("Debug: Failed to parse full date from \(dateString)")
            return nil
        }
    }

    /// Converts a time string to a `Date` object on a specified date.
    static func date(from timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }
        return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: time),
                                     minute: Calendar.current.component(.minute, from: time),
                                     second: 0,
                                     of: date)
    }


}
