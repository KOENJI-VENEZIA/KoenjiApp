//
//  AppleSignInViewModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 30/1/25.
//


import AuthenticationServices
import SwiftUI

class AppleSignInViewModel: NSObject, ObservableObject {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userEmail") private var userEmail = ""
    

    private let allowedEmail = "koenji.staff@gmail.com"  // Only allow this email

    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
}

extension AppleSignInViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let email = appleIDCredential.email ?? "Unknown"  // Get email if available
            let userIdentifier = appleIDCredential.user  // Unique Apple ID identifier
            
            print("Apple Sign-In Success: Email - \(email), ID - \(userIdentifier)")
            
            // Check if the email is allowed
            if email == allowedEmail {
                isLoggedIn = true
                userEmail = email
                print("✅ Access granted")
            } else {
                isLoggedIn = false
                userEmail = ""
                print("⛔ Access denied: Unauthorized email")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed: \(error.localizedDescription)")
    }
}
