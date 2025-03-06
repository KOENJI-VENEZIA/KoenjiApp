Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Views/Modal sheets/EditReservationView.swift...
# Documentation Suggestions for EditReservationView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Views/Modal sheets/EditReservationView.swift
Total suggestions: 69

## Class Documentation (1)

### EditReservationView (Line 5)

**Context:**

```swift
import SwiftUI
import os

struct EditReservationView: View {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "EditReservationView"
```

**Suggested Documentation:**

```swift
/// EditReservationView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (16)

### editableDetailTag (Line 348)

**Context:**

```swift
        }
    }
    
    private func editableDetailTag<Content: View>(
        icon: String,
        title: String,
        color: Color,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the editableDetailTag method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### statusIcon (Line 379)

**Context:**

```swift
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusIcon(for status: Reservation.ReservationStatus) -> String {
        switch status {
        case .showedUp: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the statusIcon method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### typeIcon (Line 392)

**Context:**

```swift
        }
    }
    
    private func typeIcon(for type: Reservation.ReservationType) -> String {
        switch type {
        case .walkIn: return "figure.walk"
        case .inAdvance: return "deskclock.fill"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the typeIcon method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### statusBadge (Line 401)

**Context:**

```swift
        }
    }
    
    private func statusBadge(status: Reservation.ReservationStatus) -> some View {
        Label {
            Text(status.localized)
                .font(.caption.weight(.semibold))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the statusBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### categoryBadge (Line 415)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func categoryBadge(category: Reservation.ReservationCategory) -> some View {
        Label {
            Text(category.localized)
                .font(.caption.weight(.semibold))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the categoryBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### typeBadge (Line 429)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func typeBadge(type: Reservation.ReservationType) -> some View {
        Label {
            Text(type.localized)
                .font(.caption.weight(.semibold))
```

**Suggested Documentation:**

```swift
/// [Add a description of what the typeBadge method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateSession (Line 443)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func updateSession(_ isEditing: Bool = false) {
        if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
            session.isEditing = isEditing
            env.reservationService.upsertSession(session)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateSession method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### validateEdit (Line 450)

**Context:**

```swift
        }
    }
    
    private func validateEdit() {
        if SessionStore.shared.sessions.contains( where: {$0.isEditing == true && $0.uuid != deviceUUID}) {
            appState.canSave = false
            env.pushAlerts.alertMessage = String(localized: "Un altro utente sta effettuando modifiche. Impossibile salvare. Attendere.")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the validateEdit method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### saveChanges (Line 461)

**Context:**

```swift
        }
    }

    private func saveChanges() {
        guard validateInputs() else { return }
        validateEdit()
        guard appState.canSave else { return }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the saveChanges method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### performSaveReservation (Line 486)

**Context:**

```swift

    }

    private func performSaveReservation() {
        if reservation.reservationType == .waitingList {
            reservation.tables = []

```

**Suggested Documentation:**

```swift
/// [Add a description of what the performSaveReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### adjustNotesForStatus (Line 548)

**Context:**

```swift
        }
    }
        
    private func adjustNotesForStatus() {
        // Define a pattern that finds our "tag" substrings, for example "[...];"
        let tagPattern = #"\[[^\]]*\];"#  // Match a "[", any number of non-"]", then "];"

```

**Suggested Documentation:**

```swift
/// [Add a description of what the adjustNotesForStatus method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### validateInputs (Line 589)

**Context:**

```swift
        reservation.notes! += newTag
    }

    private func validateInputs() -> Bool {
        if reservation.name.trimmingCharacters(in: .whitespaces).isEmpty {
            activeAlert = .error(String(localized: "Il nome non può essere lasciato vuoto."))
            return false
```

**Suggested Documentation:**

```swift
/// [Add a description of what the validateInputs method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### adjustTimesForCategory (Line 601)

**Context:**

```swift
        return true
    }

    private func adjustTimesForCategory() {
        switch reservation.category {
        case .lunch:
            reservation.startTime = "12:00"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the adjustTimesForCategory method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### loadInitialDate (Line 618)

**Context:**

```swift
        }
    }

    private func loadInitialDate() {
        selectedDate = reservation.normalizedDate ?? Date()
        Self.logger.debug("Initial date set to: \(selectedDate)")
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the loadInitialDate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getTimeSlots (Line 623)

**Context:**

```swift
        Self.logger.debug("Initial date set to: \(selectedDate)")
    }

    private func getTimeSlots(for category: Reservation.ReservationCategory) -> [String] {
        switch category {
        case .lunch:
            return stride(from: 11, through: 14, by: 0.25).map {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getTimeSlots method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getEndTimeSlots (Line 646)

**Context:**

```swift
        }
    }
    
    private func getEndTimeSlots(startTime: String, category: Reservation.ReservationCategory) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getEndTimeSlots method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (52)

### logger (Line 6)

**Context:**

```swift
import os

struct EditReservationView: View {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "EditReservationView"
    )
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### deviceUUID (Line 11)

**Context:**

```swift
        category: "EditReservationView"
    )

    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
