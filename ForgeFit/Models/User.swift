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
    var weeklyWorkoutTarget: Int
    var preferredWeightUnit: WeightUnit

    // Workout behaviour
    var restTimerDuration: Int      // seconds between sets (default 90)
    var defaultWeightIncrement: Double  // kg added per progressive overload step (default 2.5)

    // Onboarding / goals
    var fitnessGoal: FitnessGoal
    var experienceLevel: ExperienceLevel
    var startingWeightKg: Double?
    var targetWeightKg: Double?

    // Privacy
    var isProfileDiscoverable: Bool
    var profileVisibility: ProfileVisibility
    var shareWorkoutTitles: Bool
    var shareExerciseNames: Bool
    var shareSetsRepsWeight: Bool
    var sharePRs: Bool
    var shareStreaks: Bool
    var shareAchievements: Bool

    // Friend notifications
    var notifyFriendsOnWorkout: Bool
    var notifyFriendsOnPR: Bool
    var notifyFriendsOnStreak: Bool
    var notifyFriendsOnAchievement: Bool

    // Personal notifications
    var receiveStreakReminders: Bool
    var receiveFriendActivityNotifs: Bool
    var receiveInactivityReminders: Bool
    var receiveWeeklyReport: Bool
    var streakReminderHour: Int
    var inactivityThresholdDays: Int

    init(userId: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.weeklyWorkoutTarget = 4
        self.preferredWeightUnit = .kg
        self.restTimerDuration = 90
        self.defaultWeightIncrement = 2.5
        self.fitnessGoal = .buildMuscle
        self.experienceLevel = .intermediate
        self.startingWeightKg = nil
        self.targetWeightKg = nil
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

// MARK: - Enums

enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"

    var label: String { rawValue }

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        if self == target { return value }
        if self == .kg && target == .lbs { return value * 2.20462 }
        return value / 2.20462
    }

    /// Sensible weight increment for progressive overload
    var defaultIncrement: Double { self == .kg ? 2.5 : 5.0 }
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

enum FitnessGoal: String, Codable, CaseIterable {
    case loseFat       = "lose_fat"
    case buildMuscle   = "build_muscle"
    case improveFitness = "improve_fitness"

    var label: String {
        switch self {
        case .loseFat:        return "Lose Fat"
        case .buildMuscle:    return "Build Muscle"
        case .improveFitness: return "Improve Fitness"
        }
    }

    var icon: String {
        switch self {
        case .loseFat:        return "flame.fill"
        case .buildMuscle:    return "dumbbell.fill"
        case .improveFitness: return "heart.fill"
        }
    }

    var description: String {
        switch self {
        case .loseFat:
            return "Focus on calorie-burning workouts and maintaining muscle"
        case .buildMuscle:
            return "Progressive overload and compound movements for size and strength"
        case .improveFitness:
            return "A balanced mix of strength, cardio, and endurance work"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner     = "beginner"
    case intermediate = "intermediate"
    case advanced     = "advanced"

    var label: String { rawValue.capitalized }

    var description: String {
        switch self {
        case .beginner:
            return "Less than 1 year of consistent training"
        case .intermediate:
            return "1–3 years of consistent training"
        case .advanced:
            return "3+ years and comfortable with most lifts"
        }
    }

    /// Multiplier applied to default starting weights for new exercises
    var weightSeedMultiplier: Double {
        switch self {
        case .beginner:     return 0.4
        case .intermediate: return 0.7
        case .advanced:     return 1.0
        }
    }
}
