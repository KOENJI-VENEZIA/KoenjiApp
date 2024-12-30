//
//  EndTimeSelectionView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//
import SwiftUI

    
struct EndTimeSelectionView: View {
    @Binding var selectedTime: String
    var category: Reservation.ReservationCategory

    var body: some View {
        if category != .noBookingZone {
            Picker("Fino alle:", selection: $selectedTime) {
                ForEach(availableTimes, id: \.self) { time in
                    Text(time).tag(time)
                }
            }
            .pickerStyle(.menu)
        } else {
            Text("Impossibile selezionare orario in questa categoria.")
                .foregroundColor(.red)
                .font(.caption)
        }
    }

    private var availableTimes: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        switch category {
        case .lunch:
            return generateTimes(from: "12:15", to: "15:00")
        case .dinner:
            return generateTimes(from: "18:15", to: "23:45")
        case .noBookingZone:
            return []
        }
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


