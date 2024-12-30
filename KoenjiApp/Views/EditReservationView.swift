import SwiftUI

struct EditReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.dismiss) var dismiss
    
    @State var reservation: Reservation
    
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
}
