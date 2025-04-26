//
//  ReservationService.swift
//  KoenjiApp
//
//  Created by [Your Name] on [Date].
//

import Foundation
import UIKit
import FirebaseFirestore
import Firebase
import FirebaseStorage
import SwiftUI
import OSLog

/// A service class responsible for high-level operations on reservations.
/// This class serves as the central coordinator for all reservation-related functionality in the app.
/// It manages the lifecycle of reservations including creation, updating, deletion, and synchronization with Firebase.
/// The service also handles table assignments, reservation status changes, and data persistence.
///
/// Key responsibilities:
/// - Managing reservation data in local storage and Firebase
/// - Coordinating table assignments for reservations
/// - Handling reservation status changes (confirm, cancel, etc.)
/// - Synchronizing data between devices via Firebase
/// - Managing session data for collaborative editing
/// - Providing caching mechanisms for efficient data access
class ReservationService: ObservableObject {
    // MARK: - Properties
    
    /// A shared instance of the reservation service
    @MainActor static var shared: ReservationService?
    
    /// The reservation store
    let store: ReservationStore
    
    /// The backup service
    let backupService: FirebaseBackupService
    
    /// Logger for tracking reservation operations
    let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationService")
    
    // MARK: - Dependencies
    
    /// Cache for efficiently accessing current reservations
    let resCache: CurrentReservationsCache
    
    /// Store for managing table clusters
    let clusterStore: ClusterStore
    
    /// Service for managing table clusters operations
    let clusterServices: ClusterServices
    
    /// Store for managing table data
    let tableStore: TableStore
    
    /// Service for managing restaurant layout operations
    let layoutServices: LayoutServices
    
    /// Service for assigning tables to reservations
    let tableAssignmentService: TableAssignmentService
    
    /// Service for managing push notifications
    let pushAlerts: PushAlerts
    
    /// Service for sending emails
    let emailService: EmailService
    
    /// Cache for storing reservation images
    var imageCache: [UUID: UIImage] = [:]
    
    /// Manager for handling local notifications
    let notifsManager: NotificationManager
    
    /// Published property that notifies observers when a reservation changes
    @Published var changedReservation: Reservation? = nil
    
    /// Firebase listener for reservation changes
    var reservationListener: ListenerRegistration?
    
    /// Firebase listener for session changes
    var sessionListener: ListenerRegistration?
    
    /// Firebase listener for web reservation changes
    var webReservationListener: ListenerRegistration?
    
    /// Firebase listener manager for handling all Firebase listeners
    let firebaseListener: FirebaseListener
    
    // MARK: - Initializer
    
