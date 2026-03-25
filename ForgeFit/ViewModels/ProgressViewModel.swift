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

    // Body weight
    @Published var bodyWeightEntries: [BodyWeightEntry] = []
    @Published var showingBodyWeightInput = false
    @Published var bodyWeightInput: String = ""

    // Muscle group frequency
    @Published var muscleGroupFrequency: [(group: MuscleGroup, count: Int)] = []

    private var prRepo: PRRepository?
    private var workoutRepo: WorkoutRepository?
    private var userId: String = ""
    private var context: ModelContext?

    init() {}

    func configure(context: ModelContext, userId: String) {
        self.context = context
        self.prRepo = PRRepository(context: context)
        self.workoutRepo = WorkoutRepository(context: context)
        self.userId = userId
    }

    func load() {
        guard let prRepo, let workoutRepo else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            personalRecords = try prRepo.fetchAllPRs(userId: userId)
            let workouts = try workoutRepo.fetchCompletedWorkouts(userId: userId)

            let names = Set(workouts.flatMap { $0.exercises ?? [] }.map { $0.exerciseName })
            exerciseNames = names.sorted()

            if let first = exerciseNames.first, selectedExercise == nil {
                selectExercise(first, workouts: workouts)
            }

            buildMuscleGroupFrequency(from: workouts)
            loadBodyWeight()
        } catch {
            print("ProgressViewModel load error: \(error)")
        }
    }

    func selectExercise(_ name: String) {
        selectedExercise = name
        let workouts = (try? workoutRepo?.fetchCompletedWorkouts(userId: userId)) ?? []
        selectExercise(name, workouts: workouts)
    }

    private func selectExercise(_ name: String, workouts: [Workout]) {
        selectedExercise = name
        volumeTrend = ProgressOverloadEngine.computeVolumeTrend(
            exerciseName: name, historicalWorkouts: workouts)
        lastSessionSummary = ProgressOverloadEngine.lastSessionSummary(
            exerciseName: name, workouts: workouts)
        historicalSets = workouts
            .flatMap { $0.exercises ?? [] }
            .filter { $0.exerciseName == name }
            .flatMap { $0.completedSets }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    var prsByExercise: [String: [PersonalRecord]] {
        Dictionary(grouping: personalRecords) { $0.exerciseName }
    }

    /// Estimated 1RM for a PR (Brzycki formula)
    func estimated1RM(for pr: PersonalRecord) -> Double? {
        guard pr.reps > 0 && pr.reps < 37 && pr.weight > 0 else { return nil }
        if pr.reps == 1 { return pr.weight }
        return pr.weight / (1.0278 - 0.0278 * Double(pr.reps))
    }

    // MARK: - Muscle Group Frequency

    private func buildMuscleGroupFrequency(from workouts: [Workout]) {
        var counts: [MuscleGroup: Int] = [:]
        for workout in workouts {
            let groups = Set((workout.exercises ?? []).map { $0.muscleGroup })
            for group in groups { counts[group, default: 0] += 1 }
        }
        muscleGroupFrequency = counts
            .map { (group: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Body Weight

    func loadBodyWeight() {
        guard let ctx = context else { return }
        let uid = userId
        let descriptor = FetchDescriptor<BodyWeightEntry>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        bodyWeightEntries = (try? ctx.fetch(descriptor)) ?? []
    }

    func logBodyWeight() {
        guard let ctx = context,
              let value = Double(bodyWeightInput.replacingOccurrences(of: ",", with: ".")),
              value > 0 else { return }
        let entry = BodyWeightEntry(userId: userId, weightKg: value)
        ctx.insert(entry)
        do {
            try ctx.save()
        } catch {
            print("Body weight save error: \(error)")
        }
        bodyWeightInput = ""
        showingBodyWeightInput = false
        loadBodyWeight()
    }

    func deleteBodyWeightEntry(_ entry: BodyWeightEntry) {
        guard let ctx = context else { return }
        ctx.delete(entry)
        try? ctx.save()
        loadBodyWeight()
    }

    var latestBodyWeight: BodyWeightEntry? { bodyWeightEntries.first }

    var bodyWeightTrend: Double? {
        guard bodyWeightEntries.count >= 2 else { return nil }
        return bodyWeightEntries[0].weightKg - bodyWeightEntries[1].weightKg
    }
}
