//
//  ExcelExportService.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 2/3/25.
//


import Foundation
import UIKit
import UniformTypeIdentifiers

// Service for exporting data to Excel (CSV) files
class ExcelExportService {
    
    // Export monthly sales data to CSV
    func exportMonthlySales(_ monthlyRecap: MonthlySalesRecap) -> URL? {
        let fileName = String(localized: "Vendite_\(monthlyRecap.monthName)_\(monthlyRecap.year).csv")
        
        // Create CSV string
        var csvString = String(localized: "Data,Categoria,Lettura Cassa,Fatture,Yami,Yami Pulito,Totale Shiro,Bento,Cocai,Persone,Spesa Media\n")
        
        // Add daily data
        for day in monthlyRecap.days.sorted(by: { $0.dateString < $1.dateString }) {
            if let date = day.normalizedDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                let formattedDate = dateFormatter.string(from: date)
                
                // Lunch data
                csvString += String(localized: "\(formattedDate),Pranzo,\(formatCsvValue(day.lunch.letturaCassa)),\(formatCsvValue(day.lunch.fatture)),\(formatCsvValue(day.lunch.yami)),\(formatCsvValue(day.lunch.yamiPulito)),\(formatCsvValue(day.lunch.totalShiro)),\(formatCsvValue(day.lunch.bento ?? 0)),,\(day.lunch.persone ?? 0),\(formatCsvValue(day.averageLunchSpend ?? 0))\n")
                
                // Dinner data
                csvString += String(localized: "\(formattedDate),Cena,\(formatCsvValue(day.dinner.letturaCassa)),\(formatCsvValue(day.dinner.fatture)),\(formatCsvValue(day.dinner.yami)),\(formatCsvValue(day.dinner.yamiPulito)),\(formatCsvValue(day.dinner.totalShiro)),,\(formatCsvValue(day.dinner.cocai ?? 0)),,\n")
            }
        }
        
        // Add monthly summary
        csvString += "\n\n" + String(localized: "Riepilogo mensile - \(monthlyRecap.monthName) \(monthlyRecap.year)\n")
        csvString += String(localized: "Categoria,Totale\n")
        csvString += String(localized: "Pranzo,\(formatCsvValue(monthlyRecap.totalLunchSales))\n")
        csvString += String(localized: "Cena,\(formatCsvValue(monthlyRecap.totalDinnerSales))\n")
        csvString += String(localized: "Totale Vendite,\(formatCsvValue(monthlyRecap.totalSales))\n\n")

        csvString += String(localized: "Lettura Cassa,\(formatCsvValue(monthlyRecap.totalLetturaCassa))\n")
        csvString += String(localized: "Fatture,\(formatCsvValue(monthlyRecap.totalFatture))\n")
        csvString += String(localized: "Yami Lordo,\(formatCsvValue(monthlyRecap.totalYami))\n")
        csvString += String(localized: "Yami Pulito,\(formatCsvValue(monthlyRecap.totalYamiPulito))\n")
        csvString += String(localized: "Yami Netto,\(formatCsvValue(monthlyRecap.netYami))\n\n")

        csvString += String(localized: "Bento,\(formatCsvValue(monthlyRecap.totalBento))\n")
        csvString += String(localized: "Cocai,\(formatCsvValue(monthlyRecap.totalCocai))\n\n")

        csvString += String(localized: "Persone totali,\(monthlyRecap.totalLunchCustomers)\n")
        if let avgSpend = monthlyRecap.averageLunchSpend {
            csvString += String(localized: "Spesa media a pranzo,\(formatCsvValue(avgSpend))\n")
        }
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
    
    // Export yearly sales data to CSV
    func exportYearlySales(_ yearlyRecap: YearlySalesRecap) -> URL? {
        let fileName = String(localized: "Vendite_Anno_\(yearlyRecap.year).csv")
        
        // Create CSV string
        var csvString = String(localized: "Mese,Pranzo,Cena,Totale Vendite,Lettura Cassa,Fatture,Yami Lordo,Yami Pulito,Yami Netto,Bento,Cocai,Persone,Spesa Media\n")
        
        let months = [
            String(localized: "Gennaio"),
            String(localized: "Febbraio"),
            String(localized: "Marzo"),
            String(localized: "Aprile"),
            String(localized: "Maggio"),
            String(localized: "Giugno"),
            String(localized: "Luglio"),
            String(localized: "Agosto"),
            String(localized: "Settembre"),
            String(localized: "Ottobre"),
            String(localized: "Novembre"),
            String(localized: "Dicembre")
        ]
        
        // Add monthly data
        for (index, month) in months.enumerated() {
            let monthRecap = yearlyRecap.monthlyRecaps[index]
            
            csvString += String(localized: "\(month),\(formatCsvValue(monthRecap.totalLunchSales)),\(formatCsvValue(monthRecap.totalDinnerSales)),\(formatCsvValue(monthRecap.totalSales)),\(formatCsvValue(monthRecap.totalLetturaCassa)),\(formatCsvValue(monthRecap.totalFatture)),\(formatCsvValue(monthRecap.totalYami)),\(formatCsvValue(monthRecap.totalYamiPulito)),\(formatCsvValue(monthRecap.netYami)),\(formatCsvValue(monthRecap.totalBento)),\(formatCsvValue(monthRecap.totalCocai)),\(monthRecap.totalLunchCustomers),\(formatCsvValue(monthRecap.averageLunchSpend ?? 0))\n")
        }
        
        // Add yearly summary
        csvString += "\n\n" + String(localized: "Riepilogo Annuale \(yearlyRecap.year)\n")
        csvString += String(localized: "Categoria,Totale\n")
        csvString += String(localized: "Pranzo,\(formatCsvValue(yearlyRecap.totalLunchSales))\n")
        csvString += String(localized: "Cena,\(formatCsvValue(yearlyRecap.totalDinnerSales))\n")
        csvString += String(localized: "Totale Vendite,\(formatCsvValue(yearlyRecap.totalSales))\n\n")

        csvString += String(localized: "Lettura Cassa,\(formatCsvValue(yearlyRecap.totalLetturaCassa))\n")
        csvString += String(localized: "Fatture,\(formatCsvValue(yearlyRecap.totalFatture))\n")
        csvString += String(localized: "Yami Lordo,\(formatCsvValue(yearlyRecap.totalYami))\n")
        csvString += String(localized: "Yami Pulito,\(formatCsvValue(yearlyRecap.totalYamiPulito))\n")
        csvString += String(localized: "Yami Netto,\(formatCsvValue(yearlyRecap.netYami))\n\n")

        csvString += String(localized: "Bento,\(formatCsvValue(yearlyRecap.totalBento))\n")
        csvString += String(localized: "Cocai,\(formatCsvValue(yearlyRecap.totalCocai))\n\n")

        csvString += String(localized: "Persone totali,\(yearlyRecap.totalLunchCustomers)\n")
        if let avgSpend = yearlyRecap.averageLunchSpend {
            csvString += String(localized: "Spesa media a pranzo,\(formatCsvValue(avgSpend))\n")
        }
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
    
    // Helper method to format CSV values with Italian number format
    private func formatCsvValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
}

// UIActivityViewController helper for sharing files
extension UIViewController {
    func presentShareSheet(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(activityViewController, animated: true)
    }
}
