//
//  CardSwapView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//
import SwiftUI

struct CardSwapView<Content: View>: View {
    
    @Binding var selectedIndex: Int
    let navigationDirection: NavigationDirection
    @Binding var rotationAngle: Double  // External control
    @Binding var isContentReady: Bool  // Parent tracks loading state
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
                .id(selectedIndex)
                .flipEffect(
                    rotation: rotationAngle,
                    axis: navigationDirection == .backward
                        ? (x: 0, y: -1, z: 0)
                        : (x: 0, y: 1, z: 0)
                )
//                .opacity(!isContentReady ? 1 : 0)  // Hide during loading
        }
        .onChange(of: selectedIndex) {
            guard !isContentReady else { return }  // Only animate when content is ready
            
            // Phase 1: Flip out
            withAnimation(.easeIn(duration: 0.2)) {
                rotationAngle = 45
            }
            // Phase 2: Flip in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    rotationAngle = 0
                }
            }
        }
    }
}
