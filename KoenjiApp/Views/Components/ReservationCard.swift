import SwiftUI
import SwipeActions
import OSLog

struct ReservationCard: View {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ReservationCard"
    )
    
    let reservation: Reservation
    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
    
    let onTap: () -> Void
    let onCancel: () -> Void
    let onRecover: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let searchText: String
    
    var body: some View {
        SwipeView {
            cardContent
        } trailingActions: { _ in
            if reservation.status == .canceled || reservation.status == .deleted {
                SwipeAction(
                    systemImage: "arrow.uturn.backward.circle.fill",
                    backgroundColor: .blue.opacity(0.2)
                ) {
                    onRecover()
                }
            } else {
                SwipeAction(
                    systemImage: "xmark.circle.fill",
                    backgroundColor: .red.opacity(0.2)
                ) {
                    onCancel()
                }
            }
            
            if reservation.status == .canceled {
                SwipeAction(
                    systemImage: "trash.circle.fill",
                    backgroundColor: .red.opacity(0.2)
                ) {
                    onDelete()
                }
            }
        }
        .swipeActionCornerRadius(12)
        .swipeMinimumDistance(40)
        .swipeActionsMaskCornerRadius(12)
    }
    
    private var cardContent: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 16) {
                // Main content column
                VStack(alignment: .leading, spacing: 8) {
                    // Header with name
                    highlightedText(for: reservation.name, with: searchText)
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 4) {
                        detailRow(icon: "person.2.fill", text: "\(reservation.numberOfPersons) persone")
                        detailRow(icon: "calendar", text: "\(DateHelper.formatFullDate(reservation.cachedNormalizedDate ?? Date()))")
                        detailRow(icon: "clock.fill", text: "\(reservation.startTime) - \(reservation.endTime)")
                    }
                    
                    // All badges in a horizontal flow
                    HStack(spacing: 4) {
                        statusBadge
                        categoryBadge
                        typeBadge
                    }
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.55, alignment: .leading)
                
                // Notes column (if present)
                if let notes = reservation.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Note", systemImage: "note.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        highlightedText(for: notes, with: searchText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                            .truncationMode(.tail)
                            .onTapGesture {
                                notesToShow = notes
                                notesAlertShown = true
                            }
                    }
                    .frame(width: geometry.size.width * 0.35)
                }
            }
        }
        .padding(24)
        .frame(height: 150)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statusBadge: some View {
        Text(reservation.status.localized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(reservation.status.color.opacity(0.2))
            .foregroundColor(reservation.status.color)
            .clipShape(Capsule())
    }
    
    private var categoryBadge: some View {
        Text(reservation.category.localized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(reservation.category.color.opacity(0.2))
            .foregroundColor(reservation.category.color)
            .clipShape(Capsule())
    }
    
    private var typeBadge: some View {
        Text(reservation.reservationType.localized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(reservation.reservationType.color.opacity(0.2))
            .foregroundColor(reservation.reservationType.color)
            .clipShape(Capsule())
    }
    
    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var cardBackground: some View {
        Group {
            if reservation.status == .canceled {
                Color.gray.opacity(0.2)
            } else if reservation.status == .toHandle {
                Color.yellow.opacity(0.2)
            } else if reservation.status == .deleted {
                Color.red.opacity(0.2)
            } else {
                reservation.assignedColor.opacity(0.2)
            }
        }
    }
    
    // Add highlighting function
    private func highlightedText(for text: String, with searchText: String) -> Text {
        guard !searchText.isEmpty else { return Text(text) }
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        
        while let range = lowercasedText.range(of: lowercasedSearchText,
                                              range: currentIndex..<lowercasedText.endIndex) {
            let prefix = String(text[currentIndex..<range.lowerBound])
            highlighted = highlighted + Text(prefix)
            let match = String(text[range])
            highlighted = highlighted + Text(match).foregroundColor(.yellow)
            currentIndex = range.upperBound
        }
        
        let suffix = String(text[currentIndex..<lowercasedText.endIndex])
        highlighted = highlighted + Text(suffix)
        return highlighted
    }
}

// MARK: - Color Extensions
extension Reservation.ReservationStatus {
    var color: Color {
        switch self {
        case .pending: return .blue
        case .showedUp: return .green
        case .late: return .orange
        case .canceled: return .gray
        case .noShow: return .red
        case .na: return .gray
        case .toHandle: return .yellow
        case .deleted: return .red
        }
    }
}

extension Reservation.ReservationCategory {
    var color: Color {
        switch self {
        case .lunch: return .orange
        case .dinner: return .indigo
        case .noBookingZone: return .gray
        }
    }
}

extension Reservation.ReservationType {
    var color: Color {
        switch self {
        case .inAdvance: return .blue
        case .walkIn: return .green
        case .waitingList: return .orange
        case .na: return .gray
        }
    }
} 
