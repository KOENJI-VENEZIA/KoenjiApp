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
        guard let startTime = DateHelper.parseTime(start),
              let endTime = DateHelper.parseTime(end) else { return [] }

        var times: [String] = []
        var current = startTime
        while current <= endTime {
            times.append(DateHelper.formatTime(current))
            current = Calendar.current.date(byAdding: .minute, value: 15, to: current)!
        }
        return times
    }
}