    /// Initializes a new ReservationService with all required dependencies
    /// 
    /// This initializer sets up the service, loads data from disk, and starts Firebase listeners
    /// for real-time updates.
    ///
    /// - Parameters:
    ///   - store: The store for managing reservation data
    ///   - resCache: Cache for current reservations
    ///   - clusterStore: Store for table clusters
    ///   - clusterServices: Service for cluster operations
    ///   - tableStore: Store for table data
    ///   - layoutServices: Service for layout operations
    ///   - tableAssignmentService: Service for assigning tables
    ///   - backupService: Service for Firebase backup
    ///   - pushAlerts: Service for push notifications
    ///   - emailService: Service for sending emails
    ///   - notifsManager: Manager for local notifications
    ///   - firebaseListener: Manager for Firebase listeners
    ///   - isPreview: Whether this service is running in preview mode
    @MainActor
    init(store: ReservationStore, resCache: CurrentReservationsCache, clusterStore: ClusterStore, clusterServices: ClusterServices, tableStore: TableStore, layoutServices: LayoutServices, tableAssignmentService: TableAssignmentService, backupService: FirebaseBackupService, pushAlerts: PushAlerts, emailService: EmailService, notifsManager: NotificationManager = NotificationManager.shared, firebaseListener: FirebaseListener, isPreview: Bool = false) {
        self.store = store
        self.resCache = resCache
        self.clusterStore = clusterStore
        self.clusterServices = clusterServices
        self.tableStore = tableStore
        self.layoutServices = layoutServices
        self.tableAssignmentService = tableAssignmentService
        self.backupService = backupService
        self.pushAlerts = pushAlerts
        self.emailService = emailService
        self.notifsManager = notifsManager
        self.firebaseListener = firebaseListener
        
        self.layoutServices.loadFromDisk()
        self.clusterServices.loadClustersFromDisk()
        
        // In preview mode, we skip Firebase operations and just populate with mock data
        if isPreview {
            AppLog.debug("Preview mode: Using mock data for ReservationService")
            self.store.reservations = MockData.mockReservations
        } else {
            // Start Firebase listeners
            self.setupFirebaseListeners()

            // Load data directly from Firebase
            self.loadReservationsFromFirebase()
            self.loadSessionsFromFirebase()
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        self.resCache.preloadDates(around: today, range: 5, reservations: self.store.reservations)
    }
    
    /// Removes Firebase listeners when the service is deallocated
    deinit {
        self.firebaseListener.stopAllListeners()
        }
    
    /// Migrates the SQLite database schema to the latest version if needed
    ///
    /// This method checks the current database version and applies any necessary
    /// schema changes to bring it up to the target version.
    ///
    /// - Note: When making schema changes, increment the `targetVersion` and add
    ///         the migration code for each version step.
    @MainActor
    func migrateDatabaseIfNeeded() {
        do {
            // Get the current database version.
            let currentVersion = try SQLiteManager.shared.db.scalar("PRAGMA user_version") as? Int64 ?? 0
            let targetVersion: Int64 = 2  // Increment this whenever you change your schema
            
            if currentVersion < targetVersion {
                // Example: For version 2, add the sessionUUID column to sessions table.
                if currentVersion < 2 {
                    // Execute raw SQL to add a new column.
                    try SQLiteManager.shared.db.run("ALTER TABLE sessions ADD COLUMN uuid TEXT")
                    AppLog.info("Migration: Added uuid column to sessions table.")
                }
                
                // Update the database version.
                try SQLiteManager.shared.db.run("PRAGMA user_version = \(targetVersion)")
            }
        } catch {
            AppLog.error("Database migration error: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    /// Inserts or updates a session in both local storage and Firebase
    ///
    /// This method saves the session to SQLite, updates the in-memory session store,
    /// and synchronizes the data with Firebase.
    ///
    /// - Parameter session: The session to insert or update
    @MainActor
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
        
        // Push changes to Firestore
        #if DEBUG
        let dbRef = backupService.db?.collection("sessions")
        #else
        let dbRef = backupService.db?.collection("sessions_release")
        #endif
        
        let data = convertSessionToDictionary(session: session)
        
        // Using the device UUID as the document ID
        dbRef?.document(session.uuid).setData(data) { [self] error in
            if let error = error {
                AppLog.error("Error upserting session: \(error.localizedDescription)")
            } else {
                AppLog.debug("Session upserted successfully")
            }
        }
    }

    // MARK: - Profile Management
    
    /// Inserts or updates a profile in both local storage and Firebase
    ///
    /// This method saves the profile to SQLite, updates the in-memory profile store,
    /// and synchronizes the data with Firebase.
    ///
    /// - Parameter profile: The profile to insert or update
    @MainActor
    func upsertProfile(_ profile: Profile) {
        // Save to SQLite
        SQLiteManager.shared.insertProfile(profile)
        
        // Update the in-memory store
        DispatchQueue.main.async {
            ProfileStore.shared.updateProfile(profile)
        }
        
        // Push changes to Firestore
        #if DEBUG
        let dbRef = backupService.db?.collection("profiles")
        #else
        let dbRef = backupService.db?.collection("profiles_release")
        #endif
        
        let data = convertProfileToDictionary(profile: profile)
        
        // Using the profile's ID as the document ID
        dbRef?.document(profile.id).setData(data) { [self] error in
            if let error = error {
                AppLog.error("Error pushing profile to Firebase: \(error)")
            } else {
                AppLog.debug("Profile pushed to Firebase successfully.")
            }
        }
    }

    /// Loads profiles from SQLite and updates the in-memory profile store
    @MainActor
    func loadProfiles() {
        let profiles = SQLiteManager.shared.getAllProfiles()
        
        DispatchQueue.main.async {
            ProfileStore.shared.setProfiles(profiles)
        }
        
        AppLog.info("Loaded \(profiles.count) profiles from SQLite")
    }

    /// Retrieves a profile from SQLite by ID
    ///
    /// - Parameter id: The ID of the profile to retrieve
    /// - Returns: The profile if found, otherwise nil
    @MainActor
    func getProfile(withID id: String) -> Profile? {
        return SQLiteManager.shared.getProfile(withID: id)
    }

    /// Creates a new profile from a session and email
    ///
    /// This method extracts the first name and last name from the session userName,
    /// creates a device for the session, and constructs a new profile.
    ///
    /// - Parameters: 
    ///   - session: The session to create the profile from
    ///   - email: The email of the profile
    /// - Returns: The newly created profile
    @MainActor
    func createProfileFromSession(_ session: Session) -> Profile {
        // Extract first name and last name from userName
        let components = session.userName.components(separatedBy: " ")
        let firstName = components.first ?? ""
        let lastName = components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
        
        // Create a device for this session
        let device = Device(
            id: session.uuid,
            name: session.deviceName ?? DeviceInfo.shared.getDeviceName(),
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
    ///
    /// This method updates the status of a device in the profile's devices array,
    /// updates the device's lastActive timestamp, and saves the updated profile to SQLite.
    ///
    /// - Parameters: 
    ///   - profileID: The ID of the profile to update
    ///   - deviceID: The ID of the device to update
    ///   - isActive: The new status of the device
    @MainActor
    func updateDeviceStatus(profileID: String, deviceID: String, isActive: Bool) {
        // Update SQLite database
        SQLiteManager.shared.updateDeviceStatus(deviceId: deviceID, isActive: isActive)
        
        // Update the profile in memory
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Find the device in the profile
            if let deviceIndex = profile.devices.firstIndex(where: { $0.id == deviceID }) {
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
                
                AppLog.debug("Updated device status for profile: \(profileID), device: \(deviceID), active: \(isActive)")
            } else {
                AppLog.error("Cannot update device status: Device not found in profile \(profileID)")
            }
        } else {
            AppLog.error("Cannot update device status: Profile not found for ID \(profileID)")
        }
    }

    @MainActor
    func logoutAllDevices(forProfileID profileID: String) {
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Update all devices to inactive
            for i in 0..<updatedProfile.devices.count {
                updatedProfile.devices[i].isActive = false
                updatedProfile.devices[i].lastActive = Date()
            }
            
            // Update the profile
            upsertProfile(updatedProfile)
            
            // Update all sessions for this profile
            for session in SessionStore.shared.sessions where session.id == profileID {
                var updatedSession = session
                updatedSession.isActive = false
                updatedSession.isEditing = false
                upsertSession(updatedSession)
            }
        }
    }

    @MainActor
    private func convertProfileToDictionary(profile: Profile) -> [String: Any] {
        var deviceData: [[String: Any]] = []
        
        for device in profile.devices {
            let deviceDict: [String: Any] = [
                "id": device.id,
                "name": device.name,
                "lastActive": device.lastActive.timeIntervalSince1970,
                "isActive": device.isActive
            ]
            deviceData.append(deviceDict)
        }
        
        return [
            "id": profile.id,
            "firstName": profile.firstName,
            "lastName": profile.lastName,
            "email": profile.email,
            "imageURL": profile.imageURL as Any,
            "devices": deviceData,
            "createdAt": profile.createdAt.timeIntervalSince1970,
            "updatedAt": profile.updatedAt.timeIntervalSince1970
        ]
    }

    // MARK: - Reservation Management
    
    /// Adds a new reservation to the system
    ///
    /// This method adds a reservation to SQLite, updates the in-memory cache and store,
    /// marks assigned tables as occupied, and synchronizes the data with Firebase.
    ///
    /// - Note: The method assumes the reservation's tables have already been assigned.
    ///         If not, the reservation will be unassigned.
    ///
    /// - Parameter reservation: The reservation to add
    @MainActor
    func addReservation(_ reservation: Reservation) {
        // Update Database
        SQLiteManager.shared.insertReservation(reservation)

        // Manage in-store memory
        DispatchQueue.main.async {
            self.resCache.addOrUpdateReservation(reservation)
            self.store.reservations.append(reservation)
            self.store.reservations = Array(self.store.reservations)
            self.changedReservation = reservation
            reservation.tables.forEach { self.layoutServices.markTable($0, occupied: true) }
            self.invalidateClusterCache(for: reservation)
            AppLog.debug("Added reservation \(reservation.id) with tables \(reservation.tables)")
        }
        
        // Push changes to Firestore with the improved dictionary conversion
        #if DEBUG
        let dbRef = backupService.db?.collection("reservations")
        #else
        let dbRef = backupService.db?.collection("reservations_release")
        #endif
        
        let data = convertReservationToDictionary(reservation: reservation)
        
        // Using the reservation's UUID string as the document ID:
        dbRef?.document(reservation.id.uuidString).setData(data) { error in
            if let error = error {
                AppLog.error("Error pushing reservation to Firebase: \(error)")
            } else {
                AppLog.debug("Reservation pushed to Firebase successfully.")
            }
        }
    }
    
    /// Adds multiple reservations to the system
    ///
    /// This method adds multiple reservations to SQLite in a batch operation.
    ///
    /// - Parameter reservations: An array of reservations to add
    @MainActor
    func addReservations(_ reservations: [Reservation]) {
        for reservation in reservations {
            SQLiteManager.shared.insertReservation(reservation)
        }
    }
    
    /// Converts a Session object to a dictionary for Firebase storage
    ///
    /// - Parameter session: The session to convert
    /// - Returns: A dictionary representation of the session
    @MainActor
    private func convertSessionToDictionary(session: Session) -> [String: Any] {
        var data: [String: Any] = [
            "id": session.id,
            "uuid": session.uuid,
            "userName": session.userName,
            "isEditing": session.isEditing,
            "lastUpdate": session.lastUpdate.timeIntervalSince1970,
            "isActive": session.isActive
        ]
        
        // Add device name if available
        if let deviceName = session.deviceName {
            data["deviceName"] = deviceName
        }
        
        // Add profile image URL if available
        if let profileImageURL = session.profileImageURL {
            data["profileImageURL"] = profileImageURL
        }
        
        return data
    }
    
    /// Converts a Reservation object to a dictionary for Firebase storage
    ///
    /// This method also attempts to assign tables to confirmed reservations
    /// that don't have tables assigned.
    ///
    /// - Parameter reservation: The reservation to convert
    /// - Returns: A dictionary representation of the reservation
    @MainActor
    private func convertReservationToDictionary(reservation: Reservation) -> [String: Any] {
        var updatedReservation = reservation
        
        // Check if this is a confirmed reservation with no tables
        if updatedReservation.acceptance == .confirmed && updatedReservation.tables.isEmpty {
            // Log this issue
            AppLog.warning("⚠️ Found confirmed reservation with no tables: \(updatedReservation.name)")
            
            // Try to assign tables automatically
                let layoutServices = self.layoutServices
                let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    AppLog.info("✅ Auto-assigned \(assignedTables.count) tables to reservation: \(updatedReservation.name)")
                    updatedReservation.tables = assignedTables
                case .failure(let error):
                    AppLog.error("❌ Failed to auto-assign tables: \(error.localizedDescription)")
                }
            } else {
                AppLog.error("❌ Cannot auto-assign tables: layoutServices not available")
            }
        
        
        // Convert tables to a simpler format that Firestore can handle better
        let tableIds = updatedReservation.tables.map { $0.id }
        
        // Create a thread-safe copy for Firestore
        var dict: [String: Any] = [
            "id": updatedReservation.id.uuidString,
            "name": updatedReservation.name,
            "phone": updatedReservation.phone,
            "numberOfPersons": updatedReservation.numberOfPersons,
            "dateString": updatedReservation.dateString,
            "category": updatedReservation.category.rawValue,
            "startTime": updatedReservation.startTime,
            "endTime": updatedReservation.endTime,
            "acceptance": updatedReservation.acceptance.rawValue,
            "status": updatedReservation.status.rawValue,
            "reservationType": updatedReservation.reservationType.rawValue,
            "group": updatedReservation.group,
            "tableIds": tableIds,
            "tables": updatedReservation.tables.map { table in
                return [
                    "id": table.id,
                    "name": table.name,
                    "maxCapacity": table.maxCapacity
                ]
            },
            "creationDate": updatedReservation.creationDate.timeIntervalSince1970,
            "lastEditedOn": updatedReservation.lastEditedOn.timeIntervalSince1970,
            "isMock": updatedReservation.isMock,
            "colorHue": updatedReservation.colorHue,
            "preferredLanguage": updatedReservation.preferredLanguage ?? "it"
        ]
        
        // Handle optional values separately and safely
        if let notes = updatedReservation.notes {
            dict["notes"] = notes
        } else {
            dict["notes"] = NSNull()
        }
        
        if let assignedEmoji = updatedReservation.assignedEmoji {
            dict["assignedEmoji"] = assignedEmoji
        } else {
            dict["assignedEmoji"] = NSNull()
        }
        
        if let imageData = updatedReservation.imageData {
            dict["imageData"] = imageData
        } else {
            dict["imageData"] = NSNull()
        }
        
        return dict
    }

    /// Updates an existing reservation, refreshes the cache, and reassigns tables if needed
    ///
    /// This method handles the complete update process for a reservation, including:
    /// - Invalidating caches
    /// - Updating the database
    /// - Managing table assignments
    /// - Synchronizing with Firebase
    ///
    /// - Parameters:
    ///   - oldReservation: The original reservation to update
    ///   - newReservation: Optional new reservation data (defaults to oldReservation if nil)
    ///   - index: Optional index in the reservations array (will be looked up if nil)
    ///   - shouldPersist: Whether to persist changes to Firebase (defaults to true)
    ///   - completion: Closure to call when the update is complete
    @MainActor
    func updateReservation(_ oldReservation: Reservation, newReservation: Reservation? = nil, at index: Int? = nil, shouldPersist: Bool = true, completion: @escaping () -> Void) {
        // Remove from active cache
        self.invalidateClusterCache(for: oldReservation)
        resCache.removeReservation(oldReservation)
        
        let updatedReservation = newReservation ?? oldReservation

        DispatchQueue.main.async {
            let reservationIndex = index ?? self.store.reservations.firstIndex(where: { $0.id == oldReservation.id })

            guard let reservationIndex else {
                AppLog.error("Error: Reservation with ID \(oldReservation.id) not found.")
                return
            }
            
            SQLiteManager.shared.insertReservation(updatedReservation)
            
            self.store.reservations[reservationIndex] = updatedReservation
            self.store.reservations = Array(self.store.reservations)
            self.changedReservation = updatedReservation
            AppLog.info("Changed changedReservation, should update UI...")

            let oldReservation = self.store.reservations[reservationIndex]
            
            // 🔹 Compare old and new tables before unmarking/marking
            let oldTableIDs = Set(oldReservation.tables.map { $0.id })
            let newTableIDs = Set(updatedReservation.tables.map { $0.id })
            
            if oldTableIDs != newTableIDs {
                AppLog.debug("Table change detected for reservation \(updatedReservation.id). Updating tables...")

                // Unmark only if tables have changed
                for tableID in oldTableIDs.subtracting(newTableIDs) {
                    if let table = oldReservation.tables.first(where: { $0.id == tableID }) {
                        self.layoutServices.unmarkTable(table)
                    }
                }

                // Mark only new tables that weren't already assigned
                for tableID in newTableIDs.subtracting(oldTableIDs) {
                    if let table = updatedReservation.tables.first(where: { $0.id == tableID }) {
                        self.layoutServices.markTable(table, occupied: true)
                    }
                }
                
                // Invalidate cluster cache only if tables changed
                self.invalidateClusterCache(for: updatedReservation)
            } else if newTableIDs.isEmpty {
                oldReservation.tables.forEach { self.layoutServices.unmarkTable($0) }
            } else {
                AppLog.info("No table change detected for reservation \(updatedReservation.id). Skipping table update.")
            }

            // Update the reservation in the store
            self.resCache.addOrUpdateReservation(updatedReservation)
            if shouldPersist {
                self.store.finalizeReservation(updatedReservation)
                // Update database
                // Pushes to Firestore with the improved dictionary conversion
                #if DEBUG
                let dbRef = self.backupService.db?.collection("reservations")
                #else
                let dbRef = self.backupService.db?.collection("reservations_release")
                #endif
                
                let data = self.convertReservationToDictionary(reservation: updatedReservation)
                
                // Using the reservation's UUID string as the document ID:
                dbRef?.document(updatedReservation.id.uuidString).setData(data) { error in
                    if let error = error {
                        AppLog.error("Error pushing reservation to Firebase: \(error)")
                    } else {
                        AppLog.debug("Reservation pushed to Firebase successfully.")
                    }
                }
            }
            AppLog.debug("Updated reservation \(updatedReservation.id).")
        }

        // Finalize and save
        completion()
    }
    
    /// Updates all reservations in Firestore
    ///
    /// This method synchronizes all local reservations with Firebase,
    /// ensuring that the remote database is up-to-date with the local state.
    ///
    /// - Note: This operation can be resource-intensive for large datasets.
    @MainActor
    func updateAllReservationsInFirestore() async {
        AppLog.info("Beginning update of all reservations in Firestore...")
        
        let allReservations = self.store.reservations
        
        #if DEBUG
        let dbRef = backupService.db?.collection("reservations")
        #else
        let dbRef = backupService.db?.collection("reservations_release")
        #endif
        
        var successCount = 0
        var errorCount = 0
        
        for reservation in allReservations {
            do {
                // Since convertReservationToDictionary is also @MainActor, we're staying on the same actor
                let data = convertReservationToDictionary(reservation: reservation)
                
                // Create a properly isolated copy of the dictionary for Firestore
                try await Task {
                    try await dbRef?.document(reservation.id.uuidString).setData(data)
                }.value
                
                successCount += 1
                AppLog.debug("Updated reservation \(reservation.id) in Firestore")
            } catch {
                errorCount += 1
                AppLog.error("Failed to update reservation \(reservation.id) in Firestore: \(error)")
            }
        }
        
        AppLog.info("Completed updating all reservations in Firestore. Success: \(successCount), Errors: \(errorCount)")
    }

    
    /// Handles the confirmation of a reservation
    ///
    /// This method processes a reservation confirmation, assigning tables
    /// if the reservation is from the waiting list or was previously canceled.
    ///
    /// - Parameter reservation: The reservation to confirm
    @MainActor
    func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.reservationType == .waitingList || updatedReservation.status == .canceled {
            let assignmentResult = layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                DispatchQueue.main.async {
                    // do actual saving logic here
                    updatedReservation.tables = assignedTables
                    updatedReservation.reservationType = .inAdvance
                    updatedReservation.status = .pending
                    self.updateReservation(updatedReservation) {
                        AppLog.info("Updated reservations.")
                    }

                }
            case .failure(let error):
                switch error {
                    case .noTablesLeft:
                    pushAlerts.alertMessage = String(localized: "Non ci sono tavoli disponibili.")
                    case .insufficientTables:
                    pushAlerts.alertMessage = String(localized: "Non ci sono abbastanza tavoli per la prenotazione.")
                    case .tableNotFound:
                    pushAlerts.alertMessage = String(localized: "Tavolo selezionato non trovato.")
                    case .tableLocked:
                    pushAlerts.alertMessage = String(localized: "Il tavolo scelto è occupato o bloccato.")
                    case .unknown:
                    pushAlerts.alertMessage = String(localized: "Errore sconosciuto.")
                    }
                    pushAlerts.showAlert = true
            }
        }
    }
    
