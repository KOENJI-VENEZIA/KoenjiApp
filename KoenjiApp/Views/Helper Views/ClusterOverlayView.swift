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
    
    // Precomputed states
    @State private var showedUp: Bool = false
    @State private var isLate: Bool = false
    @State private var timesUp: Bool = false

    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var stateCache: ReservationStateCache

    
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
            if resCache.nearingEndReservations(currentTime: currentTime).contains(where: {$0.id == cluster.reservationID.id }) {
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
//            cluster.reservationID = resCache.reservation(forTable: cluster.tableIDs.first!, datetime: currentTime, category: selectedCategory)
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

        let calendar = Calendar.current

        // Compute "showed up" status
        let showedUpComputed = reservation.status == .showedUp

        // Compute "running late" status
        let isLateComputed: Bool
        if reservation.status != .showedUp,
           let startTime = reservation.startTimeDate,
           let endTime = reservation.endTimeDate {
            let isSameDay = calendar.isDate(systemTime, inSameDayAs: startTime)
            let elapsedTime = systemTime.timeIntervalSince(startTime)
            let reservationDuration = endTime.timeIntervalSince(startTime)

            // Late if elapsed time is >= 15 minutes but within the reservation duration
            isLateComputed = isSameDay && elapsedTime >= 15 * 60 && elapsedTime <= reservationDuration
        } else {
            isLateComputed = false
        }

        // Compute "time's up" status
        let timesUpComputed: Bool
        if let startTime = reservation.startTimeDate,
           let endTime = reservation.endTimeDate {
            let isSameDay = calendar.isDate(systemTime, inSameDayAs: startTime)
            let elapsedTime = systemTime.timeIntervalSince(startTime)
            let reservationDuration = endTime.timeIntervalSince(startTime)
            let isWithinEndWindow = endTime.timeIntervalSince(systemTime) <= 30 * 60

            // Time's up if within 30 minutes of the reservation's end and within its duration
            timesUpComputed = isSameDay && elapsedTime <= reservationDuration && isWithinEndWindow
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

