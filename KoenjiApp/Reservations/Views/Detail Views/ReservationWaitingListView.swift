//
//  ReservationWaitingListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI
import SwipeActions

struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = Set<UUID>()
    
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
        VStack {
            List(selection: $selection) {
                let reservations = reservations(at: Date())
                let filtered = filterReservations(reservations)
                let grouped = groupByCategory(filtered)
                
                if !grouped.isEmpty {
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                        Section(
                            header: HStack(spacing: 10) {
                                Text(groupKey)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("\(grouped[groupKey]?.count ?? 0) in lista d'attesa")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .background(.clear)
                            .padding(.vertical, 4)
                        ) {
                            ForEach(grouped[groupKey] ?? []) { reservation in
                                SwipeView {
                                    ReservationRows(
                                        reservation: reservation,
                                        onSelected: { newReservation in
                                            onEdit(newReservation)
                                        }
                                    )
                                } trailingActions: { _ in
                                    SwipeAction(
                                        systemImage: "checkmark.circle.fill",
                                        backgroundColor: .green.opacity(0.2)
                                    ) {
                                        handleConfirm(reservation)
                                        onConfirm(reservation)
                                    }
                                    
                                    SwipeAction(
                                        systemImage: "square.and.pencil",
                                        backgroundColor: .gray.opacity(0.2)
                                    ) {
                                        onEdit(reservation)
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
                } else {
                    Text("(Nessuna prenotazione in lista d'attesa)")
                        .font(.headline)
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
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
        .alert(isPresented: $env.pushAlerts.showAlert) {
            Alert(
                title: Text("Errore:"),
                message: Text(env.pushAlerts.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func groupByCategory(_ reservations: [Reservation]) -> [String: [Reservation]] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
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
            guard let reservationDate = reservation.normalizedDate else { return false }
            return reservationDate.isSameDay(as: date)
        }
    }
    
    func filterReservations(_ reservations: [Reservation]) -> [Reservation] {
        reservations.filter { reservation in
            return reservation.reservationType == .waitingList
        }
    }
    
    private func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            withAnimation {
                updatedReservation.tables = assignedTables
                updatedReservation.reservationType = .inAdvance
                updatedReservation.status = .pending
            }
            env.reservationService.updateReservation(updatedReservation) {
                print("Confirmed waiting list reservation with tables.")
            }
        case .failure(let error):
            withAnimation {
                updatedReservation.notes = (updatedReservation.notes ?? "") + String(localized: "\n[Non è stato possibile assegnare tavoli automaticamente - ") + "\(error)]"
            }
            env.reservationService.updateReservation(updatedReservation) {
                print("Could not assign tables due to error: \(error)")
            }
        }
    }
}
