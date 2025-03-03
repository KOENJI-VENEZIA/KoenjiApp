//
//  ExportReservationsView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//


import SwiftUI
import UniformTypeIdentifiers
import os

struct ExportReservationsView: UIViewControllerRepresentable {
    private static let logger = Logger(
        subsystem: "com.koenjiapp",
        category: "ExportReservationsView"
    )
    
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Initialize for exporting
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ExportReservationsView
        
        init(parent: ExportReservationsView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Confirm the file was saved
            if let savedURL = urls.first {
                ExportReservationsView.logger.notice("File exported successfully to: \(savedURL.path)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            ExportReservationsView.logger.notice("Export canceled by user")
        }
    }
}
