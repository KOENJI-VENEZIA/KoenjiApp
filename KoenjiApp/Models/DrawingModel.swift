//
//  DrawingModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//


import PencilKit
import Combine
import SwiftUI

// MARK: - DrawingModel with Layers
class DrawingModel: ObservableObject {
    @Published var layer1: PKDrawing = PKDrawing() // Layer for the parent view
    @Published var layer2: PKDrawing = PKDrawing() // Layer for the child view}
    @Published var layer3: PKDrawing = PKDrawing()
}

