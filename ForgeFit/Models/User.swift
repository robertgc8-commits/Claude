import SwiftData
import Foundation

@Model
final class User {
    var id: String
    var username: String
    var displayName: String
    var email: String
    var avatarURL: String?
    var bio: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var settings: UserSettings?
    @Relationship(deleteRule: .cascade) var workouts: [Workout]?
    @Relationship(deleteRule: .cascade) var achievementUnlocks: [AchievementUnlock]?
    @Relationship(deleteRule: .cascade) var streakRecords: [WeeklyStreakRecord]?
    @Relationship(deleteRule: .cascade) var friends: [FriendRelationship]?
    @Relationship(deleteRule: .cascade) var feedItems: [FeedItem]?

    init(
        id: String = UUID().uuidString,
        username: String,
        displayName: String,
        email: String,
        avatarURL: String? = nil,
        bio: String? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
        self.bio = bio
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class UserSettings {
    var id: String
    var userId: String
    var weeklyWorkoutTarget: Int  // 2-6 workouts per week
    var preferredWeightUnit: WeightUnit

    // Privacy
    var isProfileDiscoverable: Bool
    var profileVisibility: ProfileVisibility
    var shareWorkoutTitles: Bool
    var shareExerciseNames: Bool
    var shareSetsRepsWeight: Bool
    var sharePRs: Bool
    var shareStreaks: Bool
    var shareAchievements: Bool

    // Friend notifications (what friends get when I do things)
    var notifyFriendsOnWorkout: Bool
    var notifyFriendsOnPR: Bool
    var notifyFriendsOnStreak: Bool
    var notifyFriendsOnAchievement: Bool

    // Personal notifications
    var receiveStreakReminders: Bool
    var receiveFriendActivityNotifs: Bool
    var receiveInactivityReminders: Bool
    var receiveWeeklyReport: Bool
    var streakReminderHour: Int  // 0-23 hour of day
    var inactivityThresholdDays: Int

    init(userId: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.weeklyWorkoutTarget = 4
        self.preferredWeightUnit = .kg
        self.isProfileDiscoverable = true
        self.profileVisibility = .friends
        self.shareWorkoutTitles = true
        self.shareExerciseNames = true
        self.shareSetsRepsWeight = false
        self.sharePRs = true
        self.shareStreaks = true
        self.shareAchievements = true
        self.notifyFriendsOnWorkout = true
        self.notifyFriendsOnPR = true
        self.notifyFriendsOnStreak = true
        self.notifyFriendsOnAchievement = true
        self.receiveStreakReminders = true
        self.receiveFriendActivityNotifs = true
        self.receiveInactivityReminders = true
        self.receiveWeeklyReport = true
        self.streakReminderHour = 18
        self.inactivityThresholdDays = 3
    }
}

enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"

    var label: String { rawValue }

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        if self == target { return value }
        if self == .kg && target == .lbs { return value * 2.20462 }
        return value / 2.20462
    }
}

enum ProfileVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"

    var label: String {
        switch self {
        case .public: return "Everyone"
        case .friends: return "Friends Only"
        case .private: return "Only Me"
        }
    }
}
