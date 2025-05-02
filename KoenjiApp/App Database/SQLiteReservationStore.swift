import Foundation
@preconcurrency import Combine   // silence Sendable for Combine types
@preconcurrency import SQLite    // silence Sendable for SQLite.swift types

public actor SQLiteReservationStore: FirestoreDataStoreProtocol {
    nonisolated(unsafe) private let db: Connection
    private let queue = DispatchQueue(label: "db", qos: .utility)
    nonisolated(unsafe) private let subject = PassthroughSubject<[Reservation], Never>()

    public init() throws {
        // Open or create DB file in <App Documents>/Koenji.sqlite3
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Koenji.sqlite3")
        db = try Connection(url.path)

        // Create table if needed
        try db.run(ReservationColumns.reservations.create(ifNotExists: true) { t in
            t.column(ReservationColumns.id, primaryKey: true)
            t.column(ReservationColumns.name)
            t.column(ReservationColumns.phone)
            t.column(ReservationColumns.pax)
            t.column(ReservationColumns.dateString)
            t.column(ReservationColumns.category)
            t.column(ReservationColumns.startTime)
            t.column(ReservationColumns.endTime)
            t.column(ReservationColumns.acceptance)
            t.column(ReservationColumns.status)
            t.column(ReservationColumns.resType)
            t.column(ReservationColumns.group)
            t.column(ReservationColumns.tablesJSON)
            t.column(ReservationColumns.notes)
            t.column(ReservationColumns.creationDate)
            t.column(ReservationColumns.lastEditedOn)
            t.column(ReservationColumns.isMock)
            t.column(ReservationColumns.assignedEmoji)
            t.column(ReservationColumns.imageData)
            t.column(ReservationColumns.preferredLang)
        })
    }

    public nonisolated func publisher() -> AnyPublisher<[Reservation], Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: Stream all – one‑shot until we add DB notifications
    public func streamAll() async -> AsyncThrowingStream<[Reservation], Error> {
        AsyncThrowingStream { continuation in
            queue.async {
                do {
                    let rows = Array(try self.db.prepare(ReservationColumns.reservations))
                    let list = rows.compactMap(reservation(from:))
                    continuation.yield(list)
                    self.subject.send(list)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func upsert(_ r: Reservation) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    // Insert or replace
                    let json = try JSONEncoder().encode(r.tables).base64EncodedString()
                    let insert = ReservationColumns.reservations.insert(
                        or: .replace,
                        ReservationColumns.id            <- r.id.uuidString,
                        ReservationColumns.name          <- r.name,
                        ReservationColumns.phone         <- r.phone,
                        ReservationColumns.pax           <- r.numberOfPersons,
                        ReservationColumns.dateString    <- r.dateString,
                        ReservationColumns.category      <- r.category.rawValue,
                        ReservationColumns.startTime     <- r.startTime,
                        ReservationColumns.endTime       <- r.endTime,
                        ReservationColumns.acceptance    <- r.acceptance.rawValue,
                        ReservationColumns.status        <- r.status.rawValue,
                        ReservationColumns.resType       <- r.reservationType.rawValue,
                        ReservationColumns.group         <- r.group,
                        ReservationColumns.tablesJSON    <- json,
                        ReservationColumns.notes         <- r.notes,
                        ReservationColumns.creationDate  <- r.creationDate.timeIntervalSince1970,
                        ReservationColumns.lastEditedOn  <- r.lastEditedOn.timeIntervalSince1970,
                        ReservationColumns.isMock        <- r.isMock,
                        ReservationColumns.assignedEmoji <- r.assignedEmoji,
                        ReservationColumns.imageData     <- r.imageData,
                        ReservationColumns.preferredLang <- r.preferredLanguage
                    )
                    try self.db.run(insert)

                    let rows = Array(try self.db.prepare(ReservationColumns.reservations))
                    let updated = rows.compactMap(reservation(from:))
                    self.subject.send(updated)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    public func delete(id: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    let query = ReservationColumns.reservations
                        .filter(ReservationColumns.id == id)
                    try self.db.run(query.delete())

                    let rows = Array(try self.db.prepare(ReservationColumns.reservations))
                    let updated = rows.compactMap(reservation(from:))
                    self.subject.send(updated)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Preview fake -------------------------------------------------

extension SQLiteReservationStore {
    /// Lightweight in‑memory actor for SwiftUI previews
    public static func previewFake(initial: [Reservation] = []) -> some FirestoreDataStoreProtocol {
        actor PreviewStore: FirestoreDataStoreProtocol {
            private var data: [Reservation]

            init(seed: [Reservation]) { self.data = seed }

            func streamAll() async -> AsyncThrowingStream<[Reservation], Error> {
                AsyncThrowingStream { continuation in
                    continuation.yield(data)
                    continuation.finish()
                }
            }

            func upsert(_ r: Reservation) async throws {
                if let idx = data.firstIndex(where: { $0.id == r.id }) {
                    data[idx] = r
                } else {
                    data.append(r)
                }
            }

            func delete(id: String) async throws {
                data.removeAll { $0.id.uuidString == id }
            }
        }
        return PreviewStore(seed: initial)
    }
}