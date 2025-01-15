import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData

    @Environment(\.locale) var locale // Access the current locale set by .italianLocale()

    // Controls the SwiftUI NavigationSplitView's sidebar
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedReservation: Reservation? = nil
    @State private var currentReservation: Reservation? = nil
    @State private var selectedCategory: Reservation.ReservationCategory? 
    @State private var showInspector: Bool = false       // Controls Inspector visibility

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility)
        {
            // The Sidebar
            SidebarView(
                selectedReservation: $selectedReservation,
                currentReservation: $currentReservation,
                selectedCategory: $selectedCategory,
                showInspector: $showInspector
            )
                
        }
        detail: {
            // The Detail View
            Text("Seleziona un'opzione dal menu laterale.")
                .foregroundColor(.secondary)
            
        }
        .environmentObject(store)
        .environmentObject(reservationService)
        .environmentObject(gridData)
    
        .toolbar {

            Button {
                if columnVisibility == .all {
                    // Hide the sidebar
                    columnVisibility = .detailOnly
                } else {
                    // Show the sidebar
                    columnVisibility = .all
                }
            } label: {
                Text("Mostra/Nascondi menu laterale")
            }
        }
        
        .onAppear {
            print("ContentView appeared. Data already loaded by ReservationStore.")
        }
        .onChange(of: columnVisibility) { oldState, newState in
            store.isSidebarVisible = (newState == .all)
        }
        


    }
    
    func dismissInfoCard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Match animation duration
            showInspector = false
        }
    }
}

