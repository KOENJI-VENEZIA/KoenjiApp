//
//  WebReservationCard.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import SwiftUI

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
                    
                    Text("Pending approval")
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

//#Preview {
//    WebReservationCard(reservation: Reservation.mockWebPending)
//        .previewLayout(.sizeThatFits)
//        .padding()
//}
