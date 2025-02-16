import EmojiPalette
import SwiftUI

// MARK: - Drag State

enum DragState: Equatable {
    case idle
    case dragging(offset: CGSize)
    case started(offset: CGSize)
}

// MARK: - Main TableView

struct TableView: View {
    // MARK: Environment Objects & Dependencies
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState

    @ObservedObject var notifsManager = NotificationManager.shared

    @Environment(LayoutUIManager.self) var layoutUI
    @Environment(LayoutUnitViewModel.self) var unitView
    @Environment(\.colorScheme) var colorScheme
    @Environment(ClusterManager.self) var clusterManager

    // MARK: Local State & Bindings
    @State var tableView: TableViewModel = TableViewModel()
    private let normalizedTimeCache = NormalizedTimeCache()

    let table: TableModel
    let clusters: [CachedCluster]
    let onTapEmpty: (TableModel) -> Void
    let onStatusChange: () -> Void
    let onEditReservation: (Reservation) -> Void
    let isLayoutLocked: Bool
    let animationNamespace: Namespace.ID
    let onTableUpdated: (TableModel) -> Void

    @Binding var statusChanged: Int

    @GestureState private var dragOffset: CGSize = .zero
    @State private var cachedRemainingTime: String?
    @State private var lastRefreshDate: Date? = Date.distantPast

    @State private var isVisible: Bool = true
    
    
    // MARK: Computed Properties
    private var cellSize: CGFloat { env.gridData.cellSize }

    private var tableFrame: CGRect {
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }

    private var isHighlighted: Bool {
        env.layoutServices.tableAnimationState[table.id] ?? false
    }

    private var isDragging: Bool {
        if case .dragging = tableView.dragState { return true }
        return false
    }

    // MARK: - Body
    var body: some View {

        // Determine fill color and an ID suffix for matched geometry
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

        return ZStack {
            mainContent(fillColor: fillColor, idSuffix: idSuffix)
        }
        .position(x: tableFrame.minX, y: tableFrame.minY)
        .offset(dragOffset)
        .gesture(combinedGestures)
        .onAppear {
            updateResData(appState.selectedDate, refreshedKey: "onAppear", forceUpdate: true)
        }
        .onChange(of: unitView.showInspector) {
            updateResData(appState.selectedDate, refreshedKey: "showInspector")
        }
        .onChange(of: unitView.isLayoutLocked) {
            updateTableVisibility()
        }
//        .onChange(of: appState.changedReservation) {
//            updateResData(
//                appState.selectedDate, refreshedKey: "changedReservation", forceUpdate: true)
//        }
        .onChange(of: appState.selectedDate) {
            updateResData(
                appState.selectedDate, refreshedKey: "appState.selectedDate", forceUpdate: true)
        }
        .onReceive(env.store.$reservations) { new in
            print("DEBUG: env.store.$reservations sent changes!")
            updateResData(
                appState.selectedDate, refreshedKey: "env.store.reservations")
        }
        .onChange(of: appState.selectedCategory) {
            updateResData(
                appState.selectedDate, refreshedKey: "appState.selectedCategory", forceUpdate: true)
        }
        .onChange(of: tableView.selectedEmoji) {
            handleEmojiAssignment(tableView.currentActiveReservation, tableView.selectedEmoji)
        }
//        .onChange(of: tableView.currentActiveReservation?.status) {
//            updateResData(appState.selectedDate, refreshedKey: "status")
//        }

    }
}

// MARK: - Main Content & Overlay Subviews

