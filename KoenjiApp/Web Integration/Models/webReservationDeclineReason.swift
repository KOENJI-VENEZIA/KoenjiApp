//
//  WebReservationDeclineReason.swift
//  KoenjiApp
//
//  Created on 3/4/25.
//

import Foundation

/// Reasons for declining a web reservation
enum WebReservationDeclineReason: String, CaseIterable, Identifiable {
    case capacityIssue = "capacity_issue"
    case menuUnavailable = "menu_unavailable"
    case timeslotFull = "timeslot_full"
    case staffShortage = "staff_shortage"
    case technicalIssue = "technical_issue"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayText: String {
        switch self {
        case .capacityIssue:
            return String(localized: "We're at capacity for that time")
        case .menuUnavailable:
            return String(localized: "Special menu unavailable")
        case .timeslotFull:
            return String(localized: "Requested time slot is fully booked")
        case .staffShortage:
            return String(localized: "Staff shortage")
        case .technicalIssue:
            return String(localized: "Technical issue")
        case .other:
            return String(localized: "Other reason")
        }
    }
    
    var notesText: String {
        switch self {
        case .capacityIssue:
            return String(localized: "Declined: We've reached our capacity for the requested time.")
        case .menuUnavailable:
            return String(localized: "Declined: The requested special menu is unavailable for this date.")
        case .timeslotFull:
            return String(localized: "Declined: The requested time slot is fully booked.")
        case .staffShortage:
            return String(localized: "Declined: We're experiencing staff shortage for the requested date/time.")
        case .technicalIssue:
            return String(localized: "Declined: Technical issue with the reservation system.")
        case .other:
            return String(localized: "Declined: Unable to accommodate reservation.")
        }
    }
}
