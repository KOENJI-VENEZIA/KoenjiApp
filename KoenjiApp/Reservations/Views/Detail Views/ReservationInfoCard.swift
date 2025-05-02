//
//  ReservationInfoCard.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 12/1/25.
//

import SwiftUI

struct ReservationInfoCard: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(LayoutUnitViewModel.self) var unitView

    let reservationID: UUID
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onApprove: (() -> Void)?

    @State var isApproving = false
    @State var showingAlert = false
    @State var alertMessage = ""
    @State private var reservation: Reservation?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading reservation details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let reservation = reservation {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Main card content
                            VStack(alignment: .leading, spacing: 16) {
                                // Header with name and status
                                HStack {
                                    Text(reservation.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                
                                // All badges together
                                HStack(spacing: 8) {
                                    statusBadge(status: reservation.status)
                                    categoryBadge(category: reservation.category)
                                    typeBadge(type: reservation.reservationType)
                                }
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                // Primary info with icons in a grid
                                let columns = [
                                    GridItem(.adaptive(minimum: 180, maximum: .infinity), spacing: 12)
                                ]
                                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                                    detailTag(
                                        icon: "person.2.fill",
                                        title: String(localized: "Persone"),
                                        value: "\(reservation.numberOfPersons)",
                                        color: .blue
                                    )
                                    
                                    detailTag(
                                        icon: "phone.fill",
                                        title: String(localized: "Telefono"),
                                        value: reservation.phone,
                                        color: .green
                                    )
                                    
                                    detailTag(
                                        icon: "calendar",
                                        title: String(localized: "Data"),
                                        value: DateHelper.formatFullDate(reservation.normalizedDate ?? Date()),
                                        color: .orange
                                    )
                                    
                                    detailTag(
                                        icon: "clock.fill",
                                        title: String(localized: "Orario"),
                                        value: "\(reservation.startTime) - \(reservation.endTime)",
                                        color: .purple
                                    )
                                    
                                    detailTag(
                                        icon: "clock.badge.checkmark.fill",
                                        title: String(localized: "Durata"),
                                        value: calculateDuration(start: reservation.startTime, end: reservation.endTime),
                                        color: .purple
                                    )
                                    
                                    if !reservation.tables.isEmpty {
                                        detailTag(
                                            icon: "tablecells",
                                            title: String(localized: "Tavoli"),
                                            value: reservation.tables.map(\.name).joined(separator: ", "),
                                            color: .indigo
                                        )
                                    }
                                }
                                
                                // Notes section if present
                                if let notes = reservation.notes {
                                    Divider()
                                        .padding(.vertical, 8)
                                    multilineDetailTag(
                                        icon: "note.text",
                                        title: String(localized: "Note"),
                                        content: notes,
                                        color: .blue
                                    )
                                }
                                
                                // Image section if present
                                if let image = reservation.image {
                                    Divider()
                                        .padding(.vertical, 8)
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label("Immagine", systemImage: "photo")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .frame(maxWidth: .infinity)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                            .onTapGesture {
                                                unitView.isShowingFullImage = true
                                            }
                                    }
                                }
                            }
                            .padding(16)
                            .background(reservation.assignedColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(16)
                    }
                    
                    // Bottom button
                    Button(action: { onEdit(reservation) }) {
                        Label("Modifica Prenotazione", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(reservation.assignedColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(16)
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .sheet(isPresented: Binding<Bool>(
                    get: { unitView.isShowingFullImage },
                    set: { unitView.isShowingFullImage = $0 }
                )) {
                    if let image = reservation.image {
                        fullScreenImageView(image)
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Reservation Approval"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK")) {
                            if alertMessage.contains("successfully") {
                                onApprove?()
                                onClose()
                            }
                        }
                    )
                }
            } else {
                Text("Reservation not found")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            loadReservation()
        }
        .onChange(of: appState.changedReservation) { _, _ in
            loadReservation()
        }
    }
    
    private func loadReservation() {
        isLoading = true
        
        // First check the cache for the reservation
        for (_, reservations) in env.resCache.cache {
            if let found = reservations.first(where: { $0.id == reservationID }) {
                self.reservation = found
                isLoading = false
                return
            }
        }
        
        // If not found in cache, fetch from Firebase
        Task {
            do {
                // Try to fetch reservations for the current date
                let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate)
                
                await MainActor.run {
                    if let found = reservations.first(where: { $0.id == reservationID }) {
                        self.reservation = found
                    }
                    isLoading = false
                }
            } catch {
                print("Error fetching reservation: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func detailTag(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
                .alignmentGuide(.firstTextBaseline) { d in
                    d[.bottom] - 3  // Adjust to align with the title
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func multilineDetailTag(icon: String, title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
                    .alignmentGuide(.firstTextBaseline) { d in
                        d[.bottom] - 3  // Match the alignment of detailTag
                    }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(content)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 32)  // Align with text after icon
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusBadge(status: Reservation.ReservationStatus) -> some View {
        Label {
            Text(status.localized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: status == .showedUp ? "checkmark.circle.fill" : 
                             status == .canceled ? "xmark.circle.fill" :
                             status == .pending ? "clock.fill" :
                             "exclamationmark.circle.fill")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .foregroundColor(status.color)
        .clipShape(Capsule())
    }
    
    private func categoryBadge(category: Reservation.ReservationCategory) -> some View {
        Label {
            Text(category.localized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: category == .lunch ? "sun.max.fill" : "moon.fill")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.12))
        .foregroundColor(category.color)
        .clipShape(Capsule())
    }
    
    private func typeBadge(type: Reservation.ReservationType) -> some View {
        Label {
            Text(type.localized)
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: type == .inAdvance ? "calendar" : "figure.walk")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.color.opacity(0.12))
        .foregroundColor(type.color)
        .clipShape(Capsule())
    }
    
    private func fullScreenImageView(_ image: Image) -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Button(action: { unitView.isShowingFullImage = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                Spacer()
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
            }
        }
    }
    
    private func calculateDuration(start: String, end: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            return "N/A"
        }
        
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        let hours = diffComponents.hour ?? 0
        let minutes = diffComponents.minute ?? 0
        
        if hours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h\(String(format: "%02d", minutes))"
        }
    }
}
