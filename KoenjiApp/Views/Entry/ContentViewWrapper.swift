//
//  ContentViewWrapper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 31/12/24.
//


import SwiftUI

struct ContentViewWrapper: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    var body: some View {
        ContentView()
            .onAppear {
                print("App appearing. Loading data...")
            }
    }
}
