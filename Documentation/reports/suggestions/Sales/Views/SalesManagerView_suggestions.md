Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Views/SalesManagerView.swift...
# Documentation Suggestions for SalesManagerView.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Views/SalesManagerView.swift
Total suggestions: 71

## Class Documentation (3)

### SalesManagerView (Line 3)

**Context:**

```swift
import SwiftUI

struct SalesManagerView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.colorScheme) private var colorScheme
    
```

**Suggested Documentation:**

```swift
/// SalesManagerView view.
///
/// [Add a description of what this view does and its responsibilities]
```

### DeletionItem (Line 18)

**Context:**

```swift
    @State private var itemToDelete: DeletionItem? // Track what's being deleted
    
    // Enum to track what type of item is being deleted
    enum DeletionItem {
        case year(Int)
        case month(Int, Int) // year, month
    }
```

**Suggested Documentation:**

```swift
/// DeletionItem class.
///
/// [Add a description of what this class does and its responsibilities]
```

### YearSelectionView (Line 739)

**Context:**

```swift
}

// New view for year selection
struct YearSelectionView: View {
    @EnvironmentObject var env: AppDependencies
    var availableYears: [Int]
    @Binding var selectedYear: Int
```

**Suggested Documentation:**

```swift
/// YearSelectionView view.
///
/// [Add a description of what this view does and its responsibilities]
```

## Method Documentation (14)

### quickActionButton (Line 562)

**Context:**

```swift
        return formatter.string(from: Date()).capitalized
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: (() -> Void)? = nil) -> some View {
        Button(action: action ?? {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the quickActionButton method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### categoryValue (Line 582)

**Context:**

```swift
        .buttonStyle(PlainButtonStyle()) // Add this to prevent button styling conflicts with NavigationLink
    }
    
    private func categoryValue(title: String, value: Double, color: Color, isBold: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            if !isBold {
                Text(title)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the categoryValue method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getLunchTotal (Line 606)

**Context:**

```swift
        }
    }
    
    private func getLunchTotal(_ sale: DailySales) -> Double {
        return sale.lunch.totalShiro + sale.lunch.yami
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getLunchTotal method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getDinnerTotal (Line 610)

**Context:**

```swift
        return sale.lunch.totalShiro + sale.lunch.yami
    }
    
    private func getDinnerTotal(_ sale: DailySales) -> Double {
        return sale.dinner.totalShiro + sale.dinner.yami
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getDinnerTotal method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getMonthlySalesTotal (Line 614)

**Context:**

```swift
        return sale.dinner.totalShiro + sale.dinner.yami
    }
    
    private func getMonthlySalesTotal(month: Int) -> Double? {
        guard let salesStore = env.salesStore else { return nil }
        
        let monthlyRecap = salesStore.getMonthlyRecap(year: selectedYear, month: month)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getMonthlySalesTotal method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getRecentSales (Line 621)

**Context:**

```swift
        return monthlyRecap.totalSales > 0 ? monthlyRecap.totalSales : nil
    }
    
    private func getRecentSales() -> [DailySales]? {
        guard let salesStore = env.salesStore, !salesStore.allSales.isEmpty else { return nil }
        
        let sortedSales = salesStore.allSales.sorted {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getRecentSales method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### monthName (Line 631)

**Context:**

```swift
        return Array(sortedSales.prefix(5))
    }
    
    private func monthName(for monthNumber: Int) -> String {
        let monthNames = [
            String(localized: "Gennaio"), String(localized: "Febbraio"), String(localized: "Marzo"),
            String(localized: "Aprile"), String(localized: "Maggio"), String(localized: "Giugno"),
```

**Suggested Documentation:**

```swift
/// [Add a description of what the monthName method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteYear (Line 642)

**Context:**

```swift
        }
    
    // Helper methods for deletion and month name
    private func deleteYear(_ year: Int) {
        guard env.salesStore?.isAuthorized == true else { return }
        
        // Implement year deletion logic in your sales store
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteYear method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteMonth (Line 656)

**Context:**

```swift
        updateAvailableYears()
    }
    
    private func deleteMonth(year: Int, month: Int) {
        guard env.salesStore?.isAuthorized == true else { return }
        
        // Implement month deletion logic in your sales store
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteMonth method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateAvailableYears (Line 670)

**Context:**

```swift
        updateAvailableYears()
    }
    
    private func updateAvailableYears() {
        guard let salesStore = env.salesStore else { return }
        
        let years = salesStore.getAvailableYears()
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateAvailableYears method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### addNewYear (Line 690)

**Context:**

```swift
        }
    }
    
    private func addNewYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let nextYear = currentYear + 1
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the addNewYear method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### prepareDailyView (Line 703)

**Context:**

```swift
        }
    }
    
    private func prepareDailyView(for date: Date) {
        // Reset the sheet content ready flag
        sheetContentReady = false
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the prepareDailyView method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### navigateToCurrentMonth (Line 722)

**Context:**

```swift
    }

    
    private func navigateToCurrentMonth() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
```

**Suggested Documentation:**

```swift
/// [Add a description of what the navigateToCurrentMonth method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### navigateToCurrentYear (Line 732)

**Context:**

```swift
        self.selectedYear = currentYear
    }
    
    private func navigateToCurrentYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.selectedYear = currentYear
    }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the navigateToCurrentYear method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (54)

