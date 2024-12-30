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
        List {
            NavigationLink(destination: ReservationListView().environmentObject(store)) {
                Label("Database", systemImage: "list.bullet")
            }
            NavigationLink(destination: CalendarView().environmentObject(store)) {
                Label("Calendario", systemImage: "calendar")
            }
            NavigationLink(destination: LayoutView(store: store).environmentObject(store)) {
                Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
            }


        }
        .listStyle(.sidebar)
        .navigationTitle("Prenotazioni")
    }
}
