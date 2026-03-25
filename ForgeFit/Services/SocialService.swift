import Foundation
import SwiftData

// MARK: - Errors

enum SocialServiceError: LocalizedError {
    case userNotFound
    case requestAlreadySent
    case alreadyFriends
    case networkUnavailable
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .userNotFound:      return "User not found."
        case .requestAlreadySent: return "Friend request already sent."
        case .alreadyFriends:    return "You are already friends."
        case .networkUnavailable: return "Network unavailable. Try again shortly."
        case .unauthorized:      return "You are not authorised to perform this action."
        }
    }
}

// MARK: - Protocol

/// Abstracts all social backend operations.
/// Local SwiftData persistence is handled separately by repositories.
/// This layer owns: user discovery, remote friend-graph mutations,
/// leaderboard computation, challenge fanout, privacy-gated profiles,
/// and social event publishing.
protocol SocialServiceProtocol: AnyObject {

    // MARK: User Discovery
    func searchUsers(query: String, currentUserId: String) async throws -> [UserSearchResult]

    // MARK: Friend Management
    /// Notifies the backend that `fromUserId` sent a request to `toUserId`.
    /// Local FriendRelationship is inserted by the caller (FriendsViewModel).
    func sendFriendRequest(fromUserId: String, toUserId: String) async throws
    func acceptFriendRequest(relationshipId: String, userId: String) async throws
    func declineFriendRequest(relationshipId: String, userId: String) async throws
    func removeFriend(relationshipId: String, userId: String) async throws

    // MARK: Leaderboard (friends-only, current week)
    /// `currentUserValue` is pre-computed from local WorkoutRepository so no extra
    /// DB trip is needed inside the service.
    func fetchLeaderboard(
        type: LeaderboardType,
        friends: [FriendRelationship],
        currentUserId: String,
        currentUserDisplayName: String,
        currentUserUsername: String,
        currentUserValue: Double
    ) async throws -> [LeaderboardEntry]

    // MARK: Challenges
    /// Notify invitees on the backend; local Challenge creation is done by the caller.
    func notifyChallengeCreated(challengeId: String, title: String, creatorUserId: String, inviteeIds: [String]) async throws
    /// Returns mock/remote leaderboard for the given challenge.
    func fetchChallengeLeaderboard(
        challengeId: String,
        myUserId: String,
        myDisplayName: String,
        myUsername: String,
        myProgress: Double
    ) async throws -> [ChallengeParticipantEntry]

    // MARK: Privacy-Filtered Profile
    /// Server enforces the viewed user's privacy settings and returns only
    /// the fields they have opted to share. nil = hidden.
    func fetchPublicProfile(userId: String, viewerUserId: String) async throws -> PublicProfile

    // MARK: Social Event Fanout
    /// Publishes an activity event to the backend so it fans out to targetUserIds.
    /// The caller is responsible for creating a local FeedItem (isMine: true).
    func postSocialEvent(_ event: SocialNotificationEvent) async throws
}

// MARK: - Shared Provider (swap at app launch for production)

enum SocialServiceProvider {
    static var shared: SocialServiceProtocol = MockSocialService()
}

// MARK: - Mock Implementation

final class MockSocialService: SocialServiceProtocol {

    private func delay(_ ms: UInt64 = 350) async throws {
        try await Task.sleep(nanoseconds: ms * 1_000_000)
    }

    // MARK: User Discovery

    func searchUsers(query: String, currentUserId: String) async throws -> [UserSearchResult] {
        try await delay()
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return MockSocialData.allUsers
            .filter { $0.id != currentUserId }
            .filter { $0.username.lowercased().contains(q) || $0.displayName.lowercased().contains(q) }
    }

    // MARK: Friend Management

    func sendFriendRequest(fromUserId: String, toUserId: String) async throws {
        try await delay(200)
        // Backend: POST /friends/request { from, to }
    }

