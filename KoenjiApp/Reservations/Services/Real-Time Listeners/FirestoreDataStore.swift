import FirebaseFirestore
import SwiftfulFirestore
import Foundation
import Logging

public protocol FirestoreDataStoreProtocol<T> {
    associatedtype T: Codable & Sendable
    func streamAll() async -> AsyncThrowingStream<[T], Error>
    func upsert(_ document: T) async throws
    func delete(id: String) async throws
}

public actor FirestoreDataStore<T: Codable & Sendable>: FirestoreDataStoreProtocol {
    private let db: Firestore = Firestore.firestore()
    public var collection: CollectionReference
    
    // Helper class for holding listeners in sendable contexts
    private final class ListenerHolder: @unchecked Sendable {
        var listener: ListenerRegistration?
    }
    
    public init(collectionName: String) {
        #if DEBUG
        self.collection = db.collection(collectionName)
        #else
        self.collection = db.collection(collectionName + "_release")
        #endif
    }
    
    public init(customCollection: CollectionReference) {
        self.collection = customCollection
    }

    public func getAllReservations() async -> [Reservation] {
        do {
            let snapshot = try await collection.getDocuments()
            return snapshot.documents.compactMap { document -> Reservation? in
                do {
                    return try ReservationMapper.decode(from: document)
                } catch {
                    return nil
                }
            }
        } catch {
            print("Error getting documents: \(error.localizedDescription)")
            return []
        }
    }

    public func streamAll() async -> AsyncThrowingStream<[T], Error> {
        if T.self == Reservation.self {
            // Use custom mapper for Reservation type
            return AsyncThrowingStream<[T], Error> { continuation in
                let holder = ListenerHolder()
                
                holder.listener = collection.addSnapshotListener { snapshot, error in
                    if let error = error {
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    
                    // Handle all errors inside - no throws allowed
                    let reservations = documents.compactMap { document -> Reservation? in
                        do {
                            return try ReservationMapper.decode(from: document)
                        } catch {
                            print("Error decoding document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    continuation.yield(reservations as! [T])
                }
                
                continuation.onTermination = { @Sendable _ in
                    holder.listener?.remove()
                }
            }
        }
        
        // Use SwiftfulFirestore's default implementation for other types
        return collection.streamAllDocuments() as AsyncThrowingStream<[T], Error>
    }

    public func upsert(_ document: T) async throws {
        // For this to work, the document needs an 'id' property we can access
        // Implementation will depend on how you want to handle document IDs
        if let encodableDoc = document as? EncodableWithID {
            try await collection.setDocument(id: encodableDoc.documentID, document: document)
        } else {
            throw NSError(domain: "com.koenjiapp", code: 100, 
                         userInfo: [NSLocalizedDescriptionKey: "Document must conform to EncodableWithID protocol"])
        }
    }

    public func delete(id: String) async throws {
        try await collection.deleteDocument(id: id)
    }
    
    /// Gets all documents from the collection
    /// - Returns: Array of documents of type T
    public func getAll() async throws -> [T] {
        if T.self == Reservation.self {
            // For Reservation type, use custom mapper
            let snapshot = try await collection.getDocuments()
            let reservations = snapshot.documents.compactMap { document -> Reservation? in
                do {
                    return try ReservationMapper.decode(from: document)
                } catch {
                    print("Error decoding document \(document.documentID): \(error.localizedDescription)")
                    return nil
                }
            }
            return reservations as! [T]
        } else {
            // For other types, use SwiftfulFirestore
            let snapshot = try await collection.getDocuments()
            return try snapshot.documents.compactMap { document in
                try document.data(as: T.self)
            }
        }
    }
    
    /// Deletes all documents in the collection
    /// - Returns: The number of documents deleted
    public func deleteAllDocuments() async throws -> Int {
        // Get snapshot first (outside of batch operations)
        let snapshot = try await collection.getDocuments()
        let count = snapshot.documents.count
        
        if count > 0 {
            // Use withCheckedThrowingContinuation for safe batch handling
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let batch = db.batch()
                
                // Add all documents to batch
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                
                // Commit without crossing await boundaries
                batch.commit { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
        
        return count
    }
}

// Protocol to ensure documents have an accessible ID
public protocol EncodableWithID: Codable {
    var documentID: String { get }
}

// Example extension for Reservation
extension Reservation: EncodableWithID {
    public var documentID: String {
        return id.uuidString
    }
}

// Backward compatibility type alias
public typealias FirebaseReservationStore = FirestoreDataStore<Reservation>