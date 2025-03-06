Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Models/SaleCategory.swift...
# Documentation Suggestions for SaleCategory.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Sales/Models/SaleCategory.swift
Total suggestions: 110

## Class Documentation (7)

### SaleCategory (Line 4)

**Context:**

```swift
import SwiftUI
import FirebaseFirestore

struct SaleCategory: Codable, Identifiable, Hashable {
    var id: String { categoryType.rawValue }
    var categoryType: CategoryType
    var letturaCassa: Double
```

**Suggested Documentation:**

```swift
/// SaleCategory class.
///
/// [Add a description of what this class does and its responsibilities]
```

### CategoryType (Line 16)

**Context:**

```swift
    var cocai: Double? // Only for dinner
    var persone: Int? // New field only for lunch - customer count
    
    enum CategoryType: String, Codable, CaseIterable {
        case lunch
        case dinner
        
```

**Suggested Documentation:**

```swift
/// CategoryType class.
///
/// [Add a description of what this class does and its responsibilities]
```

### DailySales (Line 66)

**Context:**

```swift
    }
}

struct DailySales: Codable, Identifiable, Hashable {
    var id: String { dateString }
    var dateString: String
    var normalizedDate: Date? {
```

**Suggested Documentation:**

```swift
/// DailySales class.
///
/// [Add a description of what this class does and its responsibilities]
```

### MonthlySalesRecap (Line 106)

**Context:**

```swift
    }
}

struct MonthlySalesRecap: Identifiable {
    var id: String { "\(String(year))-\(month)" }
    var year: Int
    var month: Int
```

**Suggested Documentation:**

```swift
/// MonthlySalesRecap class.
///
/// [Add a description of what this class does and its responsibilities]
```

### YearlySalesRecap (Line 214)

**Context:**

```swift
    }
}

struct YearlySalesRecap: Identifiable {
    var id: Int { year }
    var year: Int
    var monthlyRecaps: [MonthlySalesRecap]
```

**Suggested Documentation:**

```swift
/// YearlySalesRecap class.
///
/// [Add a description of what this class does and its responsibilities]
```

### SalesStore (Line 301)

**Context:**

```swift
    }
}

class SalesStore: ObservableObject {
    @Published var allSales: [DailySales] = []
    @Published var isAuthorized: Bool = false // Track if user is authorized to view totals
    
```

**Suggested Documentation:**

```swift
/// SalesStore class.
///
/// [Add a description of what this class does and its responsibilities]
```

### SalesStore (Line 405)

**Context:**

```swift
    }
}

extension SalesStore {
    // Delete all sales for a specific year
    func deleteYear(_ year: Int) {
        // Ensure the user is authorized
```

**Suggested Documentation:**

```swift
/// SalesStore class.
///
/// [Add a description of what this class does and its responsibilities]
```

## Method Documentation (13)

### createEmpty (Line 61)

**Context:**

```swift
        }
    }
    
    static func createEmpty(for categoryType: CategoryType) -> SaleCategory {
        SaleCategory(categoryType: categoryType)
    }
}
```

**Suggested Documentation:**

