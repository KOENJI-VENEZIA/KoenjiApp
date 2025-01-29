//
//  SidebarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var appState: AppState // Access AppState
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @StateObject private var scribbleService: ScribbleService
    
    init(layoutServices: LayoutServices, selectedReservation: Binding<Reservation?>, currentReservation: Binding<Reservation?>, selectedCategory: Binding<Reservation.ReservationCategory?>, columnVisibility: Binding<NavigationSplitViewVisibility>) {

        self._selectedReservation = selectedReservation
        self._currentReservation = currentReservation
        self._selectedCategory = selectedCategory
        self._columnVisibility = columnVisibility
        
        _scribbleService = StateObject(wrappedValue: ScribbleService(layoutServices: layoutServices))
        
    }
    var body: some View {

        ZStack {
            appState.selectedCategory.sidebarColor
                .ignoresSafeArea() // Sidebar background
            VStack {
                   
                    List {
                        NavigationLink(destination: ReservationListView(columnVisibility: $columnVisibility)
                            .environmentObject(store)
                            .environmentObject(resCache)
                            .environmentObject(tableStore)
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(clusterServices)
                            .environmentObject(layoutServices)
                            .environmentObject(gridData)
                            .environmentObject(appState)
                            ) {
                                Label("Database", systemImage: "list.bullet")
                            }
                        
                        NavigationLink(destination: TabsView(columnVisibility: $columnVisibility)
                            .environmentObject(store)
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(layoutServices)
                            .environmentObject(appState)
                            .environmentObject(resCache)
                            .ignoresSafeArea(.all)
                        ) {
                            Label("Timeline", systemImage: "calendar.day.timeline.left")
                        }
                        NavigationLink(destination:
                            LayoutView(
                                appState: appState,
                                clusterServices: clusterServices,
                                layoutServices: layoutServices,
                                resCache: resCache,
                                selectedReservation: $selectedReservation,
                                currentReservation: $currentReservation,
                                columnVisibility: $columnVisibility
                            )
                            .environmentObject(store)
                            .environmentObject(resCache)
                            .environmentObject(tableStore)
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(clusterServices)
                            .environmentObject(layoutServices)
                            .environmentObject(gridData)
                            .environmentObject(scribbleService)
                            .environmentObject(appState)
                            .environmentObject(SharedToolPicker())) {
                                Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                            }
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden) // Remove default background of the list
                    .background(appState.selectedCategory.sidebarColor) // Match the list background to the sidebar color
                    .navigationTitle("Prenotazioni")
                    .padding(.vertical)
                    .toolbarColorScheme(.dark, for: .navigationBar)

                Spacer()
                
                AppVersionView()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .opacity(0.8)
                
                Image("logo_image") // Replace "YourImageName" with the actual image asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 120) // Adjust size as needed
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

extension Reservation.ReservationCategory {
    var inspectorColor: Color {
        switch self {
        case .lunch: return Color.inspector_lunch
        case .dinner: return Color.inspector_dinner
        case .noBookingZone: return Color.inspector_generic
        }
    }
}


