import SwiftUI

struct ReservationListView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService

    // MARK: - State
    @State private var searchDate = Date()
    @State private var filterPeople: Int? = nil
    @State private var filterStartDate: Date? = nil
    @State private var filterEndDate: Date? = nil
    @State private var selection = Set<UUID>() // Multi-select
    @State private var showingAddReservation = false
    @State private var showingNotesAlert = false
    @State private var notesToShow: String = ""
    @State private var currentReservation: Reservation? = nil
    @State private var selectedReservationID: UUID? = nil
    @State private var showTopControls: Bool = true

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            if showTopControls {
                filterSection
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: showTopControls)
            }
            ZStack {
                List(selection: $selection) {
                    ForEach(getFilteredReservations()) { reservation in
                        ReservationRowView(
                            reservation: reservation,
                            notesAlertShown: $showingNotesAlert,
                            notesToShow: $notesToShow,
                            selectedReservationID: $selectedReservationID,
                            onTap: {
                                handleRowTap(reservation)
                            },
                            onDelete: {
                                handleDelete(reservation)
                            },
                            onEdit: {
                                currentReservation = reservation
                            }
                        )
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("Tutte le prenotazioni")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showTopControls.toggle()
                    }
                }) {
                    Image(systemName: showTopControls ? "chevron.up" : "chevron.down")
                        .imageScale(.large)
                }
                .accessibilityLabel(showTopControls ? "Hide Controls" : "Show Controls")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddReservation = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Generate Debug Data") {
                    store.setReservations([]) // Clear existing reservations
                    generateDebugData()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Force Debug Data") {
                    generateDebugData(force: true)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save Debug Data") {
                    saveDebugData()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Flush Caches") {
                        flushCaches()
                    }
                }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddReservation) {
            AddReservationView()
                .environmentObject(store)
                .environmentObject(reservationService)
        }
        .sheet(item: $currentReservation) { reservation in
            EditReservationView(reservation: reservation)
                .environmentObject(store)
                .environmentObject(reservationService)
        }
        .alert("Notes", isPresented: $showingNotesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notesToShow)
        }
        .toolbarBackground(Material.ultraThin, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Generate Debug Data
    private func generateDebugData(force: Bool = false, shouldSave: Bool = true) {
        Task {
            let testReservations = reservationService.generateReservations(for: 10, reservationsPerDay: 40, force: force)
            store.setReservations(testReservations)
            reservationService.simulateUserActions(actionCount: 1000)
        }
    }
    
    private func saveDebugData() {
        reservationService.saveReservationsToDisk(includeMock: true)
        print("Debug data saved to disk.")
    }

    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(alignment: .leading) {
            // Guest number filter
            HStack {
                if filterPeople == nil {
                    Button("Filtra per Numero Ospiti...") {
                        withAnimation {
                            filterPeople = 1
                        }
                    }
                    .padding(.horizontal)
                    .padding(.leading, 8.5)
                    .frame(height: 40)
                }

                Spacer()

                if let unwrappedFilterPeople = filterPeople {
                    Stepper(value: Binding(
                        get: { unwrappedFilterPeople },
                        set: { newValue in
                            filterPeople = newValue
                        }
                    ), in: 1...14, step: 1) {
                        let label = (unwrappedFilterPeople < 14)
                            ? "Filtra per Numero Ospiti: da \(unwrappedFilterPeople) in su"
                            : "Filtra per Numero Ospiti: \(unwrappedFilterPeople)"
                        Text(label)
                            .frame(height: 40)
                    }

                    Button("Rimuovi Filtro") {
                        withAnimation {
                            filterPeople = nil
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .padding(.bottom, 8)

            // Date interval filter
            VStack(alignment: .leading) {
                if filterStartDate == nil || filterEndDate == nil {
                    Button("Filtra per Intervallo di Date...") {
                        withAnimation {
                            filterStartDate = Date()
                            filterEndDate = Date()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.leading, 8.5)
                    .frame(height: 40)
                }

                if let startDate = filterStartDate, let endDate = filterEndDate {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Da data:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            DatePicker("",
                                       selection: Binding(
                                           get: { startDate },
                                           set: { newValue in filterStartDate = newValue }
                                       ),
                                       displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }

                        VStack(alignment: .leading) {
                            Text("A data:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            DatePicker("",
                                       selection: Binding(
                                           get: { endDate },
                                           set: { newValue in filterEndDate = newValue }
                                       ),
                                       displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }

                        Spacer()

                        Button("Rimuovi Filtro") {
                            withAnimation {
                                filterStartDate = nil
                                filterEndDate = nil
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MARK: - Filtering Logic
    private func getFilteredReservations() -> [Reservation] {
        let all = store.getReservations()
        print("All reservations count: \(all.count)")
        let filtered = store.getReservations().filter { reservation in
            var matchesFilter = true
            
            // Filter by date interval if set
            if let start = filterStartDate,
               let end = filterEndDate
            {
                guard let reservationDate = TimeHelpers.fullDate(from: reservation.dateString) else {
                    return false
                }
                matchesFilter = matchesFilter && (reservationDate >= start && reservationDate <= end)
            }

            // Filter by guest number if set
            if let filterP = filterPeople {
                matchesFilter = matchesFilter && (reservation.numberOfPersons == filterP)
            }
            
            return matchesFilter
        }
        
        print("Filtered reservations count: \(filtered.count)")
        return store.reservations
    }

    // MARK: - Delete
    private func delete(at offsets: IndexSet) {
        reservationService.deleteReservations(at: offsets)
    }

    // MARK: - Row Tap Handler
    private func handleRowTap(_ reservation: Reservation) {
        guard selectedReservationID == nil else { return }
        selectedReservationID = reservation.id
        withAnimation {
            currentReservation = reservation
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedReservationID = nil
        }
    }

    // MARK: - Delete Handler from Context Menu
    private func handleDelete(_ reservation: Reservation) {
        if let idx = store.reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservationService.deleteReservations(at: IndexSet(integer: idx))
        }
    }
    
    // MARK: - Flush Caches
    private func flushCaches() {
        reservationService.flushAllCaches()
        print("Debug: Cache flush triggered.")
    }
}

// MARK: - ReservationRowView
/// A smaller subview that displays a single reservation row. This often helps reduce Swift's type-checking overhead.
struct ReservationRowView: View {
    let reservation: Reservation

    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var selectedReservationID: UUID?

    var onTap: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void

    var body: some View {
        // Make a local variable for table names
        let tableNames = reservation.tables.map(\.name).joined(separator: ", ")

        HStack {
            VStack(alignment: .leading) {
                Text("\(reservation.name) - \(reservation.numberOfPersons) pers.")
                    .font(.headline)
                Text("Telefono: \(reservation.phone)")
                    .font(.subheadline)
                Text("Tavolo: \(tableNames)")
                    .font(.subheadline)
                Text("Data: \(reservation.dateString)")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            Spacer()

            Button {
                if let notes = reservation.notes, !notes.isEmpty {
                    notesToShow = notes
                } else {
                    notesToShow = "(no further notes)"
                }
                notesAlertShown = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            selectedReservationID == reservation.id
                ? Color.gray.opacity(0.3)
                : Color.clear
        )
        .cornerRadius(8)
        .contentShape(Rectangle()) // The row is tappable
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button("Edit") {
                onEdit()
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    

    
}
