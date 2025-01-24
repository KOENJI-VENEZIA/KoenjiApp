//
//  ReservationsDocument.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//


import SwiftUI
import UniformTypeIdentifiers

struct ReservationsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var reservations: [Reservation]
    
    init(reservations: [Reservation]) {
        self.reservations = reservations
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.reservations = try decoder.decode([Reservation].self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(reservations)
        return FileWrapper(regularFileWithContents: data)
    }
}
