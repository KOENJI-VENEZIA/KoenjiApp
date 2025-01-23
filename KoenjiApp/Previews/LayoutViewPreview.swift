////
////  LayoutView.swift
////  KoenjiApp
////
////  Created by Matteo Nassini on 17/1/25.
////
//
//
//#if DEBUG
//import SwiftUI
//
//struct LayoutView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        
//        //Use this if NavigationBarTitle is with Large Font
//        // 1) Create local instances of the real objects (or mocks/test doubles if needed)
//        let localStore = ReservationStore(tableAssignmentService: TableAssignmentService())
//        let localTableStore = TableStore(store: localStore)
//        let layoutServices = LayoutServices(store: localStore, tableStore: localTableStore, tableAssignmentService: TableAssignmentService())
//        
//        let localClusterStore = ClusterStore(store: localStore, tableStore: localTableStore, layoutServices: layoutServices)
//        let localClusterServices = ClusterServices(store: localStore, clusterStore: localClusterStore, tableStore: localTableStore, layoutServices: layoutServices)
//
//        
//        let localReservationService = ReservationService(
//            store: localStore,
//            clusterStore: localClusterStore,
//            clusterServices: localClusterServices,
//            tableStore: localTableStore,
//            layoutServices: layoutServices,
//            tableAssignmentService: localStore.tableAssignmentService
//        )
//        
//        let localGridData = GridData(store: localStore)
//        
//        // 2) Create the SwiftUI View with any required bindings
//        let selectedCategory: Binding<Reservation.ReservationCategory?> = .constant(.lunch)
//        let selectedReservation: Binding<Reservation?> = .constant(nil)
//        let currentReservation: Binding<Reservation?> = .constant(nil)
//        
//        return
//            NavigationSplitView {
//                SidebarView(selectedReservation: selectedReservation, currentReservation: currentReservation, selectedCategory: selectedCategory)
//                    .environmentObject(localStore)
//                    .environmentObject(localTableStore)
//                    .environmentObject(localClusterStore)
//                    .environmentObject(localReservationService)
//                    .environmentObject(localClusterServices)
//                    .environmentObject(layoutServices)
//                    .environmentObject(localGridData)
//            } detail: {
//                LayoutView(
//                    selectedCategory: selectedCategory,
//                    selectedReservation: selectedReservation,
//                    currentReservation: currentReservation,
//                    onSidebarColorChange: { newColor in
//                        // Optional: handle color change
//                        print("Sidebar color changed to \(newColor)")
//                    }
//                )
//                // 3) Inject into the environment, just like in your real app
//                .environmentObject(localStore)
//                .environmentObject(localTableStore)
//                .environmentObject(localClusterStore)
//                .environmentObject(localReservationService)
//                .environmentObject(localClusterServices)
//                .environmentObject(layoutServices)
//                .environmentObject(localGridData)
//            }
//    }
//
//}
//#endif
