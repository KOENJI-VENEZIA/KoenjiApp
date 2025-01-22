//
//  ScribbleService.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//

import Foundation
import PencilKit

class ScribbleService: ObservableObject {
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
            print("Invalid drawing detected; skipping save.")
            return
        }
        scribbleQueue.sync {
            
            if cachedScribbles[key] == nil {
                cachedScribbles[key] = [:]
            }
            cachedScribbles[key]?[layer] = drawing
            saveToDisk()
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
        do {
            let data = try drawing.dataRepresentation()
            guard let decodedDrawing = try? PKDrawing(data: data) else {
                print("Failed to decode drawing from data.")
                return false
            }
            return decodedDrawing == drawing
        } catch {
            print("Error during validation: \(error)")
            return false
        }
    }
    
    private func saveToDisk() {
        let encoder = JSONEncoder()
        do {
            // Serialize drawings to base64 strings
            let serializedData = try cachedScribbles.mapValues { layers in
                try layers.mapValues { $0.dataRepresentation().base64EncodedString() }
            }
            let data = try encoder.encode(serializedData)
            UserDefaults.standard.set(data, forKey: "cachedScribbles")
            print("Scribbles saved successfully.")
        } catch {
            print("Failed to save scribbles: \(error)")
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
                            print("Invalid drawing data for layer: \(value)")
                            return PKDrawing() // Fallback to an empty drawing
                        }
                        return drawing
                    }
                }
                print("Scribbles loaded successfully: \(cachedScribbles.keys)")
            } catch {
                print("Failed to load scribbles: \(error)")
            }
        } else {
            print("No cached scribbles found.")
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
        print("All scribbles have been deleted.")
    }
}
