//
//  WebReservationExtensions.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import SwiftUI
import OSLog

// Extension to add visual distinction for web reservations
extension Reservation {
    
    var isWebReservation: Bool {
        guard let notes = notes else { return false }
        Self.logger.debug("\(notes)")
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

// Extension to ReservationInfoCard to add web-specific actions
extension ReservationInfoCard {
    @ViewBuilder
    func webReservationActions(for reservation: Reservation) -> some View {
        if reservation.isWebReservation && reservation.acceptance == .toConfirm {
            VStack(spacing: 12) {
                Divider()
                
                HStack {
                    Text("Web Reservation Request")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                
                Button(action: {
                    Task {
                        await approveReservation(reservation)
                        onClose()
                    }
                }) {
                    Text("Approve Reservation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    // Logic to decline the reservation
                    let updatedReservation = env.reservationService.separateReservation(
                        reservation, 
                        notesToAdd: "Declined web reservation"
                    )
                    
                    env.reservationService.updateReservation(reservation, newReservation: updatedReservation) {
                        onClose()
                    }
                }) {
                    Text("Decline Request")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    private func approveReservation(_ reservation: Reservation) async {
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

// Add extension to ReservationCard to display web reservation badges
extension ReservationCard {
    var webReservationIndicator: some View {
        Group {
            if reservation.isWebReservation {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption2)
                    
                    if reservation.acceptance == .toConfirm {
                        Text("Web Pending")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Text("Web")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(reservation.acceptance == .toConfirm ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(reservation.acceptance == .toConfirm ? Color.orange : Color.blue, lineWidth: 0.5)
                )
            }
        }
    }
}

// View modifier to add visual distinction for web reservations
struct WebReservationModifier: ViewModifier {
    let reservation: Reservation
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if reservation.isWebReservation {
                        if reservation.acceptance == .toConfirm {
                            // Pending web reservation
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.orange)
                                
                                Text("Web Request")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                            .position(x: 75, y: 20)
                        } else {
                            // Confirmed web reservation
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                
                                Text("Web")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .position(x: 50, y: 20)
                        }
                    }
                }
            )
    }
}

// Extension to make the modifier easier to use
extension View {
    func webReservationStyle(for reservation: Reservation) -> some View {
        self.modifier(WebReservationModifier(reservation: reservation))
    }
}

// Extension to DatabaseView to add web reservation filter and badge
extension DatabaseView {
    // Enhanced web reservation filter with improved visual feedback

    var webReservationFilter: some View {
        Button(action: {
            // Clear other filters when toggling web pending to avoid filter conflicts
            if env.listView.selectedFilters.contains(.webPending) {
                env.listView.selectedFilters.remove(.webPending)
            } else {
                // Option 1: Replace all filters with just .webPending
                // env.listView.selectedFilters = [.webPending]
                
                // Option 2: Just add .webPending to existing filters
                env.listView.selectedFilters.insert(.webPending)
                
                // Print debug information
                logger.debug("Web pending filter enabled: \(env.listView.selectedFilters, privacy: .public)")
            }
            
            // Force refresh of the list view
            refreshID = UUID()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption)
                
                Text("Web Pending")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                env.listView.selectedFilters.contains(.webPending)
                ? Color.orange
                : Color.orange.opacity(0.1)
            )
            .foregroundColor(
                env.listView.selectedFilters.contains(.webPending)
                ? .white
                : .orange
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.orange, lineWidth: env.listView.selectedFilters.contains(.webPending) ? 0 : 1)
            )
        }
    }
}


// Update the filterReservations function to handle web reservations
extension DatabaseView {
    // Updated filterReservationsExpanded function that properly handles web reservations

    func filterReservationsExpanded(
        filters: Set<FilterOption>,
        searchText: String,
        currentReservations: [Reservation]
    ) -> [Reservation] {
        var filtered = currentReservations
        
        // Case 1: If ".webPending" is the only filter or one of the filters
        if filters.contains(.webPending) {
            // Only show web pending reservations
            filtered = filtered.filter { reservation in
                return reservation.isWebReservation && reservation.acceptance == .toConfirm
            }
            
            // Apply any additional filters if present
            if filters.contains(.canceled) {
                filtered = filtered.filter { $0.status == .canceled }
            }
            if filters.contains(.toHandle) {
                filtered = filtered.filter { $0.status == .toHandle }
            }
            if filters.contains(.deleted) {
                filtered = filtered.filter { $0.status == .deleted }
            }
            if filters.contains(.waitingList) {
                filtered = filtered.filter { $0.reservationType == .waitingList }
            }
            if filters.contains(.people) {
                filtered = filtered.filter { $0.numberOfPersons == filterPeople }
            }
            if filters.contains(.date), !filters.contains(.none) {
                filtered = filtered.filter { reservation in
                    if let date = reservation.normalizedDate {
                        return date >= filterStartDate && date <= filterEndDate
                    }
                    return false
                }
            }
        }
        // Case 2: Other filters are applied but not ".webPending"
        else if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
                if filters.contains(.toHandle) {
                    matches = matches && (reservation.status == .toHandle)
                }
                if filters.contains(.deleted) {
                    matches = matches && (reservation.status == .deleted)
                }
                if filters.contains(.waitingList) {
                    matches = matches && (reservation.reservationType == .waitingList)
                }
                if filters.contains(.people) {
                    matches = matches && (reservation.numberOfPersons == filterPeople)
                }
                if filters.contains(.date) {
                    if let date = reservation.normalizedDate {
                        matches = matches && (date >= filterStartDate && date <= filterEndDate)
                    } else {
                        matches = false
                    }
                }
                return matches
            }
        }
        // Case 3: No filters applied - show all active reservations except cancelled, deleted, etc.
        else {
            filtered = filtered.filter {
                $0.status != .canceled &&
                $0.status != .deleted &&
                $0.status != .toHandle &&
                $0.reservationType != .waitingList &&
                !($0.isWebReservation && $0.acceptance == .toConfirm) // Exclude web pending reservations by default
            }
        }
        
        // Apply search text filter regardless of other filters
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                let emailMatch = reservation.emailAddress?.lowercased().contains(lowercasedSearchText) ?? false
                let phoneMatch = reservation.phone.lowercased().contains(lowercasedSearchText)
                
                return nameMatch || tableMatch || notesMatch || emailMatch || phoneMatch
            }
        }
        
        return filtered
    }
}
