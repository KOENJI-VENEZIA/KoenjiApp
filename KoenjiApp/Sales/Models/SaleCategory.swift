import SwiftUI
import FirebaseFirestore

struct SaleCategory: Codable, Identifiable, Hashable {
    var id: String { categoryType.rawValue }
    var categoryType: CategoryType
    var letturaCassa: Double
    var fatture: Double
    var yami: Double
    var yamiPulito: Double // New field for both categories
    var totalShiro: Double { letturaCassa + fatture }
    var bento: Double? // Only for lunch
    var cocai: Double? // Only for dinner
    var persone: Int? // New field only for lunch - customer count
    
    enum CategoryType: String, Codable, CaseIterable {
        case lunch
        case dinner
        
        var localized: String {
            switch self {
            case .lunch: return String(localized: "Pranzo")
            case .dinner: return String(localized: "Cena")
            }
        }
        
        var color: Color {
            switch self {
            case .lunch: return .orange
            case .dinner: return .indigo
            }
        }
        
        var iconName: String {
            switch self {
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            }
        }
    }
    
    init(categoryType: CategoryType, letturaCassa: Double = 0, fatture: Double = 0, yami: Double = 0, yamiPulito: Double = 0, bento: Double? = nil, cocai: Double? = nil, persone: Int? = nil) {
        self.categoryType = categoryType
        self.letturaCassa = letturaCassa
        self.fatture = fatture
        self.yami = yami
        self.yamiPulito = yamiPulito
        
        // Set optional fields based on category
        if categoryType == .lunch {
            self.bento = bento
            self.cocai = nil
            self.persone = persone
        } else {
            self.bento = nil
            self.cocai = cocai
            self.persone = nil
        }
    }
    
    static func createEmpty(for categoryType: CategoryType) -> SaleCategory {
        SaleCategory(categoryType: categoryType)
    }
}

struct DailySales: Codable, Identifiable, Hashable {
    var id: String { dateString }
    var dateString: String
    var normalizedDate: Date? {
        DateHelper.parseDate(dateString)
    }
    var lunch: SaleCategory
    var dinner: SaleCategory
    var lastEditedOn: Date
    
    // Computed properties for totals - Modified to exclude lunch from the total
    var totalSales: Double {
        // Only count dinner sales for the total
        dinner.totalShiro + dinner.yami
    }
    
    // Average spend per customer at lunch (if customer count > 0)
    var averageLunchSpend: Double? {
        guard let persone = lunch.persone, persone > 0 else { return nil }
        let lunchTotal = lunch.totalShiro + lunch.yami
        return lunchTotal / Double(persone)
    }
    
    init(dateString: String, lunch: SaleCategory? = nil, dinner: SaleCategory? = nil, lastEditedOn: Date = Date()) {
        self.dateString = dateString
        self.lunch = lunch ?? SaleCategory.createEmpty(for: .lunch)
        self.dinner = dinner ?? SaleCategory.createEmpty(for: .dinner)
        self.lastEditedOn = lastEditedOn
    }
    
    static func createEmpty(for date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        return DailySales(
            dateString: dateString,
            lunch: SaleCategory.createEmpty(for: .lunch),
            dinner: SaleCategory.createEmpty(for: .dinner)
        )
    }
}

struct MonthlySalesRecap: Identifiable {
    var id: String { "\(String(year))-\(month)" }
    var year: Int
    var month: Int
    var days: [DailySales]
    
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: String(localized: "it_IT"))
        dateFormatter.dateFormat = "MMMM"
        
        var components = DateComponents()
        components.year = year
        components.month = month
        
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date).capitalized
        }
        return ""
    }
    
    // Monthly totals - Modified to exclude lunch from the total
    var totalLunchSales: Double {
        days.reduce(0) { total, day in
            let lunchTotal = day.lunch.totalShiro + day.lunch.yami
            return total + lunchTotal
        }
    }
    
    var totalDinnerSales: Double {
        days.reduce(0) { total, day in
            let dinnerTotal = day.dinner.totalShiro + day.dinner.yami
            return total + dinnerTotal
        }
    }
    
    // Total sales now only counts dinner sales
    var totalSales: Double {
        totalDinnerSales - totalYamiPulito
    }
    
    // Category breakdowns
    var totalLetturaCassa: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.letturaCassa
        }
    }
    
    var totalFatture: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.fatture
        }
    }
    
    var totalShiro: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.fatture + day.dinner.letturaCassa
        }
    }
    
    var totalYami: Double {
        days.reduce(0) { total, day in
            // Only count dinner for the total
            return total + day.dinner.yami
        }
    }
    
    // New property for Yami Pulito
    var totalYamiPulito: Double {
        days.reduce(0) { total, day in
            return total + day.dinner.yamiPulito
        }
    }
    
    // Net Yami after subtracting YamiPulito
    var netYami: Double {
        totalYami - totalYamiPulito
    }
    
    var totalLunchCustomers: Int {
        days.reduce(0) { total, day in
            return total + (day.lunch.persone ?? 0)
        }
    }
    
    // Average spend per customer at lunch across the month
    var averageLunchSpend: Double? {
        let totalCustomers = totalLunchCustomers
        guard totalCustomers > 0 else { return nil }
        return totalLunchSales / Double(totalCustomers)
    }
    
    var totalBento: Double {
        days.reduce(0) { total, day in
            return total + (day.lunch.bento ?? 0)
        }
    }
    
    var totalCocai: Double {
        days.reduce(0) { total, day in
            return total + (day.dinner.cocai ?? 0)
        }
    }
}