```swift
/// [Add a description of what the createEmpty method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### createEmpty (Line 96)

**Context:**

```swift
        self.lastEditedOn = lastEditedOn
    }
    
    static func createEmpty(for date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        return DailySales(
            dateString: dateString,
```

**Suggested Documentation:**

```swift
/// [Add a description of what the createEmpty method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### setAllSales (Line 305)

**Context:**

```swift
    @Published var allSales: [DailySales] = []
    @Published var isAuthorized: Bool = false // Track if user is authorized to view totals
    
    func setAllSales(_ sales: [DailySales]) {
        self.allSales = sales
    }
    
```

**Suggested Documentation:**

```swift
/// [Add a description of what the setAllSales method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getSalesForDay (Line 309)

**Context:**

```swift
        self.allSales = sales
    }
    
    func getSalesForDay(date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        if let existingSales = allSales.first(where: { $0.dateString == dateString }) {
            return existingSales
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getSalesForDay method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### updateSales (Line 317)

**Context:**

```swift
        return DailySales.createEmpty(for: date)
    }
    
    func updateSales(_ sales: DailySales) {
        if let index = allSales.firstIndex(where: { $0.dateString == sales.dateString }) {
            allSales[index] = sales
        } else {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the updateSales method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getMonthlyRecap (Line 325)

**Context:**

```swift
        }
    }
    
    func getMonthlyRecap(year: Int, month: Int) -> MonthlySalesRecap {
        let salesInMonth = allSales.filter { sales in
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getMonthlyRecap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getYearlyRecap (Line 337)

**Context:**

```swift
        return MonthlySalesRecap(year: year, month: month, days: salesInMonth)
    }
    
    func getYearlyRecap(year: Int) -> YearlySalesRecap {
        let monthlyRecaps = (1...12).map { month in
            getMonthlyRecap(year: year, month: month)
        }
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getYearlyRecap method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### getAvailableYears (Line 345)

**Context:**

```swift
        return YearlySalesRecap(year: year, monthlyRecaps: monthlyRecaps)
    }
    
    func getAvailableYears() -> [Int] {
        var years = Set<Int>()
        
        for sale in allSales {
```

**Suggested Documentation:**

```swift
/// [Add a description of what the getAvailableYears method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### refreshSalesData (Line 363)

**Context:**

```swift
    }
    
    // Add this method to your SalesStore class
    func refreshSalesData(for date: Date) {
        // Convert the date to string format used by the store
        let dateString = DateHelper.formatDate(date)
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the refreshSalesData method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### authenticate (Line 390)

**Context:**

```swift
    }
    
    // Authenticates the user to view sales totals
    func authenticate(password: String) -> Bool {
        let correctPassword = "Koenjiiscool2025!"
        if password == correctPassword {
            isAuthorized = true
```

**Suggested Documentation:**

```swift
/// [Add a description of what the authenticate method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### logout (Line 400)

**Context:**

```swift
    }
    
    // Log out (reset authorization)
    func logout() {
        isAuthorized = false
    }
}
```

**Suggested Documentation:**

```swift
/// [Add a description of what the logout method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteYear (Line 407)

**Context:**

```swift

extension SalesStore {
    // Delete all sales for a specific year
    func deleteYear(_ year: Int) {
        // Ensure the user is authorized
        guard isAuthorized else { return }
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteYear method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### deleteMonth (Line 426)

**Context:**

```swift
    }
    
    // Delete all sales for a specific month in a specific year
    func deleteMonth(year: Int, month: Int) {
        // Ensure the user is authorized
        guard isAuthorized else { return }
        
```

**Suggested Documentation:**

```swift
/// [Add a description of what the deleteMonth method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (90)

### id (Line 5)

**Context:**

```swift
import FirebaseFirestore

struct SaleCategory: Codable, Identifiable, Hashable {
    var id: String { categoryType.rawValue }
    var categoryType: CategoryType
    var letturaCassa: Double
    var fatture: Double
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### categoryType (Line 6)

**Context:**

```swift

struct SaleCategory: Codable, Identifiable, Hashable {
    var id: String { categoryType.rawValue }
    var categoryType: CategoryType
    var letturaCassa: Double
    var fatture: Double
    var yami: Double
```

**Suggested Documentation:**

```swift
/// [Description of the categoryType property]
```

### letturaCassa (Line 7)

**Context:**

```swift
struct SaleCategory: Codable, Identifiable, Hashable {
    var id: String { categoryType.rawValue }
    var categoryType: CategoryType
    var letturaCassa: Double
    var fatture: Double
    var yami: Double
    var yamiPulito: Double // New field for both categories
```

**Suggested Documentation:**

```swift
/// [Description of the letturaCassa property]
```

### fatture (Line 8)

**Context:**

```swift
    var id: String { categoryType.rawValue }
    var categoryType: CategoryType
    var letturaCassa: Double
    var fatture: Double
    var yami: Double
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
```

**Suggested Documentation:**

```swift
/// [Description of the fatture property]
```

### yami (Line 9)

**Context:**

```swift
    var categoryType: CategoryType
    var letturaCassa: Double
    var fatture: Double
    var yami: Double
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
```

**Suggested Documentation:**

```swift
/// [Description of the yami property]
```

### yamiPulito (Line 10)

**Context:**

```swift
    var letturaCassa: Double
    var fatture: Double
    var yami: Double
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
    var cocai: Double? // Only for dinner
```

**Suggested Documentation:**

```swift
/// [Description of the yamiPulito property]
```

### totalShiro (Line 11)

**Context:**

```swift
    var fatture: Double
    var yami: Double
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
    var cocai: Double? // Only for dinner
    var persone: Int? // New field only for lunch - customer count
```

**Suggested Documentation:**

```swift
/// [Description of the totalShiro property]
```

### bento (Line 12)

**Context:**

```swift
    var yami: Double
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
    var cocai: Double? // Only for dinner
    var persone: Int? // New field only for lunch - customer count
    
```

**Suggested Documentation:**

```swift
/// [Description of the bento property]
```

### cocai (Line 13)

**Context:**

```swift
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
    var cocai: Double? // Only for dinner
    var persone: Int? // New field only for lunch - customer count
    
    enum CategoryType: String, Codable, CaseIterable {
```

**Suggested Documentation:**

```swift
/// [Description of the cocai property]
```

### persone (Line 14)

**Context:**

```swift
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
    var cocai: Double? // Only for dinner
    var persone: Int? // New field only for lunch - customer count
    
    enum CategoryType: String, Codable, CaseIterable {
        case lunch
```

**Suggested Documentation:**

```swift
/// [Description of the persone property]
```

### localized (Line 20)

**Context:**

```swift
        case lunch
        case dinner
        
        var localized: String {
            switch self {
            case .lunch: return String(localized: "Pranzo")
            case .dinner: return String(localized: "Cena")
```

**Suggested Documentation:**

```swift
/// [Description of the localized property]
```

### color (Line 27)

**Context:**

```swift
            }
        }
        
        var color: Color {
            switch self {
            case .lunch: return .orange
            case .dinner: return .indigo
```

**Suggested Documentation:**

```swift
/// [Description of the color property]
```

### iconName (Line 34)

**Context:**

```swift
            }
        }
        
        var iconName: String {
            switch self {
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
```

**Suggested Documentation:**

```swift
/// [Description of the iconName property]
```

### id (Line 67)

**Context:**

```swift
}

struct DailySales: Codable, Identifiable, Hashable {
    var id: String { dateString }
    var dateString: String
    var normalizedDate: Date? {
        DateHelper.parseDate(dateString)
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### dateString (Line 68)

**Context:**

```swift

struct DailySales: Codable, Identifiable, Hashable {
    var id: String { dateString }
    var dateString: String
    var normalizedDate: Date? {
        DateHelper.parseDate(dateString)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### normalizedDate (Line 69)

**Context:**

```swift
struct DailySales: Codable, Identifiable, Hashable {
    var id: String { dateString }
    var dateString: String
    var normalizedDate: Date? {
        DateHelper.parseDate(dateString)
    }
    var lunch: SaleCategory
```

**Suggested Documentation:**

```swift
/// [Description of the normalizedDate property]
```

### lunch (Line 72)

**Context:**

```swift
    var normalizedDate: Date? {
        DateHelper.parseDate(dateString)
    }
    var lunch: SaleCategory
    var dinner: SaleCategory
    var lastEditedOn: Date
    
```

**Suggested Documentation:**

```swift
/// [Description of the lunch property]
```

### dinner (Line 73)

**Context:**

```swift
        DateHelper.parseDate(dateString)
    }
    var lunch: SaleCategory
    var dinner: SaleCategory
    var lastEditedOn: Date
    
    // Computed properties for totals - Modified to exclude lunch from the total
```

**Suggested Documentation:**

```swift
/// [Description of the dinner property]
```

### lastEditedOn (Line 74)

**Context:**

```swift
    }
    var lunch: SaleCategory
    var dinner: SaleCategory
    var lastEditedOn: Date
    
    // Computed properties for totals - Modified to exclude lunch from the total
    var totalSales: Double {
```

**Suggested Documentation:**

```swift
/// [Description of the lastEditedOn property]
```

### totalSales (Line 77)

**Context:**

```swift
    var lastEditedOn: Date
    
    // Computed properties for totals - Modified to exclude lunch from the total
    var totalSales: Double {
        // Only count dinner sales for the total
        dinner.totalShiro + dinner.yami
    }
```

**Suggested Documentation:**

```swift
/// [Description of the totalSales property]
```

### averageLunchSpend (Line 83)

**Context:**

```swift
    }
    
    // Average spend per customer at lunch (if customer count > 0)
    var averageLunchSpend: Double? {
        guard let persone = lunch.persone, persone > 0 else { return nil }
        let lunchTotal = lunch.totalShiro + lunch.yami
        return lunchTotal / Double(persone)
```

**Suggested Documentation:**

```swift
/// [Description of the averageLunchSpend property]
```

### persone (Line 84)

**Context:**

```swift
    
    // Average spend per customer at lunch (if customer count > 0)
    var averageLunchSpend: Double? {
        guard let persone = lunch.persone, persone > 0 else { return nil }
        let lunchTotal = lunch.totalShiro + lunch.yami
        return lunchTotal / Double(persone)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the persone property]
```

### lunchTotal (Line 85)

**Context:**

```swift
    // Average spend per customer at lunch (if customer count > 0)
    var averageLunchSpend: Double? {
        guard let persone = lunch.persone, persone > 0 else { return nil }
        let lunchTotal = lunch.totalShiro + lunch.yami
        return lunchTotal / Double(persone)
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the lunchTotal property]
```

### dateString (Line 97)

**Context:**

```swift
    }
    
    static func createEmpty(for date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        return DailySales(
            dateString: dateString,
            lunch: SaleCategory.createEmpty(for: .lunch),
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### id (Line 107)

**Context:**

```swift
}

struct MonthlySalesRecap: Identifiable {
    var id: String { "\(String(year))-\(month)" }
    var year: Int
    var month: Int
    var days: [DailySales]
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### year (Line 108)

**Context:**

```swift

struct MonthlySalesRecap: Identifiable {
    var id: String { "\(String(year))-\(month)" }
    var year: Int
    var month: Int
    var days: [DailySales]
    
```

**Suggested Documentation:**

```swift
/// [Description of the year property]
```

### month (Line 109)

**Context:**

```swift
struct MonthlySalesRecap: Identifiable {
    var id: String { "\(String(year))-\(month)" }
    var year: Int
    var month: Int
    var days: [DailySales]
    
    var monthName: String {
```

**Suggested Documentation:**

```swift
/// [Description of the month property]
```

### days (Line 110)

**Context:**

```swift
    var id: String { "\(String(year))-\(month)" }
    var year: Int
    var month: Int
    var days: [DailySales]
    
    var monthName: String {
        let dateFormatter = DateFormatter()
```

**Suggested Documentation:**

```swift
/// [Description of the days property]
```

### monthName (Line 112)

**Context:**

```swift
    var month: Int
    var days: [DailySales]
    
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(localized: "it_IT"))
        dateFormatter.dateFormat = "MMMM"
```

**Suggested Documentation:**

```swift
/// [Description of the monthName property]
```

### dateFormatter (Line 113)

**Context:**

```swift
    var days: [DailySales]
    
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(localized: "it_IT"))
        dateFormatter.dateFormat = "MMMM"
        
```

**Suggested Documentation:**

```swift
/// [Description of the dateFormatter property]
```

### components (Line 117)

**Context:**

```swift
        dateFormatter.locale = Locale(identifier: String(localized: "it_IT"))
        dateFormatter.dateFormat = "MMMM"
        
        var components = DateComponents()
        components.year = year
        components.month = month
        
```

**Suggested Documentation:**

```swift
/// [Description of the components property]
```

### date (Line 121)

**Context:**

```swift
        components.year = year
        components.month = month
        
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date).capitalized
        }
        return ""
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### totalLunchSales (Line 128)

**Context:**

```swift
    }
    
    // Monthly totals - Modified to exclude lunch from the total
    var totalLunchSales: Double {
        days.reduce(0) { total, day in
            let lunchTotal = day.lunch.totalShiro + day.lunch.yami
            return total + lunchTotal
```

**Suggested Documentation:**

```swift
/// [Description of the totalLunchSales property]
```

### lunchTotal (Line 130)

**Context:**

```swift
    // Monthly totals - Modified to exclude lunch from the total
    var totalLunchSales: Double {
        days.reduce(0) { total, day in
            let lunchTotal = day.lunch.totalShiro + day.lunch.yami
            return total + lunchTotal
        }
    }
```

**Suggested Documentation:**

```swift
/// [Description of the lunchTotal property]
```

### totalDinnerSales (Line 135)

**Context:**

```swift
        }
    }
    
    var totalDinnerSales: Double {
        days.reduce(0) { total, day in
            let dinnerTotal = day.dinner.totalShiro + day.dinner.yami
            return total + dinnerTotal
```

**Suggested Documentation:**

```swift
/// [Description of the totalDinnerSales property]
```

### dinnerTotal (Line 137)

**Context:**

```swift
    
    var totalDinnerSales: Double {
        days.reduce(0) { total, day in
            let dinnerTotal = day.dinner.totalShiro + day.dinner.yami
            return total + dinnerTotal
        }
    }
```

**Suggested Documentation:**

```swift
/// [Description of the dinnerTotal property]
```

### totalSales (Line 143)

**Context:**

```swift
    }
    
    // Total sales now only counts dinner sales
    var totalSales: Double {
        totalDinnerSales - totalYamiPulito
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the totalSales property]
```

### totalLetturaCassa (Line 148)

**Context:**

```swift
    }
    
    // Category breakdowns
    var totalLetturaCassa: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.letturaCassa
```

**Suggested Documentation:**

```swift
/// [Description of the totalLetturaCassa property]
```

### totalFatture (Line 155)

**Context:**

```swift
        }
    }
    
    var totalFatture: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.fatture
```

**Suggested Documentation:**

```swift
/// [Description of the totalFatture property]
```

### totalShiro (Line 162)

**Context:**

```swift
        }
    }
    
    var totalShiro: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.fatture + day.dinner.letturaCassa
```

**Suggested Documentation:**

```swift
/// [Description of the totalShiro property]
```

### totalYami (Line 169)

**Context:**

```swift
        }
    }
    
    var totalYami: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.yami
```

**Suggested Documentation:**

```swift
/// [Description of the totalYami property]
```

### totalYamiPulito (Line 177)

**Context:**

```swift
    }
    
    // New property for Yami Pulito
    var totalYamiPulito: Double {
        days.reduce(0) { total, day in
            return total + day.dinner.yamiPulito
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalYamiPulito property]
```

### netYami (Line 184)

**Context:**

```swift
    }
    
    // Net Yami after subtracting YamiPulito
    var netYami: Double {
        totalYami - totalYamiPulito
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the netYami property]
```

### totalLunchCustomers (Line 188)

**Context:**

```swift
        totalYami - totalYamiPulito
    }
    
    var totalLunchCustomers: Int {
        days.reduce(0) { total, day in
            return total + (day.lunch.persone ?? 0)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalLunchCustomers property]
```

### averageLunchSpend (Line 195)

**Context:**

```swift
    }
    
    // Average spend per customer at lunch across the month
    var averageLunchSpend: Double? {
        let totalCustomers = totalLunchCustomers
        guard totalCustomers > 0 else { return nil }
        return totalLunchSales / Double(totalCustomers)
```

**Suggested Documentation:**

```swift
/// [Description of the averageLunchSpend property]
```

### totalCustomers (Line 196)

**Context:**

```swift
    
    // Average spend per customer at lunch across the month
    var averageLunchSpend: Double? {
        let totalCustomers = totalLunchCustomers
        guard totalCustomers > 0 else { return nil }
        return totalLunchSales / Double(totalCustomers)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the totalCustomers property]
```

### totalBento (Line 201)

**Context:**

```swift
        return totalLunchSales / Double(totalCustomers)
    }
    
    var totalBento: Double {
        days.reduce(0) { total, day in
            return total + (day.lunch.bento ?? 0)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalBento property]
```

### totalCocai (Line 207)

**Context:**

```swift
        }
    }
    
    var totalCocai: Double {
        days.reduce(0) { total, day in
            return total + (day.dinner.cocai ?? 0)
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalCocai property]
```

### id (Line 215)

**Context:**

```swift
}

