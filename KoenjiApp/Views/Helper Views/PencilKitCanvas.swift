//
//  PencilKitCanvas.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//


import SwiftUI
import PencilKit

final class SharedToolPicker: ObservableObject {
    let toolPicker: PKToolPicker
    
    init(window: UIWindow?) {
        if let window = window {
            // Create a new instance for this window.
            self.toolPicker = PKToolPicker()
            // Additional configuration if needed.
        } else {
            // Fallback instance.
            self.toolPicker = PKToolPicker()
        }
    }
}

struct PencilKitCanvas: UIViewRepresentable {
    @EnvironmentObject var drawingModel: DrawingModel
    @EnvironmentObject var sharedToolPicker: SharedToolPicker
    @ObservedObject var zoomableState: ZoomableScrollViewState
    enum Layer {
          case layer1
          case layer2
      }
    var layer: Layer
    var gridWidth: CGFloat?
    var gridHeight: CGFloat?
    var canvasSize: CGSize?
    var isEditable: Bool

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvas
        var toolPicker: PKToolPicker
        private var debounceTimer: Timer?
//        var exclusionAreaModel: ExclusionAreaModel  // regular property
        var isUpdatingFromModel = false // Flag to prevent infinite loop


        init(parent: PencilKitCanvas, toolPicker: PKToolPicker) {
                    self.parent = parent
                    self.toolPicker = toolPicker
                }
        
//        func setExclusionArea(_ area: CGRect) {
//            self.exclusionAreaModel.exclusionRect = area
//            }

        func setupToolPicker(for canvasView: PKCanvasView) {
                    if let window = canvasView.window {
                        toolPicker.setVisible(true, forFirstResponder: canvasView)
                        toolPicker.addObserver(canvasView)
                        canvasView.becomeFirstResponder()
                    }
                }
        
        

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isUpdatingFromModel else { return } // Skip if we're updating from the model

            DispatchQueue.main.async {
                var newDrawing = canvasView.drawing

                // Optional: Filter strokes based on exclusion area, but only for layer1
//                if self.parent.layer == .layer1 {
//                    let exclusionArea = self.exclusionAreaModel.exclusionRect
//                    let filteredStrokes = newDrawing.strokes.filter { stroke in
//                        // Keep strokes that do NOT intersect the exclusion area
//                        !stroke.path.intersects(exclusionArea)
//                    }
//                    newDrawing = PKDrawing(strokes: filteredStrokes)
//                }

                // Update the drawing model
                switch self.parent.layer {
                case .layer1:
                    if self.parent.drawingModel.layer1 != newDrawing {
                        self.parent.drawingModel.layer1 = newDrawing
                    }
                case .layer2:
                    if self.parent.drawingModel.layer2 != newDrawing {
                        self.parent.drawingModel.layer2 = newDrawing
                    }
                }
            }
        }
            
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, toolPicker: sharedToolPicker.toolPicker)

    }
    
    

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = getCurrentLayerDrawing() // Set initial drawing for the layer
        canvasView.isUserInteractionEnabled = isEditable
        canvasView.tool = sharedToolPicker.toolPicker.selectedTool

        canvasView.backgroundColor = UIColor.clear

        DispatchQueue.main.async {
            context.coordinator.setupToolPicker(for: canvasView)
        }
        
        // For Layer 1: Exclude the grid area from being drawable
//            if layer == .layer1, let gridWidth = gridWidth, let gridHeight = gridHeight, let canvasSize = canvasSize {
//                let gridRect = CGRect(
//                    x: (canvasSize.width - gridWidth) / 2,
//                    y: (canvasSize.height - gridHeight) / 2,
//                    width: gridWidth,
//                    height: gridHeight
//                )
//
//                // Apply exclusion logic to skip grid strokes
//                context.coordinator.setExclusionArea(gridRect)
//            }

        return canvasView
    }
    
    private func getCurrentLayerDrawing() -> PKDrawing {
        switch layer {
        case .layer1: return drawingModel.layer1
        case .layer2: return drawingModel.layer2
        }
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let currentDrawing = getCurrentLayerDrawing()

        if uiView.drawing != currentDrawing {
            context.coordinator.isUpdatingFromModel = true // Prevent feedback loop
            uiView.drawing = currentDrawing // Update the canvas view with the latest drawing
            context.coordinator.isUpdatingFromModel = false
        }

        uiView.isUserInteractionEnabled = isEditable

//        if let gridWidth = gridWidth, let gridHeight = gridHeight, let canvasSize = canvasSize {
//            let debugFrame = CGRect(
//                x: (canvasSize.width - gridWidth) / 2,
//                y: (canvasSize.height - gridHeight) / 2,
//                width: gridWidth,
//                height: gridHeight
//            )
//
//            print("Canvas Frame: \(debugFrame)")
//        }
    }
}

extension PKStrokePath {
    func intersects(_ rect: CGRect) -> Bool {
        for element in self {
            let point = element.location
            if rect.contains(point) {
                return true
            }
        }
        return false
    }
}