    func acceptFriendRequest(relationshipId: String, userId: String) async throws {
        try await delay(200)
        // Backend: PATCH /friends/{relationshipId}/accept
    }

    func declineFriendRequest(relationshipId: String, userId: String) async throws {
        try await delay(150)
        // Backend: DELETE /friends/{relationshipId}
    }

    func removeFriend(relationshipId: String, userId: String) async throws {
        try await delay(200)
        // Backend: DELETE /friends/{relationshipId}
    }

    // MARK: Leaderboard

    func fetchLeaderboard(
        type: LeaderboardType,
        friends: [FriendRelationship],
        currentUserId: String,
        currentUserDisplayName: String,
        currentUserUsername: String,
        currentUserValue: Double
    ) async throws -> [LeaderboardEntry] {
        try await delay()

        var raw: [(userId: String, displayName: String, username: String, avatarURL: String?, value: Double, isMe: Bool)] = [
            (currentUserId, currentUserDisplayName, currentUserUsername, nil, currentUserValue, true)
        ]

        for friend in friends {
            let mockValue: Double = type == .weeklyVolume
                ? Double.random(in: 400...9000).rounded()
                : Double(Int.random(in: 1...6))
            raw.append((friend.friendUserId, friend.friendDisplayName, friend.friendUsername, friend.friendAvatarURL, mockValue, false))
        }

        let sorted = raw.sorted { $0.value > $1.value }
        return sorted.enumerated().map { idx, e in
            LeaderboardEntry(rank: idx + 1, userId: e.userId, displayName: e.displayName,
                             username: e.username, avatarURL: e.avatarURL,
                             value: e.value, isCurrentUser: e.isMe)
        }
    }

    // MARK: Challenges

    func notifyChallengeCreated(challengeId: String, title: String, creatorUserId: String, inviteeIds: [String]) async throws {
        try await delay(300)
        // Backend: POST /challenges { id, title, creator, invitees }
        // Each invitee receives a push notification
    }

    func fetchChallengeLeaderboard(
        challengeId: String,
        myUserId: String,
        myDisplayName: String,
        myUsername: String,
        myProgress: Double
    ) async throws -> [ChallengeParticipantEntry] {
        try await delay()

        var entries: [ChallengeParticipantEntry] = [
            ChallengeParticipantEntry(userId: myUserId, displayName: myDisplayName, username: myUsername, progress: myProgress, rank: 0)
        ]
        for user in MockSocialData.allUsers.prefix(3) {
            entries.append(ChallengeParticipantEntry(
                userId: user.id, displayName: user.displayName,
                username: user.username, progress: Double.random(in: 0...100), rank: 0))
        }
        let sorted = entries.sorted { $0.progress > $1.progress }
        return sorted.enumerated().map { i, e in
            ChallengeParticipantEntry(userId: e.userId, displayName: e.displayName,
                                      username: e.username, progress: e.progress, rank: i + 1)
        }
    }

    // MARK: Privacy-Filtered Profile

    func fetchPublicProfile(userId: String, viewerUserId: String) async throws -> PublicProfile {
        try await delay()
        // In production: backend checks the viewed user's UserSettings (profileVisibility,
        // shareWorkouts*, etc.) and returns only what they allow.
        // Mock returns everything (no real user settings to check).
        guard let user = MockSocialData.allUsers.first(where: { $0.id == userId }) else {
            throw SocialServiceError.userNotFound
        }
        return PublicProfile(
            id: userId,
            displayName: user.displayName,
            username: user.username,
            avatarURL: nil,
            weeklyWorkouts: Int.random(in: 1...5),
            currentStreak: Int.random(in: 0...8),
            recentPRLabel: "Bench Press \(Int.random(in: 60...140))kg",
            totalWorkouts: user.workoutCount
        )
    }

    // MARK: Social Event Fanout

    func postSocialEvent(_ event: SocialNotificationEvent) async throws {
        try await delay(200)
        // Backend: POST /feed/events  { actor, type, body, targetUserIds, metadata }
        // Server fans out FeedItem to each targetUserId via push + persists in their feeds.
    }
}

