//
//  ClusterOverlayView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//
import SwiftUI

struct ClusterOverlayView: View {
    let cluster: CachedCluster
    let currentTime: Date
    let selectedCategory: Reservation.ReservationCategory
    @State private var systemTime: Date = Date()
    
    @State private var nearEndReservation: Reservation?
    
    @EnvironmentObject var resCache: CurrentReservationsCache

    
    var body: some View {
        ZStack {
            // Checkmark overlay for "showed up" status
            if cluster.reservationID.status == .showedUp {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .position(x: cluster.frame.minX + 13, y: cluster.frame.minY + 13)
            }

            // Emoji overlay
            if let emoji = cluster.reservationID.assignedEmoji {
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(maxWidth: 23, maxHeight: 23)
                    .position(x: cluster.frame.maxX - 18, y: cluster.frame.minY + 12)
            }

            // Warning overlay for reservations running late
            if cluster.reservationID.status == .late {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundColor(.yellow)
                    .symbolRenderingMode(.multicolor)
                    .position(x: cluster.frame.minX + 15, y: cluster.frame.minY + 15)
            }

            // Warning overlay for "time's up"
            if nearEndReservation != nil {
                Image(systemName: "figure.walk.motion.trianglebadge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.yellow, .orange)
                    .symbolRenderingMode(.palette)
                    .position(x: cluster.frame.maxX - 15, y: cluster.frame.maxY - 15)
                    .zIndex(2)
            }
        }
        .onAppear {
            updateNearEndReservation()
        }
        .onChange(of: currentTime) {
            updateNearEndReservation()
        }
        .animation(.easeInOut, value: cluster.reservationID.status)
    }

    // MARK: - Precompute Reservation States
    private func updateNearEndReservation() {
        if resCache.nearingEndReservations(currentTime: currentTime).contains(where: {$0.id == cluster.reservationID.id }) {
            nearEndReservation = cluster.reservationID
        }
    }
}

