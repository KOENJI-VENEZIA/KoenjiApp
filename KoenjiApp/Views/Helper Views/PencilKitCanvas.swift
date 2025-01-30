//
//  PencilKitCanvas.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//


import SwiftUI
import PencilKit

class SharedToolPicker: ObservableObject {
    @MainActor static let shared = SharedToolPicker()
    
    let toolPicker: PKToolPicker
    
    init() {
        // Create a new instance for this window.
        self.toolPicker = PKToolPicker()
        // Additional configuration if needed
    }
}

struct PencilKitCanvas: UIViewRepresentable {
    @EnvironmentObject var drawingModel: DrawingModel
    let sharedToolPicker = SharedToolPicker.shared
    @ObservedObject var zoomableState: ZoomableScrollViewState
    @Binding var toolPickerShows: Bool

    enum Layer {
          case layer1
          case layer2
        case layer3
      }
    var layer: Layer
    var gridWidth: CGFloat?
    var gridHeight: CGFloat?
    var canvasSize: CGSize?
    var isEditable: Bool

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvas
        let toolPicker = PKToolPicker()
        @Binding var toolPickerShows: Bool
        private var debounceTimer: Timer?
//        var exclusionAreaModel: ExclusionAreaModel  // regular property
        var isUpdatingFromModel = false // Flag to prevent infinite loop


        init(parent: PencilKitCanvas, toolPickerShows: Binding<Bool>) {
                    self.parent = parent
                    self._toolPickerShows = toolPickerShows
                }
        
//        func setExclusionArea(_ area: CGRect) {
//            self.exclusionAreaModel.exclusionRect = area
//            }

        func setupToolPicker(for canvasView: PKCanvasView) {
            if canvasView.window != nil {
                        toolPicker.setVisible(true, forFirstResponder: canvasView)
                        toolPicker.addObserver(canvasView)
                        if toolPickerShows {
                            canvasView.becomeFirstResponder()
                        }
                    }
                }
        
        

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isUpdatingFromModel else { return } // Prevent loops

            DispatchQueue.main.async {
                let newDrawing = canvasView.drawing

                // Update the drawing model only if there are changes
                switch self.parent.layer {
                case .layer1:
                    if self.parent.drawingModel.layer1 != newDrawing {
                        self.parent.drawingModel.layer1 = newDrawing
                    }
                case .layer2:
                    if self.parent.drawingModel.layer2 != newDrawing {
                        self.parent.drawingModel.layer2 = newDrawing
                    }
                case .layer3:
                    if self.parent.drawingModel.layer3 != newDrawing {
                        self.parent.drawingModel.layer3 = newDrawing
                    }
                }
            }
        }
            
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, toolPickerShows: $toolPickerShows)

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
        case .layer3: return drawingModel.layer3
        }
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let currentDrawing = getCurrentLayerDrawing()

        if uiView.drawing != currentDrawing {
            context.coordinator.isUpdatingFromModel = true
            uiView.drawing = currentDrawing
            context.coordinator.isUpdatingFromModel = false
        }

        uiView.isUserInteractionEnabled = isEditable
        
        sharedToolPicker.toolPicker.setVisible(toolPickerShows, forFirstResponder: uiView)
        sharedToolPicker.toolPicker.addObserver(uiView)
        if toolPickerShows {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
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
