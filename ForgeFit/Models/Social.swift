import SwiftData
import Foundation

enum FriendStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
}

@Model
final class FriendRelationship {
    var id: String
    var requesterId: String
    var receiverId: String
    var status: FriendStatus
    var createdAt: Date
    var updatedAt: Date

    // Denormalized for display (synced from remote)
    var friendUserId: String   // the other user's ID
    var friendUsername: String
    var friendDisplayName: String
    var friendAvatarURL: String?

    init(
        id: String = UUID().uuidString,
        requesterId: String,
        receiverId: String,
        friendUserId: String,
        friendUsername: String,
        friendDisplayName: String,
        friendAvatarURL: String? = nil,
        status: FriendStatus = .pending
    ) {
        self.id = id
        self.requesterId = requesterId
        self.receiverId = receiverId
        self.friendUserId = friendUserId
        self.friendUsername = friendUsername
        self.friendDisplayName = friendDisplayName
        self.friendAvatarURL = friendAvatarURL
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum FeedItemType: String, Codable {
    case workoutCompleted = "workout_completed"
    case prAchieved = "pr_achieved"
    case streakMilestone = "streak_milestone"
    case achievementUnlocked = "achievement_unlocked"
}

@Model
final class FeedItem {
    var id: String
    var actorUserId: String
    var actorUsername: String
    var actorDisplayName: String
    var actorAvatarURL: String?
    var itemType: FeedItemType
    var title: String
    var body: String
    var metadata: String   // JSON string for type-specific data
    var createdAt: Date
    var isRead: Bool
    var isMine: Bool       // true if this is my own activity

    init(
        id: String = UUID().uuidString,
        actorUserId: String,
        actorUsername: String,
        actorDisplayName: String,
        actorAvatarURL: String? = nil,
        itemType: FeedItemType,
        title: String,
        body: String,
        metadata: String = "{}",
        isMine: Bool = false
    ) {
        self.id = id
        self.actorUserId = actorUserId
        self.actorUsername = actorUsername
        self.actorDisplayName = actorDisplayName
        self.actorAvatarURL = actorAvatarURL
        self.itemType = itemType
        self.title = title
        self.body = body
        self.metadata = metadata
        self.createdAt = Date()
        self.isRead = false
        self.isMine = isMine
    }

    var typeIcon: String {
        switch itemType {
        case .workoutCompleted: return "checkmark.circle.fill"
        case .prAchieved: return "trophy.fill"
        case .streakMilestone: return "flame.fill"
        case .achievementUnlocked: return "star.fill"
        }
    }
}

// MARK: - User Search (remote DTO)

struct UserSearchResult: Identifiable, Hashable {
    let id: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let workoutCount: Int
    let isAlreadyFriend: Bool
    let hasPendingRequest: Bool
}

// MARK: - Leaderboard

enum LeaderboardType: String, CaseIterable {
    case weeklyVolume   = "weekly_volume"
    case weeklyWorkouts = "weekly_workouts"

    var label: String {
        switch self {
        case .weeklyVolume:   return "Volume"
        case .weeklyWorkouts: return "Workouts"
        }
    }
    var unit: String {
        switch self {
        case .weeklyVolume:   return "kg"
        case .weeklyWorkouts: return ""
        }
    }
    var icon: String {
        switch self {
        case .weeklyVolume:   return "scalemass.fill"
        case .weeklyWorkouts: return "checkmark.circle.fill"
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let rank: Int
    let userId: String
    let displayName: String
    let username: String
    let avatarURL: String?
    let value: Double
    let isCurrentUser: Bool
    var id: String { userId }
}

// MARK: - Privacy-Filtered Public Profile

/// All optional fields are nil when the viewed user's privacy settings hide them.
/// Filtering is enforced server-side; the client renders whatever is non-nil.
struct PublicProfile: Identifiable {
    let id: String
    let displayName: String
    let username: String
    let avatarURL: String?
    let weeklyWorkouts: Int?
    let currentStreak: Int?
    let recentPRLabel: String?
    let totalWorkouts: Int?
}

// MARK: - Social Event (fanout payload)

struct SocialNotificationEvent {
    let actorUserId: String
    let actorUsername: String
    let actorDisplayName: String
    let type: FeedItemType
    let title: String
    let body: String
    let targetUserIds: [String]
    let metadata: [String: String]
}

// MARK: - Challenge

enum ChallengeType: String, Codable, CaseIterable {
    case volume       = "volume"
    case workoutCount = "workout_count"

    var label: String {
        switch self {
        case .volume:       return "Total Volume"
        case .workoutCount: return "Workout Count"
        }
    }
    var unit: String {
        switch self {
        case .volume:       return "kg"
        case .workoutCount: return "workouts"
        }
    }
    var icon: String {
        switch self {
        case .volume:       return "scalemass.fill"
        case .workoutCount: return "checkmark.circle.fill"
        }
    }
}

enum ChallengeStatus: String, Codable {
    case active    = "active"
    case completed = "completed"
    case expired   = "expired"
}

@Model
final class Challenge {
    var id: String
    var title: String
    var challengeType: ChallengeType
    var goal: Double
    var startDate: Date
    var endDate: Date
    var creatorUserId: String
    /// JSON-encoded [String] of participant user IDs.
    var participantIdsJSON: String
    var status: ChallengeStatus
    /// Locally tracked progress for the current user.
    var myProgress: Double
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        challengeType: ChallengeType,
        goal: Double,
        startDate: Date = Date(),
        endDate: Date,
        creatorUserId: String,
        participantIds: [String] = []
    ) {
        self.id = id
        self.title = title
        self.challengeType = challengeType
        self.goal = goal
        self.startDate = startDate
        self.endDate = endDate
        self.creatorUserId = creatorUserId
        self.participantIdsJSON = (try? String(data: JSONEncoder().encode(participantIds), encoding: .utf8)) ?? "[]"
        self.status = .active
        self.myProgress = 0
        self.createdAt = Date()
    }

    var participantIds: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(participantIdsJSON.utf8))) ?? [] }
        set { participantIdsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var progressFraction: Double { goal > 0 ? min(1.0, myProgress / goal) : 0 }
    var isExpired: Bool { Date() > endDate }
    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
}

struct ChallengeParticipantEntry: Identifiable {
    let userId: String
    let displayName: String
    let username: String
    let progress: Double
    let rank: Int
    var id: String { userId }
}
