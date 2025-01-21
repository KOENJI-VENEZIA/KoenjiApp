//
//  TimerManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 15/1/25.
//


import Combine
import SwiftUI

class TimerManager: ObservableObject {
    @Published var currentDate: Date
    private var timer: AnyCancellable?

    init() {
        currentDate = Date() // Initialize to the current time
        timer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.currentDate = date
            }
    }
}
