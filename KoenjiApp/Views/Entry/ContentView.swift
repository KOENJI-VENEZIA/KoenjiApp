import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase


    @Environment(\.locale) var locale // Access the current locale set by .italianLocale()

    // Controls the SwiftUI NavigationSplitView's sidebar
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedReservation: Reservation? = nil
    @State private var currentReservation: Reservation? = nil
    @State private var selectedCategory: Reservation.ReservationCategory? 
    @State private var showInspector: Bool = false       // Controls Inspector visibility
    @State private var lastChecked: Date? = nil
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false

   
    var body: some View {
        ZStack{
            
            NavigationSplitView(columnVisibility: $appState.columnVisibility)
            {
                // The Sidebar
                SidebarView(
                    selectedReservation: $selectedReservation,
                    currentReservation: $currentReservation,
                    selectedCategory: $selectedCategory,
                    columnVisibility: $appState.columnVisibility
                )
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
            .opacity(isLoggedIn ? 1 : 0)
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
            .onAppear {
                
                if isLoggedIn {
                    authenticateUser()
                }
                Task {
                    await env.backupService.notifsManager.requestNotificationAuthorization()
                }
            }
            
            LoginView()
                .opacity(isLoggedIn ? 0 : 1)
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
            
        }

    }
    
    func authenticateUser() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Authentication failed: \(error)")
            } else {
                print("User authenticated: \(authResult?.user.uid ?? "No UID")")
            }
        }
    }
    
   

   
}

