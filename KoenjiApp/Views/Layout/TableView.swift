import EmojiPalette
import SwiftUI

struct TableView: View {
    let table: TableModel
    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    @State private var systemTime: Date = Date()
    @Binding var changedReservation: Reservation?
    @Binding var isEditing: Bool
    @EnvironmentObject var resCache: CurrentReservationsCache
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @ObservedObject var layoutUI: LayoutUIManager
    @Environment(\.colorScheme) var colorScheme

    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    @Binding var showInspector: Bool
    let onEditReservation: (Reservation) -> Void

    @GestureState private var dragOffset: CGSize = .zero

    enum DragState: Equatable {
        case idle
        case dragging(offset: CGSize)
        case started(offset: CGSize)
    }
    @State private var dragState: DragState = .idle

    @State private var selectedTable: TableModel?

    @State private var isDragging: Bool = false  // State to track dragging
    @State private var isHeld: Bool = false  // State for long press hold
    @State private var hasMoved: Bool = false
    let isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    let animationNamespace: Namespace.ID  // Animation namespace from LayoutView
    let onTableUpdated: (TableModel) -> Void

    @Binding var statusChanged: Int
    @State private var showEmojiPicker: Bool = false
    @State private var showFullEmojiPicker: Bool = false
    @State private var isContextMenuActive = false
    @State private var selectedEmoji: String = ""

    @State private var tapTimer: Timer?
    @State private var isDoubleTap = false

    @State private var currentActiveReservation: Reservation?
    @State private var firstUpcomingReservation: Reservation?
    @State private var lateReservation: Reservation?
    @State private var nearEndReservation: Reservation?
    
    private let normalizedTimeCache = NormalizedTimeCache()

    @State private var isLate: Bool = false
    @State private var showedUp: Bool = false
    @State private var isManuallyOverridden: Bool = false

    private var cellSize: CGFloat { return gridData.cellSize }

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }

    var body: some View {
        // Determine if the table is highlighted
        let isHighlighted = layoutServices.tableAnimationState[table.id] ?? false

        // Get active reservation

        let isDragging = {
            if case .dragging = dragState { return true }
            return false
        }()


        let (fillColor, idSuffix): (Color, String) = {
            if isDragging, let activeRes = currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.5), "dragging_1")
            } else if isDragging, currentActiveReservation == nil {
                return (Color(hex: "#AEAB7D").opacity(0.5), "dragging_2")
            } else if let activeRes = currentActiveReservation {
                return (activeRes.assignedColor.opacity(0.7), "reserved")
            } else if isLayoutLocked, let activeRes = currentActiveReservation {
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

                if let reservation = currentActiveReservation, reservation.id != nearEndReservation?.id {
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
                } else if nearEndReservation != nil {
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
                } else if currentActiveReservation == nil {
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
                // Image overlay in the top-left corner

                // Reservation information or table name
                Group {
                    if let reservation = currentActiveReservation {
                        // Active reservation exists: display reservation details.
                        reservationInfo(
                            reservation: reservation,
                            tableWidth: tableFrame.width,
                            tableHeight: tableFrame.height
                        )

                    } else if let upcomingRes = firstUpcomingReservation
                    {
                        // No active reservation, but there is an upcoming reservation.
                        upcomingReservationPlaceholder(
                            reservation: upcomingRes,
                            tableWidth: tableFrame.width,
                            tableHeight: tableFrame.height
                        )
                    } else {
                        tableName(
                            name: table.name,
                            tableWidth: tableFrame.width,
                            tableHeight: tableFrame.height
                        )
                    }
                }

                if let reservation = currentActiveReservation, reservation.status == .showedUp {
                    Image(systemName: "checkmark.circle.fill")  // Replace with your custom image or SF Symbol
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)  // Adjust size as needed
                        .foregroundColor(.green)  // Optional styling
                        .offset(x: -tableFrame.width / 2 + 13, y: -tableFrame.height / 2 + 13)  // Position in the top-left corner
                        .zIndex(2)
                }

                if let reservation = currentActiveReservation,
                    let emoji = reservation.assignedEmoji, !isContextMenuActive
                {
                    Text(emoji)
                        .font(.system(size: 20))  // Match the font size to the frame of the Image
                        .frame(maxWidth: 23, maxHeight: 23)  // Same dimensions as the Image
                        .offset(x: tableFrame.width / 2 - 18, y: -tableFrame.height / 2 + 12)  // Match position
                        .zIndex(2)
                }

                if let reservation = lateReservation, reservation.status != .showedUp {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)  // Adjust size as needed
                        .foregroundColor(.yellow)  // Optional styling
                        .symbolRenderingMode(.multicolor)
                        .offset(x: -tableFrame.width / 2 + 15, y: -tableFrame.height / 2 + 15)  // Position in the top-left corner
                        .zIndex(2)
                }

                if nearEndReservation != nil {
                    Image(systemName: "figure.walk.motion.trianglebadge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)  // Adjust size as needed
                        .foregroundStyle(
                            .yellow,
                            .orange /*isLunch ? Color(hex: "#6a6094") : Color(hex: "#435166")*/
                        )  // Optional styling
                        .symbolRenderingMode(.palette)  // Enable multicolor rendering
                        .offset(x: tableFrame.width / 2 - 15, y: tableFrame.height / 2 - 15)  // Position in the top-left corner
                        .zIndex(2)
                }
            }
        }
