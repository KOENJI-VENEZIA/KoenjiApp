import SwiftUI

struct YearlySalesView: View {
    @EnvironmentObject var env: AppDependencies
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    let year: Int
    
    @State private var yearlyRecap: YearlySalesRecap?
    @State private var showAuthView = false
        
    private let months = [
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Year header
                headerSection
                
                // Monthly breakdown
                monthlyBreakdownSection
                
                // Annual summary
                if let recap = yearlyRecap {
                    // Only show summary if authorized
                    if env.salesStore.isAuthorized == true {
                        annualSummarySection(recap: recap)
                    } else {
                        // Show auth required message
                        authRequiredSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Vendite \(String(year))")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
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
        }
        .onAppear {
            updateYearlyRecap()
        }
        .onChange(of: env.salesStore.allSales) {
            updateYearlyRecap()
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
            Text("Riepilogo \(String(year))")
                .font(.title)
                .fontWeight(.bold)
            
            if let recap = yearlyRecap, env.salesStore.isAuthorized == true {
                Text("Totale annuale netto: \(recap.totalSales, format: .currency(code: "EUR"))")
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
    
    private var monthlyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vendite Mensili")
                .font(.headline)
                .padding(.bottom, 4)
            
            VStack(spacing: 8) {
                // Header row
                HStack {
                    Text("Mese")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 100, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Pranzo")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("Cena")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("Totale")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .trailing)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                
                Divider()
                
                // Month rows
                if let recap = yearlyRecap {
                    ForEach(0..<12) { index in
                        let monthRecap = recap.monthlyRecaps[index]
                        NavigationLink(destination: MonthlySalesView(year: year, month: index + 1)) {
                            monthRow(month: months[index], recap: monthRecap)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id("yearly-month-\(year)-\(index+1)") // Ensure unique ID
                        
                        if index < 11 {
                            Divider()
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func monthRow(month: String, recap: MonthlySalesRecap) -> some View {
        HStack {
            Text(month)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.primary)
            
            Spacer()
            
            if env.salesStore.isAuthorized == true {
                Text(recap.totalLunchSales, format: .currency(code: "EUR"))
                    .font(.subheadline)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(.orange)
                
                Text(recap.totalDinnerSales, format: .currency(code: "EUR"))
                    .font(.subheadline)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(.indigo)
                
                Text(recap.totalSales, format: .currency(code: "EUR"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(.green)
            } else {
                // Show lock icon if not authorized
                Text("")
                    .frame(width: 80, alignment: .trailing)
                
                Text("")
                    .frame(width: 80, alignment: .trailing)
                
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .frame(width: 80, alignment: .trailing)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
    
    private func annualSummarySection(recap: YearlySalesRecap) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Riepilogo Annuale")
                .font(.headline)
                .padding(.bottom, 4)
            
            // Main category breakdown
            VStack(spacing: 12) {
                summaryRow(title: String(localized: "Pranzo"), value: recap.totalLunchSales, color: .orange)
                                
                // Only display if there are lunch customers
                if recap.totalLunchCustomers > 0 {
                    customerInsightRow(count: recap.totalLunchCustomers, avgSpend: recap.averageLunchSpend)
                }
                                
                summaryRow(title: String(localized: "Cena"), value: recap.totalDinnerSales, color: .indigo)
                                
                Divider()
                                
                summaryRow(title: String(localized: "Lettura Cassa"), value: recap.totalLetturaCassa, color: .purple)
                summaryRow(title: String(localized: "Fatture"), value: recap.totalFatture, color: .purple)
                summaryRow(title: String(localized: "Totale Shiro"), value: recap.totalShiro, color: .purple, isBold: true)
                                
                Divider()
                                
                summaryRow(title: String(localized: "Yami Lordo"), value: recap.totalYami, color: .orange)
                summaryRow(title: String(localized: "Yami Pulito"), value: recap.totalYamiPulito, color: .orange.opacity(0.7))
                summaryRow(title: String(localized: "Yami Netto"), value: recap.netYami, color: .orange, isBold: true)
                                
                Divider()
                                
                summaryRow(title: String(localized: "Bento"), value: recap.totalBento, color: .green)
                summaryRow(title: String(localized: "Cocai"), value: recap.totalCocai, color: .indigo)
                                
                Divider()
                                
                summaryRow(title: String(localized: "Totale Annuale"), value: recap.totalSales, color: .green, isBold: true)
                
                // Average monthly sales
                let avgMonthlySales = recap.totalSales / 12
                Text("Media mensile: \(avgMonthlySales, format: .currency(code: "EUR"))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
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
    
    private func updateYearlyRecap() {
        let salesStore = env.salesStore
        DispatchQueue.main.async {
            self.yearlyRecap = salesStore.getYearlyRecap(year: self.year)
        }
    }
}
