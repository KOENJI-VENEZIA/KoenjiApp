//
//  InspectorSideView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//

import SwiftUI

struct InspectorSideView: View {
    @Binding var selectedReservation: Reservation?
    @Binding var currentReservation: Reservation?
    @Binding var showInspector: Bool
    @Binding var showingEditReservation: Bool
    @Binding var sidebarColor: Color // Default
    @Binding var changedReservation: Reservation?
    @Binding var isShowingFullImage: Bool
    @State private var selectedView: SelectedView = .info
    var activeReservations: [Reservation]
    @Binding var currentTime: Date
    var selectedCategory: Reservation.ReservationCategory
    
    
    enum SelectedView {
        case info
        case cancelled
        case waiting
    }
    // MARK: - Body
    var body: some View {

        ZStack {
            Color(sidebarColor)
                .ignoresSafeArea()

            VStack {
                
//                Rectangle()
//                    .fill(.clear)
//                    .background(.clear)
//                    .frame(width: 100, height: 50)
                
                Picker("Dettagli", selection: $selectedView) {
                    Text("Info").tag(SelectedView.info)
                    Text("Cancellati").tag(SelectedView.cancelled)
                    Text("Waiting List").tag(SelectedView.waiting)
                }
                .pickerStyle(.segmented)
                .padding(.top)
                
                switch selectedView {
                case .info:
                    
                    if let reservation = selectedReservation {
                            ReservationInfoCard(
                                reservationID: reservation.id,
                                onClose: {
                                    dismissInfoCard()
                                },
                                onEdit: {
                                    currentReservation = reservation
                                    showingEditReservation = true
                                },
                                isShowingFullImage: $isShowingFullImage
                            )
                            .background(.clear)
                    
                } else {
                    
                    ReservationsInfoListView(activeReservations: activeReservations, currentTime: $currentTime, selectedCategory: selectedCategory,
                                             onClose: {
                        dismissInfoCard()
                    },
                                             onEdit: { reservation in
                        currentReservation = reservation
                        showingEditReservation = true
                    },
                                             onCancelled: { reservation in
                        changedReservation = reservation
                    })
                        .background(.clear)
                }
                case .cancelled:
                    
                    ReservationCancelledView(activeReservations: activeReservations, currentTime: currentTime, selectedCategory: selectedCategory,
                                             onClose: {
                        dismissInfoCard()
                    },
                                             onEdit: { reservation in
                        currentReservation = reservation
                        showingEditReservation = true
                    },
                                             onRestore: { reservation in
                    changedReservation = reservation
                    })
                        .background(.clear)
                    
                case .waiting:
                    
                    ReservationWaitingListView(activeReservations: activeReservations, currentTime: currentTime, selectedCategory: selectedCategory,
                                               onClose: {
                          dismissInfoCard()
                      },
                                               onEdit: { reservation in
                          currentReservation = reservation
                          showingEditReservation = true
                      },
                                               onConfirm: { reservation in
                      changedReservation = reservation
                      })
                    
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        
    }
    
    // MARK: - Helper Methods
    
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            showInspector = false
            selectedReservation = nil
        }
    }
}


