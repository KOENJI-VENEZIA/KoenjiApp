import PhotosUI
import SwiftUI

struct AddReservationView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""

    @State private var endTimeString: String = "13:45"
    @State private var startTimeString: String = "12:00"

    @State private var selectedForcedTableID: Int? = nil


    @State private var isSaving = false

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false

    // MARK: - Bindings from parent
    @State var category: Reservation.ReservationCategory = .lunch
    @State var startTime: Date = Date()
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
    
    @State private var availableTables: [(table: TableModel, isCurrentlyAssigned: Bool)] = []

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {

                Section("Obbligatori") {
                    TextField("Nome", text: $name)
                    TextField("Contatto", text: $phone)
                        .keyboardType(.phonePad)
                    Stepper(
                        "Numero Clienti: \(numberOfPersons)",
                        value: $numberOfPersons,
                        in: 2...14)

                    DatePicker(
                        "Seleziona Data", selection: $appState.selectedDate, displayedComponents: .date
                    )
                    .onChange(of: appState.selectedDate) {
                        adjustTimesForCategory()
                    }

                    Picker("Tipologia", selection: $selectedStatus) {
                        ForEach(
                            [
                                ReservationOption.type(.waitingList),
                                ReservationOption.type(.walkIn),
                                ReservationOption.acceptance(.confirmed),
                                ReservationOption.acceptance(.toConfirm),
                            ], id: \.self
                        ) { option in
                            Text(option.title.capitalized).tag(option)
                        }
                    }
                    .onAppear {
                        adjustNotesForStatus()
                    }
                    .onChange(of: selectedStatus) {
                        adjustNotesForStatus()
                        if selectedStatus.asType == .waitingList {
                            status = .na
                        }
                    }

                    Picker("Tavolo", selection: $selectedForcedTableID) {
                        Text("Auto Assegna").tag(nil as Int?)
                        ForEach(availableTables, id: \.table.id) { entry in
                            Text(
                                entry.isCurrentlyAssigned
                                    ? "\(entry.table.name) (già assegnato)"
                                    : entry.table.name
                            )
                            .tag(entry.table.id as Int?)
                        }
                    }

                    Picker("Categoria", selection: $appState.selectedCategory) {
                        Text("Pranzo").tag(
                            Reservation.ReservationCategory.lunch)
                        Text("Cena").tag(
                            Reservation.ReservationCategory.dinner)
                        Text("Pomeriggio").tag(
                            Reservation.ReservationCategory.noBookingZone)
                    }
//                    .onAppear {
//                          DispatchQueue.main.async {
//                              appState.selectedCategory = .lunch
//                          }
//                      }
                    .onChange(of: appState.selectedCategory) { old, newValue in
                        print("Selected category:", newValue, "Type:", type(of: newValue))
                        adjustTimesForCategory()
                    }

                    TimeSelectionView(
                        selectedTime: $startTimeString,
                        category: appState.selectedCategory
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onChange(of: startTimeString) { _, newValue in
                        endTimeString = TimeHelpers.calculateEndTime(
                            startTime: newValue,
                            category: appState.selectedCategory
                        )
                    }

                    EndTimeSelectionView(
                        selectedTime: $endTimeString,
                        category: appState.selectedCategory
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
                                    if let selectedImage {
                                        ZStack {
                                            selectedImage
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
                                                    .move(edge: .bottom).combined(with: .opacity))  // Add transition

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
                            } else {
                                Group {
                                    if let selectedImage {
                                        ZStack {
                                            PhotosPicker(
                                                selection: $selectedPhotoItem,
                                                matching: .images,
                                                photoLibrary: .shared()
                                            ) {
                                                selectedImage
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
                                            .transition(
                                                .move(edge: .bottom).combined(with: .opacity))  // Add transition

                                            Button(action: {
                                                withAnimation {
                                                    selectedPhotoItem = nil  // Clear the image data
                                                }
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.red)  // Destructive color
                                                    .frame(width: 30, height: 30)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.gray, lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .offset(x: 130, y: -130)
                                            .padding(5)  // Add padding to position the button inside the corner
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
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
//            .background(.thinMaterial)
            .scrollContentBackground(.hidden)
            .navigationTitle("Nuova Prenotazione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        guard !isSaving else { return }
                        isSaving = true
                        saveReservation()
                    }
                    .disabled(category == .noBookingZone)
                }
            }
            .alert(item: $env.pushAlerts.activeAddAlert) { alertType in
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
            .sheet(isPresented: $showImagePicker) {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Select an Image")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .onAppear {
                startTime = appState.selectedDate
                print("Passed value: \(DateHelper.formatTime(startTime))")
                print("Start time before: \(startTimeString)")
                print("End time before: \(endTimeString)")
                // Initialize time strings if empty

                startTimeString = DateHelper.formatTime(startTime)
                endTimeString = TimeHelpers.calculateEndTime(
                    startTime: startTimeString,
                    category: appState.selectedCategory)

//                appState.selectedCategory = categoryForTimeInterval(time: startTime)
                availableTables = env.tableAssignment.availableTables(
                    for: createTemporaryReservation(),
                    reservations: env.store.getReservations(),
                    tables: env.layoutServices.getTables()
                )

                if passedTable != nil {
                    selectedForcedTableID = passedTable!.id
                }

                print("Start time after: \(startTimeString)")
                print("End time after: \(endTimeString)")

            }
//            .onChange(of: appState.selectedCategory) { old, new in
//                category = new
//            }
            .onChange(of: selectedPhotoItem) { old, newItem in
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                                let uiImage = UIImage(data: data)
                            {
                                selectedImage = Image(uiImage: uiImage)  // Update the displayed image
                            }
                        } catch {
                            print("Error loading image: \(error)")
                        }
                    }
                } else {
                    selectedImage = nil
                }
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
            dateString: DateHelper.formatDate(appState.selectedDate),
            category: appState.selectedCategory,
            startTime: startTimeString,
            endTime: endTimeString,
            acceptance: selectedStatus.asAcceptance,
            status: status,
            reservationType: selectedStatus.asType,
            group: group,
            notes: notes.isEmpty ? nil : notes,
            tables: [],
            imageData: imageData
        )
    }

    private func adjustTimesForCategory() {
        switch category {
        case .lunch:
            startTimeString = "12:00"
        case .dinner:
            startTimeString = "18:00"
        case .noBookingZone:
            startTimeString = DateHelper.formatTime(startTime)
        }
        endTimeString = TimeHelpers.calculateEndTime(
            startTime: startTimeString,
            category: appState.selectedCategory
        )
    }

    private func adjustNotesForStatus() {
        // Define a pattern that finds our "tag" substrings, for example "[...];"
        let tagPattern = #"\[[^\]]*\];"#  // Match a "[", any number of non-"]", then "];"

        // Remove all existing tags from the notes:
        notes = notes.replacingOccurrences(of: tagPattern, with: "", options: .regularExpression)

        // Optionally, remove trailing whitespace and add one space (if you need it)
        notes = notes.trimmingCharacters(in: .whitespacesAndNewlines) + " "

        // Determine the new tag to add based on selectedStatus.
        var newTag: String = ""
        switch selectedStatus {
        case .status(let status):
            switch status {
            case .canceled: newTag = "[cancellazione];"
            case .noShow: newTag = "[no show];"
            case .pending: newTag = "[in attesa];"
            case .showedUp: newTag = "[arrivati];"
            case .late: newTag = "[in ritardo];"
            case .toHandle: newTag = "[da sistemare];"
            case .deleted: newTag = "[eliminata];"
            case .na: newTag = "[N/A]"
            }
        case .acceptance(let acceptance):
            switch acceptance {
            case .confirmed: newTag = "[confermata];"
            case .toConfirm: newTag = "[da confermare];"
            case .na: newTag = "[N/A]"
            }
        case .type(let type):
            switch type {
            case .inAdvance: newTag = "[prenotata];"
            case .walkIn: newTag = "[walk-in];"
            case .waitingList: newTag = "[waiting list];"
            case .na: newTag = "[N/A]"
            }
        }

        // Append the new tag.
        notes += newTag
    }

    private func categoryForTimeInterval(time: Date) -> Reservation.ReservationCategory {

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        switch hour {
        case 12..<15:  // Lunch hours
            return .lunch
        case 18..<23:  // Dinner hours
            return .dinner
        default:  // Default to no booking zone for other hours
            return .noBookingZone
        }

    }

    private func saveReservation() {
        guard validateInputs() else {
            isSaving = false
            return
        }

        let weekday = Calendar.current.component(.weekday, from: appState.selectedDate)
        if weekday == 2 {  // Monday
            env.pushAlerts.activeAddAlert = .mondayConfirmation
            isSaving = false
            return
        }

        performSaveReservation()
    }

    private func validateInputs() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            env.pushAlerts.activeAddAlert = .error("Il nome non può essere lasciato vuoto.")
            return false
        }
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            env.pushAlerts.activeAddAlert = .error("Il contatto non può essere lasciato vuoto.")
            return false
        }
        return true
    }

    private func performSaveReservation() {
        var newReservation = createTemporaryReservation()
        if newReservation.reservationType == .waitingList || newReservation.status == .canceled || newReservation.status == .deleted || newReservation.status == .toHandle {
            DispatchQueue.main.async {
                newReservation.tables = []
                checkBeforeSaving(newReservation: newReservation)
            }
            isSaving = false
            onAdded(newReservation)
            dismiss()
            return
        } else {
            let assignmentResult = env.layoutServices.assignTables(
                for: newReservation, selectedTableID: selectedForcedTableID)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
                    // do actual saving logic here
                    newReservation.tables = assignedTables
                    checkBeforeSaving(newReservation: newReservation)
                }
                isSaving = false
                onAdded(newReservation)
                dismiss()
                return
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    env.pushAlerts.activeAddAlert = .error("Non ci sono tavoli disponibili.")
                case .insufficientTables:
                    env.pushAlerts.activeAddAlert = .error("Non ci sono abbastanza tavoli per la prenotazione.")
                case .tableNotFound:
                    env.pushAlerts.activeAddAlert = .error("Tavolo selezionato non trovato.")
                case .tableLocked:
                    env.pushAlerts.activeAddAlert = .error("Il tavolo scelto è occupato o bloccato.")
                case .unknown:
                    env.pushAlerts.activeAddAlert = .error("Errore sconosciuto.")
                }
                return
            }
        }
    }
    
    private func checkBeforeSaving(newReservation: Reservation) {
        env.reservationService.automaticBackup()
        let localBackupTimestamp = Date() // or the timestamp of your local data
        env.backupService.uploadBackupWithConflictCheck(fileURL: env.backupService.localBackupFileURL ?? nil,
          localTimestamp: localBackupTimestamp,
        alertManager: env.pushAlerts) { result in
            switch result {
            case .success:
                // Proceed with saving to disk and any further actions
                env.resCache.addOrUpdateReservation(newReservation)
                env.store.finalizeReservation(newReservation)
                env.reservationService.saveReservationsToDisk(includeMock: true)
                print("Backup uploaded successfully.")
            case .failure(let error):
                // The alert manager has been updated; you can also handle error logging here.
                print("Backup upload failed: \(error.localizedDescription)")
            }
        }
    }

}

