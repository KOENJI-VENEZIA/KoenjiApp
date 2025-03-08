import SwiftUI
import OSLog

struct WebReservationsTab: View {
    @EnvironmentObject var env: AppDependencies
    @State private var searchText = ""
    @State private var selectedReservation: Reservation?
    @State private var refreshID = UUID()
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    @Environment(\.dismiss) var dismiss
    
    private let logger = Logger(subsystem: "com.koenjiapp", category: "WebReservationsTab")
    
    // Initialize with columnVisibility binding
    init(columnVisibility: Binding<NavigationSplitViewVisibility> = .constant(.automatic)) {
        self._columnVisibility = columnVisibility
    }
    
    // Filter web reservations
    private var webReservations: [Reservation] {
        let allReservations = env.store.reservations.filter {
            $0.isWebReservation && $0.acceptance == .toConfirm
        }
        
        if searchText.isEmpty {
            return allReservations
        } else {
            return allReservations.filter { reservation in
                reservation.name.localizedCaseInsensitiveContains(searchText) ||
                reservation.phone.localizedCaseInsensitiveContains(searchText) ||
                (reservation.emailAddress?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
            ZStack {
                if webReservations.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Web Reservations")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name, phone, or email")
            .refreshable {
                refreshID = UUID()
            }
            .sheet(item: $selectedReservation) { reservation in
                WebReservationApprovalView(
                    reservation: reservation,
                    onApprove: {
                        // Callback when reservation is approved
                        refreshID = UUID()
                        dismiss()
                    },
                    onDecline: {
                        // Callback when reservation is declined
                        refreshID = UUID()
                        dismiss()
                    }
                )
                .environmentObject(env)
            }
            .onReceive(NotificationManager.shared.$selectedReservationID) { id in
                if let id = id,
                   let reservation = env.store.reservations.first(where: { $0.id == id && $0.isWebReservation }) {
                    selectedReservation = reservation
                }
            }
            .onAppear {
                // Make sure the detail view is visible when this view appears
                columnVisibility = .detailOnly
            }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe.desk")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            Text("No Web Reservations")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Online reservation requests will appear here for approval.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // Reservation list view
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(webReservations) { reservation in
                    WebReservationCard(reservation: reservation)
                        .onTapGesture {
                            selectedReservation = reservation
                        }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .id(refreshID) // Force refresh when needed
        }
    }
}

#Preview {
    WebReservationsTab(columnVisibility: .constant(.automatic))
        .environmentObject(AppDependencies.createPreviewInstance())
}
