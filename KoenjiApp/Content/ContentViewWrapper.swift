//
//  ContentViewWrapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 31/12/24.
//


import SwiftUI

struct ContentViewWrapper: View {
    @EnvironmentObject var store: ReservationStore

    var body: some View {
        ContentView()
            .applyCustomStyles() // Applies dynamic backgrounds and Italian locale
            .environmentObject(store)
            .onAppear {
                print("App appearing. Loading data...")
                // Data loading already handled by ReservationStore initializer
            }
    }
}
