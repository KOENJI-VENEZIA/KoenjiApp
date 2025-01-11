//
//  NavigationBarHeightHelper.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 10/1/25.
//


import UIKit
import SwiftUI

struct NavigationBarHeightHelper: UIViewControllerRepresentable {
    @Binding var navigationBarHeight: CGFloat

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            if let navigationController = viewController.navigationController {
                navigationBarHeight = navigationController.navigationBar.frame.height
            } else {
                navigationBarHeight = 0 // Fallback if not embedded in a UINavigationController
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}