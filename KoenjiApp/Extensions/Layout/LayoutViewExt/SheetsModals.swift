//
//  SheetsModals.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//

import SwiftUI

extension LayoutView {
    func inspectorSheet() -> some View {
        InspectorSideView(
            selectedReservation: $selectedReservation
        )
        .environment(unitView)
        .presentationBackground(.thinMaterial)
    }
    
    func editReservationSheet(for reservation: Reservation) -> some View {
        EditReservationView(
            reservation: reservation,
            onClose: {
                appState.showingEditReservation = false
                unitView.showInspector = true
            },
            onChanged: { updatedReservation in
                appState.changedReservation = updatedReservation
            }
        )
        .presentationBackground(.thinMaterial)
    }
    
    func addReservationSheet() -> some View {
        AddReservationView(passedTable: unitView.tableForNewReservation, onAdded: { newReservation in
            appState.changedReservation = newReservation})
        .environmentObject(appState)
            .presentationBackground(.thinMaterial)
    }
    
    func shareSheet() -> some View {
        ShareModal(
            cachedScreenshot: unitView.cachedScreenshot,
            isPresented: $unitView.isPresented,
            isSharing: $unitView.isSharing
        )
    }
}
