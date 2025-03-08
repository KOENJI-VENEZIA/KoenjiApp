//
//  Profile.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import Foundation
import OSLog

/// A model representing a user profile
///
/// A profile is created during the onboarding of the user and contains information
/// about the user and their associated devices.
struct Profile: Identifiable, Hashable, Codable {
    /// The unique identifier for the profile (Apple ID identifier)
    let id: String
    
    /// The user's first name
    var firstName: String
    
    /// The user's last name
    var lastName: String
    
    /// The user's email address
    var email: String
    
    /// URL to the profile image in Firebase Storage (optional)
    var imageURL: String?
    
    /// Devices associated with this profile
    var devices: [Device]
    
    /// The date the profile was created
    var createdAt: Date
    
    /// The date the profile was last updated
    var updatedAt: Date
    
    /// The user's display name (first name + last initial)
    var displayName: String {
        if let initial = lastName.first {
            return "\(firstName) \(initial)."
        }
        return firstName
    }
    
    /// The user's full name
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    /// The user's initials
    var initials: String {
        let firstInitial = firstName.first ?? Character(" ")
        let lastInitial = lastName.first ?? Character(" ")
        return "\(firstInitial)\(lastInitial)"
    }
}

/// A model representing a device associated with a profile
///
/// A device corresponds to the physical device a user is using the app from.
/// It is associated with a profile when the user logs into the account on that device.
struct Device: Identifiable, Hashable, Codable {
    /// The unique identifier for the device
    let id: String
    
    /// The name of the device (e.g., "iPhone 13")
    var name: String
    
    /// The date the device was last active
    var lastActive: Date
    
    /// Whether the device is currently active
    var isActive: Bool
} 