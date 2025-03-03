//
//  PushAlerts.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 2/2/25.
//
import SwiftUI

@Observable

class PushAlerts {
    
    var alertMessage: String = ""
    var showAlert: Bool = false
    var activeAddAlert: AddReservationAlertType? = nil

}

enum AddReservationAlertType: Identifiable {
    case mondayConfirmation
    case editing
    case error(String)  // store an error message

    var id: String {
        switch self {
        case .mondayConfirmation: return "mondayConfirmation"
        case .editing: return "editing"
        case .error(let message): return "error_\(message)"
        }
    }
}
