//
//  WebReservationService.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications
import OSLog

// Extension to add web reservation handling to ReservationService
extension ReservationService {
    
    // Start listener specifically for web reservations
    @MainActor
    func startWebReservationListener() {
        #if DEBUG
        let dbRef = backupService.db.collection("reservations")
        #else
        let dbRef = backupService.db.collection("reservations_release")
        #endif
        
        // Listen for new web reservations with toConfirm status
        webReservationListener = dbRef.whereField("source", isEqualTo: "web")
             .whereField("acceptance", isEqualTo: "toConfirm")
             .addSnapshotListener { [weak self] snapshot, error in
                 if let error = error {
                     self?.logger.error("Error listening for web reservations: \(error)")
                     return
                 }
                 
                 self?.logger.debug("Listened for new web reservation!")
                 
                 guard let snapshot = snapshot else { return }
                 
                 var reservationsByID: [UUID: Reservation] = [:]
                 for document in snapshot.documents {
                     let data = document.data()
                     self?.logger.debug("DEBUG doc data: \(data)")
                     let idString = (data["id"] as? String ?? "").uppercased()
                     
                     if let reservation = self?.convertDictionaryToWebReservation(data: data, idString: idString) {
                         reservationsByID[reservation.id] = reservation
                         // Also upsert into SQLite:
                         self?.logger.debug("Created new reservation from web, handling...")
                         self?.handleNewWebReservation(reservation)
                     } else {
                         self?.logger.warning("convertDictionaryToWebReservation returned nil!")
                     }
                 }
             }
    }
    
    // Process new web reservation and send notification
    @MainActor private func handleNewWebReservation(_ reservation: Reservation) {
        logger.info("New web reservation received: \(reservation.id)")
        
        // Add to local database
        SQLiteManager.shared.insertReservation(reservation)
        
        // Add to in-memory store if not already there
        if !store.reservations.contains(where: { $0.id == reservation.id }) {
            DispatchQueue.main.async {
                self.store.reservations.append(reservation)
                self.store.reservations = Array(self.store.reservations)
                self.changedReservation = reservation
            }
        }
        
        // Send notification
        Task {
            let title = String(localized: "New Online Reservation")
            let message = String(localized: "New reservation for \(reservation.name) on \(reservation.dateString) at \(reservation.startTime)")
            
            await self.notifsManager.addNotification(
                title: title,
                message: message,
                type: .webReservation,
                reservation: reservation
            )
        }
    }
    
