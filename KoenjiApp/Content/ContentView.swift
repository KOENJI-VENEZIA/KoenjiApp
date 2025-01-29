import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var clusterStore: ClusterStore
    @EnvironmentObject var clusterServices: ClusterServices
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var appState: AppState

    @Environment(\.locale) var locale // Access the current locale set by .italianLocale()

    // Controls the SwiftUI NavigationSplitView's sidebar
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedReservation: Reservation? = nil
    @State private var currentReservation: Reservation? = nil
    @State private var selectedCategory: Reservation.ReservationCategory? 
    @State private var showInspector: Bool = false       // Controls Inspector visibility

   
    var body: some View {
        NavigationSplitView(columnVisibility: $appState.columnVisibility)
        {
            // The Sidebar
            SidebarView(layoutServices: layoutServices,
                selectedReservation: $selectedReservation,
                currentReservation: $currentReservation,
                selectedCategory: $selectedCategory,
                columnVisibility: $appState.columnVisibility
            )
           
            .environmentObject(store)
            .environmentObject(resCache)
            .environmentObject(tableStore)
            .environmentObject(reservationService) // For the new service
            .environmentObject(clusterServices)
            .environmentObject(layoutServices)
            .environmentObject(gridData)
            .environmentObject(appState)
                
        }
        detail: {
            // The Detail View
            Text("Seleziona un'opzione dal menu laterale.")
                .foregroundColor(.secondary)
            
        }

    
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                // Sidebar toggle button
                Button {
                    if appState.columnVisibility == .all {
                            // Hide the sidebar
                        appState.columnVisibility = .detailOnly
                    } else {
                        // Show the sidebar
                        appState.columnVisibility = .all
                    }
                } label: {
                    Text("Mostra/Nascondi menu laterale")
                }
                
               
            }
        }
        
        .onAppear {
            print("ContentView appeared. Data already loaded by ReservationStore.")
        }
        .onChange(of: appState.columnVisibility) { oldState, newState in
            store.isSidebarVisible = (newState == .all)
        }
        


    }
    
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            showInspector = false
        }
    }
}

