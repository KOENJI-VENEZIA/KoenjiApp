//
//  TimeSelectionView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//
import SwiftUI

struct TimeSelectionView: View {
    @Binding var selectedTime: String
    var category: Reservation.ReservationCategory
    
    var body: some View {
        Picker("Dalle:", selection: $selectedTime) {
            ForEach(availableTimes, id: \.self) { time in
                Text(time).tag(time)
            }
        }
        .pickerStyle(.menu)
        
    }
    
    private var availableTimes: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        var times: [String] = []

        switch category {
        case .lunch:
            times = generateTimes(from: "12:00", to: "14:45")
        case .dinner:
            times = generateTimes(from: "18:00", to: "23:45")
        case .noBookingZone:
            times = []
        }

        return times
    }

    private func generateTimes(from start: String, to end: String) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let startTime = formatter.date(from: start),
              let endTime = formatter.date(from: end) else { return [] }

        var times: [String] = []
        var current = startTime
        while current <= endTime {
            times.append(formatter.string(from: current))
            current = Calendar.current.date(byAdding: .minute, value: 15, to: current)!
        }

        return times
    }

}
