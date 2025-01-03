import SwiftUI

struct LayoutView: View {
    @StateObject private var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @Environment(\.locale) var locale // Access the current locale
    @Environment(\.horizontalSizeClass) var horizontalSizeClass // Detect compact vs regular size class

    @Namespace private var animationNamespace

    // Use the LayoutViewModel for manual dragging logic + pop-up alerts
    @StateObject private var layoutUI: LayoutUIManager

    init(store: ReservationStore) {
        let viewModel = LayoutUIManager(store: store)
        let gridWidth = CGFloat(store.totalColumns) * 40 // Use your cell size
        let gridHeight = CGFloat(store.totalRows) * 40
        let gridBounds = CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight)
        
        _layoutUI = StateObject(wrappedValue: viewModel)
        _gridData = StateObject(wrappedValue: GridData(store: store, gridBounds: gridBounds))
    }

    // MARK: - Filters
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: Reservation.ReservationCategory? = .lunch

    // MARK: - Time
    @State private var systemTime: Date = Date()
    @State private var currentTime: Date = Date()
    @State private var isManuallyOverridden: Bool = false
    @State private var overrideTimer: Timer? = nil
    @State private var showingTimePickerSheet: Bool = false

    // For tapping a reservation to edit
    @State private var selectedReservation: Reservation? = nil
    @State private var showingEditReservation: Bool = false

    // For "Add Reservation" on a table
    @State private var showingAddReservationSheet: Bool = false
    @State private var tableForNewReservation: TableModel? = nil

    // MARK: - Cell Size (for each grid cell)
    private let cellSize: CGFloat = 40
   
    // MARK: - Zoom and Pan State
    @State private var showingNoBookingAlert: Bool = false
    @State private var isLayoutLocked: Bool = true
    @State private var isZoomLocked: Bool = false
    @State private var showTopControls: Bool = true
    @State private var selectedTableID: Int?


    @GestureState private var isDragging = false
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @GestureState private var magnificationScale: CGFloat = 1.0

    var body: some View {
        let isCompact = horizontalSizeClass == .compact

        
        GeometryReader { parentGeometry in
            let viewportWidth = parentGeometry.size.width
            let viewportHeight = parentGeometry.size.height

            let gridWidth = CGFloat(store.totalColumns) * cellSize
            let gridHeight = CGFloat(store.totalRows) * cellSize
            

            Color(hex: "#C8CBEA").edgesIgnoringSafeArea([.all])

            ZoomableScrollView(scale: $scale) {
                Color(hex: "#C8CBEA").edgesIgnoringSafeArea([.all])

                     ZStack {
                         Color(hex: "#C8CBEA").edgesIgnoringSafeArea([.all])

                         Rectangle()
                             .frame(width: gridWidth, height: gridHeight)
                             .background(Color.grid_background)
                         Rectangle()
                             .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                             .frame(width: gridWidth, height: gridHeight)
                         gridData.gridBackground
                             .frame(width: gridWidth, height: gridHeight)
                             .background(Color.grid_background)

                         ForEach(layoutUI.tables, id: \.id) { table in
                             let rect = layoutUI.calculateTableRect(for: table)
                             TableView(
                                table: table,
                                selectedDate: selectedDate,
                                selectedCategory: selectedCategory ?? .lunch,
                                currentTime: currentTime, // Use selected time
                                layoutUI: layoutUI,
                                showingNoBookingAlert: $showingNoBookingAlert,
                                onTapEmpty: { handleEmptyTableTap(for: table) },
                                onEditReservation: { reservation in
                                    selectedReservation = reservation
                                    showingEditReservation = true},
                                isLayoutLocked: isLayoutLocked,
                                animationNamespace: animationNamespace
                             )
                             .environmentObject(store)
                             .environmentObject(gridData)

                         }
                     }
                     .frame(width: gridWidth, height: gridHeight)
                     .compositingGroup()
            }
            .onAppear {
                print("Viewport: \(viewportWidth)x\(viewportHeight)")
                print("Grid: \(gridWidth)x\(gridHeight)")
                print("Offset: \(offset)")
            }
            .clipped()
        }
        .ignoresSafeArea(.all, edges: .top) // Extend beneath the navigation bar
        .safeAreaInset(edge: .top) { // Insert topControls just below the navigation bar
            if showTopControls {
                topControls
                    .background(
                        // Use Material for the translucent effect
                        Material.ultraThin
                    )
                    .frame(height: isCompact ? 175 : 100)
                    .padding(.vertical, 0) // Remove unintended padding
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: showTopControls)
                    .offset(y: -1) // Fine-tune to remove slight gaps

            }
        }
        .navigationTitle("Layout Tavoli: \(store.formattedDate(date: selectedDate, locale: locale))")
        .navigationBarTitleDisplayModeAlwaysLarge()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    isLayoutLocked.toggle()
                    isZoomLocked.toggle() // Toggle zoom lock state

                }) {
                    Image(systemName: isLayoutLocked ? "lock.fill" : "lock.open.fill")
                }
                .accessibilityLabel(isLayoutLocked ? "Unlock Layout" : "Lock Layout")
                
                Button(action: {
                    store.layoutManager.resetLayout(for: selectedDate, category: selectedCategory ?? .lunch)
                    layoutUI.tables = store.tables
                    isLayoutLocked = true
                    isZoomLocked = false 
                }) {
                    Image(systemName: "arrow.counterclockwise.circle")
                }
                .accessibilityLabel("Reset Layout")
                
                Button(action: {
                    withAnimation {
                        print("Reset Zoom button tapped")
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                }
                .accessibilityLabel("Reset Zoom")
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showTopControls.toggle()
                    }
                }) {
                    Image(systemName: showTopControls ? "chevron.up" : "chevron.down")
                        .imageScale(.large)
                }
                .accessibilityLabel(showTopControls ? "Hide Controls" : "Show Controls")
            }
        }
        .sheet(item: $selectedReservation) { reservation in
            EditReservationView(reservation: reservation)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAddReservationSheet) {
            AddReservationView()
            .environmentObject(store)
        }
        .alert(isPresented: $layoutUI.showAlert) {
            Alert(
                title: Text("Posizionamento non valido"),
                message: Text(layoutUI.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            DispatchQueue.main.async {
                print("LayoutView dimensions: \(UIScreen.main.bounds.size)")
            }
        }
        .onAppear {
            layoutUI.tables = store.tables // Initial sync
            if store.tables.isEmpty {
                store.layoutManager.loadLayout(for: selectedDate, category: selectedCategory ?? .lunch, reset: false)
            }
            systemTime = Date()
            currentTime = systemTime
        }
        .onChange(of: store.reservations) { _ in
            guard layoutUI.draggingTable == nil else {
                print("onChange: Skipped syncing during drag operation")
                return
            }
            guard layoutUI.tables != store.tables else { return } // Sync only if tables differ
            layoutUI.tables = store.tables
            print("onChange: Synced layoutUI.tables with store.tables")
        }
        .onChange(of: selectedDate) { newDate in
            if isLayoutLocked {
                store.layoutManager.loadLayout(for: newDate, category: selectedCategory ?? .lunch, reset: false)
                layoutUI.tables = store.tables
            }
            checkActiveReservations()
        }
        .onChange(of: selectedCategory) { newCategory in
            guard let newCategory = newCategory else { return }
            
            adjustTime(for: newCategory)
            
            if isLayoutLocked {
                store.layoutManager.loadLayout(for: selectedDate, category: newCategory, reset: false)
                layoutUI.tables = store.tables
            }
            checkActiveReservations()
        }
        .onChange(of: currentTime) { newTime in
            let calendar = Calendar.current
            let currentTime = selectedDate.combined(withTimeFrom: newTime) ?? newTime
            
            store.handleTimeUpdate(currentTime)
            
            if let newCategory = store.selectedCategory {
                selectedCategory = newCategory // Synchronize the category picker
            }
            
            store.layoutManager.loadLayout(for: selectedDate, category: store.selectedCategory ?? .lunch, reset: false)
            layoutUI.tables = store.tables
            
            checkActiveReservations()
        }
        .onChange(of: store.tables) { updatedTables in
            guard layoutUI.tables != updatedTables else { return }
            layoutUI.tables = updatedTables
        }
        .onChange(of: store.isSidebarVisible) { isVisible in
            // Force the ZoomableScrollView to recalculate its contentInset
        }
        .alert(isPresented: $showingNoBookingAlert) {
            Alert(
                title: Text("Attenzione!"),
                message: Text("Impossibile inserire prenotazioni fuori da orario pranzo o cena."),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbarBackground(Material.ultraThin, for: .navigationBar) // Add this line for iOS 16+
        .toolbarBackground(.visible, for: .navigationBar) // Ensure the background is visible

    }

    // MARK: - Subviews

    private var topControls: some View {
        HStack {
            if horizontalSizeClass == .compact {
                // Compact layout
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        datePicker
                        categoryPicker
                    }
                    HStack(spacing: 8) {
                        timePicker
                            .frame(maxWidth: .infinity, alignment: .leading)
                        addReservationButton
                            .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
            } else {
                // Wide layout
                HStack {
                    datePicker
                    categoryPicker
                    Spacer()
                    timePicker
                    Spacer()
                    addReservationButton
                }
            }
        }
        .padding()
        .clipped() // Ensure content stays within the specified height
    }
 
    private var datePicker: some View {
        VStack(alignment: .leading) {
            Text("Seleziona Giorno")
                .font(.caption)
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .frame(height: 44)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading) {
            Text("Categoria")
                .font(.caption)
            Picker("Categoria", selection: $selectedCategory) {
                Text("Pranzo").tag(Reservation.ReservationCategory?.some(.lunch))
                Text("Cena").tag(Reservation.ReservationCategory?.some(.dinner))
            }
            .pickerStyle(.segmented)
            .frame(width: 200, height: 44)
        }
    }

    private var timePicker: some View {
        VStack(alignment: .leading) {
            Text("Orario")
                .font(.caption)
            HStack(alignment: .center, spacing: 8) {
                // Original DatePicker
                DatePicker(
                    "Scegli orario",
                    selection: Binding(
                        get: { currentTime },
                        set: { newTime in
                            currentTime = newTime
                            isManuallyOverridden = true
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()

                // Current time button aligned to the right
                Button("Torna all'ora corrente") {
                    withAnimation {
                        currentTime = systemTime
                        isManuallyOverridden = false
                    }
                }
                .font(.caption)
                .opacity(isManuallyOverridden ? 1 : 0)
                .animation(.easeInOut, value: isManuallyOverridden)
            }
        }
    }



    private var addReservationButton: some View {
        Button {
            tableForNewReservation = nil
            showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
        }
        .disabled(selectedCategory == .noBookingZone)
        .foregroundColor(selectedCategory == .noBookingZone ? .gray : .blue)
    }


    private func handleEmptyTableTap(for table: TableModel) {
        tableForNewReservation = table
        showingAddReservationSheet = true
    }

    private func adjustTime(for category: Reservation.ReservationCategory) {
        switch category {
        case .lunch:
            currentTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? currentTime
        case .dinner:
            currentTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? currentTime
        case .noBookingZone:
            break
        }
    }
    
    private func checkActiveReservations() {
        let calendar = Calendar.current
        let combinedDate = selectedDate.combined(withTimeFrom: currentTime) ?? currentTime

        for table in layoutUI.tables {
            if let activeReservation = store.activeReservation(
                for: table,
                date: combinedDate,
                time: currentTime
            ) {
                print("Active reservation found for table \(table.id): \(activeReservation)")
            } else {
                print("No active reservation for table \(table.id)")
            }
        }
    }
}

