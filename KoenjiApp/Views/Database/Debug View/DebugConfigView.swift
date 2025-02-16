//
//  DebugConfigView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 1/2/25.
//
import SwiftUI

struct DebugConfigView: View {
    @Binding var daysToSimulate: Int
    var onGenerate: () -> Void
    var onResetData: () -> Void
    var onSaveDebugData: () -> Void
    var onFlushCaches: () -> Void
    var onParse: () -> Void

    @State private var isExporting = false
    @State private var document: ReservationsDocument?
    @State private var isImporting = false
    @State private var importedDocument: ReservationsDocument?

    @EnvironmentObject var env: AppDependencies

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Parametri Simulazione")) {
                    Stepper(
                        "Giorni da Simulare: \(daysToSimulate)",
                        value: $daysToSimulate, in: 1...365)
                    Button("Genera Dati di Debug") {
                        onGenerate()
                        dismissView()
                    }
                }

                Section(header: Text("Debug Tools")) {
                    Button(role: .destructive) {
                        onResetData()
                        dismissView()
                    } label: {
                        Label("Resetta Dati", systemImage: "trash")
                    }
                    
                    Button {
                        env.reservationService.migrateJSONBackupFromFirebase()
                    } label: {
                        Label("Converti backup", systemImage: "square.and.arrow.down.on.square")
                    }

                    Button {
                        onSaveDebugData()
                        dismissView()
                    } label: {
                        Label(
                            "Salva Dati Debug",
                            systemImage: "square.and.arrow.down")
                    }

                    Button {
                        dismissView()
                        onFlushCaches()
                    } label: {
                        Label(
                            "Azzera Cache", systemImage: "arrow.clockwise")
                    }

                    Button {
                        onParse()
                    } label: {
                        Label(
                            "Log Prenotazioni Salvate",
                            systemImage: "arrow.triangle.2.circlepath")
                    }


                }
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitle("Debug Config", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Annulla") {
                    dismissView()
                }
            )
        }
    }

    private func dismissView() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene
        else { return }
        windowScene.windows.first?.rootViewController?.dismiss(
            animated: true)
    }

    private func prepareExport() {
        // Generate the ReservationsDocument with current reservations
        let reservations = getReservations()  // Replace with your actual reservations
        document = ReservationsDocument(reservations: reservations)
        isExporting = true
    }

    private func getReservations() -> [Reservation] {
        // Replace this with your actual reservations from ReservationService
        return env.store.reservations

    }

}