### env (Line 4)

**Context:**

```swift
import SwiftUI

struct SalesManagerView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### colorScheme (Line 5)

**Context:**

```swift

struct SalesManagerView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
```

**Suggested Documentation:**

```swift
/// [Description of the colorScheme property]
```

### selectedYear (Line 7)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedYear property]
```

### availableYears (Line 8)

**Context:**

```swift
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var showAuthView = false
```

**Suggested Documentation:**

```swift
/// [Description of the availableYears property]
```

### selectedDate (Line 9)

**Context:**

```swift
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var showAuthView = false
    @State private var sheetContentReady = false
```

**Suggested Documentation:**

```swift
/// [Description of the selectedDate property]
```

### showingDailyView (Line 10)

**Context:**

```swift
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var showAuthView = false
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
```

**Suggested Documentation:**

```swift
/// [Description of the showingDailyView property]
```

### showAuthView (Line 11)

**Context:**

```swift
    @State private var availableYears: [Int] = []
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var showAuthView = false
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
    @State private var showConfirmationDialog = false // For delete confirmations
```

**Suggested Documentation:**

```swift
/// [Description of the showAuthView property]
```

### sheetContentReady (Line 12)

**Context:**

```swift
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var showAuthView = false
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
    @State private var showConfirmationDialog = false // For delete confirmations
    @State private var itemToDelete: DeletionItem? // Track what's being deleted
```

**Suggested Documentation:**

```swift
/// [Description of the sheetContentReady property]
```

### showYearSelector (Line 13)

**Context:**

```swift
    @State private var showingDailyView = false
    @State private var showAuthView = false
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
    @State private var showConfirmationDialog = false // For delete confirmations
    @State private var itemToDelete: DeletionItem? // Track what's being deleted
    
```

**Suggested Documentation:**

```swift
/// [Description of the showYearSelector property]
```

### showConfirmationDialog (Line 14)

**Context:**

```swift
    @State private var showAuthView = false
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
    @State private var showConfirmationDialog = false // For delete confirmations
    @State private var itemToDelete: DeletionItem? // Track what's being deleted
    
    // Enum to track what type of item is being deleted
```

**Suggested Documentation:**

```swift
/// [Description of the showConfirmationDialog property]
```

### itemToDelete (Line 15)

**Context:**

```swift
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
    @State private var showConfirmationDialog = false // For delete confirmations
    @State private var itemToDelete: DeletionItem? // Track what's being deleted
    
    // Enum to track what type of item is being deleted
    enum DeletionItem {
```

**Suggested Documentation:**

```swift
/// [Description of the itemToDelete property]
```

### body (Line 23)

**Context:**

```swift
        case month(Int, Int) // year, month
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                ScrollView {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```

### itemToDelete (Line 95)

**Context:**

```swift
            }
        }
        .confirmationDialog("Conferma Eliminazione", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
                    if let itemToDelete = itemToDelete {
                        switch itemToDelete {
                        case .year(let year):
                            Button("Elimina Anno \(String(year))", role: .destructive) {
```

