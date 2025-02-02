//
//  ReservationWaitingListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI

struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies

    @State private var selection = Set<UUID>()  // Multi-select
    @Environment(\.colorScheme) var colorScheme


    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
        VStack {
            
            List(selection: $selection) {
                let reservations = env.resCache.activeReservations
                let filtered = filterReservations(reservations)
                let grouped = groupByCategory(filtered)
                if !grouped.isEmpty {
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                        Section(
                            header: HStack(spacing: 10) {
                                Text(groupKey)
                                    .font(.title2)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("\(grouped[groupKey]?.count ?? 0) in lista d'attesa")
                                    .font(.title2)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                            }
                                .background(.clear)
                                .padding(.vertical, 4)
                        ) {
                            ForEach(grouped[groupKey] ?? []) { reservation in
                                
                                ReservationRows(
                                    reservation: reservation,
                                    onSelected: { newReservation in
                                        onEdit(newReservation)
                                    }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        handleDelete(reservation)
                                    } label: {
                                        Label("Cancella", systemImage: "x.circle.fill")
                                    }
                                    .tint(Color(hex: "#5c140f"))
                                    Button {
                                        env.reservationService.handleConfirm(reservation)
                                        onConfirm(reservation)
                                    } label: {
                                        Label("Inserisci", systemImage: "arrowshape.turn.up.backward.2.circle.fill")
                                    }
                                    .tint(.blue)
                                }
                                .listRowSeparator(.visible) // Ensure dividers are visible
                                
                            }
                            .onDelete { offsets in
                                handleDeleteFromGroup(
                                    groupKey: groupKey, offsets: offsets)
                            }
                            .listRowBackground(Color.clear)
                            
                            
                        }
                    }
                } else {
                    Text("(Nessuna prenotazione in lista d'attesa)" )
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
        .alert(isPresented: $env.pushAlerts.showAlert) {
            Alert(
                title: Text("Errore:"),
                message: Text(env.pushAlerts.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        
    }
    
    private func handleDeleteFromGroup(groupKey: String, offsets: IndexSet) {
        // 1) Access the grouped reservations
        let reservations = env.resCache.activeReservations
        var grouped = groupByCategory(reservations)
        
        // 2) The reservations in this group
        if var reservationsInGroup = grouped[groupKey] {
            // 3) Get the items to delete
            let toDelete = offsets.map { reservationsInGroup[$0] }
            // 4) Actually remove them from your store
            for reservation in toDelete {
                if let idx = env.store.reservations.firstIndex(where: {
                    $0.id == reservation.id
                }), var reservation = env.store.reservations.first(where: { $0.id == reservation.id}) {
                    reservation.status = .canceled
                    reservation.tables = []
                    env.reservationService.updateReservation(reservation,
                        at: idx) {
                        print("Update reservation.")
                    }
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

            let key = "\(category.localized.capitalized)"
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
            return reservation.reservationType == .waitingList
        }
    }
    
    private func handleDelete(_ reservation: Reservation) {

        if let idx = env.store.reservations.firstIndex(where: {
            $0.id == reservation.id
        }), var reservation = env.store.reservations.first(where: { $0.id == reservation.id}) {
            reservation.status = .canceled
            reservation.tables = []
            env.reservationService.updateReservation(reservation,
                at: idx) {
                print("Update reservation.")
            }
        }
    }
    
    
}
