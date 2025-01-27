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
    
    @Environment(\.colorScheme) var colorScheme
    @State var reservations: [Reservation] = []
    @State var showingDatePicker: Bool = false
    @State var showingAddReservationSheet: Bool = false

    var body: some View {
        // TabView for "Lunch" and "Dinner" selection
        if #available(iOS 18.0, *) {
//            HStack {
//                Text(
//                    "\(reservations.count) PRENOTAZIONI"
//                )
//                .font(.headline)
//                .padding(.top)
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
                    
                    if appState.isToolbarVisible {
                        ZStack {
                            // MARK: Background (RoundedRectangle)
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .frame(
                                    width: appState.toolbarState != .pinnedBottom
                                    ? 80  // 20% of the available width (you can tweak the factor)
                                    : geometry.size.width * 0.4,  // 90% of the available width when pinned bottom
                                    height: appState.toolbarState != .pinnedBottom
                                    ? geometry.size.height * 0.4  // 90% of the available height when vertical
                                    : 80  // 15% of the available height when horizontal
                                )
                                .scaleEffect(appState.toolbarState == .overlay ? 1.25 : 1.0, anchor: .center)
                                .opacity(appState.toolbarState == .overlay ? 0.5 : 1.0)
                            
                            // MARK: Toolbar Content
                            toolbarContent(in: geometry, selectedDate: appState.selectedDate)
                        }
                        .ignoresSafeArea(.keyboard)
                        .position(
                            appState.isDragging
                            ? appState.dragAmount ?? calculatePosition(geometry: geometry)
                            : calculatePosition(geometry: geometry)
                        )
                        .animation(appState.isDragging ? .none : .spring(), value: appState.isDragging)
                        .transition(transitionForCurrentState(geometry: geometry))
                        .gesture(
                            toolbarGesture(in: geometry)
                        )
                        
                    } else {
                        // 2) Show a handle if hidden, positioned based on the last pinned side
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.thinMaterial)
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: "slider.horizontal.3")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(
                                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                                )
                                .frame(width: 50, height: 50)
                        }
                        .ignoresSafeArea(.keyboard)
                        .position(
                            appState.isDragging
                            ? appState.dragAmount ?? calculatePosition(geometry: geometry)
                            : calculatePosition(geometry: geometry)
                        )  // depends on pinned side
                        .animation(appState.isDragging ? .none : .spring(), value: appState.isDragging)
                        .transition(transitionForCurrentState(geometry: geometry))
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    withAnimation {
                                        appState.isToolbarVisible = true
                                    }
                                }
                        )
                        .simultaneousGesture(
                            toolbarGesture(in: geometry)
                        )
                    }
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
            .sheet(isPresented: $showingAddReservationSheet) {
                AddReservationView(
                    selectedDate: Binding<Date>(
                        get: {
                            // Force-unwrap or handle out-of-range more gracefully
                            appState.dates[appState.selectedIndex]
                        },
                        set: { newVal in
                            // Update the array in the parent
                            appState.dates[appState.selectedIndex] = newVal
                        }
                    ),
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
        switch appState.toolbarState {
        case .overlay:
            // No special transition on overlay
            return .opacity
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
        switch appState.toolbarState {
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

        case .overlay:
            // *Decide* if you want a vertical or horizontal layout
            // depending on the user’s drag or your thresholds.
            // If you want to replicate “vertical if near sides, horizontal if near bottom,”
            // you can do a quick check on overlayOffset.
            switch appState.overlayOrientation {
            case .horizontal:
                // Horizontal
                HStack(spacing: 25) {
                   
                }

            case .vertical:
                // Vertical
                VStack(spacing: 25) {
                   
                }
            }
        }
    }

    private func toolbarGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in

                appState.isDragging = true

                var currentLocation = value.location
                let currentOffset = value.translation

                if appState.toolbarState != .pinnedBottom {
                    currentLocation.y = (geometry.size.height / 2) + currentOffset.height

                } else {
                    currentLocation.x = (geometry.size.height / 2) + currentOffset.width
                }

                appState.dragAmount = currentLocation

            }
            .onEnded { value in
                var currentLocation = value.location
                let currentOffset = value.translation

                if appState.toolbarState == .pinnedBottom {
                    if currentOffset.height > 0 {
                        withAnimation {
                            appState.isToolbarVisible = false
                        }
                    }
                } else if appState.toolbarState == .pinnedLeft {
                    if currentOffset.width < 0 {
                        withAnimation {
                            appState.isToolbarVisible = false
                        }
                    }
                } else if appState.toolbarState == .pinnedRight {
                    if currentOffset.width > 0 {
                        withAnimation {
                            appState.isToolbarVisible = false
                        }
                    }
                }

                if currentLocation.y > geometry.size.height / 2 && currentOffset.height > 0
                    && (currentLocation.x > geometry.size.width / 2 && currentOffset.width < 0
                        || currentLocation.x < geometry.size.width / 2 && currentOffset.width > 0)
                {
                    withAnimation {
                        appState.toolbarState = .pinnedBottom
                    }
                } else if currentLocation.x < geometry.size.width / 2 && currentOffset.width < 0
                    && currentOffset.height < 0
                {
                    appState.toolbarState = .pinnedLeft
                } else if currentLocation.x > geometry.size.width / 2 && currentOffset.width > 0
                    && currentOffset.height < 0
                {
                    appState.toolbarState = .pinnedRight
                }

                print("ToolbarState: \(appState.toolbarState)")

                if appState.toolbarState == .pinnedLeft {
                    currentLocation.x = 60
                    currentLocation.y = geometry.size.height / 2
                    withAnimation {
                        appState.dragAmount = currentLocation
                    }
                } else if appState.toolbarState == .pinnedRight {
                    currentLocation.x = geometry.size.width - 60
                    currentLocation.y = geometry.size.height / 2
                    withAnimation {
                        appState.dragAmount = currentLocation
                    }
                } else if appState.toolbarState == .pinnedBottom {
                    currentLocation.x = geometry.size.width / 2
                    currentLocation.y = geometry.size.height - 30
                    withAnimation {
                        appState.dragAmount = currentLocation
                    }
                }

                appState.isDragging = false
            }
    }

    private func calculatePosition(geometry: GeometryProxy) -> CGPoint {
        if appState.toolbarState == .pinnedLeft {
            return CGPoint(x: 90, y: geometry.size.height / 2)
        } else if appState.toolbarState == .pinnedRight {
            return CGPoint(x: geometry.size.width - 90, y: geometry.size.height / 2)
        } else if appState.toolbarState == .pinnedBottom {
            return CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 90)
        } else {
            return appState.lastPinnedPosition
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
                showingDatePicker = true
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
        .popover(isPresented: $showingDatePicker) {
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
            showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(appState.selectedCategory == .noBookingZone)
        .foregroundColor(appState.selectedCategory == .noBookingZone ? .gray : .accentColor)
    }

}
