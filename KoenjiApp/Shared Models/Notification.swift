//
//  AppNotification.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 4/2/25.
//

import SwiftUI

enum NotificationType: Equatable {
    case late
    case nearEnd
    case canceled
    case restored
    case waitingList
    case sync
    case webReservation // New type for web reservations

}

/// A simple model representing a notification within your app.
struct AppNotification: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let date: Date = Date()
    let reservation: Reservation?
    let type: NotificationType
}

extension NotificationType {
    var localized: String {
        switch self {
        case .late:
            return String(localized: "ritardo")
        case .nearEnd:
            return String(localized: "scadenza")
        case .canceled:
            return String(localized: "cancellaz.")
        case .restored:
            return String(localized: "ripristino")
        case .waitingList:
            return String(localized: "waitinglist")
        case .sync:
            return String(localized: "sincro")
        case .webReservation:
            return String(localized: "web reservation")
        }
    }
}
