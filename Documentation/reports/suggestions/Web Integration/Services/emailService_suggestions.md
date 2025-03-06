Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/Services/emailService.swift...
# Documentation Suggestions for emailService.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Web Integration/Services/emailService.swift
Total suggestions: 51

## Class Documentation (6)

### ConfirmationEmailData (Line 14)

**Context:**

```swift

// These types are Sendable for use with the rest of the app

struct ConfirmationEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
```

**Suggested Documentation:**

```swift
/// ConfirmationEmailData class.
///
/// [Add a description of what this class does and its responsibilities]
```

### DeclineEmailData (Line 26)

**Context:**

```swift
    let language: String
}

struct DeclineEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
```

**Suggested Documentation:**

```swift
/// DeclineEmailData class.
///
/// [Add a description of what this class does and its responsibilities]
```

### EmailType (Line 38)

**Context:**

```swift
    let language: String
}

enum EmailType: Sendable {
    case confirmation(ConfirmationEmailData)
    case decline(DeclineEmailData)
}
```

**Suggested Documentation:**

```swift
/// EmailType class.
///
/// [Add a description of what this class does and its responsibilities]
```

### doesn (Line 43)

**Context:**

```swift
    case decline(DeclineEmailData)
}

// This class doesn't try to be Sendable or use Swift's modern concurrency
// It's a completely old-school approach with dispatch queues
class LegacyEmailSender {
    // Serial queue to ensure one email at a time
```

**Suggested Documentation:**

```swift
/// doesn class.
///
/// [Add a description of what this class does and its responsibilities]
```

### LegacyEmailSender (Line 45)

**Context:**

```swift

// This class doesn't try to be Sendable or use Swift's modern concurrency
// It's a completely old-school approach with dispatch queues
class LegacyEmailSender {
    // Serial queue to ensure one email at a time
    private let serialQueue = DispatchQueue(label: "com.koenjiapp.emailQueue", qos: .userInitiated)
    private var isProcessing = false
```

**Suggested Documentation:**

```swift
/// LegacyEmailSender class.
///
/// [Add a description of what this class does and its responsibilities]
```

### EmailService (Line 135)

**Context:**

```swift
nonisolated(unsafe) private let emailSender = LegacyEmailSender()

@MainActor
class EmailService {
    private let logger = Logger(subsystem: "com.koenjiapp", category: "EmailService")

    init() {}
```

**Suggested Documentation:**

```swift
/// EmailService service.
///
/// [Add a description of what this service does and its responsibilities]
```

## Method Documentation (3)

### sendEmail (Line 53)

**Context:**

```swift
    private let functions = Functions.functions()
    private let logger = Logger(subsystem: "com.koenjiapp", category: "LegacyEmailSender")

    func sendEmail(emailType: EmailType, completionHandler: @escaping @Sendable (Bool) -> Void) {
        // Queue this operation
        serialQueue.async { [weak self] in
            guard let self = self else {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the sendEmail method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### sendConfirmationEmail (Line 140)

**Context:**

```swift

    init() {}

    func sendConfirmationEmail(for reservation: Reservation) async -> Bool {
        // Extract email from notes field if present
        guard let notes = reservation.notes else {
            logger.error("No notes field containing email for web reservation \(reservation.id)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the sendConfirmationEmail method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### sendDeclineEmail (Line 185)

**Context:**

```swift
        }
    }

    func sendDeclineEmail(for reservation: Reservation, email: String, reason: WebReservationDeclineReason) async -> Bool {
        // Create data structure
        let language = reservation.preferredLanguage ?? "en"
        let emailData = DeclineEmailData(
```

**Suggested Documentation:**

```swift
/// [Add a description of what the sendDeclineEmail method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (42)

### to (Line 15)

**Context:**

```swift
// These types are Sendable for use with the rest of the app

struct ConfirmationEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
```

**Suggested Documentation:**

```swift
/// [Description of the to property]
```

### subject (Line 16)

**Context:**

```swift

struct ConfirmationEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
```

**Suggested Documentation:**

```swift
/// [Description of the subject property]
```

### name (Line 17)

**Context:**

```swift
struct ConfirmationEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### dateString (Line 18)

**Context:**

```swift
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let tables: String
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### startTime (Line 19)

**Context:**

```swift
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let tables: String
    let id: String
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### numberOfPersons (Line 20)

**Context:**

```swift
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let tables: String
    let id: String
    let language: String
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### tables (Line 21)

**Context:**

```swift
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let tables: String
    let id: String
    let language: String
}
```

**Suggested Documentation:**

```swift
/// [Description of the tables property]
```

### id (Line 22)

**Context:**

```swift
    let startTime: String
    let numberOfPersons: Int
    let tables: String
    let id: String
    let language: String
}

```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### language (Line 23)

**Context:**

```swift
    let numberOfPersons: Int
    let tables: String
    let id: String
    let language: String
}

struct DeclineEmailData: Sendable {
```

**Suggested Documentation:**

```swift
/// [Description of the language property]
```

### to (Line 27)

**Context:**

```swift
}