//        .opacity(table.isTapped ? 1 : 0)
        .onAppear {
            updateCachedReservation()
            updateLateReservation()
            updateNearEndReservation()
            updateFirstUpcoming()
            if let reservation = currentActiveReservation {
                print("DEBUG: active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found: \(reservation.name)")
            } else {
                print("DEBUG: no active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found.")
            }
        }
        .onChange(of: selectedDate) {
            updateCachedReservation()
            updateLateReservation()
            updateNearEndReservation()
            updateFirstUpcoming()

            if let reservation = currentActiveReservation {
                print("DEBUG: active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found: \(reservation.name)")
            } else {
                print("DEBUG: no active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found.")
            }
        }
        .onChange(of: statusChanged) {
            updateCachedReservation()
            updateLateReservation()
            updateNearEndReservation()
            updateFirstUpcoming()

        }
        
        .onChange(of: showInspector) {
            updateCachedReservation()
            updateLateReservation()
            updateNearEndReservation()
            updateFirstUpcoming()
        }
        .onChange(of: changedReservation) {
            updateCachedReservation()
            updateLateReservation()
            updateNearEndReservation()
            updateFirstUpcoming()
        }
        .onChange(of: appState.selectedDate) {
            updateCachedReservation()
            updateLateReservation()
            updateNearEndReservation()
            updateFirstUpcoming()

            if let reservation = currentActiveReservation {
                print("DEBUG: active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found: \(reservation.name)")
            } else {
                print("DEBUG: no active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found.")
            }
        }
        .onChange(of: selectedEmoji) {
            if let reservation = currentActiveReservation {
                handleEmojiAssignment(reservation, selectedEmoji)
                print("DEBUG: active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found: \(reservation.name)")
            } else {
                print("DEBUG: no active reservation for table \(table.id) at time \(DateHelper.formatTime(appState.selectedDate)) found.")
            }
        }
