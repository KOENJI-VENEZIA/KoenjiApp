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
    
    static func combineDateAndTime(date: Date, timeString: String) -> Date? {
        // Parse the time string into a Date object (only time components)
        guard let time = parseTime(timeString) else { return nil }
        
        // Extract the time components from the parsed time
        guard let timeComponents = extractTime(time: time) else { return nil }
        
        // Combine the date and time components
        return normalizedInputTime(time: timeComponents, date: date)
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
    
    static func normalizedInputTime(time: DateComponents, date: Date) -> Date? {
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
        guard let date = parseDate(dateString) else { return Date() }
        guard let combinedDate = combineDateAndTime(date: date, timeString: timeString) else {
            print("Warning: Failed to combine date (\(dateString)) and time (\(timeString)). Using current date as fallback.")
            return Date() // Fallback to the current date and time
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

          // Random hour and minute within the range
          let randomHour = Int.random(in: startHour...endHour)
          let randomMinute = Int.random(in: 0...59)

          // Combine random hour and minute with the given date
          var components = calendar.dateComponents([.year, .month, .day], from: date)
          components.hour = randomHour
          components.minute = randomMinute

          return calendar.date(from: components) ?? date
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
            print("Failed to parse reservation date string: \(reservationDateString)")
            return nil
        }
        
        // Parse the reservation start time.
        guard let reservationTime = timeFormatter.date(from: reservationStartTimeString) else {
            print("Failed to parse reservation time string: \(reservationStartTimeString)")
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
            print("Failed to combine date and time into a reservation start date.")
            return nil
        }
        
        // Compute and return the time interval (reservation start minus current time).
        return reservationStartDate.timeIntervalSince(currentTime)
    }
    
    static func formattedTime(from seconds: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .positional  // e.g. "01:05"
        formatter.zeroFormattingBehavior = [.pad]
        
        return formatter.string(from: seconds)
    }
}

