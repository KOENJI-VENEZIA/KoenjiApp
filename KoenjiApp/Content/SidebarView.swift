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
    @State private var sidebarColor: Color = Color(hex: "#232850") // Default color

    var body: some View {
        ZStack {
            sidebarColor
                .ignoresSafeArea() // Sidebar background
            List {
                NavigationLink(destination: ReservationListView()
                    .environmentObject(store)
                    .environmentObject(reservationService)
                    .environmentObject(gridData)) {
                    Label("Database", systemImage: "list.bullet")
                }
                NavigationLink(destination: CalendarView()
                    .environmentObject(store)
                    .environmentObject(reservationService)
                    .environmentObject(gridData)) {
                    Label("Calendario", systemImage: "calendar")
                }
                NavigationLink(destination: LayoutView(onSidebarColorChange: { newColor in
                    sidebarColor = newColor // Update sidebar color
                })
                    .environmentObject(store)
                    .environmentObject(reservationService)
                    .environmentObject(gridData)) {
                    Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden) // Remove default background of the list
            .background(sidebarColor) // Match the list background to the sidebar color
            .navigationTitle("Prenotazioni")
            .padding(.vertical)
            .foregroundStyle(Color.white)
            
        }
    }
    

}

extension Reservation.ReservationCategory {
    var sidebarColor: Color {
        switch self {
        case .lunch: return Color(hex: "#B89301")
        case .dinner: return Color(hex: "#232850")
        case .noBookingZone: return Color(hex: "#4B4D5D")
        }
    }
}


