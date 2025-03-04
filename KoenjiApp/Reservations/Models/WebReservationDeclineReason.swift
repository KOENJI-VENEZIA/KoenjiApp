public enum WebReservationDeclineReason: String, CaseIterable, Identifiable {
        case capacityIssue = "notEnoughCapacity"
        case internalIssue = "internalIssue"
        case other = "other"
        
        var id: String { rawValue }
        
        var displayText: String {
            switch self {
            case .capacityIssue:
                return String(localized: "Not enough capacity")
            case .internalIssue:
                return String(localized: "Internal issues (will follow up by phone)")
            case .other:
                return String(localized: "Other (will follow up when possible)")
            }
        }
        
        var notesText: String {
            switch self {
            case .capacityIssue:
                return "Declined: Not enough capacity for this reservation"
            case .internalIssue:
                return "Declined: Internal issues - Phone follow-up required"
            case .other:
                return "Declined: Other reasons - Phone follow-up when possible"
            }
        }
    }