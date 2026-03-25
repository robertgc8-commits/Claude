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

    private var workoutRepo: WorkoutRepository?
    private var prRepo: PRRepository?
    private var userRepo: UserRepository?
    private var userId: String = ""
    private var context: ModelContext?

    init() {}

    func configure(context: ModelContext, userId: String) {
        self.context = context
        self.workoutRepo = WorkoutRepository(context: context)
        self.prRepo = PRRepository(context: context)
        self.userRepo = UserRepository(context: context)
        self.userId = userId
    }

    func loadDashboard() {
        guard let workoutRepo = workoutRepo,
              let prRepo = prRepo,
              let userRepo = userRepo else { return }
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
        guard let context = context else { return [] }
        let uid = userId
        let descriptor = FetchDescriptor<WeeklyStreakRecord>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.weekStartDate)]
        )
        return try context.fetch(descriptor)
    }
}
