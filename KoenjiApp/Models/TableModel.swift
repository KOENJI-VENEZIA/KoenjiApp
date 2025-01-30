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
    
    var isVisible: Bool = true
    
    enum CodingKeys: String, CodingKey {
           case id, name, maxCapacity, row, column, adjacentCount, activeReservationAdjacentCount, isVisible
       }

       
    
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

extension TableModel {
    // ✅ Custom decoder to handle missing `isVisible`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        maxCapacity = try container.decode(Int.self, forKey: .maxCapacity)
        row = try container.decode(Int.self, forKey: .row)
        column = try container.decode(Int.self, forKey: .column)
        adjacentCount = try container.decodeIfPresent(Int.self, forKey: .adjacentCount) ?? 0
        activeReservationAdjacentCount = try container.decodeIfPresent(Int.self, forKey: .activeReservationAdjacentCount) ?? 0
        isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true  // ✅ Default value if missing
    }

    // ✅ Custom encoder to ensure `isVisible` is always encoded
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(maxCapacity, forKey: .maxCapacity)
        try container.encode(row, forKey: .row)
        try container.encode(column, forKey: .column)
        try container.encode(adjacentCount, forKey: .adjacentCount)
        try container.encode(activeReservationAdjacentCount, forKey: .activeReservationAdjacentCount)
        try container.encode(isVisible, forKey: .isVisible)  // ✅ Always encode `isVisible`
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
