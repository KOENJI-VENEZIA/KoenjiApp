Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Services/ExcelExportService.swift...
# Documentation Suggestions for ExcelExportService.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Services/ExcelExportService.swift
Total suggestions: 24

## Class Documentation (2)

### ExcelExportService (Line 14)

**Context:**

```swift
import UniformTypeIdentifiers

// Service for exporting data to Excel (CSV) files
class ExcelExportService {
    
    // Export monthly sales data to CSV
    func exportMonthlySales(_ monthlyRecap: MonthlySalesRecap) -> URL? {
```

**Suggested Documentation:**

```swift
/// ExcelExportService service.
///
/// [Add a description of what this service does and its responsibilities]
```

### UIViewController (Line 147)

**Context:**

```swift
}

// UIActivityViewController helper for sharing files
extension UIViewController {
    func presentShareSheet(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
```

**Suggested Documentation:**

```swift
/// UIViewController controller.
///
/// [Add a description of what this controller does and its responsibilities]
```

## Method Documentation (4)

### exportMonthlySales (Line 17)

**Context:**

```swift
class ExcelExportService {
    
    // Export monthly sales data to CSV
    func exportMonthlySales(_ monthlyRecap: MonthlySalesRecap) -> URL? {
        let fileName = String(localized: "Vendite_\(monthlyRecap.monthName)_\(monthlyRecap.year).csv")
        
        // Create CSV string
```

**Suggested Documentation:**

