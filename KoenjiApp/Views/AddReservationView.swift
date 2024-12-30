//
//  AddReservationView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.dismiss) var dismiss
    
    let selectedDate: Date
    let forcedTable: TableModel?
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var category: Reservation.ReservationCategory = .lunch
    @State private var startTime: String = "12:00"
    @State private var endTime: String = "13:45"
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Obbligatori") {
                    TextField("Nome", text: $name)
                    TextField("Telefono (+XX XXXXXXXXXX...)", text: $phone)
                        .keyboardType(.phonePad)

                    Stepper("Numero ospiti: \(numberOfPersons)",
                            value: $numberOfPersons,
                            in: 2...14)

                    Picker("Categoria", selection: $category) {
                        ForEach(Reservation.ReservationCategory.allCases, id: \.self) { cat in
                            if cat != .noBookingZone {
                                Text(cat.rawValue.capitalized).tag(cat)
                            }
                        }
                    }
                    
                    if category == .noBookingZone {
                        Text("Reservations cannot be created in 'No Booking Zone' times.")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }

                    if category != .noBookingZone {
                        TimeSelectionView(selectedTime: $startTime, category: category)
                            .onChange(of: startTime) { newStartTime in
                                endTime = TimeHelpers.calculateEndTime(startTime: newStartTime, category: category)
                            }

                        EndTimeSelectionView(selectedTime: $endTime, category: category)
                    } else {
                        Text("Impossibile inserire prenotazioni in questa categoria.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section("Facoltativo") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Nuova Prenotazione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveReservation()
                    }
                    .disabled(category == .noBookingZone)
                }
            }
        }
        .onAppear {
            adjustTimesForCategory()
        }
        .onChange(of: startTime) { newStartTime in
            guard !newStartTime.isEmpty else { return }
            endTime = TimeHelpers.calculateEndTime(startTime: newStartTime, category: category)
        }
        .onChange(of: category) { newCategory in
            adjustTimesForCategory()
        }
    }

    private func saveReservation() {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        let dateString = df.string(from: selectedDate)

        store.addReservation(
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            date: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            notes: notes.isEmpty ? nil : notes,
            forcedTable: forcedTable
        )

        store.saveReservationsToDisk()
        dismiss()
    }

    private func adjustTimesForCategory() {
        switch category {
        case .lunch:
            startTime = "12:00"
            endTime = TimeHelpers.calculateEndTime(startTime: startTime, category: .lunch)
        case .dinner:
            startTime = "18:00"
            endTime = TimeHelpers.calculateEndTime(startTime: startTime, category: .dinner)
        case .noBookingZone:
            startTime = "09:00"
            endTime = TimeHelpers.calculateEndTime(startTime: startTime, category: .noBookingZone)
        }
    }
}
