//
//  ContentViewWrapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 31/12/24.
//


import SwiftUI

struct ContentViewWrapper: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var backupService: FirebaseBackupService
    @EnvironmentObject var scribbleService: ScribbleService
    @State var listView: ListViewModel

    var body: some View {
        ContentView(listView: listView)
            .environmentObject(store)
            .environmentObject(tableStore)
            .environmentObject(resCache)
            .environmentObject(layoutServices)
            .environmentObject(clusterServices)
            .environmentObject(gridData)
            .environmentObject(backupService)
            .environmentObject(appState) // Inject AppState
            .environmentObject(reservationService) // For the new service
            .environmentObject(scribbleService)

//            .applyCustomStyles() // Applies dynamic backgrounds and Italian locale
            .onAppear {
                print("App appearing. Loading data...")
                // Data loading already handled by ReservationStore initializer
            }
    }
}
