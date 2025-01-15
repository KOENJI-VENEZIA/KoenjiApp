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
    @State private var showingNotesAlert = false // Controls visibility
    @State private var isAnimating = false      // Controls animation
    @State private var notesToShow: String = ""
    @State private var currentReservation: Reservation? = nil
    @State private var selectedReservationID: UUID? = nil
    @State private var showTopControls: Bool = false
    @State private var isFiltered: Bool = false
    @State private var daysToSimulate: Int = 5
    @State private var showingDebugConfig: Bool = false
    @State private var showingResetConfirmation = false
    @State private var shouldReopenDebugConfig = false
    @State private var selectedReservation: Reservation?
    @State private var popoverPosition: CGRect = .zero
    @State private var currentTime: Date = Date()
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: Reservation.ReservationCategory? = .lunch
    
    @State private var showInspector: Bool = false       // Controls Inspector visibility
    @State private var showingFilters = false

    @State private var sidebarDefault: Color = Color.sidebar_dinner // Default color

    @State private var sortOption: SortOption? = .removeSorting // Default to nil (not sorted)
    private var isSorted: Bool {
        sortOption != .removeSorting
    }

    enum SortOption: String, CaseIterable {
        case alphabetically = "Alphabetically"
        case chronologically = "Chronologically"
        case byNumberOfPeople = "By Number of People"
        case removeSorting = "No Sorting"
    }

    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            // Reservation List
            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(getFilteredReservations()) { reservation in
                        ReservationRowView(
                            reservation: reservation,
                            notesAlertShown: $showingNotesAlert,
                            notesToShow: $notesToShow,
                            selectedReservationID: $selectedReservationID,
                            currentReservation: $currentReservation,
                            onTap: {
                                handleEditTap(reservation)
                            },
                            onDelete: {
                                handleDelete(reservation)
                            },
                            onEdit: {
                                currentReservation = reservation
                            },
                            onInfoTap: {
                                selectedReservationID = reservation.id
                                withAnimation {
                                    isAnimating = true
                                    showInspector = true
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) // Adjust padding for better row fit
                    }
                    .onDelete(perform: delete)
                }
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 16) // Adds scrolling padding at the top
                }
                .gesture (
                    TapGesture(count: 1)
                        .onEnded {
                            selectedReservationID = nil
                        }
                )
                .allowsHitTesting(!showingNotesAlert) // Disable interaction with rows when the popover is visible
            }
            .frame(maxWidth: selectedReservation == nil ? .infinity : UIScreen.main.bounds.width * 0.6) // Resize list dynamically
        }
        
        .inspector(isPresented: $showInspector) { // Show Inspector if a reservation is selected
            if let selectedID = selectedReservationID {
                
                ZStack {

                    ReservationInfoCard(
                        reservationID: selectedID,
                        onClose: {
                            showInspector = false
                            selectedReservationID = nil
                        },
                        onEdit: {
                            // If you want to open Edit Reservation, pass the ID
                            // or fetch from the store.
                            if let reservation = store.reservations.first(where: { $0.id == selectedID }) {
                                handleEditTap(reservation)
                            }
                        }
                    )
                    .environmentObject(store) // So inside InfoCard, we can access the updated reservations
                    .padding()
                }
            }
                
            
        }
                        
        .navigationTitle("Tutte le prenotazioni")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    
                    Text("Sort by...") // Add a title here
                           .font(.headline) // Optional: Make the title stand out
                           .padding(.bottom, 4) // Optional: Add spacing below the title
                    
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                            }
                        }
                    .pickerStyle(.inline) // Optional: Use inline style for better layout

                } label: {
                    Image(systemName: isSorted ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
                        .imageScale(.large)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {

                Button(action: {
                    showingFilters = true
                }) {
                    Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .imageScale(.large)
                }
                .sheet(isPresented: $showingFilters) {
                    VStack(spacing: 16) {
                        Text("Filters")
                            .font(.title2)
                            .bold()
                            .padding(.top)

                        // Guest Number Filter
                        if let unwrappedFilterPeople = filterPeople {
                            Stepper(value: Binding(
                                get: { unwrappedFilterPeople },
                                set: { newValue in
                                    filterPeople = newValue
                                }
                            ), in: 1...14, step: 1) {
                                let label = (unwrappedFilterPeople < 14)
                                ? "Numero Ospiti: da \(unwrappedFilterPeople) in su"
                                : "Numero Ospiti: \(unwrappedFilterPeople)"
                                Text(label)
                                    .font(.headline)
                            }

                            Button("Rimuovi Filtro Numero Ospiti") {
                                withAnimation {
                                    filterPeople = nil
                                    if filterStartDate == nil && filterEndDate == nil {
                                        isFiltered = false
                                    }
                                }
                            }
                            .foregroundStyle(.red)
                        } else {
                            Button("Filtra per Numero Ospiti...") {
                                withAnimation {
                                    filterPeople = 1
                                    isFiltered = true
                                }
                            }
                            .font(.headline)
                        }

                        Divider()
                            .padding(.vertical)

                        // Date Interval Filter
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Da data:")
                                    .font(.headline)
                                DatePicker("",
                                           selection: Binding(
                                               get: { filterStartDate ?? Date() },
                                               set: { newValue in filterStartDate = newValue }
                                           ),
                                           displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }

                            VStack(alignment: .leading) {
                                Text("A data:")
                                    .font(.headline)
                                DatePicker("",
                                           selection: Binding(
                                               get: { filterEndDate ?? Date() },
                                               set: { newValue in filterEndDate = newValue }
                                           ),
                                           displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                        }

                        if filterStartDate != nil && filterEndDate != nil {
                            Button("Rimuovi Filtro Data") {
                                withAnimation {
                                    filterStartDate = nil
                                    filterEndDate = nil
                                    if filterPeople == nil {
                                        isFiltered = false
                                    }
                                }
                            }
                            .foregroundStyle(.red)
                        }


                        Button("Apply") {
                            showingFilters = false
                            isFiltered = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)
                        
                        
                    }
                    .padding(.horizontal)
                    .presentationDetents([.medium, .large]) // Medium and large detents for flexibility
                    .presentationDragIndicator(.visible)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddReservation = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Debug Config") {
                    showingDebugConfig = true
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddReservation) {
            AddReservationView(category: $selectedCategory, selectedDate: $selectedDate, startTime: $currentTime)
                .environmentObject(store)
                .environmentObject(reservationService)
        }
        .sheet(item: $currentReservation) { reservation in
            EditReservationView(reservation: reservation)
                .environmentObject(store)
                .environmentObject(reservationService)
        }
        .sheet(isPresented: $showingDebugConfig) {
            DebugConfigView(
                daysToSimulate: $daysToSimulate,
                onGenerate: {
                    generateDebugData()
                    saveDebugData()
                },
                onResetData: {
                    showingResetConfirmation = true // Show the alert first
                    shouldReopenDebugConfig = true // Mark for reopening if canceled
                },
                onSaveDebugData: {
                    saveDebugData()
                },
                onFlushCaches: {
                    flushCaches()
                },
                onParse: {
                    parseReservations()
                }
            )
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: .buttonPositionChanged,
                object: nil,
                queue: .main
            ) { notification in
                if let frame = notification.userInfo?["frame"] as? CGRect {
                    self.popoverPosition = frame
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .buttonPositionChanged, object: nil)
        }
        .alert(isPresented: $showingResetConfirmation) {
            Alert(
                title: Text("Reset All Data"),
                message: Text("Are you sure you want to delete all reservations and reset the app? This action cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    resetData()
                    shouldReopenDebugConfig = false // Ensure the sheet doesn't reopen after reset
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    if shouldReopenDebugConfig {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingDebugConfig = true
                        }
                    }
                }
            )
        }
        .toolbarBackground(Material.ultraThin, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
   
    
    func dismissInfoCard() {
        withAnimation {
            isAnimating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            selectedReservation = nil
        }
    }


    
    struct DebugConfigView: View {
        @Binding var daysToSimulate: Int
        var onGenerate: () -> Void
        var onResetData: () -> Void
        var onSaveDebugData: () -> Void
        var onFlushCaches: () -> Void
        var onParse: () -> Void

        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Simulation Parameters")) {
                        Stepper("Days to Simulate: \(daysToSimulate)", value: $daysToSimulate, in: 1...365)
                        Button("Generate Debug Data") {
                            onGenerate()
                            dismissView()
                        }
                    }
                    
                    Section(header: Text("Debug Tools")) {
                        Button(role: .destructive) {
                            onResetData()
                            dismissView()
                        } label: {
                            Label("Reset Data", systemImage: "trash")
                        }

                        Button {
                            onSaveDebugData()
                            dismissView()
                        } label: {
                            Label("Save Debug Data", systemImage: "square.and.arrow.down")
                        }

                        Button {
                            dismissView()
                            onFlushCaches()
                        } label: {
                            Label("Flush Caches", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            onParse()
                        } label: {
                            Label("Parse Reservations", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                .navigationBarTitle("Debug Config", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        dismissView()
                    }
                )
            }
        }

        private func dismissView() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.windows.first?.rootViewController?.dismiss(animated: true)
        }
        
        
    }


    // MARK: - Generate Debug Data
    private func generateDebugData(force: Bool = false) {
        Task {
            await reservationService.generateReservations(
                daysToSimulate: daysToSimulate
            )
            // breservationService.simulateUserActions(actionCount: 1000)
        }
    }
    
    private func saveDebugData() {
        
        reservationService.saveReservationsToDisk(includeMock: true)
        print("Debug data saved to disk.")
    }
    
    private func resetData() {
        store.setReservations([]) // Clear all reservations
        reservationService.clearAllData() // Custom method to reset any cached or stored data
        flushCaches()
        store.unlockAllTables()
        print("All data has been reset.")
    }
    
    private func parseReservations() {
        let reservations = store.reservations
        print("\(reservations)")
    }


    // MARK: - Filtering Logic
    private func getFilteredReservations() -> [Reservation] {
         let filtered = store.getReservations().filter { reservation in
             var matchesFilter = true

             if let start = filterStartDate, let end = filterEndDate {
                 guard let reservationDate = DateHelper.parseDate(reservation.dateString) else {
                     return false
                 }
                 matchesFilter = matchesFilter && (reservationDate >= start && reservationDate <= end)
             }

             if let filterP = filterPeople {
                 matchesFilter = matchesFilter && (reservation.numberOfPersons == filterP)
             }

             return matchesFilter
         }

         return sortReservations(filtered)
     }

    private func sortReservations(_ reservations: [Reservation]) -> [Reservation] {
        guard let sortOption = sortOption else {
            // Return unsorted reservations if sortOption is nil
            return reservations
        }

        switch sortOption {
        case .alphabetically:
            return reservations.sorted { $0.name < $1.name }
        case .chronologically:
            return reservations.sorted {
                DateHelper.combineDateAndTimeStrings(
                    dateString: $0.dateString,
                    timeString: $0.startTime
                ) <
                    DateHelper.combineDateAndTimeStrings(
                        dateString: $1.dateString,
                        timeString: $1.startTime
                    )
            }
        case .byNumberOfPeople:
            return reservations.sorted { $0.numberOfPersons < $1.numberOfPersons }
            
        case .removeSorting:
            return reservations
        }
    }

    // MARK: - Delete
    private func delete(at offsets: IndexSet) {
        reservationService.deleteReservations(at: offsets)
    }

    // MARK: - Row Tap Handler
    private func handleEditTap(_ reservation: Reservation) {
        withAnimation {
            currentReservation = reservation
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
    @Binding var currentReservation: Reservation?
    
    var onTap: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    var onInfoTap: () -> Void // Added here


    var body: some View {
        // Make a local variable for table names
        let duration = TimeHelpers.availableTimeString(endTime: reservation.endTime, startTime: reservation.startTime)
        
        HStack {
            VStack(alignment: .leading) {
                Text("\(reservation.name) - \(reservation.numberOfPersons) pers.")
                    .font(.headline)
                Text("Data: \(reservation.dateString)")
                    .font(.subheadline)
                Text("Orario: \(reservation.startTime) - \(reservation.endTime)")
                    .font(.subheadline)
                Text("Durata: \(duration ?? "Error")")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            Spacer()
            
            GeometryReader { geo in
                Button {
                    // Trigger onInfoTap and post button position
                    onInfoTap()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .buttonPositionChanged,
                            object: nil,
                            userInfo: ["frame": geo.frame(in: .global)] // Pass the button's global frame
                        )
                    }
                } label: {
                    Image(systemName: "info.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 40, height: 40) // Add a frame to ensure GeometryReader works as intended
        }
        .padding()
        .background(
            selectedReservationID == reservation.id || currentReservation == reservation
                ? Color.gray.opacity(0.3)
                : Color.clear
        )
        .cornerRadius(8)
        .contentShape(Rectangle()) // The row is tappable
        .onTapGesture(count: 2) {
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


struct ButtonPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension Notification.Name {
    static let buttonPositionChanged = Notification.Name("buttonPositionChanged")
}


