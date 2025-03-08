import SwiftUI

struct SessionsView: View {
    @AppStorage("deviceUUID") var deviceUUID: String = ""
    @EnvironmentObject var env: AppDependencies
    @State private var isShowingInfo = false
    @State private var hoveredSession: Session? = nil
    @State private var autoShowEditingInfo = false
    // Add a state to track what type of capsule to show
    @State private var showEditingCapsule = false
    
    // Add a timer to auto-hide the info
    @State private var hideTimer: Timer? = nil
    // Add a timer for resetting the hovered session
    @State private var hoverResetTimer: Timer? = nil
    
    var activeSessions: [Session] {
        return updateActiveSessions()
    }
    
    // Check if any session is currently editing
    var isAnyoneEditing: Bool {
        return activeSessions.contains(where: { $0.isEditing })
    }
    
    // Get only the sessions that are editing
    var editingSessions: [Session] {
        return activeSessions.filter { $0.isEditing }
    }
    
    // Get only the sessions that are viewing (not editing)
    var viewingSessions: [Session] {
        return activeSessions.filter { !$0.isEditing }
    }
    
    // Create random colors for users based on their UUID for consistent colors
    func colorForSession(_ session: Session) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo, .mint, .red, .yellow]
        
        // Use a more unique approach to selecting colors
        // Take the first 4 characters of the UUID and convert to an integer
        let uuidPrefix = session.uuid.prefix(4)
        var hashValue = 0
        for char in uuidPrefix {
            hashValue = ((hashValue << 5) &+ hashValue) &+ Int(char.asciiValue ?? 0)
        }
        
        return colors[abs(hashValue) % colors.count]
    }
    
    var body: some View {
        let limitedSessions = Array(activeSessions.suffix(5))
        
        VStack {
            // This will push everything to the bottom
            Spacer()
            
            // The sessions view itself (wrapped in another container to limit tap area)
            HStack(alignment: .center, spacing: 8) {
                Spacer() // Push everything to the right

                // Collaboration status label
                if !limitedSessions.isEmpty && (isShowingInfo || autoShowEditingInfo) {
                    collaborationStatusView(sessions: activeSessions)
                        .onAppear {
                            // Set or reset timer whenever the view appears
                            resetTimer()
                        }
                        .transition(.opacity)
                }
                
                // Session avatars - positioned at the left edge
                sessionAvatarsView(sessions: limitedSessions)
            }
            .padding(.leading, 10)
            .padding(.bottom, 8)
            // This tap gesture ONLY applies to the HStack containing the session avatars
            .onTapGesture {
                if isShowingInfo || autoShowEditingInfo {
                    isShowingInfo = false
                    autoShowEditingInfo = false
                    invalidateTimer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing) // Only control horizontal alignment
        .animation(.easeInOut(duration: 0.3), value: activeSessions)
        .animation(.easeInOut(duration: 0.3), value: isShowingInfo)
        .animation(.easeInOut(duration: 0.3), value: autoShowEditingInfo)
        .animation(.easeInOut(duration: 0.3), value: hoveredSession)
        // Monitor for editing changes
        .onChange(of: isAnyoneEditing) { old, newValue in
            if newValue {
                // Someone started editing, show the info automatically
                autoShowEditingInfo = true
                isShowingInfo = false
                // When auto-showing the editing info, focus on the editing capsule
                showEditingCapsule = true
                resetTimer()
            }
        }
        .onDisappear {
            invalidateTimer()
            invalidateHoverResetTimer()
        }
        // NO tap gesture here at the top level
    }
    
    // MARK: - Timer Functions
    
    private func resetTimer() {
        invalidateTimer()
        
        // Create a new timer to auto-hide after 4 seconds
        hideTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            // Use DispatchQueue.main to update UI state from the timer
            DispatchQueue.main.async {
                isShowingInfo = false
                autoShowEditingInfo = false
            }
        }
    }
    
    private func invalidateTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    // New timer functions for the hovered session
    private func resetHoverTimer() {
        invalidateHoverResetTimer()
        
        // Create a new timer to reset the hovered session after 4 seconds
        hoverResetTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            // Use DispatchQueue.main to update UI state from the timer
            DispatchQueue.main.async {
                hoveredSession = nil
            }
        }
    }
    
    private func invalidateHoverResetTimer() {
        hoverResetTimer?.invalidate()
        hoverResetTimer = nil
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func collaborationStatusView(sessions: [Session]) -> some View {
        // Determine which collection of sessions to show based on the selected mode
        let sessionsToShow = showEditingCapsule ? editingSessions : viewingSessions
        let count = sessionsToShow.count
        let isShowingEditing = showEditingCapsule
        
        HStack(spacing: 5) {
            Image(systemName: isShowingEditing ? "pencil.circle.fill" : "eye.fill")
                .foregroundColor(.secondary)
            
            if let hoveredSession = hoveredSession,
               (isShowingEditing ? hoveredSession.isEditing : !hoveredSession.isEditing) {
                // Personalized message for the hovered user
                Text("\(hoveredSession.userName) \(isShowingEditing ? String(localized: "sta modificando") : String(localized: "sta visualizzando"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // General message for multiple users or when no specific user is hovered
                Text("\(count) \(isShowingEditing ? (count == 1 ? String(localized: "sta modificando") : String(localized: "stanno modificando")) : (count == 1 ? String(localized: "sta visualizzando") : String(localized: "stanno visualizzando")))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            ZStack {
                if isShowingEditing {
                    // Solid background for editing status
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    // Material background for viewing status
                    Capsule()
                        .fill(.ultraThinMaterial)
                    Capsule()
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                }
            }
        )
    }
    
    @ViewBuilder
    private func sessionAvatarsView(sessions: [Session]) -> some View {
        HStack(spacing: -10) {
            // Extra users indicator
            extraUsersIndicator(totalCount: activeSessions.count, displayedCount: sessions.count)
            ForEach(Array(sessions.enumerated()), id: \.element.uuid) { index, session in
                sessionAvatarButton(session: session, index: index, totalCount: sessions.count)
            }
        }
    }
    
    @ViewBuilder
    private func sessionAvatarButton(session: Session, index: Int, totalCount: Int) -> some View {
        Button(action: {
            // Toggle info visibility when tapping avatar
            if isShowingInfo && hoveredSession?.uuid == session.uuid {
                isShowingInfo = false
                invalidateTimer()
                hoveredSession = nil
                invalidateHoverResetTimer()
            } else {
                hoveredSession = session
                isShowingInfo = true
                autoShowEditingInfo = false
                // Set the capsule state based on whether the tapped session is in editing mode
                showEditingCapsule = session.isEditing
                resetTimer()
                resetHoverTimer() // Start the timer to auto-reset the hovered state
            }
        }) {
            SessionAvatarView(
                session: session,
                color: colorForSession(session),
                isHovered: hoveredSession?.uuid == session.uuid
            )
            .zIndex(Double(totalCount - index))
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Text(session.userName)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text(session.deviceName ?? "Unknown device")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if session.isEditing {
                Text("Currently editing")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private func extraUsersIndicator(totalCount: Int, displayedCount: Int) -> some View {
        if totalCount > displayedCount {
            Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 38, height: 38)
                .overlay(
                    Text("+\(totalCount - displayedCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .offset(x: -5)
                .zIndex(0)
        }
    }
    
    func updateActiveSessions() -> [Session] {
        let sessions = SessionStore.shared.sessions
        return sessions.filter { session in
            session.uuid != deviceUUID &&
            session.isActive == true
        }
    }
}

// MARK: - Supporting Views

struct SessionAvatarView: View {
    let session: Session
    let color: Color
    let isHovered: Bool
    
    var body: some View {
        ZStack {
            // Avatar circle with dynamic appearance based on hover state
            Circle()
                .fill(isHovered ? color : Color.gray.opacity(0.2))
                .overlay(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(isHovered ? 0 : 0.7)
                )
                .overlay(
                    Circle()
                        .strokeBorder(color.opacity(isHovered ? 0.8 : 0.6), lineWidth: isHovered ? 2 : 1)
                )
                .frame(width: 38, height: 38)
                .shadow(color: Color.black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 4 : 2, x: 0, y: 2)
            
            // Profile image or initials
            if let imageURL = session.profileImageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Text(getInitials(from: session.userName))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isHovered ? .white : color.opacity(0.8))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                    case .failure:
                        Text(getInitials(from: session.userName))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isHovered ? .white : color.opacity(0.8))
                    @unknown default:
                        Text(getInitials(from: session.userName))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isHovered ? .white : color.opacity(0.8))
                    }
                }
            } else {
                // User initials - extract and display
                Text(getInitials(from: session.userName))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isHovered ? .white : color.opacity(0.8))
            }
            
            // Editing indicator
            editingIndicator
        }
        .frame(width: 40, height: 40)
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
    }
    
    // Extract initials from user name (e.g., "John D." -> "JD")
    private func getInitials(from name: String) -> String {
        // Handle empty string
        if name.isEmpty {
            return "?"
        }
        
        // Split the name into components
        let components = name.components(separatedBy: " ")
        
        if components.count == 1 {
            // If there's just one word, use the first letter
            return String(components[0].prefix(1))
        } else {
            // Get the first letter of first name and the first letter of the last name
            let firstInitial = components[0].prefix(1)
            let lastInitial = components[1].prefix(1)
            return "\(firstInitial)\(lastInitial)"
        }
    }
    
    @ViewBuilder
    private var editingIndicator: some View {
        if session.isEditing {
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .overlay(
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.blue)
                )
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                )
                .offset(x: 14, y: -14)
        }
    }
}
