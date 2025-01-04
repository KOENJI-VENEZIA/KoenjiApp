import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale // Access the current locale

    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var category: Reservation.ReservationCategory = .lunch
    @State private var startTime: String = "12:00"
    @State private var endTime: String = "13:45"
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""
    @State private var selectedDate: Date = Date()

    // Table Assignment States
    @State private var selectedForcedTableID: Int? = nil // Selected table ID or nil for auto assign
    @State private var shouldAssignTables: Bool = false // Determines if table assignment should occur
    @State private var showAlert: Bool = false // For error handling
    @State private var alertMessage: String = "" // Alert message
    


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

                    // Date Picker and Day Display
                    DatePicker("Seleziona data", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) { newDate in
                            // Update start and end times based on date change if needed
                        }

                    Text(store.formattedDate(date: selectedDate, locale: locale))
                        .font(.headline)
                        .padding(.vertical, 4)

                    // 📌 **Table Picker**
                    Picker("Table", selection: $selectedForcedTableID) {
                        Text("Auto Assign").tag(nil as Int?) // Option to auto-assign tables
                        ForEach(store.availableTables(for: createTemporaryReservation())) { table in
                            Text(table.name).tag(Int?(table.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedForcedTableID) { newTableID in
                        // 1) Build a fresh "temporary" Reservation object (same as your createTemporaryReservation logic)
                        //    to reflect the user's current choices (name, phone, date, category, etc.).
                        var tempReservation = Reservation(
                            id: UUID(),
                            name: name,
                            phone: phone,
                            numberOfPersons: numberOfPersons,
                            dateString: formatDate(selectedDate),
                            category: category,
                            startTime: startTime,
                            endTime: endTime,
                            acceptance: acceptance,
                            status: status,
                            reservationType: reservationType,
                            group: group,
                            notes: notes.isEmpty ? nil : notes,
                            tables: [],
                            creationDate: Date()
                        )

                        // 2) Attempt to assign tables (manual if newTableID != nil, auto if nil)
                        if let assignedTables = store.assignTables(for: tempReservation, selectedTableID: newTableID) {
                            // 3) If successful, update our local 'newReservation' with the newly assigned tables
                            tempReservation.tables = assignedTables
                            // Keep a local 'newReservation' state var if you want to reflect the final reservation
                            // the user will eventually save
                            // e.g. newReservation = tempReservation
                            // if you keep a local var 'newReservation' in your view, do that assignment here:
                            // newReservation = tempReservation

                            print("Debug: Successfully assigned: \(assignedTables.map { $0.name })")
                        } else {
                            // 4) If assignment fails, show an alert
                            alertMessage = newTableID != nil
                                ? "Impossibile assegnare la tavola selezionata."
                                : "Impossibile assegnare automaticamente le tavole."
                            showAlert = true
                        }
                    }

                    // Category Picker
                    Picker("Categoria", selection: $category) {
                        Text("Pranzo").tag(Reservation.ReservationCategory.lunch)
                        Text("Cena").tag(Reservation.ReservationCategory.dinner)
                        Text("Aperitivo").tag(Reservation.ReservationCategory.noBookingZone)
                    }
                    .onChange(of: category) { _ in
                        adjustTimesForCategory()
                    }

                    // Acceptance Picker
                    Picker("Accettazione", selection: $acceptance) {
                        Text("Confermato").tag(Reservation.Acceptance.confirmed)
                        Text("Da confermare").tag(Reservation.Acceptance.toConfirm)
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                adjustTimesForCategory()
            }
        }
    }

    // Helper to get the current selected table ID
    private func currentSelectedTableID() -> Int? {
        return selectedForcedTableID
    }

    // Creates a temporary Reservation object for availableTables calculation
    private func createTemporaryReservation() -> Reservation {
        return Reservation(
            id: UUID(), // Temporary ID
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: formatDate(selectedDate),
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes.isEmpty ? nil : notes,
            tables: [] // No tables assigned yet
        )
    }

    /// Validates user inputs before saving the reservation.
    private func validateInputs() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Il campo 'Nome' non può essere vuoto."
            showAlert = true
            return false
        }
        
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Il campo 'Telefono' non può essere vuoto."
            showAlert = true
            return false
        }
        
        if numberOfPersons < 2 || numberOfPersons > 14 {
            alertMessage = "Il numero di ospiti deve essere compreso tra 2 e 14."
            showAlert = true
            return false
        }
        
        // Add more validations as needed
        
        return true
    }

    /// Saves the reservation after assigning tables.
    private func saveReservation() {
        // Validate inputs
        guard validateInputs() else { return }

        // Create a new reservation object
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: selectedDate)

        var newReservation = Reservation(
            id: UUID(),
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes.isEmpty ? nil : notes,
            tables: [],
            creationDate: Date()
        )

        // Assign tables based on user selection
        if shouldAssignTables {
            if let assigned = store.assignTables(for: newReservation, selectedTableID: selectedForcedTableID) {
                newReservation.tables = assigned
            } else {
                // Assignment failed
                alertMessage = selectedForcedTableID != nil ? "Impossibile assegnare le tavole selezionate." : "Impossibile assegnare automaticamente le tavole."
                showAlert = true
                return
            }
        } else {
            // Default to auto assign if no change detected
            if let assigned = store.assignTablesAutomatically(for: newReservation) {
                newReservation.tables = assigned
            } else {
                // Auto assignment failed
                alertMessage = "Impossibile assegnare automaticamente le tavole."
                showAlert = true
                return
            }
        }

        // Add the reservation to the store
        store.addReservation(newReservation)
        // Save to disk
        // Dismiss the view
        dismiss()
    }

    /// Adjusts start and end times based on the selected category.
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

    /// Formats a Date object into a string.
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
