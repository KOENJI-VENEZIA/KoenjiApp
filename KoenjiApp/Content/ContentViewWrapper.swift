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
    @EnvironmentObject var gridData: GridData


    var body: some View {
        ContentView()
            .applyCustomStyles() // Applies dynamic backgrounds and Italian locale
            .environmentObject(store)
            .environmentObject(reservationService)
            .environmentObject(gridData)
            .onAppear {
                print("App appearing. Loading data...")
                // Data loading already handled by ReservationStore initializer
            }
    }
}
