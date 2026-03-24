import Foundation
import SwiftData

/// Evaluates which achievements should be unlocked given current user stats.
/// Designed to be called after any state change (workout complete, PR set, friend added).
final class AchievementEngine {

    struct EvaluationContext {
        let userId: String
        let totalWorkouts: Int
        let totalSets: Int
        let totalVolumeKg: Double
        let totalPRs: Int
        let currentStreak: Int
        let totalFriends: Int
        let workoutsPerMuscleGroup: [MuscleGroup: Int]
        let alreadyUnlocked: Set<String>  // achievement IDs
        let triggeringWorkout: Workout?
    }

    /// Returns list of newly unlocked achievements.
    static func evaluate(context: EvaluationContext) -> [AchievementDefinition] {
        AchievementDefinition.all.compactMap { definition in
            guard !context.alreadyUnlocked.contains(definition.id) else { return nil }
            return isUnlocked(definition: definition, context: context) ? definition : nil
        }
    }

    private static func isUnlocked(
        definition: AchievementDefinition,
        context: EvaluationContext
    ) -> Bool {
        switch definition.condition {
        case .firstWorkout:
            return context.totalWorkouts >= 1

        case .workoutsCompleted(let count):
            return context.totalWorkouts >= count

        case .totalSetsLogged(let count):
            return context.totalSets >= count

        case .firstPR:
            return context.totalPRs >= 1

        case .prsAchieved(let count):
            return context.totalPRs >= count

        case .consecutiveWeeks(let count):
            return context.currentStreak >= count

        case .workoutsInMuscleGroup(let group, let count):
            return (context.workoutsPerMuscleGroup[group] ?? 0) >= count

        case .addedFirstFriend:
            return context.totalFriends >= 1

        case .friendsCount(let count):
            return context.totalFriends >= count

        case .totalVolumeLifted(let kg):
            return context.totalVolumeKg >= kg

        case .workoutStreak(let weeks):
            return context.currentStreak >= weeks

        case .earlyBirdWorkouts(let count):
            // This requires additional context; skipped in basic eval
            return false

        case .lateNightWorkouts(let count):
            return false
        }
    }

    // MARK: - Context Builder

    static func buildContext(
        userId: String,
        workouts: [Workout],
        personalRecords: [PersonalRecord],
        streakStatus: StreakStatus,
        friends: [FriendRelationship],
        unlockedIds: Set<String>,
        triggeringWorkout: Workout? = nil
    ) -> EvaluationContext {
        let completedWorkouts = workouts.filter { $0.isCompleted }
        let allSets = completedWorkouts.flatMap { $0.exercises ?? [] }.flatMap { $0.sets ?? [] }.filter { $0.isCompleted }

        var muscleGroupCounts: [MuscleGroup: Int] = [:]
        for workout in completedWorkouts {
            let groups = Set((workout.exercises ?? []).map { $0.muscleGroup })
            for group in groups {
                muscleGroupCounts[group, default: 0] += 1
            }
        }

        return EvaluationContext(
            userId: userId,
            totalWorkouts: completedWorkouts.count,
            totalSets: allSets.count,
            totalVolumeKg: completedWorkouts.reduce(0) { $0 + $1.totalVolume },
            totalPRs: personalRecords.filter { $0.isActive }.count,
            currentStreak: streakStatus.currentStreak,
            totalFriends: friends.filter { $0.status == .accepted }.count,
            workoutsPerMuscleGroup: muscleGroupCounts,
            alreadyUnlocked: unlockedIds,
            triggeringWorkout: triggeringWorkout
        )
    }

    // MARK: - Persist

    static func persistUnlocks(
        _ definitions: [AchievementDefinition],
        userId: String,
        workoutId: String?,
        context: ModelContext
    ) -> [AchievementUnlock] {
        definitions.map { def in
            let unlock = AchievementUnlock(userId: userId, achievementId: def.id, workoutId: workoutId)
            context.insert(unlock)
            return unlock
        }
    }
}
