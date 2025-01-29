//
//  AppState.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var isWritingToFirebase = false
    @Published var inspectorColor: Color = Color.inspector_generic
    @Published var selectedDate: Date = Date() {
        didSet {
            selectedCategory = updateCategoryForDate()
        }
    }
    @Published var selectedCategory: Reservation.ReservationCategory
    @Published var systemTime: Date = Date()
    @Published var isManuallyOverridden: Bool = false

    @State var dates: [Date] = []
    @State var selectedIndex: Int = 15
    @State var showingDatePicker: Bool = false
    @State var showingAddReservationSheet: Bool = false
    @Published var isFullScreen = false
    @Published var columnVisibility: NavigationSplitViewVisibility = .all
    
    @Published var rotationAngle: Double = 0
    @Published var isContentReady = false

    init(selectedCategory: Reservation.ReservationCategory = .lunch) {
        self.selectedCategory = selectedCategory // Ensure category is correct at initialization
        self.selectedCategory = updateCategoryForDate()
    }

    private func updateCategoryForDate() -> Reservation.ReservationCategory {
        let calendar = Calendar.current

        // Extract hour and minute from the selectedDate
        let hour = calendar.component(.hour, from: selectedDate)
        let minute = calendar.component(.minute, from: selectedDate)

        // Determine the category based on the time
        if hour >= 12 && (hour < 15 || (hour == 15 && minute == 0)) {
            return .lunch
        } else if hour >= 18 && (hour < 23 || (hour == 23 && minute <= 45)) {
            return .dinner
        } else {
            return .noBookingZone
        }
    }
    
    
}
