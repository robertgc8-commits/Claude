import Foundation
import SwiftData

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var personalRecords: [PersonalRecord] = []
    @Published var exerciseNames: [String] = []
    @Published var selectedExercise: String?
    @Published var volumeTrend: ProgressOverloadEngine.VolumeTrend?
    @Published var lastSessionSummary: ProgressOverloadEngine.LastSessionSummary?
    @Published var historicalSets: [ExerciseSet] = []
    @Published var isLoading = false

    private let prRepo: PRRepository
    private let workoutRepo: WorkoutRepository
    private let userId: String

    init(context: ModelContext, userId: String) {
        self.prRepo = PRRepository(context: context)
        self.workoutRepo = WorkoutRepository(context: context)
        self.userId = userId
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            personalRecords = try prRepo.fetchAllPRs(userId: userId)
            let workouts = try workoutRepo.fetchCompletedWorkouts(userId: userId)

            // Build unique exercise list
            let names = Set(workouts.flatMap { $0.exercises ?? [] }.map { $0.exerciseName })
            exerciseNames = names.sorted()

            if let first = exerciseNames.first, selectedExercise == nil {
                selectExercise(first, workouts: workouts)
            }
        } catch {
            print("ProgressViewModel load error: \(error)")
        }
    }

    func selectExercise(_ name: String) {
        selectedExercise = name
        let workouts = (try? workoutRepo.fetchCompletedWorkouts(userId: userId)) ?? []
        selectExercise(name, workouts: workouts)
    }

    private func selectExercise(_ name: String, workouts: [Workout]) {
        selectedExercise = name
        volumeTrend = ProgressOverloadEngine.computeVolumeTrend(
            exerciseName: name, historicalWorkouts: workouts
        )
        lastSessionSummary = ProgressOverloadEngine.lastSessionSummary(
            exerciseName: name, workouts: workouts
        )
        // Flatten all sets for this exercise across history
        historicalSets = workouts
            .flatMap { $0.exercises ?? [] }
            .filter { $0.exerciseName == name }
            .flatMap { $0.completedSets }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    var prsByExercise: [String: [PersonalRecord]] {
        Dictionary(grouping: personalRecords) { $0.exerciseName }
    }
}
