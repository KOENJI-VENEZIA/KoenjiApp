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
    @Binding var isLayoutLocked: Bool
    var isLunch: Bool
    
    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 8.0)
                .fill(isLunch ? Color.active_table_lunch : Color.active_table_dinner)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.0)
                        .stroke(isLayoutLocked ? (isLunch ? Color.layout_locked_lunch : Color.layout_locked_dinner) : (isLunch ? Color.layout_unlocked_lunch : Color.layout_unlocked_dinner), lineWidth: isLayoutLocked ? 3 : 2))
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
                        .foregroundColor(.white)
                    Text("\(cluster.reservationID.numberOfPersons) pers.")
                        .font(.footnote)
                        .opacity(0.8)
                    Text(cluster.reservationID.phone)
                        .font(.footnote)
                        .opacity(0.8)
                    if let remaining = TimeHelpers.remainingTimeString(endTime: cluster.reservationID.endTime, currentTime: currentTime) {
                        Text("Rimasto: \(remaining)")
                            .foregroundColor(Color(hex: "#B4231F"))
                            .font(.footnote)
                    }
                    if let duration = TimeHelpers.availableTimeString(endTime: cluster.reservationID.endTime, startTime: cluster.reservationID.startTime) {
                        Text("\(duration)")
                            .foregroundColor(Color(hex: "#B4231F"))
                            .font(.footnote)
                    }
                }
                .position(x: overlayFrame.midX, y: overlayFrame.midY)
                .zIndex(2)
            }
        }
        
        .allowsHitTesting(false)
    }
}
