# UniRide

A smart university ride-sharing iOS application built with SwiftUI and Firebase. UniRide connects university students as drivers and passengers, featuring AI-powered ride recommendations, weather-aware demand forecasting, and a Gemini-powered chatbot.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Requirements](#requirements)
4. [iOS App Setup](#ios-app-setup)
5. [Firebase Functions Setup](#firebase-functions-setup)
6. [Firestore Collections](#firestore-collections)
7. [Main Features](#main-features)
8. [Data Flow](#data-flow)
9. [Team Notes](#team-notes)

---

## Project Overview

UniRide is a mobile platform designed for university communities that need a reliable, safe, and intelligent carpooling solution. The app supports two user roles — **driver** and **passenger** — and includes a **both** role for users that act as either.

**Core capabilities:**

| Capability | Technology |
|---|---|
| Authentication | Firebase Auth (Email/Password) |
| Database | Cloud Firestore (real-time listeners) |
| Backend logic | Firebase Cloud Functions (Node.js) |
| Ride recommendations | User behavior analytics stored in `user_analytics` |
| Weather-aware demand | External weather API via Cloud Function |
| AI Chatbot | Google Gemini API via Cloud Function |
| Context-aware rides | Zone-based filtering and seat availability |

---

## Architecture

```
iOS App (SwiftUI + MVVM)
        │
        ▼
Firebase Authentication
        │
        ▼
Cloud Functions (Node.js)
        │
        ├── Firestore Database
        │       ├── users
        │       ├── rides
        │       ├── rideRequests
        │       ├── rideHistory
        │       ├── user_analytics
        │       ├── analytics_cache
        │       └── api_logs
        │
        ├── Analytics Engine
        │       └── updateUserAnalytics → user_analytics → getRideRecommendations
        │
        ├── Weather API
        │       └── weatherAwareRides → analytics_cache
        │
        └── Gemini AI
                └── chatbot → conversational responses
```

The iOS app never writes to Firestore directly for business logic operations. All mutations go through **Cloud Functions**, which validate permissions, enforce business rules, and keep the database consistent.

---

## Requirements

### iOS Development

- Xcode 15 or later
- iOS 17 SDK or later
- CocoaPods or Swift Package Manager
- A physical device or simulator running iOS 17+

### Backend / Firebase

- Node.js 18 or later
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with **Blaze (pay-as-you-go)** plan (required for Cloud Functions)
- A Google Cloud account with the **Generative Language API** enabled (for Gemini chatbot)

---

## iOS App Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd GN1-Swift
```

### 2. Install dependencies

If using CocoaPods:

```bash
pod install
open GN1Swift.xcworkspace
```

If using Swift Package Manager, open `GN1Swift.xcodeproj` directly — packages resolve automatically.

### 3. Add GoogleService-Info.plist

The `GoogleService-Info.plist` file is **not included** in the repository for security reasons.

1. Go to the [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Project Settings > Your apps**
4. Download `GoogleService-Info.plist`
5. Drag it into the `GN1Swift/` folder in Xcode — make sure **"Copy items if needed"** is checked and the target `GN1Swift` is selected

### 4. Enable Firebase services

In the Firebase Console:

- **Authentication** > Sign-in method > Enable **Email/Password**
- **Firestore Database** > Create database > Start in **production mode**
- **Cloud Functions** > Enabled automatically with Blaze plan

### 5. Build and run

Select a simulator or connected device and press **Cmd+R**.

---

## Firebase Functions Setup

All backend logic lives in the `functions/` directory.

### 1. Navigate to the functions folder

```bash
cd functions
```

### 2. Install dependencies

```bash
npm install
```

### 3. Authenticate with Firebase

```bash
firebase login
```

### 4. Select your Firebase project

```bash
firebase use <your-project-id>
```

### 5. Set the Gemini API key (required for chatbot)

```bash
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
```

### 6. Deploy all functions

```bash
firebase deploy --only functions
```

To deploy a single function:

```bash
firebase deploy --only functions:getRideRecommendations
```

---

## Firestore Collections

### `users`
Stores registered user profiles.

| Field | Type | Description |
|---|---|---|
| `name` | String | Full name |
| `email` | String | University email |
| `role` | String | `passenger`, `driver`, or `both` |

### `rides`
Stores rides created by drivers.

| Field | Type | Description |
|---|---|---|
| `driverId` | String | UID of the driver |
| `driverName` | String | Display name |
| `driverRating` | Number | Average rating |
| `origin` | String | Departure location |
| `destination` | String | Arrival location |
| `zone` | String | Campus zone |
| `departureTime` | Timestamp | Scheduled time |
| `seatsAvailable` | Number | Remaining seats |
| `status` | String | `active`, `full`, `in_progress`, `completed` |

### `rideRequests`
Stores passenger requests for a ride.

| Field | Type | Description |
|---|---|---|
| `rideId` | String | Reference to ride |
| `passengerId` | String | UID of the passenger |
| `passengerName` | String | Display name |
| `driverId` | String | UID of the driver |
| `status` | String | `pending`, `accepted`, `rejected`, `completed` |
| `requestTime` | Timestamp | When the request was sent |

### `rideHistory`
Created when a ride is finished. One document per passenger.

| Field | Type | Description |
|---|---|---|
| `rideId` | String | Completed ride reference |
| `driverId` | String | Driver UID |
| `passengerId` | String | Passenger UID |
| `origin` | String | Trip origin |
| `destination` | String | Trip destination |
| `zone` | String | Campus zone |
| `completedAt` | Timestamp | Completion time |

### `user_analytics`
Stores behavioral analytics per user. Updated by `updateUserAnalytics`.

| Field | Type | Description |
|---|---|---|
| `favoriteZone` | String | Most frequent zone |
| `favoriteHour` | Number | Peak hour of usage |
| `favoriteDays` | Array | Most active weekdays |
| `totalRides` | Number | Lifetime ride count |
| `recommendedRides` | Array | Pre-computed list of ride IDs |
| `lastUpdated` | Timestamp | Last analytics update |

### `analytics_cache`
Stores the latest weather and demand data fetched by `weatherAwareRides`.

| Field | Type | Description |
|---|---|---|
| `weather` | String | Current weather description |
| `temperature` | Number | Temperature in °C |
| `demandLevel` | String | `low`, `medium`, `high` |
| `demandMultiplier` | Number | Demand factor applied to wait times |

### `api_logs`
Internal logging collection used by Cloud Functions to record API call metadata and errors.

---

## Main Features

### Create Ride
Drivers create a ride by specifying origin, destination, zone, departure time, and available seats. The `createRide` Cloud Function saves the document and associates it with the authenticated driver.

### Request Ride
Passengers browse available rides filtered by zone, seat count, and driver rating. They send a request via the `requestRide` function. Duplicate requests for the same ride are rejected server-side.

### Accept / Reject Ride
Drivers review incoming requests in real time. Accepting a request decrements `seatsAvailable` by 1 and marks the ride as `full` when it reaches 0. Rejecting simply updates the request status.

### Start Ride
When the driver is ready to depart, they press **Start Ride**. The app navigates to `RideInProgressView` showing the route and the list of accepted passengers. No database write is required at this step.

### Finish Ride
The driver presses **Finish Ride**, which calls the `finishRide` Cloud Function. This atomically:
- Sets `rides.status = "completed"`
- Creates a `rideHistory` document for each accepted passenger
- Marks all accepted `rideRequests` as `completed`
- Updates the driver's `user_analytics`

After completion, `updateUserAnalytics` is called to refresh recommendations.

### Ride History
All completed trips are stored in `rideHistory` and are accessible to both drivers and passengers for reference.

### Recommendations
When a passenger opens the Recommendations screen, the app reads `user_analytics/{userId}.recommendedRides` (a pre-computed list of ride IDs) and fetches the corresponding rides from Firestore. Recommendations are recalculated automatically after each completed ride by `updateUserAnalytics`.

### Weather Smart Feature
The `weatherAwareRides` Cloud Function periodically fetches current weather conditions and computes a demand multiplier. This data is cached in `analytics_cache` and used to display estimated wait times and demand level in the home screen.

### AI Chatbot
Users can open the in-app chatbot powered by Google Gemini. Messages are sent to the `chatbot` Cloud Function, which forwards them to the Gemini API and returns a context-aware response. The chatbot can answer questions about rides, zones, and university commuting.

---

## Data Flow

### Complete Ride Lifecycle

```
createRide
    └── rides/{rideId}  status: "active"

requestRide
    └── rideRequests/{id}  status: "pending"

acceptRide
    └── rideRequests/{id}  status: "accepted"
    └── rides/{rideId}     seatsAvailable -= 1  (status: "full" if 0)

startRide  (client-side navigation only)
    └── RideInProgressView shown to driver

finishRide
    └── rides/{rideId}         status: "completed"
    └── rideHistory/{id}       created per accepted passenger
    └── rideRequests/{id}      status: "completed"

updateUserAnalytics
    └── user_analytics/{userId}   favoriteZone, favoriteHour, recommendedRides updated

getRideRecommendations
    └── reads user_analytics/{userId}.recommendedRides
    └── fetches rides from rides collection
    └── displayed in RecommendationsView
```

---

## Team Notes

### Shared Firebase Project
All team members must connect to the **same Firebase project**. Coordinate the project ID before setting up locally.

### GoogleService-Info.plist
This file contains sensitive API keys and is **excluded from the repository** via `.gitignore`. Every team member must download their own copy from the Firebase Console and add it to their local Xcode project. **Never commit this file.**

### Environment Variables
The Gemini API key is stored as a Firebase Functions config variable and is never hardcoded. Each developer with deploy access must set it using:

```bash
firebase functions:config:set gemini.key="YOUR_KEY"
```

### Firestore Rules
Ensure Firestore security rules are configured so that users can only read and write their own data. The rules file is located at `firestore.rules` in the project root.

### Branching Strategy
- `main` — stable, production-ready code
- `develop` — integration branch for ongoing work
- `feat/*` — individual feature branches merged into `develop` via pull request
