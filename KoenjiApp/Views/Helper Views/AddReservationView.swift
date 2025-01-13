import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""
    
    @State private var endTimeString: String = ""
    @State private var startTimeString: String = ""
    
    @State private var selectedForcedTableID: Int? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var isSaving = false

    // MARK: - Bindings from parent
    @Binding var category: Reservation.ReservationCategory?
    @Binding var selectedDate: Date
    @Binding var startTime: Date
    

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section("Required") {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    Stepper("Number of Guests: \(numberOfPersons)",
                            value: $numberOfPersons,
                            in: 2...14)

                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) {
                            adjustTimesForCategory()
                        }

                    Picker("Table", selection: $selectedForcedTableID) {
                        Text("Auto Assign").tag(nil as Int?)
                        ForEach(store.tableAssignmentService.availableTables(
                            for: createTemporaryReservation(),
                            reservations: store.getReservations(),
                            tables: store.getTables()
                        ), id: \.table.id) { entry in
                            Text(entry.isCurrentlyAssigned
                                 ? "\(entry.table.name) (currently assigned)"
                                 : entry.table.name
                            )
                            .tag(entry.table.id as Int?)
                        }
                    }

                    Picker("Category", selection: $category) {
                        Text("Lunch").tag(Reservation.ReservationCategory.lunch as Reservation.ReservationCategory?)
                        Text("Dinner").tag(Reservation.ReservationCategory.dinner as Reservation.ReservationCategory?)
                        Text("No Booking").tag(Reservation.ReservationCategory.noBookingZone as Reservation.ReservationCategory?)
                    }
                    .onChange(of: category) {
                        adjustTimesForCategory()
                    }

                    TimeSelectionView(
                        selectedTime: $startTimeString,
                        category: category ?? .lunch
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onChange(of: startTimeString) { _, newValue in
                        endTimeString = TimeHelpers.calculateEndTime(
                            startTime: newValue,
                            category: category ?? .lunch
                        )
                    }

                    EndTimeSelectionView(
                        selectedTime: $endTimeString,
                        category: category ?? .lunch
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                }

                Section("Optional") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Reservation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !isSaving else { return }
                        isSaving = true
                        saveReservation()
                    }
                    .disabled(category == .noBookingZone)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Initialize time strings if empty
                if startTimeString.isEmpty {
                    startTimeString = DateHelper.formatTime(startTime)
                    category = categoryForTimeInterval(time: startTime)
                }
                if endTimeString.isEmpty {
                    endTimeString = TimeHelpers.calculateEndTime(
                        startTime: startTimeString,
                        category: category ?? .lunch
                    )
                }
                
                category = categoryForTimeInterval(time: startTime)
            }
        }
    }

    // MARK: - Helpers

    private func createTemporaryReservation() -> Reservation {
        Reservation(
            id: UUID(),
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: DateHelper.formatFullDate(selectedDate),
            category: category ?? .lunch,
            startTime: startTimeString,
            endTime: endTimeString,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes.isEmpty ? nil : notes,
            tables: []
        )
    }

    private func adjustTimesForCategory() {
        switch category ?? .lunch {
        case .lunch:
            startTimeString = "12:00"
        case .dinner:
            startTimeString = "18:00"
        case .noBookingZone:
            startTimeString = DateHelper.formatTime(startTime)
        }
        endTimeString = TimeHelpers.calculateEndTime(
            startTime: startTimeString,
            category: category ?? .lunch
        )
    }
    
    private func categoryForTimeInterval(time: Date) -> Reservation.ReservationCategory {
    

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        switch hour {
        case 12..<15: // Lunch hours
            return .lunch
        case 18..<23: // Dinner hours
            return .dinner
        default: // Default to no booking zone for other hours
            return .noBookingZone
        }
        
    }

    private func saveReservation() {
        guard validateInputs() else {
            isSaving = false
            return
        }

        let newReservation = createTemporaryReservation()

        if let assignedTables = store.assignTables(for: newReservation, selectedTableID: selectedForcedTableID) {
            DispatchQueue.main.async {
                // do actual saving logic here
                isSaving = false
                dismiss()
            }
        } else {
            alertMessage = selectedForcedTableID != nil
                ? "Could not assign selected table."
                : "Could not auto-assign tables."
            showAlert = true
            isSaving = false
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
}
