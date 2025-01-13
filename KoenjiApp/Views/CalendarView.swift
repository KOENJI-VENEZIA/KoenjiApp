//
//  CalendarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

enum CalendarDisplayMode {
    case month, week, day
}

struct CalendarView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @State private var mode: CalendarDisplayMode = .month
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            // Mode Picker
            Picker("Modalità", selection: $mode) {
                Text("Mese").tag(CalendarDisplayMode.month)
                Text("Settimana").tag(CalendarDisplayMode.week)
                Text("Giorno").tag(CalendarDisplayMode.day)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Date Picker for user to navigate to a date
            DatePicker("Seleziona Data:", selection: $selectedDate, displayedComponents: .date)
                .padding()
            
            Divider()
            
            switch mode {
            case .day:
                dayView
            case .week:
                weekView
            case .month:
                monthView
            }
            
            Spacer()
        }
        .navigationTitle("Calendario Prenotazioni")
    }
    
    private var dayView: some View {
        // All reservations for selectedDate, in chronological order
        let dailyReservations = reservationService.fetchReservations(on: selectedDate).sorted { lhs, rhs in
            // Sort by startTime, then creationDate if same
            if lhs.startTime == rhs.startTime {
                return lhs.creationDate < rhs.creationDate
            }
            return lhs.startTime < rhs.startTime
        }
        return List(dailyReservations) { reservation in
            VStack(alignment: .leading) {
                Text("\(reservation.startTime) - \(reservation.name) (\(reservation.numberOfPersons))")
                Text("Tavoli: \(reservation.tables.map(\.name).joined(separator: ", "))")
            }
        }
    }
    
    private var weekView: some View {
        // Display 7 days from selectedDate’s week
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return AnyView(Text("Nessun dato"))
        }
        let startOfWeek = weekInterval.start
        var days: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                days.append(day)
            }
        }
        
        return AnyView(
            List(days, id: \.self) { day in
                let dayReservations = reservationService.fetchReservations(on: day)
                let dayString = DateFormatter.localizedString(from: day, dateStyle: .short, timeStyle: .none)
                
                Section(header: Text(dayString)) {
                    ForEach(dayReservations) { reservation in
                        HStack {
                            Text(reservation.name)
                            Spacer()
                            Text("\(reservation.numberOfPersons) pers.")
                        }
                    }
                }
            }
        )
    }
    
    private var monthView: some View {
        // We'll keep this simple: just show # of reservations per day for the selected month
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else {
            return AnyView(Text("Nessun dato"))
        }
        
        var days: [Date] = []
        var day = monthInterval.start
        while day < monthInterval.end {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        
        return AnyView(
            List(days, id: \.self) { day in
                let count = reservationService.fetchReservations(on: day).count
                let dayString = DateFormatter.localizedString(from: day, dateStyle: .short, timeStyle: .none)
                HStack {
                    Text(dayString)
                    Spacer()
                    Text("\(count) prenotazioni")
                }
            }
        )
    }
}
