

import SwiftUI

struct LayoutView: View {
    @EnvironmentObject var store: ReservationStore
    @Environment(\.locale) var locale // Access the current locale


    @Namespace private var animationNamespace

    // Use the LayoutViewModel for manual dragging logic + pop-up alerts
    @StateObject private var layoutVM: LayoutViewModel

    init(store: ReservationStore) {
        let viewModel = LayoutViewModel(store: store)
        _layoutVM = StateObject(wrappedValue: viewModel)
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

    // For "Add Reservation" on a table
    @State private var showingAddReservationSheet: Bool = false
    @State private var tableForNewReservation: TableModel? = nil

    // MARK: - Cell Size (for each grid cell)
    private let cellSize: CGFloat = 40
   

    // MARK: - Zoom and Pan State
    // No longer needed as UIScrollView manages zooming and panning

    @State private var showingNoBookingAlert: Bool = false
    @State private var isLayoutLocked: Bool = true
    @State private var showTopControls: Bool = true

    // New State Variables for ZoomableScrollView
    @State private var parentSize: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0


    var body: some View {
        VStack {
            // Conditionally display topControls with animation
            if showTopControls {
                topControls
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()

            
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geometry in
                    let totalWidth = CGFloat(store.totalColumns) * layoutVM.cellSize
                    let totalHeight = CGFloat(store.totalRows) * layoutVM.cellSize
                    ZoomableScrollView(zoomScale: $zoomScale, contentSize: CGSize(width: totalWidth, height: totalHeight)) {
                        ZStack {
                            gridBackground

                            ForEach(layoutVM.tables, id: \.id) { table in
                                let rect = layoutVM.calculateTableRect(for: table)
                                tableView(table: table, zoomScale: zoomScale, rect: rect, isLayoutLocked: isLayoutLocked)
                            }
                        }
                        .frame(
                            width: totalWidth,
                            height: totalHeight
                        )
                    }
                    .onAppear {
                        // Center the grid initially
                        let baseGridWidth = CGFloat(store.totalColumns) * layoutVM.cellSize
                        let baseGridHeight = CGFloat(store.totalRows) * layoutVM.cellSize

                        // Calculate the initial offset to center the grid
                        let initialOffset = CGSize(
                            width: (geometry.size.width - baseGridWidth) / 2,
                            height: (geometry.size.height - baseGridHeight) / 2
                        )

                        // Apply the initial offset using UIScrollView's contentInset
                        // However, since we're using UIScrollView's built-in zooming,
                        // initial centering is handled in the `ZoomableScrollView`'s coordinator
                        // So, no additional offset is needed here
                    }
                }
                .clipped() // Ensures content doesn’t overflow the parent view

            }
            .dynamicBackground(light: Color.white, dark: Color.black)

            Spacer()
        }
        .dynamicBackground(light: Color(hex: "#BFC3E3"), dark: Color(hex: "#4A4E6D"))
        .italianLocale()
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    isLayoutLocked.toggle()
                }) {
                    Image(systemName: isLayoutLocked ? "lock.fill" : "lock.open.fill")
                }
                .accessibilityLabel(isLayoutLocked ? "Unlock Layout" : "Lock Layout")

                Button(action: {
                    store.resetLayout(for: selectedDate, category: selectedCategory ?? .lunch)
                    layoutVM.tables = store.tables
                    isLayoutLocked = true
                }) {
                    Image(systemName: "arrow.counterclockwise.circle")
                }
                .accessibilityLabel("Reset Layout")

                Button(action: {
                    withAnimation {
                        NotificationCenter.default.post(name: .resetZoom, object: nil)
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                }
                .accessibilityLabel("Reset Zoom")
            }
        }
        .sheet(item: $selectedReservation) { reservation in
            EditReservationView(reservation: reservation)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAddReservationSheet) {
            AddReservationView(
                forcedTable: tableForNewReservation,
                preselectedDate: selectedDate
            )
            .environmentObject(store)
        }
        .alert(isPresented: $layoutVM.showAlert) {
            Alert(
                title: Text("Posizionamento non valido"),
                message: Text(layoutVM.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            layoutVM.tables = store.tables // Initial sync
            if store.tables.isEmpty {
                store.loadLayout(for: selectedDate, category: selectedCategory ?? .lunch, reset: false)
            }
            systemTime = Date()
            currentTime = systemTime
        }
        .onChange(of: store.reservations) { _ in
            guard layoutVM.draggingTable == nil else {
                print("onChange: Skipped syncing during drag operation")
                return
            }
            guard layoutVM.tables != store.tables else { return } // Sync only if tables differ
            layoutVM.tables = store.tables
            print("onChange: Synced layoutVM.tables with store.tables")
        }
        .onChange(of: selectedDate) { newDate in
            if isLayoutLocked {
                store.loadLayout(for: newDate, category: selectedCategory ?? .lunch, reset: false)
                layoutVM.tables = store.tables
            }
        }
        .onChange(of: selectedCategory) { newCategory in
            guard let newCategory = newCategory else { return }

            // Update the time picker to default times for the selected category
            adjustTime(for: newCategory)

            if isLayoutLocked {
                store.loadLayout(for: selectedDate, category: newCategory, reset: false)
                layoutVM.tables = store.tables
            }
        }
        .onChange(of: currentTime) { newTime in
            store.handleTimeUpdate(newTime)

            // Update the selected category to match the new time
            if let newCategory = store.selectedCategory {
                selectedCategory = newCategory // Synchronize the category picker
            }

            // Load the layout for the new category
            store.loadLayout(for: selectedDate, category: store.selectedCategory ?? .lunch, reset: false)
            layoutVM.tables = store.tables
        }
        .onChange(of: store.tables) { updatedTables in
            guard layoutVM.tables != updatedTables else { return }
            layoutVM.tables = updatedTables
        }
        .alert(isPresented: $showingNoBookingAlert) {
            Alert(
                title: Text("Attenzione!"),
                message: Text("Impossibile inserire prenotazioni fuori da orario pranzo o cena."),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbar {
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
        .navigationTitle("Layout Tavoli: \(store.formattedDate(date: selectedDate, locale: locale))")
    }

    // MARK: - Subviews

    private var topControls: some View {
        HStack {
            datePicker
            categoryPicker
            Spacer()
            timePicker
            currentTimeButton
            Spacer()
            addReservationButton
        }
        .padding()
    }

    private var gridBackground: some View {
        GeometryReader { geometry in
            let rows = store.totalRows
            let cols = store.totalColumns
            let cellSize = layoutVM.cellSize
            let totalWidth = CGFloat(cols) * cellSize
            let totalHeight = CGFloat(rows) * cellSize

            ZStack {
                // Outer Border with Windows
                Path { path in
                    // Top Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: 0, y: 0), to: CGPoint(x: totalWidth - 1, y: 0), windows: [(2, 5), (14, 17)], isThick: true)
                    // Right Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: totalWidth, y: 0), to: CGPoint(x: totalWidth, y: totalHeight - 1), windows: [(4, 7)], isThick: true)
                    // Left Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: 0, y: totalHeight - 1), to: CGPoint(x: 0, y: 0), windows: [], isThick: true)

                    // Bottom Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: totalWidth - 1, y: totalHeight), to: CGPoint(x: 0, y: totalHeight), windows: [(3, 7)], isThick: true)
                }
                .stroke(
                    dynamicColor(light: .gray, dark: .gray),
                    style: StrokeStyle(
                        lineWidth: 4
                    )
                )
                
                Path { path in
                    // Top Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: 0, y: 0), to: CGPoint(x: totalWidth, y: 0), windows: [(2, 5), (14, 17)], isThick: false)
                    // Right Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: totalWidth, y: 0), to: CGPoint(x: totalWidth, y: totalHeight), windows: [(4, 7)], isThick: false)
                    // Left Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: 0, y: totalHeight - 1), to: CGPoint(x: 0, y: 0), windows: [], isThick: false)

                    // Bottom Border
                    addBorderWithWindows(to: &path, from: CGPoint(x: totalWidth - 1, y: totalHeight), to: CGPoint(x: 0, y: totalHeight), windows: [(3, 7)], isThick: false)
                }
                .stroke(
                    dynamicColor(light: .gray, dark: .gray),
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [6, 4]
                    )
                )

                // Inner Grid Lines
                Path { path in
                    // Horizontal Inner Grid Lines
                    for row in 1..<rows {
                        let y = CGFloat(row) * cellSize
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: totalWidth, y: y))
                    }

                    // Vertical Inner Grid Lines
                    for col in 1..<cols {
                        let x = CGFloat(col) * cellSize
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: totalHeight))
                    }
                }
                .stroke(
                    dynamicColor(light: Color(hex: "#545454"), dark: Color(hex: "#c2c0c0")),
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: [6, 4]
                    )
                )
            }
            .frame(width: totalWidth, height: totalHeight)
        }
    }

    private func addBorderWithWindows(
        to path: inout Path,
        from start: CGPoint,
        to end: CGPoint,
        windows: [(Int, Int)],
        isThick: Bool
    ) {
        let isHorizontal = start.y == end.y
        let length = isHorizontal ? abs(end.x - start.x) : abs(end.y - start.y)
        let direction = isHorizontal ? (end.x > start.x ? 1 : -1) : (end.y > start.y ? 1 : -1)
        let stepSize = layoutVM.cellSize

        for step in stride(from: 0, through: Int(length / stepSize), by: 1) {
            let inWindow = windows.contains { window in
                step >= window.0 && step <= window.1
            }

            if (inWindow && !isThick) || (!inWindow && isThick) {
                let segmentStart = isHorizontal
                    ? CGPoint(x: start.x + CGFloat(step) * stepSize * CGFloat(direction), y: start.y)
                    : CGPoint(x: start.x, y: start.y + CGFloat(step) * stepSize * CGFloat(direction))
                let segmentEnd = isHorizontal
                    ? CGPoint(x: start.x + CGFloat(step + 1) * stepSize * CGFloat(direction), y: start.y)
                    : CGPoint(x: start.x, y: start.y + CGFloat(step + 1) * stepSize * CGFloat(direction))

                path.move(to: segmentStart)
                path.addLine(to: segmentEnd)
            }
        }
    }





    @ViewBuilder
    private func tableView(table: TableModel, zoomScale: CGFloat, rect: CGRect, isLayoutLocked: Bool) -> some View {
        if layoutVM.draggingTable?.id != table.id {
            TableDragView(
                table: table,
                zoomScale: zoomScale,
                selectedDate: selectedDate,
                selectedCategory: selectedCategory ?? .lunch,
                currentTime: currentTime,
                layoutVM: layoutVM,
                showingNoBookingAlert: $showingNoBookingAlert,
                onTapEmpty: { handleEmptyTableTap(for: table) },
                onEditReservation: { reservation in selectedReservation = reservation },
                isLayoutLocked: isLayoutLocked
            )
            .environmentObject(store)
            .matchedGeometryEffect(id: table.id, in: animationNamespace)
        }
    }




    private var datePicker: some View {
        VStack(alignment: .leading) {
            Text("Seleziona Giorno")
                .font(.caption)
                .padding(.top)
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .frame(height: 44)
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading) {
            Text("Categoria")
                .font(.caption)
                .padding(.top)
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
                .padding(.top)
            DatePicker(
                "",
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
            .frame(height: 44)
        }
    }

    private var currentTimeButton: some View {
        VStack(alignment: .leading) {
            Text(" ")
                .font(.caption)
                .opacity(0)
                .frame(height: 0)
            Button("Torna all'ora corrente") {
                withAnimation {
                    currentTime = systemTime
                    isManuallyOverridden = false
                }
            }
            .font(.caption)
            .opacity(isManuallyOverridden ? 1 : 0)
            .animation(.easeInOut, value: isManuallyOverridden)
            .frame(height: 44)
        }
    }

    private var addReservationButton: some View {
        Button {
            tableForNewReservation = nil
            showingAddReservationSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .padding()
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
    
    func updateCategory(for time: Date) {
        let hour = Calendar.current.component(.hour, from: time)
        if hour >= 12 && hour <= 15 {
            selectedCategory = .lunch
        } else if hour >= 18 && hour <= 21 {
            selectedCategory = .dinner
        } else {
            selectedCategory = .noBookingZone
        }
        print("Category updated to \(selectedCategory?.rawValue ?? "none") based on time.")
    }
}

// Extension to handle reset zoom notification
extension Notification.Name {
    static let resetZoom = Notification.Name("resetZoom")
}
