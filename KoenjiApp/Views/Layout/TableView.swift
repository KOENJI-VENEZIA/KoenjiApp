import EmojiPalette
import SwiftUI

enum DragState: Equatable {
    case idle
    case dragging(offset: CGSize)
    case started(offset: CGSize)
}

struct TableView: View {
    
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @ObservedObject var layoutUI: LayoutUIManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(ClusterManager.self) var clusterManager
    
    @State var tableView: TableViewModel = TableViewModel()
    private let normalizedTimeCache = NormalizedTimeCache()

    @Binding var selectedIndex: Int
    let table: TableModel
    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID  // Animation namespace from LayoutView
    let onTableUpdated: (TableModel) -> Void
    
    @Binding var changedReservation: Reservation?
    @Binding var isEditing: Bool
    @Binding var isLayoutReset: Bool
    @Binding var showInspector: Bool
    @Binding var statusChanged: Int
    
    @GestureState private var dragOffset: CGSize = .zero
    @State private var cachedRemainingTime: String?

    private var cellSize: CGFloat { return gridData.cellSize }

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }
    
    
    // MARK: - Body
    var body: some View {
        // Determine if the table is highlighted
        let isHighlighted = layoutServices.tableAnimationState[table.id] ?? false

        // Get active reservation

        let isDragging = {
            if case .dragging = tableView.dragState { return true }
            return false
        }()


        let (fillColor, idSuffix): (Color, String) = {
            if isDragging, let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.5), "dragging_1")
            } else if isDragging, tableView.currentActiveReservation == nil {
                return (Color(hex: "#AEAB7D").opacity(0.5), "dragging_2")
            } else if let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.7), "reserved")
            } else if isLayoutLocked, let activeRes = tableView.currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.7), "locked")
            } else {
                return (Color(hex: "#A3B7D2").opacity(0.2), "default")
            }
        }()

        ZStack {

            ZStack {

                let uniqueKey = UUID().uuidString

                // Determine table style and ID suffix dynamically

                RoundedRectangle(cornerRadius: 12.0)
                    .fill(fillColor)
                    .frame(
                        width: tableFrame.width,
                        height: tableFrame.height
                    )
                    .matchedGeometryEffect(
                        id:
                            "\(table.id)-\(selectedDate)-\(selectedCategory.rawValue)-\(idSuffix)-\(uniqueKey)",
                        in: animationNamespace
                    )

                if let reservation = tableView.currentActiveReservation, reservation.id != tableView.nearEndReservation?.id {
                    // Stroke overlay
                    RoundedRectangle(cornerRadius: 12.0)
                        .stroke(
                            isDragging
                                ? Color.yellow.opacity(0.5)
                                : (isHighlighted
                                    ? Color(hex: "#9DA3D0")
                                    : (reservation.status == .late
                                            ? Color(hex: "#f78457")
                                            : (reservation.status == .showedUp ? .green : .white))),
                            style: isDragging
                                ? StrokeStyle(
                                    lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])  // Dashed when dragging
                                : StrokeStyle(lineWidth: 3)  // Solid for other states
                        )
                        .frame(
                            width: tableFrame.width,
                            height: tableFrame.height
                        )
                } else if tableView.nearEndReservation != nil {
                    // Stroke overlay
                    RoundedRectangle(cornerRadius: 12.0)
                        .stroke(
                            isDragging
                                ? Color.yellow.opacity(0.5)
                                : (isHighlighted
                                    ? Color(hex: "#9DA3D0")
                                   : .red),
                            style: isDragging
                                ? StrokeStyle(
                                    lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])  // Dashed when dragging
                                : StrokeStyle(lineWidth: 3)  // Solid for other states
                        )
                        .frame(
                            width: tableFrame.width,
                            height: tableFrame.height
                        )
                } else if tableView.currentActiveReservation == nil {
                    RoundedRectangle(cornerRadius: 12.0)
                        .stroke(
                            isDragging
                                ? Color.yellow.opacity(0.5)
                                : (isHighlighted
                                    ? Color(hex: "#9DA3D0")
                                    : .white),
                            style: isDragging
                                ? StrokeStyle(
                                    lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])  // Dashed when dragging
                                : StrokeStyle(lineWidth: 3)  // Solid for other states
                        )
                        .frame(
                            width: tableFrame.width,
                            height: tableFrame.height
                        )
                }

                

                Group {
                    showedUpMark()
                        .opacity(
                            (tableView.currentActiveReservation?.status == .showedUp) ? 1 : 0
                        )

                    emojiMark(tableView.currentActiveReservation?.assignedEmoji ?? "")
                        .opacity(
                            (tableView.currentActiveReservation?.assignedEmoji != nil) ? 1 : 0
                        )

                    lateMark()
                        .opacity(
                            tableView.lateReservation != nil && tableView.currentActiveReservation != nil && tableView.currentActiveReservation?.status != .showedUp ? 1 : 0
                        )

                    nearEndMark()
                        .opacity(tableView.nearEndReservation != nil ? 1 : 0)
                }
                
                // Reservation information or table name
                Group {
                    reservationInfo(
                        reservation: tableView.currentActiveReservation,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height
                    )
                    .opacity(tableView.currentActiveReservation != nil ? 1 : 0)

                    upcomingReservationPlaceholder(
                        reservation: tableView.firstUpcomingReservation,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height
                    )
                    .opacity(
                        tableView.currentActiveReservation == nil &&
                        tableView.firstUpcomingReservation != nil ? 1 : 0
                    )

                    tableName(
                        name: table.name,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height
                    )
                    .opacity(
                        tableView.currentActiveReservation == nil &&
                        tableView.firstUpcomingReservation == nil ? 1 : 0
                    )
                }
                
            }
            .transition(.opacity)
            .opacity(table.isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: table.isVisible)
        }
        .onAppear {
            updateResData(appState.selectedDate, refreshedKey: "onAppear")
        }
        .onChange(of: statusChanged) {
            updateResData(appState.selectedDate, refreshedKey: "statusChanged", forceUpdate: true)
        }
        .onChange(of: showInspector) {
            updateResData(appState.selectedDate, refreshedKey: "showInspector")
        }
        .onChange(of: changedReservation) {
            updateResData(appState.selectedDate, refreshedKey: "changedReservation")
        }
        .onChange(of: appState.selectedDate) {
            updateResData(appState.selectedDate, refreshedKey: "appState.selectedDate", forceUpdate: true)
        }
        .onChange(of: appState.selectedCategory) { oldCat, newCat in
            updateResData(appState.selectedDate, refreshedKey: "appState.selectedCategory", forceUpdate: true)
        }
        .onChange(of: tableView.selectedEmoji) {
            handleEmojiAssignment(tableView.currentActiveReservation, tableView.selectedEmoji)
        }
        .onChange(of: tableView.currentActiveReservation?.status) { 
                updateResData(appState.selectedDate, refreshedKey: "status")
        }
        .contextMenu {
            
            Button {
                print("DEBUG: FORCED Current active reservation: \(resCache.reservation(forTable: table.id, datetime: appState.selectedDate, category: selectedCategory)?.name ?? "none")")
            } label: {
                Label("Debug Print", systemImage: "ladybug.slash.fill")
            
            }
            
            Divider()
                
            
            Button {
                tableView.showEmojiPicker = true
            } label: {
                Label("Scegli Emoji", systemImage: "ellipsis.circle")
            }
            

            Divider()

            Button("Cancellazione") {
                if let reservation = tableView.currentActiveReservation {
                    handleCancelled(reservation)
                }
            }
        }
        .popover(isPresented: $tableView.showFullEmojiPicker) {
            EmojiPaletteView(selectedEmoji: $tableView.selectedEmoji)
        }
        .popover(isPresented: $tableView.showEmojiPicker) {
            EmojiSmallPicker(
                onEmojiSelected: { emoji in
                    if tableView.selectedEmoji != emoji {
                        tableView.selectedEmoji = emoji
                    } else {
                        tableView.selectedEmoji = ""
                    }
                    tableView.showEmojiPicker = false  // Dismiss the popover
                },
                showFullEmojiPicker: $tableView.showFullEmojiPicker,
                selectedEmoji: $tableView.selectedEmoji)
        }
        .position(x: tableFrame.minX, y: tableFrame.minY)
        .offset(dragOffset)
        .gesture(
            doubleTapGesture()
                .exclusively(before:
                    tapGesture()
                        .exclusively(before:
                            dragGesture()
                        )
                )
        )
    }
    
    // MARK: - Subviews
    private func showedUpMark() -> some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 17, height: 17)
            .foregroundColor(.green)
            .offset(x: -tableFrame.width / 2 + 13, y: -tableFrame.height / 2 + 13)
            .zIndex(2)
    }
    
    private func emojiMark(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 20))
            .frame(maxWidth: 23, maxHeight: 23)
            .offset(x: tableFrame.width / 2 - 18, y: -tableFrame.height / 2 + 12)
            .zIndex(2)
    }
    
    private func nearEndMark() -> some View {
        Image(systemName: "figure.walk.motion.trianglebadge.exclamationmark")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(
                .yellow,
                .orange
            )
            .symbolRenderingMode(.palette)
            .offset(x: tableFrame.width / 2 - 15, y: tableFrame.height / 2 - 15)
            .zIndex(2)
    }
    
    private func lateMark() -> some View {
        Image(systemName: "clock.badge.exclamationmark.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 17, height: 17)  // Adjust size as needed
            .foregroundColor(.yellow)  // Optional styling
            .symbolRenderingMode(.multicolor)
            .offset(x: -tableFrame.width / 2 + 15, y: -tableFrame.height / 2 + 15)  // Position in the top-left corner
            .zIndex(2)
    }
    
    @ViewBuilder
    private func reservationInfo(reservation: Reservation?, tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        
        if let reservation = reservation {
            VStack(spacing: 2) {
                Text(reservation.name)
                    .bold()
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .lineLimit(1) // Ensures the text stays on one line
                    .truncationMode(.tail) // Truncates with "..." at the end if it overflows
                Text("\(reservation.numberOfPersons) p.")
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                
                Text("\(reservation.phone)")
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                
                if let remaining = cachedRemainingTime
                {
                    Text("Tempo rimasto:")
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.footnote)
                    
                    if reservation.id == tableView.nearEndReservation?.id {
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .frame(width: tableFrame.width-10, height: 20)
                            
                            Text("\(remaining)")
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(hex: "#bf5b34"))
                                .font(.footnote)
                        }
                    } else {
                        Text("\(remaining)")
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.footnote)
                    }
                }
            }
            .background(Color.clear)
            .cornerRadius(8)
            .frame(width: tableFrame.width, height: tableFrame.height)
        }
        
    }
    
    @ViewBuilder
    private func upcomingReservationPlaceholder(
        reservation: Reservation?, tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {

        if let reservation = reservation {
            
            VStack(spacing: 2) {
                Text(reservation.name)
                    .bold()
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .lineLimit(1) // Ensures the text stays on one line
                    .truncationMode(.tail) // Truncates with "..." at the end if it overflows
                Text("\(reservation.numberOfPersons) p.")
                    .font(.footnote)
                    .opacity(0.8)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Text("\(reservation.phone)")
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                
                if let upcomingTime = DateHelper.timeUntilReservation(
                    currentTime: appState.selectedDate,
                    reservationDateString: reservation.dateString,
                    reservationStartTimeString: reservation.startTime)
                {
                    Text("In arrivo tra:\n\(DateHelper.formattedTime(from: upcomingTime) ?? "Errore")")
                        .bold()
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
            }
            .frame(width: tableFrame.width, height: tableFrame.height)
            .background(Color.clear)
            .cornerRadius(8)
        }
    }

    private func tableName(name: String, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        VStack {
            Text(name)
                .bold()
                .foregroundColor(.blue)
                .font(.headline)
                .padding(4)
                .background(Color.white.opacity(0.7))
                .cornerRadius(8)

            Text("Nessuna prenotazione\nin arrivo")
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .bold()
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .frame(width: tableFrame.width - 5, height: tableFrame.height - 5)

    }
    
    // MARK: - View Specific Methods
    private func updateResData(_ date: Date, refreshedKey: String, forceUpdate: Bool = false, oldCat: Reservation.ReservationCategory? = nil, newCat: Reservation.ReservationCategory? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm" // ✅ Only includes year, month, day, hour, and minute
        formatter.timeZone = TimeZone(identifier: "UTC") // Adjust if needed
        
        let formattedDate = formatter.string(from: date)
        let key = "\(formattedDate)-\(refreshedKey)-\(appState.selectedCategory.rawValue)-\(table.id)"
        
        // ✅ Guard against duplicate updates
        if !forceUpdate, oldCat == nil, newCat == nil {
            if tableView.currentActiveReservation != nil || tableView.lateReservation != nil || tableView.firstUpcomingReservation != nil || tableView.nearEndReservation != nil {
                
                guard !appState.lastRefreshedKeys.contains(key) else {
                    print("⚠️ Skipping update, key already exists!")
                    return }
            }
        }
        print("New key: \(key)")
        print("DEBUG: Refreshing for \(date) and \(refreshedKey)...")
        appState.lastRefreshedKeys.append(key) // ✅ Append only if it's a new key
        
        print("Key added!")

        updateCachedReservation(date)
        updateFirstUpcoming(date)
        updateLateReservation(date)
        updateNearEndReservation(date)
        updateRemainingTime(date)
    }
    
    private func updateRemainingTime(_ date: Date) {
        cachedRemainingTime = TimeHelpers.remainingTimeString(
            endTime: tableView.currentActiveReservation?.endTimeDate ?? Date(),
            currentTime: appState.selectedDate
        )
    }
    
    private func updateCachedReservation(_ date: Date) {
        if let reservation = resCache.reservation(forTable: table.id, datetime: date, category: selectedCategory), reservation.status != .canceled, reservation.reservationType != .waitingList {
            tableView.currentActiveReservation = reservation
        } else {
            tableView.currentActiveReservation = nil
        }
        
        
    }
    
    private func updateLateReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation, resCache.lateReservations(currentTime: date).contains(where: { $0.id == reservation.id }) {
            tableView.lateReservation = reservation
        } else {
            tableView.lateReservation = nil
        }
    }
    
    private func updateNearEndReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation, resCache.nearingEndReservations(currentTime: date).contains(where: {
            $0.id == reservation.id
        }) {
            tableView.nearEndReservation = reservation } else {
                tableView.nearEndReservation = nil
            }
    }
    
    private func updateFirstUpcoming(_ date: Date) {
        if let reservation = resCache.firstUpcomingReservation(
            forTable: table.id, date: date, time: date,
            category: selectedCategory) {
            tableView.firstUpcomingReservation = reservation
        } else {
            tableView.firstUpcomingReservation = nil
        }
    }
    
    private func handleCancelled(_ reservation: Reservation) {
        var updatedReservation = reservation
        if updatedReservation.status != .canceled {
            updatedReservation.status = .canceled
        }
        changedReservation = updatedReservation
        reservationService.updateReservation(updatedReservation)
    }

    private func handleEmojiAssignment(_ activeReservation: Reservation?, _ emoji: String) {
        guard var reservationActive = activeReservation else { return }
        print("Emoji: \(emoji)")
        reservationActive.assignedEmoji = emoji
        reservationService.updateReservation(reservationActive)
        statusChanged += 1
        onStatusChange()
    }
    
    private func handleTap(_ activeReservation: Reservation?) {
        guard let activeReservation = activeReservation else { return }

        let oldReservation = activeReservation
        var currentReservation = activeReservation

        print("1 - Status in HandleTap: \(currentReservation.status)")

        if currentReservation.status == .pending || currentReservation.status == .late {
            // Case 1: Update to .showedUp
            currentReservation.status = .showedUp
            tableView.showedUp = true
            tableView.isLate = false

            print("2 - Status in HandleTap: \(currentReservation.status)")
            reservationService.updateReservation(oldReservation, newReservation: currentReservation)  // Ensure the data store is updated
            statusChanged += 1
        } else {
            // Case 2: Determine if the reservation is late or pending
            if tableView.lateReservation?.id == currentReservation.id {
                currentReservation.status = .late
            } else {
                currentReservation.status = .pending
            }

                print("2 - Status in HandleTap: \(currentReservation.status)")
            reservationService.updateReservation(oldReservation, newReservation: currentReservation)  // Ensure the data store is updated
                statusChanged += 1
            
        }
    }

    private func handleDoubleTap() {
        // Check if the table is occupied by filtering active reservations.
        if let reservation = tableView.currentActiveReservation {
            showInspector = true
            onEditReservation(reservation)
        } else if tableView.currentActiveReservation == nil || tableView.currentActiveReservation?.id == tableView.firstUpcomingReservation?.id {
                onTapEmpty(table)
            }
        
        
    }

    private func handleDragEnd(
        translation: CGSize, cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat,
        xPos: CGFloat, yPos: CGFloat
    ) {
        layoutUI.isDragging = false
        guard !isLayoutLocked else {
            layoutServices.currentlyDraggedTableID = nil
            return
        }

        let deltaCols = Int(round(translation.width / cellSize))
        let deltaRows = Int(round(translation.height / cellSize))

        let newRow = table.row + deltaRows
        let newCol = table.column + deltaCols

        let proposedFrame = CGRect(
            x: xPos + translation.width - tableFrame.width / 2,
            y: yPos + translation.height - tableFrame.height / 2,
            width: tableFrame.width,
            height: tableFrame.height
        )

        print("Proposed Frame: \(proposedFrame)")
        print("Grid Bounds: \(gridData.gridBounds)")
        print("Excluded Regions: \(gridData.excludedRegions)")

        // Check for blockage before moving the table
        if !gridData.isBlockage(proposedFrame) {
            print("Blockage detected! Table move rejected.")
            layoutServices.currentlyDraggedTableID = nil
            return
        }

        clusterManager.lastLayoutSignature = layoutServices.computeLayoutSignature(tables: layoutUI.tables)
        
        // Delegate the move to LayoutUIManager
        layoutUI.attemptMove(
            table: table, to: (row: newRow, col: newCol), for: selectedDate,
            activeTables: layoutUI.tables
        )

        // Retrieve the updated table from layoutUI.tables
        guard let updatedTable = layoutUI.tables.first(where: { $0.id == table.id }) else {
            print("Error: Updated table not found after move!")
            return
        }
        
        
        
        let combinedDate = DateHelper.combine(date: selectedDate, time: appState.selectedDate)
//        layoutServices.saveTables(tables, for: combinedDate, category: selectedCategory)
        if let updatedLayout = layoutServices.cachedLayouts[
            layoutServices.keyFor(date: combinedDate, category: selectedCategory)]
        {
            print("Updated cache for \(selectedCategory):")
            for table in updatedLayout {
                print("Updated table \(table.name) at (\(table.row), \(table.column))")
            }
        }

        
        if let reservation = tableView.currentActiveReservation {
            reservationService.updateActiveReservationAdjacencyCounts(for: reservation)
        }
        let layoutKey = layoutServices.keyFor(date: combinedDate, category: selectedCategory)
        layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        layoutServices.saveToDisk()

        onTableUpdated(updatedTable)
        isLayoutReset = false
        layoutServices.currentlyDraggedTableID = nil

    }
    
    private func isReservationMatching(
        _ reservation: Reservation,
        table: TableModel,
        normalizedStartTime: Date,
        normalizedEndTime: Date,
        normalizedCurrentTime: Date
    ) -> Bool {
        // Check if the table is assigned to this reservation
        guard reservation.tables.contains(where: { $0.id == table.id }) else {
            return false
        }

        // Check if the current time falls within the reservation's time range
        return normalizedCurrentTime >= normalizedStartTime
            && normalizedCurrentTime < normalizedEndTime
    }
    
    // MARK: - Gestures
    private func tapGesture() -> some Gesture {
        TapGesture(count: 1).onEnded {
            // Start a timer for single-tap action
            tableView.tapTimer?.invalidate()  // Cancel any existing timer
            tableView.tapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                Task { @MainActor in
                    if !tableView.isDoubleTap {
                        // Process single-tap only if no double-tap occurred
                        if let reservation = tableView.currentActiveReservation {
                            handleTap(reservation) }
                    }
                }
            }
        }
    }
    private func doubleTapGesture() -> some Gesture {
        TapGesture(count: 2).onEnded {
            // Cancel the single-tap timer and process double-tap
            tableView.tapTimer?.invalidate()
            tableView.isDoubleTap = true  // Prevent single-tap action
            tableView.dragState = .idle
            
                handleDoubleTap()

            // Reset double-tap state shortly after handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                tableView.isDoubleTap = false
            }
        }
    }
    
    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($dragOffset) { value, state, _ in
                guard !isLayoutLocked else { return }
                state = value.translation
            }
            .onChanged { value in
                
                guard !isLayoutLocked else { return }
                tableView.dragState = .dragging(offset: value.translation)
            }
            .onEnded { value in
                tableView.dragState = .idle  // Reset dragging state
                if abs(value.translation.width) > 10 || abs(value.translation.height) > 10 {
                    handleDragEnd(
                        translation: value.translation,
                        cellSize: cellSize,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height,
                        xPos: tableFrame.minX,
                        yPos: tableFrame.minY
                    )
                }
            }
    }
}

struct EmojiSmallPicker: View {
    let onEmojiSelected: (String) -> Void
    @Binding var showFullEmojiPicker: Bool
    @Binding var selectedEmoji: String
    private let emojis = ["❤️", "😂", "😮", "😢", "🙏", "❗️"]

    var body: some View {
        HStack {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    onEmojiSelected(emoji)
                } label: {
                    Text(emoji)
                        .font(.title)
                }
            }

            Button {
                onEmojiSelected("")
                showFullEmojiPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                    Image(systemName: "plus")
                        .foregroundStyle(Color.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .presentationDetents([.height(50.0)])  // Bottom sheet size
        .presentationDragIndicator(.visible)  // Optional drag indicator
    }
}

