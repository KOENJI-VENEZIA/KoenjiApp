//
//  ProfileAccountView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import SwiftUI
import OSLog

/// A view that displays a profile account with details and device management options
///
/// This view shows a list of profile details, including name, email, and devices.
/// It also allows the user to edit the profile information and log out from devices.
struct ProfileAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var env: AppDependencies
    
    @State private var profile: Profile
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var isEditing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showLogoutConfirmation = false
    @State private var deviceToLogout: Device?
    @State private var refreshTimer: Timer? = nil
    
    // Add states for image picker
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage = false
    
    private let logger = Logger(subsystem: "com.koenjiapp", category: "ProfileAccountView")
    
    init(profile: Profile) {
        self._profile = State(initialValue: profile)
        self._firstName = State(initialValue: profile.firstName)
        self._lastName = State(initialValue: profile.lastName)
        self._email = State(initialValue: profile.email)
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    
                    // Profile image with edit button
                    ZStack(alignment: .bottomTrailing) {
                        // Profile image
                        Button(action: {
                            showImagePicker = true
                        }) {
                            if let imageURL = profile.imageURL, !imageURL.isEmpty {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    case .failure:
                                        ProfileAvatarView(profile: profile, size: 100, showPopover: false)
                                    @unknown default:
                                        ProfileAvatarView(profile: profile, size: 100, showPopover: false)
                                    }
                                }
                                .frame(width: 100, height: 100)
                            } else {
                                ProfileAvatarView(profile: profile, size: 100, showPopover: false)
                            }
                        }
                        
                        // Edit button overlay
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue)
                                .font(.system(size: 24))
                                .background(Circle().fill(Color.white).frame(width: 22, height: 22))
                        }
                        .disabled(isUploadingImage)
                    }
                    .padding(.vertical)
                    
                    Spacer()
                }
                
                if isUploadingImage {
                    HStack {
                        Spacer()
                        ProgressView("Caricamento...")
                        Spacer()
                    }
                }
                
                if isEditing {
                    TextField("Nome", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Cognome", text: $lastName)
                        .textContentType(.familyName)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } else {
                    HStack {
                        Text("Nome")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(profile.firstName)
                    }
                    
                    HStack {
                        Text("Cognome")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(profile.lastName)
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(profile.email)
                    }
                }
            } header: {
                Text("Informazioni personali")
            } footer: {
                if isEditing {
                    Text("Queste informazioni sono utilizzate per identificarti nell'app.")
                }
            }
            
            Section {
                ForEach(profile.devices) { device in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .font(.headline)
                            
                            Text(device.isActive ? "Attivo" : "Non attivo")
                                .font(.caption)
                                .foregroundStyle(device.isActive ? .green : .secondary)
                        }
                        
                        Spacer()
                        
                        if device.isActive {
                            Button(action: {
                                deviceToLogout = device
                                showLogoutConfirmation = true
                            }) {
                                Text("Disconnetti")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            } header: {
                Text("Dispositivi")
            } footer: {
                Text("Qui puoi vedere tutti i dispositivi collegati al tuo account e disconnetterli se necessario.")
            }
            
            Section {
                Button(action: {
                    showLogoutConfirmation = true
                    deviceToLogout = nil
                }) {
                    HStack {
                        Spacer()
                        Text("Disconnetti tutti i dispositivi")
                            .foregroundStyle(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Il mio account")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    if isEditing {
                        saveProfile()
                    } else {
                        isEditing = true
                    }
                }) {
                    Text(isEditing ? "Salva" : "Modifica")
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Annulla") {
                        // Reset fields to original values
                        firstName = profile.firstName
                        lastName = profile.lastName
                        email = profile.email
                        isEditing = false
                    }
                } else {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert(
            "Sei sicuro di voler disconnettere?",
            isPresented: $showLogoutConfirmation,
            actions: {
                if let device = deviceToLogout {
                    Button("Disconnetti \(device.name)", role: .destructive) {
                        logoutDevice(device)
                    }
                } else {
                    Button("Disconnetti tutti i dispositivi", role: .destructive) {
                        logoutAllDevices()
                    }
                }
                
                Button("Annulla", role: .cancel) {
                    deviceToLogout = nil
                }
            },
            message: {
                if deviceToLogout != nil {
                    Text("Questo dispositivo verrà disconnesso dal tuo account.")
                } else {
                    Text("Tutti i dispositivi verranno disconnessi dal tuo account.")
                }
            }
        )
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let image = selectedImage {
                        uploadProfileImage(image)
                    }
                }
        }
        .onAppear {
            // Start a timer to refresh the profile data periodically
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task {
                    await refreshProfileData()
                }
            }
        }
        .onDisappear {
            // Invalidate the timer when the view disappears
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
    
    /// Refreshes the profile data from the database
    private func refreshProfileData() {
        if let updatedProfile = env.reservationService.getProfile(withID: profile.id) {
            if updatedProfile.updatedAt > profile.updatedAt {
                profile = updatedProfile
            }
        }
    }
    
    /// Validates an email address
    ///
    /// This method checks if the provided email address is valid using a regular expression.
    ///
    /// - Parameter email: The email address to validate
    /// - Returns: `true` if the email is valid, otherwise `false`
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Saves the profile information
    ///
    /// This method updates the profile with the new first name, last name, and email.
    /// It also updates the sessions that use this profile.
    private func saveProfile() {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedFirstName.isEmpty || trimmedLastName.isEmpty {
            alertMessage = "Nome e cognome sono campi obbligatori."
            showAlert = true
            return
        }
        
        if !isValidEmail(trimmedEmail) {
            alertMessage = "Inserisci un indirizzo email valido."
            showAlert = true
            return
        }
        
        var updatedProfile = profile
        updatedProfile.firstName = trimmedFirstName
        updatedProfile.lastName = trimmedLastName
        updatedProfile.email = trimmedEmail
        updatedProfile.updatedAt = Date()
        
        // Update the profile
        env.reservationService.upsertProfile(updatedProfile)
        
        // Update local state
        profile = updatedProfile
        
        // Update sessions that use this profile
        for session in SessionStore.shared.sessions where session.id == profile.id {
            var updatedSession = session
            updatedSession.userName = updatedProfile.displayName
            env.reservationService.upsertSession(updatedSession)
        }
        
        // Exit editing mode
        isEditing = false
        
        AppLog.info("Profile updated: \(profile.id)")
    }
    
    /// Logs out a specific device
    ///
    /// This method updates the device status to inactive and logs out the device if it is the current device.
    ///
    /// - Parameter device: The device to log out
    private func logoutDevice(_ device: Device) {
        env.reservationService.updateDeviceStatus(profileID: profile.id, deviceID: device.id, isActive: false)
        
        // Update local state
        if let index = profile.devices.firstIndex(where: { $0.id == device.id }) {
            var updatedProfile = profile
            updatedProfile.devices[index].isActive = false
            updatedProfile.devices[index].lastActive = Date()
            profile = updatedProfile
        }
        
        // If this is the current device, log out
        let currentDeviceUUID = UserDefaults.standard.string(forKey: "deviceUUID") ?? ""
        if device.id == currentDeviceUUID {
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.set(false, forKey: "isProfileComplete")
            dismiss()
        }
        
        AppLog.info("Device logged out: \(device.id)")
    }
    
    /// Logs out all devices for the current profile
    ///
    /// This method updates the device status to inactive for all devices and logs out the current device.
    /// It also updates the local state to reflect the logout.
    private func logoutAllDevices() {
        env.reservationService.logoutAllDevices(forProfileID: profile.id)
        
        // Update local state
        var updatedProfile = profile
        for i in 0..<updatedProfile.devices.count {
            updatedProfile.devices[i].isActive = false
            updatedProfile.devices[i].lastActive = Date()
        }
        profile = updatedProfile
        
        // Log out current device
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isProfileComplete")
        dismiss()
        
        AppLog.info("All devices logged out for profile: \(profile.id)")
    }
    
    /// Uploads a profile image to Google Cloud Storage
    ///
    /// This method uploads a profile image to Google Cloud Storage and updates the profile with the image URL.
    ///
    /// - Parameter image: The image to upload
    private func uploadProfileImage(_ image: UIImage) {
        isUploadingImage = true
        
        ProfileImageService.shared.uploadProfileImage(image, for: profile.id) { result in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                
                switch result {
                case .success(let url):
                    // Update the profile with the image URL
                    var updatedProfile = self.profile
                    updatedProfile.imageURL = url.absoluteString
                    updatedProfile.updatedAt = Date()
                    
                    // Save the updated profile
                    self.env.reservationService.upsertProfile(updatedProfile)
                    
                    // Update local state
                    self.profile = updatedProfile
                    
                    // Update sessions that use this profile
                    for session in SessionStore.shared.sessions where session.id == self.profile.id {
                        var updatedSession = session
                        updatedSession.profileImageURL = url.absoluteString
                        self.env.reservationService.upsertSession(updatedSession)
                    }
                    
                    AppLog.info("Profile image updated: \(url.absoluteString)")
                    
                case .failure(let error):
                    self.alertMessage = "Impossibile caricare l'immagine: \(error.localizedDescription)"
                    self.showAlert = true
                    AppLog.error("Failed to upload profile image: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// Image picker view for selecting profile images
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
} 
