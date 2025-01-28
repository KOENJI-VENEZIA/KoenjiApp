//
//  TabsView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//

import SwiftUI
import Foundation

enum Tabs: Equatable, Hashable, CaseIterable {
    case lunch
    case dinner
}

struct TabsView: View {
    @State private var selectedTab: Tabs = .lunch
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var layoutServices: LayoutServices
    @EnvironmentObject var reservationService: ReservationService
    @State var toolbarManager = ToolbarStateManager()
    
    @Environment(\.colorScheme) var colorScheme
    @State var reservations: [Reservation] = []
    @State var bindableDate: Date = Date()
    
    
    var body: some View {
        // TabView for "Lunch" and "Dinner" selection
        if #available(iOS 18.0, *) {
            GeometryReader { geometry in
                ZStack {
                    TabView(selection: $selectedTab) {
                        Tab("Pranzo", systemImage: "sun.max.circle", value: .lunch) {
                            TimelineGantView()
                                .environmentObject(appState)
                                .environmentObject(resCache)
                        }
                        Tab("Cena", systemImage: "moon.circle.fill", value: .dinner) {
                            TimelineGantView()
                                .environmentObject(appState)
                                .environmentObject(resCache)
                        }
                        //                }
                        
                        
                    }
                    
                    ZStack {
                        ToolbarExtended(geometry: geometry, toolbarState: $toolbarManager.toolbarState)
                        
                        // MARK: Toolbar Content
                        toolbarContent(in: geometry, selectedDate: appState.selectedDate)
                    }
                    .opacity(toolbarManager.isToolbarVisible ? 1 : 0)
                    .ignoresSafeArea(.keyboard)
                    .position(
                        toolbarManager.isDragging
                        ? toolbarManager.dragAmount
                        : calculatePosition(geometry: geometry)
                    )
                    .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
                    .transition(transitionForCurrentState(geometry: geometry))
                    .gesture(
                        toolbarManager.toolbarGesture(geometry: geometry)
                    )
                    
                    ToolbarMinimized()
                        .opacity(!toolbarManager.isToolbarVisible ? 1 : 0)
                        .ignoresSafeArea(.keyboard)
                        .position(
                            toolbarManager.isDragging
                            ? toolbarManager.dragAmount
                            : calculatePosition(geometry: geometry)
                        )  // depends on pinned side
                        .animation(toolbarManager.isDragging ? .none : .spring(), value: toolbarManager.isDragging)
                        .transition(transitionForCurrentState(geometry: geometry))
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
            .navigationTitle("Timeline tavoli - \(DateHelper.dayOfWeek(for: appState.selectedDate)), \(DateHelper.formatFullDate(appState.selectedDate))")
            .ignoresSafeArea(.all)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    addReservationButton
                }
                
            }
//            .sheet(item: $currentReservation) { reservation in
//                EditReservationView(
//                    reservation: reservation,
//                    onClose: {
//                        showingEditReservation = false
//                    }
//                )
//                .environmentObject(store)
//                .environmentObject(resCache)
//                .environmentObject(reservationService)  // For the new service
//                .environmentObject(layoutServices)
//            }
            .sheet(isPresented: $appState.showingAddReservationSheet) {
                AddReservationView(
                    selectedDate: $bindableDate,
                    passedTable: nil
                )
                .environmentObject(store)
                .environmentObject(appState)
                .environmentObject(resCache)
                .environmentObject(reservationService)  // For the new service
                .environmentObject(layoutServices)
            }
            .onAppear {
                if selectedTab == .lunch {
                    appState.selectedCategory = .lunch
                } else {
                    appState.selectedCategory = .dinner
                }
                
                reservations = resCache.reservations(for: appState.selectedDate).filter { reservation in
                    reservation.category == appState.selectedCategory
                    && reservation.status != .canceled
                    && reservation.reservationType != .waitingList
                }
                
                bindableDate = appState.selectedDate
                
            }
            .onChange(of: selectedTab) {
                if selectedTab == .lunch {
                    appState.selectedCategory = .lunch
                } else {
                    appState.selectedCategory = .dinner
                }
                
                reservations = resCache.reservations(for: appState.selectedDate).filter { reservation in
                    reservation.category == appState.selectedCategory
                    && reservation.status != .canceled
                    && reservation.reservationType != .waitingList
                }
            }

        } else {
            // Fallback on earlier versions
        }
    }
    
    private func transitionForCurrentState(geometry: GeometryProxy) -> AnyTransition {
        switch toolbarManager.toolbarState {

        case .pinnedLeft:
            return .move(edge: .leading)
        case .pinnedRight:
            return .move(edge: .trailing)
        case .pinnedBottom:
            return .move(edge: .bottom)
        }
    }
    
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


    private func calculatePosition(geometry: GeometryProxy) -> CGPoint {
        if toolbarManager.toolbarState == .pinnedLeft {
            return CGPoint(x: 90, y: geometry.size.height / 2)
        } else if toolbarManager.toolbarState == .pinnedRight {
            return CGPoint(x: geometry.size.width - 90, y: geometry.size.height / 2)
        } else if toolbarManager.toolbarState == .pinnedBottom {
            return CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 90)
        } else {
            return toolbarManager.lastPinnedPosition
        }
    }



    private func navigateToPreviousDate() {
        let calendar = Calendar.current
        if appState.selectedCategory == .lunch {
            if let newDate = calendar.date(byAdding: .day, value: -1, to: appState.selectedDate) {
                appState.selectedDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date() // Fallback in case of a failure
            }
        } else if appState.selectedCategory == .dinner {
            if let newDate = calendar.date(byAdding: .day, value: -1, to: appState.selectedDate) {
                appState.selectedDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date() // Fallback in case of a failure
            }
        }
    }

    private func navigateToNextDate() {
        let calendar = Calendar.current
        if appState.selectedCategory == .lunch {
            if let newDate = calendar.date(byAdding: .day, value: 1, to: appState.selectedDate) {
                appState.selectedDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date() // Fallback in case of a failure
            }
        } else if appState.selectedCategory == .dinner {
            if let newDate = calendar.date(byAdding: .day, value: 1, to: appState.selectedDate) {
                appState.selectedDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: newDate) ?? newDate
            } else {
                appState.selectedDate = Date() // Fallback in case of a failure
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




    

    // MARK: - Helper Methods
    
    private var resetDateButton: some View {

        VStack {
        Text("Adesso")
            .font(.caption)
            .foregroundStyle(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
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
            DateHelper.compareTimes(
                firstTime: appState.selectedDate, secondTime: Date(), interval: 60)
                ? 0 : 1
        )
        .animation(.easeInOut, value: appState.selectedDate)
    }

    private var dateBackward: some View {
        VStack {
            Text("-1 gg.")
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
            
            Button(action: {
                
                navigateToPreviousDate()
                
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468"))
                    .shadow(radius: 2)
            }
        }
    }

    private var dateForward: some View {
        VStack
        {
            Text("+1 gg.")
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
            
            Button(action: {
                navigateToNextDate()

            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .symbolRenderingMode(.hierarchical)  // Enable multicolor rendering
                    .foregroundColor(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "364468"))
                    .shadow(radius: 2)
            }
        }

    }


    @ViewBuilder
    private func datePicker(selectedDate: Date) -> some View {
        VStack {
            Text("Data")
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
            
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

//    private var resetDate: some View {
//        VStack {
//            Text("Oggi")
//                .font(.caption)
//                .foregroundStyle(colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3"))
//                .opacity(Calendar.current.isDate(appState.selectedDate, inSameDayAs: appState.systemTime) ? 0 : 1)
//                .animation(.easeInOut, value: appState.selectedDate)
//            
//            Button(action: {
//                withAnimation {
//                    let today = Calendar.current.startOfDay(for: appState.systemTime)  // Get today's date with no time component
//                    guard let currentTimeOnly = DateHelper.extractTime(time: appState.selectedDate) else {
//                        return
//                    }  // Extract time components
//                    appState.selectedDate = DateHelper.combinedInputTime(time: currentTimeOnly, date: today) ?? Date()
//                    updateDatesAroundSelectedDate(appState.selectedDate)
//                    appState.isManuallyOverridden = false
//                }
//            }) {
//                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 40, height: 40)
//                    .foregroundStyle(
//                        colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
//                    )
//                    .shadow(radius: 2)
//            }
//        }
//        .opacity(Calendar.current.isDate(appState.selectedDate, inSameDayAs: systemTime) ? 0 : 1)
//        .animation(.easeInOut, value: appState.selectedDate)
//    }

    private var addReservationButton: some View {
        Button {
            appState.showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(appState.selectedCategory == .noBookingZone)
        .foregroundColor(appState.selectedCategory == .noBookingZone ? .gray : .accentColor)
    }

}


