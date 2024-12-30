//
//  ReservationListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

struct ReservationListView: View {
    @EnvironmentObject var store: ReservationStore
    
    @State private var searchDate = Date()
    @State private var filterPeople: Int? = nil
    @State private var filterStartDate: Date? = nil // Start date for interval
    @State private var filterEndDate: Date? = nil   // End date for interval
    @State private var selection = Set<UUID>() // multi-select
    
    @State private var showingAddReservation = false
    @State private var showingNotesAlert = false
    @State private var notesToShow: String = ""
    @State private var currentReservation: Reservation? = nil
    
    var filteredReservations: [Reservation] {
        store.reservations.filter { reservation in
            var matchesFilter = true
            
            // Filter by date interval if set
            if let start = filterStartDate, let end = filterEndDate {
                guard let reservationDate = reservation.date else { return false }
                matchesFilter = matchesFilter && (reservationDate >= start && reservationDate <= end)
            }
            
            // Filter by guest number if set
            if let filterP = filterPeople {
                matchesFilter = matchesFilter && (reservation.numberOfPersons == filterP)
            }
            
            return matchesFilter
        }
    }
    
    var body: some View {
        VStack {
            // Filter controls
            VStack(alignment: .leading) {
                // Guest number filter
                HStack {
                    if filterPeople == nil {
                        Button("Filtra per Numero Ospiti...") {
                            withAnimation {
                                filterPeople = 1
                            }
                        }
                        .padding(.top, 3)
                        .padding(.leading, 8.5)
                        .frame(height: 40)
                    }
                    
                    Spacer()
                    
                    if filterPeople != nil {
                        Stepper(value: Binding(
                            get: { filterPeople ?? 1 },
                            set: { newValue in
                                filterPeople = newValue
                            }
                        ), in: 1...14, step: 1) {
                            Text(filterPeople ?? 1 < 14 ? "Filtra per Numero Ospiti: da \(filterPeople ?? 1) in su" : "Filtra per Numero Ospiti: \(filterPeople ?? 1)")
                                .frame(height: 40)
                        }
                        Button("Rimuovi Filtro") {
                            withAnimation {
                                filterPeople = nil
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 8)
                
                // Date interval filter
                VStack(alignment: .leading) {
                    if filterStartDate == nil || filterEndDate == nil {
                        Button("Filtra per Intervallo di Date...") {
                            withAnimation {
                                filterStartDate = Date()
                                filterEndDate = Date()
                            }
                        }
                        .padding(.top, 3)
                        .padding(.leading, 8.5)
                        .frame(height: 40)
                    }
                    
                    if filterStartDate != nil && filterEndDate != nil {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Da data:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: Binding(
                                    get: { filterStartDate ?? Date() },
                                    set: { newValue in
                                        filterStartDate = newValue
                                    }
                                ), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("A data:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                DatePicker("", selection: Binding(
                                    get: { filterEndDate ?? Date() },
                                    set: { newValue in
                                        filterEndDate = newValue
                                    }
                                ), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            }
                            
                            Spacer()
                            
                            Button("Rimuovi Filtro") {
                                withAnimation {
                                    filterStartDate = nil
                                    filterEndDate = nil
                                }
                            }
                            .foregroundStyle(.red)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding()
            .animation(.easeInOut, value: filterPeople)
            .animation(.easeInOut, value: filterStartDate)
            
            // Reservation list
            List(selection: $selection) {
                ForEach(filteredReservations) { reservation in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(reservation.name) - \(reservation.numberOfPersons) pers.")
                                .font(.headline)
                            Text("Telefono: \(reservation.phone)")
                                .font(.subheadline)
                            Text("Tavolo: \(reservation.tables.map(\.name).joined(separator: ", "))")
                                .font(.subheadline)
                            Text("Data: \(reservation.dateString)")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        
                        Button {
                            currentReservation = reservation
                            notesToShow = reservation.notes?.isEmpty == false ?
                                reservation.notes! : "(no further notes)"
                            showingNotesAlert = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                    }
                    .tag(reservation.id)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Edit") {
                            currentReservation = reservation
                        }
                        Button("Delete", role: .destructive) {
                            if let idx = store.reservations.firstIndex(where: { $0.id == reservation.id }) {
                                store.deleteReservations(at: IndexSet(integer: idx))
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Tutte le prenotazioni")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddReservation = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddReservation) {
            AddReservationView(forcedTable: nil, preselectedDate: searchDate)
                .environmentObject(store)
        }
        .sheet(item: $currentReservation) { reservation in
            EditReservationView(reservation: reservation)
                .environmentObject(store)
        }
        .alert("Notes", isPresented: $showingNotesAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notesToShow)
        }
    }
    
    private func delete(at offsets: IndexSet) {
        store.deleteReservations(at: offsets)
    }
}
