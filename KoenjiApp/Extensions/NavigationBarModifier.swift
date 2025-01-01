//
//  NavigationBarModifier.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/1/25.
//


import SwiftUI
import UIKit

struct NavigationBarModifier: ViewModifier {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Apply blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Create a UIImage from the blur view
        let renderer = UIGraphicsImageRenderer(size: blurView.bounds.size)
        let image = renderer.image { ctx in
            blurView.layer.render(in: ctx.cgContext)
        }
        
        appearance.backgroundImage = image
        appearance.backgroundColor = UIColor.clear
        
        // Set shadow
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Additional customization if needed
            }
    }
}

extension View {
    func navigationBarWithTranslucentBackground() -> some View {
        self.modifier(NavigationBarModifier())
    }
}
