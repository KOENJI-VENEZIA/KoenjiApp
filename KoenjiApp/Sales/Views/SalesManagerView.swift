import SwiftUI

struct SalesManagerView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var availableYears: [Int] = []
    @State private var selectedDate: Date?
    @State private var showingDailyView = false
    @State private var showAuthView = false
    @State private var sheetContentReady = false
    @State private var showYearSelector = false // New state for year selection
    @State private var showConfirmationDialog = false // For delete confirmations
    @State private var itemToDelete: DeletionItem? // Track what's being deleted
    
    @Binding private var columnVisibility: NavigationSplitViewVisibility
    // Enum to track what type of item is being deleted
    enum DeletionItem {
        case year(Int)
        case month(Int, Int) // year, month
    }
    
    // Initialize with columnVisibility binding
    init(columnVisibility: Binding<NavigationSplitViewVisibility> = .constant(.automatic)) {
        self._columnVisibility = columnVisibility
    }

    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with quick actions
                        headerView
                        
                        // Year selector with navigation
                        yearSelectorView
                        
                        // Monthly quick navigation
                        monthlyNavigationView
                        
                        // Recent entries
                        recentEntriesView
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
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
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle("Gestione Vendite")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        if env.salesStore.isAuthorized == true {
                            // If already authorized, log out
                            env.salesStore.logout()
                        } else {
                            // Show auth dialog
                            showAuthView = true
                        }
                    } label: {
                        Label(
                            env.salesStore.isAuthorized == true ? "Logout" : "Login",
                            systemImage: env.salesStore.isAuthorized == true ? "lock.open.fill" : "lock.fill"
                        )
                    }
                    
                    Button {
                        prepareDailyView(for: Date())
                    } label: {
                        Label("Aggiungi Oggi", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .confirmationDialog("Conferma Eliminazione", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
                    if let itemToDelete = itemToDelete {
                        switch itemToDelete {
                        case .year(let year):
                            Button("Elimina Anno \(String(year))", role: .destructive) {
                                deleteYear(year)
                            }
                        case .month(let year, let month):
                            Button("Elimina Mese \(monthName(for: month)) \(String(year))", role: .destructive) {
                                deleteMonth(year: year, month: month)
                            }
                        }
                    }
                }
        .sheet(isPresented: $showYearSelector) {
                    NavigationStack {
                        YearSelectionView(
                            availableYears: availableYears,
                            selectedYear: $selectedYear,
                            isPresented: $showYearSelector
                        )
                        .environmentObject(env)
                    }
                }
        .sheet(isPresented: $showingDailyView, onDismiss: {
            // Reset the flag when dismissed
            sheetContentReady = false
        }) {
            if let selectedDate = selectedDate {
                NavigationStack {
                    ZStack {
                        // Always show a loading state first
                        VStack {
                            Spacer()
                            ProgressView("Caricamento...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                        
                        // Actual content with opacity animation
                        DailySalesView(
                            date: selectedDate,
                            existingSales: env.salesStore.getSalesForDay(date: selectedDate)
                        )
                        .environmentObject(env)
                        .opacity(sheetContentReady ? 1 : 0)
                        .animation(.easeIn(duration: 0.3), value: sheetContentReady)
                    }
                    .onAppear {
                        // Add a slight delay before showing content
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            sheetContentReady = true
                        }
                    }
                }
            }
        }
        .onAppear {
            columnVisibility = .detailOnly
            
            updateAvailableYears()
            
            // Ensure the Firebase listener is active
            Task {
               await env.salesService.startSalesListener()
            }
        }
        .onChange(of: env.salesStore.allSales) {
            updateAvailableYears()
            
        }
    }
    
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Title and current date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vendite")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(formattedCurrentDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Authorization status indicator
                if env.salesStore.isAuthorized {
                    Label("Autorizzato", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    Label("Non autorizzato", systemImage: "exclamationmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                        .onTapGesture {
                            showAuthView = true
                        }
                }
                
                // Add today button for quick access
                Button {
                    prepareDailyView(for: Date())
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Oggi")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            
            // Quick action buttons
            HStack(spacing: 12) {
                quickActionButton(
                    title: String(localized: "Vendite Giornaliere"),
                    icon: "calendar.day.timeline.leading",
                    color: .orange
                ) {
                    prepareDailyView(for: Date())
                }
                
                let currentYear = Calendar.current.component(.year, from: Date())

                let currentMonth = Calendar.current.component(.month, from: Date())

            
                NavigationLink(destination: MonthlySalesView(year: currentYear, month: currentMonth)) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.headline)
                        
                        Text("Mese Corrente")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: YearlySalesView(year: currentYear)) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.headline)
                        
                        Text("Anno Corrente")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var yearSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seleziona Anno")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableYears, id: \.self) { year in
                        NavigationLink(destination: YearlySalesView(year: year)) {
                            VStack(spacing: 8) {
                                Text(String(year))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Riepilogo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 120, height: 80)
                            .background(year == selectedYear ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
                            .foregroundColor(year == selectedYear ? .blue : .primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(year == selectedYear ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contextMenu {
                                if env.salesStore.isAuthorized == true && availableYears.count > 1 {
                                    Button(role: .destructive) {
                                        itemToDelete = .year(year)
                                        showConfirmationDialog = true
                                    } label: {
                                        Label("Elimina Anno", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id("year-\(year)") // Ensure unique ID
                        // Hide total values if not authorized
                        .opacity(env.salesStore.isAuthorized == true ? 1.0 : 0.5)
                        .disabled(env.salesStore.isAuthorized != true)
                        .overlay(
                            Group {
                                if env.salesStore.isAuthorized != true {
                                    Button {
                                        showAuthView = true
                                    } label: {
                                        VStack {
                                            Image(systemName: "lock.fill")
                                                .font(.body)
                                            Text("Login")
                                                .font(.caption2)
                                        }
                                        .padding(8)
                                        .background(Color(.systemBackground).opacity(0.9))
                                        .clipShape(Circle())
                                    }
                                }
                            }
                        )
                    }
                    
                    // Add new year button
                    Button {
                        addNewYear()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            
                            Text("Nuovo Anno")
                                .font(.caption)
                        }
                        .frame(width: 120, height: 80)
                        .background(Color(UIColor.systemBackground))
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                .opacity(0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var monthlyNavigationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mesi \(String(selectedYear))")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showYearSelector = true
                } label: {
                    Text("Cambia Anno")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<12) { index in
                    let monthNames = [
                        String(localized: "Gennaio"), String(localized: "Febbraio"), String(localized: "Marzo"), String(localized: "Aprile"), String(localized: "Maggio"), String(localized: "Giugno"),
                        String(localized: "Luglio"), String(localized: "Agosto"), String(localized: "Settembre"), String(localized: "Ottobre"), String(localized: "Novembre"), String(localized: "Dicembre")
                    ]
                    
                    NavigationLink(destination: MonthlySalesView(year: selectedYear, month: index + 1)) {
                        VStack(spacing: 4) {
                            Text(monthNames[index])
                                .font(.callout)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            if let monthlySales = getMonthlySalesTotal(month: index + 1), env.salesStore.isAuthorized == true {
                                Text("\(Int(monthlySales))€")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text(env.salesStore.isAuthorized == true ? "Nessun dato" : "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contextMenu {
                            if env.salesStore.isAuthorized == true {
                                Button(role: .destructive) {
                                    itemToDelete = .month(selectedYear, index + 1)
                                    showConfirmationDialog = true
                                } label: {
                                    Label("Elimina Mese", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .id("month-\(selectedYear)-\(index+1)") // Ensure unique ID
                    // Hide total values if not authorized
                    .overlay(
                        Group {
                            if env.salesStore.isAuthorized != true {
                                Button {
                                    showAuthView = true
                                } label: {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color(.systemBackground).opacity(0.7))
                                        .clipShape(Circle())
                                }
                                .offset(x: -8, y: -8)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var recentEntriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inserimenti Recenti")
                .font(.headline)
            
            if let recentSales = getRecentSales(), !recentSales.isEmpty {
                ForEach(recentSales) { sale in
                    Button {
                        selectedDate = sale.normalizedDate
                        showingDailyView = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(DateHelper.formatFullDate(sale.normalizedDate ?? Date()))
                                    .font(.callout)
                                    .fontWeight(.medium)
                                
                                Text(DateHelper.dayOfWeek(for: sale.normalizedDate ?? Date()))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                if env.salesStore.isAuthorized == true {
                                    categoryValue(title: "Pranzo", value: getLunchTotal(sale), color: .orange)
                                    categoryValue(title: "Cena", value: getDinnerTotal(sale), color: .indigo)
                                    categoryValue(title: "Totale", value: sale.totalSales, color: .green)

                                
                                } else {
                                    Text("Modifica")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let index = recentSales.firstIndex(of: sale), index < recentSales.count - 1 {
                        Divider()
                            .padding(.leading, 8)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Nessun dato recente")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        prepareDailyView(for: Date())
                    } label: {
                        Text("Inserisci vendite di oggi")
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helper Methods
    
    private var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: String(localized: "it_IT"))
        return formatter.string(from: Date()).capitalized
    }
    
    private func quickActionButton(title: String, icon: String, color: Color, action: (() -> Void)? = nil) -> some View {
        Button(action: action ?? {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle()) // Add this to prevent button styling conflicts with NavigationLink
    }
    
    private func categoryValue(title: String, value: Double, color: Color, isBold: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            if !isBold {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value, format: .currency(code: "EUR"))
                    .font(.callout)
                    .foregroundColor(color)
            } else {
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
                
                Text(value, format: .currency(code: "EUR"))
                    .font(.callout)
                    .bold()
                    .foregroundColor(color)
            }
        }
    }
    
    private func getLunchTotal(_ sale: DailySales) -> Double {
        return sale.lunch.totalShiro + sale.lunch.yami
    }
    
    private func getDinnerTotal(_ sale: DailySales) -> Double {
        return sale.dinner.totalShiro + sale.dinner.yami
    }
    
    private func getMonthlySalesTotal(month: Int) -> Double? {
        let salesStore = env.salesStore
        
        let monthlyRecap = salesStore.getMonthlyRecap(year: selectedYear, month: month)
        return monthlyRecap.totalSales > 0 ? monthlyRecap.totalSales : nil
    }
    
    private func getRecentSales() -> [DailySales]? {
        let salesStore = env.salesStore
        guard !salesStore.allSales.isEmpty else { return nil }
        
        let sortedSales = salesStore.allSales.sorted {
            $0.lastEditedOn > $1.lastEditedOn
        }
        
        return Array(sortedSales.prefix(5))
    }
    
    private func monthName(for monthNumber: Int) -> String {
        let monthNames = [
            String(localized: "Gennaio"), String(localized: "Febbraio"), String(localized: "Marzo"),
            String(localized: "Aprile"), String(localized: "Maggio"), String(localized: "Giugno"),
            String(localized: "Luglio"), String(localized: "Agosto"), String(localized: "Settembre"),
            String(localized: "Ottobre"), String(localized: "Novembre"), String(localized: "Dicembre")
        ]
            return monthNames[monthNumber - 1]
        }
    
    // Helper methods for deletion and month name
    private func deleteYear(_ year: Int) {
        guard env.salesStore.isAuthorized == true else { return }
        
        // Implement year deletion logic in your sales store
        env.salesStore.deleteYear(year)
        env.salesService.deleteYear(year) { error in
            if let error = error {
               print("Error deleting year in Firebase: \(error)")
           }
        }
        // Update available years
        updateAvailableYears()
    }
    
    private func deleteMonth(year: Int, month: Int) {
        guard env.salesStore.isAuthorized == true else { return }
        
        // Implement month deletion logic in your sales store
        env.salesStore.deleteMonth(year: year, month: month)
        env.salesService.deleteMonth(year: year, month: month) { error in
            if let error = error {
                print("Error deleting month in Firebase: \(error)")
            }
        }
        // Update available years if necessary
        updateAvailableYears()
    }
    
    private func updateAvailableYears() {
        let salesStore = env.salesStore
        
        let years = salesStore.getAvailableYears()
        
        if !years.isEmpty {
            self.availableYears = years
            
            // If current selected year is not in the list, select the most recent
            if !years.contains(selectedYear) {
                self.selectedYear = years.max() ?? Calendar.current.component(.year, from: Date())
            }
        } else {
            // Default to current year if no data
            let currentYear = Calendar.current.component(.year, from: Date())
            self.availableYears = [currentYear]
            self.selectedYear = currentYear
        }
    }
    
    private func addNewYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let nextYear = currentYear + 1
        
        if !availableYears.contains(nextYear) {
            self.selectedYear = nextYear
            if !availableYears.contains(nextYear) {
                self.availableYears.append(nextYear)
                self.availableYears.sort()
            }
        }
    }
    
    private func prepareDailyView(for date: Date) {
        // Reset the sheet content ready flag
        sheetContentReady = false
        
        // Set the selected date
        selectedDate = date
        
        // Pre-fetch the data with adequate time for it to load
        let store = env.salesStore
        _ = store.getSalesForDay(date: date)
        
        
        // Show the sheet with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showingDailyView = true
        }
    }

    
    private func navigateToCurrentMonth() {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Update selected year if needed
        self.selectedYear = currentYear
    }
    
    private func navigateToCurrentYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        self.selectedYear = currentYear
    }
}

// New view for year selection
struct YearSelectionView: View {
    @EnvironmentObject var env: AppDependencies
    var availableYears: [Int]
    @Binding var selectedYear: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        List {
            ForEach(availableYears, id: \.self) { year in
                Button {
                    selectedYear = year
                    isPresented = false
                } label: {
                    HStack {
                        Text(String(year))
                        Spacer()
                        if year == selectedYear {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Seleziona Anno")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Chiudi") {
                    isPresented = false
                }
            }
        }
    }
}
