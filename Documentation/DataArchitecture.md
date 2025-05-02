# KoenjiApp Three-Layer Data Architecture

## Overview

This document outlines the three-layer data architecture pattern used throughout KoenjiApp for managing data:

1. **FirestoreDataStore**: Low-level persistence layer (Firebase)
2. **Cache Layer**: In-memory storage with persistence coordination
3. **Service Layer**: Business logic and coordination

This architecture ensures clean separation of concerns, centralized data management, and proper Firebase integration.

## Layer Responsibilities

### 1. FirestoreDataStore<T>

**Purpose**: Generic, type-safe Firebase data access layer

**Responsibilities**:
- Direct communication with Firestore
- CRUD operations
- Safe batch operations
- Streaming data changes

**Key Methods**:
- `upsert(_ document: T)`: Add or update documents
- `delete(id: String)`: Remove documents
- `deleteAllDocuments()`: Purge collection
- `streamAll()`: Get real-time updates

### 2. Cache Layer (e.g., CurrentReservationsCache)

**Purpose**: Central state management with Firebase synchronization

**Responsibilities**:
- In-memory data storage
- Firebase synchronization
- Data validation and filtering
- Local persistence coordination (SQLite)

**Key Methods**:
- `addOrUpdateX(item, updateFirebase: Bool = true)`: Update cache and optionally Firebase
- `removeX(item)`: Remove from cache
- `clearCache()`: Clear just the memory cache
- `clearAllData(completion:)`: Clear all data sources (cache, SQLite, Firebase)

### 3. Service Layer (e.g., ReservationServices)

**Purpose**: Business logic and coordination

**Responsibilities**:
- Domain-specific operations
- Coordination between multiple caches/stores
- UI communication
- Cross-cutting concerns (notifications, etc.)

**Key Methods**:
- User-facing operations
- Coordination between different data types
- State management and UI updates

## Data Flow

1. **Write operations**: Service → Cache → Firebase
   ```
   service.addItem(item) → cache.addOrUpdateItem(item) → firestore.upsert(item)
   ```

2. **Read operations**: Cache → Service → UI
   ```
   cache.getAllItems() → service.getData() → UI display
   ```

3. **Firebase sync**: Firebase → Cache → UI updates
   ```
   Firebase change → cache update → UI refresh
   ```

## Best Practices

1. **Cache as source of truth**:
   - All Firebase operations flow through the cache
   - Services never directly access Firebase

2. **Isolation of responsibilities**:
   - Cache handles data persistence logic
   - Services handle business rules 
   - UI reactivity depends on published cache properties

3. **Safe Firebase operations**:
   - Use actors for thread safety
   - Handle data races explicitly
   - Implement retry logic for batch operations

4. **Consistent method naming**:
   - `clearCache()`: Memory only
   - `clearAllData()`: All data sources

## Implementation Example

To apply this pattern to a new data type (e.g., `Menu`):

1. Create a `FirestoreDataStore<Menu>` for Firebase operations
2. Implement a `MenuCache` class for in-memory storage and persistence
3. Create a `MenuService` for business logic

```swift
// 1. FirestoreDataStore usage
let menuStore = FirestoreDataStore<Menu>(collectionName: "menus")

// 2. Cache with Firebase coordination
class MenuCache: ObservableObject {
    @Published var items: [Menu] = []
    
    func addOrUpdateMenu(_ menu: Menu, updateFirebase: Bool = true) {
        // Update local cache
        if let index = items.firstIndex(where: { $0.id == menu.id }) {
            items[index] = menu
        } else {
            items.append(menu)
        }
        
        // Update Firebase if requested
        if updateFirebase {
            Task {
                do {
                    let store = FirestoreDataStore<Menu>(collectionName: "menus")
                    try await store.upsert(menu)
                } catch {
                    print("Firebase update failed: \(error)")
                }
            }
        }
    }
}

// 3. Service layer for business logic
class MenuService {
    private let menuCache: MenuCache
    
    init(menuCache: MenuCache) {
        self.menuCache = menuCache
    }
    
    func createNewMenuItem(name: String, price: Double) {
        let menu = Menu(id: UUID(), name: name, price: price)
        menuCache.addOrUpdateMenu(menu)
    }
}
```

By following this pattern consistently across the app, we ensure maintainable, testable code with clear responsibilities and data flow. 