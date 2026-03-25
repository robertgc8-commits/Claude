import Foundation
import SwiftData

@MainActor
final class WorkoutHistoryViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filterMuscleGroup: MuscleGroup? = nil

    private var workoutRepo: WorkoutRepository?
    private var userId: String = ""

    init() {}

    func configure(context: ModelContext, userId: String) {
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
        return result
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
        guard let repo = workoutRepo else { return }
        repo.deleteWorkout(workout)
        try? repo.save()
        load()
    }

    func duplicateWorkout(_ workout: Workout) -> Workout? {
        guard let repo = workoutRepo else { return nil }
        let copy = repo.duplicateWorkout(workout, userId: userId)
        try? repo.save()
        return copy
    }
}