    /// Clears all reservation data from Firestore
    ///
    /// This method removes all reservation documents from the Firebase database.
    /// Use with caution as this operation cannot be undone.
    ///
    /// - Parameter completion: Closure called when the operation completes, with an optional error
    @MainActor
    func clearAllDataFromFirestore(completion: @escaping (Error?) -> Void) {
        // Use the safe Firebase initialization method
        guard let db = AppDependencies.getFirestore() else {
            // In preview mode, just call the completion handler
            AppLog.debug("Preview mode: Skipping clearAllDataFromFirestore")
            completion(nil)
            return
        }
        
        #if DEBUG
        let reservationsRef = db.collection("reservations")
        #else
        let reservationsRef = db.collection("reservations_release")
        #endif
        reservationsRef.getDocuments { snapshot, error in
            if let error = error {
                AppLog.error("Error fetching documents for deletion: \(error)")
                completion(error)
                return
            }
            
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            
            let batch = db.batch()
            snapshot.documents.forEach { document in
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    AppLog.error("Error committing batch deletion: \(error)")
                } else {
                    AppLog.debug("Successfully deleted all reservations from Firestore.")
                }
                completion(error)
            }
        }
    }
    
    /// Clears all reservation data from the system
    ///
    /// This method removes all reservations from:
    /// - In-memory storage
    /// - SQLite database
    /// - Firebase database
    /// - All caches
    ///
    /// Use with extreme caution as this operation cannot be undone.
    @MainActor 
    func clearAllData() {
        store.reservations.removeAll() // Clear in-memory reservations
        
        SQLiteManager.shared.deleteAllReservations()
        flushAllCaches() // Clear any cached layouts or data
        
        clearAllDataFromFirestore { error in
               if let error = error {
                   AppLog.error("Error clearing Firestore data: \(error)")
               } else {
                   AppLog.debug("All Firestore data cleared successfully.")
               }
           }
        
        AppLog.info("ReservationService: All data has been cleared.")
    }
    
    /// Fetches reservations for a specific date.
    /// - Parameter date: The date for which to fetch reservations.
    /// - Returns: A list of reservations for the given date.
    func fetchReservations(on date: Date) -> [Reservation] {
        let targetDateString = DateHelper.formatDate(date) // Use centralized helper
        return store.reservations.filter { $0.dateString == targetDateString }
    }
    
    /// Retrieves reservations for a specific category on a given date.
    ///
    /// - Parameters:
    ///   - date: The date for which to fetch reservations
    ///   - category: The reservation category to filter by
    /// - Returns: A list of reservations matching both date and category
    func fetchReservations(on date: Date, for category: Reservation.ReservationCategory) -> [Reservation] {
        fetchReservations(on: date).filter { $0.category == category }
    }
    
    // MARK: - Cluster Cache Invalidation

    /// Invalidates the cluster cache for the given reservation.
    ///
    /// This method clears any cached cluster data for a specific reservation date and category
    /// to ensure fresh data is loaded when needed.
    ///
    /// - Parameter reservation: The reservation to invalidate cache for
    private func invalidateClusterCache(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate else {
            Task { @MainActor in
                AppLog.error("Failed to parse dateString \(reservation.normalizedDate ?? Date()). Cache invalidation skipped.")
            }
            return
        }
        self.clusterStore.invalidateClusterCache(for: reservationDate, category: reservation.category)
    }
        
    
    // MARK: - Methods for Queries
    
    /// Retrieves reservations by category.
    /// - Parameter category: The reservation category.
    /// - Returns: A list of reservations matching the category.
    func getReservations(by category: Reservation.ReservationCategory) -> [Reservation] {
        // Retrieve all reservations from the ReservationStore
        let allReservations = store.getReservations()
        
        // Filter reservations matching the specified category
        let filteredReservations = allReservations.filter { $0.category == category }
        
        // Return the filtered list
        return filteredReservations
    }
    
    // MARK: - Methods for Database Persistence
    
    /// Loads all reservations directly from Firebase
    ///
    /// This method fetches all reservation data from Firebase, processes it,
    /// and updates the local database and caches with the retrieved data.
    /// It also ensures that confirmed reservations have tables assigned.
    @MainActor
    func loadReservationsFromFirebase() {
        AppLog.info("Loading reservations directly from Firebase...")
        
        withAnimation {
            backupService.isWritingToFirebase = true
        }
        
        #if DEBUG
        let reservationsRef = backupService.db?.collection("reservations")
        #else
        let reservationsRef = backupService.db?.collection("reservations_release")
        #endif
        
        Task {
            do {
                guard let snapshot = try await reservationsRef?.getDocuments() else { return }
                AppLog.info("Retrieved \(snapshot.documents.count) reservation documents from Firebase")
                
                var loadedReservations: [Reservation] = []
                var failedCount = 0
                
                for document in snapshot.documents {
                    do {
                        let reservation = try self.reservationFromFirebaseDocument(document)
                        
                        // Ensure confirmed reservations have tables
                        if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
                            AppLog.warning("⚠️ Found confirmed reservation with no tables: \(reservation.name)")
                            
                            let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                            if case .success(let assignedTables) = assignmentResult {
                                var updatedReservation = reservation
                                updatedReservation.tables = assignedTables
                                loadedReservations.append(updatedReservation)
                                AppLog.info("✅ Auto-assigned \(assignedTables.count) tables to reservation: \(updatedReservation.name)")
                            } else {
                                loadedReservations.append(reservation)
                                AppLog.error("❌ Failed to auto-assign tables to reservation: \(reservation.name)")
                            }
                        } else {
                            loadedReservations.append(reservation)
                        }
                    } catch {
                        failedCount += 1
                        AppLog.error("Failed to decode reservation from document \(document.documentID): \(error)")
                    }
                }
                
                // Update the store with loaded reservations
                await MainActor.run {
                    AppLog.info("Successfully decoded \(loadedReservations.count) reservations (failed: \(failedCount))")
                    
                    // Update the store
                    self.store.setReservations(loadedReservations)
                    
                    // Update the cache
                    self.resCache.clearCache() // Clear the cache first to remove any stale data
                    for reservation in loadedReservations {
                        self.resCache.addOrUpdateReservation(reservation)
                    }
                    
                    // Preload dates for the cache
                    let today = Calendar.current.startOfDay(for: Date())
                    self.resCache.preloadDates(around: today, range: 5, reservations: loadedReservations)
                    
                    AppLog.info("Successfully loaded \(loadedReservations.count) reservations from Firebase")
                    
                    withAnimation {
                        self.backupService.isWritingToFirebase = false
                    }
                }
            } catch {
                AppLog.error("Error loading reservations from Firebase: \(error.localizedDescription)")
                withAnimation {
                    self.backupService.isWritingToFirebase = false
                }
            }
        }
    }
    
    /// Loads all sessions directly from Firebase
    ///
    /// This method fetches all session data from Firebase, processes it,
    /// and updates the session store with the retrieved data.
    @MainActor
    func loadSessionsFromFirebase() {
        AppLog.info("Loading sessions directly from Firebase...")
        
        withAnimation {
            backupService.isWritingToFirebase = true
        }
        
        #if DEBUG
        let sessionsRef = backupService.db?.collection("sessions")
        #else
        let sessionsRef = backupService.db?.collection("sessions_release")
        #endif
        
        Task {
            do {
                guard let snapshot = try await sessionsRef?.getDocuments() else { return }
                var loadedSessions: [Session] = []
                
                for document in snapshot.documents {
                    if let session = try? self.sessionFromFirebaseDocument(document) {
                        loadedSessions.append(session)
                    } else {
                        AppLog.error("Failed to decode session from document: \(document.documentID)")
                    }
                }
                
                // Update the store with loaded sessions
                await MainActor.run {
                    SessionStore.shared.sessions = loadedSessions
                    AppLog.info("Successfully loaded \(loadedSessions.count) sessions from Firebase")
                    
                    withAnimation {
                        self.backupService.isWritingToFirebase = false
                    }
                }
            } catch {
                AppLog.error("Error loading sessions from Firebase: \(error.localizedDescription)")
                withAnimation {
                    self.backupService.isWritingToFirebase = false
                }
            }
        }
    }
    
    /// Converts a Firebase document to a Reservation object
    ///
    /// This method extracts data from a Firebase document and creates
    /// a Reservation object with the appropriate properties.
    ///
    /// - Parameter document: The Firebase document containing reservation data
    /// - Returns: A Reservation object
    /// - Throws: An error if required fields are missing or invalid
    func reservationFromFirebaseDocument(_ document: DocumentSnapshot) throws -> Reservation {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
        // Extract basic fields
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        // Extract tables
        var tables: [TableModel] = []
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
                    tables.append(table)
                }
            }
        } else if let tableIds = data["tableIds"] as? [Int] {
            // Fallback to tableIds if tables array is not available
            tables = tableIds.map { id in
                TableModel(id: id, name: "Table \(id)", maxCapacity: 4, row: 0, column: 0)
            }
        }
        
        // Extract optional fields
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        
        // Create and return the reservation
        return Reservation(
            id: id,
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes,
            tables: tables,
            creationDate: Date(timeIntervalSince1970: creationTimeInterval),
            lastEditedOn: Date(timeIntervalSince1970: lastEditedTimeInterval),
            isMock: isMock,
            assignedEmoji: assignedEmoji ?? "",
            imageData: imageData,
            preferredLanguage: preferredLanguage
        )
    }
    
    /// Converts a Firebase document to a Session object
    ///
    /// - Parameter data: Dictionary containing session data from Firebase
    /// - Returns: A Session object if conversion is successful, nil otherwise
    @MainActor
    private func convertDictionaryToSession(data: [String: Any]) -> Session? {
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimestamp = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            AppLog.error("Missing required fields in session data")
            return nil
        }
        
        let lastUpdate = Date(timeIntervalSince1970: lastUpdateTimestamp)
        let uuid = data["uuid"] as? String ?? UUID().uuidString
        
        return Session(
            id: id,
            uuid: uuid,
            userName: userName,
            isEditing: isEditing,
            lastUpdate: lastUpdate,
            isActive: isActive
        )
    }
    
    /// Converts a Firebase document to a Session object
    ///
    /// This method extracts data from a Firebase document and creates
    /// a Session object with the appropriate properties.
    ///
    /// - Parameter document: The Firebase document containing session data
    /// - Returns: A Session object
    /// - Throws: An error if required fields are missing or invalid
    private func sessionFromFirebaseDocument(_ document: DocumentSnapshot) throws -> Session {
        guard let data = document.data() else {
            throw NSError(domain: "com.koenjiapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document data is nil"])
        }
        
        // Extract fields
        guard let id = data["id"] as? String,
              let userName = data["userName"] as? String,
              let isEditing = data["isEditing"] as? Bool,
              let lastUpdateTimeInterval = data["lastUpdate"] as? TimeInterval,
              let isActive = data["isActive"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        let uuid = data["uuid"] as? String ?? document.documentID
        let deviceName = data["deviceName"] as? String
        let profileImageURL = data["profileImageURL"] as? String
        
        // Create and return the session
        return Session(
            id: id,
            uuid: uuid,
            userName: userName,
            isEditing: isEditing,
            lastUpdate: Date(timeIntervalSince1970: lastUpdateTimeInterval),
            isActive: isActive,
            deviceName: deviceName,
            profileImageURL: profileImageURL
        )
    }
    
    /// Gets the URL for the reservations file in the documents directory
    ///
    /// - Returns: URL to the reservations file
    private func getReservationsFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(store.reservationsFileName)
    }

    func setupFirebaseListeners() {
        // Start the reservation listener
        firebaseListener.startReservationListener()
        
        // Start the session listener
        firebaseListener.startSessionListener()
        
        // Start the profile listener
        
        firebaseListener.startProfileListener()
        
        Task { @MainActor in
            AppLog.info("Firebase listeners set up")
        }
    }

    @MainActor
    func setupRealtimeDatabasePresence(for deviceUUID: String) {
        // This is now handled by the SessionManager
        AppLog.debug("Presence detection is now handled by SessionManager")
    }
    
    /// Deactivates a device remotely
    ///
    /// This method deactivates a device remotely by setting its isActive status to false.
    /// This will cause the device to be logged out the next time it checks its activation status.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the profile
    ///   - deviceID: The ID of the device to deactivate
    @MainActor
    func deactivateDeviceRemotely(profileID: String, deviceID: String) {
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
                upsertProfile(updatedProfile)
                
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
}

