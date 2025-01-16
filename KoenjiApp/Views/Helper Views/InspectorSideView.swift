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
    @Binding var sidebarColor: Color // Default color

    // MARK: - Body
    var body: some View {

        ZStack {
            Color(sidebarColor)
                .ignoresSafeArea()

            if let reservation = selectedReservation {
                ReservationInfoCard(
                    reservationID: reservation.id,
                    onClose: {
                        dismissInfoCard()
                    },
                    onEdit: {
                        currentReservation = reservation
                        showingEditReservation = true
                    }
                )
                .background(.clear)

            } else {
                Text("(Nessuna prenotazione selezionata)")
                    .multilineTextAlignment(.center)
                    .padding()
            }
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


