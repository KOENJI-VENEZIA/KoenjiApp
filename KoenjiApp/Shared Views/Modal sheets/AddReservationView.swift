import PhotosUI
import SwiftUI

struct AddReservationView: View {
    @AppStorage("deviceUUID") private var deviceUUID = ""

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
    @State var category: Reservation.ReservationCategory = .lunch
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
    
    @State private var availableTables: [(table: TableModel, isCurrentlyAssigned: Bool)] = []

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Main card content
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with name
                        TextField("Nome", text: $name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .textFieldStyle(.roundedBorder)
                        
                        // Status badges
                        HStack(spacing: 8) {
                            Menu {
                                ForEach([
                                    ReservationOption.type(.waitingList),
                                    ReservationOption.type(.walkIn),
                                    ReservationOption.acceptance(.confirmed),
                                    ReservationOption.acceptance(.toConfirm),
                                ], id: \.self) { option in
                                    Button(action: {
                                        selectedStatus = option
                                        adjustNotesForStatus()
                                    }) {
                                        Label(option.title.capitalized, systemImage: getStatusIcon(for: option))
                                    }
                                }
                            } label: {
                                statusBadge(status: selectedStatus)
                            }
                            
                            Menu {
                                ForEach(Reservation.ReservationCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        appState.selectedCategory = category
                                        adjustTimesForCategory()
                                    }) {
                                        Label(category.localized, systemImage: category == .lunch ? "sun.max.fill" : "moon.fill")
                                    }
                                }
                            } label: {
                                categoryBadge(category: appState.selectedCategory)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Primary info with icons in a grid
                        let columns = [GridItem(.adaptive(minimum: 180, maximum: .infinity), spacing: 12)]
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            editableDetailTag(
                                icon: "person.2.fill",
                                title: String(localized: "Persone"),
                                color: .blue
                            ) {
                                HStack {
                                    Text("\(numberOfPersons)")
                                        .font(.body)
                                    Spacer()
                                    Stepper("", value: $numberOfPersons, in: 2...14)
                                        .labelsHidden()
                                }
                            }
                            
                            editableDetailTag(
                                icon: "phone.fill",
                                title: String(localized: "Telefono"),
                                color: .green
                            ) {
                                TextField("Telefono", text: $phone)
                                    .keyboardType(.phonePad)
                            }
                            
                            editableDetailTag(
                                icon: "calendar",
                                title: String(localized: "Data"),
                                color: .orange
                            ) {
                                DatePicker("", selection: $appState.selectedDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            editableDetailTag(
                                icon: "clock.fill",
                                title: String(localized: "Dalle"),
                                color: .purple
                            ) {
                                Menu {
                                    ForEach(getTimeSlots(for: appState.selectedCategory), id: \.self) { time in
                                        Button(action: {
                                            startTimeString = time
                                            endTimeString = TimeHelpers.calculateEndTime(
                                                startTime: time,
                                                category: appState.selectedCategory
                                            )
                                        }) {
                                            Text(time)
                                        }
                                    }
                                } label: {
                                    Text(startTimeString)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            editableDetailTag(
                                icon: "tablecells",
                                title: String(localized: "Tavoli"),
                                color: .indigo
                            ) {
                                Picker("", selection: $selectedForcedTableID) {
                                    Text("Auto Assegna").tag(nil as Int?)
                                    ForEach(availableTables, id: \.table.id) { entry in
                                        Text(entry.isCurrentlyAssigned ? "\(entry.table.name) (già assegnato)" : entry.table.name)
                                            .tag(entry.table.id as Int?)
                                    }
                                }
                            }
                            
                            editableDetailTag(
                                icon: "clock.badge.checkmark",
                                title: String(localized: "Alle"),
                                color: .purple
                            ) {
                                Menu {
                                    ForEach(getEndTimeSlots(startTime: startTimeString, category: appState.selectedCategory), id: \.self) { time in
                                        Button(action: {
                                            endTimeString = time
                                        }) {
                                            Text(time)
                                        }
                                    }
                                } label: {
                                    Text(endTimeString)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                        // Notes section
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Note", systemImage: "note.text")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Image section
                        
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Immagine", systemImage: "photo")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        selectedImage
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: {
                                            self.selectedImage = nil
                                            self.selectedPhotoItem = nil
                                            self.imageData = nil
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                                .background(.white)
                                                .clipShape(Circle())
                                        }
                                        .padding(8)
                                    }
                                    
                                    PhotosPicker(
                                        selection: $selectedPhotoItem,
                                        matching: .images,
                                        photoLibrary: .shared()
                                    ) {
                                        Label(
                                            "Cambia immagine",
                                            systemImage: "photo.badge.plus"
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                } else {
                                    PhotosPicker(
                                        selection: $selectedPhotoItem,
                                        matching: .images,
                                        photoLibrary: .shared()
                                    ) {
                                        Label(
                                            "Aggiungi immagine",
                                            systemImage: "photo.badge.plus"
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            
                        }
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .navigationTitle("Nuova Prenotazione")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        updateSession()
                        dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        guard !isSaving else { return }
                        isSaving = true
                        updateSession()
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
                    
                case .editing:
                    return Alert(
                        title: Text("Attentione!"),
                        message: Text(env.pushAlerts.alertMessage),
                        dismissButton: .default(Text("Annulla"))
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
                
                adjustTimesForCategory()
                
                print("Start time before: \(startTimeString)")
                print("End time before: \(endTimeString)")
                // Initialize time strings if empty

               
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
                
                updateSession(true)

            }
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

    private func updateSession(_ isEditing: Bool = false) {
        if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
            session.isEditing = isEditing
            env.sessionService.upsertSession(session)
        }
    }
    
    private func validateEdit() {
        if SessionStore.shared.sessions.contains( where: {$0.isEditing == true && $0.uuid != deviceUUID}) {
            appState.canSave = false
            env.pushAlerts.alertMessage = String(localized: "Un altro utente sta effettuando modifiche. Impossibile salvare. Attendere.")
            env.pushAlerts.activeAddAlert = .editing
            
        } else {
            appState.canSave = true
        }
    }
    
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
        switch appState.selectedCategory {
        case .lunch:
            startTimeString = "12:00"
        case .dinner:
            startTimeString = "18:00"
        case .noBookingZone:
            startTimeString = DateHelper.formatTime(Date())
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
            case .canceled: newTag = String(localized: "[cancellazione];")
            case .noShow: newTag = String(localized: "[no show];")
            case .pending: newTag = String(localized: "[in attesa];")
            case .showedUp: newTag = String(localized: "[arrivati];")
            case .late: newTag = String(localized: "[in ritardo];")
            case .toHandle: newTag = String(localized: "[da sistemare];")
            case .deleted: newTag = String(localized: "[eliminata];")
            case .na: newTag = String(localized: "[N/A]")
            }
        case .acceptance(let acceptance):
            switch acceptance {
            case .confirmed: newTag = String(localized: "[confermata];")
            case .toConfirm: newTag = String(localized: "[da confermare];")
            case .na: newTag = String(localized: "[N/A]")
            }
        case .type(let type):
            switch type {
            case .inAdvance: newTag = String(localized: "[prenotata];")
            case .walkIn: newTag = String(localized: "[walk-in];")
            case .waitingList: newTag = String(localized: "[waiting list];")
            case .na: newTag = String(localized: "[N/A]")
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
        
        validateEdit()
        
        guard appState.canSave else {
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
            env.pushAlerts.activeAddAlert = .error(String(localized: "Il nome non può essere lasciato vuoto."))
            return false
        }
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            env.pushAlerts.activeAddAlert = .error(String(localized: "Il contatto non può essere lasciato vuoto."))
            return false
        }
        return true
    }

    private func performSaveReservation() {
        adjustNotesForStatus()
        var newReservation = createTemporaryReservation()
        if newReservation.reservationType == .waitingList || newReservation.status == .canceled || newReservation.status == .deleted || newReservation.status == .toHandle {
            newReservation.tables = []
            isSaving = false
            onAdded(newReservation)
            env.reservationService.addReservation(newReservation)
            dismiss()
            return
        } else {
            let assignmentResult = env.layoutServices.assignTables(
                for: newReservation, selectedTableID: selectedForcedTableID)
            switch assignmentResult {
            case .success(let assignedTables):
                newReservation.tables = assignedTables
                isSaving = false
                onAdded(newReservation)
                env.reservationService.addReservation(newReservation)
                dismiss()
                return
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    env.pushAlerts.activeAddAlert = .error(String(localized: "Non ci sono tavoli disponibili."))
                case .insufficientTables:
                    env.pushAlerts.activeAddAlert = .error(String(localized: "Non ci sono abbastanza tavoli per la prenotazione."))
                case .tableNotFound:
                    env.pushAlerts.activeAddAlert = .error(String(localized: "Tavolo selezionato non trovato."))
                case .tableLocked:
                    env.pushAlerts.activeAddAlert = .error(String(localized: "Il tavolo scelto è occupato o bloccato."))
                case .unknown:
                    env.pushAlerts.activeAddAlert = .error(String(localized: "Errore sconosciuto."))
                }
                return
            }
        }
    }
    
    private func editableDetailTag<Content: View>(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
                    .alignmentGuide(.firstTextBaseline) { d in
                        d[.bottom] - 3
                    }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            content()
                .frame(height: 32)
                .padding(.leading, 32)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusBadge(status: ReservationOption) -> some View {
        Label {
            Text(status.title.capitalized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: getStatusIcon(for: status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(getStatusColor(for: status).opacity(0.12))
        .foregroundColor(getStatusColor(for: status))
        .clipShape(Capsule())
    }
    
    private func categoryBadge(category: Reservation.ReservationCategory) -> some View {
        Label {
            Text(category.localized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: category == .lunch ? "sun.max.fill" : "moon.fill")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.12))
        .foregroundColor(category.color)
        .clipShape(Capsule())
    }
    
    private func getStatusIcon(for option: ReservationOption) -> String {
        switch option {
        case .type(.waitingList): return "person.3.sequence"
        case .type(.walkIn): return "figure.walk"
        case .type(.inAdvance): return "deskclock.fill"
        case .type(.na): return "circle.badge.questionmark.fill"
        case .acceptance(.confirmed): return "checkmark.circle.fill"
        case .acceptance(.toConfirm): return "clock.fill"
        case .status(.late): return "clock.badge.exclamationmark.fill"
        case .status(.noShow): return "questionmark.circle.fill"
        case .status(.toHandle): return "exclamationmark.triangle.fill"
        case .status(.deleted): return "xmark.bin.fill"
        case .status(.na): return "circle.badge.questionmark.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
    
    private func getStatusColor(for option: ReservationOption) -> Color {
        switch option {
        case .type(.waitingList): return .orange
        case .type(.walkIn): return .green
        case .acceptance(.confirmed): return .green
        case .acceptance(.toConfirm): return .orange
        default: return .gray
        }
    }

    private func getTimeSlots(for category: Reservation.ReservationCategory) -> [String] {
        switch category {
        case .lunch:
            return stride(from: 11, through: 15, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
        case .dinner:
            return stride(from: 18, through: 22, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
        case .noBookingZone:
            return stride(from: 0, through: 23, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
        }
    }
    
    private func getEndTimeSlots(startTime: String, category: Reservation.ReservationCategory) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime) else { return [] }
        
        let calendar = Calendar.current
        let endLimit: Date
        
        switch category {
        case .lunch:
            endLimit = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: start) ?? start
        case .dinner:
            endLimit = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: start) ?? start
        case .noBookingZone:
            endLimit = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
        }
        
        var timeSlots: [String] = []
        var currentTime = calendar.date(byAdding: .minute, value: 15, to: start) ?? start
        
        while currentTime <= endLimit {
            timeSlots.append(formatter.string(from: currentTime))
            currentTime = calendar.date(byAdding: .minute, value: 15, to: currentTime) ?? currentTime
        }
        
        return timeSlots
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
                return String(localized: "no show")
            case .showedUp:
                return String(localized: "arrivati")
            case .canceled:
                return String(localized: "cancellazione")
            case .pending:
                return String(localized: "in attesa")
            case .late:
                return String(localized: "in ritardo")
            case .na:
                return String(localized: "N/A")
            case .toHandle:
                return String(localized: "in sospeso")
            case .deleted:
                return String(localized: "eliminata")
            }
        case .type(let type):
            switch type {
            case .walkIn:
                return String(localized: "walk-in")
            case .inAdvance:
                return String(localized: "prenotata")
            case .waitingList:
                return String(localized: "waiting list")
            case .na:
                return String(localized: "n/a")
            }
        case .acceptance(let acceptance):
            switch acceptance {
            case .confirmed:
                return String(localized: "confermata")
            case .toConfirm:
                return String(localized: "da confermare")
            case .na:
                return String(localized: "n/a")
            }
        }
    }
}

extension ReservationOption {
    var asStatus: Reservation.ReservationStatus {
        if case .status(let status) = self {
            return status
        }
        // Provide a default if the current selection isn't a status.
        return .pending
    }

    var asAcceptance: Reservation.Acceptance {
        if case .acceptance(let acceptance) = self {
            return acceptance
        }
        // Provide a default if the current selection isn't acceptance.
        return .toConfirm
    }

    var asType: Reservation.ReservationType {
        if case .type(let type) = self {
            return type
        }
        // Provide a default if the current selection isn't a type.
        return .inAdvance
    }
}



