//
//  TableModels.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

/// Represents a physical table in the restaurant.
struct TableModel: Identifiable, Hashable, Codable, Equatable {
    let id: Int
    let name: String
    let maxCapacity: Int

    var row: Int
    var column: Int

    /// Dimensions
    var width: Int { 3 }
    var height: Int { 3 }
    
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
    

    
    enum TableSide: CaseIterable {
        case top
        case bottom
        case left
        case right

        func offset() -> (rowOffset: Int, colOffset: Int) {
            switch self {
            case .top: return (-3, 0)
            case .bottom: return (3, 0)
            case .left: return (0, -3)
            case .right: return (0, 3)
            }
        }
    }
    
    
}

struct TableCluster: Equatable, Encodable, Decodable {
    var id: UUID = UUID() // Unique ID for each cluster
    let reservation: Reservation
    let tables: [TableModel]
}

struct CachedCluster: Equatable, Codable, Identifiable {
    let id: UUID
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
    var frame: CGRect

    init(
        id: UUID = UUID(), // Default to auto-generate if not provided
        reservationID: Reservation,
        tableIDs: [Int],
        date: Date,
        category: Reservation.ReservationCategory,
        frame: CGRect
    ) {
        self.id = id
        self.reservationID = reservationID
        self.tableIDs = tableIDs
        self.date = date
        self.category = category
        self.frame = frame
    }
}
