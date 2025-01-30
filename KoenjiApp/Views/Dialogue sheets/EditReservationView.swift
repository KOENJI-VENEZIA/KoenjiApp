import PhotosUI
import SwiftUI

struct EditReservationView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
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
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var activeAlert: AddReservationAlertType? = nil

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var reservationImageData: Data? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false

    var onClose: () -> Void

    var body: some View {
        NavigationView {
            Form {

                Section("Obbligatori") {
                    TextField("Nome", text: $reservation.name)
                    TextField("Contatto", text: $reservation.phone)
                        .keyboardType(.phonePad)
                    Stepper(
                        "Numero Clienti: \(reservation.numberOfPersons)",
                        value: $reservation.numberOfPersons, in: 2...14)

                    DatePicker(
                        "Seleziona Data", selection: $selectedDate, displayedComponents: .date
                    )
                    .onChange(of: selectedDate) { oldDate, newDate in
                        reservation.dateString = DateHelper.formatDate(newDate)
                    }
                    .onAppear {
                        // Initialize selectedDate based on reservation.dateString
                        if let reservationDate = reservation.normalizedDate {
                            selectedDate = reservationDate
                        }
                        print("Selected date: \(selectedDate)")
                    }

                    Picker("Tipologia", selection: $reservation.reservationType) {
                        ForEach(Reservation.ReservationType.allCases, id: \.self) { type in
                            Text(type.localized.capitalized).tag(type)
                        }
                    }
                    .onAppear {
                        adjustNotesForStatus()

                    }
                    .onChange(of: reservation.reservationType) {
                        adjustNotesForStatus()
                        if reservation.reservationType == .waitingList {
                            reservation.status = .na
                        }
                    }

                    Picker("Stato", selection: $reservation.status) {
                        ForEach(Reservation.ReservationStatus.allCases, id: \.self) { type in
                            Text(type.localized.capitalized).tag(type)
                        }
                    }
                    .onAppear {
                        adjustNotesForStatus()

                    }
                    .onChange(of: reservation.status) {
                        adjustNotesForStatus()
                    }

                    Picker("Accettazione", selection: $reservation.acceptance) {
                        ForEach(Reservation.Acceptance.allCases, id: \.self) { type in
                            Text(type.localized.capitalized).tag(type)
                        }
                    }
                    .onAppear {
                        adjustNotesForStatus()

                    }
                    .onChange(of: reservation.acceptance) {
                        adjustNotesForStatus()
                    }

                    Picker("Tavolo", selection: $selectedForcedTableID) {
                        Text("Auto Assegna").tag(nil as Int?)
                        ForEach(
                            store.tableAssignmentService.availableTables(
                                for: reservation,
                                reservations: store.getReservations(),
                                tables: layoutServices.getTables()
                            ), id: \.table.id
                        ) { entry in
                            Text(
                                entry.isCurrentlyAssigned
                                    ? "\(entry.table.name) (già assegnato)" : entry.table.name
                            )
                            .tag(entry.table.id as Int?)
                        }
                    }

                    Picker("Categoria", selection: $reservation.category) {
                        Text("Pranzo").tag(Reservation.ReservationCategory.lunch)
                        Text("Cena").tag(Reservation.ReservationCategory.dinner)
                        Text("Pomeriggio").tag(Reservation.ReservationCategory.noBookingZone)
                    }
                    .onChange(of: reservation.category) { adjustTimesForCategory() }

                    TimeSelectionView(
                        selectedTime: $reservation.startTime, category: reservation.category
                    )
                    .onChange(of: reservation.startTime) { oldStartTime, newStartTime in
                        reservation.endTime = TimeHelpers.calculateEndTime(
                            startTime: newStartTime, category: reservation.category)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    EndTimeSelectionView(
                        selectedTime: $reservation.endTime, category: reservation.category
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                }

                Section("Facoltativo: Immagine") {
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    showImageField.toggle()
                                }
                            }) {
                                Label(
                                    "",
                                    systemImage: showImageField ? "chevron.up" : "chevron.down")
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if !showImageField {
                                Group {
                                    if let reservationImage = reservation.image {
                                        ZStack {
                                            reservationImage
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 50, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.gray, lineWidth: 1)
                                                )
                                                .clipped()
                                                .transition(
                                                    .move(edge: .bottom).combined(with: .opacity)
                                                ) // Add transition
                                        }
                                    } else {
                                        Image(systemName: "photo.badge.plus")  // Placeholder image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                            .opacity(0.5)
                                            .padding(5)
                                            .transition(
                                                .move(edge: .bottom).combined(with: .opacity))  // Add transition
                                    }
                                }
                            }

                            Group {
                                if showImageField {
                                    if let reservationImage = reservation.image {
                                        ZStack {
                                            PhotosPicker(
                                                selection: $selectedPhotoItem,
                                                matching: .images,
                                                photoLibrary: .shared()
                                            ) {
                                                reservationImage
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 300, height: 300)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))  // Rounded corners
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.gray, lineWidth: 1)  // Optional border
                                                    )
                                                    .clipped()
                                                    .padding(5)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .transition(.move(edge: .bottom).combined(with: .opacity))  // Add transition
                                            
                                            Button(action: {
                                                withAnimation {
                                                    selectedPhotoItem = nil // Clear the image data
                                                    reservationImageData = nil
                                                    reservation.imageData = nil // Clear the image data in the reservation

                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.red) // Destructive color
                                                    .frame(width: 30, height: 30)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.gray, lineWidth: 1)
                                                        )
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .offset(x: 130, y: -130)
                                            .padding(5) // Add padding to position the button inside the corner
                                            .zIndex(2)
                                        }
                                    } else {
                                        PhotosPicker(
                                            selection: $selectedPhotoItem,
                                            matching: .images,
                                            photoLibrary: .shared()
                                        ) {
                                            Text("Scegli un'immagine...")
                                                .padding(5)
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .frame(height: 50)
                                        .buttonStyle(BorderlessButtonStyle())
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))  // Add transition
                                    }
                                }

                            }
                        }
                        .listRowBackground(Color.clear)  // Removes background
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.easeInOut(duration: 0.5), value: showImageField)  // Apply animation when `showImageField` changes
                }

                Section("Facoltativo: Note") {
                    TextEditor(text: $reservation.notes.orEmpty())
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Modifica - \(reservation.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        resCache.addOrUpdateReservation(reservation)
                        onClose()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { saveChanges() }
                }
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .mondayConfirmation:
                    return Alert(
                        title: Text("Attenzione!"),
                        message: Text(
                            "Stai cercando di prenotare di lunedì. Sei sicuro di voler continuare?"),
                        primaryButton: .destructive(Text("Annulla")),
                        secondaryButton: .default(Text("Prosegui")) {
                            performSaveReservation()
                        }
                    )

                case .error(let message):
                    return Alert(
                        title: Text("Errore:"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .onAppear {
                if let reservationData = reservation.imageData {
                    reservationImageData = reservationData
                }
                loadInitialDate()
                if let firstTable = reservation.tables.first {
                    selectedForcedTableID = firstTable.id

                }
                print(
                    store.tableAssignmentService.availableTables(
                        for: reservation,
                        reservations: store.getReservations(),
                        tables: layoutServices.getTables()
                    ))
                print("Selected Forced Table ID: \(String(describing: selectedForcedTableID))")

            }
            .onChange(of: selectedPhotoItem) { old, newItem in
                if let newItem {
                    Task {
                        do {
                            // Load the image as Data
                            if let data = try await newItem.loadTransferable(type: Data.self),
                                let uiImage = UIImage(data: data)
                            {
                                // Convert to SwiftUI Image and update
                                self.selectedImage = Image(uiImage: uiImage)

                                // Save the image to the reservation
                                reservation.imageData = data
                            }
                        } catch {
                            print("Error loading image: \(error)")
                        }
                    }
                } else {
                    reservation.imageData = nil
                }
            }
        }
        .background(.clear)
    }

    private func saveChanges() {
        guard validateInputs() else { return }

        guard let reservationStart = reservation.startTimeDate,
            let reservationEnd = reservation.endTimeDate else { return }

        for table in reservation.tables {
            layoutServices.unlockTable(
                tableID: table.id, start: reservationStart, end: reservationEnd)
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        // In the Gregorian calendar Sunday is 1, Monday is 2, etc.
        if weekday == 2 {  // Monday detected
            activeAlert = .mondayConfirmation
            return
        }

        performSaveReservation()

    }

    private func performSaveReservation() {
        if reservation.reservationType == .waitingList {
            reservation.tables.removeAll()

            reservationService.updateReservation(reservation)
            reservationService.updateActiveReservationAdjacencyCounts(for: reservation)
            

            print("Updated tables of \(reservation.name): \(reservation.tables)")
            print("Updated status of \(reservation.name): \(reservation.status)")

            onClose()
            dismiss()
        }

        if reservation.reservationType != .waitingList {
            let assignmentResult = layoutServices.assignTables(
                for: reservation, selectedTableID: selectedForcedTableID)
            switch assignmentResult {
            case .success(let assignedTables):
                reservation.tables = assignedTables
                reservationService.updateReservation(reservation)

                reservationService.updateActiveReservationAdjacencyCounts(for: reservation)

                onClose()
                dismiss()
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    activeAlert = .error("Non ci sono tavoli disponibili.")
                case .insufficientTables:
                    activeAlert = .error("Non ci sono abbastanza tavoli per la prenotazione.")
                case .tableNotFound:
                    activeAlert = .error("Tavolo selezionato non trovato.")
                case .tableLocked:
                    activeAlert = .error("Il tavolo scelto è occupato o bloccato.")
                case .unknown:
                    activeAlert = .error("Errore sconosciuto.")
                }
                return
            }
        }
    }

    private func adjustNotesForStatus() {
        // Define a pattern that finds our "tag" substrings, for example "[...];"
        let tagPattern = #"\[[^\]]*\];"#  // Match a "[", any number of non-"]", then "];"

        // Remove all existing tags from the notes:
        reservation.notes = reservation.notes?.replacingOccurrences(
            of: tagPattern, with: "", options: .regularExpression)

        // Optionally, remove trailing whitespace and add one space (if you need it)
        reservation.notes =
            (reservation.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") + " "

        // Determine the new tag to add based on selectedStatus.
        var newTag: String = ""
        switch reservation.status {
        case .canceled: newTag = "[cancellazione];"
        case .noShow: newTag = "[no show];"
        case .pending: newTag = "[in attesa];"
        case .showedUp: newTag = "[arrivati];"
        case .late: newTag = "[in ritardo];"
        case .na: newTag = ""
        }
        switch reservation.acceptance {
        case .confirmed: newTag = "[confermata];"
        case .toConfirm: newTag = "[da confermare];"
        }
        switch reservation.reservationType {
        case .inAdvance: newTag = "[prenotata];"
        case .walkIn: newTag = "[walk-in];"
        case .waitingList: newTag = "[waiting list];"

        }

        // Append the new tag.

        reservation.notes! += newTag
    }

    private func validateInputs() -> Bool {
        if reservation.name.trimmingCharacters(in: .whitespaces).isEmpty {
            activeAlert = .error("Il nome non può essere lasciato vuoto.")
            return false
        }
        if reservation.phone.trimmingCharacters(in: .whitespaces).isEmpty {
            activeAlert = .error("Il contatto non può essere lasciato vuoto.")
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
        selectedDate = reservation.normalizedDate ?? Date()
        print("Selected date: \(selectedDate)")

    }

}
