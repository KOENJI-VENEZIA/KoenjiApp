import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale

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

    @State private var selectedForcedTableID: Int? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    

    var body: some View {
        NavigationView {
            Form {
                Section("Required") {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    Stepper("Number of Guests: \(numberOfPersons)", value: $numberOfPersons, in: 2...14)
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { adjustTimesForCategory() }

                    Picker("Table", selection: $selectedForcedTableID) {
                        Text("Auto Assign").tag(nil as Int?)
                        ForEach(store.tableAssignmentService.availableTables(
                            for: createTemporaryReservation(),
                            reservations: store.getReservations(),
                            tables: store.getTables()
                        ), id: \.table.id) { entry in
                            Text(entry.isCurrentlyAssigned ? "\(entry.table.name) (currently assigned)" : entry.table.name)
                                .tag(entry.table.id as Int?)
                        }
                    }


                    Picker("Category", selection: $category) {
                        Text("Lunch").tag(Reservation.ReservationCategory.lunch)
                        Text("Dinner").tag(Reservation.ReservationCategory.dinner)
                        Text("No Booking").tag(Reservation.ReservationCategory.noBookingZone)
                    }
                    .onChange(of: category) { adjustTimesForCategory() }

                    TimeSelectionView(selectedTime: $startTime, category: category)
                        .onChange(of: startTime) { oldValue, newValue in
                            endTime = TimeHelpers.calculateEndTime(startTime: newValue, category: category)
                        }

                    EndTimeSelectionView(selectedTime: $endTime, category: category)
                }

                Section("Optional") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle("New Reservation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReservation() }
                        .disabled(category == .noBookingZone)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear { adjustTimesForCategory() }
        }
    }

    private func createTemporaryReservation() -> Reservation {
        return Reservation(
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
            tables: []
        )
    }

    private func saveReservation() {
        guard validateInputs() else { return }

        var newReservation = createTemporaryReservation()

        if let assignedTables = store.assignTables(for: newReservation, selectedTableID: selectedForcedTableID) {
            newReservation.tables = assignedTables
            reservationService.addReservation(newReservation)
            
            store.updateActiveReservationAdjacencyCounts(for: newReservation)

            dismiss()
        } else {
            alertMessage = selectedForcedTableID != nil ? "Could not assign selected table." : "Could not auto-assign tables."
            showAlert = true
        }
    }

    private func validateInputs() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Name cannot be empty."
            showAlert = true
            return false
        }
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Phone cannot be empty."
            showAlert = true
            return false
        }
        return true
    }

    private func adjustTimesForCategory() {
        switch category {
        case .lunch:
            startTime = "12:00"
        case .dinner:
            startTime = "18:00"
        case .noBookingZone:
            startTime = "09:00"
        }
        endTime = TimeHelpers.calculateEndTime(startTime: startTime, category: category)
    }

    private func formatDate(_ date: Date) -> String {
        return DateHelper.formatFullDate(date)
    }
}
