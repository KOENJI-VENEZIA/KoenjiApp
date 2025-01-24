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
    
    // Precomputed states
    @State private var showedUp: Bool = false
    @State private var isLate: Bool = false
    @State private var timesUp: Bool = false

    @EnvironmentObject var stateCache: ReservationStateCache

    
    var body: some View {
        ZStack {
            // Checkmark overlay for "showed up" status
            if showedUp {
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
            if isLate {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundColor(.yellow)
                    .symbolRenderingMode(.multicolor)
                    .position(x: cluster.frame.minX + 15, y: cluster.frame.minY + 15)
            }

            // Warning overlay for "time's up"
            if timesUp {
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
            computeReservationStates()
        }
        .onChange(of: currentTime) { 
            computeReservationStates()
        }
        .animation(.easeInOut, value: cluster.reservationID.status)
    }

    // MARK: - Precompute Reservation States
    private func computeReservationStates() {
        let reservation = cluster.reservationID

        // Check if the reservation states are already cached
        if let cachedState = stateCache.cache[reservation.id],
           cachedState.time == systemTime {
            // Use cached values
            timesUp = cachedState.timesUp
            isLate = cachedState.isLate
            showedUp = cachedState.showedUp
            return
        }

        // Compute "showed up" status
        let showedUpComputed = reservation.status == .showedUp

        // Compute "running late" status
        let isLateComputed: Bool
        if reservation.status != .showedUp,
           let startTime = reservation.startTimeDate,
           let reservationDate = reservation.date,
           let currentTimeComponents = DateHelper.extractTime(time: systemTime),
           let newTime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: startTime) {
            isLateComputed = newTime.timeIntervalSince(startTime) >= 15 * 60 &&
                             reservationDate.isSameDay(as: systemTime)
        } else {
            isLateComputed = false
        }

        // Compute "time's up" status
        let timesUpComputed: Bool
        if let endTime = reservation.endTimeDate,
           let reservationDate = reservation.date,
           let currentTimeComponents = DateHelper.extractTime(time: systemTime),
           let newTime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: endTime) {
            timesUpComputed = endTime.timeIntervalSince(newTime) <= 60 * 30 &&
                              reservationDate.isSameDay(as: systemTime)
        } else {
            timesUpComputed = false
        }

        // Update states
        timesUp = timesUpComputed
        isLate = isLateComputed
        showedUp = showedUpComputed

        // Cache the computed values
        stateCache.cache[reservation.id] = ReservationState(
            time: systemTime,
            timesUp: timesUpComputed,
            showedUp: showedUpComputed,
            isLate: isLateComputed
        )
    }
}

