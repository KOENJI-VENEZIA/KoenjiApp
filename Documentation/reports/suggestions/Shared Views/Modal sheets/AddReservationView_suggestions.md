Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Views/Modal sheets/AddReservationView.swift...
# Documentation Suggestions for AddReservationView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Views/Modal sheets/AddReservationView.swift
Total suggestions: 87

## Class Documentation (3)

### AddReservationView (Line 4)

**Context:**

```swift
import PhotosUI
import SwiftUI

struct AddReservationView: View {
    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
```

**Suggested Documentation:**

```swift
/// AddReservationView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### ReservationOption (Line 706)

**Context:**

```swift
    }
}

enum ReservationOption: Hashable {
    case status(Reservation.ReservationStatus)
    case type(Reservation.ReservationType)
    case acceptance(Reservation.Acceptance)
```

**Suggested Documentation:**

```swift
/// ReservationOption class.
///
/// [Add a description of what this class does and its responsibilities]
```

### ReservationOption (Line 757)

**Context:**

```swift
    }
}

extension ReservationOption {
    var asStatus: Reservation.ReservationStatus {
        if case .status(let status) = self {
            return status
```

**Suggested Documentation:**

```swift
/// ReservationOption class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (16)

### updateSession (Line 379)

**Context:**

```swift

    // MARK: - Helpers

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

### validateEdit (Line 386)

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

### createTemporaryReservation (Line 397)

**Context:**

```swift
        }
    }
    
    private func createTemporaryReservation() -> Reservation {
        
        Reservation(
            id: UUID(),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the createTemporaryReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### adjustTimesForCategory (Line 418)

**Context:**

```swift
        )
    }

    private func adjustTimesForCategory() {
        switch appState.selectedCategory {
        case .lunch:
            startTimeString = "12:00"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the adjustTimesForCategory method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### adjustNotesForStatus (Line 433)

**Context:**

```swift
        )
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

### categoryForTimeInterval (Line 475)

**Context:**

```swift
        notes += newTag
    }

    private func categoryForTimeInterval(time: Date) -> Reservation.ReservationCategory {

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the categoryForTimeInterval method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### saveReservation (Line 491)

**Context:**

```swift

    }

