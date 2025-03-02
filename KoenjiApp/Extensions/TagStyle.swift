//
//  TagStyle.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/3/25.
//


import SwiftUI

/// Common styling for all tag-based toolbar items to ensure consistent appearance
struct TagStyle {
    // Fixed dimensions for all tags
    static let height: CGFloat = 32
    static let horizontalPadding: CGFloat = 8
    static let verticalPadding: CGFloat = 4
    static let cornerRadius: CGFloat = 12
    static let iconSpacing: CGFloat = 6
    
    // Common font for all tags
    static let font: Font = .caption.weight(.semibold)
    
    // Opacity values
    static let backgroundOpacity: Double = 0.12
    static let borderOpacity: Double = 0.3
    static let borderWidth: CGFloat = 1
}

// View extension to apply the tag style
extension View {
    func apply(_ style: TagStyle.Type, color: Color) -> some View {
        self
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .frame(height: style.height)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(color.opacity(style.backgroundOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: style.cornerRadius)
                            .stroke(color.opacity(style.borderOpacity), lineWidth: style.borderWidth)
                    )
            )
            .foregroundColor(color)
    }
}
