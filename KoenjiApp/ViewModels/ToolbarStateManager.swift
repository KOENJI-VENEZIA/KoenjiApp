//
//  ToolbarStateManager.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/1/25.
//
import SwiftUI
import Observation

enum NavigationDirection {
    case forward
    case backward
}

@Observable
class ToolbarStateManager {
     var isDragging: Bool = false
     var toolbarState: ToolbarState = .pinnedBottom
     var dragAmount: CGPoint = CGPoint.zero
     var isToolbarVisible: Bool = true
     var lastPinnedPosition: CGPoint = .zero
     var navigationDirection: NavigationDirection = .forward

    
    @MainActor func toolbarGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                self.isDragging = true
                
                var currentLocation = value.location
                let currentOffset = value.translation
                
                if self.toolbarState != .pinnedBottom {
                    currentLocation.y = (geometry.size.height / 2) + currentOffset.height
                } else {
                    currentLocation.x = (geometry.size.width / 2) + currentOffset.width
                }
                
                self.dragAmount = currentLocation
            }
            .onEnded { value in
                defer { self.isDragging = false }
                
                var currentLocation = value.location
                let currentOffset = value.translation
                
                // Handle toolbar visibility
                switch self.toolbarState {
                case .pinnedBottom where currentOffset.height > 0:
                    withAnimation { self.isToolbarVisible = false }
                case .pinnedLeft where currentOffset.width < 0:
                    withAnimation { self.isToolbarVisible = false }
                case .pinnedRight where currentOffset.width > 0:
                    withAnimation { self.isToolbarVisible = false }
                default: break
                }
                
                // Determine new toolbar state
                if currentLocation.y > geometry.size.height / 2 && currentOffset.height > 0
                    && (currentLocation.x > geometry.size.width / 2 && currentOffset.width < 0
                        || currentLocation.x < geometry.size.width / 2 && currentOffset.width > 0)
                {
                    withAnimation { self.toolbarState = .pinnedBottom }
                }
                else if currentLocation.x < geometry.size.width / 2 && currentOffset.width < 0
                            && currentOffset.height < 0
                {
                    self.toolbarState = .pinnedLeft
                }
                else if currentLocation.x > geometry.size.width / 2 && currentOffset.width > 0
                            && currentOffset.height < 0
                {
                    self.toolbarState = .pinnedRight
                }
                
                // Update final drag position
                switch self.toolbarState {
                case .pinnedLeft:
                    currentLocation.x = 60
                    currentLocation.y = geometry.size.height / 2
                    withAnimation { self.dragAmount = currentLocation }
                    
                case .pinnedRight:
                    currentLocation.x = geometry.size.width - 60
                    currentLocation.y = geometry.size.height / 2
                    withAnimation { self.dragAmount = currentLocation }
                    
                case .pinnedBottom:
                    currentLocation.x = geometry.size.width / 2
                    currentLocation.y = geometry.size.height - 30
                    withAnimation { self.dragAmount = currentLocation }
                }
            }
    }
    
    func calculatePosition(geometry: GeometryProxy) -> CGPoint {
        if toolbarState == .pinnedLeft {
            return CGPoint(x: 90, y: geometry.size.height / 2)
        } else if toolbarState == .pinnedRight {
            return CGPoint(x: geometry.size.width - 90, y: geometry.size.height / 2)
        } else if toolbarState == .pinnedBottom {
            return CGPoint(x: geometry.size.width / 2, y: geometry.size.height - 90)
        } else {
            return lastPinnedPosition
        }
    }
    
    func transitionForCurrentState(geometry: GeometryProxy) -> AnyTransition {
        switch toolbarState {

        case .pinnedLeft:
            return .move(edge: .leading)
        case .pinnedRight:
            return .move(edge: .trailing)
        case .pinnedBottom:
            return .move(edge: .bottom)
        }
    }

}

