//
//  GroupSort.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 30/1/25.
//

import Foundation

struct GroupedReservations: Identifiable {
    let id = UUID()
    let label: String
    let reservations: [Reservation]
    let sortDate: Date?  // Used for date-based groupings
    let sortString: String?  // Used for non-date-based groupings (e.g., table names)
}

enum SortOption: String, CaseIterable {
    case alphabetically = "A-Z"
    case chronologically = "per_data"
    case byNumberOfPeople = "per_persone"
    case removeSorting = "nessuno"
    case byCreationDate = "per_ultime_aggiunte"
    
    var localized: String {
        switch self {
        case .alphabetically:
            return "A-Z"
        case .chronologically:
            return String(localized: "Per data")
        case .byNumberOfPeople:
            return String(localized: "Per persone")
        case .removeSorting:
            return String(localized: "Nessuno")
        case .byCreationDate:
            return String(localized: "Per ultime aggiunte")
        }
    }
}

enum GroupOption: String, CaseIterable {
    case none = "nessuno"
    case table = "per_tavolo"
    case day = "per_giorno"
    case week = "per_settimana"
    case month = "per_mese"
    
    var localized: String {
        switch self {
        case .none:
            return String(localized: "Nessuno")
        case .table:
            return String(localized: "Per tavolo")
        case .day:
            return String(localized: "Per giorno")
        case .week:
            return String(localized: "Per settimana")
        case .month:
            return String(localized: "Per mese")
        }
    }
}

enum FilterOption: String, CaseIterable {
    case none = "nessuno"
    case people = "per_numero_ospiti"
    case date = "per_data"
    case canceled = "cancellazioni"
    case toHandle = "in_sospeso"
    case deleted = "eliminate"
    case waitingList = "waiting_list"
    
    var localized: String {
        switch self {
        case .none:
            return String(localized: "Nessuno")
        case .people:
            return String(localized: "Per numero ospiti")
        case .date:
            return String(localized: "Per data")
        case .canceled:
            return String(localized: "Cancellazioni")
        case .toHandle:
            return String(localized: "In sospeso")
        case .deleted:
            return String(localized: "Eliminate")
        case .waitingList:
            return String(localized: "Waiting List")
        }
    }
}
