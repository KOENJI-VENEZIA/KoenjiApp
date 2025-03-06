Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Helpers/DateHelper.swift...
# Documentation Suggestions for DateHelper.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Helpers/DateHelper.swift
Total suggestions: 70

## Class Documentation (2)

### DateHelper (Line 12)

**Context:**

```swift
import Foundation
import OSLog

struct DateHelper {
    
    static let logger = Logger(subsystem: "com.koenjiapp", category: "DateHelper")

```

**Suggested Documentation:**

```swift
/// DateHelper class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Calendar (Line 292)

**Context:**

```swift
    }
}

extension Calendar {
    /// Rounds a given date down to the nearest multiple of 15 minutes.
    func roundedDownToNearest15(_ date: Date) -> Date {
        let minuteOfHour = component(.minute, from: date)
```

**Suggested Documentation:**

```swift
/// Calendar class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (19)

### dayOfWeek (Line 40)

**Context:**

```swift
        return formatter
    }()
    
    static func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the dayOfWeek method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### formatDate (Line 47)

**Context:**

```swift
    }

    // Date formatting
    static func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the formatDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### formatTime (Line 51)

**Context:**

```swift
        return dateFormatter.string(from: date)
    }
    
    static func formatTime(_ time: Date) -> String {
        return timeFormatter.string(from: time)
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the formatTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### formatFullDate (Line 55)

**Context:**

```swift
        return timeFormatter.string(from: time)
    }
    
    static func formatFullDate(_ date: Date) -> String {
        return fullDateFormatter.string(from: date)
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the formatFullDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### parseDate (Line 60)

**Context:**

```swift
    }
    
    // Date parsing
    static func parseDate(_ dateString: String) -> Date? {
        return dateFormatter.date(from: dateString)
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the parseDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### parseTime (Line 64)

**Context:**

```swift
        return dateFormatter.date(from: dateString)
    }
    
    static func parseTime(_ timeString: String) -> Date? {
        return timeFormatter.date(from: timeString)
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the parseTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### parseFullDate (Line 68)

**Context:**

```swift
        return timeFormatter.date(from: timeString)
    }
    
    static func parseFullDate(_ dateString: String) -> Date? {
        return fullDateFormatter.date(from: dateString)
    }

```

**Suggested Documentation:**

```swift
/// [Add a description of what the parseFullDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateTimeDifference (Line 72)

**Context:**

```swift
        return fullDateFormatter.date(from: dateString)
    }

    static func calculateTimeDifference(startTime: String, endTime: String, dateFormat: String = "HH:mm") -> TimeInterval? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use a fixed locale for time parsing
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateTimeDifference method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### combineDateAndTime (Line 90)

**Context:**

