//
//  TopToolbar.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//

import SwiftUI
import PencilKit

extension LayoutView {
    
    @ToolbarContentBuilder
    var topBarToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: toggleFullScreen) {
                Label("Toggle Full Screen", systemImage: appState.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: debugCache) {
                Label("Debug Cache", systemImage: "ladybug.slash.fill")
            }
            .id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: { withAnimation { unitView.isPresented.toggle() } }) {
                Label("Share Layout", systemImage: "square.and.arrow.up")
            }
            .id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                withAnimation {
                    env.scribbleService.deleteAllScribbles()
                    UserDefaults.standard.removeObject(forKey: "cachedScribbles")
                    currentDrawing.layer1 = PKDrawing()
                    currentDrawing.layer2 = PKDrawing()
                    currentDrawing.layer3 = PKDrawing()
                }
            }) {
                Label("Delete Current Scribble", systemImage: "trash")
            }
            .id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                withAnimation {
                    unitView.isScribbleModeEnabled.toggle()
                    unitView.toolPickerShows.toggle()
                }
            }) {
                Label(unitView.isScribbleModeEnabled ? "Exit Scribble Mode" : "Enable Scribble",
                      systemImage: unitView.isScribbleModeEnabled ? "pencil.slash" : "pencil")
            }
            .id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation {
                    unitView.isLayoutLocked.toggle()
                }
                unitView.isZoomLocked.toggle()
            }) {
                Label(unitView.isLayoutLocked ? "Unlock Layout" : "Lock Layout",
                      systemImage: unitView.isLayoutLocked ? "lock.fill" : "lock.open.fill")
            }
            .tint(unitView.isLayoutLocked ? .red : .accentColor)
            .id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: resetLayout) {
                Label("Reset Layout", systemImage: "arrow.counterclockwise.circle")
            }
            .id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            addReservationButton.id(unitView.refreshID)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { withAnimation { unitView.showInspector.toggle() } }) {
                Label("Toggle Inspector", systemImage: "info.circle")
            }
            .id(unitView.refreshID)
        }
    }
    
    var addReservationButton: some View {
        Button {
            unitView.tableForNewReservation = nil
            unitView.showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(appState.selectedCategory == .noBookingZone)
        .foregroundColor(appState.selectedCategory == .noBookingZone ? .gray : .accentColor)
    }
    
}
