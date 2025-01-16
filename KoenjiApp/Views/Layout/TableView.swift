import SwiftUI

struct TableView: View {
    let table: TableModel
    let selectedDate: Date
    let selectedCategory: Reservation.ReservationCategory
    let currentTime: Date
    let activeReservations: [Reservation]
    
    @EnvironmentObject var gridData: GridData
    @EnvironmentObject var store: ReservationStore
    @EnvironmentObject var reservationService: ReservationService
    @ObservedObject var layoutUI: LayoutUIManager

    let onTapEmpty: () -> Void
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
    
    
    
    @State private var isDragging: Bool = false // State to track dragging
    @State private var isHeld: Bool = false // State for long press hold
    @State private var hasMoved: Bool = false
    let isLayoutLocked: Bool
    @Binding var isLayoutReset: Bool
    let animationNamespace: Namespace.ID // Animation namespace from LayoutView
    let onTableUpdated: (TableModel) -> Void

    @State private var statusChanged: Int = 0
    @State private var showEmojiPicker: Bool = false
    @State private var isContextMenuActive = false

        
    private var cellSize: CGFloat { return layoutUI.cellSize }
    
    private var tableFrame: CGRect {
        let cellSize = layoutUI.cellSize
        let width = CGFloat(table.width) * cellSize
        let height = CGFloat(table.height) * cellSize
        let xPos = CGFloat(table.column) * cellSize + width / 2
        let yPos = CGFloat(table.row) * cellSize + height / 2
        return CGRect(x: xPos, y: yPos, width: width, height: height)
    }

    var body: some View {
        // Determine if the table is highlighted
        let isHighlighted = store.tableAnimationState[table.id] ?? false
        
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
        
        ZStack {
            // Parent ZStack for interaction
                Color.clear // Makes the area outside the rectangle tappable
                .contentShape(RoundedRectangle(cornerRadius: 8.0)) // Expands the tappable area
                    .frame(width: tableFrame.width + 10, height: tableFrame.height + 10) // Adjust size to include badge
            // Main ZStack with rectangle and badge
            
            ZStack {
                
                let uniqueKey = UUID().uuidString
                
                // Determine table style and ID suffix dynamically
                
                
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(fillColor)
                    .frame(width: tableFrame.width * (isDragging ? 1.2 : 1.0), height: tableFrame.height * (isDragging ? 1.2 : 1.0))
                    .matchedGeometryEffect(
                        id: "\(table.id)-\(selectedDate)-\(selectedCategory.rawValue)-\(idSuffix)-\(uniqueKey)",
                        in: animationNamespace
                    )
                
                // Stroke overlay
                RoundedRectangle(cornerRadius: 8.0)
                    .stroke(
                        isDragging ? Color.yellow.opacity(0.5) :
                            (isHighlighted ? Color(hex: "#9DA3D0") :
                                (isLayoutLocked ? (isLunch ? Color.layout_locked_lunch : Color.layout_locked_dinner) : (isLunch ? Color.layout_unlocked_lunch : Color.layout_unlocked_dinner))),
                        style: isDragging
                        ? StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [3, 3]) // Dashed when dragging
                        : StrokeStyle(lineWidth: (isLayoutLocked ? 3 : 2)) // Solid for other states
                    )
                    .frame(
                        width: tableFrame.width,
                        height: tableFrame.height
                    )
                
                // Image overlay in the top-left corner
                
                
                // Reservation information or table name
                Group {
                    if let reservation = activeReservation {
                        reservationInfo(reservation: reservation, tableWidth: tableFrame.width, tableHeight: tableFrame.height)
                    } else {
                        tableName(name: table.name, tableWidth: tableFrame.width, tableHeight: tableFrame.height)
                    }
                }
                
                if let activeReservation = activeReservation, activeReservation.status == .showedUp, !isContextMenuActive {
                    Image(systemName: "checkmark.seal.fill") // Replace with your custom image or SF Symbol
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25) // Adjust size as needed
                        .foregroundColor(.green ) // Optional styling
                        .offset(x: -tableFrame.width / 2 + 15, y: -tableFrame.height / 2 + 15) // Position in the top-left corner
                        .zIndex(2)
                }
                
                if let reservation = activeReservation, !isContextMenuActive {
                    Text(reservation.assignedEmoji ?? "")
                        .font(.system(size: 25)) // Match the font size to the frame of the Image
                        .frame(maxWidth: 28, maxHeight: 28) // Same dimensions as the Image
                        .offset(x: tableFrame.width / 2 - 18, y: -tableFrame.height / 2 + 15) // Match position
                        .zIndex(2)
                }
                
                if let activeReservation = activeReservation,
                   activeReservation.status != .showedUp, !isContextMenuActive,
                   let startTime = DateHelper.parseTime(activeReservation.startTime),
                   let currentTimeComponents = DateHelper.extractTime(time: currentTime) {
                    
                    // Create normalized startTime and subtract one hour
                    let calendar = Calendar.current
                    let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                    
                    // Build a new Date object for adjustedStartTime
                    if let adjustedStartTime = calendar.date(bySettingHour: (startTimeComponents.hour ?? 0),
                                                             minute: startTimeComponents.minute ?? 0,
                                                             second: 0,
                                                             of: currentTime), // Use currentTime to align the date
                       let normalizedCurrentTime = calendar.date(bySettingHour: currentTimeComponents.hour ?? 0,
                                                                 minute: currentTimeComponents.minute ?? 0,
                                                                 second: 0,
                                                                 of: currentTime) { // Use currentTime to align the date
                        
                        // Compare the times
                        if normalizedCurrentTime.timeIntervalSince(adjustedStartTime) >= 15 * 60 { // 15 minutes in seconds
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30) // Adjust size as needed
                                .foregroundColor(.orange) // Optional styling
                                .offset(x: -tableFrame.width / 2, y: -tableFrame.height / 2) // Position in the top-left corner
                                .zIndex(2)
                        }
                    }
                }
                
