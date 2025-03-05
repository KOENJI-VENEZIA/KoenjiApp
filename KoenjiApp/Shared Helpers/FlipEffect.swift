//
//  FlipEffect.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 17/1/25.
//


import SwiftUI

struct FlipEffect: AnimatableModifier {
    var rotation: Double
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    
    nonisolated var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: axis.x, y: axis.y, z: axis.z)
            )
    }
}

extension View {
    func flipEffect(rotation: Double, axis: (x: CGFloat, y: CGFloat, z: CGFloat)) -> some View {
        self.modifier(FlipEffect(rotation: rotation, axis: axis))
    }
}
