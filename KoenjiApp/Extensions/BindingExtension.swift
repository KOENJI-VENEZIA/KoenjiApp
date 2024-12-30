//
//  BindingExtensions.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//
// BindingExtensions.swift
import SwiftUI

extension Binding where Value == String? {
    func orEmpty(_ defaultValue: String = "") -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
