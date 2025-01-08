//
//  LayoutPageView.swift
//  KoenjiApp
//
//  Refactored to maintain separate layouts per date and category.
//

import SwiftUI

struct LayoutPageView: View {
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var gridData: GridData

    @Environment(\.locale) var locale
    @Environment(\.colorScheme) var colorScheme

    @Namespace private var animationNamespace

    // Each LayoutPageView has its own LayoutUIManager
    @StateObject private var layoutUI: LayoutUIManager

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
    @Binding var isLayoutReset: Bool

    // Zoom and pan state
    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    // Initialize LayoutUIManager with date and category
    init(selectedDate: Date,
         selectedCategory: Reservation.ReservationCategory,
         currentTime: Binding<Date>,
         isManuallyOverridden: Binding<Bool>,
         showingTimePickerSheet: Binding<Bool>,
         selectedReservation: Binding<Reservation?>,
         showingEditReservation: Binding<Bool>,
         showingAddReservationSheet: Binding<Bool>,
         tableForNewReservation: Binding<TableModel?>,
         showingNoBookingAlert: Binding<Bool>,
         isLayoutLocked: Binding<Bool>,
         isLayoutReset: Binding<Bool>,
         scale: Binding<CGFloat>,
         offset: Binding<CGSize>) {
        
        self.selectedDate = selectedDate
        self.selectedCategory = selectedCategory
        self._currentTime = currentTime
        self._isManuallyOverridden = isManuallyOverridden
        self._showingTimePickerSheet = showingTimePickerSheet
        self._selectedReservation = selectedReservation
        self._showingEditReservation = showingEditReservation
        self._showingAddReservationSheet = showingAddReservationSheet
        self._tableForNewReservation = tableForNewReservation
        self._showingNoBookingAlert = showingNoBookingAlert
        self._isLayoutLocked = isLayoutLocked
        self._isLayoutReset = isLayoutReset
        self._scale = scale
        self._offset = offset
        
        // Initialize LayoutUIManager with date and category
        _layoutUI = StateObject(wrappedValue: LayoutUIManager(date: selectedDate, category: selectedCategory))
    }

    var body: some View {
        GeometryReader { parentGeometry in
            let viewportWidth = parentGeometry.size.width
            let viewportHeight = parentGeometry.size.height

            let gridWidth = CGFloat(store.totalColumns) * layoutUI.cellSize
            let gridHeight = CGFloat(store.totalRows) * layoutUI.cellSize

            Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA")).edgesIgnoringSafeArea([.all])

            ZoomableScrollView(scale: $scale) {
                
                VStack {
                    Text("\(dayOfWeek(for: selectedDate)), \(DateHelper.fullDateFormatter.string(from: selectedDate)) (\(selectedCategory.rawValue)) - \(DateHelper.timeFormatter.string(from: currentTime))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(selectedCategory == .lunch ? Color.title_color_lunch : Color.title_color_dinner)
                        .padding(.top, 16)
                        .background(Color.clear) // Slightly opaque background for better visibility
                        .padding(.horizontal, 16)

                }
                
                
                ZStack {
                    Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA"))

                    
                    Rectangle()
                        .frame(width: gridWidth, height: gridHeight)
                        .background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(width: gridWidth, height: gridHeight)
                        .background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)
                    gridData.gridBackground(selectedCategory: selectedCategory)
                        .frame(width: gridWidth, height: gridHeight)
                        .background(selectedCategory == .lunch ? Color.grid_background_lunch : Color.grid_background_dinner)

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
                            isLayoutReset: $isLayoutReset,
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
                .background(Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA")))
                .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
                

            }
            .onAppear {
                if !layoutUI.isConfigured {
                    layoutUI.configure(store: store, reservationService: reservationService)
                    print("LayoutPageView sees store ID:", ObjectIdentifier(store))
                    print("store.reservations after load: \(store.reservations)")
                }
                
                layoutUI.tables = store.loadTables(for: selectedDate, category: selectedCategory)

                // Update isLayoutReset for the parent view


            }

            .onChange(of: isLayoutReset) { reset in
                if reset {
                    // Reset tables and update layoutUI.tables
                    let key = store.keyFor(date: selectedDate, category: selectedCategory)
                    if let baseTables = store.cachedLayouts[key] {
                        layoutUI.tables = baseTables
                        print("Reset layout for \(key) and updated layoutUI.tables.")
                    }
                }
                

            }
            .onChange(of: selectedCategory) { newCategory in
                // Save the current layout before switching
                

                
                    // Load tables for the new category and date
                    layoutUI.tables = store.loadTables(for: selectedDate, category: newCategory)
                    print("Tables reloaded for \(newCategory.rawValue) on \(selectedDate)")

            }
            .onDisappear {
                // Save layout when the view disappears
            }
            .alert(isPresented: $layoutUI.showAlert) {
                Alert(
                    title: Text("Posizionamento non valido"),
                    message: Text(layoutUI.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .background(Color(hex: (selectedCategory == .lunch ? "#D4C58A" : "#C8CBEA")))
            .animation(.spring(duration: 0.3, bounce: 0.0), value: viewportWidth)
        }
    }

    // Handle tapping an empty table to add a reservation
    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        formatter.locale = locale
        return formatter.string(from: date)
    }
    
    
    private func updateLayoutResetState() {
        isLayoutReset = (layoutUI.tables == store.baseTables)
    }
}

