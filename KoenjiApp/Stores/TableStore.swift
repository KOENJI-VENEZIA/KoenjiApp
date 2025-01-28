//
//  TableStore.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//

// PLACEHOLDER: - TableStore.Swift


import Foundation
import SwiftUI

class TableStore: ObservableObject {
    nonisolated(unsafe) static let shared = TableStore(store: ReservationStore.shared)
    private let store: ReservationStore
    
    let baseTables = [
        TableModel(id: 1, name: "T1", maxCapacity: 2, row: 1, column: 14),
        TableModel(id: 2, name: "T2", maxCapacity: 2, row: 1, column: 10),
        TableModel(id: 3, name: "T3", maxCapacity: 2, row: 1, column: 6),
        TableModel(id: 4, name: "T4", maxCapacity: 2, row: 1, column: 1),
        TableModel(id: 5, name: "T5", maxCapacity: 2, row: 8, column: 7),
        TableModel(id: 6, name: "T6", maxCapacity: 2, row: 6, column: 1),
        TableModel(id: 7, name: "T7", maxCapacity: 2, row: 11, column: 1)
    ]
    
    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    var grid: [[Int?]] = []


    init(store: ReservationStore)
    {
        self.store = store
    }
    
    
    
}

