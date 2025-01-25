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
    
    @Binding var isShowingFullImage: Bool


    var body: some View {
        if let reservation = store.reservations.first(where: { $0.id == reservationID }) {

            VStack(alignment: .leading, spacing: 20) {
                ScrollView {
                    VStack (spacing: 20) {
                        Group {
                            HStack {
                                Text("Dettagli")
                                    .font(.headline)
                                Spacer()
                                if let reservationImage = reservation.image {
                                    reservationImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                        .clipped()
                                        .onTapGesture {
                                            withAnimation {
                                                isShowingFullImage = true // Show the full image when tapped
                                            }
                                        }
                                        .sheet(isPresented: $isShowingFullImage) {
                                            VStack {
                                                Spacer()
                                                reservationImage
                                                    .resizable()
                                                    .scaledToFit() // Show the full image
                                                Spacer()
                                            }
                                            .background(Color.black.edgesIgnoringSafeArea(.all)) // Optional: Fullscreen background color
                                        }
                                } else {
                                    Image(systemName: "person.2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .padding()
                        }
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
                                Text(
                                    "\(DateHelper.dayOfWeek(for: reservation.cachedNormalizedDate ?? Calendar.current.startOfDay(for: Date())))\n\(DateHelper.formatFullDate(reservation.cachedNormalizedDate ?? Date()))"
                                )
                                .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Orario:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(reservation.startTime) - \(reservation.endTime)")
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Tavoli:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(reservation.tables.map(\.name).joined(separator: ", "))")
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
                                Text(reservation.category.localized.capitalized)
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Stato:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(
                                    reservation.reservationType != .waitingList
                                    ? reservation.status.localized.capitalized : "N/A")
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                Text("Tipologia:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(reservation.reservationType.localized.capitalized)
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
                    }
                }

                HStack {  // Close Button
                    Button(action: onEdit) {
                        Text("Modifica")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .background(Color.clear)
                    }
                }
                .padding(.vertical)

            }
            .padding()
        }
    }
}