```swift
/// [Add a description of what the exportMonthlySales method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### exportYearlySales (Line 73)

**Context:**

```swift
    }
    
    // Export yearly sales data to CSV
    func exportYearlySales(_ yearlyRecap: YearlySalesRecap) -> URL? {
        let fileName = String(localized: "Vendite_Anno_\(yearlyRecap.year).csv")
        
        // Create CSV string
```

**Suggested Documentation:**

```swift
/// [Add a description of what the exportYearlySales method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### formatCsvValue (Line 136)

**Context:**

```swift
    }
    
    // Helper method to format CSV values with Italian number format
    private func formatCsvValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = ","
```

**Suggested Documentation:**

```swift
/// [Add a description of what the formatCsvValue method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### presentShareSheet (Line 148)

**Context:**

```swift

// UIActivityViewController helper for sharing files
extension UIViewController {
    func presentShareSheet(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
```

**Suggested Documentation:**

```swift
/// [Add a description of what the presentShareSheet method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (18)

### fileName (Line 18)

**Context:**

```swift
    
    // Export monthly sales data to CSV
    func exportMonthlySales(_ monthlyRecap: MonthlySalesRecap) -> URL? {
        let fileName = String(localized: "Vendite_\(monthlyRecap.monthName)_\(monthlyRecap.year).csv")
        
        // Create CSV string
        var csvString = String(localized: "Data,Categoria,Lettura Cassa,Fatture,Yami,Yami Pulito,Totale Shiro,Bento,Cocai,Persone,Spesa Media\n")
```

**Suggested Documentation:**

```swift
/// [Description of the fileName property]
```

### csvString (Line 21)

**Context:**

```swift
        let fileName = String(localized: "Vendite_\(monthlyRecap.monthName)_\(monthlyRecap.year).csv")
        
        // Create CSV string
        var csvString = String(localized: "Data,Categoria,Lettura Cassa,Fatture,Yami,Yami Pulito,Totale Shiro,Bento,Cocai,Persone,Spesa Media\n")
        
        // Add daily data
        for day in monthlyRecap.days.sorted(by: { $0.dateString < $1.dateString }) {
```

**Suggested Documentation:**

```swift
/// [Description of the csvString property]
```

### date (Line 25)

**Context:**

```swift
        
        // Add daily data
        for day in monthlyRecap.days.sorted(by: { $0.dateString < $1.dateString }) {
            if let date = day.normalizedDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                let formattedDate = dateFormatter.string(from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### dateFormatter (Line 26)

**Context:**

```swift
        // Add daily data
        for day in monthlyRecap.days.sorted(by: { $0.dateString < $1.dateString }) {
            if let date = day.normalizedDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                let formattedDate = dateFormatter.string(from: date)
                
```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### formattedDate (Line 28)

**Context:**

```swift
            if let date = day.normalizedDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                let formattedDate = dateFormatter.string(from: date)
                
                // Lunch data
                csvString += String(localized: "\(formattedDate),Pranzo,\(formatCsvValue(day.lunch.letturaCassa)),\(formatCsvValue(day.lunch.fatture)),\(formatCsvValue(day.lunch.yami)),\(formatCsvValue(day.lunch.yamiPulito)),\(formatCsvValue(day.lunch.totalShiro)),\(formatCsvValue(day.lunch.bento ?? 0)),,\(day.lunch.persone ?? 0),\(formatCsvValue(day.averageLunchSpend ?? 0))\n")
```

**Suggested Documentation:**

```swift
/// [Description of the formattedDate property]
```

### avgSpend (Line 55)

**Context:**

```swift
        csvString += String(localized: "Cocai,\(formatCsvValue(monthlyRecap.totalCocai))\n\n")

        csvString += String(localized: "Persone totali,\(monthlyRecap.totalLunchCustomers)\n")
        if let avgSpend = monthlyRecap.averageLunchSpend {
            csvString += String(localized: "Spesa media a pranzo,\(formatCsvValue(avgSpend))\n")
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the avgSpend property]
```

### tempDirectory (Line 60)

**Context:**

```swift
        }
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
```

**Suggested Documentation:**

```swift
/// [Description of the tempDirectory property]
```

### fileURL (Line 61)

**Context:**

```swift
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
```

**Suggested Documentation:**

```swift
/// [Description of the fileURL property]
```

### fileName (Line 74)

**Context:**

```swift
    
    // Export yearly sales data to CSV
    func exportYearlySales(_ yearlyRecap: YearlySalesRecap) -> URL? {
        let fileName = String(localized: "Vendite_Anno_\(yearlyRecap.year).csv")
        
        // Create CSV string
        var csvString = String(localized: "Mese,Pranzo,Cena,Totale Vendite,Lettura Cassa,Fatture,Yami Lordo,Yami Pulito,Yami Netto,Bento,Cocai,Persone,Spesa Media\n")
```

**Suggested Documentation:**

```swift
/// [Description of the fileName property]
```

### csvString (Line 77)

**Context:**

```swift
        let fileName = String(localized: "Vendite_Anno_\(yearlyRecap.year).csv")
        
        // Create CSV string
        var csvString = String(localized: "Mese,Pranzo,Cena,Totale Vendite,Lettura Cassa,Fatture,Yami Lordo,Yami Pulito,Yami Netto,Bento,Cocai,Persone,Spesa Media\n")
        
        let months = [
            String(localized: "Gennaio"),
```

**Suggested Documentation:**

```swift
/// [Description of the csvString property]
```

### months (Line 79)

**Context:**

```swift
        // Create CSV string
        var csvString = String(localized: "Mese,Pranzo,Cena,Totale Vendite,Lettura Cassa,Fatture,Yami Lordo,Yami Pulito,Yami Netto,Bento,Cocai,Persone,Spesa Media\n")
        
        let months = [
            String(localized: "Gennaio"),
            String(localized: "Febbraio"),
            String(localized: "Marzo"),
```

**Suggested Documentation:**

```swift
/// [Description of the months property]
```

### monthRecap (Line 96)

**Context:**

```swift
        
        // Add monthly data
        for (index, month) in months.enumerated() {
            let monthRecap = yearlyRecap.monthlyRecaps[index]
            
            csvString += String(localized: "\(month),\(formatCsvValue(monthRecap.totalLunchSales)),\(formatCsvValue(monthRecap.totalDinnerSales)),\(formatCsvValue(monthRecap.totalSales)),\(formatCsvValue(monthRecap.totalLetturaCassa)),\(formatCsvValue(monthRecap.totalFatture)),\(formatCsvValue(monthRecap.totalYami)),\(formatCsvValue(monthRecap.totalYamiPulito)),\(formatCsvValue(monthRecap.netYami)),\(formatCsvValue(monthRecap.totalBento)),\(formatCsvValue(monthRecap.totalCocai)),\(monthRecap.totalLunchCustomers),\(formatCsvValue(monthRecap.averageLunchSpend ?? 0))\n")
        }
```

**Suggested Documentation:**

```swift
/// [Description of the monthRecap property]
```

### avgSpend (Line 118)

**Context:**

```swift
        csvString += String(localized: "Cocai,\(formatCsvValue(yearlyRecap.totalCocai))\n\n")

        csvString += String(localized: "Persone totali,\(yearlyRecap.totalLunchCustomers)\n")
        if let avgSpend = yearlyRecap.averageLunchSpend {
            csvString += String(localized: "Spesa media a pranzo,\(formatCsvValue(avgSpend))\n")
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the avgSpend property]
```

### tempDirectory (Line 123)

**Context:**

```swift
        }
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
```

**Suggested Documentation:**

```swift
/// [Description of the tempDirectory property]
```

### fileURL (Line 124)

**Context:**

```swift
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
```

**Suggested Documentation:**

```swift
/// [Description of the fileURL property]
```

### formatter (Line 137)

**Context:**

```swift
    
    // Helper method to format CSV values with Italian number format
    private func formatCsvValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 2
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### activityViewController (Line 149)

**Context:**

```swift
// UIActivityViewController helper for sharing files
extension UIViewController {
    func presentShareSheet(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
```

**Suggested Documentation:**

```swift
/// [Description of the activityViewController property]
```

### popoverController (Line 154)

**Context:**

```swift
            applicationActivities: nil
        )
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
```

**Suggested Documentation:**

```swift
/// [Description of the popoverController property]
```


Total documentation suggestions: 24

