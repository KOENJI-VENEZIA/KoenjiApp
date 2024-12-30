//
//  EditReservationView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

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
                    
                    
                    // A custom time picker if you want the 15-min increment
                    
                    TimeSelectionView(selectedTime: $reservation.startTime, category: reservation.category)
                        .onChange(of: reservation.startTime) { newStartTime in
                            // Recalculate the end time whenever start time changes
                            reservation.endTime = TimeHelpers.calculateEndTime(startTime: newStartTime)
                        }
                    // End Time Picker
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
        }
    }
    
    private func saveChanges() {
        // Just update store
        store.updateReservation(reservation)
        store.saveReservationsToDisk()
        dismiss()
    }
}