                //            if let activeReservation = activeReservation, activeReservation.status == .pending {
                //                Image(systemName: "")
                //                    .resizable()
                //                    .scaledToFit()
                //                    .frame(width: 20, height: 20)
                //                    .offset(x: -tableFrame.width / 2, y: -tableFrame.height / 2)
                //                    .zIndex(2)
                //            }
                
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
        .contextMenu {
            // Your context menu buttons
            Button("Delete") {
                if let reservation = activeReservation {
                    handleDelete(reservation)
                }
            }
            
            if let _ = activeReservation {
                ForEach(["❤️", "💀", "🥗", "🍣", "🍪"], id: \.self) { emoji in
                    Button {
                        activeReservation?.assignedEmoji = emoji
                        reservationService.updateReservation(activeReservation!)
                        statusChanged += 1
                        onStatusChange()
                    } label: {
                        Text(emoji)
                    }
                }

                Button {
                    showEmojiPicker = true
                } label: {
                    Label("Pick Emoji", systemImage: "ellipsis.circle")
                }
            } // Optional: Add padding if needed
        }
        .sheet(isPresented: $showEmojiPicker) {
            if let _ = activeReservation {
                let assignedEmojiBinding = Binding(
                    get: { activeReservation?.assignedEmoji ?? "" },
                    set: {
                        activeReservation?.assignedEmoji = $0
                        reservationService.updateReservation(activeReservation!)
                        statusChanged += 1
                        onStatusChange()
                    }
                )
                EmojiPickerMenuView(selectedEmoji: assignedEmojiBinding, isPresented: $showEmojiPicker)

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
                    dragState = .idle // Reset dragging state
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
        .simultaneousGesture(TapGesture(count: 1).onEnded {_ in
            handleTap(activeReservation)
        })
        .simultaneousGesture(TapGesture(count: 2).onEnded {_ in
            dragState = .idle
            handleDoubleTap()
        })
    }

    // MARK: - Subviews
    private func handleDelete(_ reservation: Reservation) {
        if let idx = store.reservations.firstIndex(where: { $0.id == reservation.id }) {
            reservationService.deleteReservations(at: IndexSet(integer: idx))
        }
    }
    
    private func reservationInfo(reservation: Reservation, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text(reservation.name)
                .bold()
                .font(.headline)
            Text("\(reservation.numberOfPersons) pers.")
                .font(.footnote)
                .opacity(0.8)

            Text("\(reservation.phone)")
                .font(.footnote)
                .opacity(0.8)

            if let remaining = TimeHelpers.remainingTimeString(endTime: reservation.endTime, currentTime: currentTime) {
                Text("Rimasto: \(remaining)")
                    .foregroundColor(Color(hex: "#B4231F"))
                    .font(.footnote)
            }
        }
        .background(Color.clear)
        .cornerRadius(8)
        .frame(width: tableFrame.width, height: tableFrame.height)
    }