// MARK: - Mock Data
extension ReservationService {
    /// Loads two sample reservations for demonstration purposes
    ///
    /// This method creates and adds mock reservations to the system
    /// for testing and demonstration purposes.
    @MainActor
    private func mockData() {
        layoutServices.setTables(tableStore.baseTables)
        AppLog.debug("Tables populated in mockData: \(self.layoutServices.tables.map { $0.name })")
        
        let mockReservation1 = Reservation(
            name: "Alice",
            phone: "+44 12345678901",
            numberOfPersons: 2,
            dateString: DateHelper.formatFullDate(Date()), // Use today
            category: .lunch,
            startTime: "12:00",
            endTime: "13:45",
            acceptance: .confirmed,
            status: .pending,
            reservationType: .inAdvance,
            group: false,
            notes: "Birthday",
            isMock: true
        )
        
        let mockReservation2 = Reservation(
            name: "Bob",
            phone: "+33 98765432101",
            numberOfPersons: 4,
            dateString: DateHelper.formatFullDate(Date()), // Use today
            category: .dinner,
            startTime: "19:30",
            endTime: "21:45",
            acceptance: .confirmed,
            status: .pending,
            reservationType: .inAdvance,
            group: false,
            notes: "Allergic to peanuts",
            isMock: true
        )
        
        addReservation(mockReservation1)
        addReservation(mockReservation2)
        
    }
}

