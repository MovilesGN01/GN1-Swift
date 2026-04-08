# UniRide Architecture & Design Patterns

## 1. Architectural Style

### MVVM (Model–View–ViewModel)

MVVM divides the codebase into three clear responsibilities: data (Model), UI (View), and logic (ViewModel). A fourth layer — Services — handles all communication with the backend.

#### How it maps to this project

| Layer | Responsibility | Examples |
|-------|---------------|---------|
| **Model** | Data structures, parsed from Firestore | `Ride`, `RideRequest`, `User`, `UserAnalytics`, `WeatherData` |
| **View** | SwiftUI screens, display only | `HomeView`, `RidesView`, `RideDetailView`, `RideInProgressView` |
| **ViewModel** | Business logic, state management | `PassengerRidesViewModel`, `RideInProgressViewModel`, `ChatbotViewModel` |
| **Service** | Backend communication | `FirestoreService`, `CloudFunctionsService`, `AuthService` |

#### Example flow — passenger requests a ride

```
RidesView (button tap)
  → RideDetailViewModel.requestRide()
    → CloudFunctionsService.requestRide(rideId:)
      → Firebase Cloud Function "requestRide"
        → Firestore: creates rideRequests document
```

The View never talks to Firebase directly. It only calls the ViewModel, which delegates to a Service.

#### Why MVVM was used

- **Separation of concerns** — UI code stays in Views; no business logic bleeds into SwiftUI bodies.
- **Testability** — ViewModels can be tested without rendering a screen.
- **Maintainability** — changing how a ride is fetched only requires updating the Service and ViewModel, not every View that displays rides.

---

## 2. Client–Server Architecture

UniRide follows a classic client–server model:

```
iOS App (Client)  →  Firebase Cloud Functions (Server)  →  Firestore (Database)
```

### Client — iOS App

The app never writes directly to Firestore for critical operations. It calls Cloud Functions, which own the business logic (seat decrement on accept, ride history creation on finish, analytics refresh, etc.).

### Server — Firebase

| Component | Role |
|-----------|------|
| **Cloud Functions** | Enforce business rules, validate input, orchestrate multi-step writes |
| **Firestore** | Persistent data store; also used for real-time listeners |

### Example — starting a ride

```
DriverRidesSectionView  →  "Start Ride" button
  → CloudFunctionsService.startRide(rideId:)
    → CF: sets rides/{rideId}.status = "in_progress"
      → Firestore listener in RideInProgressViewModel fires automatically
        → UI updates in real time
```

### Why this separation

- The backend enforces rules the client cannot be trusted to enforce (e.g. seat counts, duplicate request checks).
- The app stays lightweight — it displays data and captures input, nothing more.
- A future web or Android client could reuse the same Cloud Functions without duplicating logic.

---

## 3. Design Patterns

### Singleton Pattern

A singleton is a class that has exactly one shared instance for the entire app lifetime.

**Used in:**

```swift
// Single shared instances — accessed anywhere without passing references
FirestoreService.shared
CloudFunctionsService.shared
AuthService.shared
UserSession.shared
```

`UserSession.shared` is a good example of why this matters: it stores the signed-in user's `userId`, `name`, `role`, and driver details. Every ViewModel and Service needs this data. A singleton makes it available everywhere without passing it through initializers.

**Why:**
- Avoids creating multiple Firestore or Functions clients (expensive and unnecessary).
- Provides a single source of truth for the user session.
- Simplifies call sites — `FirestoreService.shared.fetchRide(...)` from any file.

---

### Service Layer Pattern

All backend communication is isolated inside dedicated service classes, never placed directly in Views or ViewModels.

**Services in this project:**

| Service | Responsibility |
|---------|---------------|
| `AuthService` | Firebase Authentication (login, register) |
| `FirestoreService` | Firestore reads, writes, and real-time listeners |
| `CloudFunctionsService` | All Firebase Cloud Function calls |
| `OpenWeatherMapService` | External weather API |

**Example — creating a ride:**

```swift
// ✅ What actually happens
CreateRideViewModel → CloudFunctionsService.shared.createRide(...)

// ❌ What never happens
CreateRideView → Firestore.firestore().collection("rides").addDocument(...)
```

**Why:**
- Views and ViewModels stay clean and focused on their own concerns.
- If the backend API changes (e.g. a Cloud Function is renamed), only one service file needs updating.
- Centralized error handling and logging per service.

---

### Observer Pattern (SwiftUI Reactive Bindings)

The Observer pattern means: when data changes, all interested parties are notified automatically. In this project, SwiftUI's reactive system handles this natively.

**Tools used:**

| Tool | Where | Effect |
|------|-------|--------|
| `@Published` | ViewModels | Publishes property changes to subscribers |
| `@StateObject` / `@ObservedObject` | Views | Subscribes a View to a ViewModel |
| `@State` | Views | Local view state, triggers re-render on change |

**Example — real-time passenger list in `RideInProgressView`:**

```swift
// ViewModel
@Published var acceptedPassengers: [RideRequest] = []

func startListening() {
    stopListening = FirestoreService.shared.listenToAcceptedPassengers(rideId: ride.id) { passengers in
        self.acceptedPassengers = passengers  // @Published triggers UI update
    }
}

// View — no manual refresh needed
ForEach(viewModel.acceptedPassengers) { passenger in
    passengerRow(passenger)
}
```

When Firestore sends a new snapshot, the ViewModel updates `acceptedPassengers`, SwiftUI detects the `@Published` change, and the passenger list re-renders automatically.

**Why:**
- The UI is always in sync with the data without manual refresh calls.
- Reduces bugs caused by stale state.
- Aligns with SwiftUI's declarative design — describe *what* to show, not *when* to update.

---

## 4. Summary

```
View  →  ViewModel  →  Service  →  Cloud Function  →  Firestore
 UI       Logic       Backend        Server rules       Database
```

| Pattern | Purpose in UniRide |
|---------|-------------------|
| **MVVM** | Organizes the app into UI, logic, and data layers |
| **Client–Server** | Separates the iOS app from Firebase backend logic |
| **Singleton** | Provides shared access to services and user session |
| **Service Layer** | Centralizes all backend communication in one place |
| **Observer** | Keeps the UI reactive and automatically in sync with Firestore |

These patterns work together to keep the codebase modular: adding a new feature (e.g. a new ride type) only requires a new Model, a new ViewModel, and one or two Service calls — the existing architecture accommodates it without structural changes.
