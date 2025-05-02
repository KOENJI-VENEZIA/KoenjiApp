import Foundation
import FirebaseFirestore
import SwiftUI
/// Service for managing session-related operations
final class SessionService: ObservableObject, Sendable {
    
    /// Inserts or updates a session in both local storage and Firebase
    func upsertSession(_ session: Session) {
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
        
        // Use FirestoreDataStore for sessions
        Task {
            do {
                let sessionStore = FirestoreDataStore<Session>(collectionName: "sessions")
                try await sessionStore.upsert(session)
                Task { @MainActor in
                    AppLog.debug("Session upserted successfully using FirestoreDataStore")
                }
            } catch {
                Task { @MainActor in
                    AppLog.error("Error upserting session: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Loads all sessions directly from Firebase
    func loadSessionsFromFirebase() async {
        
        
            do {
                let sessionStore = FirestoreDataStore<Session>(collectionName: "sessions")
                let stream = await sessionStore.streamAll().prefix(1)
                // Create a stream of sessions
                for try await sessions in stream {
                    // This will execute once with all sessions
                        SessionStore.shared.sessions = sessions
                        Task { @MainActor in
                            AppLog.info("Successfully loaded \(sessions.count) sessions from Firebase")
                        }
                }
            } catch {
                Task { @MainActor in
                    AppLog.error("Error loading sessions from Firebase: \(error.localizedDescription)")
                }
            }
    }
    
    /// Deactivates a device remotely
    @MainActor
    func deactivateDeviceRemotely(profileID: String, deviceID: String, profileService: ProfileService) {
        AppLog.info("Deactivating device \(deviceID) remotely for profile \(profileID)")
        
        // Get the profile from the store
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Find the device in the profile
            if let deviceIndex = profile.devices.firstIndex(where: { $0.id == deviceID }) {
                // Update the device status
                updatedProfile.devices[deviceIndex].isActive = false
                updatedProfile.devices[deviceIndex].lastActive = Date()
                
                // Update the profile's timestamp
                updatedProfile.updatedAt = Date()
                
                // Save the updated profile
                profileService.upsertProfile(updatedProfile)
                
                // Update the current profile if needed
                if ProfileStore.shared.currentProfile?.id == profileID {
                    ProfileStore.shared.setCurrentProfile(updatedProfile)
                }
                
                AppLog.info("Device \(deviceID) deactivated remotely for profile \(profileID)")
                
                // Also update the session if it exists
                if let session = SessionStore.shared.sessions.first(where: { $0.id == profileID && $0.uuid == deviceID }) {
                    var updatedSession = session
                    updatedSession.isActive = false
                    updatedSession.lastUpdate = Date()
                    
                    // Update the session
                    upsertSession(updatedSession)
                    
                    AppLog.info("Session updated for deactivated device \(deviceID)")
                }
            } else {
                AppLog.error("Cannot deactivate device: Device not found in profile \(profileID)")
            }
        } else {
            AppLog.error("Cannot deactivate device: Profile not found for ID \(profileID)")
        }
    }
    
    /// Logs out all devices for a profile
    @MainActor
    func logoutAllDevices(forProfileID profileID: String, profileService: ProfileService) {
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Update all devices to inactive
            for i in 0..<updatedProfile.devices.count {
                updatedProfile.devices[i].isActive = false
                updatedProfile.devices[i].lastActive = Date()
            }
            
            // Update the profile
            profileService.upsertProfile(updatedProfile)
            
            // Update all sessions for this profile
            for session in SessionStore.shared.sessions where session.id == profileID {
                var updatedSession = session
                updatedSession.isActive = false
                updatedSession.isEditing = false
                upsertSession(updatedSession)
            }
        }
    }
} 