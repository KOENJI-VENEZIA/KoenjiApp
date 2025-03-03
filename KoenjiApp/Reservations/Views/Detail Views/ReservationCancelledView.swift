//
//  ReservationCancelledView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI
import SwipeActions

struct ReservationCancelledView: View {
    @EnvironmentObject var env: AppDependencies

    @State private var selection = Set<UUID>()  // Multi-select
    @Environment(\.colorScheme) var colorScheme

    let activeReservations: [Reservation]
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
    
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
                                    .fontWeight(.bold)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                Text("\(grouped[groupKey]?.count ?? 0) cancellazioni")
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
                                        systemImage: "arrowshape.turn.up.backward.2.circle.fill",
                                        backgroundColor: .blue.opacity(0.2)
                                    ) {
                                        handleRestore(reservation)
                                        onRestore(reservation)
                                    }
                                    
                                }
                                .swipeActionCornerRadius(12)
                                .swipeMinimumDistance(40)
                                .swipeActionsMaskCornerRadius(12)
                                .listRowSeparator(.visible)
                                .listRowBackground(Color.clear)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                } else {
                    Text("(Nessuna cancellazione)" )
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
            .scrollContentBackground(.hidden)
            .listStyle(PlainListStyle())

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
            return reservation.status == .canceled
        }
    }
    
    private func handleRestore(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .canceled {
            let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                withAnimation {
                    updatedReservation.tables = assignedTables
                    updatedReservation.status = .pending
                }
                env.reservationService.updateReservation(updatedReservation) {
                    print("Restored reservation with tables.")
                }
            case .failure(let error):
                // If table assignment fails, still restore but without tables
                withAnimation {
                    updatedReservation.status = .pending
                    updatedReservation.tables = []
                    updatedReservation.notes = (updatedReservation.notes ?? "") + String(localized: "\n[Ripristinata senza tavoli - non è stato possibile riassegnare i tavoli automaticamente]")
                }
                env.reservationService.updateReservation(updatedReservation) {
                    print("Restored reservation without tables due to error: \(error)")
                }
            }
        }
    }
    

}
