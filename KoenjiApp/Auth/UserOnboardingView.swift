import SwiftUI
import OSLog
import UIKit

struct UserOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appleSignInVM: AppleSignInViewModel
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userIdentifier") private var userIdentifier: String = ""
    @AppStorage("deviceUUID") private var deviceUUID: String = ""
    @AppStorage("isProfileComplete") private var isProfileComplete: Bool = false
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var formScale: CGFloat = 0.95
    @State private var formOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.95
    @State private var buttonOpacity: Double = 0
    @State private var existingAccountFound: Bool = false
    @State private var existingDisplayName: String = ""
    @State private var showExistingAccountAlert: Bool = false
    @FocusState private var isFirstNameFocused: Bool
    @FocusState private var isLastNameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    
    let logger: Logger = Logger(subsystem: "com.koenjiapp", category: "UserOnboardingView")
    let showHeader: Bool
    
    init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    var body: some View {
        ZStack {
            // Background tap area for dismissing keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss keyboard when tapping outside text fields
                    isFirstNameFocused = false
                    isLastNameFocused = false
                    isEmailFocused = false
                }
            
            VStack(spacing: 24) {
                // Logo and welcome header (optional)
                if showHeader {
                    VStack(spacing: 16) {
                        Image("logo_image")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        
                        Text("Ci siamo quasi!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Prima di iniziare, completa il tuo profilo")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 16)
                }
                
                // Form content
                VStack(spacing: 20) {
                    formField(title: String(localized: "Nome"), icon: "person.fill", text: $firstName, isFocused: $isFirstNameFocused)
                    formField(title: String(localized: "Cognome"), icon: "person.fill", text: $lastName, isFocused: $isLastNameFocused)
                    formField(title: String(localized: "Email"), icon: "envelope.fill", text: $email, isFocused: $isEmailFocused)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding(24)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .scaleEffect(formScale)
                .opacity(formOpacity)
                
                Spacer()
                    .frame(height: 20)
                
                // Submit button
                Button(action: saveUserProfile) {
                    Label("Continua", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal)
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
            }
            .padding(.vertical, 32)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Dati mancanti"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Account esistente rilevato", isPresented: $showExistingAccountAlert) {
            Button("Usa profilo esistente", role: .none) {
                reuseExistingProfile()
            }
            Button("Crea nuovo profilo", role: .none) {
                // Continue with form entry
            }
        } message: {
            Text("Sembra che tu abbia già creato un account su un altro dispositivo come '\(existingDisplayName)'. Vuoi usare quel profilo?")
        }
        .onAppear {
            // Generate device UUID if needed
            if deviceUUID.isEmpty {
                deviceUUID = DeviceInfo.shared.getStableDeviceIdentifier()
                logger.debug("Generated stable deviceUUID: \(deviceUUID)")
            }
            
            // Pre-fill email if available
            if !appleSignInVM.userEmail.isEmpty {
                email = appleSignInVM.userEmail
            }
            
            checkForExistingAccount()
            animateForm()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button("Fatto") {
                    isFirstNameFocused = false
                    isLastNameFocused = false
                    isEmailFocused = false
                }
            }
        }
    }
    
    private func checkForExistingAccount() {
        // Do not check if userIdentifier is empty
        guard !userIdentifier.isEmpty else {
            logger.debug("userIdentifier is empty, cannot check for existing account")
            return
        }
        
        // Check if this user has an existing profile
        if let existingProfile = env.reservationService.getProfile(withID: userIdentifier) {
            existingAccountFound = true
            existingDisplayName = existingProfile.displayName
            logger.info("Found existing profile: \(existingDisplayName)")
            
            // Automatically reuse the profile without showing an alert
            reuseExistingProfile()
        } else {
            // Check if this user has an existing session
            if let existingSession = SessionStore.shared.sessions.first(where: { $0.id == userIdentifier }) {
                existingAccountFound = true
                existingDisplayName = existingSession.userName
                logger.info("Found existing session: \(existingDisplayName)")
                
                // Automatically reuse the profile without showing an alert
                reuseExistingProfile()
            } else {
                // Also check for saved names in UserDefaults as a fallback
                if let savedName = UserDefaults.standard.string(forKey: "savedDisplayName_\(userIdentifier)") {
                    existingAccountFound = true
                    existingDisplayName = savedName
                    logger.info("Found existing name in UserDefaults: \(existingDisplayName)")
                    
                    // Automatically reuse the profile without showing an alert
                    reuseExistingProfile()
                }
            }
        }
    }
    
    private func reuseExistingProfile() {
        // Set userName from existing profile
        userName = existingDisplayName
        appleSignInVM.userName = existingDisplayName
        
        logger.debug("Reusing existing profile: \(existingDisplayName)")
        
        // Create or update session with existing data
        if deviceUUID.isEmpty {
            deviceUUID = DeviceInfo.shared.getStableDeviceIdentifier()
            logger.debug("Generated stable deviceUUID during profile reuse: \(deviceUUID)")
        }
        
        do {
            // Get the current device name
            let currentDeviceName = DeviceInfo.shared.getDeviceName()
            
            // Check if a profile with this userIdentifier exists
            if let existingProfile = env.reservationService.getProfile(withID: userIdentifier) {
                // Instead of resetting all devices, just add or update the current device
                var updatedProfile = existingProfile
                
                // Check if the current device is already in the profile
                if let deviceIndex = updatedProfile.devices.firstIndex(where: { $0.id == deviceUUID }) {
                    // Update the existing device
                    updatedProfile.devices[deviceIndex].name = currentDeviceName
                    updatedProfile.devices[deviceIndex].lastActive = Date()
                    updatedProfile.devices[deviceIndex].isActive = true
                } else {
                    // Add the current device to the profile
                    let device = Device(
                        id: deviceUUID,
                        name: currentDeviceName,
                        lastActive: Date(),
                        isActive: true
                    )
                    updatedProfile.devices.append(device)
                }
                
                // Update profile information
                updatedProfile.firstName = firstName
                updatedProfile.lastName = lastName
                updatedProfile.email = email
                updatedProfile.updatedAt = Date()
                
                // Save the updated profile
                env.reservationService.upsertProfile(updatedProfile)
                
                // Set the current profile
                ProfileStore.shared.setCurrentProfile(updatedProfile)
                
                // Create a session for this device
                let session = Session(
                    id: userIdentifier,
                    uuid: deviceUUID,
                    userName: existingProfile.displayName,
                    isEditing: false,
                    lastUpdate: Date(),
                    isActive: true,
                    deviceName: currentDeviceName
                )
                
                env.reservationService.upsertSession(session)
                logger.info("Updated existing profile and created session")
            } else {
                // Create a new profile and session with existing name
                let components = existingDisplayName.components(separatedBy: " ")
                let firstName = components.first ?? ""
                let lastName = components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
                
                let device = Device(
                    id: deviceUUID,
                    name: currentDeviceName,
                    lastActive: Date(),
                    isActive: true
                )
                
                let emailToUse = !email.isEmpty ? email : "user@example.com" // Fallback email
                
                let profile = Profile(
                    id: userIdentifier,
                    firstName: firstName,
                    lastName: lastName,
                    email: emailToUse,
                    imageURL: nil,
                    devices: [device],
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Save the profile
                env.reservationService.upsertProfile(profile)
                
                // Set the current profile
                ProfileStore.shared.setCurrentProfile(profile)
                
                // Create a session for this device
                let session = Session(
                    id: userIdentifier,
                    uuid: deviceUUID,
                    userName: profile.displayName,
                    isEditing: false,
                    lastUpdate: Date(),
                    isActive: true,
                    deviceName: currentDeviceName
                )
                
                env.reservationService.upsertSession(session)
                logger.info("Created new profile and session with existing name")
            }
            
            // Setup database presence
            env.reservationService.setupRealtimeDatabasePresence(for: deviceUUID)
            
            // Mark profile as complete
            isProfileComplete = true
            
            // Dismiss this view to continue to the main app
            dismiss()
        }
    }
    
    /// Checks if the form is valid
    ///
    /// This method checks if the form is valid.
    ///
    /// - Returns: True if the form is valid, false otherwise
    private var isFormValid: Bool {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedFirstName.isEmpty && !trimmedLastName.isEmpty && isValidEmail(trimmedEmail)
    }
    
    /// Checks if the email is valid
    ///
    /// This method checks if the email is valid.
    ///
    /// - Returns: True if the email is valid, false otherwise
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Saves the user profile
    ///
    /// This method saves the user profile.
    ///
    /// - Returns: True if the profile is saved, false otherwise
    private func saveUserProfile() {
        // Dismiss keyboard
        isFirstNameFocused = false
        isLastNameFocused = false
        isEmailFocused = false
        
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedFirstName.isEmpty || trimmedLastName.isEmpty {
            alertMessage = "Per favore, inserisci nome e cognome per continuare."
            showAlert = true
            return
        }
        
        if !isValidEmail(trimmedEmail) {
            alertMessage = "Per favore, inserisci un indirizzo email valido."
            showAlert = true
            return
        }
        
        // Critical check: Make sure we have a valid userIdentifier
        guard !userIdentifier.isEmpty else {
            logger.error("Cannot save user profile: userIdentifier is empty!")
            alertMessage = "Si è verificato un errore. Riprova più tardi."
            showAlert = true
            return
        }
        
        // Format the display name
        let displayName = formatDisplayName(firstName: trimmedFirstName, lastName: trimmedLastName)
        userName = displayName
        appleSignInVM.userName = displayName
        
        // Store both the display name and full name in UserDefaults
        let fullName = "\(trimmedFirstName) \(trimmedLastName)"
        UserDefaults.standard.set(displayName, forKey: "savedDisplayName_\(userIdentifier)")
        UserDefaults.standard.set(fullName, forKey: "savedFullName_\(userIdentifier)")
        
        logger.debug("Creating profile with userIdentifier: \(userIdentifier), userName: \(displayName), email: \(trimmedEmail)")
        
        // Make sure device UUID is valid
        if deviceUUID.isEmpty {
            deviceUUID = DeviceInfo.shared.getStableDeviceIdentifier()
            logger.debug("Generated stable deviceUUID during profile save: \(deviceUUID)")
        }
        
        do {
            // Get the current device name
            let currentDeviceName = DeviceInfo.shared.getDeviceName()
            
            // Check if a profile already exists for this user
            if let existingProfile = env.reservationService.getProfile(withID: userIdentifier) {
                // Instead of resetting all devices, just add or update the current device
                var updatedProfile = existingProfile
                
                // Check if the current device is already in the profile
                if let deviceIndex = updatedProfile.devices.firstIndex(where: { $0.id == deviceUUID }) {
                    // Update the existing device
                    updatedProfile.devices[deviceIndex].name = currentDeviceName
                    updatedProfile.devices[deviceIndex].lastActive = Date()
                    updatedProfile.devices[deviceIndex].isActive = true
                } else {
                    // Add the current device to the profile
                    let device = Device(
                        id: deviceUUID,
                        name: currentDeviceName,
                        lastActive: Date(),
                        isActive: true
                    )
                    updatedProfile.devices.append(device)
                }
                
                // Update profile information
                updatedProfile.firstName = trimmedFirstName
                updatedProfile.lastName = trimmedLastName
                updatedProfile.email = trimmedEmail
                updatedProfile.updatedAt = Date()
                
                // Save the updated profile
                env.reservationService.upsertProfile(updatedProfile)
                
                // Set the current profile
                ProfileStore.shared.setCurrentProfile(updatedProfile)
                
                // Create a session for this device
                let session = Session(
                    id: userIdentifier,
                    uuid: deviceUUID,
                    userName: displayName,
                    isEditing: false,
                    lastUpdate: Date(),
                    isActive: true,
                    deviceName: currentDeviceName
                )
                
                env.reservationService.upsertSession(session)
                logger.info("Updated existing profile and created session")
            } else {
                // Create a device for this session
                let device = Device(
                    id: deviceUUID,
                    name: currentDeviceName,
                    lastActive: Date(),
                    isActive: true
                )
                
                // Create the profile
                let profile = Profile(
                    id: userIdentifier,
                    firstName: trimmedFirstName,
                    lastName: trimmedLastName,
                    email: trimmedEmail,
                    imageURL: nil,
                    devices: [device],
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Save the profile
                env.reservationService.upsertProfile(profile)
                
                // Set the current profile
                ProfileStore.shared.setCurrentProfile(profile)
                
                // Create a session for this device
                let session = Session(
                    id: userIdentifier,
                    uuid: deviceUUID,
                    userName: displayName,
                    isEditing: false,
                    lastUpdate: Date(),
                    isActive: true,
                    deviceName: currentDeviceName
                )
                
                env.reservationService.upsertSession(session)
                logger.info("Created new profile and session")
            }
            
            // Setup database presence
            env.reservationService.setupRealtimeDatabasePresence(for: deviceUUID)
            
            // Mark profile as complete
            isProfileComplete = true
            
            // Dismiss this view to continue to the main app
            dismiss()
        }
    }
    
    /// Formats the name as "Firstname L." where L is the last name initial
    private func formatDisplayName(firstName: String, lastName: String) -> String {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get the first letter of the last name if available
        if let initialLetter = trimmedLastName.first {
            return "\(trimmedFirstName) \(initialLetter)."
        } else {
            // Fallback if somehow last name is empty but passed validation
            return trimmedFirstName
        }
    }
    
    /// Form field view
    ///
    /// This method creates a form field view.
    ///
    /// - Returns: A view of the form field
    private func formField(title: String, icon: String, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("", text: text)
                .font(.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .focused(isFocused)
                .submitLabel(.next)
        }
    }
    
    /// Animates the form
    ///
    /// This method animates the form.
    private func animateForm() {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            formScale = 1.0
            formOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            buttonScale = 1.0
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    UserOnboardingView()
}
