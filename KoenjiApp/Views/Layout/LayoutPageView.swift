import SwiftUI

struct LayoutPageView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData

    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme

    @Namespace private var animationNamespace

    // Each LayoutPageView has its own LayoutUIManager
    @StateObject private var layoutUI = LayoutUIManager()

    // Layout configuration flag
    @State private var isConfigured = false

    // Filters
    var selectedDate: Date
    var selectedCategory: Reservation.ReservationCategory

    // Time
    @Binding var currentTime: Date
    @Binding var isManuallyOverridden: Bool
    @Binding var showingTimePickerSheet: Bool

    // Reservation editing
    @Binding var selectedReservation: Reservation?
    @Binding var showingEditReservation: Bool

    // Add Reservation
    @Binding var showingAddReservationSheet: Bool
    @Binding var tableForNewReservation: TableModel?

    // Alerts and locks
    @Binding var showingNoBookingAlert: Bool
    @Binding var isLayoutLocked: Bool
    @Binding var isZoomLocked: Bool

    // Zoom and pan state
    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    var body: some View {
        GeometryReader { parentGeometry in
            let viewportWidth = parentGeometry.size.width
            let viewportHeight = parentGeometry.size.height

            let gridWidth = CGFloat(store.totalColumns) * 40
            let gridHeight = CGFloat(store.totalRows) * 40

            Color(hex: "#C8CBEA").edgesIgnoringSafeArea([.all])

            ZoomableScrollView(scale: $scale) {
                ZStack {
                    Color(hex: "#C8CBEA")

                    Rectangle()
                        .frame(width: gridWidth, height: gridHeight)
                        .background(Color.grid_background)
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(width: gridWidth, height: gridHeight)
                        .background(Color.grid_background)
                    gridData.gridBackground
                        .frame(width: gridWidth, height: gridHeight)
                        .background(Color.grid_background)

                    ForEach(layoutUI.tables, id: \.id) { table in
                        TableView(
                            table: table,
                            selectedDate: selectedDate,
                            selectedCategory: selectedCategory,
                            currentTime: currentTime,
                            layoutUI: layoutUI,
                            showingNoBookingAlert: $showingNoBookingAlert,
                            onTapEmpty: { handleEmptyTableTap(for: table) },
                            onEditReservation: { reservation in
                                selectedReservation = reservation
                                showingEditReservation = true
                            },
                            isLayoutLocked: isLayoutLocked,
                            animationNamespace: animationNamespace
                        )
                        .environmentObject(store)
                        .environmentObject(reservationService)
                        .environmentObject(gridData)
                        .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
                    }
                }
                .frame(width: gridWidth, height: gridHeight)
                .compositingGroup()
                .background(Color(hex: "#C8CBEA"))
                .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
            }
            .onAppear {
                if !isConfigured {
                    let gridWidth = CGFloat(store.totalColumns) * 40
                    let gridHeight = CGFloat(store.totalRows) * 40
                    let gridBounds = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)

                    layoutUI.configure(store: store, reservationService: reservationService)
                    gridData.configure(store: store, gridBounds: gridBounds)

                    print("LayoutPageView sees store ID:", ObjectIdentifier(store))
                    print("store.reservations after load: \(store.reservations)")
                    isConfigured = true
                }
                layoutUI.tables = store.tables // Initial sync
                if layoutUI.tables.isEmpty {
                    reservationService.layoutManager.loadLayout(for: selectedDate, category: selectedCategory, reset: false)
                    layoutUI.tables = store.tables
                }
            }
            .background(Color(hex: "#C8CBEA"))
            .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
        }
    }

    // Handle tapping an empty table to add a reservation
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }
}
