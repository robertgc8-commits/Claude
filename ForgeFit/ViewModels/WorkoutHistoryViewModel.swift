import Foundation
import SwiftData

@MainActor
final class WorkoutHistoryViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterMuscleGroup: MuscleGroup? = nil
    @Published var filterStartDate: Date? = nil
    @Published var filterEndDate: Date? = nil

    private var workoutRepo: WorkoutRepository?
    private var context: ModelContext?
    private var userId: String = ""

    init() {}

    func configure(context: ModelContext, userId: String) {
        self.context = context
        self.workoutRepo = WorkoutRepository(context: context)
        self.userId = userId
    }

    var filtered: [Workout] {
        var result = workouts
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let group = filterMuscleGroup {
            result = result.filter { w in
                (w.exercises ?? []).contains { $0.muscleGroup == group }
            }
        }
        if let start = filterStartDate {
            result = result.filter { w in
                (w.completedAt ?? w.startedAt) >= start
            }
        }
        if let end = filterEndDate {
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
            result = result.filter { w in
                (w.completedAt ?? w.startedAt) <= endOfDay
            }
        }
        return result
    }

    var isDateFiltered: Bool { filterStartDate != nil || filterEndDate != nil }

    func clearDateFilter() {
        filterStartDate = nil
        filterEndDate = nil
    }

    // Group workouts by month for section headers
    var groupedWorkouts: [(key: String, value: [Workout])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: filtered) {
            formatter.string(from: $0.startedAt)
        }
        return grouped.sorted { a, b in
            let fa = filtered.first { formatter.string(from: $0.startedAt) == a.key }?.startedAt ?? Date()
            let fb = filtered.first { formatter.string(from: $0.startedAt) == b.key }?.startedAt ?? Date()
            return fa > fb
        }
    }

    func load() {
        guard let repo = workoutRepo else { return }
        isLoading = true
        defer { isLoading = false }
        workouts = (try? repo.fetchCompletedWorkouts(userId: userId)) ?? []
    }

    func deleteWorkout(_ workout: Workout) {
        guard let repo = workoutRepo, let context else { return }
        let prRepo = PRRepository(context: context)
        try? prRepo.invalidatePRs(forWorkoutId: workout.id)
        repo.deleteWorkout(workout)
        try? repo.save()
        load()
    }

    func duplicateWorkout(_ workout: Workout) -> Workout? {
        guard let repo = workoutRepo else { return nil }
        let copy = repo.duplicateWorkout(workout, userId: userId)
        try? repo.save()
        load()
        return copy
    }

    // MARK: - Edit

    /// Updates title and/or date of a completed workout.
    /// `completedAt` is shifted to preserve the original duration relative to the new start.
    func updateWorkout(_ workout: Workout, title: String? = nil, date: Date? = nil) {
        if let title, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            workout.title = title
        }
        if let newStart = date {
            let duration = workout.durationSeconds ?? 0
            workout.startedAt = newStart
            workout.completedAt = newStart.addingTimeInterval(Double(duration))
        }
        try? workoutRepo?.save()
        load()
    }

    // MARK: - PR Recomputation

    /// Invalidates all PRs from `workout`, then re-evaluates each completed working set
    /// against the full workout history to restore accurate personal records.
    func recomputePRs(for workout: Workout) {
        guard let context else { return }
        let prRepo = PRRepository(context: context)
        let repo = WorkoutRepository(context: context)

        try? prRepo.invalidatePRs(forWorkoutId: workout.id)

        let allWorkouts = (try? repo.fetchCompletedWorkouts(userId: userId)) ?? []

        for exercise in (workout.exercises ?? []) {
            let workingSets = exercise.completedSets.filter { !$0.isWarmup }
            for set in workingSets {
                guard set.weight > 0 && set.reps > 0 else { continue }
                let historical = allWorkouts
                    .filter { $0.id != workout.id }
                    .flatMap { $0.exercises ?? [] }
                    .filter { $0.exerciseName == exercise.exerciseName }
                    .flatMap { $0.sets ?? [] }
                let existingPRs = (try? prRepo.fetchPRs(userId: userId, exerciseName: exercise.exerciseName)) ?? []
                let results = ProgressOverloadEngine.detectPRs(
                    currentSet: set,
                    exerciseName: exercise.exerciseName,
                    historicalSets: historical,
                    existingPRs: existingPRs
                )
                if !results.isEmpty {
                    let _ = prRepo.processPRs(
                        results: results,
                        exerciseName: exercise.exerciseName,
                        setId: set.id,
                        workoutId: workout.id,
                        userId: userId,
                        achievedAt: workout.completedAt ?? workout.startedAt
                    )
                }
            }
        }
        try? prRepo.save()
    }
}
