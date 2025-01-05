//
//  SidebarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData


    var body: some View {
        ZStack {
            List {
                NavigationLink(destination: ReservationListView().environmentObject(store).environmentObject(reservationService).environmentObject(gridData)) {
                    Label("Database", systemImage: "list.bullet")
                }
                NavigationLink(destination: CalendarView().environmentObject(store).environmentObject(reservationService).environmentObject(gridData)) {
                    Label("Calendario", systemImage: "calendar")
                }
                NavigationLink(destination: LayoutView().environmentObject(store).environmentObject(reservationService).environmentObject(gridData)) {
                    Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Prenotazioni")
            .padding(.vertical)
        }
    }
    

}
