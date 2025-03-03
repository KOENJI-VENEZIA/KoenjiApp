import SwiftUI
import AuthenticationServices
import OSLog

struct LoginView: View {
    @StateObject private var viewModel = AppleSignInViewModel()
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var slideOffset: CGFloat = 0
    @State private var showLoginElements: Bool = false
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "LoginView")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.sidebar_generic
                    .ignoresSafeArea(.all)
                
                HStack(spacing: 0) {
                    // Login view
                    VStack {
                        Spacer()
                        
                        Image("logo_image")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                        
                        Text("Accedi per continuare")
                            .font(.title2)
                            .padding(.vertical, 20)
                            .opacity(showLoginElements ? 1 : 0)
                            .animation(.easeIn(duration: 0.5).delay(0.3), value: showLoginElements)
                        
                        SignInWithAppleButton(.signIn) { request in
                            viewModel.signInWithApple()
                        } onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                logger.info("Apple Sign-In UI completion successful")
                                logger.debug("Auth Results: \(String(describing: authResults))")
                                
                                // Check if we need to show onboarding
                                // The actual state change will happen in onLogin observer
                            case .failure(let error):
                                logger.error("Apple Sign-In UI failed: \(error.localizedDescription)")
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.2, height: 50)
                        .padding()
                        .opacity(showLoginElements ? 1 : 0)
                        .animation(.easeIn(duration: 0.5).delay(0.5), value: showLoginElements)
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width)
                    
                    // Onboarding view
                    if showOnboarding {
                        UserOnboardingView()
                            .environmentObject(viewModel)
                            .frame(width: geometry.size.width)
                    }
                }
                .offset(x: -slideOffset)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: slideOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Animate login elements
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showLoginElements = true
                }
            }
            .onChange(of: viewModel.isLoggedIn) { _, newValue in
                if newValue {
                    // User has logged in
                    logger.debug("User logged in, checking if profile is complete")
                    if !isProfileComplete {
                        // Slide to onboarding instead of using fullScreenCover
                        showOnboarding = true
                        withAnimation {
                            slideOffset = geometry.size.width
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
