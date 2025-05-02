# KoenjiApp Component Implementation Plan

## Overview

This document outlines the implementation plan for KoenjiApp components following the three-layer data architecture:

1. **FirestoreDataStore**: Low-level persistence layer
2. **Cache Layer**: In-memory storage with persistence coordination
3. **Service Layer**: Business logic and coordination

## Implementation Plans by Component

### 1. Layouts

**Current State**:
- **FirestoreDataStore Layer**: Implemented with `LayoutData` model
- **Cache Layer**: `LayoutCache` with proper concurrency handling
- **Service Layer**: `LayoutServices` with business logic

**Implementation Design**:

1. **FirestoreDataStore Layer**:
   ```swift
   // LayoutData model that's Codable for Firebase storage
   struct LayoutData: Identifiable, Codable, Sendable, EncodableWithID {
       let id: String  // Key format: "YYYY-MM-DD-category"
       let tables: [TableModel]
       
       // Required by EncodableWithID protocol for Firestore
       var documentID: String {
           return id
       }
   }
   ```

2. **Cache Layer**:
   ```swift
   class LayoutCache: ObservableObject {
       // Published property for UI updates
       @Published var cachedLayouts: [String: [TableModel]] = [:]
       
       // Separate Firebase operations from memory cache operations
       private func updateLayoutInFirebase(_ layout: LayoutData) {
           Task {
               do {
                   let layoutStore = FirestoreDataStore<LayoutData>(collectionName: "layouts")
                   try await layoutStore.upsert(layout)
                   
                   await MainActor.run {
                       AppLog.info("Updated layout \(layout.id) in Firebase")
                   }
               } catch {
                   await MainActor.run {
                       AppLog.error("Failed to update layout in Firebase: \(error.localizedDescription)")
                   }
               }
           }
       }
       
       // Add or update layout with proper concurrency handling
       func addOrUpdateLayout(for date: Date, category: Reservation.ReservationCategory, 
                             tables: [TableModel], updateFirebase: Bool = true) {
           let key = keyFor(date: date, category: category)
           
           // Update local cache
           cachedLayouts[key] = tables
           
           Task { @MainActor in
               AppLog.debug("Cache updated for layout: \(key)")
           }
           
           // Update Firebase if requested
           if updateFirebase {
               updateLayoutInFirebase(LayoutData(id: key, tables: tables))
           }
       }
       
       // Load layouts from Firebase
       func loadLayouts() async {
           do {
               let layoutStore = FirestoreDataStore<LayoutData>(collectionName: "layouts")
               let layouts = try await layoutStore.getAll()
               
               await MainActor.run {
                   for layout in layouts {
                       self.cachedLayouts[layout.id] = layout.tables
                   }
                   AppLog.info("Loaded \(layouts.count) layouts from Firebase")
               }
           } catch {
               await MainActor.run {
                   AppLog.error("Failed to load layouts: \(error)")
               }
           }
       }
       
       // Other methods with similar patterns...
   }
   ```

3. **Service Layer**:
   ```swift
   class LayoutServices: ObservableObject {
       // Dependencies
       private let layoutCache: LayoutCache
       private let tableStore: TableStore
       // Other dependencies...
       
       // Published properties for UI reactivity
       @Published var tables: [TableModel] = []
       
       // Computed property to access cached layouts
       var cachedLayouts: [String: [TableModel]] {
           return layoutCache.cachedLayouts
       }
       
       // Initialization with dependency injection
       init(resCache: CurrentReservationsCache, 
            tableStore: TableStore, 
            tableAssignmentService: TableAssignmentService,
            layoutCache: LayoutCache = LayoutCache()) {
           self.resCache = resCache
           self.tableStore = tableStore
           self.tableAssignmentService = tableAssignmentService
           self.layoutCache = layoutCache
           
           // Load layouts from disk
           loadFromDisk()
       }
       
       // Business logic for loading tables
       func loadTables(for date: Date, category: Reservation.ReservationCategory) -> [TableModel] {
           let fullKey = keyFor(date: date, category: category)
           
           // Logic that uses the cache layer...
           if let tables = layoutCache.cachedLayouts[fullKey] {
               self.tables = tables
               return tables
           }
           
           // Fallback logic...
       }
       
       // Other business logic methods that delegate persistence to the cache layer
   }
   ```