```swift
        return difference
    }
    
    static func combineDateAndTime(date: Date, timeString: String) -> Date? {
        let cacheKey = "\(date.timeIntervalSince1970)-\(timeString)" as NSString

        if let cachedDate = combineDateAndTimeCache.object(forKey: cacheKey) {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the combineDateAndTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### extractTime (Line 118)

**Context:**

```swift
        return combinedDate
    }
    
    static func extractTime(time: Date) -> DateComponents? {
        let calendar = Calendar.current
        return calendar.dateComponents([.hour, .minute], from: time)
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the extractTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### compareTimes (Line 123)

**Context:**

```swift
        return calendar.dateComponents([.hour, .minute], from: time)
    }
    
    static func compareTimes(firstTime: Date, secondTime: Date, interval: TimeInterval) -> Bool {
        let calendar = Calendar.current

        guard let firstTimeComponents = extractTime(time: firstTime),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the compareTimes method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### normalizedInputTime (Line 142)

**Context:**

```swift
        }
    }
    
    static func normalizedInputTime(date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: 0,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the normalizedInputTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### normalizeTime (Line 151)

**Context:**

```swift
            of: date)
    }
    
    static func normalizeTime(time: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the normalizeTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### combinedInputTime (Line 163)

**Context:**

```swift
        )
    }
    
    static func combinedInputTime(time: DateComponents, date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: time.hour ?? 0,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the combinedInputTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### normalizedTime (Line 172)

**Context:**

```swift
            of: date)
    }
    
    static func normalizedTime(time: Date, date: Date) -> Date? {
        let calendar = Calendar.current

        return calendar.date(
```

**Suggested Documentation:**

```swift
/// [Add a description of what the normalizedTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### combineDateAndTimeStrings (Line 183)

**Context:**

```swift
        
    }
    
    static func combineDateAndTimeStrings(dateString: String, timeString: String) -> Date {
        guard let date = parseDate(dateString) else {
            logger.error("Failed to parse date string: \(dateString)")
            return Date()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the combineDateAndTimeStrings method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### combine (Line 196)

**Context:**

```swift
    }
    
    
    static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the combine method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### timeUntilReservation (Line 235)

**Context:**

```swift
          return result
      }
    
   static func timeUntilReservation(currentTime: Date,
                               reservationDateString: String,
                               reservationStartTimeString: String,
                               dateFormat: String = "yyyy-MM-dd",
```

**Suggested Documentation:**

```swift
/// [Add a description of what the timeUntilReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### formattedTime (Line 282)

**Context:**

```swift
        return reservationStartDate.timeIntervalSince(currentTime)
    }
    
    static func formattedTime(from seconds: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated  // e.g. "01:05"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the formattedTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (49)

### logger (Line 14)

**Context:**

```swift

struct DateHelper {
    
    static let logger = Logger(subsystem: "com.koenjiapp", category: "DateHelper")

    nonisolated(unsafe) private static var combineDateAndTimeCache = NSCache<NSString, NSDate>()

```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### combineDateAndTimeCache (Line 16)

**Context:**

```swift
    
    static let logger = Logger(subsystem: "com.koenjiapp", category: "DateHelper")

    nonisolated(unsafe) private static var combineDateAndTimeCache = NSCache<NSString, NSDate>()

    // Singleton DateFormatter instances
    private static let dateFormatter: DateFormatter = {
```

**Suggested Documentation:**

```swift
/// [Description of the combineDateAndTimeCache property]
```

### dateFormatter (Line 19)

**Context:**

```swift
    nonisolated(unsafe) private static var combineDateAndTimeCache = NSCache<NSString, NSDate>()

    // Singleton DateFormatter instances
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // ISO date format
        formatter.timeZone = TimeZone.current
```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### formatter (Line 20)

**Context:**

```swift

    // Singleton DateFormatter instances
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // ISO date format
        formatter.timeZone = TimeZone.current
        return formatter
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### timeFormatter (Line 26)

**Context:**

```swift
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
```

**Suggested Documentation:**

```swift
/// [Description of the timeFormatter property]
```

### formatter (Line 27)

**Context:**

```swift
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        return formatter
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### fullDateFormatter (Line 33)

**Context:**

```swift
        return formatter
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
```

**Suggested Documentation:**

```swift
/// [Description of the fullDateFormatter property]
```

### formatter (Line 34)

**Context:**

```swift
    }()
    
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### formatter (Line 41)

**Context:**

```swift
    }()
    
    static func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### dateFormatter (Line 73)

**Context:**

```swift
    }

    static func calculateTimeDifference(startTime: String, endTime: String, dateFormat: String = "HH:mm") -> TimeInterval? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use a fixed locale for time parsing

```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### startDate (Line 78)

**Context:**

```swift
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use a fixed locale for time parsing

        // Convert strings to Date objects
        guard let startDate = dateFormatter.date(from: startTime),
              let endDate = dateFormatter.date(from: endTime) else {
            logger.warning("Invalid time format")
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### endDate (Line 79)

**Context:**

```swift

        // Convert strings to Date objects
        guard let startDate = dateFormatter.date(from: startTime),
              let endDate = dateFormatter.date(from: endTime) else {
            logger.warning("Invalid time format")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the endDate property]
```

### difference (Line 85)

**Context:**

```swift
        }

        // Calculate the difference in seconds
        let difference = endDate.timeIntervalSince(startDate)

        return difference
    }
```

**Suggested Documentation:**

```swift
/// [Description of the difference property]
```

### cacheKey (Line 91)

**Context:**

```swift
    }
    
    static func combineDateAndTime(date: Date, timeString: String) -> Date? {
        let cacheKey = "\(date.timeIntervalSince1970)-\(timeString)" as NSString

        if let cachedDate = combineDateAndTimeCache.object(forKey: cacheKey) {
            logger.debug("Using cached combined date/time for: \(timeString)")
```

**Suggested Documentation:**

```swift
/// [Description of the cacheKey property]
```

### cachedDate (Line 93)

**Context:**

```swift
    static func combineDateAndTime(date: Date, timeString: String) -> Date? {
        let cacheKey = "\(date.timeIntervalSince1970)-\(timeString)" as NSString

        if let cachedDate = combineDateAndTimeCache.object(forKey: cacheKey) {
            logger.debug("Using cached combined date/time for: \(timeString)")
            return cachedDate as Date
        }
```

**Suggested Documentation:**

```swift
/// [Description of the cachedDate property]
```

### time (Line 98)

**Context:**

```swift
            return cachedDate as Date
        }

        guard let time = parseTime(timeString) else {
            logger.error("Failed to parse time string: \(timeString)")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the time property]
```

### timeComponents (Line 103)

**Context:**

```swift
            return nil
        }

        guard let timeComponents = extractTime(time: time) else {
            logger.error("Failed to extract time components from: \(time)")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the timeComponents property]
```

### combinedDate (Line 108)

**Context:**

```swift
            return nil
        }

        guard let combinedDate = combinedInputTime(time: timeComponents, date: date) else {
            logger.error("Failed to combine time components with date")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the combinedDate property]
```

### calendar (Line 119)

**Context:**

```swift
    }
    
    static func extractTime(time: Date) -> DateComponents? {
        let calendar = Calendar.current
        return calendar.dateComponents([.hour, .minute], from: time)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### calendar (Line 124)

**Context:**

```swift
    }
    
    static func compareTimes(firstTime: Date, secondTime: Date, interval: TimeInterval) -> Bool {
        let calendar = Calendar.current

        guard let firstTimeComponents = extractTime(time: firstTime),
              let secondTimeComponents = extractTime(time: secondTime) else { return false }
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### firstTimeComponents (Line 126)

**Context:**

```swift
    static func compareTimes(firstTime: Date, secondTime: Date, interval: TimeInterval) -> Bool {
        let calendar = Calendar.current

        guard let firstTimeComponents = extractTime(time: firstTime),
              let secondTimeComponents = extractTime(time: secondTime) else { return false }
        
        if let firstTimeDate = calendar.date(from: firstTimeComponents),
```

**Suggested Documentation:**

```swift
/// [Description of the firstTimeComponents property]
```

### secondTimeComponents (Line 127)

**Context:**

```swift
        let calendar = Calendar.current

        guard let firstTimeComponents = extractTime(time: firstTime),
              let secondTimeComponents = extractTime(time: secondTime) else { return false }
        
        if let firstTimeDate = calendar.date(from: firstTimeComponents),
           let secondTimeDate = calendar.date(from: secondTimeComponents) {
```

**Suggested Documentation:**

```swift
/// [Description of the secondTimeComponents property]
```

### firstTimeDate (Line 129)

**Context:**

```swift
        guard let firstTimeComponents = extractTime(time: firstTime),
              let secondTimeComponents = extractTime(time: secondTime) else { return false }
        
        if let firstTimeDate = calendar.date(from: firstTimeComponents),
           let secondTimeDate = calendar.date(from: secondTimeComponents) {
        let timeDifference = abs(firstTimeDate.timeIntervalSince(secondTimeDate))
            if timeDifference < interval {
```

**Suggested Documentation:**

```swift
/// [Description of the firstTimeDate property]
```

### secondTimeDate (Line 130)

**Context:**

```swift
              let secondTimeComponents = extractTime(time: secondTime) else { return false }
        
        if let firstTimeDate = calendar.date(from: firstTimeComponents),
           let secondTimeDate = calendar.date(from: secondTimeComponents) {
        let timeDifference = abs(firstTimeDate.timeIntervalSince(secondTimeDate))
            if timeDifference < interval {
                return true
```

**Suggested Documentation:**

```swift
/// [Description of the secondTimeDate property]
```

### timeDifference (Line 131)

**Context:**

```swift
        
        if let firstTimeDate = calendar.date(from: firstTimeComponents),
           let secondTimeDate = calendar.date(from: secondTimeComponents) {
        let timeDifference = abs(firstTimeDate.timeIntervalSince(secondTimeDate))
            if timeDifference < interval {
                return true
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the timeDifference property]
```

### calendar (Line 143)

**Context:**

```swift
    }
    
    static func normalizedInputTime(date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: 0,
            minute: 0,
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### calendar (Line 152)

**Context:**

```swift
    }
    
    static func normalizeTime(time: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### components (Line 153)

**Context:**

```swift
    
    static func normalizeTime(time: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(
            bySettingHour: components.hour ?? 0,
```

**Suggested Documentation:**

```swift
/// [Description of the components property]
```

### calendar (Line 164)

**Context:**

```swift
    }
    
    static func combinedInputTime(time: DateComponents, date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### calendar (Line 173)

**Context:**

```swift
    }
    
    static func normalizedTime(time: Date, date: Date) -> Date? {
        let calendar = Calendar.current

        return calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### date (Line 184)

**Context:**

```swift
    }
    
    static func combineDateAndTimeStrings(dateString: String, timeString: String) -> Date {
        guard let date = parseDate(dateString) else {
            logger.error("Failed to parse date string: \(dateString)")
            return Date()
        }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### combinedDate (Line 188)

**Context:**

```swift
            logger.error("Failed to parse date string: \(dateString)")
            return Date()
        }
        guard let combinedDate = combineDateAndTime(date: date, timeString: timeString) else {
            logger.warning("Failed to combine date (\(dateString)) and time (\(timeString)). Using current date as fallback.")
            return Date()
        }
```

**Suggested Documentation:**

```swift
/// [Description of the combinedDate property]
```

### calendar (Line 197)

**Context:**

```swift
    
    
    static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### dateComponents (Line 198)

**Context:**

```swift
    
    static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
```

**Suggested Documentation:**

```swift
/// [Description of the dateComponents property]
```

### timeComponents (Line 199)

**Context:**

```swift
    static func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
```

**Suggested Documentation:**

```swift
/// [Description of the timeComponents property]
```

### combinedComponents (Line 201)

**Context:**

```swift
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
```

**Suggested Documentation:**

```swift
/// [Description of the combinedComponents property]
```

### randomHour (Line 223)

**Context:**

```swift
          let startHour = range.0
          let endHour = range.1

          let randomHour = Int.random(in: startHour...endHour)
          let randomMinute = Int.random(in: 0...59)

          var components = calendar.dateComponents([.year, .month, .day], from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the randomHour property]
```

### randomMinute (Line 224)

**Context:**

```swift
          let endHour = range.1

          let randomHour = Int.random(in: startHour...endHour)
          let randomMinute = Int.random(in: 0...59)

          var components = calendar.dateComponents([.year, .month, .day], from: date)
          components.hour = randomHour
```

**Suggested Documentation:**

```swift
/// [Description of the randomMinute property]
```

### components (Line 226)

**Context:**

```swift
          let randomHour = Int.random(in: startHour...endHour)
          let randomMinute = Int.random(in: 0...59)

          var components = calendar.dateComponents([.year, .month, .day], from: date)
          components.hour = randomHour
          components.minute = randomMinute

```

**Suggested Documentation:**

```swift
/// [Description of the components property]
```

### result (Line 230)

**Context:**

```swift
          components.hour = randomHour
          components.minute = randomMinute

          let result = calendar.date(from: components) ?? date
          logger.debug("Generated random time: \(formatTime(result)) for date: \(formatDate(date))")
          return result
      }
```

**Suggested Documentation:**

```swift
/// [Description of the result property]
```

### calendar (Line 241)

**Context:**

```swift
                               dateFormat: String = "yyyy-MM-dd",
                               timeFormat: String = "HH:mm") -> TimeInterval? {
        
        let calendar = Calendar.current
        
        // Create DateFormatter(s) for the date and time.
        let dateFormatter = DateFormatter()
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### dateFormatter (Line 244)

**Context:**

```swift
        let calendar = Calendar.current
        
        // Create DateFormatter(s) for the date and time.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### timeFormatter (Line 248)

**Context:**

```swift
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = timeFormat
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
```

**Suggested Documentation:**

```swift
/// [Description of the timeFormatter property]
```

### reservationDate (Line 253)

**Context:**

```swift
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Parse the reservation date.
        guard let reservationDate = dateFormatter.date(from: reservationDateString) else {
            logger.warning("Failed to parse reservation date string: \(reservationDateString)")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### reservationTime (Line 259)

**Context:**

```swift
        }
        
        // Parse the reservation start time.
        guard let reservationTime = timeFormatter.date(from: reservationStartTimeString) else {
            logger.warning("Failed to parse reservation time string: \(reservationStartTimeString)")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationTime property]
```

### timeComponents (Line 265)

**Context:**

```swift
        }
        
        // Extract hour and minute components from the reservation start time.
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reservationTime)
        
        // Create a DateComponents for the full reservation datetime
        var reservationDateComponents = calendar.dateComponents([.year, .month, .day], from: reservationDate)
```

**Suggested Documentation:**

```swift
/// [Description of the timeComponents property]
```

### reservationDateComponents (Line 268)

**Context:**

```swift
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reservationTime)
        
        // Create a DateComponents for the full reservation datetime
        var reservationDateComponents = calendar.dateComponents([.year, .month, .day], from: reservationDate)
        reservationDateComponents.hour = timeComponents.hour
        reservationDateComponents.minute = timeComponents.minute
        
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDateComponents property]
```

### reservationStartDate (Line 273)

**Context:**

```swift
        reservationDateComponents.minute = timeComponents.minute
        
        // Combine into a full Date for the reservation start.
        guard let reservationStartDate = calendar.date(from: reservationDateComponents) else {
            logger.warning("Failed to combine date and time into a reservation start date.")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationStartDate property]
```

### formatter (Line 283)

**Context:**

```swift
    }
    
    static func formattedTime(from seconds: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated  // e.g. "01:05"
        formatter.zeroFormattingBehavior = [.pad]
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```


Total documentation suggestions: 70