**Suggested Documentation:**

```swift
/// [Description of the itemToDelete property]
```

### year (Line 97)

**Context:**

```swift
        .confirmationDialog("Conferma Eliminazione", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
                    if let itemToDelete = itemToDelete {
                        switch itemToDelete {
                        case .year(let year):
                            Button("Elimina Anno \(String(year))", role: .destructive) {
                                deleteYear(year)
                            }
```

**Suggested Documentation:**

```swift
/// [Description of the year property]
```

### year (Line 101)

**Context:**

```swift
                            Button("Elimina Anno \(String(year))", role: .destructive) {
                                deleteYear(year)
                            }
                        case .month(let year, let month):
                            Button("Elimina Mese \(monthName(for: month)) \(String(year))", role: .destructive) {
                                deleteMonth(year: year, month: month)
                            }
```

**Suggested Documentation:**

```swift
/// [Description of the year property]
```

### month (Line 101)

**Context:**

```swift
                            Button("Elimina Anno \(String(year))", role: .destructive) {
                                deleteYear(year)
                            }
                        case .month(let year, let month):
                            Button("Elimina Mese \(monthName(for: month)) \(String(year))", role: .destructive) {
                                deleteMonth(year: year, month: month)
                            }
```

**Suggested Documentation:**

```swift
/// [Description of the month property]
```

### selectedDate (Line 122)

**Context:**

```swift
            // Reset the flag when dismissed
            sheetContentReady = false
        }) {
            if let selectedDate = selectedDate {
                NavigationStack {
                    ZStack {
                        // Always show a loading state first
```

**Suggested Documentation:**

```swift
/// [Description of the selectedDate property]
```

### headerView (Line 165)

**Context:**

```swift
    }
    
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title and current date
            HStack {
```

**Suggested Documentation:**

```swift
/// [Description of the headerView property]
```

### isAuthorized (Line 182)

**Context:**

```swift
                Spacer()
                
                // Authorization status indicator
                if let isAuthorized = env.salesStore?.isAuthorized, isAuthorized {
                    Label("Autorizzato", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.green)
```

**Suggested Documentation:**

```swift
/// [Description of the isAuthorized property]
```

### currentYear (Line 229)

**Context:**

```swift
                    prepareDailyView(for: Date())
                }
                
                let currentYear = Calendar.current.component(.year, from: Date())

                let currentMonth = Calendar.current.component(.month, from: Date())

```

**Suggested Documentation:**

```swift
/// [Description of the currentYear property]
```

### currentMonth (Line 231)

**Context:**

```swift
                
                let currentYear = Calendar.current.component(.year, from: Date())

                let currentMonth = Calendar.current.component(.month, from: Date())

            
                NavigationLink(destination: MonthlySalesView(year: currentYear, month: currentMonth)) {
```

**Suggested Documentation:**

```swift
/// [Description of the currentMonth property]
```

### yearSelectorView (Line 277)

**Context:**

```swift
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var yearSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seleziona Anno")
                .font(.headline)
```

**Suggested Documentation:**

```swift
/// [Description of the yearSelectorView property]
```

### monthlyNavigationView (Line 371)

**Context:**

```swift
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var monthlyNavigationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mesi \(String(selectedYear))")
```

**Suggested Documentation:**

```swift
/// [Description of the monthlyNavigationView property]
```

### columns (Line 388)

**Context:**

```swift
                }
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<12) { index in
```

**Suggested Documentation:**

```swift
/// [Description of the columns property]
```

### monthNames (Line 392)

**Context:**

```swift
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<12) { index in
                    let monthNames = [
                        String(localized: "Gennaio"), String(localized: "Febbraio"), String(localized: "Marzo"), String(localized: "Aprile"), String(localized: "Maggio"), String(localized: "Giugno"),
                        String(localized: "Luglio"), String(localized: "Agosto"), String(localized: "Settembre"), String(localized: "Ottobre"), String(localized: "Novembre"), String(localized: "Dicembre")
                    ]
```

**Suggested Documentation:**

```swift
/// [Description of the monthNames property]
```

### monthlySales (Line 405)

**Context:**

