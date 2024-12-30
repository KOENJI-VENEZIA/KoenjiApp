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
    
    /// The date you want to use for the new reservation
    let selectedDate: Date
    
    /// (Optional) a table passed in from LayoutView. If this is nil,
    /// the user can pick a table or you can leave it empty.
    let forcedTable: TableModel?
    
    // Replace or add whatever states you need for your form
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var category: Reservation.ReservationCategory = .lunch
    @State private var startTime: String = "12:00" // Default start time
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
                        // Start Time Picker
                        TimeSelectionView(selectedTime: $startTime, category: category)
                            .onChange(of: startTime) { newStartTime in
                                endTime = TimeHelpers.calculateEndTime(startTime: newStartTime)
                            }

                        // End Time Picker
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
                    .disabled(category == .noBookingZone) // Disable for noBookingZone
                }
            }

            
        }
        .onAppear {
            // Automatically adjust default times based on the category
            adjustTimesForCategory()
        }
        .onChange(of: startTime) { newStartTime in
            guard !newStartTime.isEmpty else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            guard let time = formatter.date(from: newStartTime) else { return }

            let hour = Calendar.current.component(.hour, from: time)

            if hour >= 12 && hour < 15 {
                category = .lunch
            } else if hour >= 18 && hour <= 23 {
                category = .dinner
            } else {
                category = .noBookingZone
            }

            if category != .noBookingZone {
                endTime = TimeHelpers.calculateEndTime(startTime: newStartTime)
            }
        }

    }
    
    
    private func saveReservation() {
        // Convert `selectedDate` to "DD/MM/YYYY"
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        let dateString = df.string(from: selectedDate)

        // Add the new reservation to the store
        store.addReservation(
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            date: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            notes: notes.isEmpty ? nil : notes
        )

        // Assign tables to the last added reservation
        if let lastReservation = store.reservations.last {
            let startingTable = forcedTable ?? store.tables.first(where: {
                !store.isTableOccupied(
                    $0,
                    date: selectedDate, // Pass the date as is
                    startTimeString: startTime, // Pass startTime directly
                    endTimeString: endTime // Pass endTime directly
                )
            }) ?? store.tables.first! // Fallback to the first table if all are occupied

            print("Debug: Assigning tables for reservation \(lastReservation.id). Starting from table: \(startingTable.name)")

            store.assignTables(
                for: lastReservation.id,
                startingFrom: startingTable,
                numberOfPersons: numberOfPersons,
                dateString: dateString,
                startTimeString: startTime,
                endTimeString: endTime
            )

            // Debug assigned tables
            if let updatedReservation = store.reservations.first(where: { $0.id == lastReservation.id }) {
                print("Debug: Tables assigned to reservation \(lastReservation.id): \(updatedReservation.tables.map { $0.name })")
            }
        } else {
            print("Debug: Failed to find the last reservation for table assignment.")
        }

        // Save all reservations to disk
        store.saveReservationsToDisk()

        // Dismiss the sheet
        dismiss()
    }






    
    private func adjustTimesForCategory() {
        switch category {
        case .lunch:
            startTime = "12:00"
            endTime = TimeHelpers.calculateEndTime(startTime: startTime)
        case .dinner:
            startTime = "18:00"
            endTime = TimeHelpers.calculateEndTime(startTime: startTime)
        case .noBookingZone:
            startTime = ""
            endTime = ""
        }
    }

}
