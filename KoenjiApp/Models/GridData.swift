import SwiftUI

class GridData: ObservableObject {
    @Published var excludedRegions: [CGRect] = []
    @Published var gridBounds: CGRect = .zero
}