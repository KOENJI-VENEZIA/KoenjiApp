import SwiftUI

struct TimeSelectionView: View {
    @Binding var selectedTime: String
    var category: Reservation.ReservationCategory
    @State private var showingPicker = false

    var body: some View {
        VStack {
            if category != .noBookingZone {
                
                Button(action: {
                    showingPicker = true
                }) {
                    HStack {
                        Text("Dalle:")
                        Spacer()
                        Text(selectedTime)
                            .foregroundColor(.blue)
                            .bold()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))
                }
                .popover(isPresented: $showingPicker) {
                    VStack {
                        Text("Seleziona orario")
                            .font(.headline)
                            .padding(.top)
                        
                        Picker("Dalle:", selection: $selectedTime) {
                            ForEach(availableTimes, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxHeight: 150)
                        .clipped()
                        
                        Button("OK") {
                            showingPicker = false
                        }
                        .padding()
                    }
                    .frame(width: 300, height: 400) // Adjust the size of the popover
                }
            } else {
                Text("Impossibile selezionare orario in questa categoria.")
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
                
        }
        .padding()
    }

    private var availableTimes: [String] {
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
        guard let startTime = DateHelper.parseTime(start),
              let endTime = DateHelper.parseTime(end) else { return [] }

        var times: [String] = []
        var current = startTime
        while current <= endTime {
            times.append(DateHelper.formatTime(current))
            current = Calendar.current.date(byAdding: .minute, value: 5, to: current)! // Step of 5 minutes
        }

        return times
    }
}
