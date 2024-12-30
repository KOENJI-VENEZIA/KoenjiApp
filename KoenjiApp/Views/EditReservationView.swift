import SwiftUI

struct EditReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.dismiss) var dismiss
    
    @State var reservation: Reservation
    @State private var selectedDate: Date = Date() // Default to reservation's current date
    
    var body: some View {
        NavigationView {
            Form {
                Section("Obbligatori") {
                    TextField("Nome", text: $reservation.name)
                    TextField("Telefono (+XX...)", text: $reservation.phone)
                        .keyboardType(.phonePad)
                    
                    Stepper("Numero ospiti: \(reservation.numberOfPersons)",
                            value: $reservation.numberOfPersons,
                            in: 2...14)
                    

                    
                    // Date Picker and Day Display
                    DatePicker("Seleziona data", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) { newDate in
                            reservation.dateString = formatDate(newDate)
                        }
                    
                    Text(formattedDate())
                        .font(.headline)
                        .padding(.vertical, 4)
                    
                    Picker("Categoria", selection: $reservation.category) {
                        ForEach(Reservation.ReservationCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                    .onChange(of: reservation.category) { _ in
                        adjustTimesForCategory()
                    }
                    
                    TimeSelectionView(selectedTime: $reservation.startTime, category: reservation.category)
                        .onChange(of: reservation.startTime) { newStartTime in
                            reservation.endTime = TimeHelpers.calculateEndTime(startTime: newStartTime, category: reservation.category)
                        }
                    
                    EndTimeSelectionView(selectedTime: $reservation.endTime, category: reservation.category)
                }

                Section("Note") {
                    TextEditor(text: $reservation.notes.orEmpty())
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Modifica Prenotazione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                adjustTimesForCategory()
                loadInitialDate()
            }
        }
    }
    
    private func saveChanges() {
        store.updateReservation(reservation)
        store.saveReservationsToDisk()
        dismiss()
    }
    
    private func adjustTimesForCategory() {
        switch reservation.category {
        case .lunch:
            reservation.startTime = "12:00"
            reservation.endTime = TimeHelpers.calculateEndTime(startTime: reservation.startTime, category: .lunch)
        case .dinner:
            reservation.startTime = "18:00"
            reservation.endTime = TimeHelpers.calculateEndTime(startTime: reservation.startTime, category: .dinner)
        case .noBookingZone:
            reservation.startTime = "09:00"
            reservation.endTime = TimeHelpers.calculateEndTime(startTime: reservation.startTime, category: .noBookingZone)
        }
    }
    
    private func loadInitialDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        selectedDate = formatter.date(from: reservation.dateString) ?? Date()
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
