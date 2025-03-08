//
//  FirebaseListener.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/2/25.
//

import Foundation
import OSLog
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import UIKit

/// A class that manages Firebase listeners for real-time updates
///
/// This class is responsible for setting up and managing Firebase listeners for reservations, sessions, and profiles.
/// It listens for changes to these collections and updates the local database accordingly.
class FirebaseListener {
    // MARK: - Properties
    
    /// The Firestore database reference
    let db: Firestore?
    
    /// Logger for tracking listener operations
    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseListener")
    
    /// Firebase listener for reservation changes
    private var reservationListener: ListenerRegistration?
    
    /// Firebase listener for session changes
    private var sessionListener: ListenerRegistration?
    
    /// Firebase listener for profile changes
    private var profileListener: ListenerRegistration?
    
    /// Whether this listener is in preview mode
    private var isPreview: Bool {
        db == nil
    }
    
    /// The reservation store to update
    let store: ReservationStore
    
    // MARK: - Initializer
    
    /// Initializes a new FirebaseListener with a store
    ///
    /// - Parameter store: The reservation store to update
    init(store: ReservationStore) {
        // Use the safe Firebase initialization method
        self.db = AppDependencies.getFirestore()
        self.store = store
        logger.debug("FirebaseListener initialized (preview mode: \(self.isPreview))")
    }
    
    // MARK: - Reservations Listener
    
    /// Starts a listener for reservation changes
    ///
    /// In preview mode, this is a no-op
    func startReservationListener() {
        guard !isPreview, let db = db else {
            logger.debug("Preview mode: Skipping reservation listener")
            return
        }
        
        logger.info("Starting reservation listener")
        
        // Get the appropriate collection based on build configuration
        #if DEBUG
        let collectionPath = "reservations"
        #else
        let collectionPath = "reservations_release"
        #endif
        
        // Create a listener for the reservations collection
        let reservationsRef = db.collection(collectionPath)
        
        // Remove any existing listener
        if let reservationListener = reservationListener {
            reservationListener.remove()
            self.reservationListener = nil
        }
        
        // Start a new listener
        reservationListener = reservationsRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error listening for reservation changes: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                self.logger.error("Invalid snapshot received")
                return
            }
            
            // Process document changes
            for change in snapshot.documentChanges {
                let data = change.document.data()
                
                // Extract reservation data
                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    self.logger.error("Reservation document missing ID")
                    continue
                }
                
