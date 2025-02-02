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
                    checkForLatestBackup()
                Task {
                    await env.backupService.notifsManager.requestNotificationAuthorization()
                }
            }
            .onChange(of: scenePhase) { old, newPhase in
                if newPhase == .active {
                    Task { @MainActor in
                        checkForLatestBackup()
                    }
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
    
    private func checkForLatestBackup() {
        guard !appState.isRestoring else { return }
        appState.isRestoring = true
            
            // 1. List backups
            env.backupService.listBackups { result in
                switch result {
                case .success(let files):
                    // 2. Sort backups by date (most recent first)
                    let sortedFiles = files.compactMap { fileName -> (fileName: String, date: Date)? in
                        if let date = extractDate(from: fileName) {
                            return (fileName, date)
                        }
                        return nil
                    }
                    .sorted { $0.date > $1.date }
                    
                    guard let latestBackup = sortedFiles.first else {
                        appState.isRestoring = false
                        return
                    }
                    
                    // Optionally: Check if the latest backup is “newer” than your current data.
                    // You might compare dates or a version number stored in your app.
                    // For this example we assume you always want to restore the latest backup.
                    
                    // 3. Restore the latest backup
                    env.backupService.restoreBackup(fileName: latestBackup.fileName) {
                        Task {
                            // Now you can await asynchronous methods:
                            if lastChecked == nil || Date().timeIntervalSince(lastChecked ?? Date()) >= 60 * 60 {
                                await env.reservationService.checkForConflictsAndCleanup()
                                lastChecked = Date()
                            } else {
                                print("Skipping check: not enough time has passed!")
                            }
                            env.reservationService.saveReservationsToDisk()
                            let today = Calendar.current.startOfDay(for: Date())
                            env.resCache.preloadDates(around: today, range: 5, reservations: env.store.reservations)
                            
                            env.reservationService.automaticBackup()
                            
                            appState.isRestoring = false
                        }
                    }
                    
                case .failure(let error):
                    print("Failed to fetch backups: \(error.localizedDescription)")
                    appState.isRestoring = false
                }
            }
        }
        
        /// Returns a Date from a backup file name using your existing logic.
        private func extractDate(from fileName: String) -> Date? {
            let pattern = #"ReservationsBackup\.json_(\d{4}-\d{2}-\d{2})_(\d{2}:\d{2})"#
            let regex = try? NSRegularExpression(pattern: pattern)
            if let match = regex?.firstMatch(in: fileName, range: NSRange(fileName.startIndex..., in: fileName)) {
                if let dateRange = Range(match.range(at: 1), in: fileName),
                   let timeRange = Range(match.range(at: 2), in: fileName) {
                    let dateString = fileName[dateRange]
                    let timeString = fileName[timeRange]
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    return formatter.date(from: "\(dateString) \(timeString)")
                }
            }
            return nil
        }
   
}

