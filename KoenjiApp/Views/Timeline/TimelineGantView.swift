//
//  TimelineView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//
import SwiftUI
import Foundation

struct TimelineGantView: View {
    
    // MARK: - Dependencies
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @State var reservations: [Reservation] = []
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    let tables: Int = 7
    let columnsPerHour: Int = 4
    let gridRows = Array(repeating: GridItem(.fixed(40), spacing: 30), count: 8)
    let cellSize: Int = 65
    
    // MARK: - Body
    var body: some View {

        
        let totalHours = {
            if appState.selectedCategory == .lunch {
                return 4
            } else if appState.selectedCategory == .dinner {
                return 6
            } else {
                return 2
            }
        }()
        
        let startHour = {
            if appState.selectedCategory == .lunch {
                return 12
            } else if appState.selectedCategory == .dinner {
                return 18
            } else {
                return 15
            }
        }()
        
        let forEachColumns = totalHours * columnsPerHour
        
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .gesture(
                    TapGesture(count: 2) // Double-tap to exit full-screen
                        .onEnded {
                                withAnimation {
                                    appState.isFullScreen.toggle()
                                    if appState.isFullScreen {
                                        columnVisibility = .detailOnly
                                    } else {
                                        columnVisibility = .all
                                    }
                            }
                        }
                )
                
                HStack {
                    LazyHGrid(rows: gridRows, spacing: 30) {
                        Text("TAVOLI")
                            .font(.headline)
                            .padding()
                        ForEach(0..<7) { tableID in
                            Text("TABLE \(tableID + 1)")
                                .padding()
                        }
                    }
                    
//                    Divider()
                    
                    ScrollView(.horizontal) {
                        ZStack(alignment: .leading) {
                            
                            HStack(spacing: 0) {
                                ForEach(0..<forEachColumns, id: \.self) { columnIndex in  // <- Add id: \.self
                                    ZStack {
                                        Rectangle()
                                            .frame(width: 1)
                                            .foregroundColor(.clear)
                                        VStack {
                                            Rectangle()
                                                .fill(Color.clear)
                                                .frame(width: 0.5, height: 60)
                                            Rectangle()
                                                .stroke(Color.gray.opacity(0.5), style: StrokeStyle( lineWidth: 0.5, dash: [2, 4]))
                                                .frame(width: 1, height: UIScreen.main.bounds.height * 0.6)
                                                .frame(maxHeight: .infinity, alignment: .center)
                                                .padding(.bottom)
                                        }
                                    }
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: 64)
                                }
                                
                            }
                            .padding()
                            
                            LazyHGrid(rows: gridRows, spacing: 20) {
                                HStack(spacing: 0) {
                                    ForEach(0..<forEachColumns, id: \.self) { columnIndex in  // <- Add id: \.self
                                        let totalMinutes = columnIndex * 15
                                        let currentHour = startHour + (totalMinutes / 60)
                                        let currentMinute = totalMinutes % 60
                                        
                                        ZStack {
                                            HStack {
                                                Rectangle()
                                                    .frame(width: 1)
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .frame(width: 56)
                                                
                                            }
                                            Text(
                                                String(format: "%02d:%02d", currentHour, currentMinute))
                                        }
                                    }
                                }
                                
                                
                                ForEach(0..<7, id: \.self) { tableID in
                                    ZStack(alignment: .leading) {
                                        ForEach(
                                            reservations.filter { reservation in
                                                reservation.tables.contains(where: {
                                                    $0.id == (tableID + 1)
                                                })
                                            }, id: \.id
                                        ) { reservation in
                                            
                                            RectangleReservationBackground(
                                                reservation: reservation,
                                                duration: calculateWidth(for: reservation),
                                                padding: calculatePadding(
                                                    for: reservation, (tableID + 1)))
                                            .gesture(
                                                TapGesture(count: 2)
                                                    .onEnded {
                                                        appState.currentReservation = reservation
                                                        appState.showingEditReservation = true
                                                    }
                                            )
                                            
                                            
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                            }
                            .padding()
                        }
                    }
                    .background(.clear)
                }
                
                Text("\(reservations.count) \(TextHelper.pluralized("PRENOTAZIONE", "PRENOTAZIONI", reservations.count))")
                .font(.headline)
                .padding()
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onChange(of: resCache.cache) {
            calculateReservations()
        }
        .onChange(of: appState.selectedDate) {
            calculateReservations()
        }
        .onAppear {
            
            calculateReservations()
            
            for table in 0..<tables {
                let filteredReservations = reservations.filter { reservation in
                    reservation.tables.contains(where: { $0.id == (table + 1) })
                }

                for res in filteredReservations {
                    print(
                        "Res. name \(res.name) starting at \(res.startTime) or \(DateHelper.formatTime(res.startTimeDate ?? Date()))"
                    )
                }
            }

        }

    }
    
    // MARK: - View-specific Helper Methods
    func calculateReservations() {
        reservations = resCache.reservations(for: appState.selectedDate).filter { reservation in
            reservation.category == appState.selectedCategory
            && reservation.status != .canceled
            && reservation.reservationType != .waitingList
        }
    }

    func calculatePadding(for reservation: Reservation, _ table: Int) -> CGFloat {
        let startDate = reservation.startTimeDate ?? Date()
        let categoryStartTime = {
            if appState.selectedCategory == .lunch {
                return "12:00"
            } else if appState.selectedCategory == .dinner {
                return "18:00"
            } else {
                return "15:01"
            }
        }()
        
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        print("Category date: \(DateHelper.formatTime(categoryDate))")
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        print(
            "Combined Category date: \(DateHelper.formatDate(combinedCategoryDate)) - \(DateHelper.formatTime(combinedCategoryDate)) "
        )
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // Difference in seconds

        // Convert seconds to minutes
        let totalMinutes = paddingTime / 60.0
        let columnWidth: CGFloat = CGFloat(cellSize)  // Width of a 15-minute block

        // If totalMinutes is negative, padding should be zero
        if totalMinutes <= 0 {
            return 0
        }

        print(
            "Res. \(reservation.name) Table \(table), Padding time: \((paddingTime / 60.0)) in minutes, \(CGFloat(totalMinutes) / 15.0 * columnWidth) = cellSize"
        )

        // Correct padding calculation: ensure the division does not truncate values
        return (CGFloat(totalMinutes) / 15.0) * columnWidth
    }

    func calculateWidth(for reservation: Reservation) -> CGFloat {
        let duration =
            reservation.endTimeDate?.timeIntervalSince(reservation.startTimeDate ?? Date()) ?? 0.0
        let minutes = duration / 60

        let columnWidth: CGFloat = CGFloat(cellSize)  // Width of a 15-minute block
        return CGFloat(minutes / 15) * columnWidth
    }
}

// MARK: - Single Reservation View
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let cellSize: Int = 65
    let duration: CGFloat
    let padding: CGFloat
    var body: some View {

        HStack(spacing: 0) {
            if padding != 0 {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .frame(width: padding, height: 60)
                    .frame(maxHeight: .infinity, alignment: .leading)
            }
            
            ZStack(alignment: .leading) {

                RoundedRectangle(cornerRadius: 12)
                    .fill(reservation.assignedColor.opacity(0.5)) // Apply unique color
                    .stroke(Color.gray.opacity(0.5), lineWidth: 0.2)
                    .frame(width: duration, height: 60)
                
                ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
                    .frame(width: duration - 20.0, height: 40)

                    HStack(spacing: 10) {
                        Text("\(reservation.name), \(reservation.numberOfPersons) p.")
                            .font(.title3)
                            .bold()
                        
                        Text(" | ")
                            .font(.headline)
                        
                        Text("dalle \(reservation.startTime)")
                            .font(.headline)
                    }
                }
                .frame(width: duration, height: 60)
            }
        }
        .background(Color.clear)
    }
}

#Preview {

    @Previewable @StateObject var resCache = CurrentReservationsCache()
    @Previewable @StateObject var appState = AppState()
    @Previewable @State var columnVisibility: NavigationSplitViewVisibility = .all
    
    TimelineGantView(columnVisibility: $columnVisibility)
        .environmentObject(resCache)
        .environmentObject(appState)
}
