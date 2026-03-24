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
