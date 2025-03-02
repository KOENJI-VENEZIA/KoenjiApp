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
    case chronologically = "Per data"
    case byNumberOfPeople = "Per persone"
    case removeSorting = "Nessuno"
}

enum GroupOption: String, CaseIterable {
    case none = "Nessuno"
    case table = "Per tavolo"
    case day = "Per giorno"
    case week = "Per settimana"
    case month = "Per mese"
}

enum FilterOption: String, CaseIterable {
    case none = "Nessuno"
    case people = "Per numero ospiti"
    case date = "Per data"
    case canceled = "Cancellazioni"
    case toHandle = "In sospeso"
    case deleted = "Eliminate"
    case waitingList = "Waiting List"
}
