//
//  ColorHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 27/1/25.
//
import Foundation
import SwiftUI

struct ColorHelper {
    
    static func colorForUUID(_ uuid: UUID) -> Color {
        let hashValue = abs(uuid.hashValue) // Get the absolute hash value of the UUID
        let hue = Double(hashValue % 360) / 360.0 // Map the hash to a hue value between 0 and 1
        return Color(hue: hue, saturation: 0.6, brightness: 0.8) // Use a fixed saturation and brightness
    }
    
}
