//
//  SidebarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @State private var sidebarColor: Color = Color.sidebar_generic // Default color
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 

    
    var body: some View {
        

        let scribbleService = ScribbleService(layoutServices: layoutServices)
        
        ZStack {
            sidebarColor
                .ignoresSafeArea() // Sidebar background
            VStack {
                   
                    List {
                        NavigationLink(destination: ReservationListView()
                            .environmentObject(store)
                            .environmentObject(tableStore)
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(clusterServices)
                            .environmentObject(layoutServices)
                            .environmentObject(gridData)
                            .onAppear {
                                sidebarColor = Color.sidebar_generic
                            }) {
                                Label("Database", systemImage: "list.bullet")
                            }
                        NavigationLink(destination: CalendarView()
                            .environmentObject(store)
                            .environmentObject(tableStore)
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(clusterServices)
                            .environmentObject(layoutServices)
                            .environmentObject(gridData)
                            .onAppear {
                                sidebarColor = Color.sidebar_generic
                            }) {
                                Label("Calendario", systemImage: "calendar")
                            }
                        NavigationLink(destination: LayoutView(
                            selectedCategory: $selectedCategory,
                            selectedReservation: $selectedReservation,
                            currentReservation: $currentReservation,
                            onSidebarColorChange: { newColor in
                                sidebarColor = newColor // Update sidebar color
                            })
                            .environmentObject(store)
                            .environmentObject(tableStore)
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(clusterServices)
                            .environmentObject(layoutServices)
                            .environmentObject(gridData)
                            .environmentObject(scribbleService)) {
                                Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                            }
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden) // Remove default background of the list
                    .background(sidebarColor) // Match the list background to the sidebar color
                    .navigationTitle("Prenotazioni")
                    .padding(.vertical)
                    .toolbarColorScheme(.dark, for: .navigationBar)

                Spacer()
                
                Image("logo_image") // Replace "YourImageName" with the actual image asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Adjust size as needed
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .padding(.horizontal)
                    .drawingGroup() // Ensures antialiasing and higher-quality rendering
                
            }
            .ignoresSafeArea(.keyboard)

        }
    }
}

extension Reservation.ReservationCategory {
    var sidebarColor: Color {
        switch self {
        case .lunch: return Color.sidebar_lunch
        case .dinner: return Color.sidebar_dinner
        case .noBookingZone: return Color.sidebar_generic
        }
    }
}


