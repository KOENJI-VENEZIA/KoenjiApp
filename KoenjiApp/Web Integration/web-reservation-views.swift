//
//  WebReservationViews.swift
//  KoenjiApp
//
//  Created on 3/3/25.
//

import SwiftUI
import OSLog
import FirebaseFunctions

struct WebReservationsTab: View {
    @EnvironmentObject var env: AppDependencies
    @State private var searchText = ""
    @State private var selectedReservation: Reservation?
    @State private var refreshID = UUID()
    
    private let logger = Logger(subsystem: "com.koenjiapp", category: "WebReservationsTab")
    
    // Filter web reservations
    private var webReservations: [Reservation] {
        let allReservations = env.store.reservations.filter { 
            $0.isWebReservation && $0.acceptance == .toConfirm
        }
        
        if searchText.isEmpty {
            return allReservations
        } else {
            return allReservations.filter { reservation in
                reservation.name.localizedCaseInsensitiveContains(searchText) ||
                reservation.phone.localizedCaseInsensitiveContains(searchText) ||
                (reservation.emailAddress?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if webReservations.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Web Reservations")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name, phone, or email")
            .refreshable {
                refreshID = UUID()
            }
            .sheet(item: $selectedReservation) { reservation in
                WebReservationApprovalView(reservation: reservation) {
                    // Callback when reservation is approved
                    refreshID = UUID()
                }
                .environmentObject(env)
            }
            .onReceive(NotificationManager.shared.$selectedReservationID) { id in
                if let id = id, 
                   let reservation = env.store.reservations.first(where: { $0.id == id && $0.isWebReservation }) {
                    selectedReservation = reservation
                }
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe.desk")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("No Web Reservations")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Online reservation requests will appear here for approval.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // Reservation list view
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(webReservations) { reservation in
                    WebReservationCard(reservation: reservation)
                        .onTapGesture {
                            selectedReservation = reservation
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .id(refreshID) // Force refresh when needed
        }
    }
}

struct WebReservationCard: View {
    @Environment(\.colorScheme) var colorScheme
    let reservation: Reservation
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left indicator bar
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.orange)
                .frame(width: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Header with name and status
                HStack {
                    Text(reservation.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("Pending")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
                
                // Details grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    // Date
                    detailItem(
                        icon: "calendar",
                        title: "Date",
                        value: DateHelper.formatFullDate(reservation.normalizedDate ?? Date())
                    )
                    
                    // Time
                    detailItem(
                        icon: "clock.fill",
                        title: "Time",
                        value: "\(reservation.startTime)"
                    )
                    
                    // Party size
                    detailItem(
                        icon: "person.2.fill",
                        title: "Guests",
                        value: "\(reservation.numberOfPersons)"
                    )
                    
                    // Phone
                    detailItem(
                        icon: "phone.fill",
                        title: "Phone",
                        value: reservation.phone
                    )
                }
                
                // Email if available
                if let email = reservation.emailAddress {
                    detailItem(
                        icon: "envelope.fill",
                        title: "Email",
                        value: email
                    )
                }
                
                // Creation time
                HStack {
                    Spacer()
                    Text("Requested \(timeAgo(from: reservation.creationDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "just now"
        }
    }
}

// View modifier to add visual indicators for web reservations
struct WebReservationModifier: ViewModifier {
    let reservation: Reservation
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if reservation.isWebReservation {
                        if reservation.acceptance == .toConfirm {
                            // Pending web reservation
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.orange)
                                
                                Text("Web Request")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                            .position(x: 75, y: 20)
                        } else {
                            // Confirmed web reservation
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                
                                Text("Web")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                            .position(x: 50, y: 20)
                        }
                    }
                }
            )
    }
}

// Extension to make the modifier easier to use
extension View {
    func webReservationStyle(for reservation: Reservation) -> some View {
        self.modifier(WebReservationModifier(reservation: reservation))
    }
}

// Extension to ReservationInfoCard to add web-specific actions
extension ReservationInfoCard {
    @ViewBuilder
    func webReservationActions(for reservation: Reservation) -> some View {
        if reservation.isWebReservation && reservation.acceptance == .toConfirm {
            VStack(spacing: 12) {
                Divider()
                
                HStack {
                    Text("Web Reservation Request")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                
                Button(action: {
                    Task {
                        await approveReservation(reservation)
                        onClose()
                    }
                }) {
                    Text("Approve Reservation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    // Logic to decline the reservation
                    let updatedReservation = env.reservationService.separateReservation(
                        reservation, 
                        notesToAdd: "Declined web reservation"
                    )
                    
                    env.reservationService.updateReservation(reservation, newReservation: updatedReservation) {
                        onClose()
                    }
                }) {
                    Text("Decline Request")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    private func approveReservation(_ reservation: Reservation) {
        isApproving = true
        
        Task {
            let success = await env.reservationService.approveWebReservation(reservation)
            
            await MainActor.run {
                isApproving = false
                if success {
                    alertMessage = "Reservation approved successfully! A confirmation email has been sent to the guest."
                } else {
                    alertMessage = "Failed to approve reservation. Please try again."
                }
                showingAlert = true
            }
        }
    }
}

// Add extension to ReservationCard to display web reservation badges
extension ReservationCard {
    var webReservationIndicator: some View {
        Group {
            if reservation.isWebReservation {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption2)
                    
                    if reservation.acceptance == .toConfirm {
                        Text("Web Pending")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Text("Web")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(reservation.acceptance == .toConfirm ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(reservation.acceptance == .toConfirm ? Color.orange : Color.blue, lineWidth: 0.5)
                )
            }
        }
    }
}

// MARK: - Push Notification Handling

// Extension to AppDelegate for handling web reservation notifications
// Extension to AppDelegate for handling web reservation notifications
import SwiftUI
import UserNotifications
import OSLog
import Firebase

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Store the original notification handler to chain calls
    
    
    func setupWebReservationNotifications() {
            logger.info("Setting up web reservation notifications")
            
            // Register for remote notifications
            UIApplication.shared.registerForRemoteNotifications()
            
            // Add notification categories (Approve/Decline)
            let approveAction = UNNotificationAction(
                identifier: "APPROVE_ACTION",
                title: "Approve",
                options: [.foreground]
            )
            
            let declineAction = UNNotificationAction(
                identifier: "DECLINE_ACTION",
                title: "Decline",
                options: [.destructive, .foreground]
            )
            
            let webReservationCategory = UNNotificationCategory(
                identifier: "WEB_RESERVATION",
                actions: [approveAction, declineAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([webReservationCategory])
            
            // Save original notification handler if it exists
        if let existingDelegate = UNUserNotificationCenter.current().delegate as? NotificationManager {
              // That manager has a userNotificationCenter(...) closure
              Task { @MainActor in
                // Wrap it
                self.originalNotificationHandler = LegacyNotificationHandlerBox(
                  block: existingDelegate.userNotificationCenter
                )
              }
            }
            
            // Set this delegate to handle notification actions
            UNUserNotificationCenter.current().delegate = self
        }
        
        /// nonisolated delegate method so we can accept the non-Sendable UNNotificationResponse.
        /// Then we hop to the main actor for anything that’s main-actor isolated.
        nonisolated func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse
        ) async {
            let userInfo = response.notification.request.content.userInfo
            
            // Check if this is one of our web-reservation notifications
            guard
                let type = userInfo["type"] as? String,
                type == "new_web_reservation",
                let reservationId = userInfo["reservationId"] as? String,
                let uuid = UUID(uuidString: reservationId)
            else {
                // Not a web reservation; forward to original handler, if any
                await forwardToOriginalHandler(center: center, response: response)
                return
            }
            
            logger.info("Processing web reservation notification action: \(response.actionIdentifier)")
            
            let action = response.actionIdentifier
            
            switch action {
            case "APPROVE_ACTION":
                // Approve the reservation on main actor
                await MainActor.run {
                    self.handleApproveReservation(uuid: uuid)
                }
                
            case "DECLINE_ACTION":
                // Decline the reservation on main actor
                await MainActor.run {
                    self.handleDeclineReservation(uuid: uuid)
                }
                
            default:
                // User just tapped the notification
                logger.info("Opening web reservation from notification: \(uuid)")
                // Changing `selectedReservationID` is presumably main-actor isolated
                await MainActor.run {
                    NotificationManager.shared.selectedReservationID = uuid
                }
            }
        }
        
        /// Forward a notification we don't handle to the original handler (if any).
    nonisolated private func forwardToOriginalHandler(
        center: UNUserNotificationCenter,
        response: UNNotificationResponse
      ) async {
        // 1) Read the box from the main actor
        let handlerBox = await MainActor.run { self.originalNotificationHandler }
        guard let box = handlerBox else { return }
        
        // 2) Bridge the completion-based callback
        await withCheckedContinuation { continuation in
          box.block(center, response) {
            continuation.resume(returning: ())
          }
        }
      }
        
        /// MainActor-isolated approach to approving a reservation.
        @MainActor private func handleApproveReservation(uuid: UUID) {
            let dependencies = AppDependencies.shared
            guard let reservation = findReservation(with: uuid, in: dependencies) else {
                logger.warning("Could not find reservation with ID: \(uuid)")
                return
            }
            
            logger.info("Approving web reservation from notification: \(uuid)")
            // This call is presumably either sync or async on the main actor. If it's truly async, we can do:
            Task {
                await dependencies.reservationService.approveWebReservation(reservation)
            }
        }
        
        /// MainActor-isolated approach to declining a reservation.
        @MainActor private func handleDeclineReservation(uuid: UUID) {
            let dependencies = AppDependencies.shared
            guard let reservation = findReservation(with: uuid, in: dependencies) else {
                logger.warning("Could not find reservation with ID: \(uuid)")
                return
            }
            
            logger.info("Declining web reservation from notification: \(uuid)")
            
            // If separateReservation is synchronous, call directly
            let updatedReservation = dependencies.reservationService.separateReservation(
                reservation,
                notesToAdd: "Declined from notification"
            )
            
            // If updateReservation is completion-based, wrap it in a continuation
            Task {
                await withCheckedContinuation { continuation in
                    dependencies.reservationService.updateReservation(
                        reservation,
                        newReservation: updatedReservation
                    ) {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    
    private func findReservation(with id: UUID, in dependencies: AppDependencies) -> Reservation? {
        return dependencies.store.reservations.first { $0.id == id }
    }
    
    // Register device for push notifications
    // Register device token with completely detached task
        func registerDeviceWithFirebaseSafely(token: String, deviceId: String) {
            // Create a fire-and-forget Task that's completely detached from calling context
            // This avoids crossing any actor boundaries with the Firebase result
            Task.detached {
                do {
                    let functions = Functions.functions()
                    let userId = UserDefaults.standard.string(forKey: "userIdentifier") ?? deviceId
                    
                    let data: [String: Any] = [
                        "token": token,
                        "deviceId": deviceId,
                        "userId": userId
                    ]
                    
                    // Log from within the detached task
                    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseTask")
                    logger.info("Registering device token with Firebase")
                    
                    // Since this entire Task is detached, the non-Sendable result stays within
                    // the context of this task and never needs to cross boundaries
                    _ = try await functions.httpsCallable("registerDeviceToken").call(data)
                    
                    logger.info("Device successfully registered for push notifications")
                } catch {
                    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseTask")
                    logger.error("Error registering device: \(error.localizedDescription)")
                }
            }
        }
        
        // Handle notification registration failures
        func application(
            _ application: UIApplication,
            didFailToRegisterForRemoteNotificationsWithError error: Error
        ) {
            logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
        }
        
        // Register device for push notifications
        func application(
            _ application: UIApplication,
            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
            // Convert token to string
            let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
            let token = tokenParts.joined()
            
            logger.info("Device registered for push notifications with token: \(token)")
            
            // Generate a unique device ID if not already stored
            let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            
            // Register with Firebase using fire-and-forget approach
            registerDeviceWithFirebaseSafely(token: token, deviceId: deviceUUID)
        }
    
    
}

// Add shared instance to AppDependencies for easier access
// Add shared instance to AppDependencies for easier access
extension AppDependencies {
    // Private static instance to implement singleton pattern
    nonisolated(unsafe) private static var _shared: AppDependencies?
    
    // Initialize the shared instance at app launch
    static func initializeSharedInstance(_ instance: AppDependencies) {
        _shared = instance
    }
    
    // Access the shared instance safely - this approach doesn't rely on @MainActor
    static var shared: AppDependencies {
        // Check if we have already stored a reference
        if let existing = _shared {
            return existing
        }
        
        // If we don't have a shared instance yet, that's a serious error
        // Log it and return a no-op implementation that won't crash
        let logger = Logger(subsystem: "com.koenjiapp", category: "AppDependencies")
        logger.error("Fatal: Failed to access shared AppDependencies. App must call initializeSharedInstance during launch")
        
        // Instead of potentially crashing, we'll force a main thread operation
        // This is a last resort and should never happen in normal operation
        DispatchQueue.main.async {
            // Post a notification that can be observed to help debug
            NotificationCenter.default.post(
                name: Notification.Name("AppDependencies.MissingSharedInstance"),
                object: nil
            )
        }
        
        fatalError("AppDependencies.shared accessed before initialization")
    }
}

// MARK: - Integration with DatabaseView 

// Extension to DatabaseView to add web reservation filter and badge
extension DatabaseView {
    var webReservationFilter: some View {
        Button(action: {
            // Toggle filter for pending web reservations
            if env.listView.selectedFilters.contains(.webPending ?? .none) {
                env.listView.selectedFilters.remove(.webPending ?? .none)
            } else {
                env.listView.selectedFilters.insert(.webPending ?? .none)
            }
            refreshID = UUID()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption)
                
                Text("Web Pending")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                env.listView.selectedFilters.contains(.webPending ?? .none)
                ? Color.orange
                : Color.orange.opacity(0.1)
            )
            .foregroundColor(
                env.listView.selectedFilters.contains(.webPending ?? .none)
                ? .white
                : .orange
            )
            .clipShape(Capsule())
        }
    }
}

// Add web pending filter option
extension FilterOption {
    static let webPending = FilterOption(rawValue: "web_pending")
}

extension FilterOption {
    var localizedExpanded: String {
        switch self {
        case .webPending ?? .none:
            return String(localized: "Web Pending")
        default:
            return self.localized
        }
    }
}

// Update the filterReservations function to handle web reservations
extension DatabaseView {
    func filterReservationsExpanded(
        filters: Set<FilterOption>,
        searchText: String,
        currentReservations: [Reservation]
    ) -> [Reservation] {
        var filtered = currentReservations
        if !filters.isEmpty && !filters.contains(.none) {
            filtered = filtered.filter { reservation in
                var matches = true
                if filters.contains(.canceled) {
                    matches = matches && (reservation.status == .canceled)
                }
                if filters.contains(.toHandle) {
                    matches = matches && (reservation.status == .toHandle)
                }
                if filters.contains(.deleted) {
                    matches = matches && (reservation.status == .deleted)
                }
                if filters.contains(.waitingList) {
                    matches = matches && (reservation.reservationType == .waitingList)
                }
                if filters.contains(.webPending ?? .none) {
                    matches = matches && reservation.isWebReservation && reservation.acceptance == .toConfirm
                }
                if filters.contains(.people) {
                    matches = matches && (reservation.numberOfPersons == filterPeople)
                }
                if filters.contains(.date) {
                    if let date = reservation.normalizedDate {
                        matches = matches && (date >= filterStartDate && date <= filterEndDate)
                    } else {
                        matches = false
                    }
                }
                return matches
            }
        } else {
            filtered = filtered.filter { 
                $0.status != .canceled && 
                $0.status != .deleted && 
                $0.status != .toHandle && 
                $0.reservationType != .waitingList &&
                !($0.isWebReservation && $0.acceptance == .toConfirm)
            }
        }
        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { reservation in
                let nameMatch = reservation.name.lowercased().contains(lowercasedSearchText)
                let tableMatch = reservation.tables.contains { table in
                    table.name.lowercased().contains(lowercasedSearchText) ||
                    String(table.id).contains(lowercasedSearchText)
                }
                let notesMatch = reservation.notes?.lowercased().contains(lowercasedSearchText) ?? false
                let emailMatch = reservation.emailAddress?.lowercased().contains(lowercasedSearchText) ?? false
                return nameMatch || tableMatch || notesMatch || emailMatch
            }
        }
        return filtered
    }
}
