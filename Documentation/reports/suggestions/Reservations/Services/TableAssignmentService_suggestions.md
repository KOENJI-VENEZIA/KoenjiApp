Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/TableAssignmentService.swift...
# Documentation Suggestions for TableAssignmentService.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/TableAssignmentService.swift
Total suggestions: 35

## Property Documentation (35)

### reservationDate (Line 50)

**Context:**

```swift
        reservations: [Reservation],
        startingFrom selectedTable: TableModel
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else { return nil }

        // Check if the forced table is available
        if isTableOccupied(
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### contiguousBlock (Line 65)

**Context:**

```swift
        }

        // Try to find a contiguous block starting at the forced table
        if let contiguousBlock = findContiguousBlockStartingAtTable(
            tables: tables,
            forcedTable: selectedTable,
            reservation: reservation,
```

**Suggested Documentation:**

```swift
/// [Description of the contiguousBlock property]
```

### reservationDate (Line 95)

**Context:**

```swift
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else { return nil }
        return assignTablesInOrder(for: reservation, reservations: reservations, tables: tables, reservationDate: reservationDate)
    }

```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### reservationDate (Line 115)

**Context:**

```swift
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [TableModel]? {
        guard let reservationDate = reservation.normalizedDate else {
            logger.error("Failed to parse reservation date for reservation ID: \(reservation.id)")
            return nil
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### contiguousBlock (Line 121)

**Context:**

```swift
        }
        logger.debug("Processing reservation date: \(reservationDate) for reservation ID: \(reservation.id)")
        // Try to find a single contiguous block
        if let contiguousBlock = findContiguousBlock(
            reservation: reservation,
            reservations: reservations,
            orderedTables: sortTables(tables),
```

**Suggested Documentation:**

```swift
/// [Description of the contiguousBlock property]
```

### reservationID (Line 153)

**Context:**

```swift
        reservations: [Reservation],
        tables: [TableModel]
    ) -> [(table: TableModel, isCurrentlyAssigned: Bool)] {
        let reservationID = reservation?.id
        let reservationDate = reservation?.normalizedDate ?? Date()
        let startTime = reservation?.startTime ?? ""
        let endTime = reservation?.endTime ?? ""
```

**Suggested Documentation:**

```swift
/// [Description of the reservationID property]
```

### reservationDate (Line 154)

**Context:**

```swift
        tables: [TableModel]
    ) -> [(table: TableModel, isCurrentlyAssigned: Bool)] {
        let reservationID = reservation?.id
        let reservationDate = reservation?.normalizedDate ?? Date()
        let startTime = reservation?.startTime ?? ""
        let endTime = reservation?.endTime ?? ""

```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### startTime (Line 155)

**Context:**

```swift
    ) -> [(table: TableModel, isCurrentlyAssigned: Bool)] {
        let reservationID = reservation?.id
        let reservationDate = reservation?.normalizedDate ?? Date()
        let startTime = reservation?.startTime ?? ""
        let endTime = reservation?.endTime ?? ""

        return tables.compactMap { table in
```

**Suggested Documentation:**

```swift
/// [Description of the startTime property]
```

### endTime (Line 156)

**Context:**

```swift
        let reservationID = reservation?.id
        let reservationDate = reservation?.normalizedDate ?? Date()
        let startTime = reservation?.startTime ?? ""
        let endTime = reservation?.endTime ?? ""

        return tables.compactMap { table in
            let isOccupied = isTableOccupied(
```

**Suggested Documentation:**

```swift
/// [Description of the endTime property]
```

### isOccupied (Line 159)

**Context:**

```swift
        let endTime = reservation?.endTime ?? ""

        return tables.compactMap { table in
            let isOccupied = isTableOccupied(
                table,
                reservations: reservations,
                date: reservationDate,
```

**Suggested Documentation:**

```swift
/// [Description of the isOccupied property]
```

### isCurrentlyAssigned (Line 167)

**Context:**

```swift
                endTime: endTime,
                excluding: reservationID
            )
            let isCurrentlyAssigned = reservation?.tables.contains(where: { $0.id == table.id }) ?? false
            return (!isOccupied || isCurrentlyAssigned) ? (table, isCurrentlyAssigned) : nil
        }
    }
```

**Suggested Documentation:**

```swift
/// [Description of the isCurrentlyAssigned property]
```

### start (Line 197)

**Context:**

```swift
        endTime: String,
        excluding reservationID: UUID? = nil
    ) -> Bool {
        guard let start = DateHelper.combineDateAndTime(date: date, timeString: startTime),
              let end = DateHelper.combineDateAndTime(date: date, timeString: endTime) else {
            logger.error("Failed to combine date and time. Start: \(startTime), End: \(endTime)")
            return false
```

**Suggested Documentation:**

```swift
/// [Description of the start property]
```

### end (Line 198)

**Context:**

```swift
        excluding reservationID: UUID? = nil
    ) -> Bool {
        guard let start = DateHelper.combineDateAndTime(date: date, timeString: startTime),
              let end = DateHelper.combineDateAndTime(date: date, timeString: endTime) else {
            logger.error("Failed to combine date and time. Start: \(startTime), End: \(endTime)")
            return false
        }
```

**Suggested Documentation:**

```swift
/// [Description of the end property]
```

### gracePeriod (Line 204)

**Context:**

```swift
        }

        // we should evaluate if it's okay to keep it 0 or we want to hard code it; eventually it could be configured in the settings!
        let gracePeriod: TimeInterval = 0 

        return reservations.contains { reservation in
            // Exclude current reservation if editing
```

**Suggested Documentation:**

```swift
/// [Description of the gracePeriod property]
```

### reservationDate (Line 222)

**Context:**

```swift
                return false
            }

            guard let reservationDate = reservation.normalizedDate,
                  let reservationStart = reservation.startTimeDate,
                  let reservationEnd = reservation.endTimeDate,
                  reservation.tables.contains(where: { $0.id == table.id }) else {
```

**Suggested Documentation:**

```swift
/// [Description of the reservationDate property]
```

### reservationStart (Line 223)

**Context:**

```swift
            }

            guard let reservationDate = reservation.normalizedDate,
                  let reservationStart = reservation.startTimeDate,
                  let reservationEnd = reservation.endTimeDate,
                  reservation.tables.contains(where: { $0.id == table.id }) else {
                logger.warning("Failed to parse reservation details for: \(reservation.name)")
```

**Suggested Documentation:**

```swift
/// [Description of the reservationStart property]
```

### reservationEnd (Line 224)

**Context:**

```swift

            guard let reservationDate = reservation.normalizedDate,
                  let reservationStart = reservation.startTimeDate,
                  let reservationEnd = reservation.endTimeDate,
                  reservation.tables.contains(where: { $0.id == table.id }) else {
                logger.warning("Failed to parse reservation details for: \(reservation.name)")
                return false
```

**Suggested Documentation:**

```swift
/// [Description of the reservationEnd property]
```

### adjustedReservationEnd (Line 235)

**Context:**

```swift
            

            // Adjust reservation times for buffer
            let adjustedReservationEnd = reservationEnd.addingTimeInterval(gracePeriod)
            let reservationEndsCloseToNewStart = adjustedReservationEnd > start && reservationEnd <= start

            let overlaps = TimeHelpers.timeRangesOverlap(
```

**Suggested Documentation:**

```swift
/// [Description of the adjustedReservationEnd property]
```

### reservationEndsCloseToNewStart (Line 236)

**Context:**

```swift

            // Adjust reservation times for buffer
            let adjustedReservationEnd = reservationEnd.addingTimeInterval(gracePeriod)
            let reservationEndsCloseToNewStart = adjustedReservationEnd > start && reservationEnd <= start

            let overlaps = TimeHelpers.timeRangesOverlap(
                start1: reservationStart,
```

**Suggested Documentation:**

```swift
/// [Description of the reservationEndsCloseToNewStart property]
```

### overlaps (Line 238)

**Context:**

```swift
            let adjustedReservationEnd = reservationEnd.addingTimeInterval(gracePeriod)
            let reservationEndsCloseToNewStart = adjustedReservationEnd > start && reservationEnd <= start

            let overlaps = TimeHelpers.timeRangesOverlap(
                start1: reservationStart,
                end1: adjustedReservationEnd,
                start2: start,
```

**Suggested Documentation:**

```swift
/// [Description of the overlaps property]
```

### neededCapacity (Line 263)

**Context:**

```swift
        tables: [TableModel],
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        let orderedTables = sortTables(tables)
```

**Suggested Documentation:**

```swift
/// [Description of the neededCapacity property]
```

### assignedCapacity (Line 264)

**Context:**

```swift
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        let orderedTables = sortTables(tables)

```

**Suggested Documentation:**

```swift
/// [Description of the assignedCapacity property]
```

### assignedTables (Line 265)

**Context:**

```swift
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        let orderedTables = sortTables(tables)

        for table in orderedTables where !isTableOccupied(
```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### orderedTables (Line 266)

**Context:**

```swift
        let neededCapacity = reservation.numberOfPersons
        var assignedCapacity = 0
        var assignedTables: [TableModel] = []
        let orderedTables = sortTables(tables)

        for table in orderedTables where !isTableOccupied(
            table,
```

**Suggested Documentation:**

```swift
/// [Description of the orderedTables property]
```

### neededCapacity (Line 301)

**Context:**

```swift
        orderedTables: [TableModel],
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var block: [TableModel] = []
        var assignedCapacity = 0

```

**Suggested Documentation:**

```swift
/// [Description of the neededCapacity property]
```

### block (Line 302)

**Context:**

```swift
        reservationDate: Date
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var block: [TableModel] = []
        var assignedCapacity = 0

        for table in orderedTables where !isTableOccupied(
```

**Suggested Documentation:**

```swift
/// [Description of the block property]
```

### assignedCapacity (Line 303)

**Context:**

```swift
    ) -> [TableModel]? {
        let neededCapacity = reservation.numberOfPersons
        var block: [TableModel] = []
        var assignedCapacity = 0

        for table in orderedTables where !isTableOccupied(
            table,
```

**Suggested Documentation:**

```swift
/// [Description of the assignedCapacity property]
```

### orderedTables (Line 336)

**Context:**

```swift
        reservations: [Reservation],
        reservationDate: Date
    ) -> [TableModel]? {
        let orderedTables = sortTables(tables)
        let startIndex = orderedTables.firstIndex { $0.id == forcedTable.id } ?? 0
        let slice = orderedTables[startIndex...]

```

**Suggested Documentation:**

```swift
/// [Description of the orderedTables property]
```

### startIndex (Line 337)

**Context:**

```swift
        reservationDate: Date
    ) -> [TableModel]? {
        let orderedTables = sortTables(tables)
        let startIndex = orderedTables.firstIndex { $0.id == forcedTable.id } ?? 0
        let slice = orderedTables[startIndex...]

        return findContiguousBlock(
```

**Suggested Documentation:**

```swift
/// [Description of the startIndex property]
```

### slice (Line 338)

**Context:**

```swift
    ) -> [TableModel]? {
        let orderedTables = sortTables(tables)
        let startIndex = orderedTables.firstIndex { $0.id == forcedTable.id } ?? 0
        let slice = orderedTables[startIndex...]

        return findContiguousBlock(
            reservation: reservation,
```

**Suggested Documentation:**

```swift
/// [Description of the slice property]
```

### assignedTables (Line 364)

**Context:**

```swift
        forcedTable: TableModel,
        reservationDate: Date
    ) -> [TableModel]? {
        var assignedTables: [TableModel] = [forcedTable]
        let orderedTables = sortTables(tables)
        var assignedCapacity = forcedTable.maxCapacity

```

**Suggested Documentation:**

```swift
/// [Description of the assignedTables property]
```

### orderedTables (Line 365)

**Context:**

```swift
        reservationDate: Date
    ) -> [TableModel]? {
        var assignedTables: [TableModel] = [forcedTable]
        let orderedTables = sortTables(tables)
        var assignedCapacity = forcedTable.maxCapacity

        for table in orderedTables where table.id != forcedTable.id && !isTableOccupied(
```

**Suggested Documentation:**

```swift
/// [Description of the orderedTables property]
```

### assignedCapacity (Line 366)

**Context:**

```swift
    ) -> [TableModel]? {
        var assignedTables: [TableModel] = [forcedTable]
        let orderedTables = sortTables(tables)
        var assignedCapacity = forcedTable.maxCapacity

        for table in orderedTables where table.id != forcedTable.id && !isTableOccupied(
            table,
```

**Suggested Documentation:**

```swift
/// [Description of the assignedCapacity property]
```

### index1 (Line 389)

**Context:**

```swift
    /// - Returns: Sorted array of tables based on the tableAssignmentOrder
    private func sortTables(_ tables: [TableModel]) -> [TableModel] {
        tables.sorted {
            guard let index1 = tableAssignmentOrder.firstIndex(of: $0.name),
                  let index2 = tableAssignmentOrder.firstIndex(of: $1.name) else { return $0.id < $1.id }
            return index1 < index2
        }
```

**Suggested Documentation:**

```swift
/// [Description of the index1 property]
```

### index2 (Line 390)

**Context:**

```swift
    private func sortTables(_ tables: [TableModel]) -> [TableModel] {
        tables.sorted {
            guard let index1 = tableAssignmentOrder.firstIndex(of: $0.name),
                  let index2 = tableAssignmentOrder.firstIndex(of: $1.name) else { return $0.id < $1.id }
            return index1 < index2
        }
    }
```

**Suggested Documentation:**

```swift
/// [Description of the index2 property]
```


Total documentation suggestions: 35

