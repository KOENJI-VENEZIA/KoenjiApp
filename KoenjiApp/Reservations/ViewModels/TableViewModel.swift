//
//  TableViewModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/1/25.
//

import SwiftUI

@Observable class TableViewModel {
    var systemTime: Date = Date()
    var dragState: DragState = .idle
    var selectedTable: TableModel?
    var isDragging: Bool = false  // State to track dragging
    var isHeld: Bool = false  // State for long press hold
    var hasMoved: Bool = false
    var showEmojiPicker: Bool = false
    var showFullEmojiPicker: Bool = false
    var isContextMenuActive = false
    var selectedEmoji: String = ""
    var tapTimer: Timer?
    var debounceWorkItem: DispatchWorkItem?
    var isDoubleTap = false
    var currentActiveReservation: Reservation?
    var firstUpcomingReservation: Reservation?
    var lateReservation: Reservation?
    var nearEndReservation: Reservation?
    var isLate: Bool = false
    var showedUp: Bool = false
    var isManuallyOverridden: Bool = false

}