```

**Suggested Documentation:**

```swift
/// [Description of the deviceUUID property]
```

### env (Line 13)

**Context:**

```swift

    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 14)

**Context:**

```swift
    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale
```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### dismiss (Line 16)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale

    @State var reservation: Reservation
```

**Suggested Documentation:**

```swift
/// [Description of the dismiss property]
```

### locale (Line 17)

**Context:**

```swift
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale

    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the locale property]
```

### reservation (Line 19)

**Context:**

```swift
    @Environment(\.dismiss) var dismiss
    @Environment(\.locale) var locale

    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var alertMessage: String = ""
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### selectedDate (Line 20)

**Context:**

```swift
    @Environment(\.locale) var locale

    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
```

**Suggested Documentation:**

```swift
/// [Description of the selectedDate property]
```

### selectedForcedTableID (Line 21)

**Context:**

```swift

    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
```

**Suggested Documentation:**

```swift
/// [Description of the selectedForcedTableID property]
```

### alertMessage (Line 22)

**Context:**

```swift
    @State var reservation: Reservation
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var activeAlert: AddReservationAlertType? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the alertMessage property]
```

### currentTime (Line 23)

**Context:**

```swift
    @State private var selectedDate: Date = Date()
    @State private var selectedForcedTableID: Int? = nil
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var activeAlert: AddReservationAlertType? = nil

```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```

### selectedStatus (Line 24)

**Context:**

```swift
    @State private var selectedForcedTableID: Int? = nil
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var activeAlert: AddReservationAlertType? = nil

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the selectedStatus property]
```

### activeAlert (Line 25)

**Context:**

```swift
    @State private var alertMessage: String = ""
    @State private var currentTime: Date = Date()
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var activeAlert: AddReservationAlertType? = nil

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var reservationImageData: Data? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the activeAlert property]
```

### selectedPhotoItem (Line 27)

**Context:**

```swift
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var activeAlert: AddReservationAlertType? = nil

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var reservationImageData: Data? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the selectedPhotoItem property]
```

### reservationImageData (Line 28)

**Context:**

```swift
    @State private var activeAlert: AddReservationAlertType? = nil

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var reservationImageData: Data? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
```

**Suggested Documentation:**

```swift
/// [Description of the reservationImageData property]
```

### selectedImage (Line 29)

**Context:**

```swift

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var reservationImageData: Data? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedImage property]
```

### imageData (Line 30)

**Context:**

```swift
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var reservationImageData: Data? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State private var imageButtonTitle = "Aggiungi immagine"
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### showImagePicker (Line 31)

**Context:**

```swift
    @State private var reservationImageData: Data? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State private var imageButtonTitle = "Aggiungi immagine"

```

**Suggested Documentation:**

```swift
/// [Description of the showImagePicker property]
```

### showImageField (Line 32)

**Context:**

```swift
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State private var imageButtonTitle = "Aggiungi immagine"

    var onClose: () -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the showImageField property]
```

### imageButtonTitle (Line 33)

**Context:**