struct YearlySalesRecap: Identifiable {
    var id: Int { year }
    var year: Int
    var monthlyRecaps: [MonthlySalesRecap]
    
```

**Suggested Documentation:**

```swift
/// [Description of the id property]
```

### year (Line 216)

**Context:**

```swift

struct YearlySalesRecap: Identifiable {
    var id: Int { year }
    var year: Int
    var monthlyRecaps: [MonthlySalesRecap]
    
    var totalSales: Double {
```

**Suggested Documentation:**

```swift
/// [Description of the year property]
```

### monthlyRecaps (Line 217)

**Context:**

```swift
struct YearlySalesRecap: Identifiable {
    var id: Int { year }
    var year: Int
    var monthlyRecaps: [MonthlySalesRecap]
    
    var totalSales: Double {
        monthlyRecaps.reduce(0) { total, month in
```

**Suggested Documentation:**

```swift
/// [Description of the monthlyRecaps property]
```

### totalSales (Line 219)

**Context:**

```swift
    var year: Int
    var monthlyRecaps: [MonthlySalesRecap]
    
    var totalSales: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalSales
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalSales property]
```

### totalLunchSales (Line 225)

**Context:**

```swift
        }
    }
    
    var totalLunchSales: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalLunchSales
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalLunchSales property]
```

### totalDinnerSales (Line 231)

**Context:**

```swift
        }
    }
    
    var totalDinnerSales: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalDinnerSales
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalDinnerSales property]
```

### totalLetturaCassa (Line 238)

**Context:**

```swift
    }
    
    // Category breakdowns
    var totalLetturaCassa: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalLetturaCassa
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalLetturaCassa property]
```

### totalFatture (Line 244)

**Context:**

```swift
        }
    }
    
    var totalFatture: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalFatture
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalFatture property]
```

### totalShiro (Line 250)

**Context:**

```swift
        }
    }
    
    var totalShiro: Double {
        monthlyRecaps.reduce(0) { total, month in
            // Only count dinner for the total
            return total + month.totalFatture + month.totalLetturaCassa
```

**Suggested Documentation:**

```swift
/// [Description of the totalShiro property]
```

### totalYami (Line 257)

**Context:**

```swift
        }
    }
    
    var totalYami: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalYami
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalYami property]
```

### totalYamiPulito (Line 264)

**Context:**

```swift
    }
    
    // New property for Yami Pulito
    var totalYamiPulito: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalYamiPulito
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalYamiPulito property]
```

### netYami (Line 271)

**Context:**

```swift
    }
    
    // Net Yami after subtracting YamiPulito
    var netYami: Double {
        totalYami - totalYamiPulito
    }
    
