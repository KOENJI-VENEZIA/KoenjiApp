import SwiftUI
import OSLog

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
    @State private var showAlert: Bool = false
    @State private var formScale: CGFloat = 0.95
    @State private var formOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.95
    @State private var buttonOpacity: Double = 0
    @State private var existingAccountFound: Bool = false
    @State private var existingDisplayName: String = ""
    @State private var showExistingAccountAlert: Bool = false
    @FocusState private var isFirstNameFocused: Bool
    @FocusState private var isLastNameFocused: Bool
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "UserOnboardingView")
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
        .alert("Dati mancanti", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Per favore, inserisci nome e cognome per continuare.")
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
                deviceUUID = UUID().uuidString
                logger.debug("Generated new deviceUUID: \(deviceUUID)")
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
        
        // Check if this user has an existing session
        if let existingSession = SessionStore.shared.sessions.first(where: { $0.id == userIdentifier }) {
            existingAccountFound = true
            existingDisplayName = existingSession.userName
            logger.info("Found existing account: \(existingDisplayName)")
            
            // Show the alert asking if they want to reuse the profile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showExistingAccountAlert = true
            }
        } else {
            // Also check for saved names in UserDefaults as a fallback
            if let savedName = UserDefaults.standard.string(forKey: "savedDisplayName_\(userIdentifier)") {
                existingAccountFound = true
                existingDisplayName = savedName
                logger.info("Found existing name in UserDefaults: \(existingDisplayName)")
                
                // Show the alert asking if they want to reuse the profile
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showExistingAccountAlert = true
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
            deviceUUID = UUID().uuidString
            logger.debug("Generated new deviceUUID during profile reuse: \(deviceUUID)")
        }
        
        do {
            // Check if a session with this userIdentifier exists
            if let existingSession = SessionStore.shared.sessions.first(where: { $0.id == userIdentifier }) {
                // Update the existing session but keep the username
                var updatedSession = existingSession
                updatedSession.uuid = deviceUUID  // Update with current device
                updatedSession.isEditing = false
                updatedSession.lastUpdate = Date()
                updatedSession.isActive = true
                
                env.reservationService.upsertSession(updatedSession)
                logger.info("Updated existing session with new device: \(deviceUUID)")
            } else {
                // Create a new session with existing profile name
                let session = Session(
                    id: userIdentifier,
                    uuid: deviceUUID,
                    userName: existingDisplayName,
                    isEditing: false,
                    lastUpdate: Date(),
                    isActive: true
                )
                
                env.reservationService.upsertSession(session)
                logger.info("Created new session with existing profile: \(existingDisplayName)")
            }
            
            // Setup database presence
            env.reservationService.setupRealtimeDatabasePresence(for: deviceUUID)
            
            // Mark profile as complete
            isProfileComplete = true
            
            // Dismiss this view to continue to the main app
            dismiss()
        } catch {
            logger.error("Failed to create/update user session: \(error.localizedDescription)")
        }
    }
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    
    private func saveUserProfile() {
        // Dismiss keyboard
        isFirstNameFocused = false
        isLastNameFocused = false
        
        guard isFormValid else {
            showAlert = true
            return
        }
        
        // Critical check: Make sure we have a valid userIdentifier
        guard !userIdentifier.isEmpty else {
            logger.error("Cannot save user profile: userIdentifier is empty!")
            showAlert = true
            return
        }
        
        // Format the display name as "First L."
        let displayName = formatDisplayName(firstName: firstName, lastName: lastName)
        userName = displayName
        appleSignInVM.userName = displayName
        
        // Store both the display name and full name in UserDefaults
        let fullName = "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
        UserDefaults.standard.set(displayName, forKey: "savedDisplayName_\(userIdentifier)")
        UserDefaults.standard.set(fullName, forKey: "savedFullName_\(userIdentifier)")
        
        logger.debug("Creating/updating session with userIdentifier: \(userIdentifier), userName: \(displayName), deviceUUID: \(deviceUUID)")
        
        // Create session for the user
        // Make sure device UUID is valid
        if deviceUUID.isEmpty {
            deviceUUID = UUID().uuidString
            logger.debug("Generated new deviceUUID during profile save: \(deviceUUID)")
        }
        
        do {
            // Check if a session with this userIdentifier already exists
            if let existingSession = SessionStore.shared.sessions.first(where: { $0.id == userIdentifier }) {
                // Update the existing session
                var updatedSession = existingSession
                updatedSession.uuid = deviceUUID       // Update with current device UUID
                updatedSession.userName = displayName
                updatedSession.isEditing = false
                updatedSession.lastUpdate = Date()
                updatedSession.isActive = true
                
                env.reservationService.upsertSession(updatedSession)
                logger.info("Updated existing session for user: \(displayName)")
            } else {
                // Create a new session if none exists
                let session = Session(
                    id: userIdentifier,
                    uuid: deviceUUID,
                    userName: displayName,
                    isEditing: false,
                    lastUpdate: Date(),
                    isActive: true
                )
                
                env.reservationService.upsertSession(session)
                logger.info("Created new session for user: \(displayName)")
            }
            
            // Setup database presence
            env.reservationService.setupRealtimeDatabasePresence(for: deviceUUID)
            
            // Mark profile as complete
            isProfileComplete = true
            
            // Dismiss this view to continue to the main app
            dismiss()
        } catch {
            logger.error("Failed to create/update user session: \(error.localizedDescription)")
        }
    }
    
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
