Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/GridData.swift...
# Documentation Suggestions for GridData.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/ViewModels/GridData.swift
Total suggestions: 92

## Class Documentation (12)

### GridData (Line 11)

**Context:**

```swift

import SwiftUI

class GridData: ObservableObject {
    
    private(set) var store: ReservationStore
    private(set) var gridBounds: CGRect = .zero
```

**Suggested Documentation:**

```swift
/// GridData class.
///
/// [Add a description of what this class does and its responsibilities]
```

### InnerGridBackground (Line 254)

**Context:**

```swift
            print("Grid bounds updated to: \(gridBounds)")
        }
    }
    struct InnerGridBackground: Shape {
        let rows: Int
        let cols: Int
        let borderFeatures: [BorderFeature]
```

**Suggested Documentation:**

```swift
/// InnerGridBackground class.
///
/// [Add a description of what this class does and its responsibilities]
```

### InnerGridLines (Line 277)

**Context:**

```swift
        }
    }
    
    struct InnerGridLines: Shape {
        let rows: Int
        let cols: Int
        let cellSize: CGFloat
```

**Suggested Documentation:**

```swift
/// InnerGridLines class.
///
/// [Add a description of what this class does and its responsibilities]
```

### BorderSide (Line 465)

**Context:**

```swift
    }
}

enum BorderSide {
    case top, right, bottom, left
}

```

**Suggested Documentation:**

```swift
/// BorderSide class.
///
/// [Add a description of what this class does and its responsibilities]
```

### BorderFeatureType (Line 470)

**Context:**

```swift
}


enum BorderFeatureType {
    case indentation(indentation: Indentation)
    case hole(hole: Hole)
}
```

**Suggested Documentation:**

```swift
/// BorderFeatureType class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Indentation (Line 477)

**Context:**

```swift



struct Indentation: Identifiable {
    let id = UUID()
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
```

**Suggested Documentation:**

```swift
/// Indentation class.
///
/// [Add a description of what this class does and its responsibilities]
```

### IndentationSide (Line 485)

**Context:**

```swift
    let sides: IndentationSide  // Sides to draw for this indentation
}

struct IndentationSide: OptionSet {
    let rawValue: Int

    static let top    = IndentationSide(rawValue: 1 << 0)
```

**Suggested Documentation:**

```swift
/// IndentationSide class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Hole (Line 496)

**Context:**

```swift
    static let all: IndentationSide = [.top, .left, .bottom, .right]
}

struct Hole {
    let position: CGPoint // Starting point of the hole
    let span: Int         // Number of cells the hole spans
}
```

**Suggested Documentation:**

```swift
/// Hole class.
///
/// [Add a description of what this class does and its responsibilities]
```

### BorderFeature (Line 501)

**Context:**

```swift
    let span: Int         // Number of cells the hole spans
}

struct BorderFeature {
    let side: BorderSide
    let type: BorderFeatureType
}
```

**Suggested Documentation:**

```swift
/// BorderFeature class.
///
/// [Add a description of what this class does and its responsibilities]
```

### IndentationRegion (Line 507)

**Context:**

```swift
}


struct IndentationRegion {
    let rect: CGRect
}

```

**Suggested Documentation:**

```swift
/// IndentationRegion class.
///
/// [Add a description of what this class does and its responsibilities]
```

### BorderFeatureType (Line 513)

**Context:**

```swift



extension BorderFeatureType {
    func position() -> CGPoint? {
        switch self {
        case .indentation(let indentation):
```

**Suggested Documentation:**

```swift
/// BorderFeatureType class.
///
/// [Add a description of what this class does and its responsibilities]
```

### Path (Line 524)

**Context:**

```swift
    }
}

extension Path {
    mutating func addRoundedRect(in rect: CGRect, cornerSize: CGSize) {
        self.addPath(
            Path(roundedRect: rect, cornerRadius: cornerSize.width)
```

**Suggested Documentation:**

```swift
/// Path class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (13)

### configure (Line 28)

**Context:**

```swift
    
    
    
    func configure(store: ReservationStore, gridBounds: CGRect) {
        self.gridBounds = gridBounds
        // any code needing store
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the configure method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateExclusionRegions (Line 33)

**Context:**

```swift
        // any code needing store
    }
    
    func calculateExclusionRegions(
        borderFeatures: [BorderFeature],
        totalWidth: CGFloat,
        totalHeight: CGFloat
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateExclusionRegions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateExclusionRegions (Line 92)

**Context:**

```swift
        return regions
    }

