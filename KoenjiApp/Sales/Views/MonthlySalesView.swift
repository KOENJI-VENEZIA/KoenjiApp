import SwiftUI

struct MonthlySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    let year: Int
    let month: Int
    
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var monthlyRecap: MonthlySalesRecap?
    @State private var showExportOptions = false
    @State private var showAuthView = false
    
    // Export service
    private let exportService = ExcelExportService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Monthly header
                headerSection
                
                // Monthly calendar grid
                calendarGridSection
                
                // Monthly summary
                if let recap = monthlyRecap {
                    // Only show summary if authorized
                    if env.salesStore?.isAuthorized == true {
                        monthlySummarySection(recap: recap)
                    } else {
                        // Show auth required message
                        authRequiredSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle(monthName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingDailyView) {
            if let selectedDate = selectedDate {
                NavigationStack {
                    DailySalesView(
                        date: selectedDate,
                        existingSales: env.salesStore?.getSalesForDay(date: selectedDate)
                    )
                    .environmentObject(env)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(
                    destination:
                            SalesManagerView()
                                .environmentObject(env)
                ) {
                    Label("Indietro", systemImage: "chevron.left")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if env.salesStore?.isAuthorized == true {
                        showExportOptions = true
                    } else {
                        showAuthView = true
                    }
                } label: {
                    Label("Esporta", systemImage: "square.and.arrow.up")
                }
                .disabled(monthlyRecap == nil)
            }
        }
        .onAppear {
            updateMonthlyRecap()
        }
        .onChange(of: env.salesStore?.allSales) {
            updateMonthlyRecap()
        }
        .actionSheet(isPresented: $showExportOptions) {
            ActionSheet(
                title: Text("Esporta vendite \(monthName)"),
                message: Text("Scegli il formato del file"),
                buttons: [
                    .default(Text("Excel/CSV")) {
                        exportToExcel()
                    },
                    .cancel()
                ]
            )
        }
        .overlay {
            if showAuthView {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Close the auth view if tapped outside
                        showAuthView = false
                    }
                
                AuthenticationView(isPresented: $showAuthView)
                    .environmentObject(env)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(.title)
                .fontWeight(.bold)
            
            Text(String(year))
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if let recap = monthlyRecap, env.salesStore?.isAuthorized == true {
                Text("Totale mensile: \(recap.totalSales, format: .currency(code: "EUR"))")
                    .font(.title3)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var calendarGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendario Vendite")
                .font(.headline)
                .padding(.bottom, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                // Day header
                ForEach([  String(localized: "Mon"),
                           String(localized: "Tue"),
                           String(localized: "Wed"),
                           String(localized: "Thu"),
                           String(localized: "Fri"),
                           String(localized: "Sat"),
                           String(localized: "Sun")
                        ], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(height: 30)
                        .foregroundStyle(.secondary)
                }
                
                // Day cells
                ForEach(daysInMonth, id: \.self) { day in
                    if day > 0 {
                        let currentDate = dateForDay(day)
                        let daySales = salesForDay(day)
                        
                        Button {
                            selectedDate = currentDate
                            showingDailyView = true
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(day)")
                                    .font(.callout)
                                    .fontWeight(isToday(day: day) ? .bold : .regular)
                                
                                if let total = daySales?.totalSales, total > 0, env.salesStore?.isAuthorized == true {
                                    Text("\(Int(total))€")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            .frame(height: 46)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(backgroundForDay(day))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(strokeForDay(day), lineWidth: 1)
                            )
                        }
                    } else {
                        // Empty cell for days of previous month
                        Color.clear
                            .frame(height: 46)
                            .id("empty-\(day)") // Ensure unique ID for each placeholder
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var authRequiredSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Autenticazione Richiesta")
                .font(.headline)
            
            Text("Per visualizzare i dati di vendita è necessaria l'autenticazione")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                showAuthView = true
            } label: {
                Text("Accedi")
                    .fontWeight(.semibold)
                    .frame(minWidth: 100)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func monthlySummarySection(recap: MonthlySalesRecap) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Riepilogo Mensile")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Category breakdown
            VStack(spacing: 12) {
                summaryRow(title: String(localized: "Pranzo"), value: recap.totalLunchSales, color: .orange)
                
                // Only display if there are lunch customers
                if recap.totalLunchCustomers > 0 {
                    customerInsightRow(count: recap.totalLunchCustomers, avgSpend: recap.averageLunchSpend)
                }
                
                summaryRow(title: String(localized: "Cena"), value: recap.totalDinnerSales, color: .indigo)
                
                Divider()
                
                summaryRow(title: String(localized: "Lettura Cassa"), value: recap.totalLetturaCassa, color: .blue)
                summaryRow(title: String(localized: "Fatture"), value: recap.totalFatture, color: .blue)
                summaryRow(title: String(localized: "Totale Shiro"), value: recap.totalShiro, color: .purple, isBold: true)
                
                Divider()
                
                summaryRow(title: String(localized: "Yami Lordo"), value: recap.totalYami, color: .orange)
                summaryRow(title: String(localized: "Yami Pulito"), value: recap.totalYamiPulito, color: .orange.opacity(0.7))
                summaryRow(title: String(localized: "Yami Netto"), value: recap.netYami, color: .orange, isBold: true)
                
                Divider()
                
                summaryRow(title: String(localized: "Bento"), value: recap.totalBento, color: .green)
                summaryRow(title: String(localized: "Cocai"), value: recap.totalCocai, color: .indigo)
                
                Divider()
                
                summaryRow(title: String(localized: "Totale netto"), value: recap.totalSales, color: .green, isBold: true)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func summaryRow(title: String, value: Double, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isBold ? .headline : .subheadline)
                .fontWeight(isBold ? .bold : .regular)
            
            Spacer()
            
            Text(value, format: .currency(code: "EUR"))
                .font(isBold ? .headline : .subheadline)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundColor(color)
        }
    }
    
    private func customerInsightRow(count: Int, avgSpend: Double?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.teal)
                        .font(.caption)
                    
                    Text("Persone: \(count)")
                        .font(.caption)
                }
                
                if let avgSpend = avgSpend {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.teal)
                            .font(.caption)
                        
                        Text("Media: \(avgSpend, format: .currency(code: "EUR"))")
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(Color.teal.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Helper Methods
    
    private var monthName: String {
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
    
    private var daysInMonth: [Int] {
        guard let date = dateForMonth() else { return [] }
        
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numberOfDays = range.count
        
        // Get the first day of the month
        let firstDayComponents = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: firstDayComponents)!
        
        // Get the weekday of the first day (1-7, where 1 is Sunday)
        var weekday = calendar.component(.weekday, from: firstDay) - 2 // Convert to 0-6, where 0 is Monday
        if weekday < 0 { weekday += 7 } // Adjust if it's Sunday
        
        // Create array with empty spaces for days from previous month
        var days: [Int] = []
        // Add placeholders with negative values to ensure unique IDs
        for i in 0..<weekday {
            days.append(-(i+1))
        }
        // Add the days of the current month
        days.append(contentsOf: 1...numberOfDays)
        
        return days
    }
    
    private func dateForMonth() -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        return Calendar.current.date(from: components)
    }
    
    private func dateForDay(_ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        return Calendar.current.date(from: components)!
    }
    
    private func salesForDay(_ day: Int) -> DailySales? {
        guard let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        
        let dateString = DateHelper.formatDate(date)
        return monthlyRecap?.days.first { $0.dateString == dateString }
    }
    
    private func isToday(day: Int) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        return calendar.component(.year, from: today) == year &&
               calendar.component(.month, from: today) == month &&
               calendar.component(.day, from: today) == day
    }
    
    private func hasSales(day: Int) -> Bool {
        return salesForDay(day)?.totalSales ?? 0 > 0
    }
    
    private func backgroundForDay(_ day: Int) -> Color {
        if isToday(day: day) {
            return Color.blue.opacity(0.1)
        } else if hasSales(day: day) {
            return Color.green.opacity(0.05)
        } else {
            return Color(UIColor.systemBackground)
        }
    }
    
    private func strokeForDay(_ day: Int) -> Color {
        if isToday(day: day) {
            return Color.blue
        } else if hasSales(day: day) {
            return Color.green.opacity(0.5)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private func updateMonthlyRecap() {
        guard let salesStore = env.salesStore else { return }
        DispatchQueue.main.async {
            self.monthlyRecap = salesStore.getMonthlyRecap(year: self.year, month: self.month)
        }
    }
    
    // Export to Excel function
    private func exportToExcel() {
        guard let recap = monthlyRecap, let fileURL = exportService.exportMonthlySales(recap) else {
            return
        }
        
        // Access UIViewController to present share sheet
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        rootVC.presentShareSheet(url: fileURL)
    }
}
