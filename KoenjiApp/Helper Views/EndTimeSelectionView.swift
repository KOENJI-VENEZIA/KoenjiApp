import SwiftUI

struct EndTimeSelectionView: View {
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
                        Text("Fino alle:")
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
                        
                        Picker("Fino alle:", selection: $selectedTime) {
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
                    .frame(width: 300, height: 400) // Adjust size for better UX
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
               current = Calendar.current.date(byAdding: .minute, value: 5, to: current)! // Step of 5 minutes
           }
           return times
       }
}
