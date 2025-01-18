import SwiftUI

struct EditReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale

    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    var onClose: () -> Void


    var body: some View {
        NavigationView {
            Form {
                Section("Required") {
                    TextField("Name", text: $reservation.name)
                    TextField("Phone", text: $reservation.phone)
                        .keyboardType(.phonePad)
                    Stepper("Guests: \(reservation.numberOfPersons)", value: $reservation.numberOfPersons, in: 2...14)

                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { oldDate, newDate in
                            reservation.dateString = DateHelper.formatDate(newDate)
                        }
                        .onAppear {
                            // Initialize selectedDate based on reservation.dateString
                            if let reservationDate = DateHelper.parseDate(reservation.dateString) {
                                selectedDate = reservationDate
                            }
                        }

                    
                    Picker("Table", selection: $selectedForcedTableID) {
                        Text("Auto Assign").tag(nil as Int?)
                        ForEach(store.tableAssignmentService.availableTables(
                            for: reservation,
                            reservations: store.getReservations(),
                            tables: layoutServices.getTables()
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
                    .onChange(of: reservation.category) { adjustTimesForCategory() }

                    TimeSelectionView(selectedTime: $reservation.startTime, category: reservation.category)
                        .onChange(of: reservation.startTime) { oldStartTime, newStartTime in
                            reservation.endTime = TimeHelpers.calculateEndTime(startTime: newStartTime, category: reservation.category)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                    EndTimeSelectionView(selectedTime: $reservation.endTime, category: reservation.category)
                        .frame(maxWidth: .infinity, alignment: .center)

                }

                Section("Notes") {
                    TextEditor(text: $reservation.notes.orEmpty())
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Reservation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.populateActiveCache(for: reservation)
                        onClose()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadInitialDate()
                if let firstTable = reservation.tables.first {
                    selectedForcedTableID = firstTable.id
                
                }
                print(store.tableAssignmentService.availableTables(
                    for: reservation,
                    reservations: store.getReservations(),
                    tables: layoutServices.getTables()
                ))
                print("Selected Forced Table ID: \(String(describing: selectedForcedTableID))")

            }
        }
    }
    

    private func saveChanges() {
        guard validateInputs() else { return }
        
        for table in reservation.tables {
            layoutServices.unlockTable(table.id)
        }
        
        if let assignedTables = layoutServices.assignTables(for: reservation, selectedTableID: selectedForcedTableID) {
            reservation.tables = assignedTables
            reservationService.updateReservation(reservation)

            reservationService.updateActiveReservationAdjacencyCounts(for: reservation)

            onClose()
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
            reservation.startTime = DateHelper.formatTime(currentTime)
            reservation.endTime = TimeHelpers.calculateEndTime(
                startTime: DateHelper.formatTime(currentTime),
                category: reservation.category
            )
        }
    }

    private func loadInitialDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        selectedDate = formatter.date(from: reservation.dateString) ?? Date()
    }

   
}
