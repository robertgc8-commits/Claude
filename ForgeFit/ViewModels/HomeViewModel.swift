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

    // FEATURE 2: Calendar heatmap — normalized day → workout count
    @Published var calendarWorkouts: [Date: Int] = [:]

    // FEATURE 3: All-time stats
    @Published var totalWorkouts: Int = 0
    @Published var totalWeightLifted: Double = 0
    @Published var totalWorkoutMinutes: Int = 0

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

            // FEATURE 2: Calendar heatmap
            buildCalendarWorkouts(from: allWorkouts)

            // FEATURE 3: All-time stats
            computeAllTimeStats(from: allWorkouts)
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

    // MARK: - Feature 2: Calendar heatmap

    private func buildCalendarWorkouts(from workouts: [Workout]) {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for workout in workouts {
            guard let completedAt = workout.completedAt else { continue }
            let day = calendar.startOfDay(for: completedAt)
            counts[day, default: 0] += 1
        }
        calendarWorkouts = counts
    }

    // MARK: - Feature 3: All-time stats

    private func computeAllTimeStats(from workouts: [Workout]) {
        totalWorkouts = workouts.count

        var volume: Double = 0
        var minutes: Int = 0
        for workout in workouts {
            volume += workout.totalVolume
            if let dur = workout.durationSeconds {
                minutes += dur / 60
            }
        }
        totalWeightLifted = volume
        totalWorkoutMinutes = minutes
    }
}
