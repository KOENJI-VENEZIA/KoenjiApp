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
        let content: () -> Content

        @State private var rotationAngle: Double = 0

        var body: some View {
            ZStack {
                content()
                    .id(selectedIndex)  // Ensure content refresh
                    .flipEffect(
                        rotation: rotationAngle,
                        axis: navigationDirection == .backward
                            ? (x: 0, y: -30, z: 0) : (x: 0, y: 30, z: 0))
            }
            .onChange(of: selectedIndex) {
                // Animate flip out
                withAnimation(.spring(duration: 0.3)) {
                    rotationAngle = 15
                }
                // Swap content once half-flipped (after animation delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(duration: 0.5)) {
                        rotationAngle = 0
                    }
                }
            }
        }
    }