```swift
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            if let monthlySales = getMonthlySalesTotal(month: index + 1), env.salesStore?.isAuthorized == true {
                                Text("\(Int(monthlySales))€")
                                    .font(.caption)
                                    .foregroundColor(.green)
```

**Suggested Documentation:**

```swift
/// [Description of the monthlySales property]
```

### recentEntriesView (Line 465)

**Context:**

```swift
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var recentEntriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inserimenti Recenti")
                .font(.headline)
```

**Suggested Documentation:**

```swift
/// [Description of the recentEntriesView property]
```

### recentSales (Line 470)

**Context:**

```swift
            Text("Inserimenti Recenti")
                .font(.headline)
            
            if let recentSales = getRecentSales(), !recentSales.isEmpty {
                ForEach(recentSales) { sale in
                    Button {
                        selectedDate = sale.normalizedDate
```

**Suggested Documentation:**

```swift
/// [Description of the recentSales property]
```

### index (Line 515)

**Context:**

```swift
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let index = recentSales.firstIndex(of: sale), index < recentSales.count - 1 {
                        Divider()
                            .padding(.leading, 8)
                    }
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### formattedCurrentDate (Line 555)

**Context:**

```swift
    
    // MARK: - Helper Methods
    
    private var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: String(localized: "it_IT"))
```

**Suggested Documentation:**

```swift
/// [Description of the formattedCurrentDate property]
```

### formatter (Line 556)

**Context:**

```swift
    // MARK: - Helper Methods
    
    private var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: String(localized: "it_IT"))
        return formatter.string(from: Date()).capitalized