    func updateExclusionRegions(
        borderFeatures: [BorderFeature],
        totalWidth: CGFloat,
        totalHeight: CGFloat
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateExclusionRegions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### borderSide (Line 105)

**Context:**

```swift
        print("Excluded Regions Updated: \(excludedRegions)")
    }
    
    func borderSide(from segmentIndex: Int) -> BorderSide {
        switch segmentIndex {
        case 0:
            return .top
```

**Suggested Documentation:**

```swift
/// [Add a description of what the borderSide method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### gridBackground (Line 121)

**Context:**

```swift
    }
    
    
    func gridBackground(selectedCategory: Reservation.ReservationCategory) -> some View {
        
        return GeometryReader { geometry in
            let rows = 15
```

**Suggested Documentation:**

```swift
/// [Add a description of what the gridBackground method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateGridBounds (Line 248)

**Context:**

```swift

    }
    
    func updateGridBounds(_ newBounds: CGRect) {
        if newBounds != gridBounds {
            gridBounds = newBounds
            print("Grid bounds updated to: \(gridBounds)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateGridBounds method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### path (Line 260)

**Context:**

```swift
        let borderFeatures: [BorderFeature]
        let excludedRegions: [CGRect] // Add this parameter

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // Draw a grid-covering rectangle (outer boundary)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the path method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### path (Line 283)

**Context:**

```swift
        let cellSize: CGFloat
        let borderFeatures: [BorderFeature]

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // Calculate total width and height
```

**Suggested Documentation:**

```swift
/// [Add a description of what the path method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### mergeRanges (Line 370)

**Context:**

```swift
        }

        // Merge overlapping ClosedRanges
        func mergeRanges(_ ranges: [ClosedRange<CGFloat>]) -> [ClosedRange<CGFloat>] {
            guard !ranges.isEmpty else { return [] }

            let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the mergeRanges method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### calculateIndentationRegions (Line 392)

**Context:**

```swift
        }

        // Helper Function to Calculate Indentation Regions
        func calculateIndentationRegions(
            borderFeatures: [BorderFeature],
            cellSize: CGFloat,
            totalWidth: CGFloat,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the calculateIndentationRegions method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### isBlockage (Line 445)

**Context:**

```swift
        }
    }
    
