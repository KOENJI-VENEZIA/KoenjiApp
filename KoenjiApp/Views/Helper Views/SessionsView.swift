//
//  SessionsView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/2/25.
//

import SwiftUI

struct SessionsView: View {
    @AppStorage("deviceUUID") var deviceUUID: String = ""

    @EnvironmentObject var env: AppDependencies
    var activeSessions: [Session] {
        return updateActiveSessions()
    }
    
    var body: some View {
        let limitedSessions = Array(activeSessions.suffix(5))

        ForEach(Array(limitedSessions.enumerated()), id: \.element.uuid) { index, session in
                    // Calculate opacity: newest is fully opaque, older ones are semi-transparent
            let opacity = 0.5 + (CGFloat(index + 1) / CGFloat(limitedSessions.count)) * 0.5
            ZStack {
                
                Circle()
                    .fill(.gray.opacity(0.8))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(
                        Circle()
                    )
                
                Circle()
                    .fill(.clear)
                    .stroke(session.isEditing ? Color.blue : Color.white, lineWidth: 3)
                    .frame(width: 40, height: 40)
            }
            .opacity(opacity)
            .offset(x: CGFloat(index) * 20)
        
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: activeSessions)
        
        
    }
    
    func updateActiveSessions() -> [Session] {
        let sessions = SessionStore.shared.sessions
        return sessions.filter { session in
            session.uuid != deviceUUID &&
            session.isActive == true
        }
    }
    
    
}