### 2. Tables

**Current State**:
- **FirestoreDataStore Layer**: Partial implementation for tables
- **Cache Layer**: `TableStore` with base tables
- **Service Layer**: `TableService` for operations

**Implementation Plan**:

1. **FirestoreDataStore Layer**:
   ```swift
   // TableModel is already Codable - using existing class
   // Use the generic FirestoreDataStore
   let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")
   ```

2. **Cache Layer**:
   ```swift
   class TableStore: ObservableObject {
       @Published var tables: [TableModel] = []
       @Published var baseTables: [TableModel] = [/* initial tables */]
       
       private let tableFirestore = FirestoreDataStore<TableModel>(collectionName: "tables")
       
       func addOrUpdateTable(_ table: TableModel, updateFirebase: Bool = true) {
           // Update local cache
           if let index = tables.firstIndex(where: { $0.id == table.id }) {
               tables[index] = table
           } else {
               tables.append(table)
           }
           
           // Update Firebase if requested
           if updateFirebase {
               Task {
                   do {
                       try await tableFirestore.upsert(table)
                       AppLog.info("Table \(table.id) updated in Firebase")
                   } catch {
                       AppLog.error("Firebase table update failed: \(error)")
                   }
               }
           }
       }
       
       func loadTablesFromFirebase() async {
           do {
               let loadedTables = try await tableFirestore.getAll()
               await MainActor.run {
                   self.tables = loadedTables
                   if loadedTables.isEmpty {
                       self.tables = self.baseTables
                   }
               }
               AppLog.info("Loaded \(loadedTables.count) tables from Firebase")
           } catch {
               AppLog.error("Failed to load tables: \(error)")
           }
       }
   }
   ```

3. **Service Layer**:
   ```swift
   class TableService {
       private let tableStore: TableStore
       
       init(tableStore: TableStore) {
           self.tableStore = tableStore
       }
       
       // Business logic for table operations
       func createNewTable(name: String, capacity: Int, position: (row: Int, column: Int)) {
           let nextID = (tableStore.tables.map { $0.id }.max() ?? 0) + 1
           let newTable = TableModel(
               id: nextID,
               name: name,
               maxCapacity: capacity, 
               row: position.row,
               column: position.column
           )
           tableStore.addOrUpdateTable(newTable)
       }
   }
   ```

### 3. Clusters

**Current State**:
- **FirestoreDataStore Layer**: Not explicitly implemented for clusters
- **Cache Layer**: `ClusterStore` with cluster caching
- **Service Layer**: `ClusterServices` with business logic

**Implementation Plan**:

1. **FirestoreDataStore Layer**:
   ```swift
   // Ensure CachedCluster is Codable
   struct ClusterData: Identifiable, Codable {
       let id: String  // Format: "date-category-clusterId"
       let cluster: CachedCluster
   }
   
   // Use the generic FirestoreDataStore
   let clusterFirestore = FirestoreDataStore<ClusterData>(collectionName: "clusters")
   ```

