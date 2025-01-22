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
    
    var animatableData: Double {
        get { rotation }
        set { rotation = newValue }
    }
    
    func body(content: Content) -> some View {
        // When the rotation exceeds 90°, you might choose to hide content behind the flip
        content
            .opacity(rotation > 10 && rotation < 350 ? 0 : 1)
            .rotation3DEffect(.degrees(rotation), axis: axis)
    }
}

extension View {
    func flipEffect(rotation: Double, axis: (x: CGFloat, y: CGFloat, z: CGFloat)) -> some View {
        self.modifier(FlipEffect(rotation: rotation, axis: axis))
    }
}
