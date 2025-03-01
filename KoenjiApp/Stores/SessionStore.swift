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
        logger.debug("Fetching all sessions. Count: \(self.sessions.count)")
        return self.sessions
    }
    
    func setSessions(_ sessions: [Session]) {
        logger.info("Updating session store with \(sessions.count) sessions")
        self.sessions = sessions
    }
    
    @MainActor
    func updateSession(_ session: Session) {
        let sessionIndex = self.sessions.firstIndex(where: { $0.uuid == session.uuid })

        guard let sessionIndex else {
            logger.error("Error: Reservation with ID \(session.uuid) not found.")
            return
        }
        
        DispatchQueue.main.async {
            self.sessions[sessionIndex] = session
            self.logger.info("Updating session store with session \(session.uuid)")
        }
    }
}
