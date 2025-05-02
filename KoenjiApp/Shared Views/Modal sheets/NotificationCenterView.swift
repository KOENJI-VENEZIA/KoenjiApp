//
//  NotificationCenterView.swift
//  KoenjiApp
//
//  Created on 3/1/25.
//

import SwiftUI

struct NotificationCenterView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(LayoutUnitViewModel.self) var unitView
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var selectedNotification: AppNotification?
    @State private var showingAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifiche")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !notificationManager.notifications.isEmpty {
                    Button(action: {
                        showingAlert = true
                    }) {
                        Text("Pulisci tutto")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Notification list
            if notificationManager.notifications.isEmpty {
                emptyNotificationsView
            } else {
                notificationListView
            }
        }
        .background(.clear)
        .alert("Pulire tutte le notifiche?", isPresented: $showingAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Pulisci", role: .destructive) {
                Task {
                    await MainActor.run {
                        notificationManager.clearNotifications()
                    }
                }
            }
        }
    }
    
    private var emptyNotificationsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bell.badge.slash")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("Nessuna notifica")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text("Le notifiche relative alle prenotazioni appariranno qui")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var notificationListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(notificationManager.notifications.sorted(by: { $0.date > $1.date })) { notification in
                    NotificationCard(notification: notification)
                        .contextMenu {
                            Button(action: {
                                Task {
                                    await MainActor.run {
                                        notificationManager.removeNotification(notification)
                                    }
                                }
                            }) {
                                Label("Rimuovi", systemImage: "trash")
                            }
                            
                            if notification.reservation != nil {
                                Button(action: {
                                    selectedNotification = notification
                                }) {
                                    Label("Vedi prenotazione", systemImage: "info.circle")
                                }
                            }
                        }
                        .onTapGesture {
                            if notification.reservation != nil {
                                selectedNotification = notification
                            }
                        }
                }
            }
            .padding()
        }
        .sheet(item: $selectedNotification) { notification in
            if let reservation = notification.reservation {
                NavigationStack {
                    ReservationInfoCard(
                        reservationID: reservation.id,
                        onClose: { selectedNotification = nil },
                        onEdit: { _ in
                            selectedNotification = nil
                            // Handle edit action if needed
                        }
                    )
                    .navigationTitle("Dettagli Prenotazione")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { selectedNotification = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

struct NotificationCard: View {
    let notification: AppNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type and time
            HStack {
                typeBadge(type: notification.type)
                
                Spacer()
                
                Text(timeAgo(from: notification.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Title and message
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Reservation indicator if available
            if let reservation = notification.reservation {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(reservation.assignedColor)
                    
                    Text(reservation.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if notification.reservation != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(notification.type.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(notification.type.color.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func typeBadge(type: NotificationType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: type.iconName)
                .font(.caption)
            
            Text(type.localized.capitalized)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.color.opacity(0.12))
        .foregroundStyle(type.color)
        .clipShape(Capsule())
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? String(localized: "Ieri") : String(localized: "\(day) giorni fa")
        } else if let hour = components.hour, hour > 0 {
            return String(localized: "\(hour) \(hour == 1 ? "ora" : "ore") fa")
        } else if let minute = components.minute, minute > 0 {
            return String(localized: "\(minute) \(minute == 1 ? "minuto" : "minuti") fa")
        } else {
            return String(localized: "Ora")
        }
    }
}

// Extension to add necessary properties to NotificationType for UI
extension NotificationType {
    var color: Color {
        switch self {
        case .late:
            return .red
        case .nearEnd:
            return .orange
        case .canceled:
            return .pink
        case .restored:
            return .green
        case .waitingList:
            return .blue
        case .sync:
            return .purple
        }
    }
    
    var iconName: String {
        switch self {
        case .late:
            return "clock.badge.exclamationmark"
        case .nearEnd:
            return "timer"
        case .canceled:
            return "xmark.circle"
        case .restored:
            return "arrow.counterclockwise.circle"
        case .waitingList:
            return "list.bullet.clipboard"
        case .sync:
            return "arrow.triangle.2.circlepath"
        }
    }
}