2. **Cache Layer**:
   ```swift
   class ClusterStore: ObservableObject {
       @Published var clusterCache: [String: [CachedCluster]] = [:]
       private let clusterFirestore = FirestoreDataStore<ClusterData>(collectionName: "clusters")
       
       func addOrUpdateCluster(for date: Date, category: Reservation.ReservationCategory,
                              cluster: CachedCluster, updateFirebase: Bool = true) {
           let key = keyFor(date: date, category: category)
           
           // Update local cache
           if var clusters = clusterCache[key] {
               if let index = clusters.firstIndex(where: { $0.id == cluster.id }) {
                   clusters[index] = cluster
               } else {
                   clusters.append(cluster)
               }
               clusterCache[key] = clusters
           } else {
               clusterCache[key] = [cluster]
           }
           
           // Update Firebase if requested
           if updateFirebase {
               Task {
                   do {
                       let clusterData = ClusterData(id: "\(key)-\(cluster.id)", cluster: cluster)
                       try await clusterFirestore.upsert(clusterData)
                       AppLog.info("Cluster \(cluster.id) updated in Firebase")
                   } catch {
                       AppLog.error("Firebase cluster update failed: \(error)")
                   }
               }
           }
       }
       
       func loadClustersFromFirebase() async {
           do {
               let clusters = try await clusterFirestore.getAll()
               var groupedClusters: [String: [CachedCluster]] = [:]
               
               for clusterData in clusters {
                   let components = clusterData.id.split(separator: "-")
                   guard components.count >= 3 else { continue }
                   
                   let keyParts = components.dropLast()
                   let key = keyParts.joined(separator: "-")
                   
                   if groupedClusters[key] == nil {
                       groupedClusters[key] = []
                   }
                   groupedClusters[key]?.append(clusterData.cluster)
               }
               
               await MainActor.run {
                   self.clusterCache = groupedClusters
               }
               AppLog.info("Loaded clusters for \(groupedClusters.count) date/categories from Firebase")
           } catch {
               AppLog.error("Failed to load clusters: \(error)")
           }
       }
       
       func keyFor(date: Date, category: Reservation.ReservationCategory) -> String {
           let formattedDate = DateHelper.formatDate(date)
           return "\(formattedDate)-\(category.rawValue)"
       }
   }
   ```

3. **Service Layer**:
   ```swift
   class ClusterServices {
       private let clusterStore: ClusterStore
       
       init(clusterStore: ClusterStore) {
           self.clusterStore = clusterStore
       }
       
       // Business logic for cluster operations
       func createClusterFromTables(for date: Date, category: Reservation.ReservationCategory, 
                                   tables: [TableModel], name: String) {
           let cluster = CachedCluster(
               id: UUID().uuidString,
               name: name,
               tables: tables,
               capacity: tables.reduce(0) { $0 + $1.maxCapacity }
           )
           
           clusterStore.addOrUpdateCluster(for: date, category: category, cluster: cluster)
       }
   }
   ```

### 4. Profiles

**Current State**:
- **FirestoreDataStore Layer**: Already using `FirestoreDataStore<Profile>`
- **Cache Layer**: `ProfileStore` manages profiles
- **Service Layer**: `ProfileService` containing business logic

**Implementation Plan**:

1. **FirestoreDataStore Layer**: 
   ```swift
   // Profile model is already Codable
   // Using existing FirestoreDataStore with Profile
   let profileStore = FirestoreDataStore<Profile>(collectionName: "profiles")
   ```

2. **Cache Layer**:
   ```swift
   class ProfileStore: ObservableObject {
       @Published var profiles: [Profile] = []
       @Published var currentProfile: Profile?
       
       private let profileFirestore = FirestoreDataStore<Profile>(collectionName: "profiles")
       
       func addOrUpdateProfile(_ profile: Profile, updateFirebase: Bool = true) {
           // Update local cache
           if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
               profiles[index] = profile
           } else {
               profiles.append(profile)
           }
           
           // Update current profile if needed
           if currentProfile?.id == profile.id {
               currentProfile = profile
           }
           
           // Update Firebase if requested
           if updateFirebase {
               Task {
                   do {
                       try await profileFirestore.upsert(profile)
                       AppLog.info("Profile \(profile.id) updated in Firebase")
                   } catch {
                       AppLog.error("Firebase profile update failed: \(error)")
                   }
               }
           }
       }
       
       func loadProfiles() async {
           do {
               let loadedProfiles = try await profileFirestore.getAll()
               await MainActor.run {
                   self.profiles = loadedProfiles
               }
               AppLog.info("Loaded \(loadedProfiles.count) profiles from Firebase")
           } catch {
               AppLog.error("Failed to load profiles: \(error)")
           }
       }
   }
   ```

3. **Service Layer**:
   ```swift
   class ProfileService {
       private let profileStore: ProfileStore
       
       init(profileStore: ProfileStore) {
           self.profileStore = profileStore
       }
       
       // Business logic for profile operations
       func createProfile(firstName: String, lastName: String, email: String) {
           let newProfile = Profile(
               id: UUID().uuidString,
               firstName: firstName,
               lastName: lastName,
               email: email,
               createdAt: Date(),
               updatedAt: Date()
           )
           
           profileStore.addOrUpdateProfile(newProfile)
       }
   }
   ```

