//
//  InspectorSideView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//

import SwiftUI

struct InspectorSideView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView
    
    @Binding var selectedReservation: Reservation?
    @State private var selectedView: SelectedView = .info
    @State var currentTime: Date = Date()
    
    var activeReservations: [Reservation] {
        env.resCache.reservations(for: currentTime)
    }
    
    enum SelectedView {
        case info
        case cancelled
        case waiting
    }
    // MARK: - Body
    var body: some View {

        ZStack {
//            Color(appState.selectedCategory.inspectorColor)
//                .ignoresSafeArea()

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
                        onEdit: { reservation in
                            appState.currentReservation = reservation
                            appState.showingEditReservation = true
                            dismissInfoCard()
                        }
                    )
                    .background(.clear)
                    
                } else {
                    
                    ReservationsInfoListView(
                        onClose: {
                            dismissInfoCard()
                        },
                        onEdit: { reservation in
                            appState.currentReservation = reservation
                            appState.showingEditReservation = true
                            dismissInfoCard()
                        },
                        onCancelled: { reservation in
                            appState.changedReservation = reservation
                        }
                    )
                    .background(.clear)
                }
                case .cancelled:
                    
                    ReservationCancelledView(activeReservations: activeReservations, currentTime: currentTime,
                        onClose: {
                            dismissInfoCard()
                        },
                        onEdit: { reservation in
                        appState.currentReservation = reservation
                        appState.showingEditReservation = true
                            dismissInfoCard()
                        },
                        onRestore: { reservation in
                        appState.changedReservation = reservation
                        }
                    )
                    .background(.clear)
                    
                case .waiting:
                    
                    ReservationWaitingListView(
                        onClose: {
                            dismissInfoCard()
                        },
                        onEdit: { reservation in
                            appState.currentReservation = reservation
                            appState.showingEditReservation = true
                            dismissInfoCard()
                        },
                        onConfirm: { reservation in
                            appState.changedReservation = reservation
                        }
                    )
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        .padding()
        .onAppear {
            currentTime = appState.selectedDate
            // Fetch reservations when the view appears
            Task {
                do {
                    try await env.resCache.fetchReservations(for: appState.selectedDate)
                } catch {
                    print("Error fetching reservations: \(error.localizedDescription)")
                }
            }
        }
        .onChange(of: appState.selectedDate) { _, newDate in
            currentTime = newDate
            // Fetch reservations when the selected date changes
            Task {
                do {
                    try await env.resCache.fetchReservations(for: newDate)
                } catch {
                    print("Error fetching reservations: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            unitView.showInspector = false
            selectedReservation = nil
        }
    }
}