```swift
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State private var imageButtonTitle = "Aggiungi immagine"

    var onClose: () -> Void
    var onChanged: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the imageButtonTitle property]
```

### onClose (Line 35)

**Context:**

```swift
    @State private var showImageField = false
    @State private var imageButtonTitle = "Aggiungi immagine"

    var onClose: () -> Void
    var onChanged: (Reservation) -> Void

    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the onClose property]
```

### onChanged (Line 36)

**Context:**

```swift
    @State private var imageButtonTitle = "Aggiungi immagine"

    var onClose: () -> Void
    var onChanged: (Reservation) -> Void

    var body: some View {
        NavigationView {
```

**Suggested Documentation:**

```swift
/// [Description of the onChanged property]
```

### body (Line 38)

**Context:**

```swift
    var onClose: () -> Void
    var onChanged: (Reservation) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### columns (Line 96)

**Context:**

```swift
                            .padding(.vertical, 8)
                        
                        // Primary info with icons in a grid
                        let columns = [GridItem(.adaptive(minimum: 180, maximum: .infinity), spacing: 12)]
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            editableDetailTag(
                                icon: "person.2.fill",
```

**Suggested Documentation:**

```swift
/// [Description of the columns property]
```

### image (Line 214)

**Context:**

```swift
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let image = reservation.image {
                                    ZStack(alignment: .topTrailing) {
                                        image
                                            .resizable()
```

**Suggested Documentation:**

```swift
/// [Description of the image property]
```

### message (Line 311)

**Context:**

```swift
                        message: Text(env.pushAlerts.alertMessage),
                        dismissButton: .default(Text("Annulla"))
                    )
                case .error(let message):
                    return Alert(
                        title: Text("Errore:"),
                        message: Text(message),
```

**Suggested Documentation:**

```swift
/// [Description of the message property]
```

### newItem (Line 320)

**Context:**

```swift
                }
            }
            .onChange(of: selectedPhotoItem) { old, newItem in
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
```

**Suggested Documentation:**

```swift
/// [Description of the newItem property]
```

### data (Line 323)

**Context:**

```swift
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    self.selectedImage = Image(uiImage: uiImage)
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### uiImage (Line 324)

**Context:**

```swift
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    self.selectedImage = Image(uiImage: uiImage)
                                    reservation.imageData = data
```

**Suggested Documentation:**

```swift
/// [Description of the uiImage property]
```

### firstTable (Line 340)

**Context:**

```swift
            .onAppear {
                imageButtonTitle = reservation.imageData != nil ? "Cambia immagine" : "Aggiungi immagine"
                loadInitialDate()
                if let firstTable = reservation.tables.first {
                    selectedForcedTableID = firstTable.id
                }
                updateSession(true)
```

**Suggested Documentation:**

```swift
/// [Description of the firstTable property]
```

### session (Line 444)

**Context:**

```swift
    }
    
    private func updateSession(_ isEditing: Bool = false) {
        if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
            session.isEditing = isEditing
            env.reservationService.upsertSession(session)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the session property]
```

### reservationStart (Line 466)

**Context:**

```swift
        validateEdit()
        guard appState.canSave else { return }

        guard let reservationStart = reservation.startTimeDate,
            let reservationEnd = reservation.endTimeDate else { return }

        for table in reservation.tables {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationStart property]
```

### reservationEnd (Line 467)

**Context:**

```swift
        guard appState.canSave else { return }

        guard let reservationStart = reservation.startTimeDate,
            let reservationEnd = reservation.endTimeDate else { return }

        for table in reservation.tables {
            env.layoutServices.unlockTable(
```

**Suggested Documentation:**

```swift
/// [Description of the reservationEnd property]
```

### calendar (Line 474)

**Context:**

```swift
                tableID: table.id, start: reservationStart, end: reservationEnd)
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        // In the Gregorian calendar Sunday is 1, Monday is 2, etc.
        if weekday == 2 {  // Monday detected
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### weekday (Line 475)

**Context:**

```swift
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        // In the Gregorian calendar Sunday is 1, Monday is 2, etc.
        if weekday == 2 {  // Monday detected
            activeAlert = .mondayConfirmation
```

**Suggested Documentation:**

```swift
/// [Description of the weekday property]
```

### assignmentResult (Line 520)

**Context:**

```swift
        }

        if reservation.reservationType != .waitingList {
            let assignmentResult = env.layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 523)

**Context:**

```swift
            let assignmentResult = env.layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                reservation.tables = assignedTables
                env.reservationService.updateReservation(reservation){
                    onChanged(reservation)
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 530)

**Context:**

```swift
                }
                onClose()
                dismiss()
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    activeAlert = .error(String(localized: "Non ci sono tavoli disponibili."))
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### tagPattern (Line 550)

**Context:**

```swift
        
    private func adjustNotesForStatus() {
        // Define a pattern that finds our "tag" substrings, for example "[...];"
        let tagPattern = #"\[[^\]]*\];"#  // Match a "[", any number of non-"]", then "];"

        // Remove all existing tags from the notes:
        reservation.notes = reservation.notes?.replacingOccurrences(
```

**Suggested Documentation:**

```swift
/// [Description of the tagPattern property]
```

### newTag (Line 561)

**Context:**

```swift
            (reservation.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") + " "

        // Determine the new tag to add based on selectedStatus.
        var newTag: String = ""
        switch reservation.status {
        case .canceled: newTag = String(localized: "[cancellazione];")
        case .noShow: newTag = String(localized: "[no show];")
```

**Suggested Documentation:**

```swift
/// [Description of the newTag property]
```

### hour (Line 627)

**Context:**

```swift
        switch category {
        case .lunch:
            return stride(from: 11, through: 14, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### minute (Line 628)

**Context:**

```swift
        case .lunch:
            return stride(from: 11, through: 14, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
        case .dinner:
```

**Suggested Documentation:**

```swift
/// [Description of the minute property]
```

### hour (Line 633)

**Context:**

```swift
            }
        case .dinner:
            return stride(from: 18, through: 22, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### minute (Line 634)

**Context:**

```swift
        case .dinner:
            return stride(from: 18, through: 22, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
        case .noBookingZone:
```

**Suggested Documentation:**

```swift
/// [Description of the minute property]
```

### hour (Line 639)

**Context:**

```swift
            }
        case .noBookingZone:
            return stride(from: 0, through: 23, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### minute (Line 640)

**Context:**

```swift
        case .noBookingZone:
            return stride(from: 0, through: 23, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the minute property]
```

### formatter (Line 647)

**Context:**

```swift
    }
    
    private func getEndTimeSlots(startTime: String, category: Reservation.ReservationCategory) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime) else { return [] }
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### start (Line 650)

