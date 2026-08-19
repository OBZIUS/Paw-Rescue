<p align="center">
  <img src="Paw Rescue/Assets.xcassets/AppLogo.imageset/AppLogo.png" width="120" alt="Paw Rescue Logo"/>
</p>

<h1 align="center">Paw Rescue 🐾</h1>

<p align="center">
  A real-time community-powered dog rescue app built for Bali — report injured street dogs, help coordinate rescues, and share stories with fellow animal lovers.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017+-blue?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/Backend-CloudKit-blueviolet?style=flat-square&logo=icloud" />
  <img src="https://img.shields.io/badge/Auth-Sign%20In%20with%20Apple-black?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" />
</p>

---

## 🐕 What is Paw Rescue?

Paw Rescue is an iOS app that connects people who find injured street dogs with local volunteers and animal shelters. Anyone can:

- 📍 **Report** a dog in distress by pinning their exact location on a live map
- 🗺️ **See all active rescue cases** reported by other users in real time
- 🤝 **Accept a case** and track it under "Your Activity"
- ✅ **Mark a case done** when the dog is safe
- 📸 **Share the rescue story** to a community feed with before/after photos
- ❤️ **Like** posts from other rescuers

All data is **real, shared, and persistent** — pins from one device appear on every other device instantly.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🗺️ Live rescue map | Real-time dog pins from all users via CloudKit public database |
| 📷 Camera + photo upload | Multi-photo capture, uploaded as CloudKit assets |
| 🏥 Urgency triage | AI-driven classification (Rabies Risk → Emergency → High → Medium → Low) |
| 📍 GPS pin placement | Report exact location with custom pin placement on map |
| 🧵 Community feed | Instagram-style feed with image carousel, likes, captions |
| 👤 Sign In with Apple | Real identity, stored securely in Keychain |
| 📊 Profile & stats | Dogs saved / reported stats persisted across reinstalls |
| 🔁 Pull-to-refresh | Fresh data from CloudKit on demand |
| 🏠 Your Activity | Carousel of cases you've personally accepted |
| 🐾 Rescue completion | Mark a dog as saved → auto-updates stats + removes from map |
| 📤 Share to Feed | Post rescued dog stories with photos after completing a case |
| 🔒 Anonymous posting | Option to share without revealing your identity |
| 🏥 Nearest shelters | Shows closest animal shelters with call + directions |

---

## 🏗️ Architecture

Paw Rescue is built **100% with Apple-first technologies** — no third-party dependencies.

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                        │
│  HomeView · MapScreenView · ProfileView · SignInView · ...  │
└───────────────────────┬─────────────────────────────────────┘
                        │ @EnvironmentObject
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                        AppState.swift                       │
│   Central ObservableObject — all published app state        │
│   @Published + UserDefaults for persistence                 │
└───────┬───────────────────────────────────────┬─────────────┘
        │                                       │
        ▼                                       ▼
┌───────────────────┐                 ┌─────────────────────┐
│  CloudKitManager  │                 │    AuthManager      │
│  Public DB:       │                 │  Sign In with Apple │
│  · DogReport      │                 │  Keychain storage   │
│  · FeedPost       │                 │  Credential check   │
│  Private DB:      │                 └─────────────────────┘
│  · UserStats      │
│  · AssignedCases  │                 ┌─────────────────────┐
└───────────────────┘                 │ ImageCacheManager   │
                                      │ FileManager disk    │
                                      │ cache for CKAssets  │
                                      └─────────────────────┘