    private func saveReservation() {
        guard validateInputs() else {
            isSaving = false
            return
```

**Suggested Documentation:**

```swift
/// [Add a description of what the saveReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### validateInputs (Line 516)

**Context:**

```swift
        performSaveReservation()
    }

    private func validateInputs() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            env.pushAlerts.activeAddAlert = .error(String(localized: "Il nome non può essere lasciato vuoto."))
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

### performSaveReservation (Line 528)

**Context:**

```swift
        return true
    }

    private func performSaveReservation() {
        adjustNotesForStatus()
        var newReservation = createTemporaryReservation()
        if newReservation.reservationType == .waitingList || newReservation.status == .canceled || newReservation.status == .deleted || newReservation.status == .toHandle {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the performSaveReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### editableDetailTag (Line 567)

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

### statusBadge (Line 598)

**Context:**

```swift
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusBadge(status: ReservationOption) -> some View {
        Label {
            Text(status.title.capitalized)
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

### categoryBadge (Line 612)

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

### getStatusIcon (Line 626)

**Context:**

```swift
        .clipShape(Capsule())
    }
    
    private func getStatusIcon(for option: ReservationOption) -> String {
        switch option {
        case .type(.waitingList): return "person.3.sequence"
        case .type(.walkIn): return "figure.walk"
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getStatusIcon method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getStatusColor (Line 643)

**Context:**

```swift
        }
    }
    
    private func getStatusColor(for option: ReservationOption) -> Color {
        switch option {
        case .type(.waitingList): return .orange
        case .type(.walkIn): return .green
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getStatusColor method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getTimeSlots (Line 653)

**Context:**

```swift
        }
    }

    private func getTimeSlots(for category: Reservation.ReservationCategory) -> [String] {
        switch category {
        case .lunch:
            return stride(from: 11, through: 15, by: 0.25).map {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getTimeSlots method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getEndTimeSlots (Line 676)

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

## Property Documentation (68)

### deviceUUID (Line 5)

**Context:**

```swift
import SwiftUI

struct AddReservationView: View {
    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
```

**Suggested Documentation:**

```swift
/// [Description of the deviceUUID property]
```

### env (Line 7)

**Context:**

```swift
struct AddReservationView: View {
    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### appState (Line 8)

**Context:**

```swift
    @AppStorage("deviceUUID") private var deviceUUID = ""

    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss

```

**Suggested Documentation:**

```swift
/// [Description of the appState property]
```

### dismiss (Line 10)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var name: String = ""
```

**Suggested Documentation:**

```swift
/// [Description of the dismiss property]
```

### name (Line 13)

**Context:**

```swift
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### phone (Line 14)

**Context:**

```swift

    // MARK: - State
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
```

**Suggested Documentation:**

```swift
/// [Description of the phone property]
```

### numberOfPersons (Line 15)

**Context:**

```swift
    // MARK: - State
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### acceptance (Line 16)

**Context:**

```swift
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### selectedStatus (Line 17)

**Context:**

```swift
    @State private var phone: String = ""
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedStatus property]
```

### status (Line 18)

**Context:**

```swift
    @State private var numberOfPersons: Int = 2
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationType (Line 19)

**Context:**

```swift
    @State private var acceptance: Reservation.Acceptance = .confirmed
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""

```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### group (Line 20)

**Context:**

```swift
    @State private var selectedStatus: ReservationOption = .acceptance(.confirmed)
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""

    @State private var endTimeString: String = "13:45"
```

**Suggested Documentation:**

```swift
/// [Description of the group property]
```

### notes (Line 21)

**Context:**

```swift
    @State private var status: Reservation.ReservationStatus = .pending
    @State private var reservationType: Reservation.ReservationType = .inAdvance
    @State private var group: Bool = false
    @State private var notes: String = ""

    @State private var endTimeString: String = "13:45"
    @State private var startTimeString: String = "12:00"
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### endTimeString (Line 23)

**Context:**

```swift
    @State private var group: Bool = false
    @State private var notes: String = ""

    @State private var endTimeString: String = "13:45"
    @State private var startTimeString: String = "12:00"

    @State private var selectedForcedTableID: Int? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the endTimeString property]
```

### startTimeString (Line 24)

**Context:**

```swift
    @State private var notes: String = ""

    @State private var endTimeString: String = "13:45"
    @State private var startTimeString: String = "12:00"

    @State private var selectedForcedTableID: Int? = nil

```

**Suggested Documentation:**

```swift
/// [Description of the startTimeString property]
```

### selectedForcedTableID (Line 26)

**Context:**

```swift
    @State private var endTimeString: String = "13:45"
    @State private var startTimeString: String = "12:00"

    @State private var selectedForcedTableID: Int? = nil


    @State private var isSaving = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedForcedTableID property]
```

### isSaving (Line 29)

**Context:**

```swift
    @State private var selectedForcedTableID: Int? = nil


    @State private var isSaving = false

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
```

**Suggested Documentation:**

```swift
/// [Description of the isSaving property]
```

### selectedPhotoItem (Line 31)

**Context:**

```swift

    @State private var isSaving = false

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedPhotoItem property]
```

### selectedImage (Line 32)

**Context:**

```swift
    @State private var isSaving = false

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedImage property]
```

### imageData (Line 33)

**Context:**

```swift

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State var category: Reservation.ReservationCategory = .lunch
```

**Suggested Documentation:**

```swift
/// [Description of the imageData property]
```

### showImagePicker (Line 34)

**Context:**

```swift
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State var category: Reservation.ReservationCategory = .lunch
    var passedTable: TableModel?
```

**Suggested Documentation:**

```swift
/// [Description of the showImagePicker property]
```

### showImageField (Line 35)

**Context:**

```swift
    @State private var selectedImage: Image? = nil
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State var category: Reservation.ReservationCategory = .lunch
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
```

**Suggested Documentation:**

```swift
/// [Description of the showImageField property]
```

### category (Line 36)

**Context:**

```swift
    @State private var imageData: Data? = nil
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State var category: Reservation.ReservationCategory = .lunch
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
    
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### passedTable (Line 37)

**Context:**

```swift
    @State private var showImagePicker = false
    @State private var showImageField = false
    @State var category: Reservation.ReservationCategory = .lunch
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
    
    @State private var availableTables: [(table: TableModel, isCurrentlyAssigned: Bool)] = []
```

**Suggested Documentation:**

```swift
/// [Description of the passedTable property]
```

### onAdded (Line 38)

**Context:**

```swift
    @State private var showImageField = false
    @State var category: Reservation.ReservationCategory = .lunch
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
    
    @State private var availableTables: [(table: TableModel, isCurrentlyAssigned: Bool)] = []

```

**Suggested Documentation:**

```swift
/// [Description of the onAdded property]
```

### availableTables (Line 40)

**Context:**

```swift
    var passedTable: TableModel?
    var onAdded: (Reservation) -> Void
    
    @State private var availableTables: [(table: TableModel, isCurrentlyAssigned: Bool)] = []

    // MARK: - Body
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the availableTables property]
```

### body (Line 43)

**Context:**

```swift
    @State private var availableTables: [(table: TableModel, isCurrentlyAssigned: Bool)] = []

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### columns (Line 93)

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

### selectedImage (Line 203)

**Context:**

```swift
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let selectedImage {
                                    ZStack(alignment: .topTrailing) {
                                        selectedImage
                                            .resizable()
```

**Suggested Documentation:**

```swift
/// [Description of the selectedImage property]
```

### message (Line 305)

**Context:**

```swift
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

### newItem (Line 357)

**Context:**

```swift

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

### data (Line 360)

**Context:**

```swift
                if let newItem {
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                                let uiImage = UIImage(data: data)
                            {
                                selectedImage = Image(uiImage: uiImage)  // Update the displayed image
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### uiImage (Line 361)

**Context:**

```swift
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                                let uiImage = UIImage(data: data)
                            {
                                selectedImage = Image(uiImage: uiImage)  // Update the displayed image
                            }
```

**Suggested Documentation:**

```swift
/// [Description of the uiImage property]
```

### session (Line 380)

**Context:**

```swift
    // MARK: - Helpers

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

### tagPattern (Line 435)

**Context:**

```swift

    private func adjustNotesForStatus() {
        // Define a pattern that finds our "tag" substrings, for example "[...];"
        let tagPattern = #"\[[^\]]*\];"#  // Match a "[", any number of non-"]", then "];"

        // Remove all existing tags from the notes:
        notes = notes.replacingOccurrences(of: tagPattern, with: "", options: .regularExpression)
```

**Suggested Documentation:**

```swift
/// [Description of the tagPattern property]
```

### newTag (Line 444)

**Context:**

```swift
        notes = notes.trimmingCharacters(in: .whitespacesAndNewlines) + " "

        // Determine the new tag to add based on selectedStatus.
        var newTag: String = ""
        switch selectedStatus {
        case .status(let status):
            switch status {
```

**Suggested Documentation:**

```swift
/// [Description of the newTag property]
```

### status (Line 446)

**Context:**

```swift
        // Determine the new tag to add based on selectedStatus.
        var newTag: String = ""
        switch selectedStatus {
        case .status(let status):
            switch status {
            case .canceled: newTag = String(localized: "[cancellazione];")
            case .noShow: newTag = String(localized: "[no show];")
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### acceptance (Line 457)

**Context:**

```swift
            case .deleted: newTag = String(localized: "[eliminata];")
            case .na: newTag = String(localized: "[N/A]")
            }
        case .acceptance(let acceptance):
            switch acceptance {
            case .confirmed: newTag = String(localized: "[confermata];")
            case .toConfirm: newTag = String(localized: "[da confermare];")
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### type (Line 463)

**Context:**

```swift
            case .toConfirm: newTag = String(localized: "[da confermare];")
            case .na: newTag = String(localized: "[N/A]")
            }
        case .type(let type):
            switch type {
            case .inAdvance: newTag = String(localized: "[prenotata];")
            case .walkIn: newTag = String(localized: "[walk-in];")
```

**Suggested Documentation:**

```swift
/// [Description of the type property]
```

### calendar (Line 477)

**Context:**

```swift

    private func categoryForTimeInterval(time: Date) -> Reservation.ReservationCategory {

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        switch hour {
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### hour (Line 478)

**Context:**

```swift
    private func categoryForTimeInterval(time: Date) -> Reservation.ReservationCategory {

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        switch hour {
        case 12..<15:  // Lunch hours
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### weekday (Line 506)

**Context:**

```swift
        
        

        let weekday = Calendar.current.component(.weekday, from: appState.selectedDate)
        if weekday == 2 {  // Monday
            env.pushAlerts.activeAddAlert = .mondayConfirmation
            isSaving = false
```

**Suggested Documentation:**

```swift
/// [Description of the weekday property]
```

### newReservation (Line 530)

**Context:**

```swift

    private func performSaveReservation() {
        adjustNotesForStatus()
        var newReservation = createTemporaryReservation()
        if newReservation.reservationType == .waitingList || newReservation.status == .canceled || newReservation.status == .deleted || newReservation.status == .toHandle {
            newReservation.tables = []
            isSaving = false
```

**Suggested Documentation:**

```swift
/// [Description of the newReservation property]
```

### assignmentResult (Line 539)

**Context:**

```swift
            dismiss()
            return
        } else {
            let assignmentResult = env.layoutServices.assignTables(
                for: newReservation, selectedTableID: selectedForcedTableID)
            switch assignmentResult {
            case .success(let assignedTables):
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 542)

**Context:**

```swift
            let assignmentResult = env.layoutServices.assignTables(
                for: newReservation, selectedTableID: selectedForcedTableID)
            switch assignmentResult {
            case .success(let assignedTables):
                newReservation.tables = assignedTables
                isSaving = false
                onAdded(newReservation)
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### error (Line 549)

**Context:**

```swift
                env.reservationService.addReservation(newReservation)
                dismiss()
                return
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    env.pushAlerts.activeAddAlert = .error(String(localized: "Non ci sono tavoli disponibili."))
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### hour (Line 657)

**Context:**

```swift
        switch category {
        case .lunch:
            return stride(from: 11, through: 15, by: 0.25).map {
                let hour = Int($0)
                let minute = Int(($0.truncatingRemainder(dividingBy: 1) * 60).rounded())
                return String(format: "%02d:%02d", hour, minute)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the hour property]
```

### minute (Line 658)

**Context:**

```swift
        case .lunch:
            return stride(from: 11, through: 15, by: 0.25).map {
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

### hour (Line 663)

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

### minute (Line 664)

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

### hour (Line 669)

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

### minute (Line 670)

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

### formatter (Line 677)

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

### start (Line 680)

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

### calendar (Line 682)

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

### endLimit (Line 683)

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

### timeSlots (Line 694)

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

### currentTime (Line 695)

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

### title (Line 712)

**Context:**

```swift
    case acceptance(Reservation.Acceptance)

    // Optionally, provide a computed property for a localized title:
    var title: String {
        switch self {
        case .status(let status):
            switch status {
```

**Suggested Documentation:**

```swift
/// [Description of the title property]
```

### status (Line 714)

**Context:**

```swift
    // Optionally, provide a computed property for a localized title:
    var title: String {
        switch self {
        case .status(let status):
            switch status {
            case .noShow:
                return String(localized: "no show")
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### type (Line 733)

**Context:**

```swift
            case .deleted:
                return String(localized: "eliminata")
            }
        case .type(let type):
            switch type {
            case .walkIn:
                return String(localized: "walk-in")
```

**Suggested Documentation:**

```swift
/// [Description of the type property]
```

### acceptance (Line 744)

**Context:**

```swift
            case .na:
                return String(localized: "n/a")
            }
        case .acceptance(let acceptance):
            switch acceptance {
            case .confirmed:
                return String(localized: "confermata")
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### asStatus (Line 758)

**Context:**

```swift
}

extension ReservationOption {
    var asStatus: Reservation.ReservationStatus {
        if case .status(let status) = self {
            return status
        }
```

**Suggested Documentation:**

```swift
/// [Description of the asStatus property]
```

### status (Line 759)

**Context:**

```swift

extension ReservationOption {
    var asStatus: Reservation.ReservationStatus {
        if case .status(let status) = self {
            return status
        }
        // Provide a default if the current selection isn't a status.
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### asAcceptance (Line 766)

**Context:**

```swift
        return .pending
    }

    var asAcceptance: Reservation.Acceptance {
        if case .acceptance(let acceptance) = self {
            return acceptance
        }
```

**Suggested Documentation:**

```swift
/// [Description of the asAcceptance property]
```

### acceptance (Line 767)

**Context:**

```swift
    }

    var asAcceptance: Reservation.Acceptance {
        if case .acceptance(let acceptance) = self {
            return acceptance
        }
        // Provide a default if the current selection isn't acceptance.
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### asType (Line 774)

**Context:**

```swift
        return .toConfirm
    }

    var asType: Reservation.ReservationType {
        if case .type(let type) = self {
            return type
        }
```

**Suggested Documentation:**

```swift
/// [Description of the asType property]
```

### type (Line 775)

**Context:**

```swift
    }

    var asType: Reservation.ReservationType {
        if case .type(let type) = self {
            return type
        }
        // Provide a default if the current selection isn't a type.
```

**Suggested Documentation:**

```swift
/// [Description of the type property]
```


Total documentation suggestions: 87