```

**Suggested Documentation:**

```swift
/// [Description of the netYami property]
```

### totalLunchCustomers (Line 275)

**Context:**

```swift
        totalYami - totalYamiPulito
    }
    
    var totalLunchCustomers: Int {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalLunchCustomers
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalLunchCustomers property]
```

### averageLunchSpend (Line 282)

**Context:**

```swift
    }
    
    // Average spend per customer at lunch across the year
    var averageLunchSpend: Double? {
        let totalCustomers = totalLunchCustomers
        guard totalCustomers > 0 else { return nil }
        return totalLunchSales / Double(totalCustomers)
```

**Suggested Documentation:**

```swift
/// [Description of the averageLunchSpend property]
```

### totalCustomers (Line 283)

**Context:**

```swift
    
    // Average spend per customer at lunch across the year
    var averageLunchSpend: Double? {
        let totalCustomers = totalLunchCustomers
        guard totalCustomers > 0 else { return nil }
        return totalLunchSales / Double(totalCustomers)
    }
```

**Suggested Documentation:**

```swift
/// [Description of the totalCustomers property]
```

### totalBento (Line 288)

**Context:**

```swift
        return totalLunchSales / Double(totalCustomers)
    }
    
    var totalBento: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalBento
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalBento property]
```

### totalCocai (Line 294)

**Context:**

```swift
        }
    }
    
    var totalCocai: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalCocai
        }
