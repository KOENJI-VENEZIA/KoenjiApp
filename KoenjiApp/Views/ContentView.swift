import SwiftUI

struct ContentView: View {
    @StateObject var store = ReservationStore() // Create the store instance

    
    // Controls the SwiftUI NavigationSplitView's sidebar
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // The Sidebar
            SidebarView()
        } detail: {
            Text("Seleziona un opzione dal menu laterale.")
        }
        .environmentObject(store) // Add the store to the environment here
        .toolbar {
            // Add a button to toggle the sidebar in SwiftUI
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
