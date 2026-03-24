import Foundation
import SwiftData
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recentWorkouts: [Workout] = []
    @Published var streakStatus: StreakStatus = StreakStatus(
        currentStreak: 0, longestStreak: 0,
        currentWeekCompleted: 0, currentWeekTarget: 4,
        isOnTrack: true, weeklyHistory: []
    )
    @Published var recentPRs: [PersonalRecord] = []
    @Published var weeklyWorkoutCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let workoutRepo: WorkoutRepository
    private let prRepo: PRRepository
    private let userRepo: UserRepository
    private let userId: String

    init(context: ModelContext, userId: String) {
        self.workoutRepo = WorkoutRepository(context: context)
        self.prRepo = PRRepository(context: context)
        self.userRepo = UserRepository(context: context)
        self.userId = userId
    }

    func loadDashboard() {
        isLoading = true
        do {
            let allWorkouts = try workoutRepo.fetchCompletedWorkouts(userId: userId)
            let weeklyRecords = try fetchWeeklyRecords()
            let settings = try userRepo.fetchSettings(userId: userId)
            let target = settings?.weeklyWorkoutTarget ?? 4

            // Recent workouts (last 5)
            recentWorkouts = Array(allWorkouts.prefix(5))

            // This week count
            let thisWeekWorkouts = try workoutRepo.fetchWorkoutsThisWeek(userId: userId)
            weeklyWorkoutCount = thisWeekWorkouts.count

            // Streak
            streakStatus = StreakEngine.computeStreakStatus(
                workouts: allWorkouts,
                weeklyRecords: weeklyRecords,
                target: target
            )

            // Recent PRs
            recentPRs = try prRepo.fetchRecentPRs(userId: userId, limit: 3)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchWeeklyRecords() throws -> [WeeklyStreakRecord] {
        // Fetch from SwiftData — simplified descriptor
        return []
    }
}
