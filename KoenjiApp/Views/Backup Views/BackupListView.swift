import SwiftUI

struct BackupListView: View {
    @State private var backupFiles: [(fileName: String, formattedDate: String, originalDate: Date?, reservationCount: Int?)] = []
    @State private var isLoading = true
    @State private var selectedBackup: String?
    @State private var showConfirmation = false
    
    @EnvironmentObject var backupService: FirebaseBackupService
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var store: ReservationStore
    
    @Binding var showRestoreSheet: Bool

    var body: some View {
        NavigationView {
            List(backupFiles, id: \.fileName) { backup in
                Button(action: {
                    selectedBackup = backup.fileName
                    showConfirmation = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(backup.formattedDate)
                                .font(.headline)
                            Text(backup.fileName)
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if let count = backup.reservationCount {
                                Text("\(count) \(TextHelper.pluralized("PRENOTAZIONE", "PRENOTAZIONI", count))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Caricamento…")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .background(.clear)
            .navigationTitle("Ripristino da backup")
            .onAppear {
                fetchBackupList()
            }
            .overlay(
                isLoading ? ProgressView("Caricamento...") : nil
            )
            .alert("Attenzione", isPresented: $showConfirmation) {
                Button("Annulla", role: .cancel) { }
                Button("Ripristina", role: .destructive) {
                    if let fileName = selectedBackup {
                        backupService.restoreBackup(fileName: fileName) {
                            print("Reservation service save called")
                            reservationService.saveReservationsToDisk()
                            let today = Calendar.current.startOfDay(for: Date())
                            print("Rescache preloadDates called")
                            print("Reservations in store: \(store.reservations.count)")
                            resCache.preloadDates(around: today, range: 5, reservations: store.reservations)
                            reservationService.automaticBackup()
                            showRestoreSheet = false
                        }
                    }
                }
            } message: {
                Text("Questa azione è irreversibile. Sei sicuro di voler proseguire?")
            }
            
        }
        .background(.clear)

    }
    
    private func fetchBackupList() {
        backupService.listBackups { result in
            switch result {
            case .success(let files):
                let formattedFiles = files.compactMap { fileName -> (String, String, Date?, Int?)? in
                    if let date = extractDate(from: fileName) {
                        let formattedDate = formatDate(date)
                        return (fileName, formattedDate, date, nil) // Reservation count initially nil
                    }
                    return nil
                }

                // Sort backups by date (latest first)
                self.backupFiles = formattedFiles.sorted { ($0.2 ?? Date.distantPast) > ($1.2 ?? Date.distantPast) }
                self.isLoading = false

                // Fetch reservation counts for each file
                for index in backupFiles.indices {
                    fetchReservationCount(from: backupFiles[index].fileName) { count in
                        DispatchQueue.main.async {
                            self.backupFiles[index].reservationCount = count
                        }
                    }
                }

            case .failure(let error):
                print("Failed to fetch backups: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    private func fetchReservationCount(from fileName: String, completion: @escaping (Int?) -> Void) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Download the backup file from Firebase Storage
        backupService.downloadBackup(fileName: fileName, to: tempURL) { result in
            switch result {
            case .success:
                do {
                    // Read file data
                    let backupData = try Data(contentsOf: tempURL)
                    let reservations = try JSONDecoder().decode([Reservation].self, from: backupData)
                    completion(reservations.count)
                } catch {
                    print("Error reading reservations from \(fileName): \(error)")
                    completion(nil)
                }

            case .failure(let error):
                print("Failed to download backup file: \(error)")
                completion(nil)
            }
        }
    }
    
    /// Extracts the date from the backup filename
    private func extractDate(from fileName: String) -> Date? {
        let pattern = #"ReservationsBackup\.json_(\d{4}-\d{2}-\d{2})_(\d{2}:\d{2})"#
        let regex = try? NSRegularExpression(pattern: pattern)

        if let match = regex?.firstMatch(in: fileName, range: NSRange(fileName.startIndex..., in: fileName)) {
            if let dateRange = Range(match.range(at: 1), in: fileName),
               let timeRange = Range(match.range(at: 2), in: fileName) {
                let dateString = fileName[dateRange]
                let timeString = fileName[timeRange]
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter.date(from: "\(dateString) \(timeString)")
            }
        }
        return nil
    }

    /// Formats a `Date` into a more readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy - HH:mm"
        formatter.locale = Locale(identifier: "it_IT") // Italian format
        return formatter.string(from: date)
    }
}
