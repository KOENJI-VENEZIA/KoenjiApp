//
//  ClusterOverlayView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//
import SwiftUI

struct ClusterOverlayView: View {
    let cluster: CachedCluster
    let selectedCategory: Reservation.ReservationCategory
    let overlayFrame: CGRect
    @Binding var statusChanged: Int
    @State private var systemTime: Date = Date()
    
    @State private var nearEndReservation: Reservation?
    
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var reservationService: ReservationService
    
    @State var currentReservation: Reservation? = nil
    
    
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 12.0)
                .fill(.clear)
                .contentShape(Rectangle())
                .frame(width: cluster.frame.width, height: cluster.frame.height)
                .position(x: overlayFrame.midX, y: overlayFrame.midY)

            // Checkmark overlay for "showed up" status
            if currentReservation?.status == .showedUp {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .position(x: cluster.frame.minX + 13, y: cluster.frame.minY + 13)
            }

            // Emoji overlay
            if let emoji = currentReservation?.assignedEmoji {
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(maxWidth: 23, maxHeight: 23)
                    .position(x: cluster.frame.maxX - 18, y: cluster.frame.minY + 12)
            }

            // Warning overlay for reservations running late
            if currentReservation?.status == .late {
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
        .gesture(
            TapGesture()
            .onEnded {
                print("tapped!!!!")
                if let reservation = currentReservation {
                    handleTap(reservation)
                }
                
            }
        )
        .background(.clear)
        .onAppear {
            updateNearEndReservation()
            currentReservation = resCache.activeReservations.first(where: { $0.id == cluster.reservationID.id })
        }
        .onChange(of: appState.selectedDate) {
            updateNearEndReservation()
            currentReservation = cluster.tableIDs.compactMap {
                resCache.reservation(forTable: $0, datetime: appState.selectedDate, category: selectedCategory)
            }.first
        }
        .onChange(of: statusChanged) {
            currentReservation = cluster.tableIDs.compactMap {
                resCache.reservation(forTable: $0, datetime: appState.selectedDate, category: selectedCategory)
            }.first
            
            print("Current reservation status: \(currentReservation?.status ?? .pending)")
        }
        .animation(.easeInOut(duration: 0.5), value: currentReservation?.status)
    }

    // MARK: - Precompute Reservation States
    private func updateNearEndReservation() {
        if resCache.nearingEndReservations(currentTime: appState.selectedDate).contains(where: {$0.id == cluster.reservationID.id }) {
            nearEndReservation = cluster.reservationID
        }
    }
    
    private func handleTap(_ activeReservation: Reservation?) {
        guard let activeReservation = activeReservation else { return }

        let oldReservation = activeReservation
        var currentReservation = activeReservation

        print("1 - Status in HandleTap: \(currentReservation.status)")

        if currentReservation.status == .pending || currentReservation.status == .late {
            // Case 1: Update to .showedUp
            currentReservation.status = .showedUp

            print("2 - Status in HandleTap: \(currentReservation.status)")
            reservationService.updateReservation(oldReservation, newReservation: currentReservation)  // Ensure the data store is updated
            statusChanged += 1
            
        } else {
            // Case 2: Determine if the reservation is late or pending
            if resCache.lateReservations(currentTime: appState.selectedDate).first(where: {
                $0.id == currentReservation.id
            }) != nil {
                currentReservation.status = .late
            } else {
                currentReservation.status = .pending
            }

            print("2 - Status in HandleTap: \(currentReservation.status)")
            reservationService.updateReservation(oldReservation, newReservation: currentReservation)  // Ensure the data store is updated
            statusChanged += 1

        }
    }
}

