//
//  File.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//
import SwiftUI


struct ClusterView: View {

    let cluster: CachedCluster
    let overlayFrame: CGRect
    @Binding var currentTime: Date
    @State private var systemTime: Date = Date()
    @Binding var isLayoutLocked: Bool
    var isLunch: Bool
    @State var nearEndReservation: Reservation?

    // Precomputed states
    private var showedUp: Bool {
        return cluster.reservationID.status == .showedUp
    }
    private var isLate: Bool {
        return cluster.reservationID.status == .late
    }
    @EnvironmentObject var resCache: CurrentReservationsCache


    var body: some View {
        ZStack {
            if nearEndReservation == nil {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(isLunch ? Color.active_table_lunch : Color.active_table_dinner)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(
                                isLate ? Color(hex: "#f78457") : (showedUp ? .green : .white),
                                lineWidth: 3
                            )
                    )
                    .frame(width: overlayFrame.width, height: overlayFrame.height)
                    .position(x: overlayFrame.midX, y: overlayFrame.midY)
                    .zIndex(1)
                    .allowsHitTesting(false) // Ignore touch input
            } else {
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(isLunch ? Color.active_table_lunch : Color.active_table_dinner)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(.red,
                                lineWidth: 3
                            )
                    )
                    .frame(width: overlayFrame.width, height: overlayFrame.height)
                    .position(x: overlayFrame.midX, y: overlayFrame.midY)
                    .zIndex(1)
                    .allowsHitTesting(false) // Ignore touch input
            }

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
                        if nearEndReservation == nil {
                            Text("\(remaining)")
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .font(.footnote)
                        } else {
                            Text("\(remaining)")
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(hex: "#f78457"))
                                .font(.footnote)
                        }
                    }
                }
                .position(x: overlayFrame.midX, y: overlayFrame.midY)
                .zIndex(2)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            updateNearEndReservation()
        }
        .onChange(of: currentTime) {
            updateNearEndReservation()
        }
    }

    // MARK: - Precompute Reservation States
    
    private func updateNearEndReservation() {
        if resCache.nearingEndReservations(currentTime: currentTime).contains(where: {
            $0.id == cluster.reservationID.id
        }) {
            nearEndReservation = cluster.reservationID }
    }
}
