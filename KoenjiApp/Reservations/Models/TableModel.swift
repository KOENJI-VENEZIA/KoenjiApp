//
//  TableModels.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI
import os

/// Represents a physical table in the restaurant.
struct TableModel: Identifiable, Hashable, Codable, Equatable {
    // MARK: - Private Properties
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.koenjiapp",
        category: "TableModel"
    )
    
    // MARK: - Public Properties
    let id: Int
    let name: String
    let maxCapacity: Int
    var row: Int
    var column: Int
    var adjacentCount: Int = 0
    var activeReservationAdjacentCount: Int = 0
    var isVisible: Bool = true

    // MARK: - Computed Properties
    var width: Int { 3 }
    var height: Int { 3 }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, maxCapacity, row, column, adjacentCount, activeReservationAdjacentCount, isVisible
    }
    
    // MARK: - Table Side Enum
    enum TableSide: CaseIterable {
        case top, bottom, left, right

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

// MARK: - Codable Implementation
extension TableModel {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try container.decode(Int.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            maxCapacity = try container.decode(Int.self, forKey: .maxCapacity)
            row = try container.decode(Int.self, forKey: .row)
            column = try container.decode(Int.self, forKey: .column)
            adjacentCount = try container.decodeIfPresent(Int.self, forKey: .adjacentCount) ?? 0
            activeReservationAdjacentCount = try container.decodeIfPresent(Int.self, forKey: .activeReservationAdjacentCount) ?? 0
            isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
            
            let nameCopy = name
            let idCopy = id
            TableModel.logger.debug("Successfully decoded table: \(nameCopy) (ID: \(idCopy))")
        } catch {
            TableModel.logger.error("Failed to decode table: \(error.localizedDescription)")
            throw error
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        do {
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(maxCapacity, forKey: .maxCapacity)
            try container.encode(row, forKey: .row)
            try container.encode(column, forKey: .column)
            try container.encode(adjacentCount, forKey: .adjacentCount)
            try container.encode(activeReservationAdjacentCount, forKey: .activeReservationAdjacentCount)
            try container.encode(isVisible, forKey: .isVisible)
            
            TableModel.logger.debug("Successfully encoded table: \(name) (ID: \(id))")
        } catch {
            TableModel.logger.error("Failed to encode table: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Related Models
struct TableCluster: Equatable, Encodable, Decodable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TableCluster")
    // MARK: - Properties
    var id: UUID = UUID()
    let reservation: Reservation
    let tables: [TableModel]
    
    init(id: UUID = UUID(), reservation: Reservation, tables: [TableModel]) {
        self.id = id
        self.reservation = reservation
        self.tables = tables
        TableCluster.logger.debug("Created cluster for reservation: \(reservation.name) with \(tables.count) tables")
    }
}

struct CachedCluster: Equatable, Codable, Identifiable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "CachedCluster")
    // MARK: - Properties
    let id: UUID
    let reservationID: Reservation
    let tableIDs: [Int]
    let date: Date
    let category: Reservation.ReservationCategory
    var frame: CGRect
    
    init(
        id: UUID = UUID(),
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
        
        CachedCluster.logger.debug("Created cached cluster for reservation: \(reservationID.name) with \(tableIDs.count) tables")
    }
}
