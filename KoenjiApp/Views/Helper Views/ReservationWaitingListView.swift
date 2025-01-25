//
//  ReservationWaitingListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI

struct ReservationWaitingListView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @State private var selection = Set<UUID>()  // Multi-select
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.colorScheme) var colorScheme


    let activeReservations: [Reservation]
    var currentTime: Date
    var selectedCategory: Reservation.ReservationCategory
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
        VStack {
            
            List(selection: $selection) {
                let reservations = reservations(at: currentTime)
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
                                        handleConfirm(reservation)
                                        onConfirm(reservation)
                                    } label: {
                                        Label("Inserisci", systemImage: "arrowshape.turn.up.backward.2.circle.fill")
                                    }
                                    .tint(.blue)
                                }
                                .listRowSeparator(.visible) // Ensure dividers are visible
                                .listRowSeparatorTint(Color.white, edges: .bottom) // Customize divider color
                                
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
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Errore:"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        
    }
    
    private func handleDeleteFromGroup(groupKey: String, offsets: IndexSet) {
        // 1) Access the grouped reservations
        let reservations = reservations(at: currentTime)
        var grouped = groupByCategory(reservations)
        
        // 2) The reservations in this group
        if var reservationsInGroup = grouped[groupKey] {
            // 3) Get the items to delete
            let toDelete = offsets.map { reservationsInGroup[$0] }
            // 4) Actually remove them from your store
            for reservation in toDelete {
                if let idx = store.reservations.firstIndex(where: {
                    $0.id == reservation.id
                }), var reservation = store.reservations.first(where: { $0.id == reservation.id}) {
                    reservation.status = .canceled
                    reservation.tables = []
                    reservationService.updateReservation(reservation,
                        at: idx)
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
        store.reservations.filter { reservation in
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

        if let idx = store.reservations.firstIndex(where: {
            $0.id == reservation.id
        }), var reservation = store.reservations.first(where: { $0.id == reservation.id}) {
            reservation.status = .canceled
            reservation.tables = []
            reservationService.updateReservation(reservation,
                at: idx)
        }
    }
    
    private func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList {
        let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
                    // do actual saving logic here
                    updatedReservation.tables = assignedTables
                    updatedReservation.reservationType = .inAdvance
                    updatedReservation.status = .pending
                    reservationService.updateReservation(updatedReservation)

                }
            case .failure(let error):
                switch error {
                    case .noTablesLeft:
                        alertMessage = "Non ci sono tavoli disponibili."
                    case .insufficientTables:
                        alertMessage = "Non ci sono abbastanza tavoli per la prenotazione."
                    case .tableNotFound:
                        alertMessage = "Tavolo selezionato non trovato."
                    case .tableLocked:
                        alertMessage = "Il tavolo scelto è occupato o bloccato."
                    case .unknown:
                        alertMessage = "Errore sconosciuto."
                    }
                    showAlert = true
            }
        }
    }
}
