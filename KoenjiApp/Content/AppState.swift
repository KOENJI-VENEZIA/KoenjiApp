//
//  AppState.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//

import SwiftUI
import OSLog

class AppState: ObservableObject {
    let logger = Logger(subsystem: "com.koenjiapp", category: "AppState")

    // MARK: - Published Properties
    @Published var inspectorColor: Color = Color.inspector_generic
    @Published var selectedDate: Date = Date()
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false
    @Published var changedReservation: Reservation? = nil
    @Published var showingEditReservation: Bool = false
    @Published var currentReservation: Reservation? = nil
    @Published var isRestoring = false
    @Published var canSave = true
    @Published var showingDatePicker: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false
    @Published var lastRefreshedKeys: [String] = []

    // MARK: - State Properties
    @State var dates: [Date] = []
    @State var selectedIndex: Int = 15
    @State var showingAddReservationSheet: Bool = false

    init(selectedCategory: Reservation.ReservationCategory = .lunch) {
        self.selectedCategory = selectedCategory
        self.selectedCategory = updateCategoryForDate()
        logger.info("AppState initialized with category: \(selectedCategory.localized)")
    }

    private func updateCategoryForDate() -> Reservation.ReservationCategory {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)

        let category: Reservation.ReservationCategory
        if hour >= 12 && (hour < 15 || (hour == 15 && minute == 0)) {
            category = .lunch
        } else if hour >= 18 && (hour < 23 || (hour == 23 && minute <= 45)) {
            category = .dinner
        } else {
            category = .noBookingZone
        }
        
        logger.debug("Updated category to \(category.localized) for time \(hour):\(minute)")
        return category
    }
}
