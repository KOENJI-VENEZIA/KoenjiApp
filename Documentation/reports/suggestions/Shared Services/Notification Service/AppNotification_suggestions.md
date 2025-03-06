Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Services/Notification Service/AppNotification.swift...
# Documentation Suggestions for AppNotification.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Services/Notification Service/AppNotification.swift
Total suggestions: 19

## Method Documentation (5)

### requestNotificationAuthorization (Line 50)

**Context:**

```swift

    /// Adds a new notification to the in‑app log and schedules a local notification.
    
    func requestNotificationAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission granted: \(granted)")
```

**Suggested Documentation:**

```swift
/// [Add a description of what the requestNotificationAuthorization method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### addNotification (Line 60)

**Context:**

```swift
    }
    
    @MainActor
    func addNotification(title: String, message: String, type: NotificationType, reservation: Reservation? = nil) async {
        let newNotification = AppNotification(title: title, message: message, reservation: reservation, type: type)
        notifications.append(newNotification)

```

**Suggested Documentation:**

```swift
/// [Add a description of what the addNotification method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### userNotificationCenter (Line 87)

**Context:**

```swift
        }
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract values before entering the Task block
```

**Suggested Documentation:**

```swift
/// [Add a description of what the userNotificationCenter method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### userNotificationCenter (Line 110)

**Context:**

```swift
    }
    
    // You might also need this delegate method for when notifications are presented while app is in foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound when notification arrives in foreground
```

**Suggested Documentation:**

```swift
/// [Add a description of what the userNotificationCenter method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

### clearNotifications (Line 124)

**Context:**

```swift
    }

    @MainActor
    func clearNotifications() {
        notifications.removeAll()
    }
}
```

**Suggested Documentation:**

```swift
/// [Add a description of what the clearNotifications method does]
///
/// - Parameters:
///   - [parameter]: [Description of parameter]
/// - Returns: [Description of the return value]
```

## Property Documentation (14)

### logger (Line 20)

**Context:**

```swift
    @Published var notifications: [AppNotification] = []
    @Published var selectedReservationID: UUID?
    
    let logger = Logger(subsystem: "com.koenjiapp", category: "NotificationManager")
    
    // Dictionary to track last notification times for each reservation and type
    private var lastNotificationTimes: [String: Date] = [:]
```

**Suggested Documentation:**

```swift
/// [Description of the logger property]
```

### lastNotificationTimes (Line 23)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "NotificationManager")
    
    // Dictionary to track last notification times for each reservation and type
    private var lastNotificationTimes: [String: Date] = [:]

    static let shared = NotificationManager()
    
```

**Suggested Documentation:**

```swift
/// [Description of the lastNotificationTimes property]
```

### shared (Line 25)

**Context:**

```swift
    // Dictionary to track last notification times for each reservation and type
    private var lastNotificationTimes: [String: Date] = [:]

    static let shared = NotificationManager()
    
    private override init() {
            super.init()
```

**Suggested Documentation:**

```swift
/// [Description of the shared property]
```

### lastTime (Line 35)

**Context:**

```swift
    func canSendNotification(for reservationId: UUID, type: NotificationType, minimumInterval: TimeInterval) async -> Bool {
        let key = "\(reservationId)-\(type.localized)"
        
        if let lastTime = lastNotificationTimes[key] {
            let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
            if timeSinceLastNotification < minimumInterval {
                logger.debug("Skipping notification: minimum interval not reached for reservation \(reservationId)")
```

**Suggested Documentation:**

```swift
/// [Description of the lastTime property]
```

### timeSinceLastNotification (Line 36)

**Context:**

```swift
        let key = "\(reservationId)-\(type.localized)"
        
        if let lastTime = lastNotificationTimes[key] {
            let timeSinceLastNotification = Date().timeIntervalSince(lastTime)
            if timeSinceLastNotification < minimumInterval {
                logger.debug("Skipping notification: minimum interval not reached for reservation \(reservationId)")
                return false
```

**Suggested Documentation:**

```swift
/// [Description of the timeSinceLastNotification property]
```

### granted (Line 52)

**Context:**

```swift
    
    func requestNotificationAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            logger.info("Notification permission granted: \(granted)")
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
```

**Suggested Documentation:**

```swift
/// [Description of the granted property]
```

### newNotification (Line 61)

**Context:**

```swift
    
    @MainActor
    func addNotification(title: String, message: String, type: NotificationType, reservation: Reservation? = nil) async {
        let newNotification = AppNotification(title: title, message: message, reservation: reservation, type: type)
        notifications.append(newNotification)

        let content = UNMutableNotificationContent()
```

**Suggested Documentation:**

```swift
/// [Description of the newNotification property]
```

### content (Line 64)

**Context:**

```swift
        let newNotification = AppNotification(title: title, message: message, reservation: reservation, type: type)
        notifications.append(newNotification)

        let content = UNMutableNotificationContent()
          content.title = title
          content.body = message
          content.sound = .default
```

**Suggested Documentation:**

```swift
/// [Description of the content property]
```

### reservation (Line 70)

**Context:**

```swift
          content.sound = .default
          
      // Include reservation ID in the user info if available
      if let reservation = reservation {
          content.userInfo = ["reservationID": reservation.id.uuidString]
      }

```

**Suggested Documentation:**

```swift
/// [Description of the reservation property]
```

### trigger (Line 74)

**Context:**

```swift
          content.userInfo = ["reservationID": reservation.id.uuidString]
      }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) // Debug with 3s delay
        let request = UNNotificationRequest(identifier: newNotification.id.uuidString,
                                            content: content,
                                            trigger: trigger)
```

**Suggested Documentation:**

```swift
/// [Description of the trigger property]
```

### request (Line 75)

**Context:**

```swift
      }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) // Debug with 3s delay
        let request = UNNotificationRequest(identifier: newNotification.id.uuidString,
                                            content: content,
                                            trigger: trigger)

```

**Suggested Documentation:**

```swift
/// [Description of the request property]
```

### reservationIDString (Line 91)

**Context:**

```swift
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract values before entering the Task block
        guard let reservationIDString = response.notification.request.content.userInfo["reservationID"] as? String,
              let reservationID = UUID(uuidString: reservationIDString) else {
            completionHandler()
            return
```

**Suggested Documentation:**

```swift
/// [Description of the reservationIDString property]
```

### reservationID (Line 92)

**Context:**

```swift
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract values before entering the Task block
        guard let reservationIDString = response.notification.request.content.userInfo["reservationID"] as? String,
              let reservationID = UUID(uuidString: reservationIDString) else {
            completionHandler()
            return
        }
```

**Suggested Documentation:**

```swift
/// [Description of the reservationID property]
```

### notificationIdentifier (Line 96)

**Context:**

```swift
            completionHandler()
            return
        }
        let notificationIdentifier = response.notification.request.identifier

        Task {
            // Dispatch work that touches actor-isolated properties onto the main actor.
```

**Suggested Documentation:**

```swift
/// [Description of the notificationIdentifier property]
```


Total documentation suggestions: 19