// MARK: - Firebase Stub (wire up in production)

final class FirebaseSocialService: SocialServiceProtocol {

    // MARK: User Discovery
    func searchUsers(query: String, currentUserId: String) async throws -> [UserSearchResult] {
        // Firestore: collectionGroup("users").where("username", ">=", query)...
        throw SocialServiceError.networkUnavailable
    }

    // MARK: Friend Management
    func sendFriendRequest(fromUserId: String, toUserId: String) async throws {
        // Firestore: friends/{id} = { requesterId, receiverId, status: "pending" }
    }
    func acceptFriendRequest(relationshipId: String, userId: String) async throws {
        // Firestore: PATCH friends/{relationshipId}.status = "accepted"
    }
    func declineFriendRequest(relationshipId: String, userId: String) async throws {
        // Firestore: DELETE friends/{relationshipId}
    }
    func removeFriend(relationshipId: String, userId: String) async throws {
        // Firestore: DELETE friends/{relationshipId}
    }

    // MARK: Leaderboard
    func fetchLeaderboard(type: LeaderboardType, friends: [FriendRelationship], currentUserId: String, currentUserDisplayName: String, currentUserUsername: String, currentUserValue: Double) async throws -> [LeaderboardEntry] {
        // Cloud Function: GET /leaderboard?type={type}&userId={currentUserId}&weekStart={iso}
        // Returns aggregated weekly stats for currentUserId + each friendId
        throw SocialServiceError.networkUnavailable
    }

    // MARK: Challenges
    func notifyChallengeCreated(challengeId: String, title: String, creatorUserId: String, inviteeIds: [String]) async throws {
        // Cloud Function: POST /challenges { id, title, creatorUserId, inviteeIds }
    }
    func fetchChallengeLeaderboard(challengeId: String, myUserId: String, myDisplayName: String, myUsername: String, myProgress: Double) async throws -> [ChallengeParticipantEntry] {
        // Firestore: challenges/{challengeId}/participants ordered by progress desc
        throw SocialServiceError.networkUnavailable
    }

    // MARK: Privacy-Filtered Profile
    func fetchPublicProfile(userId: String, viewerUserId: String) async throws -> PublicProfile {
        // Cloud Function: GET /users/{userId}/profile?viewerId={viewerUserId}
        // Server fetches target user's UserSettings and strips hidden fields
        throw SocialServiceError.networkUnavailable
    }

    // MARK: Social Event Fanout
    func postSocialEvent(_ event: SocialNotificationEvent) async throws {
        // Cloud Function: POST /feed/events
        // Server writes FeedItem to each targetUserId's feed collection and sends APNs
    }
}

// MARK: - Mock Data

enum MockSocialData {
    static let allUsers: [UserSearchResult] = [
        UserSearchResult(id: "u002", username: "alexfit",          displayName: "Alex Chen",    avatarURL: nil, workoutCount: 87,  isAlreadyFriend: false, hasPendingRequest: false),
        UserSearchResult(id: "u003", username: "sarahruns",        displayName: "Sarah Miller", avatarURL: nil, workoutCount: 124, isAlreadyFriend: false, hasPendingRequest: false),
        UserSearchResult(id: "u004", username: "mike_lifts",       displayName: "Mike Torres",  avatarURL: nil, workoutCount: 42,  isAlreadyFriend: false, hasPendingRequest: false),
        UserSearchResult(id: "u005", username: "kettlebell_queen", displayName: "Jordan Lee",   avatarURL: nil, workoutCount: 201, isAlreadyFriend: false, hasPendingRequest: false),
        UserSearchResult(id: "u006", username: "benchpressking",   displayName: "Chris Park",   avatarURL: nil, workoutCount: 63,  isAlreadyFriend: false, hasPendingRequest: false),
    ]
}
