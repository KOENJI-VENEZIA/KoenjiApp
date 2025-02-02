//
//  ListViewModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 30/1/25.
//

import SwiftUI

enum ActiveSheet: Identifiable {
    case inspector(UUID)
    case addReservation
    case debugConfig

    var id: String {
        switch self {
        case .inspector(let id):
            return "inspector-\(id)"
        case .addReservation:
            return "addReservation"
        case .debugConfig:
            return "debugConfig"
        }
    }
}

@Observable
class ListViewModel {
    var searchText: String = ""
    var selectedFilters: Set<FilterOption> = [.none]
    var sortOption: SortOption? = .removeSorting
    var groupOption: GroupOption = .none
    var selectedReservationID: UUID?
    var showingNotesAlert: Bool = false
    var showingFilters: Bool = false
    var showRestoreSheet: Bool = false
    var activeSheet: ActiveSheet? = nil
    var showingResetConfirmation: Bool = false
    var currentReservations: [Reservation] = []
    var reservations: [Reservation] = []
    var currentReservation: Reservation? = nil
    var activeAlert: AddReservationAlertType? = nil
    var showPeoplePopover: Bool = false
    var showStartDatePopover: Bool = false
    var showEndDatePopover: Bool = false
    var notesToShow: String = ""
    var showTopControls: Bool = false
    var isFiltered: Bool = false
    var shouldReopenDebugConfig = false
    var selectedReservation: Reservation?
    var isShowingFullImage = false
    var refreshID = UUID()
    var hasSelectedPeople: Bool = false
    var hasSelectedStartDate: Bool = false
    var hasSelectedEndDate: Bool = false
    var changedReservation: Reservation?

    
    private var reservationService: ReservationService
    @ObservationIgnored private var store: ReservationStore
    @ObservationIgnored private var layoutServices: LayoutServices

    init(reservationService: ReservationService, store: ReservationStore, layoutServices: LayoutServices) {
        self.reservationService = reservationService
        self.store = store
        self.layoutServices = layoutServices
    }
    
    
    
    func handleEditTap(_ reservation: Reservation) {
            withAnimation {
                currentReservation = reservation
            }
        
    }
    
    @MainActor func handleCancel(_ reservation: Reservation) {

        if let idx = store.reservations.firstIndex(where: {
            $0.id == reservation.id
        }), var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .canceled
            reservation.tables = []
            reservationService.updateReservation(
                reservation) {
                    
                }
            changedReservation = reservation
        }
    }
    
    @MainActor func handleDelete(_ reservation: Reservation) {
            reservationService.deleteReservation(reservation)
            changedReservation = reservation
    }

    @MainActor
    func handleRecover(_ reservation: Reservation) {
        if let idx = store.reservations.firstIndex(where: { $0.id == reservation.id }),
           var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
            reservation.status = .pending
            let assignmentResult = layoutServices.assignTables(
                for: reservation, selectedTableID: nil)
            switch assignmentResult {
            case .success(let assignedTables):
                // Direct assignment on the main thread without async dispatch.
                reservation.tables = assignedTables
            case .failure(let error):
                switch error {
                case .noTablesLeft:
                    activeAlert = .error("Non ci sono tavoli disponibili.")
                case .insufficientTables:
                    activeAlert = .error("Non ci sono abbastanza tavoli per la prenotazione.")
                case .tableNotFound:
                    activeAlert = .error("Tavolo selezionato non trovato.")
                case .tableLocked:
                    activeAlert = .error("Il tavolo scelto è occupato o bloccato.")
                case .unknown:
                    activeAlert = .error("Errore sconosciuto.")
                }
                return
            }
            reservationService.updateReservation(
                reservation) {
                   
                }
            changedReservation = reservation
        }
    }
    
    func updatePeopleFilter() {
        selectedFilters.insert(.people)
        selectedFilters.remove(.none)  // Ensure `.none` is deselected
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
    }

    func updateDateFilter() {
        selectedFilters.insert(.date)
        selectedFilters.remove(.none)  // Ensure `.none` is deselected
        selectedFilters.remove(.canceled)  // Ensure `.canceled` is deselected
    }
    
    func toggleFilter(_ option: FilterOption) {
        switch option {
        case .none, .canceled, .toHandle, .deleted:
            // If selecting .none or .canceled, clear all and only add the selected one
            selectedFilters = [option]
        case .people, .date:
            // Allow multiselect for .people and .date
            selectedFilters.remove(.none)
            selectedFilters.remove(.canceled)
            if selectedFilters.contains(option) {
                selectedFilters.remove(option)
            } else {
                selectedFilters.insert(option)
            }
        }
    }

    
}