extension ReservationService {
    // MARK: - Test Data
    
    /// Generates realistic reservation data for a specified number of days
    ///
    /// This method creates realistic reservation data for testing and demonstration purposes.
    /// It generates reservations with varied party sizes, times, and other attributes.
    ///
    /// - Parameters:
    ///   - daysToSimulate: Number of days to generate reservations for
    ///   - force: Whether to force generation even if data already exists
    ///   - startFromLastSaved: Whether to start from the last saved reservation date
    @MainActor
    func generateReservations(
        daysToSimulate: Int,
        force: Bool = false,
        startFromLastSaved: Bool = true
    ) async {
        // 1. Determine start date
        var startDate = Calendar.current.startOfDay(for: Date())

        if startFromLastSaved {
            if let maxReservation = self.store.reservations.max(by: { lhs, rhs in
                guard let lhsDate = lhs.startTimeDate, let rhsDate = rhs.startTimeDate else {
                    return false
                }
                return lhsDate < rhsDate
            }) {
                if let lastReservationDate = maxReservation.startTimeDate,
                   let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastReservationDate) {
                    startDate = nextDay
                }
            }
        }

        // 2. Load resources once
        let names = loadStringsFromFile(fileName: "names").shuffled()
        let phoneNumbers = loadStringsFromFile(fileName: "phone_numbers").shuffled()
        let notes = loadStringsFromFile(fileName: "notes").shuffled()

        guard !names.isEmpty, !phoneNumbers.isEmpty else {
            AppLog.warning("Required resources are missing. Reservation generation aborted.")
            return
        }

        AppLog.info("Generating reservations for \(daysToSimulate) days with realistic variance (closed on Mondays).")

        // 3. Perform parallel reservation generation
        for dayOffset in 0..<daysToSimulate {
               await self.generateReservationsForDay(
                   dayOffset: dayOffset,
                   startDate: startDate,
                   names: names,
                   phoneNumbers: phoneNumbers,
                   notes: notes
               )
           }

