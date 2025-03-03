//
//  LoadingOverlay.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 24/1/25.
//


import SwiftUI

struct LoadingOverlay: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.clear

            // Spinner in the corner
            VStack {
                Spacer()
            
                     HStack(spacing: 20) {
                         Spacer()
                         ZStack {
                             RoundedRectangle(cornerRadius: 20)
                                 .fill(.thinMaterial)
                                 .frame(maxWidth: 200, maxHeight: 30)
                             
                             HStack {
                                 Text("Salvataggio...")
                                     .padding()
                                     .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
                                 ProgressView()
                                     .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)))
                                     .padding()
                                     .cornerRadius(10)
                             }
                         }
                    }
                     .padding([.trailing, .bottom], 20)
                
            }
        }
    }
}

#Preview {
    LoadingOverlay()
}
