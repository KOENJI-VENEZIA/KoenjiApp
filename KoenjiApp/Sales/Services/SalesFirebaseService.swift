//
//  SalesFirebaseService.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 2/3/25.
//


import Foundation
import OSLog
import Firebase
import FirebaseFirestore

class SalesFirebaseService: ObservableObject {    
    private let db: Firestore?
    private let store: SalesStore
    private var salesListener: ListenerRegistration?
    
    /// Whether this service is in preview mode
    private var isPreview: Bool {
        db == nil
    }
    
    init(store: SalesStore, db: Firestore? = nil) {
        self.store = store
        
        // Check if we're running in preview mode
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        
        // Only initialize Firestore if not in preview mode
        if !isPreview {
            self.db = db ?? Firestore.firestore()
        } else {
            self.db = nil
            Task { @MainActor in
                AppLog.debug("Preview mode: Firestore not initialized")
            }
        }

        let safeIsPreview = isPreview
        
        Task { @MainActor in
            AppLog.debug("SalesFirebaseService initialized (preview mode: \(safeIsPreview))")
        }
    }
    
    // MARK: - Firestore Listeners
    
    @MainActor
    func startSalesListener() async {
        guard !isPreview, let db = db else {
            Task { @MainActor in
                AppLog.debug("Preview mode: Skipping sales listener")
            }
            
            // In preview mode, populate with mock data if needed
            if store.allSales.isEmpty {
                // Add some mock sales data for preview
                let today = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                
                // Create a few mock daily sales
                for i in -5...5 {
                    let mockDate = Calendar.current.date(byAdding: .day, value: i, to: today)!
                    let dateString = formatter.string(from: mockDate)
                    
                    let lunch = SaleCategory(
                        categoryType: .lunch,
                        letturaCassa: Double.random(in: 800...1500),
                        fatture: Double.random(in: 700...1400),
                        yami: Double.random(in: 100...300),
                        yamiPulito: Double.random(in: 80...250),
                        bento: Double.random(in: 100...300),
                        persone: Int.random(in: 30...80)
                    )
                    
                    let dinner = SaleCategory(
                        categoryType: .dinner,
                        letturaCassa: Double.random(in: 1200...2500),
                        fatture: Double.random(in: 1100...2300),
                        yami: Double.random(in: 150...400),
                        yamiPulito: Double.random(in: 120...350),
                        cocai: Double.random(in: 100...300)
                    )
                    
                    let mockSales = DailySales(
                        dateString: dateString,
                        lunch: lunch,
                        dinner: dinner,
                        lastEditedOn: Date()
                    )
                    
                    store.allSales.append(mockSales)
                }
            }
            
            return
        }
        
#if DEBUG
        let dbRef = db.collection("sales")
#else
        let dbRef = db.collection("sales_release")
#endif
        
        salesListener = dbRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                Task { @MainActor in
                    AppLog.error("Error listening for sales: \(error)")
                }
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            var salesByDate: [String: DailySales] = [:]
            for document in snapshot.documents {
                let data = document.data()
                if let dailySales = self?.convertDictionaryToDailySales(data: data) {
                    salesByDate[dailySales.dateString] = dailySales
                }
            }
            
            // Replace the entire in-memory store with unique values
            DispatchQueue.main.async {
                self?.store.setAllSales(Array(salesByDate.values))
                Task { @MainActor in
                    AppLog.debug("Listener updated sales data. Count: \(salesByDate.values.count)")
                }
            }
        }
    }
    
    @MainActor
    func stopSalesListener() {
        guard !isPreview else {
            return
        }
        
        salesListener?.remove()
        salesListener = nil
    }
    
    // MARK: - CRUD Operations
    
    func saveDailySales(_ dailySales: DailySales, completion: @escaping (Error?) -> Void) {
        guard !isPreview, let db = db else {
            Task { @MainActor in
                AppLog.debug("Preview mode: Skipping save sales data")
            }
            // In preview mode, just update the local store
            store.updateSales(dailySales)
            completion(nil)
            return
        }
        
        // Update the lastEditedOn timestamp
        var updatedSales = dailySales
        updatedSales.lastEditedOn = Date()
        
        do {
            let data = try convertDailySalesToDictionary(dailySales: updatedSales)
            
#if DEBUG
            let dbRef = db.collection("sales").document(updatedSales.dateString)
#else
            let dbRef = db.collection("sales_release").document(updatedSales.dateString)
#endif
            
            dbRef.setData(data) { error in
                if let error = error {
                    Task { @MainActor in
                        AppLog.error("Error saving sales data: \(error)")
                    }
                    completion(error)
                } else {
                    // Capture just the necessary value to avoid data races
                    let dateString = updatedSales.dateString
                    Task { @MainActor in
                        AppLog.debug("Successfully saved sales data for \(dateString)")
                    }
                    completion(nil)
                }
            }
        } catch {
            Task { @MainActor in
                AppLog.error("Error converting sales data: \(error)")
            }
            completion(error)
        }
    }
    
    // Delete all sales for a specific month in a specific year
    func deleteMonth(year: Int, month: Int, completion: @escaping (Error?) -> Void) {
        // Determine which collection to use based on environment
#if DEBUG
        let dbRef = db?.collection("sales")
#else
        let dbRef = db?.collection("sales_release")
#endif
        
        // Find and delete all documents for the specified year and month
        dbRef?.getDocuments { [weak self] (snapshot, error) in
            guard let snapshot = snapshot else {
                completion(error)
                return
            }
            
            let batch = self?.db?.batch()
            var deletedCount = 0
            
            for document in snapshot.documents {
                guard let dateString = document.data()["dateString"] as? String,
                      let date = DateHelper.parseDate(dateString),
                      let documentsYear = Calendar.current.dateComponents([.year], from: date).year,
                      let documentsMonth = Calendar.current.dateComponents([.month], from: date).month,
                      documentsYear == year && documentsMonth == month else {
                    continue
                }
                
                // Add this document to the batch delete
                batch?.deleteDocument(document.reference)
                deletedCount += 1
            }
            
            // Commit the batch if there are documents to delete
            if deletedCount > 0 {
                batch?.commit { error in
                    if let error = error {
                        Task { @MainActor in
                            AppLog.error("Error deleting month \(month) in year \(year): \(error)")
                        }
                        completion(error)
                    } else {
                        let deletedCount = deletedCount
                        Task { @MainActor in
                            AppLog.debug("Deleted \(deletedCount) sales documents for month \(month) in year \(year)")
                        }
                        completion(nil)
                    }
                }
            } else {
                // No documents to delete
                completion(nil)
            }
        }
    }
    
    // Delete all sales for a specific year
    func deleteYear(_ year: Int, completion: @escaping (Error?) -> Void) {
        // Determine which collection to use based on environment
#if DEBUG
        let dbRef = db?.collection("sales")
#else
        let dbRef = db?.collection("sales_release")
#endif
        
        // Find and delete all documents for the specified year
        dbRef?.getDocuments { [weak self] (snapshot, error) in
            guard let snapshot = snapshot else {
                completion(error)
                return
            }
            
            let batch = self?.db?.batch()
            var deletedCount = 0
            
            for document in snapshot.documents {
                guard let dateString = document.data()["dateString"] as? String,
                      let date = DateHelper.parseDate(dateString),
                      let documentsYear = Calendar.current.dateComponents([.year], from: date).year,
                      documentsYear == year else {
                    continue
                }
                
                // Add this document to the batch delete
                batch?.deleteDocument(document.reference)
                deletedCount += 1
            }
            
            // Commit the batch if there are documents to delete
            if deletedCount > 0 {
                batch?.commit { error in
                    if let error = error {
                        Task { @MainActor in
                            AppLog.error("Error deleting year \(year): \(error)")
                        }
                        completion(error)
                    } else {
                        let deletedCount = deletedCount
                        Task { @MainActor in
                            AppLog.debug("Deleted \(deletedCount) sales documents for year \(year)")
                        }
                        completion(nil)
                    }
                }
            } else {
                // No documents to delete
                completion(nil)
            }
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertDictionaryToDailySales(data: [String: Any]) -> DailySales? {
        guard
            let dateString = data["dateString"] as? String,
            let lastEditedTimestamp = data["lastEditedOn"] as? TimeInterval
        else {
            return nil
        }
        
        // Parse lunch data
        var lunch: SaleCategory?
        if let lunchData = data["lunch"] as? [String: Any],
           let letturaCassa = lunchData["letturaCassa"] as? Double,
           let fatture = lunchData["fatture"] as? Double,
           let yami = lunchData["yami"] as? Double {
            
            let yamiPulito = lunchData["yamiPulito"] as? Double ?? 0
            let bento = lunchData["bento"] as? Double
            let persone = lunchData["persone"] as? Int
            
            lunch = SaleCategory(
                categoryType: .lunch,
                letturaCassa: letturaCassa,
                fatture: fatture,
                yami: yami,
                yamiPulito: yamiPulito,
                bento: bento,
                persone: persone
            )
        }
        
        // Parse dinner data
        var dinner: SaleCategory?
        if let dinnerData = data["dinner"] as? [String: Any],
           let letturaCassa = dinnerData["letturaCassa"] as? Double,
           let fatture = dinnerData["fatture"] as? Double,
           let yami = dinnerData["yami"] as? Double {
            
            let yamiPulito = dinnerData["yamiPulito"] as? Double ?? 0
            let cocai = dinnerData["cocai"] as? Double
            
            dinner = SaleCategory(
                categoryType: .dinner,
                letturaCassa: letturaCassa,
                fatture: fatture,
                yami: yami,
                yamiPulito: yamiPulito,
                cocai: cocai
            )
        }
        
        return DailySales(
            dateString: dateString,
            lunch: lunch,
            dinner: dinner,
            lastEditedOn: Date(timeIntervalSince1970: lastEditedTimestamp)
        )
    }
    
    private func convertDailySalesToDictionary(dailySales: DailySales) throws -> [String: Any] {
        var data: [String: Any] = [
            "dateString": dailySales.dateString,
            "lastEditedOn": dailySales.lastEditedOn.timeIntervalSince1970
        ]
        
        // Add lunch data
        let lunchData: [String: Any] = [
            "letturaCassa": dailySales.lunch.letturaCassa,
            "fatture": dailySales.lunch.fatture,
            "yami": dailySales.lunch.yami,
            "yamiPulito": dailySales.lunch.yamiPulito,
            "bento": dailySales.lunch.bento ?? 0,
            "persone": dailySales.lunch.persone ?? 0
        ]
        data["lunch"] = lunchData
        
        // Add dinner data
        let dinnerData: [String: Any] = [
            "letturaCassa": dailySales.dinner.letturaCassa,
            "fatture": dailySales.dinner.fatture,
            "yami": dailySales.dinner.yami,
            "yamiPulito": dailySales.dinner.yamiPulito,
            "cocai": dailySales.dinner.cocai ?? 0
        ]
        data["dinner"] = dinnerData
        
        return data
    }
}
