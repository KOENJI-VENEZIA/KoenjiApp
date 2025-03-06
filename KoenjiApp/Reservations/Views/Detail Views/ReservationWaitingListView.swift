//
//  ReservationWaitingListView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI
import SwipeActions
import FirebaseFirestore

struct ReservationWaitingListView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selection = Set<UUID>()
    @State private var isLoading = false
    @State private var waitingListReservations: [Reservation] = []
    
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onConfirm: (Reservation) -> Void
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading waiting list...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    let filtered = waitingListReservations
                    let grouped = groupByCategory(filtered)
                    
                    if !grouped.isEmpty {
                        ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                            Section(
                                header: HStack(spacing: 10) {
                                    Text(groupKey)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    Text("\(grouped[groupKey]?.count ?? 0) in lista d'attesa")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .background(.clear)
                                .padding(.vertical, 4)
                            ) {
                                ForEach(grouped[groupKey] ?? []) { reservation in
                                    SwipeView {
                                        ReservationRows(
                                            reservation: reservation,
                                            onSelected: { newReservation in
                                                onEdit(newReservation)
                                            }
                                        )
                                    } trailingActions: { _ in
                                        SwipeAction(
                                            systemImage: "checkmark.circle.fill",
                                            backgroundColor: .green.opacity(0.2)
                                        ) {
                                            handleConfirm(reservation)
                                            onConfirm(reservation)
                                        }
                                        
                                        SwipeAction(
                                            systemImage: "square.and.pencil",
                                            backgroundColor: .gray.opacity(0.2)
                                        ) {
                                            onEdit(reservation)
                                        }
                                    }
                                    .swipeActionCornerRadius(12)
                                    .swipeMinimumDistance(40)
                                    .swipeActionsMaskCornerRadius(12)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    } else {
                        Text("(Nessuna prenotazione in lista d'attesa)")
                            .font(.headline)
                            .padding()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            
            Button(action: onClose) {
                Text("Chiudi")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color.clear)
        .alert(isPresented: $env.pushAlerts.showAlert) {
            Alert(
                title: Text("Errore:"),
                message: Text(env.pushAlerts.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadWaitingListReservations()
        }
        .onChange(of: appState.selectedDate) { _, _ in
            loadWaitingListReservations()
        }
        .onChange(of: appState.changedReservation) { _, _ in
            loadWaitingListReservations()
        }
    }
    
    private func loadWaitingListReservations() {
        isLoading = true
        Task {
            do {
                // Fetch all waiting list reservations for the date directly from Firebase
                let targetDateString = DateHelper.formatDate(appState.selectedDate)
                let db = Firestore.firestore()
                
                #if DEBUG
                let reservationsRef = db.collection("reservations")
                #else
                let reservationsRef = db.collection("reservations_release")
                #endif
                
                let snapshot = try await reservationsRef
                    .whereField("dateString", isEqualTo: targetDateString)
                    .whereField("reservationType", isEqualTo: "waitingList")
                    .getDocuments()
                
                var results: [Reservation] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    if let reservation = try? reservationFromFirebaseData(data) {
                        results.append(reservation)
                    } else {
                        print("Failed to decode reservation from document: \(document.documentID)")
                    }
                }
                
                await MainActor.run {
                    self.waitingListReservations = results
                    isLoading = false
                }
            } catch {
                print("Error fetching waiting list reservations: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    /// Converts Firebase document data to a Reservation object
    private func reservationFromFirebaseData(_ data: [String: Any]) throws -> Reservation {
        // Extract basic fields
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let phone = data["phone"] as? String,
              let numberOfPersons = data["numberOfPersons"] as? Int,
              let dateString = data["dateString"] as? String,
              let categoryString = data["category"] as? String,
              let category = Reservation.ReservationCategory(rawValue: categoryString),
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let acceptanceString = data["acceptance"] as? String,
              let acceptance = Reservation.Acceptance(rawValue: acceptanceString),
              let statusString = data["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let reservationTypeString = data["reservationType"] as? String,
              let reservationType = Reservation.ReservationType(rawValue: reservationTypeString),
              let group = data["group"] as? Bool,
              let creationTimeInterval = data["creationDate"] as? TimeInterval,
              let lastEditedTimeInterval = data["lastEditedOn"] as? TimeInterval,
              let isMock = data["isMock"] as? Bool else {
            throw NSError(domain: "com.koenjiapp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
        }
        
        // Extract tables
        var tables: [TableModel] = []
        if let tablesData = data["tables"] as? [[String: Any]] {
            for tableData in tablesData {
                if let tableId = tableData["id"] as? Int,
                   let tableName = tableData["name"] as? String,
                   let maxCapacity = tableData["maxCapacity"] as? Int {
                    let table = TableModel(id: tableId, name: tableName, maxCapacity: maxCapacity, row: 0, column: 0)
                    tables.append(table)
                }
            }
        } else if let tableIds = data["tableIds"] as? [Int] {
            // Fallback to tableIds if tables array is not available
            tables = tableIds.map { id in
                TableModel(id: id, name: "Table \(id)", maxCapacity: 4, row: 0, column: 0)
            }
        }
        
        // Extract optional fields
        let notes = data["notes"] as? String
        let assignedEmoji = data["assignedEmoji"] as? String
        let imageData = data["imageData"] as? Data
        let preferredLanguage = data["preferredLanguage"] as? String
        let colorHue = data["colorHue"] as? Double ?? 0.0
        
        // Create and return the reservation
        return Reservation(
            id: id,
            name: name,
            phone: phone,
            numberOfPersons: numberOfPersons,
            dateString: dateString,
            category: category,
            startTime: startTime,
            endTime: endTime,
            acceptance: acceptance,
            status: status,
            reservationType: reservationType,
            group: group,
            notes: notes,
            tables: tables,
            creationDate: Date(timeIntervalSince1970: creationTimeInterval),
            lastEditedOn: Date(timeIntervalSince1970: lastEditedTimeInterval),
            isMock: isMock,
            assignedEmoji: assignedEmoji ?? "",
            imageData: imageData,
            preferredLanguage: preferredLanguage
        )
    }
    
    private func groupByCategory(_ reservations: [Reservation]) -> [String: [Reservation]] {
        var grouped: [String: [Reservation]] = [:]
        for reservation in reservations {
            var category: Reservation.ReservationCategory = .lunch
            if reservation.category == .dinner {
                category = .dinner
            }
            let key = "\(category.localized.capitalized)"
            grouped[key, default: []].append(reservation)
        }
        return grouped
    }
    
    private func handleConfirm(_ reservation: Reservation) {
        var updatedReservation = reservation
        let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
        switch assignmentResult {
        case .success(let assignedTables):
            withAnimation {
                updatedReservation.tables = assignedTables
                updatedReservation.reservationType = .inAdvance
                updatedReservation.status = .pending
            }
            
            Task {
                do {
                    await env.reservationService.updateReservation(updatedReservation) {
                        print("Confirmed waiting list reservation with tables.")
                    }
                    
                    // Refresh the reservations after update
                    loadWaitingListReservations()
                } catch {
                    print("Error confirming waiting list reservation: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            withAnimation {
                updatedReservation.notes = (updatedReservation.notes ?? "") + String(localized: "\n[Non è stato possibile assegnare tavoli automaticamente - ") + "\(error)]"
            }
            
            Task {
                do {
                    await env.reservationService.updateReservation(updatedReservation) {
                        print("Could not assign tables due to error: \(error)")
                    }
                    
                    // Refresh the reservations after update
                    loadWaitingListReservations()
                } catch {
                    print("Error updating waiting list reservation: \(error.localizedDescription)")
                }
            }
        }
    }
}
