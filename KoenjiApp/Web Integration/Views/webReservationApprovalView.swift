//
//  WebReservationApprovalView.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import SwiftUI

struct WebReservationApprovalView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let reservation: Reservation
    var onApprove: (() -> Void)?
    var onDecline: (() -> Void)?
    
    @State private var isApproving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeclineView = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Web Reservation Request")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Waiting for Approval")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Reservation details card
            VStack(alignment: .leading, spacing: 16) {
                // Name and status
                HStack {
                    Text(reservation.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text("Pending Approval")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Divider()
                
                // Date and time
                HStack(spacing: 24) {
                    detailItem(
                        icon: "calendar",
                        title: "Date",
                        value: DateHelper.formatFullDate(reservation.normalizedDate ?? Date())
                    )
                    
                    detailItem(
                        icon: "clock.fill",
                        title: "Time",
                        value: "\(reservation.startTime) - \(reservation.endTime)"
                    )
                }
                
                // Party size and contact
                HStack(spacing: 24) {
                    detailItem(
                        icon: "person.2.fill",
                        title: "Party Size",
                        value: "\(reservation.numberOfPersons) people"
                    )
                    
                    detailItem(
                        icon: "phone.fill",
                        title: "Phone",
                        value: reservation.phone
                    )
                }
                
                // Email if available
                if let email = reservation.emailAddress {
                    detailItem(
                        icon: "envelope.fill",
                        title: "Email",
                        value: email
                    )
                }
                
                // Notes
                if let notes = reservation.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(notes.replacingOccurrences(of: "Email: \\S+@\\S+\\.\\S+", with: "", options: .regularExpression)
                                 .replacingOccurrences(of: "[web reservation];", with: "")
                                 .trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    showingDeclineView = true
                }) {
                    Text("Decline")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    approveReservation()
                }) {
                    if isApproving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Approve")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isApproving)
            }
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reservation Approval"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        onApprove?()
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showingDeclineView) {
            WebReservationDeclineView(
                reservation: reservation,
                onDeclined: {
                    onDecline?()
                    dismiss()
                }
            )
            .environmentObject(env)
        }
    }
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func approveReservation() {
        isApproving = true
        
        Task {
            let success = await env.reservationService.approveWebReservation(reservation)
            
            await MainActor.run {
                isApproving = false
                if success {
                    alertMessage = "Reservation approved successfully! A confirmation email has been sent to the guest."
                } else {
                    alertMessage = "Failed to approve reservation. Please try again."
                }
                showingAlert = true
            }
        }
    }
}
//
//#Preview {
//    WebReservationApprovalView(reservation: Reservation.mockWebPending)
//        .environmentObject(AppDependencies.previewInstance)
//}
