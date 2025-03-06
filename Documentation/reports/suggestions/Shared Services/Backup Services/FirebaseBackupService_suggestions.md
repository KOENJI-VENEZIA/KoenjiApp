Analyzing /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Services/Backup Services/FirebaseBackupService.swift...
# Documentation Suggestions for FirebaseBackupService.swift

File: /Users/matteonassini/KoenjiApp/KoenjiApp/Shared Services/Backup Services/FirebaseBackupService.swift
Total suggestions: 7

## Property Documentation (7)

### errorDescription (Line 9)

**Context:**

```swift
enum BackupConflictError: Error, LocalizedError {
    case conflictFound(String)
    
    var errorDescription: String? {
        switch self {
        case .conflictFound(let message):
            return message
```

**Suggested Documentation:**

```swift
/// [Description of the errorDescription property]
```

### message (Line 11)

**Context:**

```swift
    
    var errorDescription: String? {
        switch self {
        case .conflictFound(let message):
            return message
        }
    }
```

**Suggested Documentation:**

```swift
/// [Description of the message property]
```

### db (Line 23)

**Context:**

```swift
    @Published var localBackupFileURL: URL? = nil
    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseBackupService")

    let db: Firestore!
    private let storage: Storage
    private let store: ReservationStore
    let notifsManager: NotificationManager
```

**Suggested Documentation:**

```swift
/// [Description of the db property]
```

### storage (Line 24)

**Context:**

```swift
    let logger = Logger(subsystem: "com.koenjiapp", category: "FirebaseBackupService")

    let db: Firestore!
    private let storage: Storage
    private let store: ReservationStore
    let notifsManager: NotificationManager
    private var backupDirectory: String {
```

**Suggested Documentation:**

```swift
/// [Description of the storage property]
```

### store (Line 25)

**Context:**

```swift

    let db: Firestore!
    private let storage: Storage
    private let store: ReservationStore
    let notifsManager: NotificationManager
    private var backupDirectory: String {
        #if DEBUG
```

**Suggested Documentation:**

```swift
/// [Description of the store property]
```

### notifsManager (Line 26)

**Context:**

```swift
    let db: Firestore!
    private let storage: Storage
    private let store: ReservationStore
    let notifsManager: NotificationManager
    private var backupDirectory: String {
        #if DEBUG
        return "debugBackups"
```

**Suggested Documentation:**

```swift
/// [Description of the notifsManager property]
```

### backupDirectory (Line 27)

**Context:**

```swift
    private let storage: Storage
    private let store: ReservationStore
    let notifsManager: NotificationManager
    private var backupDirectory: String {
        #if DEBUG
        return "debugBackups"
        #else
```

**Suggested Documentation:**

```swift
/// [Description of the backupDirectory property]
```


Total documentation suggestions: 7