extension TableView {
    /// Combines the background shape, stroke overlay, marks, and text overlays.
    private func mainContent(fillColor: Color, idSuffix: String) -> some View {
        ZStack {
            // Base colored rectangle with matched geometry effect
            RoundedRectangle(cornerRadius: 12.0)
                .fill(fillColor)
                .frame(width: tableFrame.width, height: tableFrame.height)
                .matchedGeometryEffect(
                    id:
                        "\(table.id)-\(appState.selectedDate)-\(appState.selectedCategory.rawValue)-\(idSuffix)-\(UUID().uuidString)",
                    in: animationNamespace
                )

            // Stroke overlay based on reservation state
            strokeOverlay

            // Group of marks and overlays
            overlayMarksAndText()
                .animation(
                    .easeInOut(duration: 0.5), value: tableView.currentActiveReservation?.status)
        }
        .transition(.opacity)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: isVisible)
        .contextMenu {
            Button {
                print(
                    "DEBUG: FORCED Current active reservation: \(env.resCache.reservation(forTable: table.id, datetime: appState.selectedDate, category: appState.selectedCategory)?.name ?? "none")"
                )
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
                    tableView.selectedEmoji = (tableView.selectedEmoji != emoji ? emoji : "")
                    tableView.showEmojiPicker = false
                },
                showFullEmojiPicker: $tableView.showFullEmojiPicker,
                selectedEmoji: $tableView.selectedEmoji
            )
        }
    }

    private var strokeOverlay: some View {

        Group {

            if let reservation = tableView.currentActiveReservation,
                reservation.id != tableView.nearEndReservation?.id
            {
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
                                lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])
                            : StrokeStyle(lineWidth: 3)
                    )
                    .frame(width: tableFrame.width, height: tableFrame.height)
            } else if tableView.nearEndReservation != nil {
                RoundedRectangle(cornerRadius: 12.0)
                    .stroke(
                        isDragging
                            ? Color.yellow.opacity(0.5)
                            : (isHighlighted ? Color(hex: "#9DA3D0") : .red),
                        style: isDragging
                            ? StrokeStyle(
                                lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])
                            : StrokeStyle(lineWidth: 3)
                    )
                    .frame(width: tableFrame.width, height: tableFrame.height)
            } else if tableView.currentActiveReservation == nil {
                RoundedRectangle(cornerRadius: 12.0)
                    .stroke(
                        isDragging
                            ? Color.yellow.opacity(0.5)
                            : (isHighlighted ? Color(hex: "#9DA3D0") : .white),
                        style: isDragging
                            ? StrokeStyle(
                                lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3])
                            : StrokeStyle(lineWidth: 3)
                    )
                    .frame(width: tableFrame.width, height: tableFrame.height)
            }
        }
    }

    /// Overlays for marks (e.g., checkmark, emoji, late, near-end) and the reservation info/text.
    @ViewBuilder
    private func overlayMarksAndText() -> some View {
        ZStack {
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
                        tableView.lateReservation != nil
                            && tableView.currentActiveReservation != nil
                            && tableView.currentActiveReservation?.status != .showedUp ? 1 : 0
                    )
                nearEndMark()
                    .opacity(tableView.nearEndReservation != nil ? 1 : 0)

            }
            .shadow(radius: 3)
            .zIndex(1)

            Group {
                reservationInfo(
                    tableWidth: tableFrame.width,
                    tableHeight: tableFrame.height
                )
                .opacity(tableView.currentActiveReservation != nil ? 1 : 0)

                upcomingReservationPlaceholder(
                    tableWidth: tableFrame.width,
                    tableHeight: tableFrame.height
                )
                .opacity(
                    tableView.currentActiveReservation == nil
                        && tableView.firstUpcomingReservation != nil ? 1 : 0)

                tableName(
                    name: table.name,
                    tableWidth: tableFrame.width,
                    tableHeight: tableFrame.height
                )
                .opacity(
                    tableView.currentActiveReservation == nil
                        && tableView.firstUpcomingReservation == nil ? 1 : 0)
            }
            .zIndex(2)
        }
    }

    // MARK: - Mark Subviews
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
            .foregroundStyle(.yellow, .orange)
            .symbolRenderingMode(.palette)
            .offset(x: tableFrame.width / 2 - 15, y: tableFrame.height / 2 - 15)
            .zIndex(4)
    }

    private func lateMark() -> some View {
        Image(systemName: "clock.badge.exclamationmark.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 17, height: 17)
            .foregroundColor(.yellow)
            .symbolRenderingMode(.multicolor)
            .offset(x: -tableFrame.width / 2 + 15, y: -tableFrame.height / 2 + 15)
            .zIndex(2)
    }

    // MARK: - Reservation Text Overlays
    @ViewBuilder
    private func reservationInfo(
        tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        if let reservation = tableView.currentActiveReservation {
            VStack(spacing: 2) {
                Text(reservation.name)
                    .bold()
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(reservation.numberOfPersons) p.")
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                Text("\(reservation.phone)")
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .opacity(0.8)
                if let remaining = cachedRemainingTime {
                    Text("Tempo rimasto:")
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.footnote)
                    if reservation.id == tableView.nearEndReservation?.id {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(radius: 2)
                                .frame(width: tableFrame.width - 10, height: 20)
                            Text(remaining)
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(hex: "#bf5b34"))
                                .font(.footnote)
                        }
                    } else {
                        Text(remaining)
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .font(.footnote)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 2)
                            .frame(width: tableFrame.width - 10, height: 20)
                        Text("Terminata")
                            .bold()
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: "#bf5b34"))
                            .font(.footnote)
                    }
                    .padding(.top)
                }
            }
            .background(Color.clear)
            .cornerRadius(8)
            .frame(width: tableFrame.width, height: tableFrame.height)
        }
    }

    @ViewBuilder
    private func upcomingReservationPlaceholder(
        tableWidth: CGFloat, tableHeight: CGFloat
    ) -> some View {
        if let reservation = tableView.firstUpcomingReservation {
            VStack(spacing: 2) {
                Text(reservation.name)
                    .bold()
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
                    Text(
                        "In arrivo tra:\n\(DateHelper.formattedTime(from: upcomingTime) ?? "Errore")"
                    )
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
}

// MARK: - Gesture Definitions

extension TableView {
    private var combinedGestures: some Gesture {
        doubleTapGesture()
            .exclusively(
                before: tapGesture()
                    .exclusively(before: dragGesture()))
    }

    private func tapGesture() -> some Gesture {
        TapGesture(count: 1).onEnded {
            tableView.tapTimer?.invalidate()
            tableView.tapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                Task { @MainActor in
                    if !tableView.isDoubleTap, let reservation = tableView.currentActiveReservation
                    {
                        handleTap(reservation)
                    }
                }
            }
        }
    }

    private func doubleTapGesture() -> some Gesture {
        TapGesture(count: 2).onEnded {
            tableView.tapTimer?.invalidate()
            tableView.isDoubleTap = true
            tableView.dragState = .idle
            handleDoubleTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                tableView.isDoubleTap = false
            }
        }
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in
                guard !isLayoutLocked else { return }
                state = value.translation
            }
            .onChanged { value in
                guard !isLayoutLocked else { return }
                tableView.dragState = .dragging(offset: value.translation)
            }
            .onEnded { value in
                tableView.dragState = .idle
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

// MARK: - Helper Methods & Reservation Updates

extension TableView {
    private func updateTableVisibility() {
        print("DEBUG: updating table visibility")
        print("DEBUG: clusters \(clusters)")
        
        for cluster in clusters {
            if cluster.tableIDs.first(where: { $0 == table.id}) != nil && cluster.date.isSameDay(as: appState.selectedDate) && unitView.isLayoutLocked {
                print("DEBUG: setting table to hidden")
                isVisible = false
            } else if cluster.tableIDs.first(where: { $0 == table.id}) != nil && !unitView.isLayoutLocked {
                print("DEBUG: setting table to visible")
                isVisible = true
            } else {
                isVisible = true
            }
        }
    }
    
    private func updateResData(_ date: Date, refreshedKey: String, forceUpdate: Bool = false) {
        updateTableVisibility()
        let now = Date()
        // if we already refreshed in last 0.5 seconds, skip
        guard now.timeIntervalSince(lastRefreshDate ?? Date()) > 0.5 else {
            return
        }
        lastRefreshDate = now
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let formattedDate = formatter.string(from: date)
        let key =
            "\(formattedDate)-\(refreshedKey)-\(appState.selectedCategory.rawValue)-\(table.id)"

//        if !forceUpdate {
//            if tableView.currentActiveReservation != nil || tableView.lateReservation != nil
//                || tableView.firstUpcomingReservation != nil || tableView.nearEndReservation != nil
//            {
//
//                guard !appState.lastRefreshedKeys.contains(key) else {
//                    print("⚠️ Skipping update, key already exists!")
//                    return
//                }
//            }
//        }
//        print("New key: \(key)")
//        appState.lastRefreshedKeys.append(key)
//        print("Key added!")

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

        let reservationEnd = tableView.currentActiveReservation?.endTimeDate ?? Date()
        let timeRemaining = reservationEnd.timeIntervalSince(appState.selectedDate)  // Get time difference

        print("🕒 Time remaining until reservation ends: \(timeRemaining) seconds")

        if let lastNotification = notifsManager.notifications.first(where: {
            $0.type == .nearEnd && $0.reservation == tableView.currentActiveReservation
        }) {
            guard date.timeIntervalSince(lastNotification.date) >= 60 * 5 else {
                print("Not enough time since last notified. Skipping notification!")
                return
            }
        }
        
        guard let reservation = tableView.currentActiveReservation else { return }

        if timeRemaining <= 30 * 60 && timeRemaining > 0 {
            Task {
                
                await notifsManager.addNotification(
                    title: "Prenotazione in scadenza",
                    message:
                        "Prenotazione a nome di \(tableView.currentActiveReservation?.name ?? "Errore") sta per terminare (-\(Int(timeRemaining / 60)) minuti).",
                    type: .nearEnd, reservation: reservation
                )
            }
        }
    }

    private func updateCachedReservation(_ date: Date) {
        if let reservation = env.resCache.reservation(
            forTable: table.id, datetime: date, category: appState.selectedCategory),
            reservation.status != .canceled,
           reservation.status != .deleted,
           reservation.status != .toHandle,
            reservation.reservationType != .waitingList
        {
            tableView.currentActiveReservation = reservation
        } else {
            tableView.currentActiveReservation = nil
        }
    }

    private func updateLateReservation(_ date: Date) {
        // 1) Check if the current reservation is late.
        print("Called updateLateReservation!")
        print("Notifications: \(notifsManager.notifications)")
        if let reservation = tableView.currentActiveReservation,
           env.resCache.lateReservations(currentTime: date).contains(where: { $0.id == reservation.id }) {

            tableView.lateReservation = reservation

            print("Notifications 2: \(notifsManager.notifications)")

            // 2) Look for a *late* notification, not .nearEnd.
            if let lastNotification = notifsManager.notifications.first(where: {
                $0.type == .late && $0.reservation == reservation
            }) {
                // 3) Compare "now" minus "last notification time":
                let timeElapsed = date.timeIntervalSince(lastNotification.date)
                print("Time elapsed = \(timeElapsed)")
                guard timeElapsed >= 5 * 60 else {
                    print("Not enough time since last notified. Skipping notification!")
                    return
                }
                
                
                // 4) Otherwise, send a new .late notification
                Task { @MainActor in
                    await notifsManager.addNotification(
                        title: "\(reservation.name): ritardo",
                        message: "Prenotazione a nome di \(reservation.name) è in ritardo.",
                        type: .late,
                        reservation: reservation
                    )
                }
            } else {
                Task { @MainActor in
                    await notifsManager.addNotification(
                        title: "\(reservation.name): ritardo",
                        message: "Prenotazione a nome di \(reservation.name) è in ritardo.",
                        type: .late,
                        reservation: reservation
                    )
                }
            }

        } else {
            tableView.lateReservation = nil
        }
    }

    private func updateNearEndReservation(_ date: Date) {
        if let reservation = tableView.currentActiveReservation,
            env.resCache.nearingEndReservations(currentTime: date).contains(where: {
                $0.id == reservation.id
            })
        {
            tableView.nearEndReservation = reservation
        } else {
            tableView.nearEndReservation = nil
        }
    }

    private func updateFirstUpcoming(_ date: Date) {
        if let reservation = env.resCache.firstUpcomingReservation(
            forTable: table.id,
            date: date,
            time: date,
            category: appState.selectedCategory)
        {
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
        env.reservationService.updateReservation(updatedReservation) {
            appState.changedReservation = updatedReservation
        }
    }

    private func handleEmojiAssignment(_ activeReservation: Reservation?, _ emoji: String) {
        guard var reservationActive = activeReservation else { return }
        print("Emoji: \(emoji)")
        reservationActive.assignedEmoji = emoji
        env.reservationService.updateReservation(reservationActive) {
            appState.changedReservation = reservationActive
        }
        onStatusChange()
    }

    private func handleTap(_ activeReservation: Reservation) {
        var currentReservation = activeReservation
        print("1 - Status in HandleTap: \(currentReservation.status)")
        if currentReservation.status == .pending || currentReservation.status == .late {
            currentReservation.status = .showedUp
            tableView.showedUp = true
            tableView.isLate = false
            print("2 - Status in HandleTap: \(currentReservation.status)")
            env.reservationService.updateReservation(
                    activeReservation, newReservation: currentReservation) {
                        appState.changedReservation = currentReservation
                    }
        } else if currentReservation.status == .showedUp {
            currentReservation.status =
                (tableView.lateReservation?.id == currentReservation.id ? .late : .pending)
            print("2 - Status in HandleTap: \(currentReservation.status)")
            env.reservationService.updateReservation(
                    activeReservation, newReservation: currentReservation) {
                        appState.changedReservation = currentReservation
                    }
        }
    }

    private func handleDoubleTap() {
        if let reservation = tableView.currentActiveReservation {
            unitView.showInspector = true
            onEditReservation(reservation)
        } else if tableView.currentActiveReservation == nil
            || tableView.currentActiveReservation?.id == tableView.firstUpcomingReservation?.id
        {
            onTapEmpty(table)
        }
    }

    private func handleDragEnd(
        translation: CGSize, cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat,
        xPos: CGFloat, yPos: CGFloat
    ) {
        layoutUI.isDragging = false
        guard !isLayoutLocked else {
            env.layoutServices.currentlyDraggedTableID = nil
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

        // Check for blockage before moving the table
        if !env.gridData.isBlockage(proposedFrame) {
            print("Blockage detected! Table move rejected.")
            env.layoutServices.currentlyDraggedTableID = nil
            return
        }

        clusterManager.lastLayoutSignature = env.layoutServices.computeLayoutSignature(
            tables: layoutUI.tables)

        // Delegate the move to LayoutUIManager
        layoutUI.attemptMove(
            table: table, to: (row: newRow, col: newCol), for: appState.selectedDate,
            activeTables: layoutUI.tables,
            category: appState.selectedCategory
        )

        // Retrieve the updated table from layoutUI.tables
        guard let updatedTable = layoutUI.tables.first(where: { $0.id == table.id }) else {
            print("Error: Updated table not found after move!")
            return
        }

        let combinedDate = DateHelper.combine(
            date: appState.selectedDate, time: appState.selectedDate)
        if let updatedLayout = env.layoutServices.cachedLayouts[
            env.layoutServices.keyFor(date: combinedDate, category: appState.selectedCategory)]
        {
            print("Updated cache for \(appState.selectedCategory):")
            for table in updatedLayout {
                print("Updated table \(table.name) at (\(table.row), \(table.column))")
            }
        }

        if let reservation = tableView.currentActiveReservation {
            env.reservationService.updateActiveReservationAdjacencyCounts(for: reservation)
        }
        let layoutKey = env.layoutServices.keyFor(
            date: combinedDate, category: appState.selectedCategory)
        env.layoutServices.cachedLayouts[layoutKey] = layoutUI.tables
        env.layoutServices.saveToDisk()

        onTableUpdated(updatedTable)
        unitView.isLayoutReset = false
        env.layoutServices.currentlyDraggedTableID = nil
    }
}
