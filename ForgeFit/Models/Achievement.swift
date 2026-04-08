import SwiftData
import Foundation

// AchievementDefinition is a value type — defined in code, not persisted
struct AchievementDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let iconName: String
    let condition: AchievementCondition

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: AchievementDefinition, rhs: AchievementDefinition) -> Bool { lhs.id == rhs.id }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case milestones = "Milestones"
    case consistency = "Consistency"
    case strength = "Strength"
    case volume = "Volume"
    case social = "Social"

    var color: String {
        switch self {
        case .milestones: return "ffGold"
        case .consistency: return "ffAccent"
        case .strength: return "ffRed"
        case .volume: return "ffOrange"
        case .social: return "ffPurple"
        }
    }
}

enum AchievementCondition: Hashable {
    case firstWorkout
    case workoutsCompleted(count: Int)
    case totalSetsLogged(count: Int)
    case firstPR
    case prsAchieved(count: Int)
    case consecutiveWeeks(count: Int)
    case workoutsInMuscleGroup(group: MuscleGroup, count: Int)
    case addedFirstFriend
    case friendsCount(count: Int)
    case totalVolumeLifted(kg: Double)
    case workoutStreak(weeks: Int)
    case earlyBirdWorkouts(count: Int)  // workouts started before 7am
    case lateNightWorkouts(count: Int)  // workouts started after 9pm
}

// Persisted unlock record
@Model
final class AchievementUnlock {
    var id: String
    var userId: String
    var achievementId: String
    var unlockedAt: Date
    var workoutId: String?  // what triggered the unlock

    init(
        id: String = UUID().uuidString,
        userId: String,
        achievementId: String,
        workoutId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.achievementId = achievementId
        self.unlockedAt = Date()
        self.workoutId = workoutId
    }
}

// MARK: - Achievement Library
extension AchievementDefinition {
    static let all: [AchievementDefinition] = [
        // Milestones
        AchievementDefinition(
            id: "first_workout",
            title: "First Rep",
            description: "Log your first workout.",
            category: .milestones,
            iconName: "flag.fill",
            condition: .firstWorkout
        ),
        AchievementDefinition(
            id: "workouts_10",
            title: "Ten Strong",
            description: "Complete 10 workouts.",
            category: .milestones,
            iconName: "10.circle.fill",
            condition: .workoutsCompleted(count: 10)
        ),
        AchievementDefinition(
            id: "workouts_25",
            title: "Quarter Century",
            description: "Complete 25 workouts.",
            category: .milestones,
            iconName: "25.circle.fill",
            condition: .workoutsCompleted(count: 25)
        ),
        AchievementDefinition(
            id: "workouts_50",
            title: "Fifty Strong",
            description: "Complete 50 workouts.",
            category: .milestones,
            iconName: "50.circle.fill",
            condition: .workoutsCompleted(count: 50)
        ),
        AchievementDefinition(
            id: "workouts_100",
            title: "The Century",
            description: "Complete 100 workouts.",
            category: .milestones,
            iconName: "100.circle.fill",
            condition: .workoutsCompleted(count: 100)
        ),
        // Volume
        AchievementDefinition(
            id: "sets_100",
            title: "100 Sets In",
            description: "Log 100 total sets across all workouts.",
            category: .volume,
            iconName: "list.number",
            condition: .totalSetsLogged(count: 100)
        ),
        AchievementDefinition(
            id: "sets_500",
            title: "500 Club",
            description: "Log 500 total sets.",
            category: .volume,
            iconName: "list.star",
            condition: .totalSetsLogged(count: 500)
        ),
        AchievementDefinition(
            id: "volume_10k",
            title: "10,000 kg Moved",
            description: "Lift a total of 10,000 kg across all workouts.",
            category: .volume,
            iconName: "scalemass.fill",
            condition: .totalVolumeLifted(kg: 10000)
        ),
        AchievementDefinition(
            id: "volume_100k",
            title: "100,000 kg Moved",
            description: "Lift a total of 100,000 kg.",
            category: .volume,
            iconName: "scalemass.fill",
            condition: .totalVolumeLifted(kg: 100000)
        ),
        // Strength
        AchievementDefinition(
            id: "first_pr",
            title: "New Heights",
            description: "Hit your first personal record.",
            category: .strength,
            iconName: "trophy.fill",
            condition: .firstPR
        ),
        AchievementDefinition(
            id: "prs_10",
            title: "Record Breaker",
            description: "Set 10 personal records.",
            category: .strength,
            iconName: "trophy.fill",
            condition: .prsAchieved(count: 10)
        ),
        AchievementDefinition(
            id: "prs_50",
            title: "Elite Level",
            description: "Set 50 personal records.",
            category: .strength,
            iconName: "medal.fill",
            condition: .prsAchieved(count: 50)
        ),
        // Consistency
        AchievementDefinition(
            id: "streak_2",
            title: "Locked In",
            description: "Hit your weekly target 2 weeks in a row.",
            category: .consistency,
            iconName: "flame",
            condition: .consecutiveWeeks(count: 2)
        ),
        AchievementDefinition(
            id: "streak_4",
            title: "Month Strong",
            description: "Hit your weekly target 4 weeks in a row.",
            category: .consistency,
            iconName: "flame.fill",
            condition: .consecutiveWeeks(count: 4)
        ),
        AchievementDefinition(
            id: "streak_8",
            title: "Two Months Solid",
            description: "Hit your weekly target 8 weeks in a row.",
            category: .consistency,
            iconName: "bolt.fill",
            condition: .consecutiveWeeks(count: 8)
        ),
        AchievementDefinition(
            id: "streak_12",
            title: "The Quarter",
            description: "Hit your weekly target for 12 consecutive weeks.",
            category: .consistency,
            iconName: "bolt.circle.fill",
            condition: .consecutiveWeeks(count: 12)
        ),
        // Muscle group specific
        AchievementDefinition(
            id: "chest_10",
            title: "Chest Day Devotee",
            description: "Complete 10 workouts with chest exercises.",
            category: .milestones,
            iconName: "figure.strengthtraining.traditional",
            condition: .workoutsInMuscleGroup(group: .chest, count: 10)
        ),
        AchievementDefinition(
            id: "legs_10",
            title: "Never Skip Legs",
            description: "Complete 10 workouts with leg exercises.",
            category: .milestones,
            iconName: "figure.walk",
            condition: .workoutsInMuscleGroup(group: .legs, count: 10)
        ),
        // Social
        AchievementDefinition(
            id: "first_friend",
            title: "Better Together",
            description: "Add your first friend.",
            category: .social,
            iconName: "person.badge.plus",
            condition: .addedFirstFriend
        ),
        AchievementDefinition(
            id: "friends_5",
            title: "Squad Goals",
            description: "Connect with 5 friends.",
            category: .social,
            iconName: "person.3.fill",
            condition: .friendsCount(count: 5)
        ),
    ]

    static func definition(for id: String) -> AchievementDefinition? {
        all.first { $0.id == id }
    }
}
