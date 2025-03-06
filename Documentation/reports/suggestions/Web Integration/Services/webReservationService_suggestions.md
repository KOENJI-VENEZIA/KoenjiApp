Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/Services/webReservationService.swift...
# Documentation Suggestions for webReservationService.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/Services/webReservationService.swift
Total suggestions: 60

## Class Documentation (1)

### ReservationService (Line 14)

**Context:**

```swift
import OSLog

// Extension to add web reservation handling to ReservationService
extension ReservationService {
    
    // Start listener specifically for web reservations
    @MainActor
```

**Suggested Documentation:**

```swift
/// ReservationService service.
///
/// [Add a description of what this service does and its responsibilities]
```

## Method Documentation (5)

### startWebReservationListener (Line 18)

**Context:**

```swift
    
    // Start listener specifically for web reservations
    @MainActor
    func startWebReservationListener() {
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
```

**Suggested Documentation:**

```swift
/// [Add a description of what the startWebReservationListener method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### handleNewWebReservation (Line 57)

**Context:**

```swift
    }
    
    // Process new web reservation and send notification
    @MainActor private func handleNewWebReservation(_ reservation: Reservation) {
        logger.info("New web reservation received: \(reservation.id)")
        
        // Add to local database
```

**Suggested Documentation:**

```swift
/// [Add a description of what the handleNewWebReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### convertDictionaryToWebReservation (Line 87)

**Context:**

```swift
    }
    
    // Modified version of convertDictionaryToReservation to handle web reservations
    private func convertDictionaryToWebReservation(data: [String: Any], idString: String?) -> Reservation? {
        guard
            let idString = idString,
            let id = UUID(uuidString: idString),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the convertDictionaryToWebReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### approveWebReservation (Line 153)

**Context:**

```swift
    
    // Approve a web reservation and send confirmation email
    @MainActor
    func approveWebReservation(_ reservation: Reservation) async -> Bool {
        logger.debug("Called approveWebReservation")
        
        // 1. Create a new reservation with the same details but a new UUID
```

**Suggested Documentation:**

```swift
/// [Add a description of what the approveWebReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### declineWebReservation (Line 201)

**Context:**

```swift
    
    /// Decline a web reservation and update its status
    @MainActor
    func declineWebReservation(_ reservation: Reservation, reason: WebReservationDeclineReason, customNotes: String? = nil) async -> Bool {
        logger.debug("Called declineWebReservation with reason: \(reason.rawValue)")
        
        // 1. Create a new reservation with the updated details
```

**Suggested Documentation:**

```swift
/// [Add a description of what the declineWebReservation method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (54)

### dbRef (Line 20)

**Context:**

```swift
    @MainActor
    func startWebReservationListener() {
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 22)

**Context:**

```swift
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        // Listen for new web reservations with toConfirm status
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### error (Line 29)

**Context:**

```swift
        webReservationListener = dbRef.whereField("source", isEqualTo: "web")
             .whereField("acceptance", isEqualTo: "toConfirm")
             .addSnapshotListener { [weak self] snapshot, error in
                 if let error = error {
                     self?.logger.error("Error listening for web reservations: \(error)")
                     return
                 }
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### snapshot (Line 36)

**Context:**

```swift
                 
                 self?.logger.debug("Listened for new web reservation!")
                 
                 guard let snapshot = snapshot else { return }
                 
                 var reservationsByID: [UUID: Reservation] = [:]
                 for document in snapshot.documents {
```

**Suggested Documentation:**

```swift
/// [Description of the snapshot property]
```

### reservationsByID (Line 38)

**Context:**

```swift
                 
                 guard let snapshot = snapshot else { return }
                 
                 var reservationsByID: [UUID: Reservation] = [:]
                 for document in snapshot.documents {
                     let data = document.data()
                     self?.logger.debug("DEBUG doc data: \(data)")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationsByID property]
```

### data (Line 40)

**Context:**

```swift
                 
                 var reservationsByID: [UUID: Reservation] = [:]
                 for document in snapshot.documents {
                     let data = document.data()
                     self?.logger.debug("DEBUG doc data: \(data)")
                     let idString = (data["id"] as? String ?? "").uppercased()
                     
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### idString (Line 42)

**Context:**

```swift
                 for document in snapshot.documents {
                     let data = document.data()
                     self?.logger.debug("DEBUG doc data: \(data)")
                     let idString = (data["id"] as? String ?? "").uppercased()
                     
                     if let reservation = self?.convertDictionaryToWebReservation(data: data, idString: idString) {
                         reservationsByID[reservation.id] = reservation
```

**Suggested Documentation:**

```swift
/// [Description of the idString property]
```

### reservation (Line 44)

**Context:**

```swift
                     self?.logger.debug("DEBUG doc data: \(data)")
                     let idString = (data["id"] as? String ?? "").uppercased()
                     
                     if let reservation = self?.convertDictionaryToWebReservation(data: data, idString: idString) {
                         reservationsByID[reservation.id] = reservation
                         // Also upsert into SQLite:
                         self?.logger.debug("Created new reservation from web, handling...")
```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### title (Line 74)

**Context:**

```swift
        
        // Send notification
        Task {
            let title = String(localized: "New Online Reservation")
            let message = String(localized: "New reservation for \(reservation.name) on \(reservation.dateString) at \(reservation.startTime)")
            
            await self.notifsManager.addNotification(
```

**Suggested Documentation:**

```swift
/// [Description of the title property]
```

### message (Line 75)

**Context:**

```swift
        // Send notification
        Task {
            let title = String(localized: "New Online Reservation")
            let message = String(localized: "New reservation for \(reservation.name) on \(reservation.dateString) at \(reservation.startTime)")
            
            await self.notifsManager.addNotification(
                title: title,
```

**Suggested Documentation:**

```swift
/// [Description of the message property]
```

### idString (Line 89)

**Context:**

```swift
    // Modified version of convertDictionaryToReservation to handle web reservations
    private func convertDictionaryToWebReservation(data: [String: Any], idString: String?) -> Reservation? {
        guard
            let idString = idString,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the idString property]
```

### id (Line 90)

**Context:**

```swift
    private func convertDictionaryToWebReservation(data: [String: Any], idString: String?) -> Reservation? {
        guard
            let idString = idString,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### name (Line 91)

**Context:**

```swift
        guard
            let idString = idString,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### phone (Line 92)

**Context:**

```swift
            let idString = idString,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the phone property]
```

### numberOfPersons (Line 93)

**Context:**

```swift
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### dateString (Line 94)

**Context:**

```swift
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### categoryRaw (Line 95)

**Context:**

```swift
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the categoryRaw property]
```

### category (Line 96)

**Context:**

```swift
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the category property]
```

### startTime (Line 97)

**Context:**

```swift
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 98)

**Context:**

```swift
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### acceptanceRaw (Line 99)

**Context:**

```swift
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
```

**Suggested Documentation:**

```swift
/// [Description of the acceptanceRaw property]
```

### acceptance (Line 100)

**Context:**

```swift
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
```

**Suggested Documentation:**

```swift
/// [Description of the acceptance property]
```

### statusRaw (Line 101)

**Context:**

```swift
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
```

**Suggested Documentation:**

```swift
/// [Description of the statusRaw property]
```

### status (Line 102)

**Context:**

```swift
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
```

**Suggested Documentation:**

```swift
/// [Description of the status property]
```

### reservationTypeRaw (Line 103)

**Context:**

```swift
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
```

**Suggested Documentation:**

```swift
/// [Description of the reservationTypeRaw property]
```

### reservationType (Line 104)

**Context:**

```swift
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval
```

**Suggested Documentation:**

```swift
/// [Description of the reservationType property]
```

### group (Line 105)

**Context:**

```swift
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval
        else {
```

**Suggested Documentation:**

```swift
/// [Description of the group property]
```

### creationTimestamp (Line 106)

**Context:**

```swift
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval
        else {
            return nil
```

**Suggested Documentation:**

```swift
/// [Description of the creationTimestamp property]
```

### lastEditedTimestamp (Line 107)

**Context:**

```swift
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval
        else {
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the lastEditedTimestamp property]
```

### preferredLanguage (Line 112)

**Context:**

```swift
            return nil
        }
        
        let preferredLanguage = data["preferredLanguage"] as? String
        
        // Email field is unique to web reservations
        let email = data["email"] as? String
```

**Suggested Documentation:**

```swift
/// [Description of the preferredLanguage property]
```

### email (Line 115)

**Context:**

```swift
        let preferredLanguage = data["preferredLanguage"] as? String
        
        // Email field is unique to web reservations
        let email = data["email"] as? String
        let source = data["source"] as? String
        
        // Prepare notes field with web reservation information
```

**Suggested Documentation:**

```swift
/// [Description of the email property]
```

### source (Line 116)

**Context:**

```swift
        
        // Email field is unique to web reservations
        let email = data["email"] as? String
        let source = data["source"] as? String
        
        // Prepare notes field with web reservation information
        var notesText = data["notes"] as? String ?? ""
```

**Suggested Documentation:**

```swift
/// [Description of the source property]
```

### notesText (Line 119)

**Context:**

```swift
        let source = data["source"] as? String
        
        // Prepare notes field with web reservation information
        var notesText = data["notes"] as? String ?? ""
        if let email = email {
            notesText += "\n\nEmail: \(email)"
        }
```

**Suggested Documentation:**

```swift
/// [Description of the notesText property]
```

### email (Line 120)

**Context:**

```swift
        
        // Prepare notes field with web reservation information
        var notesText = data["notes"] as? String ?? ""
        if let email = email {
            notesText += "\n\nEmail: \(email)"
        }
        if source == "web" {
```

**Suggested Documentation:**

```swift
/// [Description of the email property]
```

### newReservation (Line 157)

**Context:**

```swift
        logger.debug("Called approveWebReservation")
        
        // 1. Create a new reservation with the same details but a new UUID
        var newReservation = reservation
        newReservation.acceptance = .confirmed
        
        // 2. Assign tables if needed
```

**Suggested Documentation:**

```swift
/// [Description of the newReservation property]
```

### assignmentResult (Line 161)

**Context:**

```swift
        newReservation.acceptance = .confirmed
        
        // 2. Assign tables if needed
        let assignmentResult = layoutServices.assignTables(for: newReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            newReservation.tables = assignedTables
```

**Suggested Documentation:**

```swift
/// [Description of the assignmentResult property]
```

### assignedTables (Line 163)

**Context:**

```swift
        // 2. Assign tables if needed
        let assignmentResult = layoutServices.assignTables(for: newReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            newReservation.tables = assignedTables
            logger.debug("Successfully assigned tables for web reservation \(reservation.name)")
        case .failure:
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### dbRef (Line 177)

**Context:**

```swift
        // 4. Delete the original reservation from Firestore using async/await
        do {
            #if DEBUG
            let dbRef = backupService.db.collection("reservations")
            #else
            let dbRef = backupService.db.collection("reservations_release")
            #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 179)

**Context:**

```swift
            #if DEBUG
            let dbRef = backupService.db.collection("reservations")
            #else
            let dbRef = backupService.db.collection("reservations_release")
            #endif
            
            try await dbRef.document(reservation.id.uuidString.lowercased()).delete()
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### emailSent (Line 189)

**Context:**

```swift
        }
        
        // 5. Send confirmation email
        let emailSent = await self.emailService.sendConfirmationEmail(for: newReservation)
        if emailSent {
            logger.info("Confirmation email sent for reservation \(newReservation.name)")
        } else {
```

**Suggested Documentation:**

```swift
/// [Description of the emailSent property]
```

### declinedReservation (Line 205)

**Context:**

```swift
        logger.debug("Called declineWebReservation with reason: \(reason.rawValue)")
        
        // 1. Create a new reservation with the updated details
        var declinedReservation = reservation
        declinedReservation.acceptance = .na
        declinedReservation.status = .canceled
        declinedReservation.preferredLanguage = reservation.preferredLanguage
```

**Suggested Documentation:**

```swift
/// [Description of the declinedReservation property]
```

### declineNotes (Line 212)

**Context:**

```swift
        
        logger.debug("Preferred language is: \(declinedReservation.preferredLanguage ?? "Not set")")
        // 2. Add appropriate notes based on the decline reason
        let declineNotes = reason.notesText
        let additionalNotes = customNotes != nil && !customNotes!.isEmpty ? "\nAdditional notes: \(customNotes!)" : ""
        
        // 3. Ensure we preserve the email information
```

**Suggested Documentation:**

```swift
/// [Description of the declineNotes property]
```

### additionalNotes (Line 213)

**Context:**

```swift
        logger.debug("Preferred language is: \(declinedReservation.preferredLanguage ?? "Not set")")
        // 2. Add appropriate notes based on the decline reason
        let declineNotes = reason.notesText
        let additionalNotes = customNotes != nil && !customNotes!.isEmpty ? "\nAdditional notes: \(customNotes!)" : ""
        
        // 3. Ensure we preserve the email information
        var updatedNotes = ""
```

**Suggested Documentation:**

```swift
/// [Description of the additionalNotes property]
```

### updatedNotes (Line 216)

**Context:**

```swift
        let additionalNotes = customNotes != nil && !customNotes!.isEmpty ? "\nAdditional notes: \(customNotes!)" : ""
        
        // 3. Ensure we preserve the email information
        var updatedNotes = ""
        if let existingNotes = declinedReservation.notes {
            // Extract email from existing notes
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
```

**Suggested Documentation:**

```swift
/// [Description of the updatedNotes property]
```

### existingNotes (Line 217)

**Context:**

```swift
        
        // 3. Ensure we preserve the email information
        var updatedNotes = ""
        if let existingNotes = declinedReservation.notes {
            // Extract email from existing notes
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
```

**Suggested Documentation:**

```swift
/// [Description of the existingNotes property]
```

### emailRegex (Line 219)

**Context:**

```swift
        var updatedNotes = ""
        if let existingNotes = declinedReservation.notes {
            // Extract email from existing notes
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
            if let match = emailRegex?.firstMatch(in: existingNotes, range: range),
               let emailRange = Range(match.range(at: 1), in: existingNotes) {
```

**Suggested Documentation:**

```swift
/// [Description of the emailRegex property]
```

### range (Line 220)

**Context:**

```swift
        if let existingNotes = declinedReservation.notes {
            // Extract email from existing notes
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
            if let match = emailRegex?.firstMatch(in: existingNotes, range: range),
               let emailRange = Range(match.range(at: 1), in: existingNotes) {
                let email = String(existingNotes[emailRange])
```

**Suggested Documentation:**

```swift
/// [Description of the range property]
```

### match (Line 221)

**Context:**

```swift
            // Extract email from existing notes
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
            if let match = emailRegex?.firstMatch(in: existingNotes, range: range),
               let emailRange = Range(match.range(at: 1), in: existingNotes) {
                let email = String(existingNotes[emailRange])
                updatedNotes = "\(declineNotes)\(additionalNotes)\n\nEmail: \(email)\n[declined web reservation];"
```

**Suggested Documentation:**

```swift
/// [Description of the match property]
```

### emailRange (Line 222)

**Context:**

```swift
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
            if let match = emailRegex?.firstMatch(in: existingNotes, range: range),
               let emailRange = Range(match.range(at: 1), in: existingNotes) {
                let email = String(existingNotes[emailRange])
                updatedNotes = "\(declineNotes)\(additionalNotes)\n\nEmail: \(email)\n[declined web reservation];"
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the emailRange property]
```

### email (Line 223)

**Context:**

```swift
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
            if let match = emailRegex?.firstMatch(in: existingNotes, range: range),
               let emailRange = Range(match.range(at: 1), in: existingNotes) {
                let email = String(existingNotes[emailRange])
                updatedNotes = "\(declineNotes)\(additionalNotes)\n\nEmail: \(email)\n[declined web reservation];"
            } else {
                updatedNotes = "\(declineNotes)\(additionalNotes)\n\n[declined web reservation];"
```

**Suggested Documentation:**

```swift
/// [Description of the email property]
```

### dbRef (Line 237)

**Context:**

```swift
        // 4. Delete the original reservation from Firestore
        do {
            #if DEBUG
            let dbRef = backupService.db.collection("reservations")
            #else
            let dbRef = backupService.db.collection("reservations_release")
            #endif
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### dbRef (Line 239)

**Context:**

```swift
            #if DEBUG
            let dbRef = backupService.db.collection("reservations")
            #else
            let dbRef = backupService.db.collection("reservations_release")
            #endif
            
            try await dbRef.document(reservation.id.uuidString.lowercased()).delete()
```

**Suggested Documentation:**

```swift
/// [Description of the dbRef property]
```

### email (Line 252)

**Context:**

```swift
        addReservation(declinedReservation)
        
        // 6. Send decline notification email if email is available
        if let email = declinedReservation.emailAddress {
            let emailSent = await self.emailService.sendDeclineEmail(for: declinedReservation, email: email, reason: reason)
            if emailSent {
                logger.info("Decline email sent for reservation \(declinedReservation.name)")
```

**Suggested Documentation:**

```swift
/// [Description of the email property]
```

### emailSent (Line 253)

**Context:**

```swift
        
        // 6. Send decline notification email if email is available
        if let email = declinedReservation.emailAddress {
            let emailSent = await self.emailService.sendDeclineEmail(for: declinedReservation, email: email, reason: reason)
            if emailSent {
                logger.info("Decline email sent for reservation \(declinedReservation.name)")
            } else {
```

**Suggested Documentation:**

```swift
/// [Description of the emailSent property]
```


Total documentation suggestions: 60

