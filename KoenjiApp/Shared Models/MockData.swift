import Foundation
import SwiftUI

/// A class that provides mock data for previews
///
/// This class contains static methods and properties that provide mock data
/// for use in SwiftUI previews. It includes mock reservations, profiles, and sessions.
class MockData {
    // MARK: - Mock Reservations
    
    /// A collection of mock reservations for previews
    static var mockReservations: [Reservation] {
        [
            createReservation(
                name: "Mario Rossi",
                phone: "+39 123 456 7890",
                persons: 4,
                date: Date().addingTimeInterval(3600 * 24), // Tomorrow
                startTime: "20:00",
                endTime: "22:00",
                category: .dinner,
                type: .inAdvance,
                status: .pending,
                acceptance: .confirmed,
                notes: "Compleanno, tavolo vicino alla finestra"
            ),
            createReservation(
                name: "Giulia Bianchi",
                phone: "+39 234 567 8901",
                persons: 2,
                date: Date(), // Today
                startTime: "13:00",
                endTime: "14:30",
                category: .lunch,
                type: .inAdvance,
                status: .pending,
                acceptance: .confirmed,
                notes: "Allergia ai frutti di mare"
            ),
            createReservation(
                name: "Luca Verdi",
                phone: "+39 345 678 9012",
                persons: 6,
                date: Date().addingTimeInterval(3600 * 48), // Day after tomorrow
                startTime: "19:30",
                endTime: "22:00",
                category: .dinner,
                type: .inAdvance,
                status: .pending,
                acceptance: .confirmed,
                notes: "Gruppo aziendale, preferisce tavolo riservato"
            ),
            createReservation(
                name: "Sofia Neri",
                phone: "+39 456 789 0123",
                persons: 3,
                date: Date(), // Today
                startTime: "20:30",
                endTime: "22:30",
                category: .dinner,
                type: .inAdvance,
                status: .pending,
                acceptance: .toConfirm,
                notes: "[web reservation]; email: sofia@example.com"
            ),
            createReservation(
                name: "Marco Gialli",
                phone: "+39 567 890 1234",
                persons: 2,
                date: Date().addingTimeInterval(-3600 * 24), // Yesterday
                startTime: "19:00",
                endTime: "21:00",
                category: .dinner,
                type: .inAdvance,
                status: .pending,
                acceptance: .confirmed,
                notes: "Anniversario"
            ),
            createReservation(
                name: "Marco Gialli",
                phone: "+39 567 890 1234",
                persons: 2,
                date: Date().addingTimeInterval(-3600 * 24), // Yesterday
                startTime: "19:00",
                endTime: "21:00",
                category: .dinner,
                type: .inAdvance,
                status: .na,
                acceptance: .toConfirm,
                notes: "Anniversario; [web reservation]; email: <marco@example.com>"
            )
        ]
    }
    
    /// Creates a mock reservation with the specified properties
    ///
    /// - Parameters:
    ///   - name: The name of the reservation
    ///   - phone: The phone number
    ///   - persons: The number of persons
    ///   - date: The date of the reservation
    ///   - startTime: The start time (HH:MM)
    ///   - endTime: The end time (HH:MM)
    ///   - category: The reservation category
    ///   - status: The reservation status
    ///   - notes: Any notes for the reservation
    /// - Returns: A mock reservation
    static func createReservation(
        name: String,
        phone: String,
        persons: Int,
        date: Date,
        startTime: String,
        endTime: String,
        category: Reservation.ReservationCategory,
        type: Reservation.ReservationType,
        status: Reservation.ReservationStatus,
        acceptance: Reservation.Acceptance,
        notes: String
    ) -> Reservation {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return Reservation(
            id: UUID(),
            name: name,
            phone: phone,
            numberOfPersons: persons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: type,
            group: false,
            notes: notes,
            tables: [],
            creationDate: Date().addingTimeInterval(-3600 * 24 * 7), // A week ago
            lastEditedOn: Date(),
            isMock: true,
            assignedEmoji: "🍽️",
            imageData: nil,
            preferredLanguage: "it"
        )
    }
    
    // MARK: - Mock Profiles
    
    /// A mock profile for previews
    static var mockProfile: Profile {
        Profile(
            id: "mock-profile-id",
            firstName: "Mario",
            lastName: "Rossi",
            email: "mario.rossi@example.com",
            imageURL: nil,
            devices: [mockDevice],
            createdAt: Date().addingTimeInterval(-3600 * 24 * 30), // A month ago
            updatedAt: Date()
        )
    }
    
    /// A mock device for previews
    static var mockDevice: Device {
        Device(
            id: "mock-device-id",
            name: "iPhone di Mario",
            lastActive: Date(),
            isActive: true
        )
    }
    
    // MARK: - Mock Sessions
    
    /// A collection of mock sessions for previews
    static var mockSessions: [Session] {
        [
            Session(
                id: "mock-profile-id",
                uuid: "mock-device-id",
                userName: "Mario R.",
                isEditing: false,
                lastUpdate: Date(),
                isActive: true,
                deviceName: "iPhone di Mario",
                profileImageURL: nil
            ),
            Session(
                id: "mock-profile-id-2",
                uuid: "mock-device-id-2",
                userName: "Giulia B.",
                isEditing: true,
                lastUpdate: Date(),
                isActive: true,
                deviceName: "iPad di Giulia",
                profileImageURL: nil
            )
        ]
    }
} 
