import Foundation
import SwiftData
import Combine

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {
    @Published var workout: Workout
    @Published var exercises: [WorkoutExercise] = []
    @Published var isFinished: Bool = false
    @Published var newlyUnlockedAchievements: [AchievementDefinition] = []
    @Published var newPRs: [PersonalRecord] = []
    @Published var elapsedSeconds: Int = 0
    @Published var lastSessionSummaries: [String: ProgressOverloadEngine.LastSessionSummary] = [:]
    @Published var suggestions: [String: ProgressOverloadEngine.OverloadSuggestion] = [:]

    // Rest timer
    @Published var restTimerRemaining: Int? = nil
    @Published var restTimerTotal: Int = 90
    private var restTimerTask: Task<Void, Never>?

    private let workoutRepo: WorkoutRepository
    private let prRepo: PRRepository
    private let context: ModelContext
    private let userId: String
    private var workoutTimer: Timer?
    private var allWorkouts: [Workout] = []
    private var settings: UserSettings?

    init(context: ModelContext, userId: String, workout: Workout) {
        self.context = context
        self.userId = userId
        self.workout = workout
        self.workoutRepo = WorkoutRepository(context: context)
        self.prRepo = PRRepository(context: context)
        self.exercises = (workout.exercises ?? []).sorted { $0.order < $1.order }
        startWorkoutTimer()
        loadHistory()
    }

    // MARK: - Workout Timer

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor [weak self] in self?.elapsedSeconds += 1 }
        }
    }

    var elapsedFormatted: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int = 90) {
        restTimerTask?.cancel()
        restTimerTotal = seconds
        restTimerRemaining = seconds
        restTimerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while let remaining = self.restTimerRemaining, remaining > 0 {
                do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch { return }
                guard self.restTimerRemaining != nil else { return }
                self.restTimerRemaining = (self.restTimerRemaining ?? 1) - 1
                if self.restTimerRemaining == 0 {
                    HapticFeedback.success()
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if self.restTimerRemaining == 0 { self.restTimerRemaining = nil }
                }
            }
        }
    }

    func skipRestTimer() {
        restTimerTask?.cancel()
        restTimerTask = nil
        restTimerRemaining = nil
    }

    // MARK: - Exercises

    func addExercise(name: String, muscleGroup: MuscleGroup, templateId: String? = nil, initialSets: [(reps: Int, weight: Double)] = []) {
        let exercise = WorkoutExercise(
            workoutId: workout.id,
            exerciseName: name,
            exerciseTemplateId: templateId,
            muscleGroup: muscleGroup,
            order: exercises.count
        )
        exercise.sets = []
        context.insert(exercise)
        exercises.append(exercise)

        if initialSets.isEmpty {
            addDefaultSet(to: exercise)
        } else {
            for (i, entry) in initialSets.enumerated() {
                let set = ExerciseSet(
                    workoutExerciseId: exercise.id,
                    setNumber: i + 1,
                    reps: entry.reps,
                    weight: entry.weight
                )
                exercise.sets?.append(set)
                context.insert(set)
            }
        }
        try? context.save()
        loadSuggestion(for: exercise)
    }

    func removeExercise(_ exercise: WorkoutExercise) {
        exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)
        try? context.save()
    }

    func reorderExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
        for (i, exercise) in exercises.enumerated() { exercise.order = i }
    }

    // MARK: - Sets

    func addSet(to exercise: WorkoutExercise) {
        let existing = (exercise.sets ?? []).filter { !$0.isWarmup }
        let lastSet = existing.last
        let set = ExerciseSet(
            workoutExerciseId: exercise.id,
            setNumber: existing.count + 1,
            reps: lastSet?.reps ?? 8,
            weight: lastSet?.weight ?? 0
        )
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        context.insert(set)
        try? context.save()
        objectWillChange.send()
    }

    func addWarmupSet(to exercise: WorkoutExercise) {
        let warmups = (exercise.sets ?? []).filter { $0.isWarmup }
        let set = ExerciseSet(
            workoutExerciseId: exercise.id,
            setNumber: warmups.count + 1,
            reps: 10,
            weight: 0,
            isWarmup: true
        )
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        context.insert(set)
        try? context.save()
        objectWillChange.send()
    }

    func removeSet(_ set: ExerciseSet, from exercise: WorkoutExercise) {
        exercise.sets?.removeAll { $0.id == set.id }
        context.delete(set)
        try? context.save()
        objectWillChange.send()
    }

    func completeSet(_ set: ExerciseSet, exercise: WorkoutExercise) {
        set.isCompleted = true
        set.loggedAt = Date()
        checkForPRs(set: set, exercise: exercise)
        startRestTimer(seconds: 90)
        objectWillChange.send()
    }

    private func addDefaultSet(to exercise: WorkoutExercise) {
        let suggestion = suggestions[exercise.exerciseName]
        let set = ExerciseSet(
            workoutExerciseId: exercise.id,
            setNumber: 1,
            reps: suggestion?.suggestedReps ?? 8,
            weight: suggestion?.suggestedWeight ?? 0
        )
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(set)
        context.insert(set)
    }

    // MARK: - PR Detection

    private func checkForPRs(set: ExerciseSet, exercise: WorkoutExercise) {
        guard set.weight > 0 && set.reps > 0 else { return }
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
            let prs = prRepo.processPRs(
                results: results,
                exerciseName: exercise.exerciseName,
                setId: set.id,
                workoutId: workout.id,
                userId: userId,
                achievedAt: Date()
            )
            newPRs.append(contentsOf: prs)
        }
    }

    // MARK: - History + Suggestions

    private func loadHistory() {
        allWorkouts = (try? workoutRepo.fetchCompletedWorkouts(userId: userId)) ?? []
    }

    func loadSuggestion(for exercise: WorkoutExercise) {
        guard let settings else { return }
        let lastSession = ProgressOverloadEngine.lastSessionSummary(
            exerciseName: exercise.exerciseName,
            workouts: allWorkouts,
            excludingWorkoutId: workout.id
        )
        lastSessionSummaries[exercise.exerciseName] = lastSession
        let suggestion = ProgressOverloadEngine.suggest(
            exerciseName: exercise.exerciseName,
            lastSessionSets: lastSession?.sets ?? [],
            currentSessionSetCount: (exercise.sets ?? []).count,
            weightUnit: settings.preferredWeightUnit
        )
        suggestions[exercise.exerciseName] = suggestion
    }

    func loadSettings() {
        settings = try? UserRepository(context: context).fetchSettings(userId: userId)
    }

    // MARK: - Finish / Discard

    func finishWorkout() {
        workoutTimer?.invalidate()
        restTimerTask?.cancel()
        restTimerRemaining = nil
        workout.complete()
        try? context.save()
        isFinished = true
    }

    func discardWorkout() {
        workoutTimer?.invalidate()
        restTimerTask?.cancel()
        restTimerRemaining = nil
        workoutRepo.deleteWorkout(workout)
        try? workoutRepo.save()
        isFinished = true
    }
}
