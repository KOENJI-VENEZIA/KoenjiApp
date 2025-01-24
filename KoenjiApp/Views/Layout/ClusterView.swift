//
//  File.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//
import SwiftUI

class ReservationStateCache: ObservableObject {
    @Published var cache: [UUID: ReservationState] = [:]
}

struct ReservationState {
    let time: Date
    let timesUp: Bool
    let showedUp: Bool
    let isLate: Bool
}

struct ClusterView: View {

    let cluster: CachedCluster
    let overlayFrame: CGRect
    @Binding var currentTime: Date
    @State private var systemTime: Date = Date()
    @Binding var isLayoutLocked: Bool
    var isLunch: Bool

    // Precomputed states
    @State private var timesUp: Bool = false
    @State private var showedUp: Bool = false
    @State private var isLate: Bool = false
    @EnvironmentObject var stateCache: ReservationStateCache


    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8.0)
                .fill(isLunch ? Color.active_table_lunch : Color.active_table_dinner)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.0)
                        .stroke(
                            timesUp ? .red : (isLate ? Color(hex: "#f78457") : (showedUp ? .green : .white)),
                            lineWidth: 3
                        )
                )
                .frame(width: overlayFrame.width, height: overlayFrame.height)
                .position(x: overlayFrame.midX, y: overlayFrame.midY)
                .zIndex(1)
                .allowsHitTesting(false) // Ignore touch input

            // Reservation label (centered on the cluster)
            if cluster.tableIDs.first != nil {
                let overlayFrame = cluster.frame
                VStack(spacing: 4) {
                    Text(cluster.reservationID.name)
                        .bold()
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("\(cluster.reservationID.numberOfPersons) p.")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .opacity(0.8)

                    Text(cluster.reservationID.phone)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .opacity(0.8)

                    if let remaining = TimeHelpers.remainingTimeString(
                        endTime: cluster.reservationID.endTime,
                        currentTime: currentTime
                    ) {
                        Text("Tempo rimasto:")
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .font(.footnote)

                        Text("\(remaining)")
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(timesUp ? Color(hex: "#f78457") : .white)
                            .font(.footnote)
                    }
                }
                .position(x: overlayFrame.midX, y: overlayFrame.midY)
                .zIndex(2)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            computeReservationStates()
        }
        .onChange(of: currentTime) {
            computeReservationStates()
        }
    }

    // MARK: - Precompute Reservation States
    private func computeReservationStates() {
        let activeReservation = cluster.reservationID

        // Check the cache first
        if let cachedState = stateCache.cache[activeReservation.id],
           cachedState.time == currentTime {
            // Use cached values if `currentTime` hasn't changed
            timesUp = cachedState.timesUp
            showedUp = cachedState.showedUp
            isLate = cachedState.isLate
            return
        }

        let calendar = Calendar.current

        // Compute `timesUp`
        let timesUpComputed: Bool
        if let startTime = activeReservation.startTimeDate,
           let endTime = activeReservation.endTimeDate {
            // Check if systemTime is within 30 minutes of the reservation end time
            let elapsedTime = systemTime.timeIntervalSince(startTime)
            let reservationDuration = endTime.timeIntervalSince(startTime)
            let isWithinEndWindow = endTime.timeIntervalSince(systemTime) <= 30 * 60
            let isSameDay = calendar.isDate(systemTime, inSameDayAs: startTime)

            timesUpComputed = isSameDay && elapsedTime <= reservationDuration && isWithinEndWindow
        } else {
            timesUpComputed = false
        }

        // Compute `showedUp`
        let showedUpComputed = activeReservation.status == .showedUp

        // Compute `isLate`
        let isLateComputed: Bool
        if activeReservation.status != .showedUp,
           let startTime = activeReservation.startTimeDate,
           let endTime = activeReservation.endTimeDate {
            let elapsedTime = systemTime.timeIntervalSince(startTime)
            let reservationDuration = endTime.timeIntervalSince(startTime)
            let isSameDay = calendar.isDate(systemTime, inSameDayAs: startTime)

            // Reservation is late if elapsed time >= 15 minutes but within the reservation duration
            isLateComputed = isSameDay && elapsedTime >= 15 * 60 && elapsedTime <= reservationDuration
        } else {
            isLateComputed = false
        }

        // Update states
        timesUp = timesUpComputed
        showedUp = showedUpComputed
        isLate = isLateComputed

        // Cache the computed values
        stateCache.cache[activeReservation.id] = ReservationState(
            time: systemTime,
            timesUp: timesUpComputed,
            showedUp: showedUpComputed,
            isLate: isLateComputed
        )
    }
}
