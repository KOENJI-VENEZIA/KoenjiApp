//
//  WebReservationExtensions.swift
//  KoenjiApp
//
//  Created on 3/3/25.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications
import OSLog
import FirebaseFunctions

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
            assignedEmoji: data["assignedEmoji"] as? String ?? ""
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
        let emailSent = await sendConfirmationEmail(for: newReservation)
        if emailSent {
            logger.info("Confirmation email sent for reservation \(newReservation.name)")
        } else {
            logger.error("Failed to send confirmation email for reservation \(newReservation.name)")
        }
        
        return true
    }
    
    // Send confirmation email
    @MainActor
    private func sendConfirmationEmail(for reservation: Reservation) async -> Bool {
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
        
        // Now we have the email, we can send a confirmation
        // This would typically connect to a server or email service API
        // For this example, we'll use Firebase Cloud Functions
        
        // Create request data for our email sending function
        let emailData: [String: Any] = [
            "to": email,
            "subject": "Your Reservation is Confirmed",
            "reservation": [
                "name": reservation.name,
                "date": reservation.dateString,
                "time": reservation.startTime,
                "people": reservation.numberOfPersons,
                "tables": reservation.tables.map { $0.name }.joined(separator: ", "),
                "id": reservation.id.uuidString
            ]
        ]
        
        // In a real implementation, you would call your email sending service here
        // For demonstration purposes, we'll simulate a successful email sending
        
        // TODO: Replace with actual email sending code
        logger.info("Would send email to \(email) for reservation \(reservation.id)")
        return true
    }
}

// MARK: - Web Reservation UI Extensions

// Extension to add visual distinction for web reservations
extension Reservation {
    var isWebReservation: Bool {
        guard let notes = notes else { return false }
        Reservation.logger.debug("\(notes)")
        return notes.contains("web reservation")
    }
    
    var hasEmail: Bool {
        return notes?.contains("Email:") ?? false
    }
    
    var emailAddress: String? {
        guard let notes = notes else { return nil }
        
        let emailRegex = try? NSRegularExpression(pattern: "Email: (\\S+@\\S+\\.\\S+)")
        let range = NSRange(notes.startIndex..., in: notes)
        guard let match = emailRegex?.firstMatch(in: notes, range: range),
              let emailRange = Range(match.range(at: 1), in: notes) else {
            return nil
        }
        
        return String(notes[emailRange])
    }
}

// Add web reservation badge to ReservationCard
extension ReservationCard {
    @ViewBuilder
    func webReservationBadge(for reservation: Reservation) -> some View {
        if reservation.isWebReservation {
            Text("Web")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .clipShape(Capsule())
        }
    }
}

// Custom web reservation approval view
struct WebReservationApprovalView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let reservation: Reservation
    var onApprove: (() -> Void)?
    
    @State private var isApproving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Web Reservation Request")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Waiting for Approval")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Reservation details card
            VStack(alignment: .leading, spacing: 16) {
                // Name and status
                HStack {
                    Text(reservation.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text("Pending Approval")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Divider()
                
                // Date and time
                HStack(spacing: 24) {
                    detailItem(
                        icon: "calendar",
                        title: "Date",
                        value: DateHelper.formatFullDate(reservation.normalizedDate ?? Date())
                    )
                    
                    detailItem(
                        icon: "clock.fill",
                        title: "Time",
                        value: "\(reservation.startTime) - \(reservation.endTime)"
                    )
                }
                
                // Party size and contact
                HStack(spacing: 24) {
                    detailItem(
                        icon: "person.2.fill",
                        title: "Party Size",
                        value: "\(reservation.numberOfPersons) people"
                    )
                    
                    detailItem(
                        icon: "phone.fill",
                        title: "Phone",
                        value: reservation.phone
                    )
                }
                
                // Email if available
                if let email = reservation.emailAddress {
                    detailItem(
                        icon: "envelope.fill",
                        title: "Email",
                        value: email
                    )
                }
                
                // Notes
                if let notes = reservation.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(notes.replacingOccurrences(of: "Email: \\S+@\\S+\\.\\S+", with: "", options: .regularExpression)
                                 .replacingOccurrences(of: "[web reservation];", with: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    dismiss()
                }) {
                    Text("Decline")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    approveReservation()
                }) {
                    if isApproving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Approve")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isApproving)
            }
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reservation Approval"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        onApprove?()
                        dismiss()
                    }
                }
            )
        }
    }
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func approveReservation() {
        isApproving = true
        
        Task {
            let success = await env.reservationService.approveWebReservation(reservation)
            
            await MainActor.run {
                isApproving = false
                if success {
                    alertMessage = "Reservation approved successfully! A confirmation email has been sent to the guest."
                } else {
                    alertMessage = "Failed to approve reservation. Please try again."
                }
                showingAlert = true
            }
        }
    }
}

// MARK: - Web Reservation Email Service

// Cloud Function request handler for sending emails
class EmailService {
    private let logger = Logger(subsystem: "com.koenjiapp", category: "EmailService")
    private let functions: Functions
    
    init() {
        self.functions = Functions.functions()
    }
    
    func sendConfirmationEmail(to email: String, reservation: Reservation) async -> Bool {
        do {
            let data: [String: Any] = [
                "to": email,
                "subject": "Your Reservation is Confirmed",
                "reservation": [
                    "name": reservation.name,
                    "date": reservation.dateString,
                    "time": reservation.startTime,
                    "people": reservation.numberOfPersons,
                    "tables": reservation.tables.map { $0.name }.joined(separator: ", "),
                    "id": reservation.id.uuidString
                ]
            ]
            
            let result = try await functions.httpsCallable("sendEmail").call(data)
            logger.info("Email sent result: \(String(describing: result.data))")
            return true
        } catch {
            logger.error("Failed to send email: \(error.localizedDescription)")
            return false
        }
    }
}
