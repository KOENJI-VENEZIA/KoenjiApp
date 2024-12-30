//
//  TimeHelpers.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import Foundation

struct TimeHelpers {
    static func calculateEndTime(startTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current

        
        guard let start = formatter.date(from: startTime) else {
            return startTime
        }
        
        let last_full = "13:15"
        let first_incomplete = "13:30"
        let second_incomplete = "13:45"
        
        guard let last_full_start = formatter.date(from: last_full) else {
            return last_full
        }
        
        guard let first_incomplete_time = formatter.date(from: first_incomplete) else {
            return first_incomplete
        }
        
        guard let second_incomplete_time = formatter.date(from: second_incomplete) else {
            return second_incomplete
        }
        
        var end = Date()
        
        if start == first_incomplete_time {
            end = Calendar.current.date(byAdding: .minute, value: 90, to: start) ?? start
        } else if start == second_incomplete_time {
            end = Calendar.current.date(byAdding: .minute, value: 75, to: start) ?? start
        } else {
            end = Calendar.current.date(byAdding: .minute, value: 105, to: start) ?? start
        }
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
    
}

extension Date {

    

}

