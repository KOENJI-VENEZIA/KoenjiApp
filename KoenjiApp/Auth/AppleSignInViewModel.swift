//
//  AppleSignInViewModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 30/1/25.
//


import AuthenticationServices
import SwiftUI

class AppleSignInViewModel: NSObject, ObservableObject {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userIdentifier") var userIdentifier: String = ""  // Persist the identifier
    @AppStorage("userName") var userName: String = ""

    func signInWithApple() {
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
            
            print("Apple Sign-In Success: \(userName), Email: \(email), ID: \(userIdentifier)")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed: \(error.localizedDescription)")
    }
}
