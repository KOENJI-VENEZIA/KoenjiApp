//
//  File.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//
import SwiftUI


struct ClusterView: View {
    @Environment(LayoutUnitViewModel.self) var unitView

    @State private var systemTime: Date = Date()

    
    @State var nearEndReservation: Reservation?
    @State private var cachedRemainingTime: String?
    @State private var tapTimer: Timer?
    @State private var isDoubleTap = false

    let cluster: CachedCluster
    let tables: [TableModel]
    let overlayFrame: CGRect
    @Binding var statusChanged: Int
    @Binding var selectedReservation: Reservation?
    var isLunch: Bool
    
    // Precomputed states
    private var showedUp: Bool {
        return cluster.reservationID.status == .showedUp
    }
    private var isLate: Bool {
        return cluster.reservationID.status == .late
    }
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    
    @Environment(\.colorScheme) var colorScheme


    var body: some View {
        
        ZStack {
            if nearEndReservation == nil {
                RoundedRectangle(cornerRadius: 12.0)
                    .fill(cluster.reservationID.assignedColor.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12.0)
                            .stroke(
                                isLate ? Color(hex: "#f78457") : (showedUp ? .green : .white),
                                lineWidth: 3
                            )
                    )
                    .frame(width: overlayFrame.width, height: overlayFrame.height)
                    .position(x: overlayFrame.midX, y: overlayFrame.midY)
            } else {
                RoundedRectangle(cornerRadius: 12.0)
                    .fill(cluster.reservationID.assignedColor.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8.0)
                            .stroke(.red,
                                lineWidth: 3
                            )
                    )
                    .frame(width: overlayFrame.width, height: overlayFrame.height)
                    .position(x: overlayFrame.midX, y: overlayFrame.midY)
            }

            // Reservation label (centered on the cluster)
            if cluster.tableIDs.first != nil {
                let overlayFrame = cluster.frame
                VStack(spacing: 4) {
                    Text(cluster.reservationID.name)
                        .bold()
                        .font(.headline)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)

                    Text("\(cluster.reservationID.numberOfPersons) p.")
                        .font(.footnote)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .opacity(0.8)

                    Text(cluster.reservationID.phone)
                        .font(.footnote)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .opacity(0.8)

                    if let remaining = cachedRemainingTime {
                        Text("Tempo rimasto:")
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.footnote)
                        if nearEndReservation == nil {
                            Text("\(remaining)")
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundStyle(colorScheme == .dark ? .white : .black)
                                .font(.footnote)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: cluster.frame.width-20, height: 20)
                                
                                Text("\(remaining)")
                                    .bold()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color(hex: "#bf5b34"))
                                    .font(.footnote)
                            }
                        }
                    }
                }
                .background(.clear)
                .position(x: overlayFrame.midX, y: overlayFrame.midY)
            }
        }
//        .highPriorityGesture(tapGesture())
//        .simultaneousGesture(doubleTapGesture())
        .onAppear {
            updateNearEndReservation()
            updateRemainingTime()
        }
        .onChange(of: appState.selectedDate) { _, newDate in
            Task {
                do {
                    await MainActor.run {
                        updateNearEndReservation()
                        updateRemainingTime()
                    }
                }
            }
        }
    }

    // MARK: - Precompute Reservation States
    
//    private func tapGesture() -> some Gesture {
//        TapGesture(count: 1).onEnded {
//            // Start a timer for single-tap action
//            tapTimer?.invalidate()  // Cancel any existing timer
//            tapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
//                Task { @MainActor in
//                    if !isDoubleTap {
//                        // Process single-tap only if no double-tap occurred
//                        handleTap(cluster.reservationID)
//                    }
//                }
//            }
//        }
//    }
    
    
    
    private func doubleTapGesture() -> some Gesture {
        TapGesture(count: 2).onEnded {
            // Cancel the single-tap timer and process double-tap
            tapTimer?.invalidate()
            isDoubleTap = true  // Prevent single-tap action
            
            
                handleDoubleTap()

            // Reset double-tap state shortly after handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isDoubleTap = false
            }
        }
    }
    
    private func handleDoubleTap() {
        // Check if the table is occupied by filtering active reservations.
       
        unitView.showInspector = true
        selectedReservation = cluster.reservationID
        
    }
    
    private func updateRemainingTime() {
        cachedRemainingTime = TimeHelpers.remainingTimeString(
            endTime: cluster.reservationID.endTimeDate ?? Date(),
            currentTime: appState.selectedDate
        )
    }
    
    private func updateNearEndReservation() {
        if env.resCache.nearingEndReservations(currentTime: appState.selectedDate).contains(where: {
            $0.id == cluster.reservationID.id
        }) {
            nearEndReservation = cluster.reservationID 
        }
    }
}
