import Foundation
import FirebaseFirestore

/// Service for managing user profiles
class ProfileService: ObservableObject {
    private let store: ReservationStore
    private let deviceInfo: DeviceInfo
    
    init(store: ReservationStore, deviceInfo: DeviceInfo) {
        self.store = store
        self.deviceInfo = deviceInfo
    }
    
    /// Inserts or updates a profile in both local storage and Firebase
    func upsertProfile(_ profile: Profile) {
        // Save to SQLite
        SQLiteManager.shared.insertProfile(profile)
        
        // Update the in-memory store
        DispatchQueue.main.async {
            ProfileStore.shared.updateProfile(profile)
        }
        
        // Use FirestoreDataStore for profiles
        Task {
            do {
                let profileStore: FirestoreDataStore<Profile> = FirestoreDataStore<Profile>(collectionName: "profiles")
                try await profileStore.upsert(profile)
                Task { @MainActor in
                    AppLog.debug("Profile pushed to Firebase successfully")
                }
            } catch {
                Task { @MainActor in
                    AppLog.error("Error pushing profile to Firebase: \(error)")
                }
            }
        }
    }
    
    /// Loads profiles from SQLite and updates the in-memory profile store
    func loadProfiles() {
        let profiles: [Profile] = SQLiteManager.shared.getAllProfiles()
        
        DispatchQueue.main.async {
            ProfileStore.shared.setProfiles(profiles)
        }
        
        Task { @MainActor in
            AppLog.info("Loaded \(profiles.count) profiles from SQLite")
        }
    }
    
    /// Retrieves a profile from SQLite by ID
    func getProfile(withID id: String) -> Profile? {
        return SQLiteManager.shared.getProfile(withID: id)
    }
    
