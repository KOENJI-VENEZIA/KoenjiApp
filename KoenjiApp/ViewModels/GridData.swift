//
//  GridData.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 3/1/25.
//


import SwiftUI

class GridData: ObservableObject {
    
    private(set) var store: ReservationStore
    private(set) var gridBounds: CGRect = .zero

    @Published var excludedRegions: [CGRect] = []
    let cellSize: CGFloat = 40

    let totalRows: Int = 15
    let totalColumns: Int = 18
    
    init(store: ReservationStore) {
        self.store = store
    }
    
    
    
    func configure(store: ReservationStore, gridBounds: CGRect) {
        self.gridBounds = gridBounds
        // any code needing store
    }
    
    func calculateExclusionRegions(
        borderFeatures: [BorderFeature],
        totalWidth: CGFloat,
        totalHeight: CGFloat
    ) -> [CGRect] {
        var regions: [CGRect] = []

        for feature in borderFeatures {
            switch feature.type {
            case .indentation(let indentation):
                let rect: CGRect
                switch feature.side {
                case .top:
                    rect = CGRect(
                        x: indentation.position.x,
                        y: indentation.position.y,
                        width: CGFloat(indentation.horizontalSpan) * cellSize,
                        height: CGFloat(indentation.verticalSpan) * cellSize
                    )
                case .bottom:
                    rect = CGRect(
                        x: indentation.position.x,
                        y: indentation.position.y - CGFloat(indentation.verticalSpan) * cellSize,
                        width: CGFloat(indentation.horizontalSpan) * cellSize,
                        height: CGFloat(indentation.verticalSpan) * cellSize
                    )
                case .left:
                    rect = CGRect(
                        x: indentation.position.x,
                        y: indentation.position.y,
                        width: CGFloat(indentation.horizontalSpan) * cellSize,
                        height: CGFloat(indentation.verticalSpan) * cellSize
                    )
                case .right:
                    rect = CGRect(
                        x: indentation.position.x - CGFloat(indentation.horizontalSpan) * cellSize,
                        y: indentation.position.y,
                        width: CGFloat(indentation.horizontalSpan) * cellSize,
                        height: CGFloat(indentation.verticalSpan) * cellSize
                    )
                }
                regions.append(rect)
            case .hole(let hole):
                let rect = CGRect(
                    x: hole.position.x,
                    y: hole.position.y,
                    width: CGFloat(hole.span) * cellSize,
                    height: 0
                    
                )
                regions.append(rect)
                // Handle corner indentations similarly if needed
                break
            }
        }

        return regions
    }

    func updateExclusionRegions(
        borderFeatures: [BorderFeature],
        totalWidth: CGFloat,
        totalHeight: CGFloat
    ) {
        excludedRegions = calculateExclusionRegions(
            borderFeatures: borderFeatures,
            totalWidth: totalWidth,
            totalHeight: totalHeight
        )
        print("Excluded Regions Updated: \(excludedRegions)")
    }
    
