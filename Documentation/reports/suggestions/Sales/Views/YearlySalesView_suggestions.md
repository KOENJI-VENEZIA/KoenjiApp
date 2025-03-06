Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Views/YearlySalesView.swift...
# Documentation Suggestions for YearlySalesView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Views/YearlySalesView.swift
Total suggestions: 30

## Class Documentation (1)

### YearlySalesView (Line 3)

**Context:**

```swift
import SwiftUI

struct YearlySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
```

**Suggested Documentation:**

```swift
/// YearlySalesView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (6)

### monthRow (Line 232)

**Context:**

```swift
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func monthRow(month: String, recap: MonthlySalesRecap) -> some View {
        HStack {
            Text(month)
                .font(.subheadline)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the monthRow method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### annualSummarySection (Line 277)

**Context:**

```swift
        .contentShape(Rectangle())
    }
    
    private func annualSummarySection(recap: YearlySalesRecap) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Riepilogo Annuale")
                .font(.headline)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the annualSummarySection method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### summaryRow (Line 330)

**Context:**

```swift
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func summaryRow(title: String, value: Double, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isBold ? .headline : .subheadline)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the summaryRow method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### customerInsightRow (Line 345)

**Context:**

```swift
        }
    }
    
    private func customerInsightRow(count: Int, avgSpend: Double?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the customerInsightRow method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateYearlyRecap (Line 377)

**Context:**

```swift
        .cornerRadius(6)
    }
    
    private func updateYearlyRecap() {
        guard let salesStore = env.salesStore else { return }
        DispatchQueue.main.async {
            self.yearlyRecap = salesStore.getYearlyRecap(year: self.year)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateYearlyRecap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### exportToExcel (Line 385)

**Context:**

```swift
    }
    
    // Export to Excel function
    private func exportToExcel() {
        guard let recap = yearlyRecap, let fileURL = exportService.exportYearlySales(recap) else {
            return
        }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the exportToExcel method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (23)

### env (Line 4)

**Context:**

```swift
import SwiftUI

struct YearlySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### dismiss (Line 5)

**Context:**

```swift

struct YearlySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    let year: Int
```

**Suggested Documentation:**

```swift
/// [Description of the dismiss property]
```

### presentationMode (Line 6)

**Context:**

```swift
struct YearlySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    let year: Int
    
```

**Suggested Documentation:**

```swift
/// [Description of the presentationMode property]
```

### year (Line 8)

**Context:**

```swift
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    let year: Int
    
    @State private var yearlyRecap: YearlySalesRecap?
    @State private var showExportOptions = false
```

**Suggested Documentation:**

```swift
/// [Description of the year property]
```

### yearlyRecap (Line 10)

**Context:**

```swift
    
    let year: Int
    
    @State private var yearlyRecap: YearlySalesRecap?
    @State private var showExportOptions = false
    @State private var showAuthView = false
    
```

**Suggested Documentation:**

```swift
/// [Description of the yearlyRecap property]
```

### showExportOptions (Line 11)

**Context:**

```swift
    let year: Int
    
    @State private var yearlyRecap: YearlySalesRecap?
    @State private var showExportOptions = false
    @State private var showAuthView = false
    
    // Export service
```

**Suggested Documentation:**

```swift
/// [Description of the showExportOptions property]
```

### showAuthView (Line 12)

**Context:**

```swift
    
    @State private var yearlyRecap: YearlySalesRecap?
    @State private var showExportOptions = false
    @State private var showAuthView = false
    
    // Export service
    private let exportService = ExcelExportService()
```

**Suggested Documentation:**

```swift
/// [Description of the showAuthView property]
```

### exportService (Line 15)

**Context:**

```swift
    @State private var showAuthView = false
    
    // Export service
    private let exportService = ExcelExportService()
    
    private let months = [
        String(localized: "Gennaio"),
```

**Suggested Documentation:**

```swift
/// [Description of the exportService property]
```

### months (Line 17)

**Context:**

```swift
    // Export service
    private let exportService = ExcelExportService()
    
    private let months = [
        String(localized: "Gennaio"),
        String(localized: "Febbraio"),
        String(localized: "Marzo"),
```

**Suggested Documentation:**

```swift
/// [Description of the months property]
```

### body (Line 32)

**Context:**

```swift
        String(localized: "Dicembre")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Year header
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### recap (Line 42)

**Context:**

```swift
                monthlyBreakdownSection
                
                // Annual summary
                if let recap = yearlyRecap {
                    // Only show summary if authorized
                    if env.salesStore?.isAuthorized == true {
                        annualSummarySection(recap: recap)
```

**Suggested Documentation:**

```swift
/// [Description of the recap property]
```

### headerSection (Line 114)

**Context:**

```swift
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Riepilogo \(String(year))")
                .font(.title)
```

**Suggested Documentation:**

```swift
/// [Description of the headerSection property]
```

### recap (Line 120)

**Context:**

```swift
                .font(.title)
                .fontWeight(.bold)
            
            if let recap = yearlyRecap, env.salesStore?.isAuthorized == true {
                Text("Totale annuale netto: \(recap.totalSales, format: .currency(code: "EUR"))")
                    .font(.title3)
                    .foregroundColor(.green)
```

**Suggested Documentation:**

```swift
/// [Description of the recap property]
```

### authRequiredSection (Line 135)

**Context:**

```swift
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var authRequiredSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
```

**Suggested Documentation:**

```swift
/// [Description of the authRequiredSection property]
```

### monthlyBreakdownSection (Line 172)

**Context:**

```swift
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var monthlyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vendite Mensili")
                .font(.headline)
```

**Suggested Documentation:**

```swift
/// [Description of the monthlyBreakdownSection property]
```

### recap (Line 209)

**Context:**

```swift
                Divider()
                
                // Month rows
                if let recap = yearlyRecap {
                    ForEach(0..<12) { index in
                        let monthRecap = recap.monthlyRecaps[index]
                        NavigationLink(destination: MonthlySalesView(year: year, month: index + 1)) {
```

**Suggested Documentation:**

```swift
/// [Description of the recap property]
```

### monthRecap (Line 211)

**Context:**

```swift
                // Month rows
                if let recap = yearlyRecap {
                    ForEach(0..<12) { index in
                        let monthRecap = recap.monthlyRecaps[index]
                        NavigationLink(destination: MonthlySalesView(year: year, month: index + 1)) {
                            monthRow(month: months[index], recap: monthRecap)
                        }
```

**Suggested Documentation:**

```swift
/// [Description of the monthRecap property]
```

### avgMonthlySales (Line 316)

**Context:**

```swift
                summaryRow(title: String(localized: "Totale Annuale"), value: recap.totalSales, color: .green, isBold: true)
                
                // Average monthly sales
                let avgMonthlySales = recap.totalSales / 12
                Text("Media mensile: \(avgMonthlySales, format: .currency(code: "EUR"))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
```

**Suggested Documentation:**

```swift
/// [Description of the avgMonthlySales property]
```

### avgSpend (Line 357)

**Context:**

```swift
                        .font(.caption)
                }
                
                if let avgSpend = avgSpend {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.teal)
```

**Suggested Documentation:**

```swift
/// [Description of the avgSpend property]
```

### salesStore (Line 378)

**Context:**

```swift
    }
    
    private func updateYearlyRecap() {
        guard let salesStore = env.salesStore else { return }
        DispatchQueue.main.async {
            self.yearlyRecap = salesStore.getYearlyRecap(year: self.year)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the salesStore property]
```

### recap (Line 386)

**Context:**

```swift
    
    // Export to Excel function
    private func exportToExcel() {
        guard let recap = yearlyRecap, let fileURL = exportService.exportYearlySales(recap) else {
            return
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the recap property]
```

### fileURL (Line 386)

**Context:**

```swift
    
    // Export to Excel function
    private func exportToExcel() {
        guard let recap = yearlyRecap, let fileURL = exportService.exportYearlySales(recap) else {
            return
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the fileURL property]
```

### rootVC (Line 391)

**Context:**

```swift
        }
        
        // Access UIViewController to present share sheet
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the rootVC property]
```


Total documentation suggestions: 30

