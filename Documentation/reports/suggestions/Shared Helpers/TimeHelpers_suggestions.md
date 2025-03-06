Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Helpers/TimeHelpers.swift...
# Documentation Suggestions for TimeHelpers.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Helpers/TimeHelpers.swift
Total suggestions: 36

## Class Documentation (1)

### TimeHelpers (Line 11)

**Context:**

```swift
import Foundation
import OSLog

struct TimeHelpers {
    
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TimeHelpers")

```

**Suggested Documentation:**

```swift
/// TimeHelpers class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (6)

### calculateEndTime (Line 16)

**Context:**

```swift
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TimeHelpers")


    static func calculateEndTime(startTime: String, category: Reservation.ReservationCategory) -> String {
        guard let start = DateHelper.parseTime(startTime) else {
            logger.error("Failed to parse start time: \(startTime)")
            return startTime
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateEndTime method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### remainingTimeString (Line 40)

**Context:**

```swift
        return DateHelper.formatTime(end)
    }

    static func remainingTimeString(endTime: Date, currentTime: Date) -> String? {
        let calendar = Calendar.current

        // If the end time is in the past, return nil
```

**Suggested Documentation:**

```swift
/// [Add a description of what the remainingTimeString method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### elapsedTimeString (Line 60)

**Context:**

```swift
        return nil
    }
    
    static func elapsedTimeString(date: Date, currentTime: Date) -> String {
        let calendar = Calendar.current
        
        let diff = calendar.dateComponents([.hour, .minute], from: date, to: currentTime)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the elapsedTimeString method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### availableTimeString (Line 74)

**Context:**

```swift
        }
    }

    static func availableTimeString(endTime: String, startTime: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
```

**Suggested Documentation:**

```swift
/// [Add a description of what the availableTimeString method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### parseFullDate (Line 105)

**Context:**

```swift

    nonisolated(unsafe) private static var dateCache: [String: Date] = [:]
    
    static func parseFullDate(from dateString: String) -> Date? {
        if let cachedDate = dateCache[dateString] {
            logger.debug("Using cached date for: \(dateString)")
            return cachedDate
```

**Suggested Documentation:**

```swift
/// [Add a description of what the parseFullDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateTimeDifference (Line 136)

**Context:**

```swift
                                     of: date)
    }

    static func calculateTimeDifference(startTime: String, endTime: String, dateFormat: String = "HH:mm") -> TimeInterval? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateTimeDifference method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (29)

### logger (Line 13)

**Context:**

```swift

struct TimeHelpers {
    
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TimeHelpers")


    static func calculateEndTime(startTime: String, category: Reservation.ReservationCategory) -> String {
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### start (Line 17)

**Context:**

```swift


    static func calculateEndTime(startTime: String, category: Reservation.ReservationCategory) -> String {
        guard let start = DateHelper.parseTime(startTime) else {
            logger.error("Failed to parse start time: \(startTime)")
            return startTime
        }
```

**Suggested Documentation:**

```swift
/// [Description of the start property]
```

### lastLunchTime (Line 23)

**Context:**

```swift
        }

        // Define category-specific time constraints
        let lastLunchTime = DateHelper.parseTime("15:00")!
        let lastDinnerTime = DateHelper.parseTime("23:45")!
        let maxEndTime = category == .lunch ? lastLunchTime : lastDinnerTime

```

**Suggested Documentation:**

```swift
/// [Description of the lastLunchTime property]
```

### lastDinnerTime (Line 24)

**Context:**

```swift

        // Define category-specific time constraints
        let lastLunchTime = DateHelper.parseTime("15:00")!
        let lastDinnerTime = DateHelper.parseTime("23:45")!
        let maxEndTime = category == .lunch ? lastLunchTime : lastDinnerTime

        var end: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the lastDinnerTime property]
```

### maxEndTime (Line 25)

**Context:**

```swift
        // Define category-specific time constraints
        let lastLunchTime = DateHelper.parseTime("15:00")!
        let lastDinnerTime = DateHelper.parseTime("23:45")!
        let maxEndTime = category == .lunch ? lastLunchTime : lastDinnerTime

        var end: Date = Date()
        // Adjust end time based on start time
```

**Suggested Documentation:**

```swift
/// [Description of the maxEndTime property]
```

### end (Line 27)

**Context:**

```swift
        let lastDinnerTime = DateHelper.parseTime("23:45")!
        let maxEndTime = category == .lunch ? lastLunchTime : lastDinnerTime

        var end: Date = Date()
        // Adjust end time based on start time
        if category == .lunch {
            end = Calendar.current.date(byAdding: .minute, value: 80, to: start) ?? start
```

**Suggested Documentation:**

```swift
/// [Description of the end property]
```

### calendar (Line 41)

**Context:**

```swift
    }

    static func remainingTimeString(endTime: Date, currentTime: Date) -> String? {
        let calendar = Calendar.current

        // If the end time is in the past, return nil
        if endTime <= currentTime {
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### diff (Line 49)

**Context:**

```swift
        }

        // Calculate the difference in hours and minutes
        let diff = calendar.dateComponents([.hour, .minute], from: currentTime, to: endTime)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

```

**Suggested Documentation:**

```swift
/// [Description of the diff property]
```

### hours (Line 50)

**Context:**

```swift

        // Calculate the difference in hours and minutes
        let diff = calendar.dateComponents([.hour, .minute], from: currentTime, to: endTime)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

        // Return formatted string if there's time left
```

**Suggested Documentation:**

```swift
/// [Description of the hours property]
```

### minutes (Line 51)

**Context:**

```swift
        // Calculate the difference in hours and minutes
        let diff = calendar.dateComponents([.hour, .minute], from: currentTime, to: endTime)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

        // Return formatted string if there's time left
        if hours > 0 || minutes > 0 {
```

**Suggested Documentation:**

```swift
/// [Description of the minutes property]
```

### calendar (Line 61)

**Context:**

```swift
    }
    
    static func elapsedTimeString(date: Date, currentTime: Date) -> String {
        let calendar = Calendar.current
        
        let diff = calendar.dateComponents([.hour, .minute], from: date, to: currentTime)
        let hours = diff.hour ?? 0
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### diff (Line 63)

**Context:**

```swift
    static func elapsedTimeString(date: Date, currentTime: Date) -> String {
        let calendar = Calendar.current
        
        let diff = calendar.dateComponents([.hour, .minute], from: date, to: currentTime)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        
```

**Suggested Documentation:**

```swift
/// [Description of the diff property]
```

### hours (Line 64)

**Context:**

```swift
        let calendar = Calendar.current
        
        let diff = calendar.dateComponents([.hour, .minute], from: date, to: currentTime)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        
        if hours != 0 {
```

**Suggested Documentation:**

```swift
/// [Description of the hours property]
```

### minutes (Line 65)

**Context:**

```swift
        
        let diff = calendar.dateComponents([.hour, .minute], from: date, to: currentTime)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0
        
        if hours != 0 {
            return "\(hours)h fa"
```

**Suggested Documentation:**

```swift
/// [Description of the minutes property]
```

### formatter (Line 75)

**Context:**

```swift
    }

    static func availableTimeString(endTime: String, startTime: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### start (Line 79)

**Context:**

```swift
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let start = formatter.date(from: startTime) else { return nil }
        guard let end = formatter.date(from: endTime) else { return nil }


```

**Suggested Documentation:**

```swift
/// [Description of the start property]
```

### end (Line 80)

**Context:**

```swift
        formatter.timeZone = TimeZone.current

        guard let start = formatter.date(from: startTime) else { return nil }
        guard let end = formatter.date(from: endTime) else { return nil }


        let delta = start.distance(to: end)
```

**Suggested Documentation:**

```swift
/// [Description of the end property]
```

### delta (Line 83)

**Context:**

```swift
        guard let end = formatter.date(from: endTime) else { return nil }


        let delta = start.distance(to: end)
        let tformatter = DateComponentsFormatter()

        tformatter.unitsStyle = .abbreviated
```

**Suggested Documentation:**

```swift
/// [Description of the delta property]
```

### tformatter (Line 84)

**Context:**

```swift


        let delta = start.distance(to: end)
        let tformatter = DateComponentsFormatter()

        tformatter.unitsStyle = .abbreviated
        tformatter.allowedUnits = [.hour, .minute]
```

**Suggested Documentation:**

```swift
/// [Description of the tformatter property]
```

### dateCache (Line 103)

**Context:**

```swift
        return start1 < end2 && start2 < end1
    }

    nonisolated(unsafe) private static var dateCache: [String: Date] = [:]
    
    static func parseFullDate(from dateString: String) -> Date? {
        if let cachedDate = dateCache[dateString] {
```

**Suggested Documentation:**

```swift
/// [Description of the dateCache property]
```

### cachedDate (Line 106)

**Context:**

```swift
    nonisolated(unsafe) private static var dateCache: [String: Date] = [:]
    
    static func parseFullDate(from dateString: String) -> Date? {
        if let cachedDate = dateCache[dateString] {
            logger.debug("Using cached date for: \(dateString)")
            return cachedDate
        }
```

**Suggested Documentation:**

```swift
/// [Description of the cachedDate property]
```

### formatter (Line 111)

**Context:**

```swift
            return cachedDate
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current

```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### parsedDate (Line 115)

**Context:**

```swift
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.timeZone = TimeZone.current

        if let parsedDate = formatter.date(from: dateString) {
            dateCache[dateString] = parsedDate
            logger.debug("Successfully parsed date: \(dateString)")
            return parsedDate
```

**Suggested Documentation:**

```swift
/// [Description of the parsedDate property]
```

### formatter (Line 127)

**Context:**

```swift

    /// Converts a time string to a `Date` object on a specified date.
    static func date(from timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }
        return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: time),
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### time (Line 129)

**Context:**

```swift
    static func date(from timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return nil }
        return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: time),
                                     minute: Calendar.current.component(.minute, from: time),
                                     second: 0,
```

**Suggested Documentation:**

```swift
/// [Description of the time property]
```

### dateFormatter (Line 137)

**Context:**

```swift
    }

    static func calculateTimeDifference(startTime: String, endTime: String, dateFormat: String = "HH:mm") -> TimeInterval? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### startDate (Line 141)

**Context:**

```swift
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let startDate = dateFormatter.date(from: startTime),
              let endDate = dateFormatter.date(from: endTime) else {
            logger.error("Invalid time format - Start: \(startTime), End: \(endTime)")
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the startDate property]
```

### endDate (Line 142)

**Context:**

```swift
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        guard let startDate = dateFormatter.date(from: startTime),
              let endDate = dateFormatter.date(from: endTime) else {
            logger.error("Invalid time format - Start: \(startTime), End: \(endTime)")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the endDate property]
```

### difference (Line 147)

**Context:**

```swift
            return nil
        }

        let difference = endDate.timeIntervalSince(startDate)
        return difference
    }
}
```

**Suggested Documentation:**

```swift
/// [Description of the difference property]
```


Total documentation suggestions: 36

