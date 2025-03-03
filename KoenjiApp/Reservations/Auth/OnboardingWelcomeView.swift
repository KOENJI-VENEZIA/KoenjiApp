import SwiftUI
import AuthenticationServices

struct OnboardingWelcomeView: View {
    @State private var showLoginView = false
    @State private var showProfileView = false
    @State private var showMainApp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var slideOffset: CGFloat = 0
    @State private var currentStage: OnboardingStage = .welcome
    
    // Add this to match the LoginView behavior
    @State private var showLoginElements: Bool = false
    
    @StateObject private var appleSignInVM = AppleSignInViewModel()
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    
    enum OnboardingStage {
        case welcome
        case login
        case profile
        case complete
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background for all screens
                Color.sidebar_generic
                    .ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Welcome content
                    welcomeView
                        .frame(width: geometry.size.width)
                    
                    // Login view that slides in
                    if showLoginView {
                        loginTransitionView
                            .frame(width: geometry.size.width)
                    }
                    
                    // Profile setup that slides in
                    if showProfileView {
                        profileTransitionView
                            .frame(width: geometry.size.width)
                    }
                }
                .offset(x: -slideOffset)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: slideOffset)
            }
            .onAppear {
                animateWelcomeView()
            }
            .onChange(of: appleSignInVM.isLoggedIn) { _, newValue in
                if newValue {
                    // After successful login, show the profile setup screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showProfileView = true
                        withAnimation {
                            slideOffset = geometry.size.width * 2 // Slide to profile view
                            currentStage = .profile
                        }
                    }
                }
            }
            .onChange(of: isProfileComplete) { _, newValue in
                if newValue {
                    // After profile completion, transition to main app
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showMainApp = true
                            currentStage = .complete
                        }
                    }
                }
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Container for logo and text - aligned to the left
            VStack(alignment: .leading, spacing: 20) {
                // Logo with animation - now left aligned
                Image("logo_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Welcome text - already left aligned
                VStack(alignment: .leading, spacing: 16) {
                    Text("Benvenut* in\nKOENJI. VENEZIA")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Qui per assisterti con la\ngestione delle prenotazioni (e altro in arrivo...)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(textOpacity)
            }
            .frame(width: UIScreen.main.bounds.width * 0.7, alignment: .leading)
            
            Spacer()
            
            // Start button - keeping it centered
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showLoginView = true
                    slideOffset = UIScreen.main.bounds.width // Slide to login view
                    currentStage = .login
                    
                    // Reset login elements animation state
                    showLoginElements = false
                    
                    // Trigger animation for login elements after slide completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showLoginElements = true
                    }
                }
            }) {
                Text("Iniziamo!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 280)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .frame(maxWidth: .infinity, alignment: .center) // Keep button centered
            .opacity(buttonOpacity)
            .disabled(showLoginView)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var loginTransitionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Image("logo_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text("Per iniziare, accedi con il tuo account Apple")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .opacity(showLoginElements ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: showLoginElements)
            }
            
            // The custom login view
            SignInWithAppleButton(.signIn) { request in
                appleSignInVM.signInWithApple()
            } onCompletion: { result in
                // Completion is handled in onChange
            }
            .frame(width: UIScreen.main.bounds.width * 0.2, height: 50)
            .padding()
            .opacity(showLoginElements ? 1 : 0)
            .animation(.easeIn(duration: 0.5).delay(0.5), value: showLoginElements)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var profileTransitionView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image("logo_image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text("Ottimo! Ora, creiamo il tuo profilo")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            // Using our UserOnboardingView but without the header elements
            UserOnboardingView(showHeader: false)
                .environmentObject(appleSignInVM)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func animateWelcomeView() {
        // Animate logo
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate text
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            textOpacity = 1.0
        }
        
        // Animate button
        withAnimation(.easeOut(duration: 0.8).delay(1.5)) {
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    OnboardingWelcomeView()
}
