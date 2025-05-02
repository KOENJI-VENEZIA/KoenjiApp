//
//  ProfileAvatarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import SwiftUI

/// A view that displays a profile avatar with a popover for profile details
///
/// This view shows a circular avatar for a profile, which can be tapped to show
/// a popover with profile details. The popover includes options to view the
/// profile account and log out.
struct ProfileAvatarView: View {
    let profile: Profile?
    let size: CGFloat
    let showPopover: Bool
    
    @State private var showingPopover = false
    @State private var showingAccountView = false
    @State private var showingMenu = false
    @EnvironmentObject var env: AppDependencies
    @AppStorage("userIdentifier") private var userIdentifier: String = ""
    
    // Check if the device is an iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    init(profile: Profile?, size: CGFloat = 40, showPopover: Bool = true) {
        self.profile = profile
        self.size = size
        self.showPopover = showPopover
    }
    
    var body: some View {
        Button(action: {
            if showPopover {
                if isIPad {
                    showingPopover = true
                } else {
                    showingMenu = true
                }
            }
        }) {
            if let imageURL = profile?.imageURL, !imageURL.isEmpty {
                // If there's a profile image, display it
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        initialsView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                // Otherwise show initials
                initialsView
            }
        }
        .buttonStyle(.plain)
        // Use popover on iPad
        .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
            profileMenuContent
                .presentationCompactAdaptation(.none) // Prevent it from becoming a sheet
        }
        // Use menu on iPhone
        .confirmationDialog("", isPresented: $showingMenu) {
            Button("Il mio account") {
                showingAccountView = true
            }
            
            Button("Esci", role: .destructive) {
                logout()
            }
        }
        .sheet(isPresented: $showingAccountView) {
            if let profile = profile {
                NavigationStack {
                    ProfileAccountView(profile: profile)
                        .environmentObject(env)
                }
            }
        }
    }
    
    /// A view that displays the initials of a profile
    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(profileColor)
            
            Text(profile?.initials ?? "")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
    
    /// The color of the profile avatar
    private var profileColor: Color {
        if let profile = profile {
            // Generate a consistent color based on the profile ID
            let hash = profile.id.hash
            let hue = Double(abs(hash) % 360) / 360.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.8)
        } else {
            return Color.gray
        }
    }
    
    /// Logs out the current user
    private func logout() {
        guard let profile = profile else { return }
        
        // Get the current device UUID
        let deviceUUID = UserDefaults.standard.string(forKey: "deviceUUID") ?? ""
        
        if !deviceUUID.isEmpty {
            // Log out this device
            env.profileService.updateDeviceStatus(profileID: profile.id, deviceID: deviceUUID, isActive: false)
        }
        
        // Update AppStorage
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isProfileComplete")
        
        // Keep userIdentifier for potential reuse
    }
    
    // Extract the profile menu content to a separate view
    private var profileMenuContent: some View {
        VStack(spacing: 0) {
            if let profile = profile {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(profile.fullName)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Text(profile.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        showingPopover = false
                        showingAccountView = true
                    }) {
                        Label("Il mio account", systemImage: "person.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Button(action: {
                        logout()
                    }) {
                        Label("Esci", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .padding(.bottom, 12)
                .frame(width: 250)
            } else {
                Text("Profilo non disponibile")
                    .padding()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Preview with mock profile
        ProfileAvatarView(profile: MockData.mockProfile)
            .environmentObject(AppDependencies.createPreviewInstance())
        
        // Preview with profile that has an image URL
        let profileWithImage = Profile(
            id: "mock-profile-with-image",
            firstName: "Anna",
            lastName: "Verdi",
            email: "anna.verdi@example.com",
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            devices: [MockData.mockDevice],
            createdAt: Date(),
            updatedAt: Date()
        )
        ProfileAvatarView(profile: profileWithImage)
            .environmentObject(AppDependencies.createPreviewInstance())
        
        // Preview with no profile
        ProfileAvatarView(profile: nil)
            .environmentObject(AppDependencies.createPreviewInstance())
    }
    .padding()
} 
