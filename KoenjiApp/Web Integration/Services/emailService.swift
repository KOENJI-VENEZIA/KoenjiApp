//
//  EmailService.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import Foundation
import FirebaseFunctions
import OSLog

// These types are Sendable for use with the rest of the app

struct ConfirmationEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let tables: String
    let id: String
    let language: String
}

struct DeclineEmailData: Sendable {
    let to: String
    let subject: String
    let name: String
    let dateString: String
    let startTime: String
    let numberOfPersons: Int
    let id: String
    let reason: String
    let language: String
}

enum EmailType: Sendable {
    case confirmation(ConfirmationEmailData)
    case decline(DeclineEmailData)
}

// This class doesn't try to be Sendable or use Swift's modern concurrency
// It's a completely old-school approach with dispatch queues
class LegacyEmailSender {
    // Serial queue to ensure one email at a time
    private let serialQueue = DispatchQueue(label: "com.koenjiapp.emailQueue", qos: .userInitiated)
    private var isProcessing = false
    // Create a single Functions instance
    private let functions = Functions.functions()
    private let logger = Logger(subsystem: "com.koenjiapp", category: "LegacyEmailSender")

    func sendEmail(emailType: EmailType, completionHandler: @escaping @Sendable (Bool) -> Void) {
        // Queue this operation
        serialQueue.async { [weak self] in
            guard let self = self else {
                completionHandler(false)
                return
            }

            // Wait until any previous operation completes
            while self.isProcessing {
                Thread.sleep(forTimeInterval: 0.1)
            }

            // Mark as processing
            self.isProcessing = true

            // Prepare parameters based on email type
            let parameters: [String: Any]
            switch emailType {
            case .confirmation(let data):
                parameters = [
                    "to": data.to,
                    "subject": data.subject,
                    "action": "confirm",
                    "reservation": [
                        "name": data.name,
                        "date": data.dateString,
                        "time": data.startTime,
                        "people": data.numberOfPersons,
                        "tables": data.tables,
                        "id": data.id,
                        "preferredLanguage": data.language
                    ]
                ]
            case .decline(let data):
                parameters = [
                    "to": data.to,
                    "subject": data.subject,
                    "action": "decline",
                    "reservation": [
                        "name": data.name,
                        "date": data.dateString,
                        "time": data.startTime,
                        "people": data.numberOfPersons,
                        "id": data.id,
                        "reason": data.reason,
                        "preferredLanguage": data.language
                    ]
                ]
            }

            // Make the call - Move the completion handler call inside this callback
            self.functions.httpsCallable("sendEmail").call(parameters) { result, error in
                // Mark as no longer processing first to prevent deadlocks
                self.isProcessing = false

                var success = false
                if let error = error {
                    self.logger.error("Firebase error: \(error.localizedDescription)")
                } else if let resultDict = result?.data as? [String: Any],
                          let successValue = resultDict["success"] as? Bool {
                    self.logger.info("SuccessValue: \(successValue)")
                    self.logger.info("Result: \(resultDict)")
                    success = successValue
                } else {
                    // If we can't extract a success value but got a result, assume success
                    success = true
                }

                // Call completion handler on the main queue from inside the Firebase callback
                DispatchQueue.main.async {
                    completionHandler(success)
                }
            }
        }
    }
}

// Create a single instance for the application to use
nonisolated(unsafe) private let emailSender = LegacyEmailSender()

@MainActor
class EmailService {
    private let logger = Logger(subsystem: "com.koenjiapp", category: "EmailService")

    init() {}

    func sendConfirmationEmail(for reservation: Reservation) async -> Bool {
        // Extract email from notes field if present
        guard let notes = reservation.notes else {
            logger.error("No notes field containing email for web reservation \(reservation.id)")
            return false
        }

        // Regex to extract email from notes
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range) else {
            logger.error("Could not find email in notes for web reservation \(reservation.id)")
            return false
        }

        guard let emailRange = Range(match.range(at: 1), in: notes) else {
            logger.error("Could not extract email from range for web reservation \(reservation.id)")
            return false
        }

        let email = String(notes[emailRange])
        let language = reservation.preferredLanguage ?? "en"

        // Create data structure
        let emailData = ConfirmationEmailData(
            to: email,
            subject: "Your Reservation is Confirmed",
            name: reservation.name,
            dateString: reservation.dateString,
            startTime: reservation.startTime,
            numberOfPersons: reservation.numberOfPersons,
            tables: reservation.tables.map { $0.name }.joined(separator: ", "),
            id: reservation.id.uuidString,
            language: language // Add language parameter
        )

        // Bridge to async/await at the last moment
        return await withCheckedContinuation { continuation in
            emailSender.sendEmail(emailType: .confirmation(emailData)) { success in
                self.logger.info("Confirmation email sent successfully: \(success)")
                continuation.resume(returning: success)
            }
        }
    }

    func sendDeclineEmail(for reservation: Reservation, email: String, reason: WebReservationDeclineReason) async -> Bool {
        // Create data structure
        let language = reservation.preferredLanguage ?? "en"
        let emailData = DeclineEmailData(
            to: email,
            subject: "Regarding Your Reservation Request",
            name: reservation.name,
            dateString: reservation.dateString,
            startTime: reservation.startTime,
            numberOfPersons: reservation.numberOfPersons,
            id: reservation.id.uuidString,
            reason: reason.rawValue,
            language: language // Add language parameter
        )

        // Bridge to async/await at the last moment
        return await withCheckedContinuation { continuation in
            emailSender.sendEmail(emailType: .decline(emailData)) { success in
                self.logger.info("Decline email sent successfully: \(success)")
                continuation.resume(returning: success)
            }
        }
    }
}

