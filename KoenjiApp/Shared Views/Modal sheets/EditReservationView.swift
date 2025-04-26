import PhotosUI
import SwiftUI
import os

struct EditReservationView: View {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "EditReservationView"
    )

    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

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
    @State private var imageButtonTitle = "Aggiungi immagine"

    var onClose: () -> Void
    var onChanged: (Reservation) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Main card content
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with name
                        TextField("Nome", text: $reservation.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .textFieldStyle(.roundedBorder)
                        
                        // Status badges
                        HStack(spacing: 8) {
                            Menu {
                                ForEach(Reservation.ReservationStatus.allCases, id: \.self) { status in
                                    Button(action: {
                                        reservation.status = status
                                        adjustNotesForStatus()
                                    }) {
                                        Label(status.localized, systemImage: statusIcon(for: status))
                                    }
                                }
                            } label: {
                                statusBadge(status: reservation.status)
                            }
                            
                            Menu {
                                ForEach(Reservation.ReservationCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        reservation.category = category
                                        adjustTimesForCategory()
                                    }) {
                                        Label(category.localized, systemImage: category == .lunch ? "sun.max.fill" : "moon.fill")
                                    }
                                }
                            } label: {
                                categoryBadge(category: reservation.category)
                            }
                            
                            Menu {
                                ForEach(Reservation.ReservationType.allCases, id: \.self) { type in
                                    Button(action: {
                                        reservation.reservationType = type
                                        adjustNotesForStatus()
                                    }) {
                                        Label(type.localized, systemImage: typeIcon(for: type))
                                    }
                                }
                            } label: {
                                typeBadge(type: reservation.reservationType)
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
                                    Text("\(reservation.numberOfPersons)")
                                        .font(.body)
                                    Spacer()
                                    Stepper("", value: $reservation.numberOfPersons, in: 2...14)
                                        .labelsHidden()
                                }
                            }
                            
                            editableDetailTag(
                                icon: "phone.fill",
                                title: String(localized: "Telefono"),
                                color: .green
                            ) {
                                TextField("", text: $reservation.phone)
                                    .keyboardType(.phonePad)
                            }
                            
                            
                            
                            editableDetailTag(
                                icon: "clock.fill",
                                title: String(localized: "Dalle"),
                                color: .purple
                            ) {
                                Menu {
                                    ForEach(getTimeSlots(for: reservation.category), id: \.self) { time in
                                        Button(action: {
                                            reservation.startTime = time
                                            // Update end time based on start time
                                            reservation.endTime = TimeHelpers.calculateEndTime(
                                                startTime: time,
                                                category: reservation.category
                                            )
                                        }) {
                                            Text(time)
                                        }
                                    }
                                } label: {
                                    Text(reservation.startTime)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            editableDetailTag(
                                icon: "clock.badge.checkmark",
                                title: String(localized: "Alle"),
                                color: .purple
                            ) {
                                Menu {
                                    ForEach(getEndTimeSlots(startTime: reservation.startTime, category: reservation.category), id: \.self) { time in
                                        Button(action: {
                                            reservation.endTime = time
                                        }) {
                                            Text(time)
                                        }
                                    }
                                } label: {
                                    Text(reservation.endTime)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            
                            editableDetailTag(
                                icon: "calendar",
                                title: String(localized: "Data"),
                                color: .orange
                            ) {
                                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            
                            editableDetailTag(
                                icon: "tablecells",
                                title: String(localized: "Tavoli"),
                                color: .indigo
                            ) {
                                Picker("", selection: $selectedForcedTableID) {
                                    Text("Auto Assegna").tag(nil as Int?)
                                    ForEach(env.tableAssignment.availableTables(
                                        for: reservation,
                                        reservations: env.store.getReservations(),
                                        tables: env.layoutServices.getTables()
                                    ), id: \.table.id) { entry in
                                        Text(entry.isCurrentlyAssigned ? "\(entry.table.name) (già assegnato)" : entry.table.name)
                                            .tag(entry.table.id as Int?)
                                    }
                                }
                            }
                            
                            
                        }
                        
                        // Notes section
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Note", systemImage: "note.text")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $reservation.notes.orEmpty())
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
                                
                                if let image = reservation.image {
                                    ZStack(alignment: .topTrailing) {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Button(action: {
                                            selectedPhotoItem = nil
                                            reservation.imageData = nil
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
                    .background(reservation.assignedColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .navigationTitle("Modifica Prenotazione")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        env.resCache.addOrUpdateReservation(reservation)
                        updateSession()
                        onClose()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        updateSession()
                        saveChanges()
                    }
                }
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .mondayConfirmation:
                    return Alert(
                        title: Text("Attenzione!"),
                        message: Text("Stai cercando di prenotare di lunedì. Sei sicuro di voler continuare?"),
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
            .onChange(of: selectedPhotoItem) { old, newItem in
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    self.selectedImage = Image(uiImage: uiImage)
                                    reservation.imageData = data
                                    imageButtonTitle = String(localized: "Cambia immagine")
                                }
                            }
                        } catch {
                            AppLog.error("Error loading image: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .onAppear {
                imageButtonTitle = reservation.imageData != nil ? "Cambia immagine" : "Aggiungi immagine"
                loadInitialDate()
                if let firstTable = reservation.tables.first {
                    selectedForcedTableID = firstTable.id
                }
                updateSession(true)
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
    
    private func statusIcon(for status: Reservation.ReservationStatus) -> String {
        switch status {
        case .showedUp: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        case .late: return "clock.badge.exclamationmark.fill"
        case .noShow: return "questionmark.circle.fill"
        case .toHandle: return "exclamationmark.triangle.fill"
        case .deleted: return "xmark.bin.fill"
        case .na: return "circle.badge.questionmark.fill"
        }
    }
    
    private func typeIcon(for type: Reservation.ReservationType) -> String {
        switch type {
        case .walkIn: return "figure.walk"
        case .inAdvance: return "deskclock.fill"
        case .waitingList: return "person.3.sequence"
        case .na: return "circle.badge.questionmark.fill"
        }
    }
    
    private func statusBadge(status: Reservation.ReservationStatus) -> some View {
        Label {
            Text(status.localized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: statusIcon(for: status))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .foregroundColor(status.color)
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
    
    private func typeBadge(type: Reservation.ReservationType) -> some View {
        Label {
            Text(type.localized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: typeIcon(for: type))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.color.opacity(0.12))
        .foregroundColor(type.color)
        .clipShape(Capsule())
    }
    
    private func updateSession(_ isEditing: Bool = false) {
        if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
            session.isEditing = isEditing
            env.reservationService.upsertSession(session)
        }
    }
    
    private func validateEdit() {
        if SessionStore.shared.sessions.contains( where: {$0.isEditing == true && $0.uuid != deviceUUID}) {
            appState.canSave = false
            env.pushAlerts.alertMessage = String(localized: "Un altro utente sta effettuando modifiche. Impossibile salvare. Attendere.")
            activeAlert = .editing
            
        } else {
            appState.canSave = true
        }
    }

    private func saveChanges() {
        guard validateInputs() else { return }
        validateEdit()
        guard appState.canSave else { return }

        guard let reservationStart = reservation.startTimeDate,
            let reservationEnd = reservation.endTimeDate else { return }

        for table in reservation.tables {
            env.layoutServices.unlockTable(
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
            reservation.tables = []

            env.reservationService.updateReservation(reservation) {
                onChanged(reservation)
            }
            

            onClose()
            dismiss()
            return
        }
        
        if reservation.status == .canceled || reservation.status == .toHandle {
            reservation.tables = []

            env.reservationService.updateReservation(reservation){
                onChanged(reservation)
            }
            onClose()
            dismiss()
            return
        }
        
        if reservation.status == .deleted {
            env.reservationService.deleteReservation(reservation)
            onChanged(reservation)
            onClose()
            dismiss()
            return
        }

        if reservation.reservationType != .waitingList {
            let assignmentResult = env.layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                reservation.tables = assignedTables
                env.reservationService.updateReservation(reservation){
                    onChanged(reservation)
                }
                onClose()
                dismiss()
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    activeAlert = .error(String(localized: "Non ci sono tavoli disponibili."))
                case .insufficientTables:
                    activeAlert = .error(String(localized: "Non ci sono abbastanza tavoli per la prenotazione."))
                case .tableNotFound:
                    activeAlert = .error(String(localized: "Tavolo selezionato non trovato."))
                case .tableLocked:
                    activeAlert = .error(String(localized: "Il tavolo scelto è occupato o bloccato."))
                case .unknown:
                    activeAlert = .error(String(localized: "Errore sconosciuto."))
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
        case .canceled: newTag = String(localized: "[cancellazione];")
        case .noShow: newTag = String(localized: "[no show];")
        case .pending: newTag = String(localized: "[in attesa];")
        case .showedUp: newTag = String(localized: "[arrivati];")
        case .late: newTag = String(localized: "[in ritardo];")
        case .na: newTag = ""
        case .toHandle: newTag = String(localized: "[in sospeso];")
        case .deleted: newTag = String(localized: "[cancellata];")
        }
        switch reservation.acceptance {
        case .confirmed: newTag = String(localized: "[confermata];")
        case .toConfirm: newTag = String(localized: "[da confermare];")
        case .na: newTag = String(localized: "[N/A];")
        }
        switch reservation.reservationType {
        case .inAdvance: newTag = String(localized: "[prenotata];")
        case .walkIn: newTag = String(localized: "[walk-in];")
        case .waitingList: newTag = String(localized: "[waiting list];")
        case .na: newTag = String(localized: "[N/A];")
        }

        // Append the new tag.

        reservation.notes! += newTag
    }

    private func validateInputs() -> Bool {
        if reservation.name.trimmingCharacters(in: .whitespaces).isEmpty {
            activeAlert = .error(String(localized: "Il nome non può essere lasciato vuoto."))
            return false
        }
        if reservation.phone.trimmingCharacters(in: .whitespaces).isEmpty {
            activeAlert = .error(String(localized: "Il contatto non può essere lasciato vuoto."))
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
        AppLog.debug("Initial date set to: \(selectedDate)")
    }

    private func getTimeSlots(for category: Reservation.ReservationCategory) -> [String] {
        switch category {
        case .lunch:
            return stride(from: 11, through: 14, by: 0.25).map {
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
            endLimit = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: start) ?? start
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
