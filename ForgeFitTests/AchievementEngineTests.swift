import XCTest
@testable import ForgeFit

final class AchievementEngineTests: XCTestCase {

    func testFirstWorkoutUnlocks() {
        let context = makeContext(totalWorkouts: 1)
        let unlocked = AchievementEngine.evaluate(context: context)
        XCTAssertTrue(unlocked.contains { $0.id == "first_workout" })
    }

    func testFirstWorkoutNotUnlockedWithZero() {
        let context = makeContext(totalWorkouts: 0)
        let unlocked = AchievementEngine.evaluate(context: context)
        XCTAssertFalse(unlocked.contains { $0.id == "first_workout" })
    }

    func testTenWorkoutsUnlocks() {
        let context = makeContext(totalWorkouts: 10)
        let unlocked = AchievementEngine.evaluate(context: context)
        XCTAssertTrue(unlocked.contains { $0.id == "workouts_10" })
    }

    func testAlreadyUnlockedSkipped() {
        let context = makeContext(totalWorkouts: 10, alreadyUnlocked: ["workouts_10"])
        let unlocked = AchievementEngine.evaluate(context: context)
        XCTAssertFalse(unlocked.contains { $0.id == "workouts_10" })
    }

    func testStreakAchievement() {
        let context = makeContext(totalWorkouts: 5, currentStreak: 4)
        let unlocked = AchievementEngine.evaluate(context: context)
        XCTAssertTrue(unlocked.contains { $0.id == "streak_4" })
    }

    func testSocialAchievement() {
        let context = makeContext(totalWorkouts: 3, totalFriends: 1)
        let unlocked = AchievementEngine.evaluate(context: context)
        XCTAssertTrue(unlocked.contains { $0.id == "first_friend" })
    }

    // MARK: - Helpers

    private func makeContext(
        totalWorkouts: Int = 0,
        totalSets: Int = 0,
        totalVolumeKg: Double = 0,
        totalPRs: Int = 0,
        currentStreak: Int = 0,
        totalFriends: Int = 0,
        alreadyUnlocked: Set<String> = []
    ) -> AchievementEngine.EvaluationContext {
        let streak = StreakStatus(
            currentStreak: currentStreak, longestStreak: currentStreak,
            currentWeekCompleted: 0, currentWeekTarget: 4,
            isOnTrack: true, weeklyHistory: []
        )
        return AchievementEngine.EvaluationContext(
            userId: "test",
            totalWorkouts: totalWorkouts,
            totalSets: totalSets,
            totalVolumeKg: totalVolumeKg,
            totalPRs: totalPRs,
            currentStreak: currentStreak,
            totalFriends: totalFriends,
            workoutsPerMuscleGroup: [:],
            alreadyUnlocked: alreadyUnlocked,
            triggeringWorkout: nil
        )
    }
}
