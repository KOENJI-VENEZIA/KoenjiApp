//
//  AppleSignInViewModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 30/1/25.
//


import AuthenticationServices
import SwiftUI
import OSLog

class AppleSignInViewModel: NSObject, ObservableObject {
    
    // MARK: - App Storage
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userIdentifier") var userIdentifier: String = ""  // Persist the identifier
    @AppStorage("userName") var userName: String = ""
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppleSignInViewModel")
    
    // MARK: - Public Methods
    func signInWithApple() {
        logger.debug("Initiating Apple Sign In process")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
}

extension AppleSignInViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Store login state
            isLoggedIn = true
            
            // You can retrieve the Apple ID's email and full name (first time sign-in)
            userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email ?? "Unknown email"
            let fullName = appleIDCredential.fullName?.givenName ?? "User"
            userName = fullName
            
            logger.info("Apple Sign-In successful for user: \(self.userName) (ID: \(self.userIdentifier))")
            if appleIDCredential.email != nil {
                logger.debug("Email provided during sign-in")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        logger.error("Apple Sign-In failed: \(error.localizedDescription)")
    }
}