enum ReservationOption: Hashable {
    case status(Reservation.ReservationStatus)
    case type(Reservation.ReservationType)
    case acceptance(Reservation.Acceptance)

    // Optionally, provide a computed property for a localized title:
    var title: String {
        switch self {
        case .status(let status):
            switch status {
            case .noShow:
                return "no show"
            case .showedUp:
                return "arrivati"
            case .canceled:
                return "cancellazione"
            case .pending:
                return "in attesa"
            case .late:
                return "in ritardo"
            case .na:
                return "N/A"
            case .toHandle:
                return "in sospeso"
            case .deleted:
                return "eliminata"
            }
        case .type(let type):
            switch type {
            case .walkIn:
                return "walk-in"
            case .inAdvance:
                return "prenotata"
            case .waitingList:
                return "waiting list"
            case .na:
                return "n/a"
            }
        case .acceptance(let acceptance):
            switch acceptance {
            case .confirmed:
                return "confermata"
            case .toConfirm:
                return "da confermare"
            case .na:
                return "n/a"
            }
        }
    }
}

extension ReservationOption {
    var asStatus: Reservation.ReservationStatus {
        if case .status(let status) = self {
            return status
        }
        // Provide a default if the current selection isn’t a status.
        return .pending
    }

    var asAcceptance: Reservation.Acceptance {
        if case .acceptance(let acceptance) = self {
            return acceptance
        }
        // Provide a default if the current selection isn’t acceptance.
        return .toConfirm
    }

    var asType: Reservation.ReservationType {
        if case .type(let type) = self {
            return type
        }
        // Provide a default if the current selection isn’t a type.
        return .inAdvance
    }
}


