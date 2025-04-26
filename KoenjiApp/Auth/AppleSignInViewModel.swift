import AuthenticationServices
import SwiftUI
import Logging
import UIKit

/// A view model for handling Apple Sign In
///
/// This view model manages the Apple Sign In process, including checking existing credentials,
/// signing in with Apple, and signing out. It also handles the storage of user information.
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
    // MARK: - Initialization
    override init() {
        super.init()
        // Sync published property with AppStorage
        isLoggedIn = storedIsLoggedIn
        
        // Check existing credential to keep session valid
        checkExistingCredential()
    }
    
    // MARK: - Public Methods

    /// Signs in with Apple
    ///
    /// This method initiates the Apple Sign In process by creating a request for full name and email scopes.
    /// It then sets up the authorization controller and performs the request.
    @MainActor
    func signInWithApple() {
        AppLog.debug("Initiating Apple Sign In process")
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

    /// Checks for an existing Apple ID credential
    ///
    /// This method checks the credential state for the stored user identifier.
    /// If the credential is valid, it logs a debug message. If the credential is revoked or not found,
    /// it logs a warning and signs out the user.    
    func checkExistingCredential() {
        // Only proceed if we have a stored user identifier
        guard !userIdentifier.isEmpty else { return }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        
        // Dispatch to a background queue
        appleIDProvider.getCredentialState(forUserID: userIdentifier) { [weak self] (credentialState, error) in
            switch credentialState {
            case .authorized:
                // The Apple ID credential is valid
                Task { @MainActor in
                    AppLog.debug("Existing Apple ID credential is valid.")
                }
                
            case .revoked, .notFound:
                // The Apple ID credential is either revoked or not found
                Task { @MainActor in
                    AppLog.warning("Apple ID credential is revoked or not found. Signing out.")
                }
            default:
                break
            }
        }
    }
    
    /// Signs out the user
    ///
    /// This method updates the device status to inactive and clears the user's data.
    @MainActor
    func signOut() {        
        // We'll rely on the ProfileAvatarView's logout method to handle the device status update
        // This is a simpler approach than trying to access the environment
        
        storedIsLoggedIn = false
        isLoggedIn = false
        isProfileComplete = false
        // Keep the userIdentifier for potential reuse but clear other data
        userName = ""
        userEmail = ""
        
        AppLog.info("User signed out")
    }
}

extension AppleSignInViewModel: ASAuthorizationControllerDelegate {
    /// Handles the completion of the authorization process
    ///
    /// This method is called when the authorization process is complete.
    /// It checks the type of credential returned and extracts the user identifier.
    /// It also logs debug information about the credential and user information.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isSigningIn = false
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Store the user identifier
            userIdentifier = appleIDCredential.user
            
            // Log debug information about what we're receiving
            AppLog.debug("Received Apple ID credential for user: \(appleIDCredential.user)")
            AppLog.debug("Email provided: \(appleIDCredential.email != nil ? "Yes" : "No")")
            AppLog.debug("Full name provided: \(appleIDCredential.fullName != nil ? "Yes" : "No")")
            
            if let fullName = appleIDCredential.fullName {
                AppLog.debug("First name: \(fullName.givenName ?? "nil")")
                AppLog.debug("Last name: \(fullName.familyName ?? "nil")")
            }
            
            // Handle user information
            if let email = appleIDCredential.email {
                userEmail = email
                AppLog.debug("Email provided during sign-in: \(email)")
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
                AppLog.debug("Got complete name from Apple: \(newUserName)")
            } else {
                // Check if we have a previously saved name
                if let storedName = UserDefaults.standard.string(forKey: "savedFullName_\(appleIDCredential.user)"),
                   !storedName.isEmpty {
                    userName = storedName
                    isProfileComplete = true
                    AppLog.debug("Using previously saved name: \(storedName)")
                } else {
                    // We'll need to collect user information
                    userName = ""  // Clear any default name
                    isProfileComplete = false
                    AppLog.debug("No name available - will need to collect user information")
                }
            }
            
            // Set logged in state - this will trigger our onboarding flow
            // via the onChange handler in the onboarding welcome view
            storedIsLoggedIn = true
            isLoggedIn = true
            
            AppLog.info("Apple Sign-In successful for user ID: \(self.userIdentifier)")
        }
    }

    /// Handles errors during the authorization process
    ///
    /// This method is called when an error occurs during the authorization process.
    /// It logs an error message with the error details.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isSigningIn = false
        AppLog.error("Apple Sign-In failed: \(error.localizedDescription)")
    }
}

// Helper class to provide presentation context
class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
        super.init()
    }

    /// Provides the presentation anchor for the authorization controller
    ///
    /// This method returns the window that should be used for presenting the authorization controller.
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return window
    }
}

