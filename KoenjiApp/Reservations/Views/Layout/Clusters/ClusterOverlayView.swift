//
//  ClusterOverlayView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/1/25.
//
import SwiftUI

struct ClusterOverlayView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(LayoutUnitViewModel.self) var unitView

    let cluster: CachedCluster
    let selectedCategory: Reservation.ReservationCategory
    let overlayFrame: CGRect
    @Binding var statusChanged: Int
    @Binding var selectedReservation: Reservation?
    
    @State private var systemTime: Date = Date()
    
    @State private var nearEndReservation: Reservation?
    @State private var currentReservation: Reservation?
        
    
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 12.0)
                .fill(.clear)
                .contentShape(Rectangle())
                .frame(width: cluster.frame.width, height: cluster.frame.height)
                .position(x: overlayFrame.midX, y: overlayFrame.midY)

            // Checkmark overlay for "showed up" status
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .position(x: cluster.frame.minX + 13, y: cluster.frame.minY + 13)
                    .opacity(currentReservation?.status == .showedUp ? 1 : 0)

            // Emoji overlay
            if let emoji = currentReservation?.assignedEmoji, emoji != "" {
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(maxWidth: 23, maxHeight: 23)
                    .position(x: cluster.frame.maxX - 18, y: cluster.frame.minY + 12)
            }

            // Warning overlay for reservations running late
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundColor(.yellow)
                    .symbolRenderingMode(.multicolor)
                    .position(x: cluster.frame.minX + 15, y: cluster.frame.minY + 15)
                    .opacity(currentReservation?.status == .late ? 1 : 0)

            // Warning overlay for "time's up"
                Image(systemName: "figure.walk.motion.trianglebadge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.yellow, .orange)
                    .symbolRenderingMode(.palette)
                    .position(x: cluster.frame.maxX - 15, y: cluster.frame.maxY - 15)
                    .zIndex(2)
                    .opacity(nearEndReservation != nil ? 1 : 0)
        }
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    handleDoubleTap()
                }
                .exclusively(before:
                    TapGesture()
                        .onEnded {
                            print("tapped!!!!")
                            if let reservation = currentReservation {
                                handleTap(reservation)
                            }
                        }
                )
                
        )
        .background(.clear)
        .onAppear {
            updateNearEndReservation()
            updateReservation()
        }
        .onChange(of: appState.selectedDate) { _, newDate in
            Task {
                do {
                    await MainActor.run {
                        updateNearEndReservation()
                        updateReservation()
                    }
                }
            }
        }
        .onChange(of: statusChanged) {
            updateReservation()
            print("Current reservation status: \(currentReservation?.status ?? .pending)")
        }
        .animation(.easeInOut(duration: 0.5), value: currentReservation?.status)
    }

    // MARK: - Precompute Reservation States
    private func updateNearEndReservation() {
        if env.resCache.nearingEndReservations(currentTime: appState.selectedDate).contains(where: {$0.id == cluster.reservationID.id }) {
            nearEndReservation = cluster.reservationID
        }
    }
    
    private func updateReservation() {
        currentReservation = env.resCache.reservation(
            forTable: cluster.tableIDs.first!, datetime: appState.selectedDate, category: appState.selectedCategory)
    }
    
    private func handleDoubleTap() {
        // Check if the table is occupied by filtering active reservations.
       
        unitView.showInspector = true
        selectedReservation = cluster.reservationID
        
    }
    
    private func handleTap(_ activeReservation: Reservation) {
        guard activeReservation == activeReservation else { return }
        var currentReservation = activeReservation
        let lateReservation = env.resCache.lateReservations(currentTime: appState.selectedDate).first(where: {
            $0.id == currentReservation.id
        })
        print("1 - Status in HandleTap: \(currentReservation.status)")
        if currentReservation.status == .pending || currentReservation.status == .late {
            currentReservation.status = .showedUp
            print("2 - Status in HandleTap: \(currentReservation.status)")
            
            Task {
                do {
                    env.reservationService.updateReservation(currentReservation) {
                        appState.changedReservation = currentReservation
                    }
                    
                }
            }
        } else if currentReservation.status == .showedUp {
            currentReservation.status =
            (lateReservation?.id == currentReservation.id ? .late : .pending)
            print("2 - Status in HandleTap: \(currentReservation.status)")
            
            Task {
                do {
                    env.reservationService.updateReservation(currentReservation) {
                        appState.changedReservation = currentReservation
                    }
                }
            }
        }
    }
}


