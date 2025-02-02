//
//  TabsView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//

import Foundation
import SwiftUI

enum Tabs: Equatable, Hashable, CaseIterable {
    case lunch
    case dinner
}

struct TabsView: View {
    // - MARK: Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @Environment(\.colorScheme) var colorScheme

    @State var toolbarManager = ToolbarStateManager()
    @State private var selectedTab: Tabs = .lunch
    @State var reservations: [Reservation] = []
    @State var bindableDate: Date = Date()
    @State var showingAddReservationSheet: Bool = false

    @Binding var columnVisibility: NavigationSplitViewVisibility

    // MARK: - Body
    var body: some View {
        // TabView for "Lunch" and "Dinner" selection
        if #available(iOS 18.0, *) {
            GeometryReader { geometry in
                ZStack {
                    Color.clear

                    TabView(selection: $selectedTab) {
                        Tab("Pranzo", systemImage: "sun.max.circle", value: .lunch) {
                            TimelineGantView(reservations: reservations, columnVisibility: $columnVisibility)
                        }
                        Tab("Cena", systemImage: "moon.circle.fill", value: .dinner) {
                            TimelineGantView(reservations: reservations, columnVisibility: $columnVisibility)
                        }

                    }

                    ZStack {
                        ToolbarExtended(
                            geometry: geometry, toolbarState: $toolbarManager.toolbarState,
                            small: true)

                        // MARK: Toolbar Content
                        toolbarContent(in: geometry, selectedDate: appState.selectedDate)
                    }
                    .opacity(toolbarManager.isToolbarVisible ? 1 : 0)
                    .ignoresSafeArea(.keyboard)
                    .position(
                        toolbarManager.isDragging
                            ? toolbarManager.dragAmount
                            : toolbarManager.calculatePosition(geometry: geometry)
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
                                : toolbarManager.calculatePosition(geometry: geometry)
                        )  // depends on pinned side
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
                }
            }
            .navigationTitle("Timeline tavoli")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.all)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        withAnimation {
                            appState.isFullScreen.toggle()
                            if appState.isFullScreen {
                                columnVisibility = .detailOnly
                            } else {
                                columnVisibility = .all
                            }
                        }
                    }) {
                        Label(
                            "Toggle Full Screen",
                            systemImage: appState.isFullScreen
                                ? "arrow.down.right.and.arrow.up.left"
                                : "arrow.up.left.and.arrow.down.right")
                    }
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
                        appState.changedReservation = newReservation}
                )
                .environmentObject(appState)
                .environmentObject(env)
                .presentationBackground(.thinMaterial)
            }
            .onAppear {
                if selectedTab == .lunch {
                    appState.selectedCategory = .lunch
                } else {
                    appState.selectedCategory = .dinner
                }

                updateActiveReservations()

                bindableDate = appState.selectedDate

            }
            .onChange(of: selectedTab) {
                if selectedTab == .lunch {
                    appState.selectedCategory = .lunch
                } else {
                    appState.selectedCategory = .dinner
                }

                updateActiveReservations()

            }
            .onChange(of: env.resCache.cache) { updateActiveReservations() }
            .onChange(of: appState.selectedDate) { _, newDate in
                updateActiveReservations()
                env.resCache.preloadDates(around: newDate, range: 5, reservations: env.store.reservations)
            }

        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func toolbarContent(in geometry: GeometryProxy, selectedDate: Date)
        -> some View
    {
        switch toolbarManager.toolbarState {
        case .pinnedLeft, .pinnedRight:
            // Vertical layout:
            VStack {

                resetDateButton
                    .padding(.bottom, 2)

                dateBackward
                    .padding(.bottom, 2)

                dateForward
                    .padding(.bottom, 2)

                datePicker(selectedDate: selectedDate)
                    .padding(.bottom, 2)

            }

        case .pinnedBottom:
            // Horizontal layout:
            HStack(spacing: 25) {

                resetDateButton

                dateBackward

                dateForward

                datePicker(selectedDate: selectedDate)

            }
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
    
    private func updateActiveReservations() {
        reservations = env.resCache.reservations(for: appState.selectedDate).filter {
            reservation in
            reservation.category == appState.selectedCategory
            && reservation.status != .canceled
            && reservation.status != .deleted
            && reservation.status != .toHandle
            && reservation.reservationType != .waitingList
        }
    }
}
