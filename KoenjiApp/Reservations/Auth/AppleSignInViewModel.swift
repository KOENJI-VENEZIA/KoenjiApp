import AuthenticationServices
import SwiftUI
import OSLog
import UIKit

class AppleSignInViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSigningIn: Bool = false
    @Published var isLoggedIn: Bool = false
    
    // MARK: - App Storage
    @AppStorage("isLoggedIn") var storedIsLoggedIn: Bool = false
    @AppStorage("userIdentifier") var userIdentifier: String = ""
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppleSignInViewModel")
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Sync published property with AppStorage
        isLoggedIn = storedIsLoggedIn
        
        // Check existing credential to keep session valid
        checkExistingCredential()
    }
    
    // MARK: - Public Methods
    @MainActor
    func signInWithApple() {
        logger.debug("Initiating Apple Sign In process")
        isSigningIn = true
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        
        // Set presentation context provider
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            controller.presentationContextProvider = AppleSignInPresentationContextProvider(window: window)
        }
        
        controller.performRequests()
    }
    
    func checkExistingCredential() {
        // Only proceed if we have a stored user identifier
        guard !userIdentifier.isEmpty else { return }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        // Dispatch to a background queue
        appleIDProvider.getCredentialState(forUserID: userIdentifier) { [weak self] (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid
                self?.logger.debug("Existing Apple ID credential is valid.")
                
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or not found
                self?.logger.warning("Apple ID credential is revoked or not found. Signing out.")
            default:
                break
            }
        }
    }
    
//    @MainActor
//    func signOut() {
//        storedIsLoggedIn = false
//        isLoggedIn = false
//        isProfileComplete = false
//        // Keep the userIdentifier for potential reuse but clear other data
//        userName = ""
//        userEmail = ""
//    }
}

extension AppleSignInViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isSigningIn = false
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Store the user identifier
            userIdentifier = appleIDCredential.user
            
            // Log debug information about what we're receiving
            logger.debug("Received Apple ID credential for user: \(appleIDCredential.user)")
            logger.debug("Email provided: \(appleIDCredential.email != nil ? "Yes" : "No")")
            logger.debug("Full name provided: \(appleIDCredential.fullName != nil ? "Yes" : "No")")
            
            if let fullName = appleIDCredential.fullName {
                logger.debug("First name: \(fullName.givenName ?? "nil")")
                logger.debug("Last name: \(fullName.familyName ?? "nil")")
            }
            
            // Handle user information
            if let email = appleIDCredential.email {
                userEmail = email
                logger.debug("Email provided during sign-in: \(email)")
            }
            
            // Handle name information - Apple may provide it for new users
            if let fullName = appleIDCredential.fullName,
               let givenName = fullName.givenName,
               let familyName = fullName.familyName,
               !givenName.isEmpty,
               !familyName.isEmpty {
                
                // In the rare case Apple actually provides name info
                let newUserName = "\(givenName) \(familyName)"
                userName = newUserName
                
                // Store for future use
                UserDefaults.standard.set(newUserName, forKey: "savedFullName_\(appleIDCredential.user)")
                isProfileComplete = true
                logger.debug("Got complete name from Apple: \(newUserName)")
            } else {
                // Check if we have a previously saved name
                if let storedName = UserDefaults.standard.string(forKey: "savedFullName_\(appleIDCredential.user)"),
                   !storedName.isEmpty {
                    userName = storedName
                    isProfileComplete = true
                    logger.debug("Using previously saved name: \(storedName)")
                } else {
                    // We'll need to collect user information
                    userName = ""  // Clear any default name
                    isProfileComplete = false
                    logger.debug("No name available - will need to collect user information")
                }
            }
            
            // Set logged in state - this will trigger our onboarding flow
            // via the onChange handler in the onboarding welcome view
            storedIsLoggedIn = true
            isLoggedIn = true
            
            logger.info("Apple Sign-In successful for user ID: \(self.userIdentifier)")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isSigningIn = false
        logger.error("Apple Sign-In failed: \(error.localizedDescription)")
    }
}

// Helper class to provide presentation context
class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window
    }
}
