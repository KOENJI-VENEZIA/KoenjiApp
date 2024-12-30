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
    
    let forcedTable: TableModel?
    // Replace or add whatever states you need for your form
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var category: Reservation.ReservationCategory = .lunch
    @State private var startTime: String = "12:00"
    @State private var endTime: String = "13:45"
    @State private var notes: String = ""
    @State private var selectedDate: Date

    init(forcedTable: TableModel?, preselectedDate: Date = Date()) {
        self.forcedTable = forcedTable
        self._selectedDate = State(initialValue: preselectedDate)
    }
    
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

                    
                    
                    if category == .noBookingZone {
                        Text("Reservations cannot be created in 'No Booking Zone' times.")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }

                    // Date Picker and Day Display
                    DatePicker("Seleziona data", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    
                    Text(formattedDate())
                        .font(.headline)
                        .padding(.vertical, 4)
                    
                    Picker("Categoria", selection: $category) {
                        ForEach(Reservation.ReservationCategory.allCases, id: \.self) { cat in
                            if cat != .noBookingZone {
                                Text(cat.rawValue.capitalized).tag(cat)
                            }
                        }
                    }
                    .onChange(of: category) { _ in
                        adjustTimesForCategory()
                    }

                    if category != .noBookingZone {
                        TimeSelectionView(selectedTime: $startTime, category: category)
                            .onChange(of: startTime) { newStartTime in
                                endTime = TimeHelpers.calculateEndTime(startTime: newStartTime, category: category)
                            }

                        EndTimeSelectionView(selectedTime: $endTime, category: category)
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
    }
    
    private func saveReservation() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: selectedDate)

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
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        return formatter.string(from: selectedDate)
    }
}
