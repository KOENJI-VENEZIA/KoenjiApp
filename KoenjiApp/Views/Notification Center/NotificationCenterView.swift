//
//  NotificationCenterView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 4/2/25.
//

import SwiftUI

struct NotificationCenterView: View {
    
    @EnvironmentObject var notifsManager: MockNotifManager

    
    var body: some View {
        
        ScrollView {
            LazyVStack {
                ForEach(notifsManager.notifications, id: \.self) { notification in
                    NotificationRowView(
                        notification: notification,
                        onTap: {},
                        onDelete: {},
                        onAction: {}
                    )
                }
            }
        }
        
    }
    
}

class MockNotifManager: ObservableObject {
    @Published var notifications: [AppNotification] = [
        .init(
            title: "In ritardo",
            message: "La prenotazione di Elena e' in ritardo di 15 minuti.",
            reservation: .init(name: "Elena", phone: "3478962417", numberOfPersons: 8, dateString: "2025-01-10", category: .dinner, startTime: "19:00", acceptance: .confirmed, status: .pending, reservationType: .inAdvance),
            type: .late
        ),
        .init(
            title: "In scadenza",
            message: "La prenotazione di Vittoria e' in scadenza!",
            reservation: .init(name: "Vittoria", phone: "3478962418", numberOfPersons: 3, dateString: "2025-01-09", category: .lunch, startTime: "12:00", acceptance: .confirmed, status: .pending, reservationType: .inAdvance),
            type: .nearEnd
        )
        
    ]
}

#Preview {
    @Previewable @StateObject var mockManager = MockNotifManager()
    
    NotificationCenterView()
        .environmentObject(mockManager)
}
