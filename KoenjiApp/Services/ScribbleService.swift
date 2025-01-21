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

    init(layoutServices: LayoutServices) {
        self.layoutServices = layoutServices
        loadFromDisk() // Load previously saved scribbles
    }

    // MARK: - Save Scribble
    func saveDrawing(_ drawing: PKDrawing, for key: String, layer: String) {
        if cachedScribbles[key] == nil {
            cachedScribbles[key] = [:]
        }
        cachedScribbles[key]?[layer] = drawing
        saveToDisk() // Persist the updated scribbles
    }

    // MARK: - Load Scribble
    func loadDrawing(for key: String, layer: String) -> PKDrawing? {
        return cachedScribbles[key]?[layer]
    }

    // MARK: - Disk Persistence
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
                        return try PKDrawing(data: data)
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

        return drawingModel
    }
    
    func deleteAllScribbles() {
        cachedScribbles.removeAll()
        UserDefaults.standard.removeObject(forKey: "cachedScribbles")
        print("All scribbles have been deleted.")
    }
}
