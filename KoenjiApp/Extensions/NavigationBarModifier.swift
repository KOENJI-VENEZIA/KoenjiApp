//
//  NavigationBarModifier.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 3/1/25.
//


import SwiftUI
import UIKit

// A ViewModifier to configure the UINavigationController's navigation bar
struct NavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NavigationConfigurator { navigationController in
                // Ensure large titles are preferred
                navigationController.navigationBar.prefersLargeTitles = true
                navigationController.topViewController?.navigationItem.largeTitleDisplayMode = .always

                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                
                appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial) 
                
                navigationController.navigationBar.standardAppearance = appearance
                navigationController.navigationBar.scrollEdgeAppearance = appearance
                navigationController.navigationBar.compactAppearance = appearance
            })
    }
}

// A helper UIViewControllerRepresentable to configure UINavigationController
struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        // Perform configuration in `viewDidAppear` to ensure the navigation controller is available
        DispatchQueue.main.async {
            if let navigationController = viewController.navigationController {
                self.configure(navigationController)
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// Extension to easily apply the modifier
extension View {
    func navigationBarTitleDisplayModeAlwaysLarge() -> some View {
        self.modifier(NavigationBarModifier())
    }
}