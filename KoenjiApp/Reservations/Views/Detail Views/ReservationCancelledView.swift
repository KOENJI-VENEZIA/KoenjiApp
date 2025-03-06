//
//  ReservationCancelledView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 19/1/25.
//

import SwiftUI
import SwipeActions
import FirebaseFirestore

struct ReservationCancelledView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @State private var selection = Set<UUID>()  // Multi-select
    @State private var isLoading = false
    @State private var cancelledReservations: [Reservation] = []
    @Environment(\.colorScheme) var colorScheme

    let activeReservations: [Reservation]
    var currentTime: Date
    var onClose: () -> Void
    var onEdit: (Reservation) -> Void
    var onRestore: (Reservation) -> Void
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading cancelled reservations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    let filtered = cancelledReservations
                    let grouped = groupByCategory(filtered)
                    if !grouped.isEmpty {
                        ForEach(grouped.keys.sorted(by: >), id: \.self) { groupKey in
                            Section(
                                header: HStack(spacing: 10) {
                                    Text(groupKey)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    Text("\(grouped[groupKey]?.count ?? 0) cancellazioni")
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
                                            systemImage: "arrowshape.turn.up.backward.2.circle.fill",
                                            backgroundColor: .blue.opacity(0.2)
                                        ) {
                                            handleRestore(reservation)
                                            onRestore(reservation)
                                        }
                                        
                                    }
                                    .swipeActionCornerRadius(12)
                                    .swipeMinimumDistance(40)
                                    .swipeActionsMaskCornerRadius(12)
                                    .listRowSeparator(.visible)
                                    .listRowBackground(Color.clear)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                    } else {
                        Text("(Nessuna cancellazione)" )
                            .font(.headline)
                            .padding()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                    }
                    
                    Section {
                        
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                }
                .scrollContentBackground(.hidden)
                .listStyle(PlainListStyle())
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
        .onAppear {
            loadCancelledReservations()
        }
        .onChange(of: appState.changedReservation) { _, _ in
            loadCancelledReservations()
        }
    }
    
    private func loadCancelledReservations() {
        isLoading = true
        Task {
            do {
                // Fetch all reservations for the date directly from Firebase
                let targetDateString = DateHelper.formatDate(currentTime)
                let db = Firestore.firestore()
                
                #if DEBUG
                let reservationsRef = db.collection("reservations")
                #else
                let reservationsRef = db.collection("reservations_release")
                #endif
                
                let snapshot = try await reservationsRef
                    .whereField("dateString", isEqualTo: targetDateString)
                    .whereField("status", isEqualTo: "canceled")
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
                    self.cancelledReservations = results
                    isLoading = false
                }
            } catch {
                print("Error fetching cancelled reservations: \(error.localizedDescription)")
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
    
    private func groupByCategory(_ activeReservations: [Reservation]) -> [String:
        [Reservation]]
    {
        var grouped: [String: [Reservation]] = [:]
        for reservation in activeReservations {
            // Suppose reservation.tables is an array of Table objects
            // that each have an .id or .name property
            var category: Reservation.ReservationCategory = .lunch
           
            if reservation.category == .dinner {
                category = .dinner
            }

            let key = "\(category.localized.capitalized)"
            grouped[key, default: []].append(reservation)
        }

        return grouped
    }
    
    private func handleRestore(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status == .canceled {
            let assignmentResult = env.layoutServices.assignTables(for: updatedReservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                withAnimation {
                    updatedReservation.tables = assignedTables
                    updatedReservation.status = .pending
                }
                
                Task {
                    do {
                        await env.reservationService.updateReservation(updatedReservation) {
                            print("Restored reservation with tables.")
                        }
                        
                        // Refresh the reservations after update
                        loadCancelledReservations()
                    } catch {
                        print("Error restoring reservation: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                // If table assignment fails, still restore but without tables
                withAnimation {
                    updatedReservation.status = .pending
                    updatedReservation.tables = []
                    updatedReservation.notes = (updatedReservation.notes ?? "") + String(localized: "\n[Ripristinata senza tavoli - non è stato possibile riassegnare i tavoli automaticamente]")
                }
                
                Task {
                    do {
                        await env.reservationService.updateReservation(updatedReservation) {
                            print("Restored reservation without tables due to error: \(error)")
                        }
                        
                        // Refresh the reservations after update
                        loadCancelledReservations()
                    } catch {
                        print("Error restoring reservation without tables: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
