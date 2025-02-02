//
//  LayoutUnitViewModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//

import SwiftUI
import PencilKit
import ScreenshotSwiftUI

@Observable
class LayoutUnitViewModel {
    
    var dates: [Date] = []
    var selectedIndex: Int = 15

    var systemTime: Date = Date()
    var isManuallyOverridden: Bool = false
    var showInspector: Bool = false
    var showingDatePicker: Bool = false

    var showingAddReservationSheet: Bool = false
    var tableForNewReservation: TableModel? = nil

    var showingNoBookingAlert: Bool = false
    var isLayoutLocked: Bool = true
    var isZoomLocked: Bool = false
    var isLayoutReset: Bool = false

    var isScribbleModeEnabled: Bool = false
    var drawings: [String: PKDrawing] = [:]

    var toolPickerShows = false

    var capturedImage: UIImage? = nil
    var cachedScreenshot: ScreenshotMaker?
    var isSharing: Bool = false
    var isPresented: Bool = false

    var refreshID = UUID()
    var scale: CGFloat = 1
    var isShowingFullImage: Bool = false
    
}
