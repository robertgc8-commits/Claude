# ForgeFit — Architecture

## Overview

ForgeFit is a native iOS app (Swift + SwiftUI, iOS 17+) using:
- **SwiftData** for local offline-first persistence
- **MVVM** architecture with `@Observable` / `@MainActor` ViewModels
- **Firebase** (Auth + Firestore + FCM) for social backend — stubbed with `MockSyncService` in MVP
- **Protocol-driven services** so every service can be swapped for testing

---

## Folder Structure

```
ForgeFit/
  App/               Entry point, AppState, ContentView / MainTabView
  Models/            SwiftData @Model classes (local source of truth)
  Engines/           Pure-logic engines: Streak, Achievement, ProgressOverload
  Repositories/      SwiftData query/write layer (one per domain)
  Services/          Auth, Notifications, Sync (protocol + mock + real stub)
  ViewModels/        One ObservableObject per screen
  Views/
    Onboarding/
    Home/
    Workout/
    Progress/
    Achievements/
    Social/
    Profile/
    Settings/
  Components/
    Cards/           StatCard, WorkoutCard, PRBadge
    Streak/          StreakCard
    Achievement/     AchievementBadge, AchievementToast
    Workout/         ExerciseSetRow
    Shared/          FFButton, FFTextField
  Extensions/        Color+Theme, Date+Workout, View+Extensions
  Resources/         Assets.xcassets (brand colors)
  Mock/              MockData, PreviewHelpers
ForgeFitTests/       XCTest suite for Engines
```

---

## Data Flow

```
View  ──(binds)──▶  ViewModel  ──(calls)──▶  Repository  ──(reads/writes)──▶  SwiftData
                                    │
                                    ▼
                                 Engine
                            (pure computation)
                                    │
                                    ▼
                              SyncService
                           (Firestore push)
```

---

## Streak Logic

A "streak" = consecutive calendar **weeks** (Mon–Sun) where the user met their
custom weekly workout target (2–7 workouts). This rewards consistency without
punishing deliberate rest days.

- `WeeklyStreakRecord` stores completed vs. target counts per week
- `StreakEngine.computeStreakStatus()` derives the current streak by walking
  backwards from last week — the current in-progress week is never broken
- Milestones: 2, 4, 8, 12, 16, 20, 26, 52 consecutive weeks

---

## Achievement Engine

- `AchievementDefinition.all` — the full library of 20 achievements, value types
- `AchievementEngine.evaluate(context:)` — pure function; returns newly unlocked definitions
- `AchievementEngine.EvaluationContext` — all stats needed (workouts, PRs, streak, friends)
- `AchievementUnlock` — SwiftData record of what was unlocked and when
- Called after workout completion and after adding a friend

---

## Progressive Overload Engine

- `detectPRs()` — compares current set to all historical sets for same exercise
- Three PR types: heaviest weight, most reps at a given weight, highest set volume
- `suggest()` — if last session's max reps ≥ 8 (target), suggest +2.5kg; else +1 rep
- `computeVolumeTrend()` — groups volume by week, compares last 4 vs prior 4 weeks

---

## Privacy Model

`UserSettings` contains explicit boolean flags for every visibility dimension:
- `shareWorkoutTitles`, `shareExerciseNames`, `shareSetsRepsWeight`, `sharePRs`,
  `shareStreaks`, `shareAchievements`
- `notifyFriendsOn{Workout,PR,Streak,Achievement}` — controls push to friends
- `receive{Streak,FriendActivity,Inactivity,WeeklyReport}` — controls own notifications

Firestore security rules (production) must enforce that feed item visibility
matches the poster's settings at write time (via Cloud Function fanout).

---

## Backend Architecture (Firebase)

```
Firestore collections:
  /users/{userId}                  — profile, settings
  /users/{userId}/workouts/{id}    — workout documents (if user allows sync)
  /friendships/{id}                — bidirectional relationship
  /feed/{userId}/items/{id}        — fan-out feed items per user

Cloud Functions:
  onWorkoutComplete   — generate feed items for friends (respecting privacy settings)
  onFriendRequest     — notify receiver
  onFriendAccept      — notify requester, create bidirectional feed access
  onPRHit             — generate PR feed item if settings allow
  onAchievementUnlock — generate achievement feed item if settings allow
```

---

## Adding Firebase (post-MVP)

1. Add Firebase iOS SDK via SPM: `firebase-ios-sdk` → select `FirebaseAuth`,
   `FirebaseFirestore`, `FirebaseMessaging`
2. Replace `MockAuthService` with `FirebaseAuthService: AuthServiceProtocol`
3. Replace `MockSyncService` with `FirestoreSyncService` (stub already exists)
4. Add `GoogleService-Info.plist` from Firebase console
5. Configure FCM token registration in `AppDelegate` / `ForgeFitApp`
6. Deploy Cloud Functions from `/functions` directory
