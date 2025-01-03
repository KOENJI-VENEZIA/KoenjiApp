//
//  TimeHelpers.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation

struct TimeHelpers {
    static func calculateEndTime(startTime: String, category: Reservation.ReservationCategory) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let start = formatter.date(from: startTime) else {
            return startTime
        }

        // Define category-specific time constraints
        let lastLunchTime = formatter.date(from: "15:00")!
        let lastDinnerTime = formatter.date(from: "23:45")!
        let maxEndTime = category == .lunch ? lastLunchTime : lastDinnerTime

        // Adjust end time based on start time
        var end = Calendar.current.date(byAdding: .minute, value: 105, to: start) ?? start

        // Ensure the calculated end time does not exceed the maximum allowed time
        end = min(end, maxEndTime)

        return formatter.string(from: end)
    }

    
    static func remainingTimeString(endTime: String, currentTime: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        
        guard let end = formatter.date(from: endTime) else {
            return nil
        }
        
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
    
    func timeInterval(lhs: Date, rhs: Date) -> TimeInterval {
       return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
   }
    
    func calculateTime(_ timeValue: Float) -> String {
            let timeMeasure = Measurement(value: Double(timeValue), unit: UnitDuration.minutes)
            let hours = timeMeasure.converted(to: .hours)
            if hours.value > 1 {
                let minutes = timeMeasure.value.truncatingRemainder(dividingBy: 60)
                return String(format: "%.f%@%.f%@", hours.value, "h", minutes, "min")
            }
            return String(format: "%.f%@", timeMeasure.value, "min")
        }
    
    static func availableTimeString(endTime: String, startTime: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        
        guard let start = formatter.date(from: startTime) else { return nil }
        guard let end = formatter.date(from: endTime) else { return nil }
        
        let idealEnd = Calendar.current.date(byAdding: .minute, value: 105, to: start) ?? start
        
        let idealDelta = start.distance(to: idealEnd)
        let delta = start.distance(to: end)
        let tformatter = DateComponentsFormatter()
        
        tformatter.unitsStyle = .abbreviated
        tformatter.allowedUnits = [.hour, .minute]
        
        if delta - idealDelta < 0 {
            return "Attenzione:\ndurata(\(tformatter.string(from: delta)!))!"
        }
        return nil
    }
    
    /// Checks if two time ranges overlap.
    static func timeRangesOverlap(start1: Date?, end1: Date?, start2: Date, end2: Date) -> Bool {
        guard let start1 = start1, let end1 = end1 else { return false }
        return (start1 < end2 && end1 > start2)
    }

    /// Converts a time string in "HH:mm" format into a `Date` object on a specific date.
    static func date(from timeString: String, on date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        guard let time = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: components.hour ?? 0,
                             minute: components.minute ?? 0,
                             second: 0,
                             of: date)
    }
    
}


