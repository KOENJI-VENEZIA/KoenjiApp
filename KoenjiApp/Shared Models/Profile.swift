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
public struct Profile: Identifiable, Hashable, Codable, Sendable{
    /// The unique identifier for the profile (Apple ID identifier)
   public let id: String
    
    /// The user's first name
    public var firstName: String
    
    /// The user's last name
    public var lastName: String
    
    /// The user's email address
    public var email: String
    
    /// URL to the profile image in Firebase Storage (optional)
    public var imageURL: String?
    
    /// Devices associated with this profile
    public var devices: [Device]
    
    /// The date the profile was created
    public var createdAt: Date
    
    /// The date the profile was last updated
    public var updatedAt: Date
    
    /// The user's display name (first name + last initial)
    public var displayName: String {
        if let initial = lastName.first {
            return "\(firstName) \(initial)."
        }
        return firstName
    }
    
    /// The user's full name
    public var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    /// The user's initials
    public var initials: String {
        let firstInitial = firstName.first ?? Character(" ")
        let lastInitial = lastName.first ?? Character(" ")
        return "\(firstInitial)\(lastInitial)"
    }
}

/// A model representing a device associated with a profile
///
/// A device corresponds to the physical device a user is using the app from.
/// It is associated with a profile when the user logs into the account on that device.
public struct Device: Identifiable, Hashable, Codable, Sendable {
    /// The unique identifier for the device
    public let id: String
    
    /// The name of the device (e.g., "iPhone 13")
    public var name: String
    
    /// The date the device was last active
    public var lastActive: Date
    
    /// Whether the device is currently active
    public var isActive: Bool
} 