struct DeclineEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
```

**Suggested Documentation:**

```swift
/// [Description of the to property]
```

### subject (Line 28)

**Context:**

```swift

struct DeclineEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
```

**Suggested Documentation:**

```swift
/// [Description of the subject property]
```

### name (Line 29)

**Context:**

```swift
struct DeclineEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
```

**Suggested Documentation:**

```swift
/// [Description of the name property]
```

### dateString (Line 30)

**Context:**

```swift
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let id: String
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### startTime (Line 31)

**Context:**

```swift
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let id: String
    let reason: String
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### numberOfPersons (Line 32)

**Context:**

```swift
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let id: String
    let reason: String
    let language: String
```

**Suggested Documentation:**

```swift
/// [Description of the numberOfPersons property]
```

### id (Line 33)

**Context:**

```swift
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let id: String
    let reason: String
    let language: String
}
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### reason (Line 34)

**Context:**

```swift
    let startTime: String
    let numberOfPersons: Int
    let id: String
    let reason: String
    let language: String
}

```

**Suggested Documentation:**

```swift
/// [Description of the reason property]
```

### language (Line 35)

**Context:**

```swift
    let numberOfPersons: Int
    let id: String
    let reason: String
    let language: String
}

enum EmailType: Sendable {
```

**Suggested Documentation:**

```swift
/// [Description of the language property]
```

### serialQueue (Line 47)

**Context:**

```swift
// It's a completely old-school approach with dispatch queues
class LegacyEmailSender {
    // Serial queue to ensure one email at a time
    private let serialQueue = DispatchQueue(label: "com.koenjiapp.emailQueue", qos: .userInitiated)
    private var isProcessing = false
    // Create a single Functions instance
    private let functions = Functions.functions()
```

**Suggested Documentation:**

```swift
/// [Description of the serialQueue property]
```

### isProcessing (Line 48)

**Context:**

```swift
class LegacyEmailSender {
    // Serial queue to ensure one email at a time
    private let serialQueue = DispatchQueue(label: "com.koenjiapp.emailQueue", qos: .userInitiated)
    private var isProcessing = false
    // Create a single Functions instance
    private let functions = Functions.functions()
    private let logger = Logger(subsystem: "com.koenjiapp", category: "LegacyEmailSender")
```

**Suggested Documentation:**

```swift
/// [Description of the isProcessing property]
```

### functions (Line 50)

**Context:**

```swift
    private let serialQueue = DispatchQueue(label: "com.koenjiapp.emailQueue", qos: .userInitiated)
    private var isProcessing = false
    // Create a single Functions instance
    private let functions = Functions.functions()
    private let logger = Logger(subsystem: "com.koenjiapp", category: "LegacyEmailSender")

    func sendEmail(emailType: EmailType, completionHandler: @escaping @Sendable (Bool) -> Void) {
```

**Suggested Documentation:**

```swift
/// [Description of the functions property]
```

### logger (Line 51)

**Context:**