//        .onChange(of: dragState) {
//            if dragState != .idle {
//                layoutUI.setTableTapped(table)
//            }
//        }
        .contextMenu {
            
            Button {
                print("DEBUG: FORCED Current active reservation: \(resCache.reservation(forTable: table.id, datetime: appState.selectedDate, category: selectedCategory)?.name ?? "none")")
            } label: {
                Label("Debug Print", systemImage: "ladybug.slash.fill")
            
            }
            
            Divider()
                
            
            Button {
                showEmojiPicker = true
            } label: {
                Label("Scegli Emoji", systemImage: "ellipsis.circle")
            }
            

            Divider()

            Button("Cancellazione") {
                if let reservation = currentActiveReservation {
                    handleCancelled(reservation)
                }
            }
        }
        .popover(isPresented: $showFullEmojiPicker) {
            EmojiPaletteView(selectedEmoji: $selectedEmoji)
        }
        .popover(isPresented: $showEmojiPicker) {
            EmojiSmallPicker(
                onEmojiSelected: { emoji in
                    if selectedEmoji != emoji {
                        selectedEmoji = emoji
                    } else {
                        selectedEmoji = ""
                    }
                    showEmojiPicker = false  // Dismiss the popover
                },
                showFullEmojiPicker: $showFullEmojiPicker,
                selectedEmoji: $selectedEmoji)
        }
        .position(x: tableFrame.minX, y: tableFrame.minY)
        .offset(dragOffset)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    guard !isLayoutLocked else { return }
                    state = value.translation
                }
                .onChanged { value in
                    guard !isLayoutLocked else { return }
                    dragState = .dragging(offset: value.translation)
                }
                .onEnded { value in
                    dragState = .idle  // Reset dragging state
                    handleDragEnd(
                        translation: value.translation,
                        cellSize: cellSize,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height,
                        xPos: tableFrame.minX,
                        yPos: tableFrame.minY
                    )
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                // Cancel the single-tap timer and process double-tap
                tapTimer?.invalidate()
                isDoubleTap = true  // Prevent single-tap action
                dragState = .idle
                
                    handleDoubleTap()

                // Reset double-tap state shortly after handling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isDoubleTap = false
                }
            }
        )
        .simultaneousGesture(
            TapGesture(count: 1).onEnded {
                // Start a timer for single-tap action
                tapTimer?.invalidate()  // Cancel any existing timer
                tapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                    Task { @MainActor in
                        if !isDoubleTap {
                            // Process single-tap only if no double-tap occurred
                            if let reservation = currentActiveReservation {
                                handleTap(reservation) }
                            //                        if let reservation = currentActiveReservation {
                            //                            print("UI status: showedUp: \(showedUp), isLate: \(isLate)")
                            //                        }
                        }
                    }
                }
            }
        )
    }
    

    private func updateCachedReservation() {
        if let reservation = resCache.reservation(forTable: table.id, datetime: appState.selectedDate, category: selectedCategory), reservation.status != .canceled, reservation.reservationType != .waitingList {
            currentActiveReservation = reservation
        } else {
            currentActiveReservation = nil
        }
    }
    
    private func updateLateReservation() {
        if let reservation = currentActiveReservation, resCache.lateReservations(currentTime: appState.selectedDate).contains(where: { $0.id == reservation.id }) {
            lateReservation = reservation
        } else {
            lateReservation = nil
        }
    }
    
    private func updateNearEndReservation() {
        if let reservation = currentActiveReservation, resCache.nearingEndReservations(currentTime: appState.selectedDate).contains(where: {
            $0.id == reservation.id
        }) {
            nearEndReservation = reservation } else {
                nearEndReservation = nil
            }
    }
    
    private func updateFirstUpcoming() {
        if let reservation = resCache.firstUpcomingReservation(
            forTable: table.id, date: appState.selectedDate, time: appState.selectedDate,
            category: selectedCategory) {
            firstUpcomingReservation = reservation
        } else {
            firstUpcomingReservation = nil
        }
    }
    
    // MARK: - Subviews
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

    private func reservationInfo(reservation: Reservation, tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        VStack(spacing: 2) {
            Text(reservation.name)
                .bold()
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            Text("\(reservation.numberOfPersons) p.")
                .font(.footnote)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .opacity(0.8)

            Text("\(reservation.phone)")
                .font(.footnote)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .opacity(0.8)

            if let remaining = TimeHelpers.remainingTimeString(
                endTime: reservation.endTime, currentTime: appState.selectedDate)
            {
                Text("Tempo rimasto:")
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.footnote)
                
                if reservation.id == nearEndReservation?.id {
                    
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

    private func upcomingReservationPlaceholder(
        reservation: Reservation, tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        VStack(spacing: 2) {
            Text(reservation.name)
                .bold()
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
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
        .background(Color.clear)
        .cornerRadius(8)
        .frame(width: tableFrame.width, height: tableFrame.height)
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

    // MARK: - Gestures
    private func dragGesture(
        cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat, xPos: CGFloat, yPos: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($dragOffset) { value, state, _ in
                guard !isLayoutLocked else { return }
                state = value.translation
            }
            .onChanged { value in
                guard !isLayoutLocked else { return }

                // Define a threshold distance (e.g., 10 points)
                let dragThreshold: CGFloat = 10

                switch dragState {
                case .idle:
                    // If the drag distance exceeds the threshold, move to the "started" state
                    if abs(value.translation.width) > dragThreshold
                        || abs(value.translation.height) > dragThreshold
                    {
                        dragState = .started(offset: value.translation)
                    }
                case .started, .dragging:
                    // Update the drag state with the current offset
                    dragState = .dragging(offset: value.translation)
                }
            }
            .onEnded { value in
                switch dragState {
                case .dragging(let offset):
                    // Perform the drag end operation only if it was in the dragging state
                    handleDragEnd(
                        translation: offset,
                        cellSize: cellSize,
                        tableWidth: tableFrame.width,
                        tableHeight: tableFrame.height,
                        xPos: tableFrame.minX,
                        yPos: tableFrame.minY
                    )
                default:
                    // No action needed for other states
                    break
                }

                // Reset drag state to idle
                dragState = .idle
            }
    }

    // MARK: - Actions
    private func handleTap(_ activeReservation: Reservation?) {
        guard let activeReservation = activeReservation else { return }

        var currentReservation = activeReservation

        print("1 - Status in HandleTap: \(currentReservation.status)")

        if currentReservation.status == .pending || currentReservation.status == .late {
            // Case 1: Update to .showedUp
            currentReservation.status = .showedUp
            showedUp = true
            isLate = false

            print("2 - Status in HandleTap: \(currentReservation.status)")
            reservationService.updateReservation(currentReservation)  // Ensure the data store is updated
            statusChanged += 1
        } else {
            // Case 2: Determine if the reservation is late or pending
            if let reservationStart = currentReservation.startTimeDate,
                let reservationEnd = currentReservation.endTimeDate
            {
                let calendar = Calendar.current
                let isSameDay = calendar.isDate(systemTime, inSameDayAs: reservationStart)

                // Calculate elapsed time since reservation started
                let elapsedTime = systemTime.timeIntervalSince(reservationStart)

                // Calculate the total duration of the reservation
                let reservationDuration = reservationEnd.timeIntervalSince(reservationStart)

                if isSameDay && elapsedTime >= 15 * 60 && elapsedTime <= reservationDuration {
                    // Mark as .late if the elapsed time is within bounds
                    currentReservation.status = .late
                    isLate = true
                    showedUp = false
                } else {
                    // Otherwise, mark as .pending
                    currentReservation.status = .pending
                    isLate = false
                    showedUp = false
                }

                print("2 - Status in HandleTap: \(currentReservation.status)")
                reservationService.updateReservation(currentReservation)  // Ensure the data store is updated
                statusChanged += 1
            }
        }
    }

    private func handleDoubleTap() {
        // Check if the table is occupied by filtering active reservations.
        if let reservation = currentActiveReservation {
            showInspector = true
            onEditReservation(reservation)
        } else if currentActiveReservation == nil || currentActiveReservation?.id == firstUpcomingReservation?.id {
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

        let tables = layoutUI.tables
        let combinedDate = DateHelper.combine(date: selectedDate, time: appState.selectedDate)
        layoutServices.saveTables(tables, for: combinedDate, category: selectedCategory)
        if let updatedLayout = layoutServices.cachedLayouts[
            layoutServices.keyFor(date: combinedDate, category: selectedCategory)]
        {
            print("Updated cache for \(selectedCategory):")
            for table in updatedLayout {
                print("Updated table \(table.name) at (\(table.row), \(table.column))")
            }
        }

        
        if let reservation = currentActiveReservation {
            reservationService.updateActiveReservationAdjacencyCounts(for: reservation)
        }
        let layoutKey = layoutServices.keyFor(date: combinedDate, category: selectedCategory)
        layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        layoutServices.saveToDisk()

        onTableUpdated(updatedTable)
        isLayoutReset = false
        layoutServices.currentlyDraggedTableID = nil

    }

    //    private func filterActiveReservation(for table: TableModel, in activeReservations: [Reservation]) -> Reservation? {
    //        let calendar = Calendar.current
    //
    //        // Normalize the current time for the selected date
    //        guard let normalizedCurrentTime = calendar.date(
    //            bySettingHour: calendar.component(.hour, from: currentTime),
    //            minute: calendar.component(.minute, from: currentTime),
    //            second: 0,
    //            of: calendar.startOfDay(for: selectedDate)
    //        ) else {
    //            return nil
    //        }
    //
    //        // Search in the activeReservations array
    //        return activeReservations.first { reservation in
    //            guard let startTime = reservation.startTimeDate,
    //                  let endTime = reservation.endTimeDate else {
    //                return false
    //            }
    //
    //            // Check if the table is part of the reservation
    //            return reservation.tables.contains(where: { $0.id == table.id }) &&
    //                // Check if the current time falls within the reservation's time range
    //                startTime <= normalizedCurrentTime && normalizedCurrentTime < endTime &&
    //                // Ensure the reservation matches the selected date
    //                calendar.isDate(reservation.startTimeDate ?? Date(), inSameDayAs: selectedDate)
    //        }
    //    }

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

struct EmojiButton: View {
    let emoji: Character
    @State private var animate = false

    var body: some View {
        Text(String(emoji))
            .font(.largeTitle)
            .phaseAnimator([false, true], trigger: animate) { content, phase in
                content.scaleEffect(phase ? 1.3 : 1)
            } animation: { phase in
                .bouncy(duration: phase ? 0.2 : 0.05, extraBounce: phase ? 0.7 : 0)
            }
            .onTapGesture {
                print("\(emoji) tapped")
                animate.toggle()
            }

    }

}