### 5. Sessions

**Current State**:
- **FirestoreDataStore Layer**: Partial implementation
- **Cache Layer**: `SessionStore` mentioned but implementation unclear
- **Service Layer**: `SessionService` with business logic

**Implementation Plan**:

1. **FirestoreDataStore Layer**:
   ```swift
   // Session model is already Codable
   // Use the generic FirestoreDataStore
   let sessionFirestore = FirestoreDataStore<Session>(collectionName: "sessions")
   ```

2. **Cache Layer**:
   ```swift
   class SessionStore: ObservableObject {
       @Published var sessions: [Session] = []
       
       private let sessionFirestore = FirestoreDataStore<Session>(collectionName: "sessions")
       
       func addOrUpdateSession(_ session: Session, updateFirebase: Bool = true) {
           // Update local cache
           if let index = sessions.firstIndex(where: { $0.id == session.id }) {
               sessions[index] = session
           } else {
               sessions.append(session)
           }
           
           // Update Firebase if requested
           if updateFirebase {
               Task {
                   do {
                       try await sessionFirestore.upsert(session)
                       AppLog.info("Session \(session.id) updated in Firebase")
                   } catch {
                       AppLog.error("Firebase session update failed: \(error)")
                   }
               }
           }
       }
       
       func loadSessions() async {
           do {
               let loadedSessions = try await sessionFirestore.getAll()
               await MainActor.run {
                   self.sessions = loadedSessions
               }
               AppLog.info("Loaded \(loadedSessions.count) sessions from Firebase")
           } catch {
               AppLog.error("Failed to load sessions: \(error)")
           }
       }
       
       func removeSession(_ sessionID: String, updateFirebase: Bool = true) {
           // Remove from local cache
           sessions.removeAll(where: { $0.id == sessionID })
           
           // Remove from Firebase if requested
           if updateFirebase {
               Task {
                   do {
                       try await sessionFirestore.delete(id: sessionID)
                       AppLog.info("Session \(sessionID) removed from Firebase")
                   } catch {
                       AppLog.error("Firebase session deletion failed: \(error)")
                   }
               }
           }
       }
   }
   ```

3. **Service Layer**:
   ```swift
   class SessionService {
       private let sessionStore: SessionStore
       private let profileStore: ProfileStore
       
       init(sessionStore: SessionStore, profileStore: ProfileStore) {
           self.sessionStore = sessionStore
           self.profileStore = profileStore
       }
       
       // Business logic for session operations
       func createSession(for profile: Profile, deviceID: String, deviceName: String) {
           let newSession = Session(
               id: profile.id,
               uuid: deviceID,
               userName: "\(profile.firstName) \(profile.lastName)",
               isEditing: false,
               lastUpdate: Date(),
               isActive: true,
               deviceName: deviceName,
               profileImageURL: profile.imageURL
           )
           
           sessionStore.addOrUpdateSession(newSession)
       }
       
       func markSessionInactive(sessionID: String) {
           if var session = sessionStore.sessions.first(where: { $0.id == sessionID }) {
               session.isActive = false
               session.lastUpdate = Date()
               sessionStore.addOrUpdateSession(session)
           }
       }
   }
   ```

## Implementation Guidelines

When implementing these components, follow these guidelines:

1. **Consistent Method Naming**:
   - `addOrUpdateX()`: For adding or updating items in the cache
   - `loadXFromFirebase()`: For loading data from Firebase
   - `removeX()`: For removing items

2. **Error Handling**:
   - Use `Task { @MainActor in ... }` for UI updates
   - Use `AppLog` for consistent logging
   - Implement proper error handling with meaningful messages

3. **Thread Safety**:
   - Use `@MainActor` annotations where appropriate
   - Consider using actors for thread-safe caches

4. **Firebase Operations**:
   - Always go through the cache for Firebase operations
   - Make Firebase updates optional with a flag

5. **Model Consistency**:
   - Ensure all models conform to `Identifiable` and `Codable`
   - Use consistent ID generation strategies

By following these implementation plans, all components will align with the three-layer architecture pattern, ensuring clean separation of concerns and maintainable code. 