```swift
    private var isProcessing = false
    // Create a single Functions instance
    private let functions = Functions.functions()
    private let logger = Logger(subsystem: "com.koenjiapp", category: "LegacyEmailSender")

    func sendEmail(emailType: EmailType, completionHandler: @escaping @Sendable (Bool) -> Void) {
        // Queue this operation
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### self (Line 56)

**Context:**

```swift
    func sendEmail(emailType: EmailType, completionHandler: @escaping @Sendable (Bool) -> Void) {
        // Queue this operation
        serialQueue.async { [weak self] in
            guard let self = self else {
                completionHandler(false)
                return
            }
```

**Suggested Documentation:**

```swift
/// [Description of the self property]
```

### parameters (Line 70)

**Context:**

```swift
            self.isProcessing = true

            // Prepare parameters based on email type
            let parameters: [String: Any]
            switch emailType {
            case .confirmation(let data):
                parameters = [
```

**Suggested Documentation:**

```swift
/// [Description of the parameters property]
```

### data (Line 72)

**Context:**

```swift
            // Prepare parameters based on email type
            let parameters: [String: Any]
            switch emailType {
            case .confirmation(let data):
                parameters = [
                    "to": data.to,
                    "subject": data.subject,
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### data (Line 87)

**Context:**

```swift
                        "preferredLanguage": data.language
                    ]
                ]
            case .decline(let data):
                parameters = [
                    "to": data.to,
                    "subject": data.subject,
```

**Suggested Documentation:**

```swift
/// [Description of the data property]
```

### success (Line 109)

**Context:**

```swift
                // Mark as no longer processing first to prevent deadlocks
                self.isProcessing = false

                var success = false
                if let error = error {
                    self.logger.error("Firebase error: \(error.localizedDescription)")
                } else if let resultDict = result?.data as? [String: Any],
```

**Suggested Documentation:**

```swift
/// [Description of the success property]
```

### error (Line 110)

**Context:**

```swift
                self.isProcessing = false

                var success = false
                if let error = error {
                    self.logger.error("Firebase error: \(error.localizedDescription)")
                } else if let resultDict = result?.data as? [String: Any],
                          let successValue = resultDict["success"] as? Bool {
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### resultDict (Line 112)

**Context:**

```swift
                var success = false
                if let error = error {
                    self.logger.error("Firebase error: \(error.localizedDescription)")
                } else if let resultDict = result?.data as? [String: Any],
                          let successValue = resultDict["success"] as? Bool {
                    self.logger.info("SuccessValue: \(successValue)")
                    self.logger.info("Result: \(resultDict)")
```

**Suggested Documentation:**

```swift
/// [Description of the resultDict property]
```

### successValue (Line 113)

**Context:**

```swift
                if let error = error {
                    self.logger.error("Firebase error: \(error.localizedDescription)")
                } else if let resultDict = result?.data as? [String: Any],
                          let successValue = resultDict["success"] as? Bool {
                    self.logger.info("SuccessValue: \(successValue)")
                    self.logger.info("Result: \(resultDict)")
                    success = successValue
```

**Suggested Documentation:**

```swift
/// [Description of the successValue property]
```

### emailSender (Line 132)

**Context:**

```swift
}

// Create a single instance for the application to use
nonisolated(unsafe) private let emailSender = LegacyEmailSender()

@MainActor
class EmailService {
```

**Suggested Documentation:**

```swift
/// [Description of the emailSender property]
```

### logger (Line 136)

**Context:**

```swift

@MainActor
class EmailService {
    private let logger = Logger(subsystem: "com.koenjiapp", category: "EmailService")

    init() {}

```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### notes (Line 142)

**Context:**

```swift

    func sendConfirmationEmail(for reservation: Reservation) async -> Bool {
        // Extract email from notes field if present
        guard let notes = reservation.notes else {
            logger.error("No notes field containing email for web reservation \(reservation.id)")
            return false
        }
```

**Suggested Documentation:**

```swift
/// [Description of the notes property]
```

### emailRegex (Line 148)

**Context:**

```swift
        }

        // Regex to extract email from notes
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range) else {
            logger.error("Could not find email in notes for web reservation \(reservation.id)")
```

**Suggested Documentation:**

```swift
/// [Description of the emailRegex property]
```

### range (Line 149)

**Context:**

```swift

        // Regex to extract email from notes
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range) else {
            logger.error("Could not find email in notes for web reservation \(reservation.id)")
            return false
```

**Suggested Documentation:**

```swift
/// [Description of the range property]
```

### match (Line 150)

**Context:**

```swift
        // Regex to extract email from notes
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range) else {
            logger.error("Could not find email in notes for web reservation \(reservation.id)")
            return false
        }
```

**Suggested Documentation:**

```swift
/// [Description of the match property]
```

### emailRange (Line 155)

**Context:**

```swift
            return false
        }

        guard let emailRange = Range(match.range(at: 1), in: notes) else {
            logger.error("Could not extract email from range for web reservation \(reservation.id)")
            return false
        }
```

**Suggested Documentation:**

```swift
/// [Description of the emailRange property]
```

### email (Line 160)

**Context:**

```swift
            return false
        }

        let email = String(notes[emailRange])
        let language = reservation.preferredLanguage ?? "en"

        // Create data structure
```

**Suggested Documentation:**

```swift
/// [Description of the email property]
```

### language (Line 161)

**Context:**

```swift
        }

        let email = String(notes[emailRange])
        let language = reservation.preferredLanguage ?? "en"

        // Create data structure
        let emailData = ConfirmationEmailData(
```

**Suggested Documentation:**

```swift
/// [Description of the language property]
```

### emailData (Line 164)

**Context:**

```swift
        let language = reservation.preferredLanguage ?? "en"

        // Create data structure
        let emailData = ConfirmationEmailData(
            to: email,
            subject: "Your Reservation is Confirmed",
            name: reservation.name,
```

**Suggested Documentation:**

```swift
/// [Description of the emailData property]
```

### language (Line 187)

**Context:**

```swift

    func sendDeclineEmail(for reservation: Reservation, email: String, reason: WebReservationDeclineReason) async -> Bool {
        // Create data structure
        let language = reservation.preferredLanguage ?? "en"
        let emailData = DeclineEmailData(
            to: email,
            subject: "Regarding Your Reservation Request",
```

**Suggested Documentation:**

```swift
/// [Description of the language property]
```

### emailData (Line 188)

**Context:**

```swift
    func sendDeclineEmail(for reservation: Reservation, email: String, reason: WebReservationDeclineReason) async -> Bool {
        // Create data structure
        let language = reservation.preferredLanguage ?? "en"
        let emailData = DeclineEmailData(
            to: email,
            subject: "Regarding Your Reservation Request",
            name: reservation.name,
```

**Suggested Documentation:**

```swift
/// [Description of the emailData property]
```


Total documentation suggestions: 51

