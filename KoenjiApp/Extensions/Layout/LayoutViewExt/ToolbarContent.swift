//
//  ToolbarContent.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//
import SwiftUI

extension LayoutView {

@ViewBuilder
    func toolbarContent(in geometry: GeometryProxy, selectedDate: Date) -> some View {
        switch toolbarManager.toolbarState {
        case .pinnedLeft, .pinnedRight:
            VStack {
                resetDate.padding(.vertical, 2)
                dateBackward.padding(.bottom, 2)
                dateForward.padding(.bottom, 2)
                datePicker(selectedDate: selectedDate).padding(.bottom, 2)
                resetTime.padding(.bottom, 2)
                timeBackward.padding(.bottom, 2)
                timeForward.padding(.bottom, 2)
                lunchButton.padding(.bottom, 2)
                dinnerButton.padding(.bottom, 2)
            }
        case .pinnedBottom:
            HStack(spacing: 25) {
                resetDate
                dateBackward
                dateForward
                datePicker(selectedDate: selectedDate)
                resetTime
                timeBackward
                timeForward
                lunchButton
                dinnerButton
            }
        }
    }
}
