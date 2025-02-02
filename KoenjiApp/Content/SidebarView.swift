//
//  SidebarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    init(selectedReservation: Binding<Reservation?>, currentReservation: Binding<Reservation?>, selectedCategory: Binding<Reservation.ReservationCategory?>, columnVisibility: Binding<NavigationSplitViewVisibility>) {

    
        self._selectedReservation = selectedReservation
        self._currentReservation = currentReservation
        self._selectedCategory = selectedCategory
        self._columnVisibility = columnVisibility
        
        
        
    }
    var body: some View {

        ZStack {
            appState.selectedCategory.sidebarColor
                .ignoresSafeArea() // Sidebar background
            VStack {
                   
                    List {
                        NavigationLink(
                            destination: DatabaseView(
                                store: env.store,
                                reservationService: env.reservationService,
                                layoutServices: env.layoutServices,
                                columnVisibility: $columnVisibility,
                                listView: env.listView
                            )
                        ) {
                            Label("Database", systemImage: "list.bullet")
                        }
                        
                        NavigationLink(
                            destination: TabsView(
                                columnVisibility: $columnVisibility
                            )
                            .ignoresSafeArea(.all)
                        ) {
                            Label("Timeline", systemImage: "calendar.day.timeline.left")
                        }
                        NavigationLink(
                            destination: LayoutView(
                                appState: appState,
                                store: env.store,
                                reservationService: env.reservationService,
                                clusterServices: env.clusterServices,
                                layoutServices: env.layoutServices,
                                resCache: env.resCache,
                                selectedReservation: $selectedReservation,
                                columnVisibility: $columnVisibility
                            )
                        ) {
                                Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                            }
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                    .background(appState.selectedCategory.sidebarColor)
                    .navigationTitle("Prenotazioni")
                    .padding(.vertical)

                Spacer()
                
                AppVersionView()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .opacity(0.8)
                
                Image("logo_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 120) // Adjust size as needed
                    .frame(maxWidth: .infinity, alignment: .bottomLeading)
                    .padding(.horizontal)
                    .drawingGroup()
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}




