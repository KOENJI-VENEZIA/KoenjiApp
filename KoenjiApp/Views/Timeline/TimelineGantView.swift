//
//  TimelineGantView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 26/1/25.
//
import SwiftUI
import Foundation
import os

struct TimelineGantView: View {

    // MARK: - Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "TimelineGantView"
    )

    var reservations: [Reservation]
    @Binding var columnVisibility: NavigationSplitViewVisibility

    // MARK: - Layout Constants
    private let tables: Int = 7
    private let columnsPerHour: Int = 4
    private let cellSize: CGFloat = 65
    private let gridRowCount: Int = 8

    // Computed grid rows for the LazyHGrid
    private var gridRows: [GridItem] {
        Array(repeating: GridItem(.fixed(60), spacing: 20), count: gridRowCount)
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
        LazyHGrid(rows: gridRows, spacing: 20) {
            Text("TAV.")
                .font(.headline)
                .padding()
            ForEach(0..<7) { tableID in
                Text("T\(tableID + 1)")
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
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 0.5, height: 60)
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3),
                                style: StrokeStyle(
                                    lineWidth: 0.8,
                                    dash: [2, 3]
                                ))
                        .frame(width: 1)
                        .frame(height: UIScreen.main.bounds.height * 0.8)
                }
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
                Text(String(format: "%02d:%02d", currentHour, currentMinute))
                    .frame(width: cellSize)
            }
        }
    }
    
    /// Displays the reservations for each table.
    private func reservationsRows() -> some View {
        ForEach(0..<tables, id: \.self) { tableID in
            HStack {
                ZStack(alignment: .leading) {
                    let tableReservations = filteredReservations(for: tableID + 1)
                    ForEach(tableReservations) { reservation in
                        RectangleReservationBackground(
                            reservation: reservation,
                            duration: calculateWidth(for: reservation),
                            padding: calculatePadding(for: reservation, tableID + 1),
                            tableID: tableID + 1
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
            .frame(height: 60)
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
                Self.logger.debug("Table \(table + 1): Reservation '\(res.name)' starting at \(res.startTime) (\(DateHelper.formatTime(res.startTimeDate ?? Date())))")
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
        return totalMinutes <= 0 ? (cellSize / 2.0) : ((CGFloat(totalMinutes) / 15.0) * cellSize) + (cellSize / 2.0)
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
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    
    let reservation: Reservation
    let duration: CGFloat
    let padding: CGFloat
    let tableID: Int
    private let cellHeight: CGFloat = 60
    
    private var shouldShowReservation: Bool {
        reservation.tables.map(\.id).min() == tableID
    }
    
    private var isTableOccupied: Bool {
        reservation.tables.map(\.id).contains(tableID) && !shouldShowReservation
    }
    
    var body: some View {
        Group {
            if shouldShowReservation || isTableOccupied {
                HStack(spacing: 0) {
                    if padding > 0 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: padding)
                    }
                    
                    if isTableOccupied {
                        // Occupancy indicator for spanned tables
                        RoundedRectangle(cornerRadius: 8)
                            .fill(reservation.assignedColor.opacity(0.2))
                            .frame(width: duration, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        reservation.assignedColor.opacity(0.4),
                                        style: StrokeStyle(
                                            lineWidth: 1,
                                            dash: [4, 8],
                                            dashPhase: 10
                                        )
                                    )
                            )
                            .overlay(
                                // Add reservation name to occupied table indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                    Text(reservation.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                            )
                    } else {
                        // Main reservation card
                        RoundedRectangle(cornerRadius: 12)
                            .fill(reservation.assignedColor.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .overlay(
                                // Card content
                                VStack(alignment: .leading, spacing: 6) {
                                    // Top row with name and status
                                    HStack(spacing: 8) {
                                        Text(reservation.name)
                                            .font(.headline)
                                            .bold()
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        // Status badge
                                        Label(reservation.status.localized, systemImage: statusIcon(for: reservation.status))
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(reservation.status.color.opacity(0.12))
                                            .foregroundColor(reservation.status.color)
                                            .clipShape(Capsule())
                                    }
                                    
                                    // Bottom row with details
                                    HStack(spacing: 12) {
                                        Label("\(reservation.numberOfPersons)p", systemImage: "person.2.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        
                                        Label("\(reservation.startTime)-\(reservation.endTime)", systemImage: "clock.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        if reservation.tables.count > 1 {
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            
                                            Label("\(reservation.tables.count) tavoli", systemImage: "tablecells")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            )
                            .frame(width: duration)
                            .contextMenu {
                                Button {
                                    print("DEBUG: Reservation details for \(reservation.name)")
                                } label: {
                                    Label("Debug Print", systemImage: "ladybug.slash.fill")
                                }

                                Divider()

                                Button {
                                    // Handle emoji picker
                                    // Note: You'll need to add state for emoji picker
                                } label: {
                                    Label("Scegli Emoji", systemImage: "ellipsis.circle")
                                }

                                Divider()

                                Button("Cancellazione") {
                                    var updatedReservation = reservation
                                    if updatedReservation.status != .canceled {
                                        updatedReservation.status = .canceled
                                    }
                                    env.reservationService.updateReservation(updatedReservation) {
                                        appState.changedReservation = updatedReservation
                                    }
                                }
                            }
                    }
                }
                .frame(height: isTableOccupied ? 30 : cellHeight)
            }
        }
    }
    
    private func statusIcon(for status: Reservation.ReservationStatus) -> String {
        switch status {
        case .showedUp: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        case .pending: return "clock.fill"
        default: return "exclamationmark.circle.fill"
        }
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
