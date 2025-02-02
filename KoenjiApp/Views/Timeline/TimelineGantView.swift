//
//  TimelineGantView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//
import SwiftUI
import Foundation

struct TimelineGantView: View {

    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    var reservations: [Reservation]
    @Binding var columnVisibility: NavigationSplitViewVisibility

    // MARK: - Layout Constants
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8

    // Computed grid rows for the LazyHGrid
    private var gridRows: [GridItem] {
        Array(repeating: GridItem(.fixed(40), spacing: 30), count: gridRowCount)
    }
    
    // MARK: - Time & Category Computations
    private var totalHours: Int {
        switch appState.selectedCategory {
        case .lunch:  return 4
        case .dinner: return 6
        default:      return 2
        }
    }
    
    private var startHour: Int {
        switch appState.selectedCategory {
        case .lunch:  return 12
        case .dinner: return 18
        default:      return 15
        }
    }
    
    private var totalColumns: Int {
        totalHours * columnsPerHour
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                headerText(in: geometry)
                fullScreenToggleOverlay()
                contentView()
                reservationCountText()
            }
        }
        .onAppear {
            logReservationsPerTable()
        }
    }
}

// MARK: - Subviews & Helper Functions
extension TimelineGantView {
    
    /// Displays the header with the day of week and full date.
    private func headerText(in geometry: GeometryProxy) -> some View {
        Text("\(DateHelper.dayOfWeek(for: appState.selectedDate)), \(DateHelper.formatFullDate(appState.selectedDate))")
            .bold()
            .padding()
            .font(.title3)
            .offset(y: (-geometry.size.height / 2) + 20)
    }
    
