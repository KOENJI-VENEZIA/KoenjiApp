//
//  ContentViewWrapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 31/12/24.
//


import SwiftUI

struct ContentViewWrapper: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var gridData: GridData


    var body: some View {
        ContentView()
            .applyCustomStyles() // Applies dynamic backgrounds and Italian locale
            .onAppear {
                print("App appearing. Loading data...")
                // Data loading already handled by ReservationStore initializer
            }
    }
}