```

**Suggested Documentation:**

```swift
/// [Description of the formatter property]
```

### salesStore (Line 615)

**Context:**

```swift
    }
    
    private func getMonthlySalesTotal(month: Int) -> Double? {
        guard let salesStore = env.salesStore else { return nil }
        
        let monthlyRecap = salesStore.getMonthlyRecap(year: selectedYear, month: month)
        return monthlyRecap.totalSales > 0 ? monthlyRecap.totalSales : nil
```

**Suggested Documentation:**

```swift
/// [Description of the salesStore property]
```

### monthlyRecap (Line 617)

**Context:**

```swift
    private func getMonthlySalesTotal(month: Int) -> Double? {
        guard let salesStore = env.salesStore else { return nil }
        
        let monthlyRecap = salesStore.getMonthlyRecap(year: selectedYear, month: month)
        return monthlyRecap.totalSales > 0 ? monthlyRecap.totalSales : nil
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the monthlyRecap property]
```

### salesStore (Line 622)

**Context:**

```swift
    }
    
    private func getRecentSales() -> [DailySales]? {
        guard let salesStore = env.salesStore, !salesStore.allSales.isEmpty else { return nil }
        
        let sortedSales = salesStore.allSales.sorted {
            $0.lastEditedOn > $1.lastEditedOn
```

**Suggested Documentation:**

```swift
/// [Description of the salesStore property]
```

### sortedSales (Line 624)

**Context:**

```swift
    private func getRecentSales() -> [DailySales]? {
        guard let salesStore = env.salesStore, !salesStore.allSales.isEmpty else { return nil }
        
        let sortedSales = salesStore.allSales.sorted {
            $0.lastEditedOn > $1.lastEditedOn
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the sortedSales property]
```

### monthNames (Line 632)

**Context:**

```swift
    }
    
    private func monthName(for monthNumber: Int) -> String {
        let monthNames = [
            String(localized: "Gennaio"), String(localized: "Febbraio"), String(localized: "Marzo"),
            String(localized: "Aprile"), String(localized: "Maggio"), String(localized: "Giugno"),
            String(localized: "Luglio"), String(localized: "Agosto"), String(localized: "Settembre"),
```

**Suggested Documentation:**

```swift
/// [Description of the monthNames property]
```

### error (Line 648)

**Context:**

```swift
        // Implement year deletion logic in your sales store
        env.salesStore?.deleteYear(year)
        env.salesService?.deleteYear(year) { error in
            if let error = error {
               print("Error deleting year in Firebase: \(error)")
           }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### error (Line 662)

**Context:**

```swift
        // Implement month deletion logic in your sales store
        env.salesStore?.deleteMonth(year: year, month: month)
        env.salesService?.deleteMonth(year: year, month: month) { error in
            if let error = error {
                print("Error deleting month in Firebase: \(error)")
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the error property]
```

### salesStore (Line 671)

**Context:**

```swift
    }
    
    private func updateAvailableYears() {
        guard let salesStore = env.salesStore else { return }
        
        let years = salesStore.getAvailableYears()
        
```

**Suggested Documentation:**

```swift
/// [Description of the salesStore property]
```

### years (Line 673)

**Context:**

```swift
    private func updateAvailableYears() {
        guard let salesStore = env.salesStore else { return }
        
        let years = salesStore.getAvailableYears()
        
        if !years.isEmpty {
            self.availableYears = years
```

**Suggested Documentation:**

```swift
/// [Description of the years property]
```

### currentYear (Line 684)

**Context:**

```swift
            }
        } else {
            // Default to current year if no data
            let currentYear = Calendar.current.component(.year, from: Date())
            self.availableYears = [currentYear]
            self.selectedYear = currentYear
        }
```

**Suggested Documentation:**

```swift
/// [Description of the currentYear property]
```

### currentYear (Line 691)

**Context:**

```swift
    }
    
    private func addNewYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let nextYear = currentYear + 1
        
        if !availableYears.contains(nextYear) {
```

**Suggested Documentation:**

```swift
/// [Description of the currentYear property]
```

### nextYear (Line 692)

**Context:**

```swift
    
    private func addNewYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let nextYear = currentYear + 1
        
        if !availableYears.contains(nextYear) {
            self.selectedYear = nextYear
```

**Suggested Documentation:**

```swift
/// [Description of the nextYear property]
```

### store (Line 711)

**Context:**

```swift
        selectedDate = date
        
        // Pre-fetch the data with adequate time for it to load
        if let store = env.salesStore {
            _ = store.getSalesForDay(date: date)
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### currentDate (Line 723)

**Context:**

```swift

    
    private func navigateToCurrentMonth() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
```

**Suggested Documentation:**

```swift
/// [Description of the currentDate property]
```

### calendar (Line 724)

**Context:**

```swift
    
    private func navigateToCurrentMonth() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### currentYear (Line 725)

**Context:**

```swift
    private func navigateToCurrentMonth() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Update selected year if needed
```

**Suggested Documentation:**

```swift
/// [Description of the currentYear property]
```

### currentMonth (Line 726)

**Context:**

```swift
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Update selected year if needed
        self.selectedYear = currentYear
```

**Suggested Documentation:**

```swift
/// [Description of the currentMonth property]
```

### currentYear (Line 733)

**Context:**

```swift
    }
    
    private func navigateToCurrentYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.selectedYear = currentYear
    }
}
```

**Suggested Documentation:**

```swift
/// [Description of the currentYear property]
```

### env (Line 740)

**Context:**

```swift

// New view for year selection
struct YearSelectionView: View {
    @EnvironmentObject var env: AppDependencies
    var availableYears: [Int]
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
```

**Suggested Documentation:**

```swift
/// [Description of the env property]
```

### availableYears (Line 741)

**Context:**

```swift
// New view for year selection
struct YearSelectionView: View {
    @EnvironmentObject var env: AppDependencies
    var availableYears: [Int]
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
```

**Suggested Documentation:**

```swift
/// [Description of the availableYears property]
```

### selectedYear (Line 742)

**Context:**

```swift
struct YearSelectionView: View {
    @EnvironmentObject var env: AppDependencies
    var availableYears: [Int]
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
    var body: some View {
```

**Suggested Documentation:**

```swift
/// [Description of the selectedYear property]
```

### isPresented (Line 743)

**Context:**

```swift
    @EnvironmentObject var env: AppDependencies
    var availableYears: [Int]
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        List {
```

**Suggested Documentation:**

```swift
/// [Description of the isPresented property]
```

### body (Line 745)

**Context:**

```swift
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        List {
            ForEach(availableYears, id: \.self) { year in
                Button {
```

**Suggested Documentation:**

```swift
/// [Description of the body property]
```


Total documentation suggestions: 71

