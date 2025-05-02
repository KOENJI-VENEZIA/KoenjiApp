import Foundation

/// Model representing layout data for Firestore storage
public struct LayoutData: Identifiable, Codable, Sendable, EncodableWithID {
    /// Unique identifier for the layout (format: "YYYY-MM-DD-category")
    public let id: String
    /// The tables in this layout
    public let tables: [TableModel]
    
    /// Required by EncodableWithID protocol for Firestore
    public var documentID: String {
        return id
    }
} 