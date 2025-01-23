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
    @State private var systemTime: Date = Date()

    private var timesUp: Bool {
        let activeReservation = cluster.reservationID
        if let endTime = DateHelper.parseTime(activeReservation.endTime),
        let currentTimeComponents = DateHelper.extractTime(time: systemTime),
        let newTime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: endTime),
        endTime.timeIntervalSince(newTime) <= 60 * 30 {
            return true
        }
        return false
    }
    
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
            if cluster.reservationID.status != .showedUp,
               let startTime = DateHelper.parseTime(cluster.reservationID.startTime),
               let currentTimeComponents = DateHelper.extractTime(time: systemTime),
               let newtime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: startTime),
               newtime.timeIntervalSince(startTime) >= 15 * 60 {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17) // Adjust size as needed
                    .foregroundColor(.yellow) // Optional styling
                    .symbolRenderingMode(.multicolor)
                    .position(x: cluster.frame.minX + 15, y: cluster.frame.minY + 15)
            }
            
            if let endTime = DateHelper.parseTime(cluster.reservationID.endTime),
               let currentTimeComponents = DateHelper.extractTime(time: systemTime),
               let newTime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: endTime),
               endTime.timeIntervalSince(newTime) <= 60 * 30 {
                Image(systemName: "figure.walk.motion.trianglebadge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20) // Adjust size as needed
                    .foregroundStyle(.yellow, .orange /*isLunch ? Color(hex: "#6a6094") : Color(hex: "#435166")*/) // Optional styling
                    .symbolRenderingMode(.palette) // Enable multicolor rendering
                    .position(x: cluster.frame.maxX - 15, y: cluster.frame.maxY - 15) // Position in the top-left corner
                    .zIndex(2)
            }
        }
        .animation(.easeInOut, value: cluster.reservationID.status)
    }
}

