//
//  SessionStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/2/25.
//

import Foundation
import SwiftUI
import OSLog

@Observable
class SessionStore {
    // MARK: - Private Properties
    private let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "SessionStore"
    )
    
    // MARK: - Static Properties
    nonisolated(unsafe) static let shared = SessionStore()

    // MARK: - Properties
    var sessions: [Session] = []
    
    // MARK: - Public Methods
    func getSessions() -> [Session] {
        let count = self.sessions.count
        Task { @MainActor in
            AppLog.debug("Fetching all sessions. Count: \(count)")
        }
        return self.sessions
    }
    
    func setSessions(_ sessions: [Session]) {
        let count = sessions.count
        Task { @MainActor in
            AppLog.info("Updating session store with \(count) sessions")
        }
        self.sessions = sessions
    }
    
    @MainActor
    func updateSession(_ session: Session) {
        let sessionIndex = self.sessions.firstIndex(where: { $0.uuid == session.uuid })

        guard let sessionIndex else {
            AppLog.error("Error: Reservation with ID \(session.uuid) not found.")
            return
        }
        
        DispatchQueue.main.async {
            self.sessions[sessionIndex] = session
            AppLog.info("Updating session store with session \(session.uuid)")
        }
    }
}
