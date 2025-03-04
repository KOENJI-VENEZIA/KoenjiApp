import SwiftUI
import FirebaseAuth
import OSLog
import FirebaseDatabase

// Create the unlocking animation view
struct UnlockingAnimationView: View {
    @Binding var isComplete: Bool
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var readyTagScale: CGFloat = 0
    @State private var readyTagOpacity: Double = 0
    @State private var readyTagOffset: CGFloat = 10
    
    // For final fade out
    @State private var finalOpacity: Double = 1.0
    
    var body: some View {
        // The entire animation container
        ZStack {
            // Background that matches the app's background
            Color.sidebar_generic
                .ignoresSafeArea()
                .opacity(finalOpacity)
            
            // Content that will fade
            VStack(spacing: 24) {
                // Logo
                Image("logo_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Text
                Text("Scartabellando...")
                    .font(.title3)
                    .opacity(textOpacity)
                
                // "Tutto pronto!" capsule tag
                Text("Tutto pronto!")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 3)
                    .scaleEffect(readyTagScale)
                    .opacity(readyTagOpacity)
                    .offset(y: readyTagOffset)
            }
            .opacity(finalOpacity)
        }
        .onAppear {
            // First animation sequence
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
                scale = 1
            }
            
            withAnimation(.easeInOut(duration: 1.2)) {
                rotation = 360
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                textOpacity = 1
            }
            
            // Show "Tutto pronto!" capsule
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)) {
                    readyTagScale = 1
                    readyTagOpacity = 1
                    readyTagOffset = 0
                }
                
                // Simple fade out of everything together
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        finalOpacity = 0
                    }
                    
                    // Signal completion after animation finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isComplete = true
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) var locale
    
    // Controls the SwiftUI NavigationSplitView's sidebar
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedReservation: Reservation? = nil
    @State private var currentReservation: Reservation? = nil
    @State private var selectedCategory: Reservation.ReservationCategory?
    @State private var showInspector: Bool = false
    @State private var lastChecked: Date? = nil
    @State private var hasInitializedSession: Bool = false
    @State private var showOnboardingWelcome: Bool = true
    
    // Animation states for unlocking effect
    @State private var showUnlockingAnimation: Bool = false
    @State private var unlockingCompleted: Bool = false
    @State private var mainAppOpacity: Double = 0
    @State private var mainAppScale: CGFloat = 0.95
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userIdentifier") private var userIdentifier = ""
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("deviceUUID") private var deviceUUID: String = ""
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "ContentView")
    private let lastActiveKey = "lastActiveTimestamp"
    private let maxInactiveInterval: TimeInterval = 30 // seconds
    
    var body: some View {
            ZStack {
                Color.sidebar_generic
                    .ignoresSafeArea()

                // Order matters:
                // 1. Show onboarding only if not done yet
                if !hasCompletedOnboarding {
                    OnboardingWelcomeView()
                        .onDisappear {
                            hasCompletedOnboarding = true
                        }
                }
                // 2. If not logged in, show login screen
                else if !isLoggedIn {
                    LoginView()
                }
                // 3. If logged in but profile isn’t complete, show a profile completion view.
                //    (You could reuse your onboarding flow or create a dedicated ProfileCompletionView)
                else if !isProfileComplete {
                    UserOnboardingView()
                        .onDisappear {
                            hasCompletedOnboarding = true
                        }
                }
                // 4. If the user is logged in and profile is complete but the unlocking animation hasn't finished, show it
                else if !unlockingCompleted {
                    UnlockingAnimationView(isComplete: $unlockingCompleted)
                }
                // 5. Finally, show the main app view
                else {
                    NavigationSplitView(columnVisibility: $appState.columnVisibility) {
                        SidebarView(
                            selectedReservation: $selectedReservation,
                            currentReservation: $currentReservation,
                            selectedCategory: $selectedCategory,
                            columnVisibility: $appState.columnVisibility
                        )
                    } detail: {
                        Text("Seleziona un'opzione dal menu laterale.")
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        // Trigger session initialization if needed.
                        if isLoggedIn && isProfileComplete {
                            initializeApp()
                        }
                    }
                }
            }
        .onChange(of: isLoggedIn) { oldValue, newValue in
            if newValue && isProfileComplete && (!showOnboardingWelcome || hasCompletedOnboarding) {
                // Trigger initializing animation for already logged-in, onboarded users
                showUnlockingAnimation = true
                logger.info("User logged in: \(userName), initiating unlocking animation")
                
                // Initialize session after a delay to allow animation to play
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    initializeUserSession()
                    hasCompletedOnboarding = true
                }
            }
        }
        .onChange(of: isProfileComplete) { oldValue, newValue in
            if newValue && isLoggedIn && !hasInitializedSession {
                // User just completed profile - run unlocking animation
                showUnlockingAnimation = true
                logger.info("User profile completed: \(userName), initiating unlocking animation")
                
                // Initialize session after a delay to allow animation to play
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    initializeUserSession()
                    hasCompletedOnboarding = true
                }
            }
        }
        .onChange(of: unlockingCompleted) { oldValue, newValue in
            if newValue {
                // Reset animation states for clean reveal
                mainAppOpacity = 0
                mainAppScale = 0.95
            }
        }
        .onChange(of: scenePhase) { old, newPhase in
            // Only update session state if we've already initialized a session
            if hasInitializedSession {
                let sessionRef = Database.database().reference().child("sessions").child(deviceUUID)
                if newPhase == .background {
                    if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
                        session.isActive = false
                        session.isEditing = false
                        env.reservationService.upsertSession(session)
                        sessionRef.child("isActive").setValue(false)
                    }
                } else if newPhase == .active {
                    if var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID}) {
                        session.isActive = true
                        session.isEditing = false
                        env.reservationService.upsertSession(session)
                        sessionRef.child("isActive").setValue(true)
                    }
                }
            }
        }
    }
    
    private func initializeApp() {
        checkLastActiveTimestamp()
        startActivityMonitoring()
        
        if deviceUUID.isEmpty {
            deviceUUID = UUID().uuidString
            logger.debug("Generated new deviceUUID: \(deviceUUID)")
        }
        
        authenticateUser()
        
        if !hasInitializedSession && !userIdentifier.isEmpty && !userName.isEmpty {
            if isLoggedIn && isProfileComplete && !unlockingCompleted {
                // Trigger the unlocking animation for returning users who are already logged in
                showUnlockingAnimation = true
                logger.info("User already logged in, initiating unlocking animation")
                
                // Initialize session after a delay to allow animation to play
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    initializeUserSession()
                }
            } else {
                initializeUserSession()
            }
        }
        
        Task {
            await env.backupService.notifsManager.requestNotificationAuthorization()
        }
    }
    
    private func initializeUserSession() {
        logger.debug("Initializing user session with userName: \(userName), userIdentifier: \(userIdentifier)")
        
        if var session = SessionStore.shared.sessions.first(where: { $0.id == userIdentifier }) {
            session.uuid = deviceUUID
            session.userName = userName
            session.isActive = true
            session.lastUpdate = Date()
            env.reservationService.upsertSession(session)
            logger.info("Updated existing session for user: \(userName)")
        } else {
            let session = Session(
                id: userIdentifier,
                uuid: deviceUUID,
                userName: userName,
                isEditing: false,
                lastUpdate: Date(),
                isActive: true
            )
            
            logger.info("Created new session for user: \(userName)")
            env.reservationService.upsertSession(session)
        }
        
        env.reservationService.setupRealtimeDatabasePresence(for: deviceUUID)
        hasInitializedSession = true
    }
    
    func authenticateUser() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                logger.error("Firebase authentication failed: \(error.localizedDescription)")
            } else {
                logger.debug("Firebase user authenticated: \(authResult?.user.uid ?? "No UID")")
            }
        }
    }
    
    private func checkLastActiveTimestamp() {
        if let lastTimestamp = UserDefaults.standard.object(forKey: lastActiveKey) as? Date {
            let inactiveInterval = Date().timeIntervalSince(lastTimestamp)
            if inactiveInterval > maxInactiveInterval {
                // App was likely terminated abnormally
                if hasInitializedSession, var session = SessionStore.shared.sessions.first(where: { $0.uuid == deviceUUID }) {
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

#Preview {
    ContentView()
        .environmentObject(AppDependencies())
        .environmentObject(AppState())
}
