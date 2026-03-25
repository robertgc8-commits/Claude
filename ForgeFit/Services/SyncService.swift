import Foundation
import SwiftData

/// Handles bidirectional sync between local SwiftData and remote Firestore.
/// In MVP, social features use mock data. Real sync is stubbed here.
protocol SyncServiceProtocol {
    func syncUserProfile(userId: String) async throws
    func syncFriends(userId: String) async throws
    func syncFeed(userId: String) async throws
    func pushWorkout(_ workout: Workout, userId: String) async throws
    func pushFeedItem(_ item: FeedItem, userId: String) async throws
    /// Sends a backend account-deletion request. Local data is wiped by the caller.
    func deleteAccount(userId: String) async throws
}

final class MockSyncService: SyncServiceProtocol {
    func syncUserProfile(userId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    func syncFriends(userId: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    func syncFeed(userId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    func pushWorkout(_ workout: Workout, userId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    func pushFeedItem(_ item: FeedItem, userId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    func deleteAccount(userId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}

/// Real implementation stub (wire up Firebase here)
final class FirestoreSyncService: SyncServiceProtocol {
    // Inject Firestore client in production
    func syncUserProfile(userId: String) async throws { /* Firestore fetch */ }
    func syncFriends(userId: String) async throws { /* Firestore query friends collection */ }
    func syncFeed(userId: String) async throws { /* Firestore query feed collection */ }
    func pushWorkout(_ workout: Workout, userId: String) async throws { /* Firestore write */ }
    func pushFeedItem(_ item: FeedItem, userId: String) async throws { /* Firestore write */ }
    func deleteAccount(userId: String) async throws { /* DELETE /users/{userId} on backend */ }
}
