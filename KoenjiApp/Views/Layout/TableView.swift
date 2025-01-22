import SwiftUI

struct TableView: View {
    let table: TableModel
    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    let currentTime: Date
    @State private var systemTime: Date = Date()
    let activeReservations: [Reservation]
    @Binding var changedReservation: Reservation?
    @Binding var isEditing: Bool

    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var tableStore: TableStore
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var layoutServices: LayoutServices
    @ObservedObject var layoutUI: LayoutUIManager

    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    @Binding var showInspector: Bool
    let onEditReservation: (Reservation) -> Void

    @GestureState private var dragOffset: CGSize = .zero

    enum DragState {
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

    @State private var statusChanged: Int = 0
    @State private var showEmojiPicker: Bool = false
    @State private var isContextMenuActive = false
    @State private var selectedEmoji: String? = nil

    @State private var tapTimer: Timer?
    @State private var isDoubleTap = false

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
        var activeReservation = filterActiveReservation(for: table) ?? nil

        let isDragging = {
            if case .dragging = dragState { return true }
            return false
        }()

        let isLunch = {
            if case .lunch = selectedCategory { return true }
            return false
        }()

        let (fillColor, idSuffix): (Color, String) = {
            if isDragging {
                return (Color(hex: "#AEAB7D").opacity(0.2), "dragging")
            } else if activeReservation != nil {
                return (isLunch ? Color.active_table_lunch : Color.active_table_dinner, "reserved")
            } else if isLayoutLocked {
                return (Color(hex: "#A3B7D2"), "locked")
            } else {
                return (Color(hex: "#A3B7D2"), "default")
            }
        }()

        let timesUp = {
            guard let activeReservation = activeReservation else { return false }
            if let endTime = DateHelper.parseTime(activeReservation.endTime),
                let currentTimeComponents = DateHelper.extractTime(time: currentTime),
                let newTime = DateHelper.normalizedInputTime(
                    time: currentTimeComponents, date: endTime),
                endTime.timeIntervalSince(newTime) <= 60 * 30
            {
                return true
            }
            return false
        }()

        let showedUp = {
            if let activeReservation = activeReservation, activeReservation.status == .showedUp {
                return true
            }
            return false
        }()

        let isLate = {
            if let activeReservation = activeReservation,
                activeReservation.status != .showedUp, !isContextMenuActive,
                let startTime = DateHelper.parseTime(activeReservation.startTime),
                let currentTimeComponents = DateHelper.extractTime(time: currentTime),
                let newtime = DateHelper.normalizedInputTime(
                    time: currentTimeComponents, date: startTime),
                newtime.timeIntervalSince(startTime) >= 15 * 60
            {
                return true
            }
            return false
        }()

        ZStack {
            // Parent ZStack for interaction
            //            Color.clear  // Makes the area outside the rectangle tappable
            //                .contentShape(RoundedRectangle(cornerRadius: 8.0))  // Expands the tappable area
            //                .frame(width: tableFrame.width + 10, height: tableFrame.height + 10)  // Adjust size to include badge
            // Main ZStack with rectangle and badge

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

                // Stroke overlay
                RoundedRectangle(cornerRadius: 12.0)
                    .stroke(
                        isDragging
                            ? Color.yellow.opacity(0.5)
                            : (isHighlighted
                                ? Color(hex: "#9DA3D0")
                                : (timesUp
                                    ? .red
                                    : (isLate
                                        ? Color(hex: "#f78457") : (showedUp ? .green : .white)))),
                        style: isDragging
                            ? StrokeStyle(
                                lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])  // Dashed when dragging
                            : StrokeStyle(lineWidth: 3)  // Solid for other states
                    )
                    .frame(
                        width: tableFrame.width,
                        height: tableFrame.height
                    )

                // Image overlay in the top-left corner