                // Process based on change type
                switch change.type {
                case .added, .modified:
                    // Properly capture the id value to avoid data races
                    let capturedId = id
                    let capturedData = data
                    // Dispatch to avoid blocking the listener
                        self.handleReservationUpdate(id: capturedId, data: capturedData)
                case .removed:
                    self.logger.info("Reservation removed: \(id)")
                    // We don't typically remove reservations, but we could handle it if needed
                }
            }
        }
    }
    
    /// Handles a reservation update from Firebase
    ///
    /// This method processes a reservation update from Firebase and updates the local database.
    ///
    /// - Parameters:
    ///   - id: The ID of the reservation
    ///   - data: The reservation data from Firebase
    private func handleReservationUpdate(id: UUID, data: [String: Any]) {
        // This method would convert the data to a Reservation object and update the local database
        // For now, we'll just log the update
        logger.info("Reservation update received for ID: \(id)")
    }
    
    /// Stops the reservation listener
    func stopReservationListener() {
        guard !isPreview else {
            return
        }
        
        if let reservationListener = reservationListener {
            reservationListener.remove()
            self.reservationListener = nil
            logger.info("Stopped reservation listener")
        }
    }
    
    // MARK: - Sessions Listener
    
    /// Starts a listener for session changes
    ///
    /// In preview mode, this is a no-op
    func startSessionListener() {
        guard !isPreview, let db = db else {
            logger.debug("Preview mode: Skipping session listener")
            return
        }
        
        logger.info("Starting session listener")
        
        // Get the appropriate collection based on build configuration
        #if DEBUG
        let collectionPath = "sessions"
        #else
        let collectionPath = "sessions_release"
        #endif
        
        // Create a listener for the sessions collection
        let sessionsRef = db.collection(collectionPath)
        
        // Remove any existing listener
        if let sessionListener = sessionListener {
            sessionListener.remove()
            self.sessionListener = nil
        }
        
        // Start a new listener
        sessionListener = sessionsRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error listening for session changes: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                self.logger.error("Invalid snapshot received")
                return
            }
            
            // Process document changes
            for change in snapshot.documentChanges {
                let data = change.document.data()
                
                // Extract session data
                guard let id = data["id"] as? String else {
                    self.logger.error("Session document missing ID")
                    continue
                }
                
                // Process based on change type
                switch change.type {
                case .added, .modified:
                    // Properly capture the id value to avoid data races
                    let capturedId = id
                    let capturedData = data
                    // Properly dispatch to the main actor
                    Task { @MainActor in
                        await ReservationMapper.handleSessionUpdate(id: capturedId, data: capturedData)
                    }
                case .removed:
                    self.logger.info("Session removed: \(id)")
                    // We don't typically remove sessions, but we could handle it if needed
                }
            }
        }
    }
    
    
    
    
    
    /// Stops the session listener
    func stopSessionListener() {
        guard !isPreview else {
            return
        }
        
        if let sessionListener = sessionListener {
            sessionListener.remove()
            self.sessionListener = nil
            logger.info("Stopped session listener")
        }
    }
    
    // MARK: - Profile Listener
    
    /// Starts a listener for profile changes
    ///
    /// This method creates a listener for the profiles collection in Firebase.
    /// It listens for changes to the profiles and updates the local database accordingly.
    func startProfileListener() {
        logger.info("Starting profile listener")
        
        // Get the appropriate collection based on build configuration
        #if DEBUG
        let collectionPath = "profiles"
        #else
        let collectionPath = "profiles_release"
        #endif
        
        // Create a listener for the profiles collection
        let profilesRef = db?.collection(collectionPath)
        
        // Remove any existing listener
        if let profileListener = profileListener {
            profileListener.remove()
            self.profileListener = nil
        }
        
        // Start a new listener
        profileListener = profilesRef?.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error listening for profile changes: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                self.logger.error("Invalid snapshot received")
                return
            }
            
            // Process document changes
            for change in snapshot.documentChanges {
                let data = change.document.data()
                
                // Extract profile data
                guard let id = data["id"] as? String else {
                    self.logger.error("Profile document missing ID")
                    continue
                }
                
                // Process based on change type
                switch change.type {
                case .added, .modified:
                    // Properly capture the id value to avoid data races
                    let capturedId = id
                    let capturedData = data
                    // Properly dispatch to the main actor
                    Task { @MainActor in
                        await ReservationMapper.handleProfileUpdate(id: capturedId, data: capturedData)
                    }
                case .removed:
                    self.logger.info("Profile removed: \(id)")
                    // We don't typically remove profiles, but we could handle it if needed
                }
            }
        }
    }
    
   
    
    // MARK: - Realtime Database Presence
    
    /// Sets up a listener for realtime database presence detection
    ///
    /// This method creates a listener for the connection state of the Realtime Database.
    /// When the connection is established, it marks the session as active and sets up handlers
    /// to mark the session inactive when the connection is lost.
    ///
    /// - Parameter deviceUUID: The UUID of the device to track
    func setupRealtimeDatabasePresence(for deviceUUID: String) {
        // Get a reference to the Realtime Database
        let databaseRef = Database.database().reference()
        
        // Create a reference for the client's connection state using the .info/connected node
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        
        // Observe the connection state
        connectedRef.observe(.value) { snapshot in
            guard let connected = snapshot.value as? Bool, connected else {
                // Not connected, so no updates are made here.
                return
            }
            
            // Define a reference to the session node for this device
            #if DEBUG
            let sessionRef = databaseRef.child("sessions").child(deviceUUID)
            #else
            let sessionRef = databaseRef.child("sessions_release").child(deviceUUID)
            #endif
            
            // Mark the session as active when connected
            sessionRef.child("isActive").setValue(true)
            
            // Set up onDisconnect handlers to mark the session inactive and update the last active timestamp
            sessionRef.child("isActive").onDisconnectSetValue(false)
            sessionRef.child("lastActive").setValue(ServerValue.timestamp())
            sessionRef.child("lastActive").onDisconnectSetValue(ServerValue.timestamp())
        }
    }
    
    // MARK: - Cleanup
    
    /// Stops all active listeners
    func stopAllListeners() {
        stopReservationListener()
        stopSessionListener()
    }
}