    func isBlockage(_ tableRect: CGRect) -> Bool {
        // Ensure the table is within the grid bounds
        guard gridBounds.contains(tableRect) else {
            print("TableRect is out of grid bounds.")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the isBlockage method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### position (Line 514)

**Context:**

```swift


extension BorderFeatureType {
    func position() -> CGPoint? {
        switch self {
        case .indentation(let indentation):
            return indentation.position
```

**Suggested Documentation:**

```swift
/// [Add a description of what the position method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### addRoundedRect (Line 525)

**Context:**

```swift
}

extension Path {
    mutating func addRoundedRect(in rect: CGRect, cornerSize: CGSize) {
        self.addPath(
            Path(roundedRect: rect, cornerRadius: cornerSize.width)
        )
```

**Suggested Documentation:**

```swift
/// [Add a description of what the addRoundedRect method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (67)

### store (Line 13)

**Context:**

```swift

class GridData: ObservableObject {
    
    private(set) var store: ReservationStore
    private(set) var gridBounds: CGRect = .zero

    @Published var excludedRegions: [CGRect] = []
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### gridBounds (Line 14)

**Context:**

```swift
class GridData: ObservableObject {
    
    private(set) var store: ReservationStore
    private(set) var gridBounds: CGRect = .zero

    @Published var excludedRegions: [CGRect] = []
    let cellSize: CGFloat = 40
```

**Suggested Documentation:**

```swift
/// [Description of the gridBounds property]
```

### excludedRegions (Line 16)

**Context:**

```swift
    private(set) var store: ReservationStore
    private(set) var gridBounds: CGRect = .zero

    @Published var excludedRegions: [CGRect] = []
    let cellSize: CGFloat = 40

    let totalRows: Int = 15
```

**Suggested Documentation:**

```swift
/// [Description of the excludedRegions property]
```

### cellSize (Line 17)

**Context:**

```swift
    private(set) var gridBounds: CGRect = .zero

    @Published var excludedRegions: [CGRect] = []
    let cellSize: CGFloat = 40

    let totalRows: Int = 15
    let totalColumns: Int = 18
```

**Suggested Documentation:**

```swift
/// [Description of the cellSize property]
```

### totalRows (Line 19)

**Context:**

```swift
    @Published var excludedRegions: [CGRect] = []
    let cellSize: CGFloat = 40

    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    init(store: ReservationStore) {
```

**Suggested Documentation:**

```swift
/// [Description of the totalRows property]
```

### totalColumns (Line 20)

**Context:**

```swift
    let cellSize: CGFloat = 40

    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    init(store: ReservationStore) {
        self.store = store
```

**Suggested Documentation:**

```swift
/// [Description of the totalColumns property]
```

### regions (Line 38)

**Context:**

```swift
        totalWidth: CGFloat,
        totalHeight: CGFloat
    ) -> [CGRect] {
        var regions: [CGRect] = []

        for feature in borderFeatures {
            switch feature.type {
```

**Suggested Documentation:**

```swift
/// [Description of the regions property]
```

### indentation (Line 42)

**Context:**

```swift

        for feature in borderFeatures {
            switch feature.type {
            case .indentation(let indentation):
                let rect: CGRect
                switch feature.side {
                case .top:
```

**Suggested Documentation:**

```swift
/// [Description of the indentation property]
```

### rect (Line 43)

**Context:**

```swift
        for feature in borderFeatures {
            switch feature.type {
            case .indentation(let indentation):
                let rect: CGRect
                switch feature.side {
                case .top:
                    rect = CGRect(
```

**Suggested Documentation:**

```swift
/// [Description of the rect property]
```

### hole (Line 75)

**Context:**

```swift
                    )
                }
                regions.append(rect)
            case .hole(let hole):
                let rect = CGRect(
                    x: hole.position.x,
                    y: hole.position.y,
```

**Suggested Documentation:**

```swift
/// [Description of the hole property]
```

### rect (Line 76)

**Context:**

```swift
                }
                regions.append(rect)
            case .hole(let hole):
                let rect = CGRect(
                    x: hole.position.x,
                    y: hole.position.y,
                    width: CGFloat(hole.span) * cellSize,
```

**Suggested Documentation:**

```swift
/// [Description of the rect property]
```

### rows (Line 124)

**Context:**

```swift
    func gridBackground(selectedCategory: Reservation.ReservationCategory) -> some View {
        
        return GeometryReader { geometry in
            let rows = 15
            let cols = 18
            let totalWidth = CGFloat(cols) * self.cellSize
            let totalHeight = CGFloat(rows) * self.cellSize
```

**Suggested Documentation:**

```swift
/// [Description of the rows property]
```

### cols (Line 125)

**Context:**

```swift
        
        return GeometryReader { geometry in
            let rows = 15
            let cols = 18
            let totalWidth = CGFloat(cols) * self.cellSize
            let totalHeight = CGFloat(rows) * self.cellSize

```

**Suggested Documentation:**

```swift
/// [Description of the cols property]
```

### totalWidth (Line 126)

**Context:**

```swift
        return GeometryReader { geometry in
            let rows = 15
            let cols = 18
            let totalWidth = CGFloat(cols) * self.cellSize
            let totalHeight = CGFloat(rows) * self.cellSize

            
```

**Suggested Documentation:**

```swift
/// [Description of the totalWidth property]
```

### totalHeight (Line 127)

**Context:**

```swift
            let rows = 15
            let cols = 18
            let totalWidth = CGFloat(cols) * self.cellSize
            let totalHeight = CGFloat(rows) * self.cellSize

            
            
```

**Suggested Documentation:**

```swift
/// [Description of the totalHeight property]
```

### borderFeatures (Line 132)

**Context:**

```swift
            
            
            // Define the border features with both indentations and holes
            let borderFeatures: [BorderFeature] = [
                
                
                BorderFeature(
```

**Suggested Documentation:**

```swift
/// [Description of the borderFeatures property]
```

### excludedRegions (Line 201)

**Context:**

```swift
            ZStack {
            
                
                let excludedRegions = self.calculateExclusionRegions(
                                borderFeatures: borderFeatures,
                                totalWidth: totalWidth,
                                totalHeight: totalHeight
```

**Suggested Documentation:**

```swift
/// [Description of the excludedRegions property]
```

### rows (Line 255)

**Context:**

```swift
        }
    }
    struct InnerGridBackground: Shape {
        let rows: Int
        let cols: Int
        let borderFeatures: [BorderFeature]
        let excludedRegions: [CGRect] // Add this parameter
```

**Suggested Documentation:**

```swift
/// [Description of the rows property]
```

### cols (Line 256)

**Context:**

```swift
    }
    struct InnerGridBackground: Shape {
        let rows: Int
        let cols: Int
        let borderFeatures: [BorderFeature]
        let excludedRegions: [CGRect] // Add this parameter

```

**Suggested Documentation:**

```swift
/// [Description of the cols property]
```

### borderFeatures (Line 257)

**Context:**

```swift
    struct InnerGridBackground: Shape {
        let rows: Int
        let cols: Int
        let borderFeatures: [BorderFeature]
        let excludedRegions: [CGRect] // Add this parameter

        func path(in rect: CGRect) -> Path {
```

**Suggested Documentation:**

```swift
/// [Description of the borderFeatures property]
```

### excludedRegions (Line 258)

**Context:**

```swift
        let rows: Int
        let cols: Int
        let borderFeatures: [BorderFeature]
        let excludedRegions: [CGRect] // Add this parameter

        func path(in rect: CGRect) -> Path {
            var path = Path()
```

**Suggested Documentation:**

```swift
/// [Description of the excludedRegions property]
```

### path (Line 261)

**Context:**

```swift
        let excludedRegions: [CGRect] // Add this parameter

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // Draw a grid-covering rectangle (outer boundary)
            // path.addRect(rect)
```

**Suggested Documentation:**

```swift
/// [Description of the path property]
```

### roundedRect (Line 268)

**Context:**

```swift

            // Subtract exclusion regions (rounded rectangles)
            for region in excludedRegions {
                let roundedRect = CGRect(x: region.origin.x, y: region.origin.y, width: region.width, height: region.height)
                let cornerRadius: CGFloat = 8.0
                path.addRoundedRect(in: roundedRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }
```

**Suggested Documentation:**

```swift
/// [Description of the roundedRect property]
```

### cornerRadius (Line 269)

**Context:**

```swift
            // Subtract exclusion regions (rounded rectangles)
            for region in excludedRegions {
                let roundedRect = CGRect(x: region.origin.x, y: region.origin.y, width: region.width, height: region.height)
                let cornerRadius: CGFloat = 8.0
                path.addRoundedRect(in: roundedRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }

```

**Suggested Documentation:**

```swift
/// [Description of the cornerRadius property]
```

### rows (Line 278)

**Context:**

```swift
    }
    
    struct InnerGridLines: Shape {
        let rows: Int
        let cols: Int
        let cellSize: CGFloat
        let borderFeatures: [BorderFeature]
```

**Suggested Documentation:**

```swift
/// [Description of the rows property]
```

### cols (Line 279)

**Context:**

```swift
    
    struct InnerGridLines: Shape {
        let rows: Int
        let cols: Int
        let cellSize: CGFloat
        let borderFeatures: [BorderFeature]

```

**Suggested Documentation:**

```swift
/// [Description of the cols property]
```

### cellSize (Line 280)

**Context:**

```swift
    struct InnerGridLines: Shape {
        let rows: Int
        let cols: Int
        let cellSize: CGFloat
        let borderFeatures: [BorderFeature]

        func path(in rect: CGRect) -> Path {
```

**Suggested Documentation:**

```swift
/// [Description of the cellSize property]
```

### borderFeatures (Line 281)

**Context:**

```swift
        let rows: Int
        let cols: Int
        let cellSize: CGFloat
        let borderFeatures: [BorderFeature]

        func path(in rect: CGRect) -> Path {
            var path = Path()
```

**Suggested Documentation:**

```swift
/// [Description of the borderFeatures property]
```

### path (Line 284)

**Context:**

```swift
        let borderFeatures: [BorderFeature]

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // Calculate total width and height
            let totalWidth = CGFloat(cols) * cellSize
```

**Suggested Documentation:**

```swift
/// [Description of the path property]
```

### totalWidth (Line 287)

**Context:**

```swift
            var path = Path()

            // Calculate total width and height
            let totalWidth = CGFloat(cols) * cellSize
            let totalHeight = CGFloat(rows) * cellSize

            // Calculate indentation regions
```

**Suggested Documentation:**

```swift
/// [Description of the totalWidth property]
```

### totalHeight (Line 288)

**Context:**

```swift

            // Calculate total width and height
            let totalWidth = CGFloat(cols) * cellSize
            let totalHeight = CGFloat(rows) * cellSize

            // Calculate indentation regions
            let indentationRegions = calculateIndentationRegions(
```

**Suggested Documentation:**

```swift
/// [Description of the totalHeight property]
```

### indentationRegions (Line 291)

**Context:**

```swift
            let totalHeight = CGFloat(rows) * cellSize

            // Calculate indentation regions
            let indentationRegions = calculateIndentationRegions(
                borderFeatures: borderFeatures,
                cellSize: cellSize,
                totalWidth: totalWidth,
```

**Suggested Documentation:**

```swift
/// [Description of the indentationRegions property]
```

### y (Line 300)

**Context:**

```swift

            // Draw horizontal grid lines
            for row in 1..<rows {
                let y = CGFloat(row) * self.cellSize

                // Find all exclusion ranges for this horizontal line
                let exclusionRanges = indentationRegions
```

**Suggested Documentation:**

```swift
/// [Description of the y property]
```

### exclusionRanges (Line 303)

**Context:**

```swift
                let y = CGFloat(row) * self.cellSize

                // Find all exclusion ranges for this horizontal line
                let exclusionRanges = indentationRegions
                    .filter { y >= $0.rect.minY && y <= $0.rect.maxY }
                    .map { $0.rect.minX...$0.rect.maxX }

```

**Suggested Documentation:**

```swift
/// [Description of the exclusionRanges property]
```

### mergedExclusions (Line 308)

**Context:**

```swift
                    .map { $0.rect.minX...$0.rect.maxX }

                // Merge overlapping exclusion ranges
                let mergedExclusions = mergeRanges(exclusionRanges)

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
```

**Suggested Documentation:**

```swift
/// [Description of the mergedExclusions property]
```

### remainingSegments (Line 311)

**Context:**

```swift
                let mergedExclusions = mergeRanges(exclusionRanges)

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
                var currentStart = 0.0

                for exclusion in mergedExclusions {
```

**Suggested Documentation:**

```swift
/// [Description of the remainingSegments property]
```

### currentStart (Line 312)

**Context:**

```swift

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
                var currentStart = 0.0

                for exclusion in mergedExclusions {
                    if currentStart < exclusion.lowerBound {
```

**Suggested Documentation:**

```swift
/// [Description of the currentStart property]
```

### x (Line 334)

**Context:**

```swift

            // Draw vertical grid lines
            for col in 1..<cols {
                let x = CGFloat(col) * cellSize

                // Find all exclusion ranges for this vertical line
                let exclusionRanges = indentationRegions
```

**Suggested Documentation:**

```swift
/// [Description of the x property]
```

### exclusionRanges (Line 337)

**Context:**

```swift
                let x = CGFloat(col) * cellSize

                // Find all exclusion ranges for this vertical line
                let exclusionRanges = indentationRegions
                    .filter { x >= $0.rect.minX && x <= $0.rect.maxX }
                    .map { $0.rect.minY...$0.rect.maxY }

```

**Suggested Documentation:**

```swift
/// [Description of the exclusionRanges property]
```

### mergedExclusions (Line 342)

**Context:**

```swift
                    .map { $0.rect.minY...$0.rect.maxY }

                // Merge overlapping exclusion ranges
                let mergedExclusions = mergeRanges(exclusionRanges)

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
```

**Suggested Documentation:**

```swift
/// [Description of the mergedExclusions property]
```

### remainingSegments (Line 345)

**Context:**

```swift
                let mergedExclusions = mergeRanges(exclusionRanges)

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
                var currentStart = 0.0

                for exclusion in mergedExclusions {
```

**Suggested Documentation:**

```swift
/// [Description of the remainingSegments property]
```

### currentStart (Line 346)

**Context:**

```swift

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
                var currentStart = 0.0

                for exclusion in mergedExclusions {
                    if currentStart < exclusion.lowerBound {
```

**Suggested Documentation:**

```swift
/// [Description of the currentStart property]
```

### sorted (Line 373)

**Context:**

```swift
        func mergeRanges(_ ranges: [ClosedRange<CGFloat>]) -> [ClosedRange<CGFloat>] {
            guard !ranges.isEmpty else { return [] }

            let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
            var merged: [ClosedRange<CGFloat>] = [sorted[0]]

            for range in sorted.dropFirst() {
```

**Suggested Documentation:**

```swift
/// [Description of the sorted property]
```

### merged (Line 374)

**Context:**

```swift
            guard !ranges.isEmpty else { return [] }

            let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
            var merged: [ClosedRange<CGFloat>] = [sorted[0]]

            for range in sorted.dropFirst() {
                let last = merged.removeLast()
```

**Suggested Documentation:**

```swift
/// [Description of the merged property]
```

### last (Line 377)

**Context:**

```swift
            var merged: [ClosedRange<CGFloat>] = [sorted[0]]

            for range in sorted.dropFirst() {
                let last = merged.removeLast()
                if range.lowerBound <= last.upperBound {
                    // Overlapping or adjacent ranges, merge them
                    let newRange = last.lowerBound...max(last.upperBound, range.upperBound)
```

**Suggested Documentation:**

```swift
/// [Description of the last property]
```

### newRange (Line 380)

**Context:**

```swift
                let last = merged.removeLast()
                if range.lowerBound <= last.upperBound {
                    // Overlapping or adjacent ranges, merge them
                    let newRange = last.lowerBound...max(last.upperBound, range.upperBound)
                    merged.append(newRange)
                } else {
                    merged.append(last)
```

**Suggested Documentation:**

```swift
/// [Description of the newRange property]
```

### regions (Line 398)

**Context:**

```swift
            totalWidth: CGFloat,
            totalHeight: CGFloat
        ) -> [IndentationRegion] {
            var regions: [IndentationRegion] = []

            for feature in borderFeatures {
                switch feature.type {
```

**Suggested Documentation:**

```swift
/// [Description of the regions property]
```

### indentation (Line 402)

**Context:**

```swift

            for feature in borderFeatures {
                switch feature.type {
                case .indentation(let indentation):
                    let rect: CGRect
                    switch feature.side {
                    case .top:
```

**Suggested Documentation:**

```swift
/// [Description of the indentation property]
```

### rect (Line 403)

**Context:**

```swift
            for feature in borderFeatures {
                switch feature.type {
                case .indentation(let indentation):
                    let rect: CGRect
                    switch feature.side {
                    case .top:
                        rect = CGRect(
```

**Suggested Documentation:**

```swift
/// [Description of the rect property]
```

### id (Line 478)

**Context:**

```swift


struct Indentation: Identifiable {
    let id = UUID()
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
    let verticalSpan: Int       // Number of cells to move vertically
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### position (Line 479)

**Context:**

```swift

struct Indentation: Identifiable {
    let id = UUID()
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
    let verticalSpan: Int       // Number of cells to move vertically
    let sides: IndentationSide  // Sides to draw for this indentation
```

**Suggested Documentation:**

```swift
/// [Description of the position property]
```

### horizontalSpan (Line 480)

**Context:**

```swift
struct Indentation: Identifiable {
    let id = UUID()
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
    let verticalSpan: Int       // Number of cells to move vertically
    let sides: IndentationSide  // Sides to draw for this indentation
}
```

**Suggested Documentation:**

```swift
/// [Description of the horizontalSpan property]
```

### verticalSpan (Line 481)

**Context:**

```swift
    let id = UUID()
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
    let verticalSpan: Int       // Number of cells to move vertically
    let sides: IndentationSide  // Sides to draw for this indentation
}

```

**Suggested Documentation:**

```swift
/// [Description of the verticalSpan property]
```

### sides (Line 482)

**Context:**

```swift
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
    let verticalSpan: Int       // Number of cells to move vertically
    let sides: IndentationSide  // Sides to draw for this indentation
}

struct IndentationSide: OptionSet {
```

**Suggested Documentation:**

```swift
/// [Description of the sides property]
```

### rawValue (Line 486)

**Context:**

```swift
}

struct IndentationSide: OptionSet {
    let rawValue: Int

    static let top    = IndentationSide(rawValue: 1 << 0)
    static let left   = IndentationSide(rawValue: 1 << 1)
```

**Suggested Documentation:**

```swift
/// [Description of the rawValue property]
```

### top (Line 488)

**Context:**

```swift
struct IndentationSide: OptionSet {
    let rawValue: Int

    static let top    = IndentationSide(rawValue: 1 << 0)
    static let left   = IndentationSide(rawValue: 1 << 1)
    static let bottom = IndentationSide(rawValue: 1 << 2)
    static let right  = IndentationSide(rawValue: 1 << 3)
```

**Suggested Documentation:**

```swift
/// [Description of the top property]
```

### left (Line 489)

**Context:**

```swift
    let rawValue: Int

    static let top    = IndentationSide(rawValue: 1 << 0)
    static let left   = IndentationSide(rawValue: 1 << 1)
    static let bottom = IndentationSide(rawValue: 1 << 2)
    static let right  = IndentationSide(rawValue: 1 << 3)

```

**Suggested Documentation:**

```swift
/// [Description of the left property]
```

### bottom (Line 490)

**Context:**

```swift

    static let top    = IndentationSide(rawValue: 1 << 0)
    static let left   = IndentationSide(rawValue: 1 << 1)
    static let bottom = IndentationSide(rawValue: 1 << 2)
    static let right  = IndentationSide(rawValue: 1 << 3)

    static let all: IndentationSide = [.top, .left, .bottom, .right]
```

**Suggested Documentation:**

```swift
/// [Description of the bottom property]
```

### right (Line 491)

**Context:**

```swift
    static let top    = IndentationSide(rawValue: 1 << 0)
    static let left   = IndentationSide(rawValue: 1 << 1)
    static let bottom = IndentationSide(rawValue: 1 << 2)
    static let right  = IndentationSide(rawValue: 1 << 3)

    static let all: IndentationSide = [.top, .left, .bottom, .right]
}
```

**Suggested Documentation:**

```swift
/// [Description of the right property]
```

### all (Line 493)

**Context:**

```swift
    static let bottom = IndentationSide(rawValue: 1 << 2)
    static let right  = IndentationSide(rawValue: 1 << 3)

    static let all: IndentationSide = [.top, .left, .bottom, .right]
}

struct Hole {
```

**Suggested Documentation:**

```swift
/// [Description of the all property]
```

### position (Line 497)

**Context:**

```swift
}

struct Hole {
    let position: CGPoint // Starting point of the hole
    let span: Int         // Number of cells the hole spans
}

```

**Suggested Documentation:**

```swift
/// [Description of the position property]
```

### span (Line 498)

**Context:**

```swift

struct Hole {
    let position: CGPoint // Starting point of the hole
    let span: Int         // Number of cells the hole spans
}

struct BorderFeature {
```

**Suggested Documentation:**

```swift
/// [Description of the span property]
```

### side (Line 502)

**Context:**

```swift
}

struct BorderFeature {
    let side: BorderSide
    let type: BorderFeatureType
}

```

**Suggested Documentation:**

```swift
/// [Description of the side property]
```

### type (Line 503)

**Context:**

```swift

struct BorderFeature {
    let side: BorderSide
    let type: BorderFeatureType
}


```

**Suggested Documentation:**

```swift
/// [Description of the type property]
```

### rect (Line 508)

**Context:**

```swift


struct IndentationRegion {
    let rect: CGRect
}


```

**Suggested Documentation:**

```swift
/// [Description of the rect property]
```

### indentation (Line 516)

**Context:**

```swift
extension BorderFeatureType {
    func position() -> CGPoint? {
        switch self {
        case .indentation(let indentation):
            return indentation.position
        case .hole(let hole):
            return hole.position
```

**Suggested Documentation:**

```swift
/// [Description of the indentation property]
```

### hole (Line 518)

**Context:**

```swift
        switch self {
        case .indentation(let indentation):
            return indentation.position
        case .hole(let hole):
            return hole.position
        }
    }
```

**Suggested Documentation:**

```swift
/// [Description of the hole property]
```


Total documentation suggestions: 92

