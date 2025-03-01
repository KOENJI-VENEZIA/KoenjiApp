//
//  ReservationRowView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//

import SwiftUI
import SwipeActions

struct ReservationRowView: View {
    let reservation: Reservation
    @Binding var notesAlertShown: Bool
    @Binding var notesToShow: String
    @Binding var currentReservation: Reservation?
    
    var onTap: () -> Void
    var onCancel: () -> Void
    var onRecover: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    var searchText: String
    
    var body: some View {
        let duration = reservation.duration
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12.0)
                .fill(.thinMaterial)
                .frame(maxWidth: 100, maxHeight: 100)
            SwipeView() {
                VStack(alignment: .leading, spacing: 4) {
                    if searchText.isEmpty {
                        Text("\(reservation.name) - \(reservation.numberOfPersons) p.")
                            .font(.headline)
                    } else {
                        highlightedText(for: reservation.name, with: searchText)
                        + Text(" - \(reservation.numberOfPersons) p.")
                            .font(.headline)
                    }
                    Text("Data: \(reservation.dateString)")
                        .font(.subheadline)
                    Text("Orario: \(reservation.startTime) - \(reservation.endTime)")
                        .font(.subheadline)
                    if !searchText.isEmpty {
                        if let notes = reservation.notes, !notes.isEmpty {
                            Text("Note:")
                                .font(.subheadline)
                                .bold()
                            highlightedText(for: notes, with: searchText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Durata: \(duration)")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: 100, maxHeight: 100, alignment: .leading)
                .padding()
                .contentShape(Rectangle())
            } trailingActions: { _ in
                if reservation.status != .canceled && reservation.status != .toHandle && reservation.reservationType != .waitingList  {
                    SwipeAction(systemImage: "x.circle.fill",
                                backgroundColor: Color(hex: "#5c140f")) {
                        onCancel()
                    }
                    .swipeActionLabelHorizontalPadding()
                } else {
                    SwipeAction(systemImage: "arrowshape.turn.up.backward.2.circle.fill",
                                backgroundColor: reservation.assignedColor) {
                        onRecover()
                    }
                    .swipeActionLabelHorizontalPadding()
                    .allowSwipeToTrigger()
                }
                
                if (reservation.status == .canceled || reservation.status == .toHandle) && reservation.status != .deleted {
                    SwipeAction(systemImage: "x.circle.fill",
                                backgroundColor: .black) {
                        onDelete()
                    }
                    .swipeActionLabelHorizontalPadding()
                }
            }
            .swipeActionCornerRadius(12)
            .swipeMinimumDistance(40)
            .swipeActionsMaskCornerRadius(12)
        }
        .padding()
    }
    
    private func highlightedText(for text: String, with searchText: String) -> Text {
        guard !searchText.isEmpty else { return Text(text) }
        let lowercasedText = text.lowercased()
        let lowercasedSearchText = searchText.lowercased()
        var highlighted = Text("")
        var currentIndex = lowercasedText.startIndex
        while let range = lowercasedText.range(of: lowercasedSearchText,
                                               range: currentIndex..<lowercasedText.endIndex) {
            let prefix = String(text[currentIndex..<range.lowerBound])
            highlighted = highlighted + Text(prefix)
            let match = String(text[range])
            highlighted = highlighted + Text(match).foregroundColor(.yellow)
            currentIndex = range.upperBound
        }
        let suffix = String(text[currentIndex..<lowercasedText.endIndex])
        highlighted = highlighted + Text(suffix)
        return highlighted
    }
}