        // 4. Save data to disk after all tasks complete
        self.resCache.preloadDates(around: startDate, range: daysToSimulate, reservations: store.reservations)
            self.layoutServices.saveToDisk()
        AppLog.info("Finished generating reservations.")
    }

    /// Generates reservations for a specific day
    ///
    /// This method creates realistic reservations for a single day,
    /// with appropriate time slots and party sizes.
    ///
    /// - Parameters:
    ///   - dayOffset: Number of days from the start date
    ///   - startDate: Base date to start from
    ///   - names: Array of names to use for reservations
    ///   - phoneNumbers: Array of phone numbers to use for reservations
    ///   - notes: Array of notes to use for reservations
    @MainActor
    private func generateReservationsForDay(
        dayOffset: Int,
        startDate: Date,
        names: [String],
        phoneNumbers: [String],
        notes: [String]
    ) async {
        let reservationDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate)!
        let dayOfWeek = Calendar.current.component(.weekday, from: reservationDate)

        // Skip Mondays
        if dayOfWeek == 2 {
            AppLog.info("Skipping Monday: \(reservationDate)")
            return
        }

        let maxDailyReservations = Int.random(in: 10...30)
        var totalGeneratedReservations = 0

        // Available time slots (Lunch and Dinner)
        var availableTimeSlots = Set(self.generateTimeSlots(for: reservationDate, range: (12, 14)))
        availableTimeSlots.formUnion(self.generateTimeSlots(for: reservationDate, range: (18, 22)))

        while totalGeneratedReservations < maxDailyReservations && !availableTimeSlots.isEmpty {
            guard let startTime = availableTimeSlots.min() else { break }
            availableTimeSlots.remove(startTime)

            let numberOfPersons = self.generateWeightedGroupSize()
            let durationMinutes: Int = {
                if numberOfPersons <= 2 { return Int.random(in: 90...105) }
                if numberOfPersons >= 10 { return Int.random(in: 120...150) }
                return 105
            }()

            let endTime = self.roundToNearestFiveMinutes(
                Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!
            )

            if let nextSlot = availableTimeSlots.min(), nextSlot < endTime.addingTimeInterval(600) {
                availableTimeSlots.remove(nextSlot)
            }

            let category: Reservation.ReservationCategory = Calendar.current.component(.hour, from: startTime) < 15 ? .lunch : .dinner
            let dateString = DateHelper.formatDate(reservationDate)
            let startTimeString = DateHelper.timeFormatter.string(from: startTime)

            let reservation = Reservation(
                id: UUID(),
                name: names.randomElement()!,
                phone: phoneNumbers.randomElement()!,
                numberOfPersons: numberOfPersons,
                dateString: dateString,
                category: category,
                startTime: startTimeString,
                endTime: DateHelper.timeFormatter.string(from: endTime),
                acceptance: .confirmed,
                status: .pending,
                reservationType: .inAdvance,
                group: Bool.random(),
                notes: notes.randomElement(),
                tables: [],
                creationDate: Date(),
                isMock: false
            )

            
            // Offload table assignment and reservation updates to the background thread


                await MainActor.run {
                let assignmentResult = self.layoutServices.assignTables(for: reservation, selectedTableID: nil)
                    switch assignmentResult {
                    case .success(let assignedTables):
                        var updatedReservation = reservation
                        updatedReservation.tables = assignedTables
                        
                    let key = self.layoutServices.keyFor(date: reservationDate, category: category)
                    
                    if self.layoutServices.cachedLayouts[key] == nil {
                        self.layoutServices.cachedLayouts[key] = self.tableStore.baseTables
                    }
                        guard let reservationStart = reservation.startTimeDate,
                              let reservationEnd = reservation.endTimeDate else { break }
                        
                        assignedTables.forEach { self.layoutServices.unlockTable(tableID: $0.id, start: reservationStart, end: reservationEnd) }
                        self.store.finalizeReservation(updatedReservation)

                        if !self.store.reservations.contains(where: { $0.id == updatedReservation.id }) {
                            self.resCache.addOrUpdateReservation(updatedReservation)
                            self.store.reservations.append(updatedReservation)
                            self.updateReservation(updatedReservation) {
                                AppLog.info("Generated reservation: \(updatedReservation.name)")
                            }
                        }
                    case .failure(let error):
                        // Show an alert message based on `error`.
                        switch error {
                        case .noTablesLeft:
                             print(String(localized: "Non ci sono tavoli disponibili."))
                        case .insufficientTables:
                            print(String(localized: "Non ci sono abbastanza tavoli per la prenotazione."))
                        case .tableNotFound:
                            print(String(localized: "Tavolo selezionato non trovato."))
                        case .tableLocked:
                            print(String(localized: "Il tavolo scelto è occupato o bloccato."))
                        case .unknown:
                            print(String(localized: "Errore sconosciuto."))
                        }
                        
                }
                    
                
            }
            
            totalGeneratedReservations += 1

        }
    }

    /// Generates time slots for a specific date and hour range
    ///
    /// - Parameters:
    ///   - date: The base date
    ///   - range: Tuple containing start and end hour (inclusive/exclusive)
    /// - Returns: Array of dates representing time slots at 5-minute intervals
    private func generateTimeSlots(for date: Date, range: (Int, Int)) -> [Date] {
        var slots: [Date] = []
        for hour in range.0..<range.1 {
            for minute in stride(from: 0, to: 60, by: 5) { // Step of 5 minutes
                if let slot = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    slots.append(slot)
                }
            }
        }
        return slots
    }
    
    /// Rounds a date to the nearest 5-minute interval
    ///
    /// - Parameter date: The date to round
    /// - Returns: The rounded date
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 5
        let adjustment = remainder < 3 ? -remainder : (5 - remainder)
        return calendar.date(byAdding: .minute, value: adjustment, to: date)!
    }

    /// Generates a realistic party size with weighted distribution
    ///
    /// This method returns party sizes with a distribution that
    /// matches real-world restaurant patterns.
    ///
    /// - Returns: A party size between 2 and 14
    private func generateWeightedGroupSize() -> Int {
        let random = Double.random(in: 0...1)
        switch random {
        case 0..<0.5: return Int.random(in: 2...3) // 50% chance for groups of 2-3
        case 0.5..<0.7: return Int.random(in: 4...5) // 20% chance for groups of 4-5
        case 0.7..<0.8: return Int.random(in: 6...7) // 10% chance for groups of 6-7
        case 0.8..<0.95: return Int.random(in: 8...9) // 15% chance for groups of 8-9
        case 0.95..<0.99: return Int.random(in: 9...12) // 4% chance for groups of 9-12
        default: return Int.random(in: 13...14) // 1% chance for groups of 13-14
        }
    }
    
    /// Loads strings from a text file in the app bundle
    ///
    /// - Parameters:
    ///   - fileName: Name of the file to load
    ///   - folder: Optional folder containing the file
    /// - Returns: Array of strings from the file
    func loadStringsFromFile(fileName: String, folder: String? = nil) -> [String] {
        let resourceName = folder != nil ? "\(String(describing: folder))/\(fileName)" : fileName
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "txt") else {
            Task { @MainActor in
                AppLog.warning("Failed to load \(fileName) from folder \(String(describing: folder)).")
            }
            return []
        }
        
        do {
            let content = try String(contentsOf: fileURL)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            Task { @MainActor in
                AppLog.debug("Loaded \(lines.count) lines from \(fileName) (folder: \(String(describing: folder))).")
            }
            return lines
        } catch {
            Task { @MainActor in
                AppLog.error("Error reading \(fileName): \(error)")
            }
            return []
        }
    }
    
    /// Simulates user actions for testing purposes
    ///
    /// This method simulates a series of table movements to test
    /// the system's ability to handle concurrent operations.
    ///
    /// - Parameter actionCount: Number of actions to simulate
    @MainActor
    func simulateUserActions(actionCount: Int = 1000) {
        Task {
            do {
                for _ in 0..<actionCount {
                    try await Task.sleep(nanoseconds: UInt64(10_000_000)) // Small delay to simulate real-world actions
                    
                    let randomTable = self.layoutServices.tables.randomElement()!
                    let newRow = Int.random(in: 0..<self.tableStore.totalRows)
                    let newColumn = Int.random(in: 0..<self.tableStore.totalColumns)
                    
                    let layoutServices = self.layoutServices // Capture layoutServices explicitly
                    Task {
                        let result = layoutServices.moveTable(randomTable, toRow: newRow, toCol: newColumn)
                        AppLog.debug("Simulated moving \(randomTable.name) to (\(newRow), \(newColumn)): \(String(describing: result))")
                    }
                }
            } catch {
                AppLog.error("Task.sleep encountered an error: \(error)")
            }
        }
    }
    
    /// Updates adjacency counts for tables in a reservation
    ///
    /// This method calculates and updates the adjacency counts for tables
    /// in a reservation, which is used for optimizing table layouts.
    ///
    /// - Parameter reservation: The reservation to update adjacency counts for
    func updateActiveReservationAdjacencyCounts(for reservation: Reservation) {
        guard let reservationDate = reservation.normalizedDate,
              let combinedDateTime = reservation.startTimeDate else {
            Task { @MainActor in
                AppLog.warning("Invalid reservation date or time for updating adjacency counts.")
            }
            return
        }

        // Get active tables for the reservation's layout
        let activeTables = layoutServices.getTables(for: reservationDate, category: reservation.category)

        // Iterate over all tables in the reservation
        for table in reservation.tables {
            let adjacentTables = layoutServices.isTableAdjacent(table, combinedDateTime: combinedDateTime, activeTables: activeTables)
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id}) {
                layoutServices.tables[index].adjacentCount = adjacentTables.adjacentCount
            }
            // Calculate adjacent tables with shared reservations
            let sharedTables = layoutServices.isAdjacentWithSameReservation(for: table, combinedDateTime: combinedDateTime, activeTables: activeTables)

            // Update `activeReservationAdjacentCount` for this table
            if let index = layoutServices.tables.firstIndex(where: { $0.id == table.id }) {
                layoutServices.tables[index].activeReservationAdjacentCount = sharedTables.count
            }

            // Update in the cached layout
            let key = layoutServices.keyFor(date: reservationDate, category: reservation.category)
            if let cachedIndex = layoutServices.cachedLayouts[key]?.firstIndex(where: { $0.id == table.id }) {
                layoutServices.cachedLayouts[key]?[cachedIndex].activeReservationAdjacentCount = sharedTables.count
            }
        }

        // Save changes to disk
        layoutServices.saveToDisk()
        Task { @MainActor in
            AppLog.info("Updated activeReservationAdjacentCount for tables in reservation \(reservation.id).")
        }
    }
    
}

