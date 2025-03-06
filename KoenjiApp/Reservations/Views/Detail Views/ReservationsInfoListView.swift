//
//  ReservationsInfoListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI
import Foundation
import SwipeActions

struct ReservationsInfoListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
    
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading reservations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    let reservations = reservations(at: appState.selectedDate)
                    let filtered = filterReservations(reservations)
                    let grouped = groupByCategory(filtered)
                    
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                        Section(
                            header: HStack(spacing: 10) {
                                Text(groupKey)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("\(grouped[groupKey]?.count ?? 0) \(TextHelper.pluralized("prenotazione", "prenotazioni", grouped[groupKey]?.count ?? 0))")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .background(.clear)
                            .padding(.vertical, 4)
                        ) {
                            if let reservationsInGroup = grouped[groupKey] {
                                ForEach(reservationsInGroup) { reservation in
                                    SwipeView {
                                        ReservationRows(
                                            reservation: reservation,
                                            onSelected: { newReservation in
                                                onEdit(newReservation)
                                            }
                                        )
                                        .onTapGesture(count: 2) {
                                            onEdit(reservation)
                                        }
                                    } trailingActions: { _ in
                                        SwipeAction (
                                            systemImage: "x.circle.fill",
                                            backgroundColor: Color(hex: "#5c140f").opacity(0.2)
                                            
                                        ) {
                                            handleCancelled(reservation)
                                            onCancelled(reservation)
                                        }
                                        
                                        SwipeAction (
                                            systemImage: "square.and.pencil",
                                            backgroundColor: .gray.opacity(0.2)
                                            
                                        ) {
                                            onEdit(reservation)
                                        }
                                        
                                        SwipeAction (
                                            systemImage: "arrowshape.turn.up.backward.badge.clock",
                                            backgroundColor: .indigo.opacity(0.2)
                                            
                                        ) {
                                            showReservationInTime(reservation)
                                        }
                                        
                                    }
                                    .swipeActionCornerRadius(12)
                                    .swipeMinimumDistance(40)
                                    .swipeActionsMaskCornerRadius(12)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    
                    if grouped.isEmpty {
                        Section {
                            Text("Nessuna prenotazione per la giornata")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color.clear)
                                .padding()
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            
            Button(action: onClose) {
                Text("Chiudi")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color.clear)
        .onAppear {
            loadReservations()
        }
        .onChange(of: appState.selectedDate) { _, _ in
            loadReservations()
        }
        .onChange(of: appState.changedReservation) { _, _ in
            loadReservations()
        }
    }
    
    private func loadReservations() {
        isLoading = true
        Task {
            do {
                try await env.resCache.fetchReservations(for: appState.selectedDate)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("Error fetching reservations: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func groupByCategory(_ activeReservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
        for reservation in activeReservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
            var category: Reservation.ReservationCategory = .lunch
           
            if reservation.category == .dinner {
                category = .dinner
            }

            let key = "\(category.localized.uppercased())"
            grouped[key, default: []].append(reservation)
        }

        return grouped
    }
    
    func reservations(at date: Date) -> [Reservation] {
        return env.resCache.reservations(for: date)
    }
    
    func filterReservations(_ reservations: [Reservation]) -> [Reservation] {
        reservations.filter { reservation in
            return reservation.status != .canceled && reservation.reservationType != .waitingList
        }
    }
    
    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            withAnimation {
                updatedReservation.status = .canceled
                updatedReservation.tables = []
            }
        }
        
        Task {
            do {
                await env.reservationService.updateReservation(updatedReservation) {
                    print("Update reservation.")
                }
                
                // Refresh the reservations after update
                try await env.resCache.fetchReservations(for: appState.selectedDate)
            } catch {
                print("Error updating reservation: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func showReservationInTime(_ reservation: Reservation) {
        if let reservationStart = reservation.startTimeDate {
            let combinedDate = DateHelper.combine(date: appState.selectedDate, time: reservationStart)
            
            appState.selectedDate = combinedDate
        }
    }
    
    private func markReservationStatus(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .pending || updatedReservation.status == .late {
            updatedReservation.status = .showedUp
        }
        else if updatedReservation.startTimeDate != nil {
            updatedReservation.status = .pending
        }
        
        Task {
            do {
                await env.reservationService.updateReservation(updatedReservation) {
                    print("Update reservation.")
                }
                
                // Refresh the reservations after update
                try await env.resCache.fetchReservations(for: appState.selectedDate)
            } catch {
                print("Error updating reservation status: \(error.localizedDescription)")
            }
        }
    }
}

struct ReservationRows: View {
    let reservation: Reservation
    var onSelected: (Reservation) -> Void
    var body: some View {
         
        VStack(spacing: 12) {
            HStack {
                Text("\(reservation.name), \(reservation.numberOfPersons) p.")
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                
                Label(reservation.status.localized.capitalized, systemImage: statusIcon(for: reservation.status))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(reservation.status.color.opacity(0.12))
                    .foregroundColor(reservation.status.color)
                    .clipShape(Capsule())
            }
            
            HStack {
                Label("\(reservation.startTime) - \(reservation.endTime)", systemImage: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                
                if !reservation.tables.isEmpty {
                    Label(reservation.tables.map(\.name).joined(separator: ", "), systemImage: "tablecells")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(reservation.assignedColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 4)
    }
    
    private func statusIcon(for status: Reservation.ReservationStatus) -> String {
        switch status {
        case .showedUp: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
}