    /// Creates a new profile from a session
    func createProfileFromSession(_ session: Session) async -> Profile {
        // Extract first name and last name from userName
        let components: [String] = session.userName.components(separatedBy: " ")
        let firstName: String = components.first ?? ""
        let lastName: String = components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
        var deviceName: String = ""
        if (session.deviceName != nil) {
            deviceName = session.deviceName!
        } else {
            deviceName = await deviceInfo.getDeviceName()
        }

        // Create a device for this session
        let device: Device = Device(
            id: session.uuid,
            name: deviceName,
            lastActive: session.lastUpdate,
            isActive: session.isActive
        )
        
        // Create the profile
        return Profile(
            id: session.id,
            firstName: firstName,
            lastName: lastName,
            email: "user@example.com", // Default email
            imageURL: nil,
            devices: [device],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Updates the status of a device for a profile
    func updateDeviceStatus(profileID: String, deviceID: String, isActive: Bool) {
        // Update SQLite database
        SQLiteManager.shared.updateDeviceStatus(deviceId: deviceID, isActive: isActive)
        
        // Update the profile in memory
        if let profile: Profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile: Profile = profile
            
            // Find the device in the profile
            if let deviceIndex: Array<Device>.Index  = profile.devices.firstIndex(where: { $0.id == deviceID }) {
                // Update the device status
                updatedProfile.devices[deviceIndex].isActive = isActive
                updatedProfile.devices[deviceIndex].lastActive = Date()
                
                // Update the profile's timestamp
                updatedProfile.updatedAt = Date()
                
                // Save the updated profile
                upsertProfile(updatedProfile)
                
                // Update the current profile if needed
                if ProfileStore.shared.currentProfile?.id == profileID {
                    ProfileStore.shared.setCurrentProfile(updatedProfile)
                }
                
                Task { @MainActor in
                    AppLog.debug("Updated device status for profile: \(profileID), device: \(deviceID), active: \(isActive)")
                }
            } else {
                Task { @MainActor in
                    AppLog.error("Cannot update device status: Device not found in profile \(profileID)")
                }
            }
        } else {
            Task { @MainActor in
                AppLog.error("Cannot update device status: Profile not found for ID \(profileID)")
            }
        }
    }
    
    /// Cleans up duplicate devices in a profile
    func cleanupDuplicateDevices(profileID: String, currentDeviceID: String) async {
        if let profile: Profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile: Profile = profile
            var deviceNameChanged: Bool = false
            
            // Get device name safely before using it
            let safeDeviceName: String = await deviceInfo.getDeviceName()
            
            // First, ensure the current device is properly updated
            if let currentDeviceIndex: Array<Device>.Index = updatedProfile.devices.firstIndex(where: { $0.id == currentDeviceID }) {
                // Update the existing device
                updatedProfile.devices[currentDeviceIndex].lastActive = Date()
                updatedProfile.devices[currentDeviceIndex].isActive = true
                
                // Check if we need to update the device name
                if updatedProfile.devices[currentDeviceIndex].name == "Unknown Device" {
                    updatedProfile.devices[currentDeviceIndex].name = safeDeviceName
                    deviceNameChanged = true
                }
            } else {
                // If current device isn't in the profile, add it
                let newDevice: Device = Device(
                    id: currentDeviceID,
                    name: safeDeviceName,
                    lastActive: Date(),
                    isActive: true
                )
                updatedProfile.devices.append(newDevice)
                deviceNameChanged = true
                Task { @MainActor in
                    AppLog.info("Added current device \(currentDeviceID) to profile \(profileID)")
                }
            }
            
            // Group devices by name
            let devicesByName: Dictionary<String, Array<Device>> = Dictionary(grouping: updatedProfile.devices) { $0.name }
            
            // For each group of devices with the same name
            for (deviceName, devicesWithName) in devicesByName {
                // If there are multiple devices with the same name
                if devicesWithName.count > 1 {
                    Task { @MainActor in
                        AppLog.info("Found \(devicesWithName.count) devices with name '\(deviceName)' in profile \(profileID)")
                    }
                    // For other devices with the same name, keep only the most recently active one
                    let otherDevices: Array<Device> = devicesWithName.filter { $0.id != currentDeviceID }
                    
                    if !otherDevices.isEmpty {
                        // Sort by last active date and keep the most recent one
                        let sortedOtherDevices: [Device] = otherDevices.sorted(by: { $0.lastActive > $1.lastActive })
                        let deviceToKeep: Device = sortedOtherDevices.first!
                        
                        // Remove all other devices with this name except the current device and the most recent one
                        updatedProfile.devices.removeAll { device in
                            device.name == deviceName && 
                            device.id != currentDeviceID && 
                            device.id != deviceToKeep.id
                        }
                        
                        Task { @MainActor in
                            AppLog.info("Kept current device \(currentDeviceID) and most recent device \(deviceToKeep.id) with name '\(deviceName)'")
                        }
                    }
                }
            }
            
            // Update the profile if changes were made
            if updatedProfile.devices.count != profile.devices.count || deviceNameChanged {
                updatedProfile.updatedAt = Date()
                upsertProfile(updatedProfile)
                
                // Update the current profile if needed
                if ProfileStore.shared.currentProfile?.id == profileID {
                    ProfileStore.shared.setCurrentProfile(updatedProfile)
                }
                
                Task { @MainActor in
                    AppLog.info("Cleaned up duplicate devices in profile \(profileID). Removed \(profile.devices.count - updatedProfile.devices.count) devices.")
                }
            }
        }
    }
    
    /// Completely resets a profile's devices, keeping only the current device
    func resetProfileDevices(profileID: String, currentDeviceID: String, deviceName: String) {
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Create a device for the current device
            let currentDevice = Device(
                id: currentDeviceID,
                name: deviceName,
                lastActive: Date(),
                isActive: true
            )
            
            // Reset the devices array to contain only the current device
            updatedProfile.devices = [currentDevice]
            updatedProfile.updatedAt = Date()
            
            // Update the profile
            upsertProfile(updatedProfile)
            
            // Update the current profile if needed
            if ProfileStore.shared.currentProfile?.id == profileID {
                ProfileStore.shared.setCurrentProfile(updatedProfile)
            }
            
            // Update device status in SQLite
            SQLiteManager.shared.updateDeviceStatus(deviceId: currentDeviceID, isActive: true)
            
            Task { @MainActor in
                AppLog.warning("Completely reset devices for profile \(profileID). Removed \(profile.devices.count - 1) devices.")
            }
        }
    }
} 