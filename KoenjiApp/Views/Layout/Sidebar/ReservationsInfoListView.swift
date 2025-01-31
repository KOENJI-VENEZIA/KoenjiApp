//
//  ReservationsInfoListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI
import Foundation

struct ReservationsInfoListView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @State private var selection = Set<UUID>()  // Multi-select
    @Environment(\.colorScheme) var colorScheme
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onCancelled: (Reservation) -> Void
    
    
    var body: some View {
        VStack {
//            Color.clear.ignoresSafeArea()
            
            List(selection: $selection) {
                let reservations = resCache.activeReservations
                let filtered = filterReservations(reservations)
                let grouped = groupByCategory(filtered)
                if !grouped.isEmpty {
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                        Section(
                            header: HStack(spacing: 10) {
                                Text(groupKey)
                                    .font(.title2)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("\(grouped[groupKey]?.count ?? 0) \(TextHelper.pluralized("prenotazione", "prenotazioni", grouped[groupKey]?.count ?? 0))")

                                    .font(.title2)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                                .background(.clear)
                                .padding(.vertical, 4)
                        ) {
                            ForEach(grouped[groupKey] ?? []) { reservation in
                                let whichIconForStatus = {
                                    if reservation.status == .pending { return "checkmark.circle" } else if reservation.status == .late { return "clock.badge.exclamationmark.fill" } else if reservation.status == .showedUp { return "stopwatch.fill" } else {
                                        return "questionmark.circle.fill"
                                    }
                                }()
                                
                                let whichColorForStatus = {
                                    if reservation.status == .pending || reservation.status == .late { return Color.green } else if reservation.status == .showedUp { return Color.gray} else { return Color.gray}
                                }()
                                
                                ReservationRows(
                                    reservation: reservation,
                                    onSelected: { newReservation in
                                        onEdit(newReservation)
                                    }
                                )
                                .onTapGesture(count: 2) {
                                    onEdit(reservation)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        handleCancelled(reservation)
                                        onCancelled(reservation)
                                    } label: {
                                        Label("Cancellazione", systemImage: "x.circle.fill")
                                    }
                                    .tint(Color(hex: "#5c140f"))
                                    
                                    Button {
                                        markReservationStatus(reservation)
                                        onEdit(reservation)
                                    } label: {
                                        Label("Stato", systemImage: whichIconForStatus)
                                    }
                                    .tint(whichColorForStatus)
                                    
                                    Button {
                                        showReservationInTime(reservation)
                                    } label: {
                                        Label("Mostra", systemImage: "arrowshape.turn.up.backward.badge.clock.fill")
                                    }
                                    .tint(.indigo)
                                }
                                .listRowSeparator(.visible) // Ensure dividers are visible
//                                .listRowSeparatorTint(Color.white, edges: .bottom) // Customize divider color
                                
                            }
                            .onDelete { offsets in
                                handleDeleteFromGroup(
                                    groupKey: groupKey, offsets: offsets)
                            }
                            .listRowBackground(Color.clear)
                            
                            
                        }
                    }
                } else {
                    Text("(Nessuna prenotazione per la giornata)" )
                        .font(.headline)
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
                
                Section {
                    
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
            }
            .scrollContentBackground(.hidden) // Removes the List's default background (iOS 16+)
            .listStyle(GroupedListStyle())
            
            Button(action: onClose) {
                Text("Chiudi")
                    .font(.headline)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }
    
    private func handleDeleteFromGroup(groupKey: String, offsets: IndexSet) {
        // 1) Access the grouped reservations
        let reservations = reservations(at: appState.selectedDate)
        var grouped = groupByCategory(reservations)
        
        // 2) The reservations in this group
        if var reservationsInGroup = grouped[groupKey] {
            // 3) Get the items to delete
            let toDelete = offsets.map { reservationsInGroup[$0] }
            // 4) Actually remove them from your store
            for reservation in toDelete {
                if let idx = store.reservations.firstIndex(where: {
                    $0.id == reservation.id
                }) {
                    reservationService.deleteReservations(
                        at: IndexSet(integer: idx))
                }
            }
            // 5) Optionally remove them from `grouped[groupKey]` if you want to keep a local copy
            offsets.forEach { reservationsInGroup.remove(at: $0) }
            grouped[groupKey] = reservationsInGroup
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
        store.reservations.filter { reservation in
            guard let reservationDate = reservation.normalizedDate else { return false }// Skip reservations with invalid times
            return reservationDate.isSameDay(as: date)
        }
    }
    
    func filterReservations(_ reservations: [Reservation]) -> [Reservation] {
        reservations.filter { reservation in
            return reservation.status != .canceled && reservation.reservationType != .waitingList
        }
    }
    
    private func handleDelete(_ reservation: Reservation) {
        if let idx = store.reservations.firstIndex(where: {
            $0.id == reservation.id
        }) {
            reservationService.deleteReservations(at: IndexSet(integer: idx))
        }
    }
    
    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            withAnimation {
                updatedReservation.status = .canceled
            }
        }
        reservationService.updateReservation(updatedReservation)
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
            reservationService.updateReservation(updatedReservation)
    }
}

struct ReservationRows: View {
    let reservation: Reservation
    var onSelected: (Reservation) -> Void
    var body: some View {
         
        ZStack {
            VStack{
                HStack {
                    Text("\(reservation.name), \(reservation.numberOfPersons) p.")
                        .font(.headline)
                        .bold()
                        .lineLimit(1) // Restrict to one line
                        .truncationMode(.tail) // Show "..." at the end if truncated
                    Spacer()
                    
                    Text("\(reservation.reservationType != .waitingList ? reservation.status.localized.capitalized : "N/A")")
                        .font(.subheadline)
                        .lineLimit(1) // Restrict to one line
                        .truncationMode(.tail) // Show "..." at the end if truncated

                }
                HStack {
                    
                    Text("\(reservation.startTime) - \(reservation.endTime)")
                        .font(.subheadline)

                    
                    Spacer()
                    
                        Text("Tavoli: \(reservation.tables.map(\.name).joined(separator: ", "))")
                        .font(.subheadline)

                }
            }
        }
        .padding(2)
//        .contentShape(Rectangle())  // Make the entire row tappable
//        .background(
//                RoundedRectangle(cornerRadius: 12) // Add a rounded rectangle
//                    .fill(Color.accentColor.opacity(0.4))
//            )
        .contextMenu {
            Button("Modifica") {
                onSelected(reservation)
                
            }
            Button("Elimina", role: .destructive) {
                //placeholder
            }
        }
    }
}
