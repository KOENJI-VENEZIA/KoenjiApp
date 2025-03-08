//
//  WebReservationDeclineView.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import SwiftUI

struct WebReservationDeclineView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let reservation: Reservation
    var onDeclined: (() -> Void)?
    
    @State private var selectedReason: WebReservationDeclineReason = .capacityIssue
    @State private var customNotes: String = ""
    @State private var isDeclining = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView{
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Decline Web Reservation")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please select a reason")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Reservation summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(reservation.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            
                            Text("Web Request")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    // Date and party size
                    HStack(spacing: 16) {
                        Label {
                            Text(DateHelper.formatFullDate(reservation.normalizedDate ?? Date()))
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        
                        Label {
                            Text("\(reservation.numberOfPersons) people")
                        } icon: {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .font(.callout)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Decline reason selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select a Reason")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(WebReservationDeclineReason.allCases) { reason in
                        HStack {
                            Button(action: {
                                selectedReason = reason
                            }) {
                                HStack {
                                    Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(selectedReason == reason ? .red : .gray)
                                    
                                    Text(reason.displayText)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes (Optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $customNotes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                    Button(action: {
                        declineReservation()
                    }) {
                        if isDeclining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Decline Reservation")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(isDeclining)
                }
            }
        }
        .padding()
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Reservation Declined"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    dismiss()
                    onDeclined?()
                }
            )
        }
    }
    
    private func declineReservation() {
        isDeclining = true
        
        Task {
            let success = await env.reservationService.declineWebReservation(
                reservation,
                reason: selectedReason,
                customNotes: customNotes
            )
            
            await MainActor.run {
                isDeclining = false
                if success {
                    alertMessage = "Reservation has been declined successfully."
                    if reservation.emailAddress != nil {
                        alertMessage += " A notification email has been sent to the guest."
                    }
                } else {
                    alertMessage = "Failed to decline reservation. Please try again."
                }
                showingAlert = true
            }
            
        }
    }
}

//#Preview {
//    WebReservationDeclineView(reservation: Reservation.mockWebPending)
//        .environmentObject(AppDependencies.previewInstance)
//}
