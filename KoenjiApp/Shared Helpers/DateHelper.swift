//
//  DateHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 7/1/25.
//


import Foundation
import OSLog

struct DateHelper {
    
    static let logger = Logger(subsystem: "com.koenjiapp", category: "DateHelper")

    nonisolated(unsafe) private static var combineDateAndTimeCache = NSCache<NSString, NSDate>()

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
    
    static func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

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

    static func calculateTimeDifference(startTime: String, endTime: String, dateFormat: String = "HH:mm") -> TimeInterval? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use a fixed locale for time parsing

        // Convert strings to Date objects
        guard let startDate = dateFormatter.date(from: startTime),
              let endDate = dateFormatter.date(from: endTime) else {
            Task { @MainActor in
                AppLog.warning("Invalid time format")
            }
            return nil
        }

        // Calculate the difference in seconds
        let difference = endDate.timeIntervalSince(startDate)

        return difference
    }
    
    static func combineDateAndTime(date: Date, timeString: String) -> Date? {
        let cacheKey = "\(date.timeIntervalSince1970)-\(timeString)" as NSString

        if let cachedDate = combineDateAndTimeCache.object(forKey: cacheKey) {
            Task { @MainActor in
                AppLog.debug("Using cached combined date/time for: \(timeString)")
            }
            return cachedDate as Date
        }

        guard let time = parseTime(timeString) else {
            Task { @MainActor in
                AppLog.error("Failed to parse time string: \(timeString)")
            }
            return nil
        }

        guard let timeComponents = extractTime(time: time) else {
            Task { @MainActor in
                AppLog.error("Failed to extract time components from: \(time)")
            }
            return nil
        }

        guard let combinedDate = combinedInputTime(time: timeComponents, date: date) else {
            Task { @MainActor in
                AppLog.error("Failed to combine time components with date")
            }
            return nil
        }

        combineDateAndTimeCache.setObject(combinedDate as NSDate, forKey: cacheKey)
        Task { @MainActor in
            AppLog.debug("Successfully combined date and time: \(combinedDate)")
        }
        return combinedDate
    }
    
    static func extractTime(time: Date) -> DateComponents? {
        let calendar = Calendar.current
        return calendar.dateComponents([.hour, .minute], from: time)
    }
    
    static func compareTimes(firstTime: Date, secondTime: Date, interval: TimeInterval) -> Bool {
        let calendar = Calendar.current

        guard let firstTimeComponents = extractTime(time: firstTime),
              let secondTimeComponents = extractTime(time: secondTime) else { return false }
        
        if let firstTimeDate = calendar.date(from: firstTimeComponents),
           let secondTimeDate = calendar.date(from: secondTimeComponents) {
        let timeDifference = abs(firstTimeDate.timeIntervalSince(secondTimeDate))
            if timeDifference < interval {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    static func normalizedInputTime(date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: 0,
            minute: 0,
            second: 0,
            of: date)
    }
    
    static func normalizeTime(time: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: time
        )
    }
    
    static func combinedInputTime(time: DateComponents, date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: 0,
            of: date)
    }
    
    static func normalizedTime(time: Date, date: Date) -> Date? {
        let calendar = Calendar.current

        return calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            second: 0,
            of: date)
        
    }
    
    static func combineDateAndTimeStrings(dateString: String, timeString: String) -> Date {
        guard let date = parseDate(dateString) else {
            Task { @MainActor in
                AppLog.error("Failed to parse date string: \(dateString)")
            }
            return Date()
        }
        guard let combinedDate = combineDateAndTime(date: date, timeString: timeString) else {
            Task { @MainActor in
                AppLog.warning("Failed to combine date (\(dateString)) and time (\(timeString)). Using current date as fallback.")
            }
            return Date()
        }
        return combinedDate
    }
    
    
    static func combine(date: Date, time: Date) -> Date {
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

        // Return a valid date or fallback to the input `date` if combining fails
        return calendar.date(from: combinedComponents) ?? date
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

          let randomHour = Int.random(in: startHour...endHour)
          let randomMinute = Int.random(in: 0...59)

          var components = calendar.dateComponents([.year, .month, .day], from: date)
          components.hour = randomHour
          components.minute = randomMinute

          let result = calendar.date(from: components) ?? date
          Task { @MainActor in
            AppLog.debug("Generated random time: \(formatTime(result)) for date: \(formatDate(date))")
          }
          return result
      }
    
   static func timeUntilReservation(currentTime: Date,
                               reservationDateString: String,
                               reservationStartTimeString: String,
                               dateFormat: String = "yyyy-MM-dd",
                               timeFormat: String = "HH:mm") -> TimeInterval? {
        
        let calendar = Calendar.current
        
        // Create DateFormatter(s) for the date and time.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = timeFormat
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Parse the reservation date.
        guard let reservationDate = dateFormatter.date(from: reservationDateString) else {
            Task { @MainActor in
                AppLog.warning("Failed to parse reservation date string: \(reservationDateString)")
            }
            return nil
        }
        
        // Parse the reservation start time.
        guard let reservationTime = timeFormatter.date(from: reservationStartTimeString) else {
            Task { @MainActor in
                AppLog.warning("Failed to parse reservation time string: \(reservationStartTimeString)")
            }
            return nil
        }
        
        // Extract hour and minute components from the reservation start time.
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reservationTime)
        
        // Create a DateComponents for the full reservation datetime
        var reservationDateComponents = calendar.dateComponents([.year, .month, .day], from: reservationDate)
        reservationDateComponents.hour = timeComponents.hour
        reservationDateComponents.minute = timeComponents.minute
        
        // Combine into a full Date for the reservation start.
        guard let reservationStartDate = calendar.date(from: reservationDateComponents) else {
            Task { @MainActor in
                AppLog.warning("Failed to combine date and time into a reservation start date.")
            }
            return nil
        }
        
        // Compute and return the time interval (reservation start minus current time).
        return reservationStartDate.timeIntervalSince(currentTime)
    }
    
    static func formattedTime(from seconds: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated  // e.g. "01:05"
        formatter.zeroFormattingBehavior = [.pad]
        
        return formatter.string(from: seconds)
    }
}

extension Calendar {
    /// Rounds a given date down to the nearest multiple of 15 minutes.
    func roundedDownToNearest15(_ date: Date) -> Date {
        let minuteOfHour = component(.minute, from: date)
        let remainder = minuteOfHour % 15
        // Subtract 'remainder' minutes to get down to 0, 15, 30, or 45.
        return self.date(byAdding: .minute, value: -remainder, to: date)!
    }
}