struct YearlySalesRecap: Identifiable {
    var id: Int { year }
    var year: Int
    var monthlyRecaps: [MonthlySalesRecap]
    
    var totalSales: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalSales
        }
    }
    
    var totalLunchSales: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalLunchSales
        }
    }
    
    var totalDinnerSales: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalDinnerSales
        }
    }
    
    // Category breakdowns
    var totalLetturaCassa: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalLetturaCassa
        }
    }
    
    var totalFatture: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalFatture
        }
    }
    
    var totalShiro: Double {
        monthlyRecaps.reduce(0) { total, month in
            // Only count dinner for the total
            return total + month.totalFatture + month.totalLetturaCassa
        }
    }
    
    var totalYami: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalYami
        }
    }
    
    // New property for Yami Pulito
    var totalYamiPulito: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalYamiPulito
        }
    }
    
    // Net Yami after subtracting YamiPulito
    var netYami: Double {
        totalYami - totalYamiPulito
    }
    
    var totalLunchCustomers: Int {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalLunchCustomers
        }
    }
    
    // Average spend per customer at lunch across the year
    var averageLunchSpend: Double? {
        let totalCustomers = totalLunchCustomers
        guard totalCustomers > 0 else { return nil }
        return totalLunchSales / Double(totalCustomers)
    }
    
    var totalBento: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalBento
        }
    }
    
    var totalCocai: Double {
        monthlyRecaps.reduce(0) { total, month in
            return total + month.totalCocai
        }
    }
}

class SalesStore: ObservableObject {
    @Published var allSales: [DailySales] = []
    @Published var isAuthorized: Bool = false // Track if user is authorized to view totals
    
    func setAllSales(_ sales: [DailySales]) {
        self.allSales = sales
    }
    
    func getSalesForDay(date: Date) -> DailySales {
        let dateString = DateHelper.formatDate(date)
        if let existingSales = allSales.first(where: { $0.dateString == dateString }) {
            return existingSales
        }
        return DailySales.createEmpty(for: date)
    }
    
    func updateSales(_ sales: DailySales) {
        if let index = allSales.firstIndex(where: { $0.dateString == sales.dateString }) {
            allSales[index] = sales
        } else {
            allSales.append(sales)
        }
    }
    
    func getMonthlyRecap(year: Int, month: Int) -> MonthlySalesRecap {
        let salesInMonth = allSales.filter { sales in
            guard let date = sales.normalizedDate else { return false }
            let calendar = Calendar.current
            let salesYear = calendar.component(.year, from: date)
            let salesMonth = calendar.component(.month, from: date)
            return salesYear == year && salesMonth == month
        }
        
        return MonthlySalesRecap(year: year, month: month, days: salesInMonth)
    }
    
    func getYearlyRecap(year: Int) -> YearlySalesRecap {
        let monthlyRecaps = (1...12).map { month in
            getMonthlyRecap(year: year, month: month)
        }
        
        return YearlySalesRecap(year: year, monthlyRecaps: monthlyRecaps)
    }
    
    func getAvailableYears() -> [Int] {
        var years = Set<Int>()
        
        for sale in allSales {
            if let date = sale.normalizedDate {
                let year = Calendar.current.component(.year, from: date)
                years.insert(year)
            }
        }
        
        if years.isEmpty {
            years.insert(Calendar.current.component(.year, from: Date()))
        }
        
        return Array(years).sorted()
    }
    
    // Add this method to your SalesStore class
    func refreshSalesData(for date: Date) {
        // Convert the date to string format used by the store
        let dateString = DateHelper.formatDate(date)
        
        // Check if we already have sales data for this date
        let existingSales = allSales.first(where: { $0.dateString == dateString })
        
        if existingSales == nil {
            // If no data exists yet, create a default empty sales object
            let emptySales = DailySales.createEmpty(for: date)
            
            // Add it to the local collection
            allSales.append(emptySales)
            
            // Trigger UI update
            objectWillChange.send()
        } else {
            // If using Firebase, you could refresh from there
            // This is a simplified version that just ensures the data is available
            
            // No need to do anything if the data already exists
            // But we can trigger a UI update to ensure everything is refreshed
            objectWillChange.send()
        }
    }
    
    // Authenticates the user to view sales totals
    func authenticate(password: String) -> Bool {
        let correctPassword = "Koenjiiscool2025!"
        if password == correctPassword {
            isAuthorized = true
            return true
        }
        return false
    }
    
    // Log out (reset authorization)
    func logout() {
        isAuthorized = false
    }
}

extension SalesStore {
    // Delete all sales for a specific year
    func deleteYear(_ year: Int) {
        // Ensure the user is authorized
        guard isAuthorized else { return }
        
        // Remove sales for the specified year
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            return saleYear == year
        }
        
        // Trigger UI update
        objectWillChange.send()
        
        
    }
    
    // Delete all sales for a specific month in a specific year
    func deleteMonth(year: Int, month: Int) {
        // Ensure the user is authorized
        guard isAuthorized else { return }
        
        // Remove sales for the specified year and month
        allSales.removeAll { sale in
            guard let date = sale.normalizedDate else { return false }
            let calendar = Calendar.current
            let saleYear = calendar.component(.year, from: date)
            let saleMonth = calendar.component(.month, from: date)
            return saleYear == year && saleMonth == month
        }
        
        // Trigger UI update
        objectWillChange.send()
        
        
    }
}
