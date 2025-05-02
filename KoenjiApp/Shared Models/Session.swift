//
//  Session.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/2/25.
//

import Foundation
import OSLog

/// A model representing a user session
///
/// A session corresponds to the activity status of an app instance.
/// It is tied to a profile and a device, and a profile can have multiple sessions
/// (associated through the isActive property of a device).
public struct Session: Identifiable, Hashable, Codable, Sendable {
    /// The unique identifier for the session (same as profile ID)
    public let id: String
    
    /// The UUID of the device associated with this session
    public var uuid: String
    
    /// The display name of the user (from profile)
    public var userName: String
    
    /// Whether the user is currently editing something
    public var isEditing: Bool
    
    /// The date the session was last updated
    public var lastUpdate: Date
    
    /// Whether the session is currently active
    public var isActive: Bool
    
    /// The name of the device associated with this session
    public var deviceName: String?
    
    /// The URL of the profile image
    public var profileImageURL: String?
    
    /// Computed property to get the profile ID
    public var profileID: String {
        return id
    }
}
