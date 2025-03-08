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
    var sortOption: SortOption? = .chronologically
    var groupOption: GroupOption = .day
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
    var showFilterPopover: Bool = false
    var filterPeople: Int = 1
    var filterStartDate: Date = Date()
    var filterEndDate: Date = Date()

    /// Whether this view model is running in preview mode
    private let isPreview: Bool
    
    // Service dependencies
    private let reservationService: ReservationService
    private let store: ReservationStore
    private let layoutServices: LayoutServices

    init(reservationService: ReservationService, store: ReservationStore, layoutServices: LayoutServices, isPreview: Bool = false) {
        self.reservationService = reservationService
        self.store = store
        self.layoutServices = layoutServices
        self.isPreview = isPreview
        
        if isPreview {
            // In preview mode, populate with mock data
            self.reservations = MockData.mockReservations
            self.currentReservations = MockData.mockReservations
        } else {
            // In regular mode, load reservations from the store
            self.loadReservations()
        }
    }
    
    private func loadReservations() {
        self.reservations = store.reservations
    }
    
    func handleEditTap(_ reservation: Reservation) {
            withAnimation {
                currentReservation = reservation
            }
        
    }
    
    @MainActor func handleCancel(_ reservation: Reservation) {

        if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
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
           if var reservation = store.reservations.first(where: { $0.id == reservation.id }) {
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
                    activeAlert = .error(String(localized: "Non ci sono tavoli disponibili."))
                case .insufficientTables:
                    activeAlert = .error(String(localized: "Non ci sono abbastanza tavoli per la prenotazione."))
                case .tableNotFound:
                    activeAlert = .error(String(localized: "Tavolo selezionato non trovato."))
                case .tableLocked:
                    activeAlert = .error(String(localized: "Il tavolo scelto è occupato o bloccato."))
                case .unknown:
                    activeAlert = .error(String(localized: "Errore sconosciuto."))
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
        case .none, .canceled, .toHandle, .deleted, .waitingList, .webPending:
            // If selecting .none or .canceled, clear all and only add the selected one
            selectedFilters = [option]
        case .people, .date:
            // Allow multiselect for .people and .date
            selectedFilters.remove(.none)
            selectedFilters.remove(.canceled)
            selectedFilters.remove(.toHandle)
            selectedFilters.remove(.deleted)
            selectedFilters.remove(.waitingList)
            selectedFilters.remove(.webPending)
            if selectedFilters.contains(option) {
                selectedFilters.remove(option)
            } else {
                selectedFilters.insert(option)
            }
        }
    }

    
}
