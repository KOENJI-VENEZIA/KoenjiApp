//
//  ScribbleService.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//

import Foundation
import PencilKit
import OSLog



class ScribbleService: ObservableObject {
    let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ScribbleService"
    )
    
    private let layoutServices: LayoutServices
    @Published var cachedScribbles: [String: [String: PKDrawing]] = [:]
    private let scribbleQueue = DispatchQueue(label: "com.koenjiapp.scribbleQueue")

    init(layoutServices: LayoutServices) {
        self.layoutServices = layoutServices
        loadFromDisk() // Load previously saved scribbles
    }

    // MARK: - Save Scribble
    func saveDrawing(_ drawing: PKDrawing, for key: String, layer: String) {
        if !validateDrawingData(drawing) {
            logger.error("Invalid drawing detected for key: \(key), layer: \(layer)")
            return
        }
        scribbleQueue.sync {
            if cachedScribbles[key] == nil {
                cachedScribbles[key] = [:]
            }
            cachedScribbles[key]?[layer] = drawing
            saveToDisk()
            logger.debug("Drawing saved successfully for key: \(key), layer: \(layer)")
        }
    }

    // MARK: - Load Scribble
    func loadDrawing(for key: String, layer: String) -> PKDrawing? {
        return scribbleQueue.sync {
            return cachedScribbles[key]?[layer]
        }
    }

    // MARK: - Disk Persistence
    
    func validateDrawingData(_ drawing: PKDrawing) -> Bool {
        let data = drawing.dataRepresentation()
        guard let decodedDrawing = try? PKDrawing(data: data) else {
            logger.error("Failed to decode drawing from data")
            return false
        }
        return decodedDrawing == drawing
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        do {
            // Serialize drawings to base64 strings
            let serializedData = cachedScribbles.mapValues { layers in
                layers.mapValues { $0.dataRepresentation().base64EncodedString() }
            }
            let data = try encoder.encode(serializedData)
            UserDefaults.standard.set(data, forKey: "cachedScribbles")
            logger.info("Scribbles saved successfully to disk")
        } catch {
            logger.error("Failed to save scribbles: \(error.localizedDescription)")
        }
    }

    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "cachedScribbles") {
            do {
                let decoded = try JSONDecoder().decode([String: [String: String]].self, from: data)
                cachedScribbles = try decoded.mapValues { layers in
                    try layers.mapValues { value in
                        guard let data = Data(base64Encoded: value) else { throw NSError() }
                        guard let drawing = try? PKDrawing(data: data) else {
                            logger.warning("Invalid drawing data for layer: \(value)")
                            return PKDrawing() // Fallback to an empty drawing
                        }
                        return drawing
                    }
                }
                logger.info("Scribbles loaded successfully. Found keys: \(self.cachedScribbles.keys)")
            } catch {
                logger.error("Failed to load scribbles: \(error)")
            }
        } else {
            logger.notice("No cached scribbles found")
        }
    }
    
    func reloadDrawings(for combinedDate: Date, category: Reservation.ReservationCategory) -> DrawingModel {
        let layoutKey = layoutServices.keyFor(date: combinedDate, category: category)
        let drawingModel = DrawingModel()

        // Load layer 1 or use an empty drawing
        drawingModel.layer1 = loadDrawing(for: layoutKey, layer: "layer1") ?? PKDrawing()
        
        // Load layer 2 or use an empty drawing
        drawingModel.layer2 = loadDrawing(for: layoutKey, layer: "layer2") ?? PKDrawing()
        
        drawingModel.layer3 = loadDrawing(for: layoutKey, layer: "layer3") ?? PKDrawing()


        return drawingModel
    }
    
    func deleteAllScribbles() {
        cachedScribbles.removeAll()
        UserDefaults.standard.removeObject(forKey: "cachedScribbles")
        logger.notice("All scribbles have been deleted")
    }
    
    func saveScribbleForCurrentLayout(_ currentDrawing: DrawingModel, _ currentLayoutKey: String) {
        logger.debug("Saving scribbles for layout key: \(currentLayoutKey)")

        saveDrawing(currentDrawing.layer1, for: currentLayoutKey, layer: "layer1")
        saveDrawing(currentDrawing.layer2, for: currentLayoutKey, layer: "layer2")
        saveDrawing(currentDrawing.layer3, for: currentLayoutKey, layer: "layer3")

        logger.info("All layers saved successfully for layout key: \(currentLayoutKey)")
    }
}
