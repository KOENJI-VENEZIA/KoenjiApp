//
//  ReservationsDocument.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//


import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct ReservationsDocument: FileDocument {
    // MARK: - Static Properties
    static var readableContentTypes: [UTType] { [.json] }
    static let logger = Logger(subsystem: "com.koenjiapp", category: "ReservationsDocument")

    // MARK: - Public Properties
    var reservations: [Reservation]
    
    // MARK: - Initialization
    init(reservations: [Reservation]) {
        self.reservations = reservations
        ReservationsDocument.logger.debug("Created document with \(reservations.count) reservations")
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            ReservationsDocument.logger.error("Failed to read file contents")
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            self.reservations = try decoder.decode([Reservation].self, from: data)
            ReservationsDocument.logger.info("Successfully decoded reservations from file")
        } catch {
            ReservationsDocument.logger.error("Failed to decode reservations: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - File Operations
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(reservations)
            ReservationsDocument.logger.info("Successfully encoded \(reservations.count) reservations to file")
            return FileWrapper(regularFileWithContents: data)
        } catch {
            ReservationsDocument.logger.error("Failed to encode reservations: \(error.localizedDescription)")
            throw error
        }
    }
}