```

**Suggested Documentation:**

```swift
/// [Description of the totalCocai property]
```

### allSales (Line 302)

**Context:**

```swift
}

class SalesStore: ObservableObject {
    @Published var allSales: [DailySales] = []
    @Published var isAuthorized: Bool = false // Track if user is authorized to view totals
    
    func setAllSales(_ sales: [DailySales]) {
```

**Suggested Documentation:**

```swift
/// [Description of the allSales property]
```

### isAuthorized (Line 303)

**Context:**

```swift

class SalesStore: ObservableObject {
    @Published var allSales: [DailySales] = []
    @Published var isAuthorized: Bool = false // Track if user is authorized to view totals
    
    func setAllSales(_ sales: [DailySales]) {
        self.allSales = sales
```

**Suggested Documentation:**

```swift
/// [Description of the isAuthorized property]
```

### dateString (Line 310)

**Context:**

```swift
    }
    
    func getSalesForDay(date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        if let existingSales = allSales.first(where: { $0.dateString == dateString }) {
            return existingSales
        }
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### existingSales (Line 311)

**Context:**

```swift
    
    func getSalesForDay(date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        if let existingSales = allSales.first(where: { $0.dateString == dateString }) {
            return existingSales
        }
        return DailySales.createEmpty(for: date)
```

**Suggested Documentation:**

```swift
/// [Description of the existingSales property]
```

### index (Line 318)

**Context:**

```swift
    }
    
    func updateSales(_ sales: DailySales) {
        if let index = allSales.firstIndex(where: { $0.dateString == sales.dateString }) {
            allSales[index] = sales
        } else {
            allSales.append(sales)
```

**Suggested Documentation:**

```swift
/// [Description of the index property]
```

### salesInMonth (Line 326)

**Context:**

```swift
    }
    
    func getMonthlyRecap(year: Int, month: Int) -> MonthlySalesRecap {
        let salesInMonth = allSales.filter { sales in
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
            let salesYear = calendar.component(.year, from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the salesInMonth property]
```

### date (Line 327)

**Context:**

```swift
    
    func getMonthlyRecap(year: Int, month: Int) -> MonthlySalesRecap {
        let salesInMonth = allSales.filter { sales in
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
            let salesYear = calendar.component(.year, from: date)
            let salesMonth = calendar.component(.month, from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### calendar (Line 328)

**Context:**

```swift
    func getMonthlyRecap(year: Int, month: Int) -> MonthlySalesRecap {
        let salesInMonth = allSales.filter { sales in
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
            let salesYear = calendar.component(.year, from: date)
            let salesMonth = calendar.component(.month, from: date)
            return salesYear == year && salesMonth == month
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### salesYear (Line 329)

**Context:**

```swift
        let salesInMonth = allSales.filter { sales in
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
            let salesYear = calendar.component(.year, from: date)
            let salesMonth = calendar.component(.month, from: date)
            return salesYear == year && salesMonth == month
        }
```

**Suggested Documentation:**

```swift
/// [Description of the salesYear property]
```

### salesMonth (Line 330)

**Context:**

```swift
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
            let salesYear = calendar.component(.year, from: date)
            let salesMonth = calendar.component(.month, from: date)
            return salesYear == year && salesMonth == month
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the salesMonth property]
```

### monthlyRecaps (Line 338)

**Context:**

```swift
    }
    
    func getYearlyRecap(year: Int) -> YearlySalesRecap {
        let monthlyRecaps = (1...12).map { month in
            getMonthlyRecap(year: year, month: month)
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the monthlyRecaps property]
```

### years (Line 346)

**Context:**

```swift
    }
    
    func getAvailableYears() -> [Int] {
        var years = Set<Int>()
        
        for sale in allSales {
            if let date = sale.normalizedDate {
```

**Suggested Documentation:**

```swift
/// [Description of the years property]
```

### date (Line 349)

**Context:**

```swift
        var years = Set<Int>()
        
        for sale in allSales {
            if let date = sale.normalizedDate {
                let year = Calendar.current.component(.year, from: date)
                years.insert(year)
            }
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### year (Line 350)

**Context:**

```swift
        
        for sale in allSales {
            if let date = sale.normalizedDate {
                let year = Calendar.current.component(.year, from: date)
                years.insert(year)
            }
        }
```

**Suggested Documentation:**

```swift
/// [Description of the year property]
```

### dateString (Line 365)

**Context:**

```swift
    // Add this method to your SalesStore class
    func refreshSalesData(for date: Date) {
        // Convert the date to string format used by the store
        let dateString = DateHelper.formatDate(date)
        
        // Check if we already have sales data for this date
        let existingSales = allSales.first(where: { $0.dateString == dateString })
```

**Suggested Documentation:**

```swift
/// [Description of the dateString property]
```

### existingSales (Line 368)

**Context:**

```swift
        let dateString = DateHelper.formatDate(date)
        
        // Check if we already have sales data for this date
        let existingSales = allSales.first(where: { $0.dateString == dateString })
        
        if existingSales == nil {
            // If no data exists yet, create a default empty sales object
```

**Suggested Documentation:**

```swift
/// [Description of the existingSales property]
```

### emptySales (Line 372)

**Context:**

```swift
        
        if existingSales == nil {
            // If no data exists yet, create a default empty sales object
            let emptySales = DailySales.createEmpty(for: date)
            
            // Add it to the local collection
            allSales.append(emptySales)
```

**Suggested Documentation:**

```swift
/// [Description of the emptySales property]
```

### correctPassword (Line 391)

**Context:**

```swift
    
    // Authenticates the user to view sales totals
    func authenticate(password: String) -> Bool {
        let correctPassword = "Koenjiiscool2025!"
        if password == correctPassword {
            isAuthorized = true
            return true
```

**Suggested Documentation:**

```swift
/// [Description of the correctPassword property]
```

### date (Line 413)

**Context:**

```swift
        
        // Remove sales for the specified year
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            return saleYear == year
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### calendar (Line 414)

**Context:**

```swift
        // Remove sales for the specified year
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            return saleYear == year
        }
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### saleYear (Line 415)

**Context:**

```swift
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            return saleYear == year
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the saleYear property]
```

### date (Line 432)

**Context:**

```swift
        
        // Remove sales for the specified year and month
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            let saleMonth = calendar.component(.month, from: date)
```

**Suggested Documentation:**

```swift
/// [Description of the date property]
```

### calendar (Line 433)

**Context:**

```swift
        // Remove sales for the specified year and month
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            let saleMonth = calendar.component(.month, from: date)
            return saleYear == year && saleMonth == month
```

**Suggested Documentation:**

```swift
/// [Description of the calendar property]
```

### saleYear (Line 434)

**Context:**

```swift
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            let saleMonth = calendar.component(.month, from: date)
            return saleYear == year && saleMonth == month
        }
```

**Suggested Documentation:**

```swift
/// [Description of the saleYear property]
```

### saleMonth (Line 435)

**Context:**

```swift
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            let saleMonth = calendar.component(.month, from: date)
            return saleYear == year && saleMonth == month
        }
        
```

**Suggested Documentation:**

```swift
/// [Description of the saleMonth property]
```


Total documentation suggestions: 110

