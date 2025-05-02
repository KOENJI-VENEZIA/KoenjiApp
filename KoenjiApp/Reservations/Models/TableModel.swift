//
//  TableModels.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI
import os

/// Represents a physical table in the restaurant.
public struct TableModel: Identifiable, Hashable, Codable, Equatable, Sendable {
    // MARK: - Private Properties
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.koenjiapp",
        category: "TableModel"
    )
    
    // MARK: - Public Properties
    public let id: Int
    public let name: String
    public let maxCapacity: Int
    public var row: Int
    public var column: Int
    public var adjacentCount: Int = 0
    public var activeReservationAdjacentCount: Int = 0
    public var isVisible: Bool = true

    // MARK: - Computed Properties
    public var width: Int { 3 }
    public var height: Int { 3 }
    
    // MARK: - Initializers
    public init(
        id: Int,
        name: String,
        maxCapacity: Int,
        row: Int,
        column: Int,
        adjacentCount: Int = 0,
        activeReservationAdjacentCount: Int = 0,
        isVisible: Bool = true
    ) {
        self.id = id
        self.name = name
        self.maxCapacity = maxCapacity
        self.row = row
        self.column = column
        self.adjacentCount = adjacentCount
        self.activeReservationAdjacentCount = activeReservationAdjacentCount
        self.isVisible = isVisible
        
        TableModel.logger.debug("Created table: \(name) (ID: \(id)) at position (\(row), \(column))")
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, name, maxCapacity, row, column, adjacentCount, activeReservationAdjacentCount, isVisible
    }
    
    // MARK: - Table Side Enum
    public enum TableSide: CaseIterable {
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
    public init(from decoder: Decoder) throws {
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

    public func encode(to encoder: Encoder) throws {
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

// MARK: - EncodableWithID Implementation
extension TableModel: EncodableWithID {
    public var documentID: String {
        return String(id)
    }
}

// MARK: - Table Convenience Methods
extension TableModel {
    /// Determines if this table is adjacent to another table
    /// - Parameter other: The other table to check
    /// - Returns: True if the tables are adjacent, false otherwise
    public func isAdjacentTo(_ other: TableModel) -> Bool {
        // Check if tables are horizontally adjacent
        let horizontallyAdjacent = abs(self.column - other.column) <= self.width && 
                                  abs(self.row - other.row) == self.height
        
        // Check if tables are vertically adjacent
        let verticallyAdjacent = abs(self.row - other.row) <= self.height && 
                                abs(self.column - other.column) == self.width
        
        return horizontallyAdjacent || verticallyAdjacent
    }
    
    /// Get the side where this table is adjacent to another table
    /// - Parameter other: The other table to check
    /// - Returns: The table side if adjacent, nil otherwise
    public func getAdjacentSide(to other: TableModel) -> TableSide? {
        // Check top
        if other.row + other.height == self.row && 
           abs(other.column - self.column) < self.width {
            return .top
        }
        
        // Check bottom
        if self.row + self.height == other.row && 
           abs(other.column - self.column) < self.width {
            return .bottom
        }
        
        // Check left
        if other.column + other.width == self.column && 
           abs(other.row - self.row) < self.height {
            return .left
        }
        
        // Check right
        if self.column + self.width == other.column && 
           abs(other.row - self.row) < self.height {
            return .right
        }
        
        return nil
    }
    
    /// Creates a bounding rectangle for the table in grid coordinates
    /// - Returns: CGRect representing the table bounds
    public func boundingRect() -> CGRect {
        return CGRect(x: column, y: row, width: width, height: height)
    }
}

// MARK: - Related Models
public struct TableCluster: Equatable, Encodable, Decodable, Sendable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "TableCluster")
    // MARK: - Properties
    public var id: UUID = UUID()
    public let reservation: Reservation
    public let tables: [TableModel]
    
    public init(id: UUID = UUID(), reservation: Reservation, tables: [TableModel]) {
        self.id = id
        self.reservation = reservation
        self.tables = tables
        TableCluster.logger.debug("Created cluster for reservation: \(reservation.name) with \(tables.count) tables")
    }
}

public struct CachedCluster: Equatable, Codable, Identifiable, Sendable {
    static let logger = Logger(subsystem: "com.koenjiapp", category: "CachedCluster")
    // MARK: - Properties
    public let id: UUID
    public let reservationID: Reservation
    public let tableIDs: [Int]
    public let date: Date
    public let category: Reservation.ReservationCategory
    public var frame: CGRect
    
    public init(
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
