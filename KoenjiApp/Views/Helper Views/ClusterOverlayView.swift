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

    var body: some View {
        ZStack {
            // Checkmark overlay for "showed up" status
           
            Image(systemName: cluster.reservationID.status == .pending ? "" : "checkmark.circle.fill")
                .resizable()
                .foregroundColor(cluster.reservationID.status == .pending ? .gray : .green)
                .animation(.easeInOut, value: cluster.reservationID.status)
                .scaledToFit()
                .frame(width: 20, height: 20)
                .position(x: cluster.frame.minX + 15, y: cluster.frame.minY + 15)
        

            // Emoji overlay
            if let emoji = cluster.reservationID.assignedEmoji {
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(maxWidth: 23, maxHeight: 23)
                    .position(x: cluster.frame.maxX - 15, y: cluster.frame.minY + 15)
            }

            // Warning overlay for reservations running late
            if cluster.reservationID.status != .showedUp,
               let startTime = DateHelper.parseTime(cluster.reservationID.startTime),
               let currentTimeComponents = DateHelper.extractTime(time: currentTime),
               let newtime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: startTime),
               newtime.timeIntervalSince(startTime) >= 15 * 60 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.orange)
                    .position(x: cluster.frame.minX + 15, y: cluster.frame.minY + 15)
            }
        }
        .animation(.easeInOut, value: cluster.reservationID.status)
    }
}

struct CheckmarkView: View, Equatable {
    let status: Reservation.ReservationStatus

    static func == (lhs: CheckmarkView, rhs: CheckmarkView) -> Bool {
        lhs.status == rhs.status
    }

    var body: some View {
        Image(systemName: status == .pending ? "" : "checkmark.circle.fill")
            .foregroundColor(status == .pending ? .gray : .green)
            // Add any animations or transitions if needed
    }
}
