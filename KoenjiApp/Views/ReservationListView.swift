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
    @State private var selection = Set<UUID>() // multi-select
    
    // *** CHANGED: Add sheet presentation to add a reservation
    @State private var showingAddReservation = false
    
    // For displaying notes in a popup
    @State private var showingNotesAlert = false
    @State private var notesToShow: String = ""
    @State private var currentReservation: Reservation? = nil
    
    var filteredReservations: [Reservation] {
        store.reservations.filter { reservation in
            var matchesFilter = true
            // Filter by date

            
            // Filter by # people if set
            if let filterP = filterPeople {
                matchesFilter = matchesFilter && (reservation.numberOfPersons == filterP)
            }
            
            return matchesFilter
        }
    }
    
    struct TestToolbar: View {
        var body: some View {
            NavigationView {
                Text("Hello, toolbar!")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("OK") {}
                        }
                    }
            }
        }
    }
    
    var body: some View {
        VStack {
            // Filter controls
            HStack {
                if filterPeople == nil {
                    Button("Filtra per Numero Ospiti...") {
                        filterPeople = 1
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
                        filterPeople = nil
                    }
                    .foregroundStyle(.red)
                }
            }
            .padding()
            
            
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
                        
                        // *** CHANGED: The "i" button to show notes popup
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
                    .onTapGesture {
                        currentReservation = reservation
                    }
                    .contextMenu {
                        Button("Edit") {
                            // show edit
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
            // *** CHANGED: Add a "+" button
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
        // *** CHANGED: Add Reservation sheet
        .sheet(isPresented: $showingAddReservation) {
            AddReservationView(
                selectedDate: searchDate,
                forcedTable: nil)
                .environmentObject(store)
        }
        .sheet(item: $currentReservation) { reservation in
            EditReservationView(reservation: reservation)
                .environmentObject(store)
        }
        // *** CHANGED: Show notes popup
        .alert("Notes", isPresented: $showingNotesAlert, actions: {
            Button("Edit") {
                // If you have an EditReservationView or you want to inline-edit the notes
                // you can present a sheet or do inline editing
            }
            Button("OK", role: .cancel) { }
        }, message: {
            Text(notesToShow)
        })
    }
    
    private func delete(at offsets: IndexSet) {
        store.deleteReservations(at: offsets)
    }
}
