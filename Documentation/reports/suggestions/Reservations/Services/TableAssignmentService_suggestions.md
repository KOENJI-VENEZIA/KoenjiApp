Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/TableAssignmentService.swift...
# Documentation Suggestions for TableAssignmentService.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Reservations/Services/TableAssignmentService.swift
Total suggestions: 10

## Property Documentation (10)

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


Total documentation suggestions: 10