                // Reservation information or table name
                Group {
                    if let reservation = activeReservation {
                        // Active reservation exists: display reservation details.
                        reservationInfo(
                            status: timesUp,
                            reservation: reservation,
                            tableWidth: tableFrame.width,
                            tableHeight: tableFrame.height
                        )
                    } else if let upcomingRes = upcomingReservation(
                        for: table,
                        from: activeReservations,
                        selectedDate: selectedDate,
                        selectedCategory: selectedCategory,
                        currentTime: currentTime)
                    {
                        // No active reservation, but there is an upcoming reservation.
                        upcomingReservationPlaceholder(
                            reservation: upcomingRes,
                            tableWidth: tableFrame.width,
                            tableHeight: tableFrame.height
                        )
                    } else {
                        // Otherwise, just display the table name.
                        tableName(
                            name: table.name,
                            tableWidth: tableFrame.width,
                            tableHeight: tableFrame.height
                        )
                    }
                }

                if showedUp, !isContextMenuActive {
                    Image(systemName: "checkmark.circle.fill")  // Replace with your custom image or SF Symbol
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)  // Adjust size as needed
                        .foregroundColor(.green)  // Optional styling
                        .offset(x: -tableFrame.width / 2 + 13, y: -tableFrame.height / 2 + 13)  // Position in the top-left corner
                        .zIndex(2)
                }

                if let reservation = activeReservation, !isContextMenuActive {
                    Text(reservation.assignedEmoji)
                        .font(.system(size: 20))  // Match the font size to the frame of the Image
                        .frame(maxWidth: 23, maxHeight: 23)  // Same dimensions as the Image
                        .offset(x: tableFrame.width / 2 - 18, y: -tableFrame.height / 2 + 12)  // Match position
                        .zIndex(2)
                }

