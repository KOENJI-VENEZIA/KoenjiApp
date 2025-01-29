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
    @Binding var changedReservation: Reservation?
    @Binding var isShowingFullImage: Bool
    @State private var selectedView: SelectedView = .info
    @State var currentTime: Date = Date()
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    
    var activeReservations: [Reservation] {
        resCache.reservations(for: currentTime)
    }
    
    enum SelectedView {
        case info
        case cancelled
        case waiting
    }
    // MARK: - Body
    var body: some View {

        ZStack {
            Color(appState.selectedCategory.inspectorColor)
                .ignoresSafeArea()

            VStack {
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
                    
                    ReservationsInfoListView(
                        onClose: {
                            dismissInfoCard()
                        },
                        onEdit: { reservation in
                            currentReservation = reservation
                            changedReservation = reservation
                            showingEditReservation = true
                        },
                        onCancelled: { reservation in
                            changedReservation = reservation
                        }
                    )
                    .environmentObject(resCache)
                    .environmentObject(appState)
                    .environmentObject(store)
                    .environmentObject(reservationService)
                    .environmentObject(layoutServices)
                    .background(.clear)
                }
                case .cancelled:
                    
                    ReservationCancelledView(activeReservations: activeReservations, currentTime: currentTime,
                        onClose: {
                            dismissInfoCard()
                        },
                        onEdit: { reservation in
                            currentReservation = reservation
                            showingEditReservation = true
                        },
                        onRestore: { reservation in
                        changedReservation = reservation
                        }
                    )
                    .background(.clear)
                    
                case .waiting:
                    
                    ReservationWaitingListView(
                        onClose: {
                            dismissInfoCard()
                        },
                        onEdit: { reservation in
                            currentReservation = reservation
                            showingEditReservation = true
                        },
                        onConfirm: { reservation in
                            changedReservation = reservation
                        }
                    )
                    .environmentObject(resCache)
                    .environmentObject(appState)
                    .environmentObject(store)
                    .environmentObject(reservationService)
                    .environmentObject(layoutServices)
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        .onAppear {
            currentTime = appState.selectedDate
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


