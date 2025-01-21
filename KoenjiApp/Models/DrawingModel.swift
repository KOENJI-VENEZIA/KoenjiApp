//
//  DrawingModel.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//


import PencilKit
import Combine
import SwiftUI


class DrawingModel: ObservableObject {
    @Published var layer1: PKDrawing = PKDrawing() // Layer for the parent view
    @Published var layer2: PKDrawing = PKDrawing() // Layer for the child view}
}

class ExclusionAreaModel: ObservableObject {
    @Published var exclusionRect: CGRect = .zero
}


final class PencilToolState: ObservableObject {
    @Published var selectedTool: PKTool = PKInkingTool(.pen, color: .black, width: 5)
    // You can add more properties as needed (e.g., color, stroke width, etc.)
}
