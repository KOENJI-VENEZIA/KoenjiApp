import SwiftUI
import FirebaseAuth
import OSLog
import FirebaseDatabase
import UIKit

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

// Custom alert to prevent dismissal
struct NonDismissibleAlert: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let action: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isPresented)
            
            if isPresented {
                // Full-screen overlay to prevent interaction with background
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1000) // Ensure it's above everything
                
                // Alert view
                VStack(spacing: 20) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        action()
                        isPresented = false
                    }) {
                        Text("OK")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // Ensure consistent styling
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 10)
                .padding(30)
                .frame(maxWidth: 400) // Limit width for larger screens
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2) // Center on screen
                .zIndex(1001) // Above the overlay
            }
        }
        .animation(.easeInOut, value: isPresented) // Smooth transition
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
    @State private var isSessionIconShift: Bool = false
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userIdentifier") private var userIdentifier = ""
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("deviceUUID") private var deviceUUID: String = ""
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var showRemoteLogoutAlert: Bool = false
    @State private var sheetContent: AnyView? = nil
    @State private var showSheet: Bool = false
    
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
                // 3. If the user is logged in but the unlocking animation hasn't finished, show it
                else if !unlockingCompleted {
                    UnlockingAnimationView(isComplete: $unlockingCompleted)
                        .onAppear {
                            // If profile isn't complete, show the profile completion view after animation
                            if !isProfileComplete {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    showSheet(UserOnboardingView())
                                }
                            }
                        }
                }
                // 4. Finally, show the main app view
                else {
                    ZStack(alignment: .bottomLeading) {
                        NavigationSplitView(columnVisibility: $appState.columnVisibility) {
                            SidebarView(
                                selectedReservation: $selectedReservation,
                                currentReservation: $currentReservation,
                                selectedCategory: $selectedCategory,
                                columnVisibility: $appState.columnVisibility,
                                isSessionIconShift: $isSessionIconShift
                            )
                        } detail: {
                            #if os(iOS)
                            DatabaseView(columnVisibility: $appState.columnVisibility, isDatabase: $isSessionIconShift)
                                .onAppear {
                                    withAnimation {
                                        isSessionIconShift = false
                                    }
                                }
                            #endif
                        }
                        
                        SessionsView()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: SessionStore.shared.sessions)
                            .padding(.trailing, 16)
                            .padding(.bottom, isSessionIconShift ? 60 : 8)
                            .environmentObject(env)
                    }
                    .onAppear {
                        // Load the current profile if available
                        if !userIdentifier.isEmpty {
                            Task {
                                if let profile = env.profileService.getProfile(withID: userIdentifier) {
                                }
                            }
                        }
                        
                        // Trigger session initialization if needed.
                        if !hasInitializedSession {
                            initializeSession()
                            hasInitializedSession = true
                        }
                    }
                }
            }
            .modifier(NonDismissibleAlert(isPresented: $showRemoteLogoutAlert, 
                                         title: "Sessione terminata", 
                                         message: "La tua sessione è stata terminata da un altro dispositivo. Effettua nuovamente l'accesso.", 
                                         action: performLogout))
            .sheet(isPresented: $showSheet) {
                if let content = sheetContent {
                    content
                }
            }
        .onChange(of: isLoggedIn) { oldValue, newValue in
            if newValue && isProfileComplete && (!showOnboardingWelcome || hasCompletedOnboarding) {
                // Trigger initializing animation for already logged-in, onboarded users
                showUnlockingAnimation = true
                AppLog.info("User logged in: \(userName), initiating unlocking animation")
                
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
                AppLog.info("User profile completed: \(userName), initiating unlocking animation")
                
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
        .onChange(of: scenePhase) {
            // Only update session state if we've already initialized a session
            if hasInitializedSession {
                if scenePhase == .background {
                    Task {
                         await env.sessionManager.updateSessionStatus(isActive: false)
                        AppLog.debug("App entered background, session marked inactive")
                    }
                } else if scenePhase == .active {
                    Task {
                        // Mark the session as active
                         await env.sessionManager.updateSessionStatus(isActive: true)
                        AppLog.debug("App became active, session marked active")
                        
                        // Add a delay to allow Firebase to sync
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        
                        // Check if we need to refresh the profile data
                        if let userIdentifier = UserDefaults.standard.string(forKey: "userIdentifier"),
                           !userIdentifier.isEmpty {
                            if let profile = env.profileService.getProfile(withID: userIdentifier) {
                                ProfileStore.shared.setCurrentProfile(profile)
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RemoteLogoutRequested"))) { _ in
            AppLog.warning("Remote logout requested")
            showRemoteLogoutAlert = true
        }
    }
    
    /// Initializes the app by setting up the session and loading data
    ///
    /// This method is called when the app is launched and the user is logged in.
    /// It sets up the session, loads data, and initializes the app state.
    private func initializeSession() {
        checkLastActiveTimestamp()
        startActivityMonitoring()
        
        if deviceUUID.isEmpty {
            Task {
                deviceUUID = await env.deviceInfo.getStableDeviceIdentifier()
                AppLog.debug("Generated stable deviceUUID: \(deviceUUID)")
            }
        }
        
        authenticateUser()
        
        if !hasInitializedSession && !userIdentifier.isEmpty && !userName.isEmpty {
            if isLoggedIn && isProfileComplete && !unlockingCompleted {
                // Trigger the unlocking animation for returning users who are already logged in
                showUnlockingAnimation = true
                AppLog.info("User already logged in, initiating unlocking animation")
                
                // Initialize session after a delay to allow animation to play
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    initializeUserSession()
                }
            } else {
                initializeUserSession()
            }
        }
    }
    
    private func initializeUserSession() {
        AppLog.debug("Initializing user session with userName: \(userName), userIdentifier: \(userIdentifier)")
        
        // Use the SessionManager to initialize the session
        Task {
            await env.sessionManager.initializeSession(profileID: userIdentifier, userName: userName)
            hasInitializedSession = true
        }
        
        // Authenticate with Firebase
        authenticateUser()
    }
    
    func authenticateUser() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                AppLog.error("Firebase authentication failed: \(error.localizedDescription)")
            } else {
                AppLog.debug("Firebase user authenticated: \(authResult?.user.uid ?? "No UID")")
            }
        }
    }
    
    private func checkLastActiveTimestamp() {
        if let lastTimestamp = UserDefaults.standard.object(forKey: lastActiveKey) as? Date {
            let inactiveInterval = Date().timeIntervalSince(lastTimestamp)
            if inactiveInterval > maxInactiveInterval {
                // App was likely terminated abnormally
                if hasInitializedSession {
                    Task {
                        await env.sessionManager.updateSessionStatus(isActive: false)
                        AppLog.warning("Session marked inactive due to abnormal termination. Inactive duration: \(Int(inactiveInterval))s")
                    }
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
    
    private func performLogout() {
        // Perform the remote logout
        Task {
            await env.sessionManager.performRemoteLogout()
            
            // Reset user state
            isLoggedIn = false
            isProfileComplete = false
            hasInitializedSession = false
            
            // Clear user data
            userIdentifier = ""
            userName = ""
            
            AppLog.info("User logged out due to remote deactivation")
        }
    }
    
    // Helper function to show a sheet with any content
    private func showSheet<Content: View>(_ content: Content) {
        sheetContent = AnyView(content)
        showSheet = true
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDependencies())
        .environmentObject(AppState())
}
