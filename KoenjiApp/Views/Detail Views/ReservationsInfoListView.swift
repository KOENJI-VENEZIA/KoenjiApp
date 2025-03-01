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
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
    
    
    var body: some View {
        VStack {
//            Color.clear.ignoresSafeArea()
            
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
    }
    
//    private func handleDeleteFromGroup(groupKey: String, offsets: IndexSet) {
//        // 1) Access the grouped reservations
//        let reservations = reservations(at: appState.selectedDate)
//        var grouped = groupByCategory(reservations)
//        
//        // 2) The reservations in this group
//        if var reservationsInGroup = grouped[groupKey] {
//            // 3) Get the items to delete
//            let toDelete = offsets.map { reservationsInGroup[$0] }
//            // 4) Actually remove them from your store
//            for reservation in toDelete {
//                if let idx = env.store.reservations.firstIndex(where: {
//                    $0.id == reservation.id
//                }) {
//                    env.reservationService.deleteReservations(
//                        at: IndexSet(integer: idx))
//                }
//            }
//            // 5) Optionally remove them from `grouped[groupKey]` if you want to keep a local copy
//            offsets.forEach { reservationsInGroup.remove(at: $0) }
//            grouped[groupKey] = reservationsInGroup
//        }
//    }
    
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
        env.store.reservations.filter { reservation in
            guard let reservationDate = reservation.normalizedDate else { return false }// Skip reservations with invalid times
            return reservationDate.isSameDay(as: date)
        }
    }
    
    func filterReservations(_ reservations: [Reservation]) -> [Reservation] {
        reservations.filter { reservation in
            return reservation.status != .canceled && reservation.reservationType != .waitingList
        }
    }
    
//    private func handleDelete(_ reservation: Reservation) {
//        if let idx = env.store.reservations.firstIndex(where: {
//            $0.id == reservation.id
//        }) {
//            env.reservationService.deleteReservations(at: IndexSet(integer: idx))
//        }
//    }
    
    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            withAnimation {
                updatedReservation.status = .canceled
                updatedReservation.tables = []
            }
        }
        env.reservationService.updateReservation(updatedReservation) {
            print("Update reservation.")
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
        env.reservationService.updateReservation(updatedReservation) {
            print("Update reservation.")
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