    func borderSide(from segmentIndex: Int) -> BorderSide {
        switch segmentIndex {
        case 0:
            return .top
        case 1:
            return .right
        case 2:
            return .bottom
        case 3:
            return .left
        default:
            return .top
        }
    }
    
    
    func gridBackground(selectedCategory: Reservation.ReservationCategory) -> some View {
        
        return GeometryReader { geometry in
            let rows = 15
            let cols = 18
            let totalWidth = CGFloat(cols) * self.cellSize
            let totalHeight = CGFloat(rows) * self.cellSize

            
            
            // Define the border features with both indentations and holes
            let borderFeatures: [BorderFeature] = [
                
                
                BorderFeature(
                    side: .top,
                    type: .hole(
                        hole: Hole(
                            position: CGPoint(x: self.cellSize * 2, y: 0),
                            span: 4
                        )
                    )
                ),
                BorderFeature(
                    side: .top,
                    type: .hole(
                        hole: Hole(
                            position: CGPoint(x: self.cellSize * 12, y: 0),
                            span: 4
                        )
                    )
                ),
                BorderFeature(
                    side: .right,
                    type: .indentation(
                        indentation: Indentation(
                            position: CGPoint(x: totalWidth, y: self.cellSize * 11),
                            horizontalSpan: 4,
                            verticalSpan: 4,
                            sides: [.top, .left]
                        )
                    )
                ),
                BorderFeature(
                    side: .right,
                    type: .hole(
                        hole: Hole(
                            position: CGPoint(x: totalWidth, y: self.cellSize * 4),
                            span: 7
                        )
                    )
                ),
                BorderFeature(
                    side: .bottom,
                    type: .hole(
                        hole: Hole(
                            position: CGPoint(x: totalWidth - (self.cellSize*4), y: totalHeight),
                            span: 4
                        )
                    )
                ),
                 BorderFeature(
                    side: .bottom,
                    type: .indentation(
                        indentation: Indentation(
                            position: CGPoint(x: self.cellSize * 5, y: totalHeight),
                            horizontalSpan: 5,
                            verticalSpan: 3,
                            sides: [.top, .left, .right]
                        )
                    )
                ),

            ]
            
            

            ZStack {
            
                
                let excludedRegions = self.calculateExclusionRegions(
                                borderFeatures: borderFeatures,
                                totalWidth: totalWidth,
                                totalHeight: totalHeight
                            )
                
                InnerGridBackground(
                        rows: rows,
                        cols: cols,
                        borderFeatures: borderFeatures,
                        excludedRegions: excludedRegions
                )
                .fill(selectedCategory == .lunch ? Color(hex: "#3E3B2E") : Color(hex: "#2D2F43").opacity(0))
                .stroke(.white, lineWidth: 2)
                // Background color or pattern

                // Inner Grid Lines excluding Indentation Regions
                InnerGridLines(
                    rows: rows,
                    cols: cols,
                    cellSize: self.cellSize,
                    borderFeatures: borderFeatures
                )
                .stroke(
                    selectedCategory == .lunch ? Color.stroke_color_lunch.opacity(0.5) : Color.stroke_color_dinner.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, lineJoin: .round, dash: [2, 5])
                )
            }
            .frame(width: totalWidth, height: totalHeight)
            .onAppear {
                self.updateExclusionRegions(
                               borderFeatures: borderFeatures,
                               totalWidth: totalWidth,
                               totalHeight: totalHeight
                           )
            }
            .onAppear {
                self.updateGridBounds(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))
            }
            .onChange(of: geometry.size) { 
                self.updateGridBounds(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))
            }
        }

    }
    
    func updateGridBounds(_ newBounds: CGRect) {
        if newBounds != gridBounds {
            gridBounds = newBounds
            print("Grid bounds updated to: \(gridBounds)")
        }
    }
    struct InnerGridBackground: Shape {
        let rows: Int
        let cols: Int
        let borderFeatures: [BorderFeature]
        let excludedRegions: [CGRect] // Add this parameter

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // Draw a grid-covering rectangle (outer boundary)
            // path.addRect(rect)

            // Subtract exclusion regions (rounded rectangles)
            for region in excludedRegions {
                let roundedRect = CGRect(x: region.origin.x, y: region.origin.y, width: region.width, height: region.height)
                let cornerRadius: CGFloat = 8.0
                path.addRoundedRect(in: roundedRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            }

            return path
        }
    }
    
    struct InnerGridLines: Shape {
        let rows: Int
        let cols: Int
        let cellSize: CGFloat
        let borderFeatures: [BorderFeature]

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // Calculate total width and height
            let totalWidth = CGFloat(cols) * cellSize
            let totalHeight = CGFloat(rows) * cellSize

            // Calculate indentation regions
            let indentationRegions = calculateIndentationRegions(
                borderFeatures: borderFeatures,
                cellSize: cellSize,
                totalWidth: totalWidth,
                totalHeight: totalHeight
            )

            // Draw horizontal grid lines
            for row in 1..<rows {
                let y = CGFloat(row) * self.cellSize

                // Find all exclusion ranges for this horizontal line
                let exclusionRanges = indentationRegions
                    .filter { y >= $0.rect.minY && y <= $0.rect.maxY }
                    .map { $0.rect.minX...$0.rect.maxX }

                // Merge overlapping exclusion ranges
                let mergedExclusions = mergeRanges(exclusionRanges)

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
                var currentStart = 0.0

                for exclusion in mergedExclusions {
                    if currentStart < exclusion.lowerBound {
                        remainingSegments.append(currentStart...exclusion.lowerBound)
                    }
                    currentStart = exclusion.upperBound
                }

                if currentStart < totalWidth {
                    remainingSegments.append(currentStart...totalWidth)
                }

                // Draw remaining segments
                for segment in remainingSegments {
                    path.move(to: CGPoint(x: segment.lowerBound, y: y))
                    path.addLine(to: CGPoint(x: segment.upperBound, y: y))
                }
            }

            // Draw vertical grid lines
            for col in 1..<cols {
                let x = CGFloat(col) * cellSize

                // Find all exclusion ranges for this vertical line
                let exclusionRanges = indentationRegions
                    .filter { x >= $0.rect.minX && x <= $0.rect.maxX }
                    .map { $0.rect.minY...$0.rect.maxY }

                // Merge overlapping exclusion ranges
                let mergedExclusions = mergeRanges(exclusionRanges)

                // Compute remaining segments by excluding mergedExclusions from full range
                var remainingSegments: [ClosedRange<CGFloat>] = []
                var currentStart = 0.0

                for exclusion in mergedExclusions {
                    if currentStart < exclusion.lowerBound {
                        remainingSegments.append(currentStart...exclusion.lowerBound)
                    }
                    currentStart = exclusion.upperBound
                }

                if currentStart < totalHeight {
                    remainingSegments.append(currentStart...totalHeight)
                }

                // Draw remaining segments
                for segment in remainingSegments {
                    path.move(to: CGPoint(x: x, y: segment.lowerBound))
                    path.addLine(to: CGPoint(x: x, y: segment.upperBound))
                }
            }

            return path
        }

        // Merge overlapping ClosedRanges
        func mergeRanges(_ ranges: [ClosedRange<CGFloat>]) -> [ClosedRange<CGFloat>] {
            guard !ranges.isEmpty else { return [] }

            let sorted = ranges.sorted { $0.lowerBound < $1.lowerBound }
            var merged: [ClosedRange<CGFloat>] = [sorted[0]]

            for range in sorted.dropFirst() {
                let last = merged.removeLast()
                if range.lowerBound <= last.upperBound {
                    // Overlapping or adjacent ranges, merge them
                    let newRange = last.lowerBound...max(last.upperBound, range.upperBound)
                    merged.append(newRange)
                } else {
                    merged.append(last)
                    merged.append(range)
                }
            }

            return merged
        }

        // Helper Function to Calculate Indentation Regions
        func calculateIndentationRegions(
            borderFeatures: [BorderFeature],
            cellSize: CGFloat,
            totalWidth: CGFloat,
            totalHeight: CGFloat
        ) -> [IndentationRegion] {
            var regions: [IndentationRegion] = []

            for feature in borderFeatures {
                switch feature.type {
                case .indentation(let indentation):
                    let rect: CGRect
                    switch feature.side {
                    case .top:
                        rect = CGRect(
                            x: indentation.position.x,
                            y: indentation.position.y,
                            width: CGFloat(indentation.horizontalSpan) * cellSize,
                            height: CGFloat(indentation.verticalSpan) * cellSize
                        )
                    case .bottom:
                        rect = CGRect(
                            x: indentation.position.x,
                            y: indentation.position.y - CGFloat(indentation.verticalSpan) * cellSize,
                            width: CGFloat(indentation.horizontalSpan) * cellSize,
                            height: CGFloat(indentation.verticalSpan) * cellSize
                        )
                    case .left:
                        rect = CGRect(
                            x: indentation.position.x,
                            y: indentation.position.y,
                            width: CGFloat(indentation.horizontalSpan) * cellSize,
                            height: CGFloat(indentation.verticalSpan) * cellSize
                        )
                    case .right:
                        rect = CGRect(
                            x: indentation.position.x - CGFloat(indentation.horizontalSpan) * cellSize,
                            y: indentation.position.y,
                            width: CGFloat(indentation.horizontalSpan) * cellSize,
                            height: CGFloat(indentation.verticalSpan) * cellSize
                        )
                    }
                    regions.append(IndentationRegion(rect: rect))
                case .hole:
                    // Holes do not affect grid lines
                    continue
                }
            }

            return regions
        }
    }
    
    func isBlockage(_ tableRect: CGRect) -> Bool {
        // Ensure the table is within the grid bounds
        guard gridBounds.contains(tableRect) else {
            print("TableRect is out of grid bounds.")
            return false
        }

        // Check if the table overlaps any excluded region
        for region in excludedRegions {
            if tableRect.intersects(region) {
                print("TableRect intersects with excluded region: \(region).")
                return false
            }
        }

        // If no blockage is detected, return true
        return true
    }
}

