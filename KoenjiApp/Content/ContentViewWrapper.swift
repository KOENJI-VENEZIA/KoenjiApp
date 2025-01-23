//
//  ContentViewWrapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 31/12/24.
//


import SwiftUI

struct ContentViewWrapper: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var appState: AppState

    var body: some View {
        ContentView()
            .environmentObject(store)
            .environmentObject(tableStore)
            .environmentObject(reservationService) // For the new service
            .environmentObject(clusterServices)
            .environmentObject(layoutServices)
            .environmentObject(gridData)
            .environmentObject(appState) // Inject AppState
            .applyCustomStyles() // Applies dynamic backgrounds and Italian locale
            .onAppear {
                print("App appearing. Loading data...")
                // Data loading already handled by ReservationStore initializer
            }
    }
}