    /// A clear overlay that toggles full-screen mode on double tap.
    private func fullScreenToggleOverlay() -> some View {
        Color.clear
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation {
                            appState.isFullScreen.toggle()
                            columnVisibility = appState.isFullScreen ? .detailOnly : .all
                        }
                    }
            )
    }
    
    /// The main content view containing the table headers and scrollable timeline.
    private func contentView() -> some View {
        HStack {
            tableHeadersView()
            timelineScrollView()
        }
    }
    
    /// Displays the table headers.
    private func tableHeadersView() -> some View {
        LazyHGrid(rows: gridRows, spacing: 30) {
            Text("TAVOLI")
                .font(.headline)
                .padding()
            ForEach(0..<7) { tableID in
                Text("TAVOLO \(tableID + 1)")
                    .padding()
            }
        }
    }
    
    /// The scrollable timeline containing the background grid, time markers, and reservations.
    private func timelineScrollView() -> some View {
        ScrollView(.horizontal) {
            ZStack(alignment: .leading) {
                backgroundGridView().padding()
                timelineContentView().padding()
            }
        }
        .background(Color.clear)
    }
    
    /// The background grid with vertical markers.
    private func backgroundGridView() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { _ in
                ZStack {
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.clear)
                    VStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 0.5, height: 60)
                        Rectangle()
                            .stroke(Color.gray.opacity(0.5),
                                    style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                            .frame(width: 1, height: UIScreen.main.bounds.height * 0.6)
                            .frame(maxHeight: .infinity, alignment: .center)
                            .padding(.bottom)
                    }
                }
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: cellSize)
            }
        }
    }
    
    /// Combines the time markers and reservations rows.
    private func timelineContentView() -> some View {
        LazyHGrid(rows: gridRows, spacing: 20) {
            timeMarkersRow()
            reservationsRows()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// Displays the row with time markers.
    private func timeMarkersRow() -> some View {
        HStack(spacing: 0) {
            ForEach(0..<totalColumns, id: \.self) { columnIndex in
                let totalMinutes = columnIndex * 15
                let currentHour = startHour + (totalMinutes / 60)
                let currentMinute = totalMinutes % 60
                ZStack {
                    // A simple background; adjust spacing as needed
                    HStack {
                        Rectangle().frame(width: 1)
                        Rectangle().fill(Color.clear).frame(width: cellSize - 9)
                    }
                    Text(String(format: "%02d:%02d", currentHour, currentMinute))
                }
            }
        }
    }
    
    /// Displays the reservations for each table.
    private func reservationsRows() -> some View {
        ForEach(0..<tables, id: \.self) { tableID in
            ZStack(alignment: .leading) {
                ForEach(filteredReservations(for: tableID + 1)) { reservation in
                    RectangleReservationBackground(
                        reservation: reservation,
                        duration: calculateWidth(for: reservation),
                        padding: calculatePadding(for: reservation, tableID + 1)
                    )
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
    }
    
    /// Displays the total number of reservations at the bottom.
    private func reservationCountText() -> some View {
        Text("\(reservations.count) \(TextHelper.pluralized("PRENOTAZIONE", "PRENOTAZIONI", reservations.count))")
            .font(.headline)
            .padding()
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    // MARK: - Data & Calculation Helpers
    
    /// Filters reservations for a given table.
    private func filteredReservations(for table: Int) -> [Reservation] {
        reservations.filter { reservation in
            reservation.tables.contains { $0.id == table }
        }
    }
    
    /// Logs reservations for each table.
    private func logReservationsPerTable() {
        for table in 0..<tables {
            let tableReservations = reservations.filter { reservation in
                reservation.tables.contains { $0.id == (table + 1) }
            }
            for res in tableReservations {
                print("Res. name \(res.name) starting at \(res.startTime) or \(DateHelper.formatTime(res.startTimeDate ?? Date()))")
            }
        }
    }
    
    /// Calculates the reservations to display based on the selected date and category.
    
    
    /// Calculates the left padding (in points) for a reservation view on a specific table.
    private func calculatePadding(for reservation: Reservation, _ table: Int) -> CGFloat {
        let startDate = reservation.startTimeDate ?? Date()
        let categoryStartTime: String = {
            switch appState.selectedCategory {
            case .lunch:  return "12:00"
            case .dinner: return "18:00"
            default:      return "15:01"
            }
        }()
        let categoryDate = DateHelper.parseTime(categoryStartTime) ?? Date()
        let combinedCategoryDate = DateHelper.combine(date: appState.selectedDate, time: categoryDate)
        let paddingTime = startDate.timeIntervalSince(combinedCategoryDate)  // in seconds
        let totalMinutes = paddingTime / 60.0
        return totalMinutes <= 0 ? 0 : (CGFloat(totalMinutes) / 15.0) * cellSize
    }
    
    /// Calculates the width (in points) for a reservation view based on its duration.
    private func calculateWidth(for reservation: Reservation) -> CGFloat {
        let duration = reservation.endTimeDate?.timeIntervalSince(reservation.startTimeDate ?? Date()) ?? 0.0
        let minutes = duration / 60.0
        return CGFloat(minutes / 15.0) * cellSize
    }
}

// MARK: - RectangleReservationBackground Subview
struct RectangleReservationBackground: View {
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    private let cellHeight: CGFloat = 60
    
    var body: some View {
        HStack(spacing: 0) {
            if padding > 0 {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .frame(width: padding, height: cellHeight)
                    .frame(maxHeight: .infinity, alignment: .leading)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(reservation.assignedColor.opacity(0.5))
                    .stroke(Color.gray.opacity(0.5), lineWidth: 0.2)
                    .frame(width: duration, height: cellHeight)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                        .frame(width: duration - 20, height: 40)
                    GeometryReader { geo in
                        HStack(spacing: 10) {
                            Text("\(reservation.name),")
                                .font(.title3)
                                .bold()
                            Text("\(reservation.numberOfPersons) p.")
                                .font(.headline)
                            Text("|")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("dalle \(reservation.startTime)")
                                .font(.headline)
                        }
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                        .frame(maxWidth: geo.size.width - 20, alignment: .center)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
                .frame(width: duration, height: cellHeight)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: reservation)
        .background(Color.clear)
    }
}

//#Preview {
//    @Previewable @StateObject var resCache = CurrentReservationsCache()
//    @Previewable @StateObject var appState = AppState()
//    @Previewable @State var columnVisibility: NavigationSplitViewVisibility = .all
//
//    TimelineGantView(reservations: columnVisibility: $columnVisibility)
//        .environmentObject(resCache)
//        .environmentObject(appState)
//}
