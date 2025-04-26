//
//  SessionManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import Foundation
import OSLog
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import UIKit

/// A class that manages user sessions and device associations
///
/// This class is responsible for creating, updating, and managing user sessions
/// and their associated devices. It handles the synchronization between local
/// session data and Firebase.
@MainActor
class SessionManager {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = SessionManager()
    
    /// Logger for tracking session operations
    private let logger = Logger(subsystem: "com.koenjiapp", category: "SessionManager")
    
    /// Firestore database reference
    private var db: Firestore?
    
    /// Realtime Database reference
    private var rtdb: DatabaseReference?
    
    /// The current user's profile ID
    private var currentProfileID: String?
    
    /// The current device UUID
    private var currentDeviceUUID: String
    
    /// Whether this service is in preview mode
    private var isPreview: Bool
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        self.isPreview = AppDependencies.isPreviewMode
        
        if isPreview {
            // In preview mode, don't initialize Firebase components
            self.db = nil
            self.rtdb = nil
        } else {
            // Use the safe Firebase initialization methods
            self.db = AppDependencies.getFirestore()
            self.rtdb = AppDependencies.getDatabase()
        }
        
        self.currentDeviceUUID = DeviceInfo.shared.getStableDeviceIdentifier()
        
        AppLog.debug("SessionManager initialized with device UUID: \(self.currentDeviceUUID), preview mode: \(self.isPreview)")
    }
    
    // MARK: - Public Methods
    
    /// Initializes a user session
    ///
    /// This method creates or updates a session for the current user and device.
    /// It also ensures that the user's profile has the correct device association.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the user's profile
    ///   - userName: The display name of the user
    func initializeSession(profileID: String, userName: String) {
        AppLog.debug("Initializing session for profile: \(profileID), user: \(userName)")
        
        // Store the current profile ID
        self.currentProfileID = profileID
        
        // Get the current device name
        let deviceName = DeviceInfo.shared.getDeviceName()
        
        // Get the profile image URL if available
        var profileImageURL: String? = nil
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            profileImageURL = profile.imageURL
        }
        
        // Check if a session already exists for this profile
        if var existingSession = SessionStore.shared.sessions.first(where: { $0.id == profileID }) {
            // Update the existing session
            existingSession.uuid = currentDeviceUUID
            existingSession.userName = userName
            existingSession.isActive = true
            existingSession.lastUpdate = Date()
            existingSession.deviceName = deviceName
            existingSession.profileImageURL = profileImageURL
            
            // Save the updated session
            upsertSession(existingSession)
            AppLog.info("Updated existing session for user: \(userName)")
        } else {
            // Create a new session
            let newSession = Session(
                id: profileID,
                uuid: currentDeviceUUID,
                userName: userName,
                isEditing: false,
                lastUpdate: Date(),
                isActive: true,
                deviceName: deviceName,
                profileImageURL: profileImageURL
            )
            
            // Save the new session
            upsertSession(newSession)
            AppLog.info("Created new session for user: \(userName)")
        }
        
        // Ensure the profile has the correct device association
        ensureDeviceAssociation(profileID: profileID, deviceName: deviceName)
        
        // Set up presence detection
        setupPresenceDetection()
    }
    
    /// Updates a session's active status
    ///
    /// This method updates the active status of a session and its associated device.
    ///
    /// - Parameters:
    ///   - isActive: Whether the session is active
    func updateSessionStatus(isActive: Bool) {
        guard let profileID = currentProfileID else {
            AppLog.error("Cannot update session status: No current profile ID")
            return
        }
        
        AppLog.debug("Updating session status for profile: \(profileID), active: \(isActive)")
        
        // Update the session in Firebase
        if let session = SessionStore.shared.sessions.first(where: { $0.id == profileID && $0.uuid == currentDeviceUUID }) {
            var updatedSession = session
            updatedSession.isActive = isActive
            updatedSession.lastUpdate = Date()
            
            // Save the updated session
            upsertSession(updatedSession)
        }
        
        // Update the device status in the profile
        updateDeviceStatus(profileID: profileID, isActive: isActive)
        
        // If we're marking the session as active, ensure the device is properly registered
        if isActive {
            // Get the current device name
            let deviceName = DeviceInfo.shared.getDeviceName()
            
            // Ensure the device is properly registered in the profile
            ensureDeviceAssociation(profileID: profileID, deviceName: deviceName)
        }
    }
    
    /// Signs out the current user
    ///
    /// This method signs out the current user by marking their session as inactive
    /// and updating their device status.
    func signOut() {
        guard let profileID = currentProfileID else {
            AppLog.error("Cannot sign out: No current profile ID")
            return
        }
        
        AppLog.debug("Signing out user with profile: \(profileID)")
        
        // Mark the session as inactive
        updateSessionStatus(isActive: false)
        
        // Clear the current profile ID
        currentProfileID = nil
    }
    
    /// Checks if the current device has been deactivated remotely
    ///
    /// This method checks if the current device has been deactivated remotely
    /// and handles the logout process if necessary.
    ///
    /// - Returns: True if the device has been deactivated, false otherwise
    func checkDeviceActivationStatus() -> Bool {
        guard let profileID = currentProfileID else {
            AppLog.error("Cannot check device activation status: No current profile ID")
            return false
        }
        
        AppLog.debug("Checking device activation status for profile: \(profileID), device: \(self.currentDeviceUUID)")
        
        // Get the profile from the store
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            // Find the device in the profile
            if let device = profile.devices.first(where: { $0.id == currentDeviceUUID }) {
                // Check if the device is active
                if !device.isActive {
                    AppLog.warning("Device \(self.currentDeviceUUID) has been deactivated remotely")
                    return true
                }
            } else {
                // Device not found in profile, consider it deactivated
                AppLog.warning("Device \(self.currentDeviceUUID) not found in profile \(profileID)")
                return true
            }
        } else {
            // Profile not found, consider device deactivated
            AppLog.warning("Profile not found for ID \(profileID)")
            return true
        }
        
        return false
    }
    
    /// Performs a remote logout
    ///
    /// This method performs a remote logout by clearing the current profile ID
    /// and updating the session status.
    func performRemoteLogout() {
        AppLog.warning("Performing remote logout for device: \(self.currentDeviceUUID)")
        
        // Update session status to inactive
        if let profileID = currentProfileID {
            if let session = SessionStore.shared.sessions.first(where: { $0.id == profileID && $0.uuid == currentDeviceUUID }) {
                var updatedSession = session
                updatedSession.isActive = false
                updatedSession.lastUpdate = Date()
                
                // Save the updated session
                upsertSession(updatedSession)
            }
        }
        
        // Clear the current profile ID
        currentProfileID = nil
    }
    
    // MARK: - Private Methods
    
    /// Ensures that a profile has the correct device association
    ///
    /// This method ensures that a profile has the correct device association by
    /// checking if the device exists in the profile and adding it if necessary.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the profile
    ///   - deviceName: The name of the device
    private func ensureDeviceAssociation(profileID: String, deviceName: String) {
        AppLog.debug("Ensuring device association for profile: \(profileID)")
        
        // Get the profile from the store
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Check if the device already exists in the profile
            if let deviceIndex = profile.devices.firstIndex(where: { $0.id == currentDeviceUUID }) {
                // Update the existing device
                updatedProfile.devices[deviceIndex].lastActive = Date()
                updatedProfile.devices[deviceIndex].isActive = true
                
                // Update the device name if it's unknown
                if updatedProfile.devices[deviceIndex].name == "Unknown Device" {
                    updatedProfile.devices[deviceIndex].name = deviceName
                }
            } else {
                // Add the device to the profile
                let newDevice = Device(
                    id: currentDeviceUUID,
                    name: deviceName,
                    lastActive: Date(),
                    isActive: true
                )
                updatedProfile.devices.append(newDevice)
                AppLog.info("Added device \(self.currentDeviceUUID) to profile \(profileID)")
            }
            
            // Clean up duplicate devices if necessary
            if updatedProfile.devices.count > 5 {
                cleanupDuplicateDevices(profile: &updatedProfile)
            }
            
            // Update the profile's timestamp
            updatedProfile.updatedAt = Date()
            
            // Save the updated profile
            upsertProfile(updatedProfile)
        } else {
            AppLog.error("Cannot ensure device association: Profile not found for ID \(profileID)")
        }
    }
    
    /// Updates a device's active status in a profile
    ///
    /// This method updates the active status of a device in a profile.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the profile
    ///   - isActive: Whether the device is active
    private func updateDeviceStatus(profileID: String, isActive: Bool) {
        AppLog.debug("Updating device status for profile: \(profileID), active: \(isActive)")
        
        // Get the profile from the store
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Find the device in the profile
            if let deviceIndex = profile.devices.firstIndex(where: { $0.id == currentDeviceUUID }) {
                // Update the device status
                updatedProfile.devices[deviceIndex].isActive = isActive
                updatedProfile.devices[deviceIndex].lastActive = Date()
                
                // Update the profile's timestamp
                updatedProfile.updatedAt = Date()
                
                // Save the updated profile
                upsertProfile(updatedProfile)
            } else {
                AppLog.error("Cannot update device status: Device not found in profile \(profileID)")
            }
        } else {
            AppLog.error("Cannot update device status: Profile not found for ID \(profileID)")
        }
    }
    
    /// Cleans up duplicate devices in a profile
    ///
    /// This method removes duplicate devices from a profile, keeping only the current
    /// device and the most recently active device for each device name.
    ///
    /// - Parameter profile: The profile to clean up
    private func cleanupDuplicateDevices(profile: inout Profile) {
        let profileCopy = profile
        AppLog.debug("Cleaning up duplicate devices for profile: \(profileCopy.id)")
        
        // Group devices by name
        let devicesByName = Dictionary(grouping: profile.devices) { $0.name }
        
        // For each group of devices with the same name
        for (name, devices) in devicesByName {
            // If there are multiple devices with the same name
            if devices.count > 1 {
                AppLog.info("Found \(devices.count) devices with name '\(name)' in profile \(profileCopy.id)")
                
                // For other devices with the same name, keep only the most recently active one
                let otherDevices = devices.filter { $0.id != currentDeviceUUID }
                
                if !otherDevices.isEmpty {
                    // Sort by last active date and keep the most recent one
                    let sortedOtherDevices = otherDevices.sorted(by: { $0.lastActive > $1.lastActive })
                    let deviceToKeep = sortedOtherDevices.first!
                    
                    // Remove all other devices with this name except the current device and the most recent one
                    profile.devices.removeAll { device in
                        device.name == name && 
                        device.id != currentDeviceUUID && 
                        device.id != deviceToKeep.id
                    }
                    
                    AppLog.info("Kept current device \(self.currentDeviceUUID) and most recent device \(deviceToKeep.id) with name '\(name)'")
                }
            }
        }
    }
    
    /// Upserts a session to Firestore and local storage
    ///
    /// This method saves a session to Firestore and local storage.
    ///
    /// - Parameter session: The session to save
    private func upsertSession(_ session: Session) {
        AppLog.debug("Upserting session for profile: \(session.id)")
        
        // Save to SQLite
        SQLiteManager.shared.insertSession(session)
        
        // Update the session store
        DispatchQueue.main.async {
            // Check if the session already exists in the store
            if let index = SessionStore.shared.sessions.firstIndex(where: { $0.id == session.id && $0.uuid == session.uuid }) {
                // Update the existing session
                SessionStore.shared.sessions[index] = session
            } else {
                // Add the new session
                SessionStore.shared.sessions.append(session)
                SessionStore.shared.sessions = Array(Set(SessionStore.shared.sessions))
            }
        }
        
        // Save to Firestore
        #if DEBUG
        let collectionPath = "sessions"
        #else
        let collectionPath = "sessions_release"
        #endif
        
        let sessionData: [String: Any] = [
            "id": session.id,
            "uuid": session.uuid,
            "userName": session.userName,
            "isEditing": session.isEditing,
            "lastUpdate": session.lastUpdate.timeIntervalSince1970,
            "isActive": session.isActive,
            "deviceName": session.deviceName ?? DeviceInfo.shared.getDeviceName()
        ]
        
        // Add profile image URL if available
        if let profileImageURL = session.profileImageURL {
            var updatedSessionData = sessionData
            updatedSessionData["profileImageURL"] = profileImageURL
            
            db?.collection(collectionPath).document(session.uuid).setData(updatedSessionData) { error in
                if let error = error {
                    AppLog.error("Error upserting session: \(error.localizedDescription)")
                } else {
                    AppLog.debug("Session upserted successfully")
                }
            }
        } else {
            db?.collection(collectionPath).document(session.uuid).setData(sessionData) { error in
                if let error = error {
                    AppLog.error("Error upserting session: \(error.localizedDescription)")
                } else {
                    AppLog.debug("Session upserted successfully")
                }
            }
        }
    }
    
    /// Upserts a profile to Firestore and local storage
    ///
    /// This method saves a profile to Firestore and local storage.
    ///
    /// - Parameter profile: The profile to save
    private func upsertProfile(_ profile: Profile) {
        AppLog.debug("Upserting profile: \(profile.id)")
        
        // Save to SQLite
        SQLiteManager.shared.insertProfile(profile)
        
        // Update the profile store
        DispatchQueue.main.async {
            ProfileStore.shared.updateProfile(profile)
            
            // If this is the current user's profile, update the current profile
            if profile.id == self.currentProfileID {
                ProfileStore.shared.setCurrentProfile(profile)
            }
        }
        
        // Save to Firestore
        #if DEBUG
        let collectionPath = "profiles"
        #else
        let collectionPath = "profiles_release"
        #endif
        
        // Convert devices to dictionaries
        let deviceDicts = profile.devices.map { device -> [String: Any] in
            return [
                "id": device.id,
                "name": device.name,
                "lastActive": device.lastActive.timeIntervalSince1970,
                "isActive": device.isActive
            ]
        }
        
        let profileData: [String: Any] = [
            "id": profile.id,
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "email": profile.email,
            "imageURL": profile.imageURL ?? "",
            "devices": deviceDicts,
            "createdAt": profile.createdAt.timeIntervalSince1970,
            "updatedAt": profile.updatedAt.timeIntervalSince1970
        ]
        
        db?.collection(collectionPath).document(profile.id).setData(profileData) { error in
            if let error = error {
                AppLog.error("Error upserting profile: \(error.localizedDescription)")
            } else {
                AppLog.debug("Profile upserted successfully")
            }
        }
    }
    
    /// Sets up presence detection for the current device
    ///
    /// This method sets up presence detection for the current device using
    /// Firebase Realtime Database.
    private func setupPresenceDetection() {
        AppLog.debug("Setting up presence detection for device: \(self.currentDeviceUUID)")
        
        // Get a reference to the Realtime Database
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        // Observe the connection state
        connectedRef.observe(.value) { [weak self] snapshot in
            guard let self = self, let profileID = self.currentProfileID else { return }
            
            guard let connected = snapshot.value as? Bool, connected else {
                // Not connected, so no updates are made here.
                return
            }
            
            // Define a reference to the session node for this device
            #if DEBUG
            let sessionRef = self.rtdb?.child("sessions").child(self.currentDeviceUUID)
            #else
            let sessionRef = self.rtdb?.child("sessions_release").child(self.currentDeviceUUID)
            #endif
            
            // Mark the session as active when connected
            sessionRef?.child("isActive").setValue(true)
            
            // Set up onDisconnect handlers to mark the session inactive and update the last active timestamp
            sessionRef?.child("isActive").onDisconnectSetValue(false)
            sessionRef?.child("lastActive").setValue(ServerValue.timestamp())
            sessionRef?.child("lastActive").onDisconnectSetValue(ServerValue.timestamp())
            
            // Also update the profile's device status
            self.updateDeviceStatus(profileID: profileID, isActive: true)
            
            AppLog.info("Presence detection set up for device: \(self.currentDeviceUUID)")
        }
    }
} 