**Context:**

```swift
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime) else { return [] }
        
        let calendar = Calendar.current
        let endLimit: Date
```

**Suggested Documentation:**

```swift
/// [Description of the start property]
```

### calendar (Line 652)

**Context:**

```swift
        
        guard let start = formatter.date(from: startTime) else { return [] }
        
        let calendar = Calendar.current
        let endLimit: Date
        
        switch category {
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### endLimit (Line 653)

**Context:**

```swift
        guard let start = formatter.date(from: startTime) else { return [] }
        
        let calendar = Calendar.current
        let endLimit: Date
        
        switch category {
        case .lunch:
```

**Suggested Documentation:**

```swift
/// [Description of the endLimit property]
```

### timeSlots (Line 664)

**Context:**

```swift
            endLimit = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
        }
        
        var timeSlots: [String] = []
        var currentTime = calendar.date(byAdding: .minute, value: 15, to: start) ?? start
        
        while currentTime <= endLimit {
```

**Suggested Documentation:**

```swift
/// [Description of the timeSlots property]
```

### currentTime (Line 665)

**Context:**

```swift
        }
        
        var timeSlots: [String] = []
        var currentTime = calendar.date(byAdding: .minute, value: 15, to: start) ?? start
        
        while currentTime <= endLimit {
            timeSlots.append(formatter.string(from: currentTime))
```

**Suggested Documentation:**

```swift
/// [Description of the currentTime property]
```


Total documentation suggestions: 69