enum BorderSide {
    case top, right, bottom, left
}


enum BorderFeatureType {
    case indentation(indentation: Indentation)
    case hole(hole: Hole)
}



struct Indentation: Identifiable {
    let id = UUID()
    let position: CGPoint       // Starting point of the indentation
    let horizontalSpan: Int     // Number of cells to move horizontally
    let verticalSpan: Int       // Number of cells to move vertically
    let sides: IndentationSide  // Sides to draw for this indentation
}

struct IndentationSide: OptionSet {
    let rawValue: Int

    static let top    = IndentationSide(rawValue: 1 << 0)
    static let left   = IndentationSide(rawValue: 1 << 1)
    static let bottom = IndentationSide(rawValue: 1 << 2)
    static let right  = IndentationSide(rawValue: 1 << 3)

    static let all: IndentationSide = [.top, .left, .bottom, .right]
}

struct Hole {
    let position: CGPoint // Starting point of the hole
    let span: Int         // Number of cells the hole spans
}

struct BorderFeature {
    let side: BorderSide
    let type: BorderFeatureType
}


struct IndentationRegion {
    let rect: CGRect
}



extension BorderFeatureType {
    func position() -> CGPoint? {
        switch self {
        case .indentation(let indentation):
            return indentation.position
        case .hole(let hole):
            return hole.position
        }
    }
}

extension Path {
    mutating func addRoundedRect(in rect: CGRect, cornerSize: CGSize) {
        self.addPath(
            Path(roundedRect: rect, cornerRadius: cornerSize.width)
        )
    }
}
