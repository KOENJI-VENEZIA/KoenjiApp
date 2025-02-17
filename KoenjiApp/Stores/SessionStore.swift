//
//  SessionStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/2/25.
//

import Foundation
import SwiftUI

@Observable
class SessionStore {
    
    nonisolated(unsafe) static let shared = SessionStore()

    var sessions: [Session] = []
    
    func getSessions() -> [Session] {
        return self.sessions
    }
    
    func setSessions(_ sessions: [Session]) {
            self.sessions = sessions
    }
}
