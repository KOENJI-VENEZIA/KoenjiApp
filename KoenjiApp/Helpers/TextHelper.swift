//
//  TextHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 29/1/25.
//

import SwiftUI
import Foundation

struct TextHelper {
    
    static func pluralized(_ singular: String, _ plural: String, _ count: Int) -> String {
        return count == 1 ? singular : plural
    }
}
