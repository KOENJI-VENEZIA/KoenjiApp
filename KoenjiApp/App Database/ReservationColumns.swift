//
//  ReservationColumns.swift
//  KoenjiApp
//
//  Auto-generated during concurrency refactor – 27 Apr 2025
//

@preconcurrency import SQLite   // suppress Sendable warnings for SQLite.swift types
import Foundation

/// Strongly-typed SQLite column expressions reused by the store
/// and mapper helpers.
enum ReservationColumns: @unchecked Sendable {
    static let reservations  = Table("reservations")

    // Primary key
    static let id            = Expression<String>("id")               // UUID string

    // Scalars
    static let name          = Expression<String>("name")
    static let phone         = Expression<String>("phone")
    static let pax           = Expression<Int>("numberOfPersons")
    static let dateString    = Expression<String>("dateString")
    static let category      = Expression<String>("category")
    static let startTime     = Expression<String>("startTime")
    static let endTime       = Expression<String>("endTime")
    static let acceptance    = Expression<String>("acceptance")
    static let status        = Expression<String>("status")
    static let resType       = Expression<String>("reservationType")
    static let group         = Expression<Bool>("group")

    // JSON blobs / optionals stored as TEXT
    static let tablesJSON    = Expression<String?>("tables")
    static let notes         = Expression<String?>("notes")

    // Timestamps
    static let creationDate  = Expression<Double>("creationDate")
    static let lastEditedOn  = Expression<Double>("lastEditedOn")

    // Misc
    static let isMock        = Expression<Bool>("isMock")
    static let assignedEmoji = Expression<String?>("assignedEmoji")
    static let imageData     = Expression<Data?>("imageData")
    static let preferredLang = Expression<String?>("preferredLanguage")
}