    private func tableName(name: String, tableWidth: CGFloat, tableHeight: CGFloat) -> some View {
        Text(name)
            .bold()
            .foregroundColor(.blue)
            .font(.headline)
            .padding(4)
            .background(Color.white.opacity(0.7))
            .cornerRadius(8)
            .frame(width: tableFrame.width - 5, height: tableFrame.height - 5)
    }

    // MARK: - Gestures
    private func dragGesture(cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat, xPos: CGFloat, yPos: CGFloat) -> some Gesture {
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
                    if abs(value.translation.width) > dragThreshold || abs(value.translation.height) > dragThreshold {
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
            if currentReservation.status == .pending {
               
                currentReservation.status = .showedUp
                reservationService.updateReservation(currentReservation) // Ensure the data store is updated
                statusChanged += 1
                onStatusChange()
                
            } else {
                currentReservation.status = .pending
                reservationService.updateReservation(currentReservation) // Ensure the data store is updated
                statusChanged += 1
                onStatusChange()
            }
        }
    }
    private func handleDoubleTap() {
        

        let startTimeString = DateHelper.formatTime(currentTime)
        let endTimeString = TimeHelpers.calculateEndTime(startTime: startTimeString, category: selectedCategory)

        let isOccupied = store.tableAssignmentService.isTableOccupied(
            table,
            reservations: store.reservations,
            date: selectedDate,
            startTime: startTimeString,
            endTime: endTimeString
        )

        if !isOccupied {
            onTapEmpty()
        } else if let reservation = filterActiveReservation(for: table) {
            showInspector = true
            onEditReservation(reservation)
        }
    }

    private func handleDragEnd(translation: CGSize, cellSize: CGFloat, tableWidth: CGFloat, tableHeight: CGFloat, xPos: CGFloat, yPos: CGFloat) {
        layoutUI.isDragging = false
        guard !isLayoutLocked else {
            store.currentlyDraggedTableID = nil
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
            store.currentlyDraggedTableID = nil
            return
        }
        
        // Delegate the move to LayoutUIManager
        layoutUI.attemptMove(table: table, to: (row: newRow, col: newCol), for: selectedDate, activeTables: layoutUI.tables)
        
        // Retrieve the updated table from layoutUI.tables
        guard let updatedTable = layoutUI.tables.first(where: { $0.id == table.id }) else {
            print("Error: Updated table not found after move!")
            return
        }
        
        let tables = layoutUI.tables
        let combinedDate = DateHelper.combine(date: selectedDate, time: currentTime)
        store.saveTables(tables, for: combinedDate, category: selectedCategory)
        if let updatedLayout = store.cachedLayouts[store.keyFor(date: combinedDate, category: selectedCategory)] {
            print("Updated cache for \(selectedCategory):")
            for table in updatedLayout {
                print("Updated table \(table.name) at (\(table.row), \(table.column))")
            }
        }
        
        let layoutKey = store.keyFor(date: combinedDate, category: selectedCategory)
        store.cachedLayouts[layoutKey] = layoutUI.tables
        store.saveToDisk()
        
        onTableUpdated(updatedTable)
        isLayoutReset = false
        store.currentlyDraggedTableID = nil
        
    }
    
    private func filterActiveReservation(for table: TableModel) -> Reservation? {
        let calendar = Calendar.current
            
            return activeReservations.first { reservation in
                // Check if the table is assigned to this reservation
                reservation.tables.contains(where: { $0.id == table.id }) &&
                
                // Check if the reservation date matches the selected date
                reservation.dateString == DateHelper.formatDate(selectedDate) &&
                
                // Check if the current time falls within the reservation's time range
                {
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
                              of: calendar.startOfDay(for: selectedDate)) else {
                        return false
                    }

                    return normalizedCurrentTime >= normalizedStartTime && normalizedCurrentTime < normalizedEndTime
                }()
            }
    }
    
}