                if isLate {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 17, height: 17)  // Adjust size as needed
                        .foregroundColor(.yellow)  // Optional styling
                        .symbolRenderingMode(.multicolor)
                        .offset(x: -tableFrame.width / 2 + 15, y: -tableFrame.height / 2 + 15)  // Position in the top-left corner
                        .zIndex(2)
                        .onAppear {
                            print("Reservation appeared at \(Date()) - marking as late")
                            activeReservation = filterActiveReservation(for: table)
                            if var reservation = activeReservation {
                                guard reservation.reservationType != .waitingList else { return }
                                reservation.status = .late
                                reservationService.updateReservation(reservation)
                            }
                        }
                        .onDisappear {
                            print("Reservation disappeared at \(Date()) - marking as pending")
                            activeReservation = filterActiveReservation(for: table)
                            if var reservation = activeReservation {
                                guard reservation.reservationType != .waitingList else { return }
                                reservation.status = .pending
                                reservationService.updateReservation(reservation)

                            }
                        }
                }

                if timesUp {
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
        .onChange(of: statusChanged) {
            if let reservation = activeReservation {
                print("Reservation start time: \(reservation.startTime)")

            }
            print("Status change triggered!")
            print("Current time: \(currentTime)")
            activeReservation = filterActiveReservation(for: table) ?? nil
        }
        .onChange(of: selectedEmoji) {
            handleEmojiAssignment(activeReservation, selectedEmoji ?? "")
        }
        .onChange(of: changedReservation) {
            activeReservation = filterActiveReservation(for: table) ?? nil
        }
        .contextMenu {

            Button {
                showEmojiPicker = true
            } label: {
                Label("Scegli Emoji", systemImage: "ellipsis.circle")
            }

            Divider()

            Button("Cancellazione") {
                if let reservation = activeReservation {
                    handleCancelled(reservation)
                }
            }
        }
        .popover(isPresented: $showEmojiPicker, arrowEdge: .top) {
            EmojiPickerView { emoji in
                if selectedEmoji != emoji {
                    selectedEmoji = emoji
                } else {
                    selectedEmoji = ""
                }
                showEmojiPicker = false  // Dismiss the popover
            }
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
                handleDoubleTap(activeReservations)

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
                    if !isDoubleTap {
                        // Process single-tap only if no double-tap occurred
                        handleTap(activeReservation)
                    }
                }
            }
        )
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

    private func reservationInfo(
        status: Bool, reservation: Reservation, tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        VStack(spacing: 2) {
            Text(reservation.name)
                .bold()
                .font(.headline)
                .foregroundStyle(.white)
            Text("\(reservation.numberOfPersons) p.")
                .font(.footnote)
                .foregroundStyle(.white)
                .opacity(0.8)

            Text("\(reservation.phone)")
                .font(.footnote)
                .foregroundStyle(.white)
                .opacity(0.8)

            if let remaining = TimeHelpers.remainingTimeString(
                endTime: reservation.endTime, currentTime: currentTime)
            {
                Text("Tempo rimasto:")
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.footnote)

                Text("\(remaining)")
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundColor(status ? Color(hex: "#f78457") : .white)
                    .font(.footnote)
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
                .foregroundStyle(.white)
            Text("\(reservation.numberOfPersons) p.")
                .font(.footnote)
                .opacity(0.8)
                .foregroundStyle(.white)

            Text("\(reservation.phone)")
                .font(.footnote)
                .foregroundStyle(.white)
                .opacity(0.8)

            if let upcomingTime = DateHelper.timeUntilReservation(
                currentTime: currentTime,
                reservationDateString: reservation.dateString,
                reservationStartTimeString: reservation.startTime)
            {
                Text("In arrivo tra:\n\(DateHelper.formattedTime(from: upcomingTime) ?? "Errore")")
                    .bold()
                    .foregroundColor(Color(hex: "#5681ba"))
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
                .foregroundColor(Color(hex: "#5681ba"))
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
        if let index = activeReservations.firstIndex(where: { $0.id == activeReservation?.id }) {
            var currentReservation = activeReservations[index]
            if currentReservation.status == .pending || currentReservation.status == .late {

                currentReservation.status = .showedUp
                reservationService.updateReservation(currentReservation)  // Ensure the data store is updated
                statusChanged += 1
                onStatusChange()

            } else {
                if let reservationStart = DateHelper.parseTime(currentReservation.startTime),
                    currentTime.timeIntervalSince(reservationStart) >= 60 * 15
                {
                    currentReservation.status = .late
                } else {
                    currentReservation.status = .pending
                }
                reservationService.updateReservation(currentReservation)  // Ensure the data store is updated
                statusChanged += 1
                onStatusChange()
            }
        }
    }
    private func handleDoubleTap(_ activeReservations: [Reservation]) {
        let startTimeString = DateHelper.formatTime(currentTime)

        // Check if the table is occupied by filtering active reservations.
        let isOccupied = activeReservations.contains { (reservation: Reservation) in
            // The reservation must "own" the table.
            guard reservation.tables.contains(where: { $0.id == table.id }) else {
                return false
            }

            // Ensure the reservation is active (i.e., overlaps with the current time).
            let resStart = DateHelper.combineDateAndTimeStrings(
                dateString: reservation.dateString, timeString: reservation.startTime)

            return resStart <= DateHelper.combineDateAndTime(
                date: selectedDate, timeString: startTimeString) ?? Date()
        }

        if !isOccupied {
            // Table is not occupied: handle as empty.
            onTapEmpty(table)
        } else if let reservation = filterActiveReservation(for: table) {
            // Table is occupied: handle as an active reservation.
            showInspector = true
            onEditReservation(reservation)
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
        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
        layoutServices.saveTables(tables, for: combinedDate, category: selectedCategory)
        if let updatedLayout = layoutServices.cachedLayouts[
            layoutServices.keyFor(date: combinedDate, category: selectedCategory)]
        {
            print("Updated cache for \(selectedCategory):")
            for table in updatedLayout {
                print("Updated table \(table.name) at (\(table.row), \(table.column))")
            }
        }

        let layoutKey = layoutServices.keyFor(date: combinedDate, category: selectedCategory)
        layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        layoutServices.saveToDisk()

        onTableUpdated(updatedTable)
        isLayoutReset = false
        layoutServices.currentlyDraggedTableID = nil

    }

    private func filterActiveReservation(for table: TableModel) -> Reservation? {
        let calendar = Calendar.current

        return store.reservations.first { reservation in
            // Check if the table is assigned to this reservation
            reservation.tables.contains(where: { $0.id == table.id })

                && reservation.status != .canceled
                && reservation.reservationType != .waitingList
                // Check if the reservation date matches the selected date
                && reservation.dateString == DateHelper.formatDate(selectedDate)

                // Check if the current time falls within the reservation's time range
                && {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    timeFormatter.timeZone = TimeZone.current

                    guard let startTime = timeFormatter.date(from: reservation.startTime),
                        let endTime = timeFormatter.date(from: reservation.endTime),
                        let normalizedStartTime = calendar.date(
                            bySettingHour: calendar.component(.hour, from: startTime),
                            minute: calendar.component(.minute, from: startTime),
                            second: 0,
                            of: calendar.startOfDay(for: selectedDate)),
                        let normalizedEndTime = calendar.date(
                            bySettingHour: calendar.component(.hour, from: endTime),
                            minute: calendar.component(.minute, from: endTime),
                            second: 0,
                            of: calendar.startOfDay(for: selectedDate)),
                        let normalizedCurrentTime = calendar.date(
                            bySettingHour: calendar.component(.hour, from: currentTime),
                            minute: calendar.component(.minute, from: currentTime),
                            second: 0,
                            of: calendar.startOfDay(for: selectedDate))
                    else {
                        return false
                    }

                    return normalizedCurrentTime >= normalizedStartTime
                        && normalizedCurrentTime < normalizedEndTime
                }()
        }
    }
}

//activeReservations.filter { reservation in
//    let filteredReservations = reservation.status != .canceled

/// Returns a Date object that represents the reservation's start date and time.
/// Adjust date formats as needed.
func reservationStartDate(for reservation: Reservation) -> Date? {
    let calendar = Calendar.current

    // Assuming reservation.dateString is something like "2025-01-18"
    // and reservation.startTime is something like "18:00"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    timeFormatter.locale = Locale(identifier: "en_US_POSIX")

    guard let baseDate = dateFormatter.date(from: reservation.dateString),
        let timeDate = timeFormatter.date(from: reservation.startTime)
    else {
        return nil
    }

    let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
    var fullComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
    fullComponents.hour = timeComponents.hour
    fullComponents.minute = timeComponents.minute

    return calendar.date(from: fullComponents)
}

/// Returns the time window for the given reservation category on the provided date.
func timeWindow(for category: Reservation.ReservationCategory, on date: Date) -> (
    start: Date, end: Date
)? {
    let calendar = Calendar.current
    switch category {
    case .lunch:
        guard let start = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date),
            let end = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date)
        else {
            return nil
        }
        return (start, end)
    case .dinner:
        guard let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date),
            let end = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: date)
        else {
            return nil
        }
        return (start, end)
    case .noBookingZone:
        return nil
    }
}