extension ReservationService {
    /// Clears all caches in the store and resets layouts and clusters
    ///
    /// This method removes all cached data from memory and persists
    /// the changes to disk to ensure a clean state.
    @MainActor
    func flushAllCaches() {
        DispatchQueue.main.async {
            // Clear cached layouts
            self.layoutServices.cachedLayouts.removeAll()
            self.layoutServices.saveToDisk() // Persist changes

            // Clear cluster cache
            self.clusterStore.clusterCache.removeAll()
            self.clusterServices.saveClustersToDisk() // Persist changes

            // Clear active reservation cache
            self.store.activeReservationCache.removeAll()

            AppLog.info("All caches flushed successfully.")
        }
    }
}


// MARK: - Conflict Manager
extension ReservationService {

    
    // MARK: - Helper Method
    
    /// "Deletes" a reservation by marking it with "NA" values and clearing its tables and notes
    ///
    /// This method creates a soft-deleted version of a reservation by
    /// updating its status and adding notes.
    ///
    /// - Parameters:
    ///   - reservation: The reservation to mark as separated
    ///   - notesToAdd: Optional notes to add to the reservation
    /// - Returns: The updated reservation
    @MainActor
    func separateReservation(_ reservation: Reservation, notesToAdd: String = "") -> Reservation {
        var updatedReservation = reservation  // Create a mutable copy
        let finalNotes = notesToAdd == "" ? "" : "\(notesToAdd)\n\n"
        updatedReservation.status = .pending
        updatedReservation.notes = "\(finalNotes)[da controllare];"
        return updatedReservation
    }
    
    /// Marks a reservation as deleted
    ///
    /// This method performs a soft delete by changing the reservation's
    /// status and type, and clearing its tables.
    ///
    /// - Parameter reservation: The reservation to delete
    @MainActor
    func deleteReservation(_ reservation: Reservation) {
        var updatedReservation = reservation  // Create a mutable copy
        updatedReservation.reservationType = .na
        updatedReservation.status = .deleted
        updatedReservation.acceptance = .na
        updatedReservation.tables = []
        updatedReservation.notes = "[eliminata];"
        
        updateReservation(updatedReservation) {
            AppLog.info("Updated reservation")
        }
    }
    
    /// Ensures all confirmed reservations have tables assigned
    ///
    /// This method scans the database for confirmed reservations without
    /// tables and attempts to assign tables to them.
    @MainActor
    func ensureConfirmedReservationsHaveTables() {
        AppLog.info("Scanning database for confirmed reservations without tables...")
        
        var updatedCount = 0
        var failedCount = 0
        
        // Create a copy to avoid modifying while iterating
        let reservationsToCheck = store.reservations
        
        for reservation in reservationsToCheck {
            if reservation.acceptance == .confirmed && reservation.tables.isEmpty {
                AppLog.warning("⚠️ Found confirmed reservation in database with no tables: \(reservation.name) (ID: \(reservation.id))")
                
                // Try to assign tables automatically
                let assignmentResult = layoutServices.assignTables(for: reservation, selectedTableID: nil)
                switch assignmentResult {
                case .success(let assignedTables):
                    var updatedReservation = reservation
                    updatedReservation.tables = assignedTables
                    
                    // Update in SQLite
                    SQLiteManager.shared.updateReservation(updatedReservation)
                    
                    // Update in memory
                    if let index = store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                        store.reservations[index] = updatedReservation
                    }
                    
                    // Update in cache
                    resCache.addOrUpdateReservation(updatedReservation)
                    
                    AppLog.info("✅ Auto-assigned \(assignedTables.count) tables to stored reservation: \(updatedReservation.name)")
                    updatedCount += 1
                    
                case .failure(let error):
                    AppLog.error("❌ Failed to auto-assign tables to stored reservation: \(error.localizedDescription)")
                    failedCount += 1
                }
            }
        }
        
        AppLog.info("Database scan complete. Updated \(updatedCount) reservations, failed to update \(failedCount) reservations.")
    }
}

extension Date {
    /// Returns the start of the next minute for the current date.
    func startOfNextMinute() -> Date {
        let nextMinute = Calendar.current.date(byAdding: .minute, value: 1, to: self)!
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextMinute))!
    }
}

extension Date {
    /// Returns the start of the day for the current date
    func normalizedToDayStart() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
}

/// Ensures all confirmed reservations in the database have tables assigned

