import SwiftUI
import FirebaseAuth
import OSLog
import FirebaseDatabase

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
    @AppStorage("userIdentifier") private var userIdentifier = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("deviceUUID") var deviceUUID: String = ""

    let logger = Logger(subsystem: "com.koenjiapp", category: "ContentView")
    private let lastActiveKey = "lastActiveTimestamp"
    private let maxInactiveInterval: TimeInterval = 30 // seconds
    
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
                checkLastActiveTimestamp()
                startActivityMonitoring()
                
                if deviceUUID.isEmpty {
                    deviceUUID = UUID().uuidString
                    print("Generated new deviceUUID: \(deviceUUID)")
                } else {
                    print("Using existing deviceUUID: \(deviceUUID)")
                }
                
                
                if isLoggedIn {
                    authenticateUser()
                    
                   
                    
                }
                
                if var session = SessionStore.shared.sessions.first(where: { $0.id == userIdentifier} ) {
                    session.uuid = deviceUUID
                    env.reservationService.upsertSession(session)
                } else {
                    let session = Session(
                        id: userIdentifier,
                        uuid: deviceUUID,
                        userName: userName,
                        isEditing: false,
                        lastUpdate: Date(),
                        isActive: true
                    )
                    
                    print("Created new session")
                    env.reservationService.upsertSession(session)
                }
                
                env.reservationService.setupRealtimeDatabasePresence(for: deviceUUID)

                
                Task {
                    await env.backupService.notifsManager.requestNotificationAuthorization()
                }
            }
            .onChange(of: scenePhase) { old, newPhase in
                let sessionRef = Database.database().reference().child("sessions").child(deviceUUID)
                if newPhase == .background {
                    // Update Firestore directly or through your app’s service immediately
                    if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
                        session.isActive = false
                        session.isEditing = false
                        env.reservationService.upsertSession(session)
                        // Also update realtime database if needed:
                        sessionRef.child("isActive").setValue(false)
                    }
                } else if newPhase == .active {
                    if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
                        session.isActive = true
                        session.isEditing = false
                        env.reservationService.upsertSession(session)
                        // Also update realtime database if needed:
                        sessionRef.child("isActive").setValue(true)
                    }
                }
            }
//            .onChange(of: scenePhase) { old, new in
//                
//                if new == .background {
//                    if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
//                        session.isActive = false
//                        session.isEditing = false 
//                        env.reservationService.upsertSession(session)
//                    }
//                } else {
//                    if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
//                        session.isActive = true
//                        session.isEditing = false 
//                        env.reservationService.upsertSession(session)
//                    }
//                }
//            }
            
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
    
    private func checkLastActiveTimestamp() {
        if let lastTimestamp = UserDefaults.standard.object(forKey: lastActiveKey) as? Date {
            let inactiveInterval = Date().timeIntervalSince(lastTimestamp)
            if inactiveInterval > maxInactiveInterval {
                // App was likely terminated abnormally
                if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID }) {
                    session.isActive = false
                    env.reservationService.upsertSession(session)
                    logger.warning("Session marked inactive due to abnormal termination. Inactive duration: \(Int(inactiveInterval))s")
                }
            }
        }
    }
    
    private func startActivityMonitoring() {
        // Update timestamp every few seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            UserDefaults.standard.set(Date(), forKey: lastActiveKey)
        }
    }
    
   

   
}