/// Returns the first upcoming reservation for the given table that:
/// 1. Is on the selected date and in the selected category.
/// 2. Has a start time in the future (relative to currentTime).
/// 3. Has a start time that falls within the category's time window.
func upcomingReservation(
    for table: TableModel,
    from activeReservations: [Reservation],
    selectedDate: Date,
    selectedCategory: Reservation.ReservationCategory,
    currentTime: Date
) -> Reservation? {

    // Get the time window for the category on the selected date.
    guard let window = timeWindow(for: selectedCategory, on: selectedDate) else {
        return nil
    }

    // Filter reservations that:
    // - "Own" the table.
    // - Are in the selected category.
    // - Are on the selected date.
    // - Have a start time within the time window (window.start <= resStart <= window.end).
    // - Have a start time in the future relative to `currentTime`.
    let filteredReservations = activeReservations.filter { reservation in
        guard reservation.tables.contains(where: { $0.id == table.id }) else {
            return false
        }

        guard reservation.status != .canceled else {
            return false
        }

        guard reservation.reservationType != .waitingList else {
            return false
        }

        guard reservation.category == selectedCategory else {
            return false
        }

        let reservationDate = DateHelper.parseDate(reservation.dateString) ?? selectedDate
        guard Calendar.current.isDate(selectedDate, inSameDayAs: reservationDate) else {
            return false
        }

        guard let resStart = reservationStartDate(for: reservation) else {
            return false
        }

        if !(resStart >= currentTime && resStart <= window.end) {
            return false
        }

        return true
    }

    // Sort by start time (soonest first)
    let sortedReservations = filteredReservations.sorted {
        let start1 = reservationStartDate(for: $0) ?? Date.distantFuture
        let start2 = reservationStartDate(for: $1) ?? Date.distantFuture
        return start1 < start2
    }

    // Return the soonest upcoming reservation, if any.
    return sortedReservations.first
}

struct EmojiPickerView: View {
    let onEmojiSelected: (String) -> Void
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
