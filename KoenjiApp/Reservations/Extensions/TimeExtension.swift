//
//  TimeExtension.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation

extension Date {
    /// Checks if the date is the same day as another date.
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: otherDate)
    }

    /// Determines if the date is within a specific time range.
    func isWithinTimeRange(start: Date, end: Date) -> Bool {
        return self >= start && self <= end
    }

    /// Adds a specified number of minutes to the date.
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
}

extension String {
    /// Converts a time string in "HH:mm" format into a `Date` on the specified date.
    func toDate(on date: Date = Date()) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: self) else { return nil }
        let calendar = Calendar.current
        return calendar.date(bySettingHour: calendar.component(.hour, from: time),
                             minute: calendar.component(.minute, from: time),
                             second: 0,
                             of: date)
    }
}

extension Date {
    /// Combines the date from one `Date` with the time from another `Date`.
    func combined(withTimeFrom time: Date, using calendar: Calendar = .current) -> Date? {
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            second: calendar.component(.second, from: time),
            of: self
        )
    }
}
