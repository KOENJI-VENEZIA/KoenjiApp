//
//  Toolbar.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/1/25.
//

import SwiftUI

struct ToolbarExtended: View {

    let geometry: GeometryProxy
    @Binding var toolbarState: ToolbarState
    let small: Bool
    var timeline: Bool = false

    var body: some View {

            // MARK: Background (RoundedRectangle)
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(
                    width: toolbarState != .pinnedBottom
                    ? 80  // 20% of the available width (you can tweak the factor)
                    : (small ? geometry.size.width * 0.7 : geometry.size.width * 0.9 ),  // 90% of the available width when pinned bottom
                    height: toolbarState != .pinnedBottom
                    ? (small ? (timeline ? geometry.size.height * 0.4 : geometry.size.height * 0.7) : geometry.size.height * 0.9 )  // 90% of the available height when vertical
                    : 80  // 15% of the available height when horizontal
                )
    }
    
}


struct ToolbarMinimized: View {
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .frame(width: 90, height: 90)
            
            Image(systemName: "slider.horizontal.3")
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    colorScheme == .dark ? Color(hex: "A3B7D2") : Color(hex: "#6c7ba3")
                )
                .frame(width: 50, height: 50)
        }
        
    }
}
