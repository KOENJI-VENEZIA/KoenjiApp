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
    @EnvironmentObject var backupService: FirebaseBackupService
    @EnvironmentObject var scribbleService: ScribbleService
    @State var listView: ListViewModel
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    init(layoutServices: LayoutServices, listView: ListViewModel, selectedReservation: Binding<Reservation?>, currentReservation: Binding<Reservation?>, selectedCategory: Binding<Reservation.ReservationCategory?>, columnVisibility: Binding<NavigationSplitViewVisibility>) {

        self._listView = State(wrappedValue: listView)
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
                            destination: ReservationListView(
                                store: store,
                                reservationService: reservationService,
                                layoutServices: layoutServices,
                                columnVisibility: $columnVisibility,
                                listView: listView
                            )
                            
                            .environmentObject(resCache)
                            .environmentObject(backupService)
                            .environmentObject(appState) // Inject AppState
                            ) {
                                Label("Database", systemImage: "list.bullet")
                            }
                        
                        NavigationLink(
                            destination: TabsView(
                                columnVisibility: $columnVisibility
                            )
                            .environmentObject(store)
                            .environmentObject(tableStore)
                            .environmentObject(resCache)
                            .environmentObject(layoutServices)
                            .environmentObject(clusterServices)
                            .environmentObject(gridData)
                            .environmentObject(backupService)
                            .environmentObject(appState) // Inject AppState
                            .environmentObject(reservationService) // For the new service
                            .ignoresSafeArea(.all)
                        ) {
                            Label("Timeline", systemImage: "calendar.day.timeline.left")
                        }
                        NavigationLink(
                            destination: LayoutView(
                                appState: appState,
                                clusterServices: clusterServices,
                                layoutServices: layoutServices,
                                resCache: resCache,
                                selectedReservation: $selectedReservation,
                                columnVisibility: $columnVisibility
                            )
                            .environmentObject(store)
                            .environmentObject(tableStore)
                            .environmentObject(resCache)
                            .environmentObject(layoutServices)
                            .environmentObject(clusterServices)
                            .environmentObject(gridData)
                            .environmentObject(backupService)
                            .environmentObject(appState) // Inject AppState
                            .environmentObject(reservationService) // For the new service
                            .environmentObject(scribbleService)
                        ) {
                                Label("Layout Tavoli", systemImage: "rectangle.grid.3x2")
                            }
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden) // Remove default background of the list
                    .background(appState.selectedCategory.sidebarColor) // Match the list background to the sidebar color
                    .navigationTitle("Prenotazioni")
                    .padding(.vertical)

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