```

### Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Backend | CloudKit (public + private databases) |
| Auth | AuthenticationServices (Sign In with Apple) |
| Credential Storage | Security framework (Keychain) |
| Image Caching | FileManager + NSCache |
| Location | CoreLocation + MapKit |
| Image Capture | AVFoundation (custom camera) |
| AI Triage | CoreML / Vision (dog detection) |
| Persistence | UserDefaults (flags + stats) |

---

## 📁 Project Structure

```
Paw Rescue/
├── PawRescueApp.swift          # App entry point, AuthManager injection
│
├── Services/
│   ├── CloudKitManager.swift   # All CloudKit reads & writes
│   ├── AuthManager.swift       # Sign In with Apple + Keychain
│   └── ImageCacheManager.swift # Disk + memory photo cache
│
├── Navigation/
│   └── AppState.swift          # Central ObservableObject, all app state
│
├── Models/
│   ├── DogReport.swift         # DogReport, FeedPost, ReportFormData models
│   ├── MockData.swift          # Static shelters + map center only
│   └── UrgencyClassifier.swift # Triage algorithm (Rabies → Low)
│
├── Screens/
│   ├── Onboarding/             # Video onboarding flow
│   ├── SignIn/                 # Sign In with Apple screen
│   ├── Home/                   # Feed + Your Activity carousel
│   ├── Map/                    # Live rescue map + dog detail sheet
│   ├── Report/                 # Multi-step report form + loading
│   ├── Case/                   # Your Case, Share Feed, Can't Help
│   ├── Profile/                # Stats, polaroid photo stack, sign out
│   ├── Camera/                 # Custom camera capture + review
│   └── Main/                   # Tab bar
│
├── Theme/
│   ├── AppColors.swift
│   ├── AppFonts.swift
│   ├── AppConstants.swift
│   └── LiquidGlass.swift       # Liquid glass button styles
│
└── Assets.xcassets/            # App icon, logo, accent color
```

---

## ☁️ CloudKit Schema

### Public Database (shared between all users)

**DogReport**
| Field | Type | Description |
|---|---|---|
| title | String | e.g. "DOG #3" |
| reporterName | String | Reporter's Apple ID name |
| reporterUserID | String | Apple ID user identifier |
| latitude | Double (NSNumber) | GPS latitude |
| longitude | Double (NSNumber) | GPS longitude |
| location | String | Human-readable location name |
| urgencyRaw | String | UrgencyLevel raw value |
| description | String | Free-text description |
| symptomsJSON | String | JSON-encoded symptom array |
| photos | [CKAsset] | Uploaded dog photos |
| isCompleted | Int (NSNumber) | 0 = active, 1 = resolved |

**FeedPost**
| Field | Type | Description |
|---|---|---|
| username | String | Poster's username or "anonymous_rescuer" |
| userID | String | Apple ID (empty if anonymous) |
| caption | String | Story caption |
| likeCount | Int (NSNumber) | Global like count |
| likedByUsers | [String] | Array of user IDs who liked |
| images | [CKAsset] | Post photos |

### Private Database (per user)

**UserStats**
| Field | Type | Description |
|---|---|---|
| userID | String | Apple ID user identifier |
| dogsSaved | Int (NSNumber) | Dogs marked as done |
| dogsReported | Int (NSNumber) | Dogs reported |
| assignedCaseIDs | [String] | CloudKit record names of active cases |

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator signed into iCloud
- Apple Developer account (for CloudKit + Sign In with Apple)

### Setup

**1. Clone the repo**
```bash
git clone https://github.com/OBZIUS/Paw-Rescue.git
cd Paw-Rescue
open "Paw Rescue.xcodeproj"
```

**2. Enable Capabilities in Xcode**

Go to your target → **Signing & Capabilities**:

- ☁️ Add **iCloud** → tick **CloudKit** → add container: `iCloud.com.pawrescue.app`
- 🍎 Add **Sign In with Apple**

**3. Update the CloudKit container ID** (if using your own)

In [`CloudKitManager.swift`](Paw%20Rescue/Services/CloudKitManager.swift), line 67:
```swift
container = CKContainer(identifier: "iCloud.com.pawrescue.app")
```
Replace with your actual container ID.

**4. Build & Run**
```
Cmd + B  →  Build
Cmd + R  →  Run on device
```

> ⚠️ CloudKit and Sign In with Apple require a **real device** or a simulator signed into iCloud.

---

## 🔄 How Data Flows

```
User A reports a dog
  → Photo taken with custom camera
  → Report form filled (triage questions)
  → submitReport() called in AppState
  → Pin appears INSTANTLY on User A's map (optimistic update)
  → CloudKitManager.saveReport() uploads in background
  → Photos uploaded as CKAssets to CloudKit public DB

User B opens the app
  → MapScreenView.onAppear → appState.loadReports()
  → CloudKitManager.fetchReports() pulls all records
  → User A's pin appears on User B's map with real photo

User B taps "Help this dog"
  → assignCaseToUser() → saved to UserDefaults + CloudKit private DB
  → Appears in User B's "Your Activity" carousel on Home tab

User B taps "Mark as Done"
  → markCaseDone() → CloudKit public record updated (isCompleted = 1)
  → Pin removed from map for everyone
  → dogsSavedCount++ → synced to CloudKit private DB

User B shares a rescue story
  → ShareFeedView → addFeedPost()
  → Post appears INSTANTLY in feed (optimistic update)
  → CloudKitManager.saveFeedPost() uploads with photos in background
  → Visible in every user's Feed tab
```

---

## 🔐 Authentication Flow

```
First launch
  └─ OnboardingView → "Get started" → SignInView
      └─ Tap "Sign in with Apple"
          └─ ASAuthorizationAppleIDProvider request
              └─ Apple returns: userID, fullName, email
                  └─ Saved to Keychain
                      └─ AppState.isSignedIn = true → MainTabView

Subsequent launches
  └─ AuthManager.init() → restoreFromKeychain()
      └─ ASAuthorizationAppleIDProvider.getCredentialState(forUserID:)
          ├─ .authorized → isAuthenticated = true → skip sign-in
          └─ .revoked / .notFound → signOut() → back to SignInView

Sign out
  └─ ProfileView sign-out button
      └─ AuthManager.signOut()
          ├─ Clears Keychain (userID, name, email)
          ├─ Clears image disk cache
          └─ AppState.isSignedIn = false → SignInView
```

---

## 🎨 Design System

| Token | Value |
|---|---|
| Primary Background | `#FFF6E9` (warm cream) |
| Primary Blue | `#2D4A9A` |
| Secondary Cream | `#FFE3B7` |
| Emergency Red | `#E53935` |
| Warning Yellow | `#FFC107` |
| Safe Green | `#4CAF50` |
| Corner Radius XL | 20pt |
| Corner Radius XXL | 28pt |

All buttons use **Liquid Glass** styling with `ultraThinMaterial` for a premium iOS 18 feel.

---

## 📱 Screenshots

> Coming soon — run the app on your device to see it in action!

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

---

## 📄 License

MIT © 2026 OBZIUS / Paw Rescue Team
