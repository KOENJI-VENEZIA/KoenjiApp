//
//  TableModels.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

/// Represents a physical table in the restaurant.
struct TableModel: Identifiable, Hashable, Codable, Equatable {
    let id: Int
    let name: String
    let maxCapacity: Int

    var row: Int
    var column: Int

    /// Dimensions
    var width: Int { 3 }
    var height: Int { 3 }
    
    
}


