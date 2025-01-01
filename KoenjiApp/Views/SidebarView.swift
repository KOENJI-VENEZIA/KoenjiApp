//
//  SidebarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct SidebarView: View {
    @StateObject var store = ReservationStore() // Create the store instance

    var body: some View {
        ZStack {
            List {
                NavigationLink(destination: ReservationListView()) {
                    Label("Database", systemImage: "list.bullet")
                }
                NavigationLink(destination: CalendarView()) {
                    Label("Calendario", systemImage: "calendar")
                }
                NavigationLink(destination: LayoutView(store: store).environmentObject(store)) {
                    Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Prenotazioni")
            .padding(.vertical)
            .dynamicBackground(light: Color(hex: "#BFC3E3"), dark: Color(hex: "#4A4E6D"))// Hide the List's default background
        }
    }
    

}
