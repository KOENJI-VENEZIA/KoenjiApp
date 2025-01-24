//
//  AppState.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//


import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var sidebarColor: Color = Color.sidebar_generic // Replace with your default color
    @Published var isWritingToFirebase = false
    
}
