import SwiftUI

struct EditReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale // Access the current locale

    // MARK: - State
    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var shouldAssignTables: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

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

                    // Table Picker
                    Picker("Tavolo", selection: $selectedForcedTableID) {
                        Text("Auto").tag(nil as Int?) // Option to auto-assign tables
                        ForEach(store.availableTables(for: reservation)) { table in
                            Text(table.name).tag(Int?(table.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedForcedTableID) { newTableID in
                        if newTableID == nil {
                            // We switched from forced table to "Auto"
                            // We can re-run the store logic to get a new assignment
                            if let assigned = store.assignTables(for: reservation, selectedTableID: nil) {
                                reservation.tables = assigned
                            } else {
                                // handle error
                            }
                        } else {
                            // We switched from auto to a forced table
                            if let assigned = store.assignTables(for: reservation, selectedTableID: newTableID) {
                                reservation.tables = assigned
                            } else {
                                // handle error
                            }
                        }
                    }

                    // Category Picker
                    Picker("Categoria", selection: $reservation.category) {
                        Text("Pranzo").tag(Reservation.ReservationCategory.lunch)
                        Text("Cena").tag(Reservation.ReservationCategory.dinner)
                        Text("Aperitivo").tag(Reservation.ReservationCategory.noBookingZone)
                    }
                    .onChange(of: reservation.category) { _ in
                        adjustTimesForCategory()
                    }

                    // Acceptance Picker
                    Picker("Accettazione", selection: $reservation.acceptance) {
                        Text("Confermato").tag(Reservation.Acceptance.confirmed)
                        Text("Da confermare").tag(Reservation.Acceptance.toConfirm)
                    }

                    // Time Pickers
                    TimeSelectionView(selectedTime: $reservation.startTime, category: reservation.category)
                        .onChange(of: reservation.startTime) { newStartTime in
                            reservation.endTime = TimeHelpers.calculateEndTime(
                                startTime: newStartTime,
                                category: reservation.category
                            )
                        }

                    EndTimeSelectionView(
                        selectedTime: $reservation.endTime,
                        category: reservation.category
                    )
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                adjustTimesForCategory()
                loadInitialDate()

                // If there is already a table assigned, reflect it in the picker
                if let firstTable = reservation.tables.first {
                    selectedForcedTableID = firstTable.id
                }
            }
        }
        .italianLocale()
    }

    // MARK: - Save Changes
    private func saveChanges() {
        // 1) Validate
        guard validateInputs() else { return }

        // 2) Assign tables if needed
        if shouldAssignTables {
            // If user selected a specific table
            if let tableID = selectedForcedTableID {
                if let selectedTable = store.tables.first(where: { $0.id == tableID }) {
                    // Manual assignment
                    if store.isTableOccupied(
                        selectedTable,
                        date: TimeHelpers.fullDate(from: reservation.dateString)!,
                        startTimeString: reservation.startTime,
                        endTimeString: reservation.endTime,
                        excluding: reservation.id
                    ) {
                        // Table is occupied
                        alertMessage = "La tavola selezionata è già occupata."
                        showAlert = true
                        return
                    } else {
                        if let assigned = store.assignTablesManually(for: reservation, startingFrom: selectedTable) {
                            reservation.tables = assigned
                        } else {
                            alertMessage = "Impossibile assegnare le tavole selezionate."
                            showAlert = true
                            return
                        }
                    }
                } else {
                    // Selected table not found
                    alertMessage = "La tavola selezionata non esiste."
                    showAlert = true
                    return
                }
            } else {
                // Auto assign if "Auto" is selected
                if let assigned = store.assignTablesAutomatically(for: reservation) {
                    reservation.tables = assigned
                } else {
                    // Auto assignment failed
                    alertMessage = "Impossibile assegnare automaticamente le tavole."
                    showAlert = true
                    return
                }
            }
        } else {
            // No change in table selection; keep existing tables
            // (Optionally verify existing tables are still valid)
        }

        // 3) Update the reservation in the store
        store.updateReservation(reservation)
        dismiss()
    }

    // MARK: - Validation
    private func validateInputs() -> Bool {
        if reservation.name.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Il campo 'Nome' non può essere vuoto."
            showAlert = true
            return false
        }

        if reservation.phone.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Il campo 'Telefono' non può essere vuoto."
            showAlert = true
            return false
        }

        if reservation.numberOfPersons < 2 || reservation.numberOfPersons > 14 {
            alertMessage = "Il numero di ospiti deve essere compreso tra 2 e 14."
            showAlert = true
            return false
        }

        return true
    }

    // MARK: - Category Time Defaults
    private func adjustTimesForCategory() {
        switch reservation.category {
        case .lunch:
            reservation.startTime = "12:00"
            reservation.endTime = TimeHelpers.calculateEndTime(
                startTime: reservation.startTime,
                category: .lunch
            )
        case .dinner:
            reservation.startTime = "18:00"
            reservation.endTime = TimeHelpers.calculateEndTime(
                startTime: reservation.startTime,
                category: .dinner
            )
        case .noBookingZone:
            reservation.startTime = "09:00"
            reservation.endTime = TimeHelpers.calculateEndTime(
                startTime: reservation.startTime,
                category: .noBookingZone
            )
        }
    }

    // MARK: - Load Initial Date from Reservation
    private func loadInitialDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        selectedDate = formatter.date(from: reservation.dateString) ?? Date()
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
