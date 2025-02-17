//
//  EditingSession.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 16/2/25.
//

import Foundation

struct Session: Identifiable, Hashable, Codable {
    let id: String
    var uuid: String
    var userName: String
    var isEditing: Bool
    var lastUpdate: Date
    var isActive: Bool
    
    
    
}
