//
//  DateHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 7/1/25.
//


import Foundation

struct DateHelper {
    // Singleton DateFormatter instances
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // ISO date format
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // Date formatting
    static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    static func formatTime(_ time: Date) -> String {
        return timeFormatter.string(from: time)
    }
    
    static func formatFullDate(_ date: Date) -> String {
        return fullDateFormatter.string(from: date)
    }
    
    // Date parsing
    static func parseDate(_ dateString: String) -> Date? {
        return dateFormatter.date(from: dateString)
    }
    
    static func parseTime(_ timeString: String) -> Date? {
        return timeFormatter.date(from: timeString)
    }
    
    static func parseFullDate(_ dateString: String) -> Date? {
        return fullDateFormatter.date(from: dateString)
    }
    
    static func combineDateAndTime(date: Date, timeString: String) -> Date? {
        // Parse the time string into a Date object (only time components)
        guard let time = parseTime(timeString) else { return nil }
        
        // Extract the time components from the parsed time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        // Combine the date and time components
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                             minute: timeComponents.minute ?? 0,
                             second: timeComponents.second ?? 0,
                             of: date)
    }
    
    static func combine(date: Date, time: Date) -> Date? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second

        return calendar.date(from: combinedComponents)
    }
    
    static func prepareCombinedDate(date: Date, with time: Date) -> Date {
        guard let updatedTime = Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute: Calendar.current.component(.minute, from: time),
            second: 0,
            of: date
        ) else { return time }
        return updatedTime
        }
    
}

extension DateHelper {
    static func dateFromKey(key: String) -> (date: Date, category: Reservation.ReservationCategory)? {
        let components = key.split(separator: "-")
        guard components.count >= 2,
              let date = DateHelper.parseDate(String(components[0])),
              let category = Reservation.ReservationCategory(rawValue: String(components[1])) else {
            return nil
        }
        return (date: date, category: category)
    }
    
    /// Generates a random time within the given hour range on a specific date.
      /// - Parameters:
      ///   - date: The base date.
      ///   - range: The range of hours (e.g., (12, 23) for lunch to dinner).
      /// - Returns: A `Date` with a randomized time within the specified range.
      static func randomTime(for date: Date, range: (Int, Int)) -> Date {
          let calendar = Calendar.current
          let startHour = range.0
          let endHour = range.1

          // Random hour and minute within the range
          let randomHour = Int.random(in: startHour...endHour)
          let randomMinute = Int.random(in: 0...59)

          // Combine random hour and minute with the given date
          var components = calendar.dateComponents([.year, .month, .day], from: date)
          components.hour = randomHour
          components.minute = randomMinute

          return calendar.date(from: components) ?? date
      }
}