extension ReservationService {
    /// Detects and removes duplicate reservations, prioritizing those with tables assigned
    ///
    /// This method identifies reservations with the same ID, keeps the best one
    /// (prioritizing those with tables or the most recently edited), and removes the others.
    @MainActor
    func removeDuplicateReservations() {
        AppLog.info("Checking for duplicate reservations...")
        
        // Group reservations by ID
        let groupedReservations = Dictionary(grouping: store.reservations) { $0.id }
        var reservationsToKeep: [UUID: Reservation] = [:]
        var reservationsToRemove: [Reservation] = []
        var duplicatesFound = 0
        
        // Process each group of reservations with the same ID
        for (id, duplicates) in groupedReservations where duplicates.count > 1 {
            duplicatesFound += duplicates.count - 1
            AppLog.warning("Found \(duplicates.count) duplicates for reservation ID: \(id)")
            
            // First, try to find a reservation with tables
            let reservationsWithTables = duplicates.filter { !$0.tables.isEmpty }
            
            if let bestReservation = reservationsWithTables.first {
                // Keep the reservation with tables
                reservationsToKeep[id] = bestReservation
                AppLog.debug("Keeping reservation with \(bestReservation.tables.count) tables for ID: \(id)")
                
                // Mark others for removal
                let othersToRemove = duplicates.filter { $0.id == id && $0 != bestReservation }
                reservationsToRemove.append(contentsOf: othersToRemove)
            } else {
                // If none have tables, keep the most recently edited one
                let mostRecent = duplicates.max(by: { $0.lastEditedOn < $1.lastEditedOn })!
                reservationsToKeep[id] = mostRecent
                AppLog.debug("No reservations with tables found for ID: \(id). Keeping most recent.")
                
                // Mark others for removal
                let othersToRemove = duplicates.filter { $0.id == id && $0 != mostRecent }
                reservationsToRemove.append(contentsOf: othersToRemove)
            }
        }
        
        // Add non-duplicate reservations to the keep list
        for (id, reservations) in groupedReservations where reservations.count == 1 {
            reservationsToKeep[id] = reservations.first!
        }
        
        // Remove duplicates from SQLite
        for reservation in reservationsToRemove {
            SQLiteManager.shared.deleteReservation(withID: reservation.id)
            AppLog.debug("Removed duplicate reservation from SQLite: \(reservation.id)")
        }
        
        // Update the store with deduplicated reservations
        store.reservations = Array(reservationsToKeep.values)
        
        // Update the cache
        for reservation in store.reservations {
            resCache.addOrUpdateReservation(reservation)
        }
        
        AppLog.info("Duplicate removal complete. Removed \(duplicatesFound) duplicate reservations. Kept \(reservationsToKeep.count) unique reservations.")
    }
    
    /// Cleans up duplicate devices in a profile
    ///
    /// This method removes duplicate devices with the same name but different IDs from a profile.
    /// It's useful for preventing the accumulation of duplicate devices when logging in from different devices.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the profile to clean up
    ///   - currentDeviceID: The ID of the current device (which should be kept)
    @MainActor
    func cleanupDuplicateDevices(profileID: String, currentDeviceID: String) {
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            var deviceNameChanged = false
            var newDeviceName = ""
            
            // Get device name safely before using it
            let safeDeviceName = DeviceInfo.shared.getDeviceName()
            
            // First, ensure the current device is properly updated
            if let currentDeviceIndex = updatedProfile.devices.firstIndex(where: { $0.id == currentDeviceID }) {
                // Update the existing device
                updatedProfile.devices[currentDeviceIndex].lastActive = Date()
                updatedProfile.devices[currentDeviceIndex].isActive = true
                
                // Check if we need to update the device name
                if updatedProfile.devices[currentDeviceIndex].name == "Unknown Device" {
                    updatedProfile.devices[currentDeviceIndex].name = safeDeviceName
                    deviceNameChanged = true
                    newDeviceName = safeDeviceName
                }
            } else {
                // If current device isn't in the profile, add it
                let newDevice = Device(
                    id: currentDeviceID,
                    name: safeDeviceName,
                    lastActive: Date(),
                    isActive: true
                )
                updatedProfile.devices.append(newDevice)
                deviceNameChanged = true
                newDeviceName = safeDeviceName
                AppLog.info("Added current device \(currentDeviceID) to profile \(profileID)")
            }
            
            // Group devices by name
            let devicesByName = Dictionary(grouping: updatedProfile.devices) { $0.name }
            
            // For each group of devices with the same name
            for (name, devices) in devicesByName {
                // If there are multiple devices with the same name
                if devices.count > 1 {
                    AppLog.info("Found \(devices.count) devices with name '\(name)' in profile \(profileID)")
                    
                    // For other devices with the same name, keep only the most recently active one
                    let otherDevices = devices.filter { $0.id != currentDeviceID }
                    
                    if !otherDevices.isEmpty {
                        // Sort by last active date and keep the most recent one
                        let sortedOtherDevices = otherDevices.sorted(by: { $0.lastActive > $1.lastActive })
                        let deviceToKeep = sortedOtherDevices.first!
                        
                        // Remove all other devices with this name except the current device and the most recent one
                        updatedProfile.devices.removeAll { device in
                            device.name == name && 
                            device.id != currentDeviceID && 
                            device.id != deviceToKeep.id
                        }
                        
                        AppLog.info("Kept current device \(currentDeviceID) and most recent device \(deviceToKeep.id) with name '\(name)'")
                    }
                }
            }
            
            // If we made changes to the profile
            if updatedProfile.devices.count != profile.devices.count || deviceNameChanged {
                updatedProfile.updatedAt = Date()
                
                // Update the profile
                upsertProfile(updatedProfile)
                
                // Update the current profile if needed
                if ProfileStore.shared.currentProfile?.id == profileID {
                    ProfileStore.shared.setCurrentProfile(updatedProfile)
                }
                
                // Update the session if the device name changed
                if deviceNameChanged {
                    if let session = SessionStore.shared.sessions.first(where: { $0.id == profileID && $0.uuid == currentDeviceID }) {
                        var updatedSession = session
                        updatedSession.deviceName = newDeviceName
                        
                        // Update session in SQLite
                        SQLiteManager.shared.insertSession(updatedSession)
                        
                        // Update session in memory
                        if let index = SessionStore.shared.sessions.firstIndex(where: { $0.id == profileID && $0.uuid == currentDeviceID }) {
                            SessionStore.shared.sessions[index] = updatedSession
                        }
                        
                        // Update session in Firebase
                        #if DEBUG
                        let dbRef = backupService.db?.collection("sessions")
                        #else
                        let dbRef = backupService.db?.collection("sessions_release")
                        #endif
                        
                        let data = convertSessionToDictionary(session: updatedSession)
                        
                        // Use Task to handle the async operation
                        Task {
                            do {
                                if let dbRef = dbRef {
                                    try await dbRef.document(updatedSession.uuid).setData(data)
                                    AppLog.debug("Session updated in Firebase with new device name")
                                }
                            } catch {
                                AppLog.error("Error updating session in Firebase: \(error)")
                            }
                        }
                    }
                }
                
                AppLog.info("Cleaned up duplicate devices in profile \(profileID). Removed \(profile.devices.count - updatedProfile.devices.count) devices.")
            }
        }
    }
    
    /// Completely resets a profile's devices, keeping only the current device
    ///
    /// This method removes all devices from a profile except for the current device.
    /// It's useful for fixing profiles that have accumulated many duplicate devices.
    ///
    /// - Parameters:
    ///   - profileID: The ID of the profile to reset
    ///   - currentDeviceID: The ID of the current device (which should be kept)
    ///   - deviceName: The name to use for the current device
    @MainActor
    func resetProfileDevices(profileID: String, currentDeviceID: String, deviceName: String) {
        if let profile = ProfileStore.shared.getProfile(withID: profileID) {
            var updatedProfile = profile
            
            // Check if the current device is already in the profile
            let currentDevice: Device
            if profile.devices.first(where: { $0.id == currentDeviceID }) != nil {
                // Update the existing device
                currentDevice = Device(
                    id: currentDeviceID,
                    name: deviceName,
                    lastActive: Date(),
                    isActive: true
                )
            } else {
                // Create a new device
                currentDevice = Device(
                    id: currentDeviceID,
                    name: deviceName,
                    lastActive: Date(),
                    isActive: true
                )
            }
            
            // Reset the devices array to contain only the current device
            updatedProfile.devices = [currentDevice]
            updatedProfile.updatedAt = Date()
            
            // Log what we're doing
            AppLog.warning("Completely reset devices for profile \(profileID). Removed \(profile.devices.count - 1) devices.")
            
            // Update the profile
            upsertProfile(updatedProfile)
            
            // Update the current profile if needed
            if ProfileStore.shared.currentProfile?.id == profileID {
                ProfileStore.shared.setCurrentProfile(updatedProfile)
            }
            
            // Also explicitly update the device status in SQLite
            SQLiteManager.shared.updateDeviceStatus(deviceId: currentDeviceID, isActive: true)
        }
    }
}

