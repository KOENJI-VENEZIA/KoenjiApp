//
//  ImportReservationsView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 23/1/25.
//


import SwiftUI
import UniformTypeIdentifiers

struct ImportReservationsView: UIViewControllerRepresentable {
    var onImport: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImport: onImport)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onImport: (URL) -> Void

        init(onImport: @escaping (URL) -> Void) {
            self.onImport = onImport
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let selectedURL = urls.first {
                onImport(selectedURL)
            }
        }
    }
}