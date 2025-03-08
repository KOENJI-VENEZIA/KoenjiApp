import SwiftUI
import OSLog

struct DailySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    
    private let logger = Logger(subsystem: "com.koenjiapp", category: "DailySalesView")
    
    @State private var dailySales: DailySales
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    @State private var selectedDate: Date
    
    @State private var showDatePicker = false
    
    init(date: Date, existingSales: DailySales? = nil) {
        _selectedDate = State(initialValue: date)
        
        if let existingSales = existingSales {
            _dailySales = State(initialValue: existingSales)
        } else {
            _dailySales = State(initialValue: DailySales.createEmpty(for: date))
        }
    }
    
    var body: some View {
        Form {
            // Date header
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(DateHelper.formatFullDate(selectedDate))
                                    .font(.headline)
                                Text(DateHelper.dayOfWeek(for: selectedDate))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button {
                                showDatePicker.toggle()
                            } label: {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text(String(format: "€ %.2f", dailySales.totalSales))
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
                    
                if showDatePicker {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) { old, newDate in
                            updateDailySales(for: newDate)
                        }
                }
            }
                
            // Lunch Section
            salesCategorySection(
                category: .lunch,
                sales: $dailySales.lunch,
                showBento: true,
                showCocai: false,
                showPersone: true
            )
            
            // Lunch Insights (if we have customer data)
            if let averageSpend = dailySales.averageLunchSpend, dailySales.lunch.persone ?? 0 > 0 {
                Section {
                    HStack {
                        Label {
                            Text("Spesa media a persona")
                                .font(.callout)
                        } icon: {
                            Image(systemName: "person.text.rectangle")
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "€ %.2f", averageSpend))
                            .font(.callout.bold())
                            .foregroundColor(.orange)
                    }
                }
                .listRowBackground(Color.orange.opacity(0.05))
            }
            
            // Dinner Section
            salesCategorySection(
                category: .dinner,
                sales: Binding(
                    get: { dailySales.dinner },
                    set: { dailySales.dinner = $0 }
                ),
                showBento: false,
                showCocai: true,
                showPersone: false
            )
        }
        .navigationTitle("Vendite Giornaliere")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Annulla") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveSalesData()
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Salva")
                            .fontWeight(.bold)
                    }
                }
                .disabled(isLoading)
            }
        }
        .alert("Dati salvati", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("I dati di vendita sono stati salvati con successo.")
        }
        .alert("Errore", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    
    private func salesCategorySection(
        category: SaleCategory.CategoryType,
        sales: Binding<SaleCategory>,
        showBento: Bool,
        showCocai: Bool,
        showPersone: Bool
    ) -> some View {
        // Create direct bindings to the dailySales property to ensure persistence
        let letturaCassaBinding = Binding<Double>(
            get: { category == .lunch ? self.dailySales.lunch.letturaCassa : self.dailySales.dinner.letturaCassa },
            set: {
                if category == .lunch {
                    self.dailySales.lunch.letturaCassa = $0
                } else {
                    self.dailySales.dinner.letturaCassa = $0
                }
            }
        )
        
        let fattureBinding = Binding<Double>(
            get: { category == .lunch ? self.dailySales.lunch.fatture : self.dailySales.dinner.fatture },
            set: {
                if category == .lunch {
                    self.dailySales.lunch.fatture = $0
                } else {
                    self.dailySales.dinner.fatture = $0
                }
            }
        )
        
        let yamiBinding = Binding<Double>(
            get: { category == .lunch ? self.dailySales.lunch.yami : self.dailySales.dinner.yami },
            set: {
                if category == .lunch {
                    self.dailySales.lunch.yami = $0
                } else {
                    self.dailySales.dinner.yami = $0
                }
            }
        )
        
        // New binding for Yami Pulito
        let yamiPulitoBinding = Binding<Double>(
            get: { category == .lunch ? self.dailySales.lunch.yamiPulito : self.dailySales.dinner.yamiPulito },
            set: {
                if category == .lunch {
                    self.dailySales.lunch.yamiPulito = $0
                } else {
                    self.dailySales.dinner.yamiPulito = $0
                }
            }
        )
        
        let bentoBinding = Binding<Double>(
            get: { self.dailySales.lunch.bento ?? 0 },
            set: { self.dailySales.lunch.bento = $0 }
        )
        
        let cocaiBinding = Binding<Double>(
            get: { self.dailySales.dinner.cocai ?? 0 },
            set: { self.dailySales.dinner.cocai = $0 }
        )
        
        // New binding for Persone (customer count)
        let personeBinding = Binding<Int>(
            get: { self.dailySales.lunch.persone ?? 0 },
            set: { self.dailySales.lunch.persone = $0 }
        )
        
        return Section {
            Label {
                Text(category.localized)
                    .font(.headline)
            } icon: {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
            }
            
            VStack(spacing: 16) {
                CurrencyField(
                    title: String(localized: "Lettura cassa"),
                    value: letturaCassaBinding,
                    icon: "eurosign.circle.fill",
                    color: .blue
                )
                
                CurrencyField(
                    title: String(localized: "Fatture"),
                    value: fattureBinding,
                    icon: "doc.text.fill",
                    color: .purple
                )
                
                CurrencyField(
                    title: String(localized: "Yami"),
                    value: yamiBinding,
                    icon: "creditcard.fill",
                    color: .orange
                )
                
                CurrencyField(
                    title: String(localized: "Yami Pulito"),
                    value: yamiPulitoBinding,
                    icon: "creditcard.circle.fill",
                    color: .orange
                )
                
                TotalField(
                    title: String(localized: "Totale Shiro"),
                    value: category == .lunch ? dailySales.lunch.totalShiro : dailySales.dinner.totalShiro,
                    icon: "sum",
                    color: .green
                )
                
                if showBento {
                    CurrencyField(
                        title: String(localized: "Bento"),
                        value: bentoBinding,
                        icon: "takeoutbag.and.cup.and.straw.fill",
                        color: .indigo
                    )
                }
                
                if showCocai {
                    CurrencyField(
                        title: String(localized: "Cocai"),
                        value: cocaiBinding,
                        icon: "bag.fill",
                        color: .indigo
                    )
                }
                
                if showPersone {
                    IntegerField(
                        title: String(localized: "Persone"),
                        value: personeBinding,
                        icon: "person.2.fill",
                        color: .teal
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(category.color.opacity(0.05))
    }
    
    private func saveSalesData() {
        isLoading = true
        
        let salesService = env.salesService
        
        salesService.saveDailySales(dailySales) { error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Errore durante il salvataggio: \(error.localizedDescription)"
                } else {
                    showSuccessAlert = true
                }
            }
        }
    }
    
    private func updateDailySales(for date: Date) {
        let existingSales = env.salesStore.getSalesForDay(date: date)
            // Use existing sales data if we have it
            dailySales = existingSales
        
        
        // Hide the date picker after selection
        showDatePicker = false
    }
}

// Custom field components for the form
struct CurrencyField: View {
    let title: String
    @Binding var value: Double
    let icon: String
    let color: Color
    
    @State private var stringValue: String = ""
    
    init(title: String, value: Binding<Double>, icon: String, color: Color) {
        self.title = title
        self._value = value
        self.icon = icon
        self.color = color
        
        // Initialize string value from the double
        self._stringValue = State(initialValue: String(format: "%.2f", value.wrappedValue))
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.callout)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            TextField("0,00", text: $stringValue)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .onChange(of: stringValue) { old, newValue in
                    // Convert string to double when the text changes
                    let sanitized = newValue.replacingOccurrences(of: ",", with: ".")
                    if let doubleValue = Double(sanitized) {
                        value = doubleValue
                    }
                }
                .onChange(of: value) { old, newValue in
                    // Keep stringValue in sync with the actual value
                    if Double(stringValue.replacingOccurrences(of: ",", with: ".")) != newValue {
                        stringValue = String(format: "%.2f", newValue)
                    }
                }
                .onAppear {
                    // Ensure we have the latest value when the view appears
                    stringValue = String(format: "%.2f", value)
                }
        }
    }
}

// New component for integer fields
struct IntegerField: View {
    let title: String
    @Binding var value: Int
    let icon: String
    let color: Color
    
    @State private var stringValue: String = ""
    
    init(title: String, value: Binding<Int>, icon: String, color: Color) {
        self.title = title
        self._value = value
        self.icon = icon
        self.color = color
        
        // Initialize string value from the integer
        self._stringValue = State(initialValue: String(value.wrappedValue))
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.callout)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            TextField("0", text: $stringValue)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .onChange(of: stringValue) { old, newValue in
                    // Convert string to integer when the text changes
                    if let intValue = Int(newValue) {
                        value = intValue
                    }
                }
                .onChange(of: value) { old, newValue in
                    // Keep stringValue in sync with the actual value
                    if Int(stringValue) != newValue {
                        stringValue = String(newValue)
                    }
                }
                .onAppear {
                    // Ensure we have the latest value when the view appears
                    stringValue = String(value)
                }
        }
    }
}

struct TotalField: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.callout.bold())
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(value, format: .currency(code: "EUR"))
                .fontWeight(.bold)
        }
    }
}

#Preview {
    DailySalesView(date: Date())
        .environmentObject(AppDependencies())
}
