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

    @StateObject private var notificationManager = NotificationManager.shared

    @State var unitView = LayoutUnitViewModel()
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    @State private var showingReservationInfo = false

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
                                columnVisibility: $columnVisibility
                            )
                        ) {
                            Label("Database", systemImage: "list.bullet")
                        }
                        
                        NavigationLink(
                            destination: TabsView(
                                columnVisibility: $columnVisibility
                            )
                            .ignoresSafeArea(.container, edges: .top)
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
                
                HStack {
                    Image("logo_image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 120) // Adjust size as needed
                        .frame(maxWidth: .infinity, alignment: .bottomLeading)
                        .padding(.horizontal)
                        .drawingGroup()
                    
                    
                }
            }
            .sheet(isPresented: Binding<Bool>(
                       get: { notificationManager.selectedReservationID != nil },
                       set: { if !$0 { notificationManager.selectedReservationID = nil } }
                   )) {
                       if let reservationID = notificationManager.selectedReservationID {
                           NavigationStack {
                               ReservationInfoCard(
                                   reservationID: reservationID,
                                   onClose: { notificationManager.selectedReservationID = nil },
                                   onEdit: { _ in
                                       notificationManager.selectedReservationID = nil
                                       // Handle edit action if needed
                                   }
                               )
                               .environment(unitView)
                               .navigationTitle("Dettagli Prenotazione")
                               .navigationBarTitleDisplayMode(.inline)
                               .toolbar {
                                   ToolbarItem(placement: .topBarTrailing) {
                                       Button(action: { notificationManager.selectedReservationID = nil }) {
                                           Image(systemName: "xmark.circle.fill")
                                               .foregroundStyle(.secondary)
                                       }
                                   }
                               }
                           }
                           .presentationDetents([.medium, .large])
                       }
                   }
                   .task {
                       await notificationManager.requestNotificationAuthorization()
                   }
            .ignoresSafeArea(.keyboard)
        }
    }
}




