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

  private var timesUp: Bool {
    let activeReservation = cluster.reservationID
    if let endTime = DateHelper.parseTime(activeReservation.endTime),
      let currentTimeComponents = DateHelper.extractTime(time: currentTime),
      let newTime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: endTime),
      endTime.timeIntervalSince(newTime) <= 60 * 30
    {
      return true
    }
    return false
  }

  private var showedUp: Bool {
    let activeReservation = cluster.reservationID
    if activeReservation.status == .showedUp {
      return true
    }
    return false
  }

  private var isLate: Bool {
    let activeReservation = cluster.reservationID
    if activeReservation.status != .showedUp,
      let startTime = DateHelper.parseTime(activeReservation.startTime),
      let currentTimeComponents = DateHelper.extractTime(time: currentTime),
      let newtime = DateHelper.normalizedInputTime(time: currentTimeComponents, date: startTime),
      newtime.timeIntervalSince(startTime) >= 15 * 60
    {
      return true
    }
    return false
  }

  var body: some View {

    ZStack {
      RoundedRectangle(cornerRadius: 8.0)
        .fill(isLunch ? Color.active_table_lunch : Color.active_table_dinner)
        .overlay(
          RoundedRectangle(cornerRadius: 8.0)
            .stroke(
              timesUp ? .red : (isLate ? Color(hex: "#f78457") : (showedUp ? .green : .white)),
              lineWidth: 3)
        )
        .frame(width: overlayFrame.width, height: overlayFrame.height)
        .position(x: overlayFrame.midX, y: overlayFrame.midY)
        .zIndex(1)
        .allowsHitTesting(false)  // Ignore touch input
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
            endTime: cluster.reservationID.endTime, currentTime: currentTime)
          {
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
  }
}