    // Modified version of convertDictionaryToReservation to handle web reservations
    private func convertDictionaryToWebReservation(data: [String: Any], idString: String?) -> Reservation? {
        guard
            let idString = idString,
            let id = UUID(uuidString: idString),
            let name = data["name"] as? String,
            let phone = data["phone"] as? String,
            let numberOfPersons = data["numberOfPersons"] as? Int,
            let dateString = data["dateString"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = Reservation.ReservationCategory(rawValue: categoryRaw),
            let startTime = data["startTime"] as? String,
            let endTime = data["endTime"] as? String,
            let acceptanceRaw = data["acceptance"] as? String,
            let acceptance = Reservation.Acceptance(rawValue: acceptanceRaw),
            let statusRaw = data["status"] as? String,
            let status = Reservation.ReservationStatus(rawValue: statusRaw),
            let reservationTypeRaw = data["reservationType"] as? String,
            let reservationType = Reservation.ReservationType(rawValue: reservationTypeRaw),
            let group = data["group"] as? Bool,
            let creationTimestamp = data["creationDate"] as? TimeInterval,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval
        else {
            return nil
        }
        
        let preferredLanguage = data["preferredLanguage"] as? String
        
        // Email field is unique to web reservations
        let email = data["email"] as? String
        let source = data["source"] as? String
        
        // Prepare notes field with web reservation information
        var notesText = data["notes"] as? String ?? ""
        if let email = email {
            notesText += "\n\nEmail: \(email)"
        }
        if source == "web" {
            notesText += "\n[web reservation];"
        }
        
        // Create reservation object
        return Reservation(
            id: id,
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notesText,
            tables: [],
            creationDate: Date(timeIntervalSince1970: creationTimestamp),
            lastEditedOn: Date(timeIntervalSince1970: lastEditedTimestamp),
            isMock: false,
            assignedEmoji: data["assignedEmoji"] as? String ?? "",
            preferredLanguage: preferredLanguage
        )
    }
    
    // Approve a web reservation and send confirmation email
    @MainActor
    func approveWebReservation(_ reservation: Reservation) async -> Bool {
        logger.debug("Called approveWebReservation")
        
        // 1. Create a new reservation with the same details but a new UUID
        var newReservation = reservation
        newReservation.acceptance = .confirmed
        
        // 2. Assign tables if needed
        let assignmentResult = layoutServices.assignTables(for: newReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            newReservation.tables = assignedTables
            logger.debug("Successfully assigned tables for web reservation \(reservation.name)")
        case .failure:
            // Even if table assignment fails, we still want to approve the reservation
            logger.warning("Failed to assign tables for web reservation \(reservation.name)")
        }
        
        // 3. Add the new reservation to your local store
        addReservation(newReservation)
        
        // 4. Delete the original reservation from Firestore using async/await
        do {
            #if DEBUG
            let dbRef = backupService.db.collection("reservations")
            #else
            let dbRef = backupService.db.collection("reservations_release")
            #endif
            
            try await dbRef.document(reservation.id.uuidString.lowercased()).delete()
            logger.debug("Original web reservation deleted successfully")
        } catch {
            logger.error("Error deleting original web reservation: \(error)")
        }
        
        // 5. Send confirmation email
        let emailSent = await self.emailService.sendConfirmationEmail(for: newReservation)
        if emailSent {
            logger.info("Confirmation email sent for reservation \(newReservation.name)")
        } else {
            logger.error("Failed to send confirmation email for reservation \(newReservation.name)")
        }
        
        return true
    }
    
    /// Decline a web reservation and update its status
    @MainActor
    func declineWebReservation(_ reservation: Reservation, reason: WebReservationDeclineReason, customNotes: String? = nil) async -> Bool {
        logger.debug("Called declineWebReservation with reason: \(reason.rawValue)")
        
        // 1. Create a new reservation with the updated details
        var declinedReservation = reservation
        declinedReservation.acceptance = .na
        declinedReservation.status = .canceled
        declinedReservation.preferredLanguage = reservation.preferredLanguage
        
        logger.debug("Preferred language is: \(declinedReservation.preferredLanguage ?? "Not set")")
        // 2. Add appropriate notes based on the decline reason
        let declineNotes = reason.notesText
        let additionalNotes = customNotes != nil && !customNotes!.isEmpty ? "\nAdditional notes: \(customNotes!)" : ""
        
        // 3. Ensure we preserve the email information
        var updatedNotes = ""
        if let existingNotes = declinedReservation.notes {
            // Extract email from existing notes
            let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
            let range = NSRange(existingNotes.startIndex..., in: existingNotes)
            if let match = emailRegex?.firstMatch(in: existingNotes, range: range),
               let emailRange = Range(match.range(at: 1), in: existingNotes) {
                let email = String(existingNotes[emailRange])
                updatedNotes = "\(declineNotes)\(additionalNotes)\n\nEmail: \(email)\n[declined web reservation];"
            } else {
                updatedNotes = "\(declineNotes)\(additionalNotes)\n\n[declined web reservation];"
            }
        } else {
            updatedNotes = "\(declineNotes)\(additionalNotes)\n\n[declined web reservation];"
        }
        
        declinedReservation.notes = updatedNotes
        
        // 4. Delete the original reservation from Firestore
        do {
            #if DEBUG
            let dbRef = backupService.db.collection("reservations")
            #else
            let dbRef = backupService.db.collection("reservations_release")
            #endif
            
            try await dbRef.document(reservation.id.uuidString.lowercased()).delete()
            logger.debug("Original web reservation deleted successfully")
        } catch {
            logger.error("Error deleting original web reservation: \(error)")
        }
        
        // 5. Add the declined reservation to the local store
        addReservation(declinedReservation)
        
        // 6. Send decline notification email if email is available
        if let email = declinedReservation.emailAddress {
            let emailSent = await self.emailService.sendDeclineEmail(for: declinedReservation, email: email, reason: reason)
            if emailSent {
                logger.info("Decline email sent for reservation \(declinedReservation.name)")
            } else {
                logger.error("Failed to send decline email for reservation \(declinedReservation.name)")
            }
        }
        
        return true
    }
}
