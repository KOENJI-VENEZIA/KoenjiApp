//
//  AppDependenciesEnvironmentKey.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 6/3/25.
//

import SwiftUI

/// A key for the AppDependencies environment value
///
/// This key is used to access the AppDependencies instance in the environment.
struct AppDependenciesKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: AppDependencies? = nil
}

/// An extension on EnvironmentValues to provide a property for accessing the AppDependencies instance
///
/// This extension adds a property to the EnvironmentValues struct that allows easy access to the AppDependencies instance.
extension EnvironmentValues {
    var appDependencies: AppDependencies? {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
} 
