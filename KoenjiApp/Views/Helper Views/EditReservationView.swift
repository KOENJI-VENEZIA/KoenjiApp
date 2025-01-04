import SwiftUI

struct EditReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale

    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    

    var body: some View {
        NavigationView {
            Form {
                Section("Required") {
                    TextField("Name", text: $reservation.name)
                    TextField("Phone", text: $reservation.phone)
                        .keyboardType(.phonePad)
                    Stepper("Guests: \(reservation.numberOfPersons)", value: $reservation.numberOfPersons, in: 2...14)

                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) {
                            reservation.dateString = formatDate($0)
                        }

                    
                    Picker("Table", selection: $selectedForcedTableID) {
                        Text("Auto Assign").tag(nil as Int?)
                        ForEach(store.tableAssignmentService.availableTables(
                            for: reservation,
                            reservations: store.getReservations(),
                            tables: store.getTables()
                        ), id: \.table.id) { entry in
                            Text(entry.isCurrentlyAssigned ? "\(entry.table.name) (currently assigned)" : entry.table.name)
                                .tag(entry.table.id as Int?)
                        }
                    }


                    Picker("Category", selection: $reservation.category) {
                        Text("Lunch").tag(Reservation.ReservationCategory.lunch)
                        Text("Dinner").tag(Reservation.ReservationCategory.dinner)
                        Text("No Booking").tag(Reservation.ReservationCategory.noBookingZone)
                    }
                    .onChange(of: reservation.category) { _ in adjustTimesForCategory() }

                    TimeSelectionView(selectedTime: $reservation.startTime, category: reservation.category)
                        .onChange(of: reservation.startTime) {
                            reservation.endTime = TimeHelpers.calculateEndTime(startTime: $0, category: reservation.category)
                        }
                    EndTimeSelectionView(selectedTime: $reservation.endTime, category: reservation.category)
                }

                Section("Notes") {
                    TextEditor(text: $reservation.notes.orEmpty())
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Reservation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                adjustTimesForCategory()
                loadInitialDate()
                if let firstTable = reservation.tables.first {
                    selectedForcedTableID = firstTable.id
                
                }
                print(store.tableAssignmentService.availableTables(
                    for: reservation,
                    reservations: store.getReservations(),
                    tables: store.getTables()
                ))
                print("Selected Forced Table ID: \(selectedForcedTableID)")

            }
        }
    }
    

    private func saveChanges() {
        guard validateInputs() else { return }

        if let assignedTables = store.assignTables(for: reservation, selectedTableID: selectedForcedTableID) {
            reservation.tables = assignedTables
            store.updateReservation(reservation)
            dismiss()
        } else {
            alertMessage = "Table assignment failed."
            showAlert = true
        }
    }

    private func validateInputs() -> Bool {
        if reservation.name.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Name cannot be empty."
            showAlert = true
            return false
        }
        if reservation.phone.trimmingCharacters(in: .whitespaces).isEmpty {
            alertMessage = "Phone cannot be empty."
            showAlert = true
            return false
        }
        return true
    }

    private func adjustTimesForCategory() {
        switch reservation.category {
        case .lunch:
            reservation.startTime = "12:00"
            reservation.endTime = "13:45"
        case .dinner:
            reservation.startTime = "18:00"
            reservation.endTime = "20:45"
        case .noBookingZone:
            reservation.startTime = "09:00"
            reservation.endTime = "10:00"
        }
    }

    private func loadInitialDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        selectedDate = formatter.date(from: reservation.dateString) ?? Date()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}
