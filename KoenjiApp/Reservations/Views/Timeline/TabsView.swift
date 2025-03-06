//
//  TabsView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//

import Foundation
import SwiftUI
import os

enum Tabs: Equatable, Hashable, CaseIterable {
    case lunch
    case dinner
}

struct TabsView: View {
    // - MARK: Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.colorScheme) var colorScheme

    @State var unitView = LayoutUnitViewModel()
    @State var toolbarManager = ToolbarStateManager()
    @State private var selectedTab: Tabs = .lunch
    @State var reservations: [Reservation] = []
    @State var bindableDate: Date = Date()
    @State var showingAddReservationSheet: Bool = false

    @Binding var columnVisibility: NavigationSplitViewVisibility

    // MARK: - Dependencies
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "TabsView"
    )

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Color.clear
                
                // Main content
                TimelineGantView(reservations: reservations, columnVisibility: $columnVisibility)
//                    .ignoresSafeArea(.all)

                ZStack {
                    ToolbarExtended(
                        geometry: geometry, toolbarState: $toolbarManager.toolbarState,
                        small: true, timeline: true)

                    // MARK: Toolbar Content
                    toolbarContent(in: geometry, selectedDate: appState.selectedDate)
                }
                .opacity(toolbarManager.isToolbarVisible ? 1 : 0)
                .ignoresSafeArea(.keyboard)
                .position(
                    toolbarManager.isDragging
                        ? toolbarManager.dragAmount
                    : toolbarManager.calculatePosition(geometry: geometry, isPhone: isPhone)
                )
                .animation(
                    toolbarManager.isDragging ? .none : .spring(),
                    value: toolbarManager.isDragging
                )
                .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
                .gesture(
                    toolbarManager.toolbarGesture(geometry: geometry)
                )

                ToolbarMinimized()
                    .opacity(!toolbarManager.isToolbarVisible ? 1 : 0)
                    .ignoresSafeArea(.keyboard)
                    .position(
                        toolbarManager.isDragging
                            ? toolbarManager.dragAmount
                        : toolbarManager.calculatePosition(geometry: geometry, isPhone: isPhone)
                    )
                    .animation(
                        toolbarManager.isDragging ? .none : .spring(),
                        value: toolbarManager.isDragging
                    )
                    .transition(toolbarManager.transitionForCurrentState(geometry: geometry))
                    .gesture(
                        TapGesture()
                            .onEnded {
                                withAnimation {
                                    toolbarManager.isToolbarVisible = true
                                }
                            }
                    )
                    .simultaneousGesture(
                        toolbarManager.toolbarGesture(geometry: geometry)
                    )
                
                SessionsView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: SessionStore.shared.sessions)
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
                    .environmentObject(env)
            }
        }
        .task {
            // Initialize category and time on first load
            if appState.selectedCategory == .noBookingZone {
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: Date())
                
                // Set initial category and time based on current hour
                if hour < 15 {
                    if let lunchTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) {
                        appState.selectedCategory = .lunch
                        appState.selectedDate = DateHelper.combine(date: Date(), time: lunchTime)
                    }
                } else {
                    if let dinnerTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) {
                        appState.selectedCategory = .dinner
                        appState.selectedDate = DateHelper.combine(date: Date(), time: dinnerTime)
                    }
                }
                Task {
                    await updateActiveReservations()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
//        .ignoresSafeArea(.all)
        .toolbar {
            
            ToolbarItem(placement: .principal) {
                Text("\(DateHelper.dayOfWeek(for: appState.selectedDate)), \(DateHelper.formatFullDate(appState.selectedDate))")
                    .font(.title3)
                    .bold()
            }
            
            
        
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    withAnimation {
                        appState.isFullScreen.toggle()
                        columnVisibility = appState.isFullScreen ? .detailOnly : .all
                    }
                }) {
                    Label(
                        "Toggle Full Screen",
                        systemImage: appState.isFullScreen
                            ? "arrow.down.right.and.arrow.up.left"
                            : "arrow.up.left.and.arrow.down.right")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    unitView.showNotifsCenter.toggle()
                } label: {
                   Image(systemName: "app.badge")
                }
                .id(unitView.refreshID)
            }
            
            ToolbarItem(placement: .topBarLeading) {
                categoryButtons
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { withAnimation { unitView.showInspector.toggle() } }) {
                    Label("Toggle Inspector", systemImage: "info.circle")
                }
                .id(unitView.refreshID)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                addReservationButton
            }
        }
        .sheet(item: $appState.currentReservation) { reservation in
            EditReservationView(
                reservation: reservation,
                onClose: {
                    appState.showingEditReservation = false
                },
                onChanged: { reservation in
                    appState.changedReservation = reservation
                }
            )
            .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: $showingAddReservationSheet) {
            AddReservationView(
                passedTable: nil,
                onAdded: { newReservation in
                    appState.changedReservation = newReservation
                }
            )
            .environmentObject(appState)
            .environmentObject(env)
            .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: $unitView.showNotifsCenter) {
            NotificationCenterView()
                .environmentObject(env)
                .environment(unitView)
                .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: $unitView.showInspector) {
                   InspectorSideView(selectedReservation: $appState.currentReservation)
                       .presentationBackground(.thinMaterial)
                       .environment(unitView)
               }
        .onAppear {
            Task {
                await updateActiveReservations()
            }
            bindableDate = appState.selectedDate
        }
        .onChange(of: env.store.reservations) {
            Task {
                await updateActiveReservations()
            }
            env.resCache.preloadDates(around: appState.selectedDate, range: 5, reservations: env.store.reservations)
        }
        .onChange(of: appState.selectedCategory) {
            Task {
                await updateActiveReservations()
            }
        }
        .onChange(of: env.resCache.cache) { 
            Task {
                await updateActiveReservations()
            }
        }
        .onChange(of: appState.selectedDate) { _, newDate in
            Task {
                await updateActiveReservations()
            }
            env.resCache.preloadDates(around: newDate, range: 5, reservations: env.store.reservations)
        }
    }

    // MARK: - Subviews
    // Helper function to compute toolbar size.
    private func toolbarSize(geometry: GeometryProxy) -> (width: CGFloat, height: CGFloat) {
        if toolbarManager.toolbarState != .pinnedBottom {
            return (80, geometry.size.height * 0.4)
        } else {
            return (geometry.size.width * 0.7, 80)
        }
    }

    @ViewBuilder
    private func toolbarContent(in geometry: GeometryProxy, selectedDate: Date) -> some View {
        let size = toolbarSize(geometry: geometry)
        
        switch toolbarManager.toolbarState {
        case .pinnedLeft, .pinnedRight:
            // Vertical toolbar: wrap in a vertical ScrollView and ensure the inner VStack fills the parent's height.
            ScrollView(.vertical) {
                VStack(spacing: 4) {
                    resetDateButton.padding(.bottom, 2)
                    dateBackward.padding(.bottom, 2)
                    dateForward.padding(.bottom, 2)
                    datePicker(selectedDate: selectedDate).padding(.bottom, 2)
                }
                // Ensure the VStack takes up at least the entire height, centering its content.
                .frame(minHeight: size.height, alignment: .center)
            }
            .frame(width: size.width, height: size.height, alignment: .center)
            
        case .pinnedBottom:
            // Horizontal toolbar: wrap in a horizontal ScrollView and ensure the inner HStack fills the parent's width.
            ScrollView(.horizontal) {
                HStack(spacing: 25) {
                    resetDateButton
                    dateBackward
                    dateForward
                    datePicker(selectedDate: selectedDate)
                }
                // Ensure the HStack takes up at least the entire width, centering its content.
                .frame(minWidth: size.width, alignment: .center)
            }
            .frame(width: size.width, height: size.height, alignment: .center)
            
        default:
            EmptyView()
        }
    }

    private var resetDateButton: some View {

        VStack {
            Text("Adesso")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
            // Reset to Default or System Time
            Button(action: {
                withAnimation {
                    resetDate()
                }

            }) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .opacity(
            appState.selectedDate.isSameDay(as: Date())
                ? 0 : 1
        )
        .animation(.easeInOut(duration: 0.5), value: appState.selectedDate)
    }

    private var dateBackward: some View {
        VStack {
            Text("-1 gg.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))

            Button(action: {

                navigateToPreviousDate()

            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468")
                    )
                    .shadow(radius: 2)
            }
        }
    }

    private var dateForward: some View {
        VStack {
            Text("+1 gg.")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))

            Button(action: {
                navigateToNextDate()

            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468")
                    )
                    .shadow(radius: 2)
            }
        }

    }

    @ViewBuilder
    private func datePicker(selectedDate: Date) -> some View {
        VStack {
            Text("Data")
                .font(.caption)
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))

            Button(action: {
                appState.showingDatePicker = true
                print("Pressed date picker button!")
            }) {
                Image(systemName: "calendar.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(
                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                    )
                    .shadow(radius: 2)
            }
        }
        .popover(isPresented: $appState.showingDatePicker) {
            DatePickerView()
                .environmentObject(appState)
                .frame(width: 300, height: 350)  // Adjust as needed

        }

    }

    private var addReservationButton: some View {
        Button {
            showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(appState.selectedCategory == .noBookingZone)
        .foregroundColor(appState.selectedCategory == .noBookingZone ? .gray : .accentColor)
    }

    private var categoryButtons: some View {
        HStack(spacing: 8) {
            Button(action: {
                withAnimation {
                    let lunchTime = "12:00"
                    let day = appState.selectedDate
                    guard let combinedTime = DateHelper.combineDateAndTime(date: day, timeString: lunchTime)
                    else { return }
                    appState.selectedCategory = .lunch
                    appState.selectedDate = combinedTime
                }
            }) {
                Label("Pranzo", systemImage: "sun.max.circle.fill")
                    .foregroundStyle(appState.selectedCategory == .lunch ? .primary : .secondary)
            }

            Button(action: {
                withAnimation {
                    let dinnerTime = "18:00"
                    let day = appState.selectedDate
                    guard let combinedTime = DateHelper.combineDateAndTime(date: day, timeString: dinnerTime)
                    else { return }
                    appState.selectedCategory = .dinner
                    appState.selectedDate = combinedTime
                }
            }) {
                Label("Cena", systemImage: "moon.circle.fill")
                    .foregroundStyle(appState.selectedCategory == .dinner ? .primary : .secondary)
            }
        }
    }

    // MARK: - View Specific Methods

    private func navigateToPreviousDate() {
        let calendar = Calendar.current
        if appState.selectedCategory == .lunch {
            if let newDate = calendar.date(byAdding: .day, value: -1, to: appState.selectedDate) {
                appState.selectedDate =
                    calendar.date(bySettingHour: 12, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date()  // Fallback in case of a failure
            }
        } else if appState.selectedCategory == .dinner {
            if let newDate = calendar.date(byAdding: .day, value: -1, to: appState.selectedDate) {
                appState.selectedDate =
                    calendar.date(bySettingHour: 18, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date()  // Fallback in case of a failure
            }
        }
    }

    private func navigateToNextDate() {
        let calendar = Calendar.current
        if appState.selectedCategory == .lunch {
            if let newDate = calendar.date(byAdding: .day, value: 1, to: appState.selectedDate) {
                appState.selectedDate =
                    calendar.date(bySettingHour: 12, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date()  // Fallback in case of a failure
            }
        } else if appState.selectedCategory == .dinner {
            if let newDate = calendar.date(byAdding: .day, value: 1, to: appState.selectedDate) {
                appState.selectedDate =
                    calendar.date(bySettingHour: 18, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date()  // Fallback in case of a failure
            }
        }
    }

    private func resetDate() {
        let calendar = Calendar.current
        if appState.selectedCategory == .lunch {
            if let newTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) {
                appState.selectedDate = DateHelper.combine(date: Date(), time: newTime)
            }
        } else if appState.selectedCategory == .dinner {
            if let newTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) {
                appState.selectedDate = DateHelper.combine(date: Date(), time: newTime)
            }
        }
    }
    
    private func updateActiveReservations() async {
        do {
            let reservations = try await env.resCache.fetchReservations(for: appState.selectedDate).filter {
                reservation in
                reservation.category == appState.selectedCategory
                && reservation.status != .canceled
                && reservation.status != .deleted
                && reservation.status != .toHandle
                && reservation.reservationType != .waitingList
            }
            
            await MainActor.run {
                self.reservations = reservations
            }
            
            TabsView.logger.info("Reservations count: \(reservations.count)")
        } catch {
            TabsView.logger.error("Error fetching reservations: \(error.localizedDescription)")
            
            // Update UI on the main thread to show empty state
            await MainActor.run {
                self.reservations = []
            }
        }
    }
}
