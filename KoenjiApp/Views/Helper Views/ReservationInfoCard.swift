//
//  ReservationInfoCard.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 12/1/25.
//


import SwiftUI

struct ReservationInfoCard: View {
    @EnvironmentObject var store: ReservationStore
    let reservationID: UUID
    var onClose: () -> Void
    var onEdit: () -> Void

    var body: some View {
        if let reservation = store.reservations.first(where: { $0.id == reservationID }) {
            
            VStack(alignment: .center, spacing: 12) {
                Text("Dettagli Prenotazione")
                    .font(.headline)
                    .padding()
                // Guest Name and Phone
                Group {
                    HStack {
                        Text("Nome:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(reservation.name)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Telefono:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(reservation.phone)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Date and Time
                Group {
                    HStack {
                        Text("Data:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(DateHelper.dayOfWeek(for: DateHelper.parseFullDate(reservation.dateString) ?? Calendar.current.startOfDay(for: Date()))) - \(reservation.dateString)")
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Orario:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(reservation.startTime) - \(reservation.endTime)")
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Category, Status, and Type
                Group {
                    HStack {
                        Text("Categoria:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(reservation.category.rawValue.capitalized)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Stato:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(reservation.status.rawValue.capitalized)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Tipologia:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(reservation.reservationType.rawValue.capitalized)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Notes
                VStack(alignment: .center) {
                    Text("Note:")
                        .fontWeight(.semibold)
                        .padding()
                    ScrollView {
                        Text(reservation.notes ?? "(Nessuna nota)")
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                }
                
                
                HStack {// Close Button
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                    }
                    .padding()
                    
                    Button(action: onClose) {
                        Text("Close")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                    }
                    .padding()
                }
            }
            .padding()
        }
        }
}
