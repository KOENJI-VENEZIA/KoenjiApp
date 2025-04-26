//
//  ProfileStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import Foundation
import SwiftUI
import OSLog

@Observable
class ProfileStore {
    // MARK: - Private Properties
    private let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ProfileStore"
    )
    
    // MARK: - Static Properties
    nonisolated(unsafe) static let shared = ProfileStore()

    // MARK: - Properties
    var profiles: [Profile] = []
    var currentProfile: Profile?
    
    // MARK: - Public Methods
    func getProfiles() -> [Profile] {
        let count = self.profiles.count
        Task { @MainActor in
            AppLog.debug("Fetching all profiles. Count: \(count)")
        }
        return self.profiles
    }
    
    func setProfiles(_ profiles: [Profile]) {
        Task { @MainActor in
            AppLog.info("Updating profile store with \(profiles.count) profiles")
        }
        self.profiles = profiles
    }
    
    @MainActor
    func updateProfile(_ profile: Profile) {
        let profileIndex = self.profiles.firstIndex(where: { $0.id == profile.id })

        if let profileIndex {
            DispatchQueue.main.async {
                self.profiles[profileIndex] = profile
                if self.currentProfile?.id == profile.id {
                    self.currentProfile = profile
                }
                Task { @MainActor in
                    AppLog.info("Updating profile store with profile \(profile.id)")
                }
            }
        } else {
            // If profile doesn't exist, add it
            DispatchQueue.main.async {
                self.profiles.append(profile)
                Task { @MainActor in
                    AppLog.info("Adding new profile to store: \(profile.id)")
                }
            }
        }
    }
    
    func getProfile(withID id: String) -> Profile? {
        return profiles.first(where: { $0.id == id })
    }
    
    func setCurrentProfile(_ profile: Profile) {
        currentProfile = profile
        Task { @MainActor in
            AppLog.info("Set current profile to: \(profile.id)")
        }
    }
} 