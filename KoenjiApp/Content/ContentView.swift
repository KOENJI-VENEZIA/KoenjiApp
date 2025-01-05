import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData

    @Environment(\.locale) var locale // Access the current locale set by .italianLocale()

    // Controls the SwiftUI NavigationSplitView's sidebar
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility)
        {
            // The Sidebar
            SidebarView()
                .toolbarBackground(.hidden)
                .toolbarBackground(.ultraThinMaterial)
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
        // Whenever we change columnVisibility, update store.isSidebarVisible
        .onChange(of: columnVisibility) { newVisibility in
            // .all means sidebar is visible, anything else means hidden
            store.isSidebarVisible = (newVisibility == .all)
        }
        


    }
}

