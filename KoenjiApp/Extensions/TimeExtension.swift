//
//  TimeExtension.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation

extension Date {
    /// Formats a `Date` into a string with the specified format.
    func formattedString(format: String = "HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    /// Calculates the difference in minutes between two dates.
    func minutesDifference(from date: Date) -> Int {
        let diff = Calendar.current.dateComponents([.minute], from: date, to: self)
        return diff.minute ?? 0
    }
    
    /// Adds a specified number of minutes to the current date.
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    
    /// Determines whether a date falls within a specific time range.
    func isWithinTimeRange(start: Date, end: Date) -> Bool {
        return self >= start && self <= end
    }
}

extension String {
    /// Converts a time string in "HH:mm" format into a `Date` object.
    func toDate(on date: Date = Date()) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        
        guard let time = formatter.date(from: self) else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        return calendar.date(bySettingHour: Calendar.current.component(.hour, from: time),
                             minute: Calendar.current.component(.minute, from: time),
                             second: 0,
                             of: calendar.date(from: components)!)
    }
}
