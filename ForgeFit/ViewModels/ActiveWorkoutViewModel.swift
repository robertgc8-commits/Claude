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
    private var userDisplayName: String = ""
    private var userUsername: String = ""
    private let socialService: SocialServiceProtocol

    init(context: ModelContext, userId: String, workout: Workout,
         socialService: SocialServiceProtocol = SocialServiceProvider.shared) {
        self.context = context
        self.userId = userId
        self.workout = workout
        self.workoutRepo = WorkoutRepository(context: context)
        self.prRepo = PRRepository(context: context)
        self.socialService = socialService
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
        startRestTimer(seconds: settings?.restTimerDuration ?? 90)
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

            if settings?.notifyFriendsOnPR == true {
                postPREvent(exercise: exercise, set: set)
            }
        }
    }

    private func postPREvent(exercise: WorkoutExercise, set: ExerciseSet) {
        let friendIds = (try? FriendRepository(context: context)
            .fetchAcceptedFriends(userId: userId)
            .map { $0.friendUserId }) ?? []
        guard !friendIds.isEmpty else { return }

        let name = userDisplayName.isEmpty ? "Someone" : userDisplayName
        let weightStr = String(format: "%.1f", set.weight)
        let prBody = "\(name) hit a new \(exercise.exerciseName) PR: \(weightStr)kg × \(set.reps)"
        let event = SocialNotificationEvent(
            actorUserId: userId,
            actorUsername: userUsername,
            actorDisplayName: name,
            type: .prAchieved,
            title: "New PR",
            body: prBody,
            targetUserIds: friendIds,
            metadata: ["exercise": exercise.exerciseName, "weight": weightStr, "reps": "\(set.reps)"]
        )
        let feedRepo = FeedRepository(context: context)
        let _ = feedRepo.createFeedItem(
            actorUserId: userId, actorUsername: userUsername, actorDisplayName: name,
            type: .prAchieved, title: "New PR",
            body: "You hit a new \(exercise.exerciseName) PR: \(weightStr)kg × \(set.reps)", isMine: true
        )
        try? context.save()
        Task { try? await socialService.postSocialEvent(event) }
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
            weightUnit: settings.preferredWeightUnit,
            increment: settings.defaultWeightIncrement
        )
        suggestions[exercise.exerciseName] = suggestion
    }

    func loadSettings() {
        let userRepo = UserRepository(context: context)
        settings = try? userRepo.fetchSettings(userId: userId)
        if let user = try? userRepo.fetchCurrentUser(userId: userId) {
            userDisplayName = user.displayName
            userUsername = user.username
        }
    }

    // MARK: - Templates

    /// Pre-fills the current workout from a saved template.
    /// Each template exercise is added in order with its default sets pre-loaded.
    /// The template's usage stats are updated afterwards.
    func loadTemplate(_ template: WorkoutTemplate) {
        let sorted = (template.exercises ?? []).sorted { $0.order < $1.order }
        for templateExercise in sorted {
            let initialSets: [(reps: Int, weight: Double)] = Array(
                repeating: (reps: templateExercise.defaultReps,
                            weight: templateExercise.defaultWeight),
                count: max(1, templateExercise.defaultSets)
            )
            addExercise(
                name: templateExercise.exerciseName,
                muscleGroup: templateExercise.muscleGroup,
                templateId: templateExercise.exerciseTemplateId,
                initialSets: initialSets
            )
        }
        template.lastUsedAt = Date()
        template.useCount += 1
        try? context.save()
    }

    /// Copies the most recently completed workout into the current session,
    /// pre-filling each exercise with the actual weights and reps from that last session.
    func copyLastWorkout() {
        guard let lastWorkout = (try? workoutRepo.fetchCompletedWorkouts(userId: userId))?.first else { return }
        let sortedExercises = (lastWorkout.exercises ?? []).sorted { $0.order < $1.order }
        for workoutExercise in sortedExercises {
            let workingSets = (workoutExercise.sets ?? [])
                .filter { !$0.isWarmup }
                .sorted { $0.setNumber < $1.setNumber }
            let initialSets: [(reps: Int, weight: Double)] = workingSets.isEmpty
                ? [(reps: 8, weight: 0)]
                : workingSets.map { (reps: $0.reps, weight: $0.weight) }
            addExercise(
                name: workoutExercise.exerciseName,
                muscleGroup: workoutExercise.muscleGroup,
                templateId: workoutExercise.exerciseTemplateId,
                initialSets: initialSets
            )
        }
    }

    // MARK: - Drop Set

    /// Inserts a new drop-set immediately after `completedSet`, pre-filled at 80 % of its weight
    /// (rounded down to the nearest 2.5 kg). All subsequent set numbers are shifted up by one.
    func addDropSet(after completedSet: ExerciseSet, to exercise: WorkoutExercise) {
        let allSets = (exercise.sets ?? []).filter { !$0.isWarmup }.sorted { $0.setNumber < $1.setNumber }
        for s in allSets where s.setNumber > completedSet.setNumber {
            s.setNumber += 1
        }
        let reducedWeight = (completedSet.weight * 0.8 / 2.5).rounded(.down) * 2.5
        let newSet = ExerciseSet(
            workoutExerciseId: exercise.id,
            setNumber: completedSet.setNumber + 1,
            reps: completedSet.reps,
            weight: max(0, reducedWeight)
        )
        newSet.isDropSet = true
        if exercise.sets == nil { exercise.sets = [] }
        exercise.sets?.append(newSet)
        context.insert(newSet)
        try? context.save()
        objectWillChange.send()
    }

    // MARK: - Swap Exercise

    func swapExercise(_ exercise: WorkoutExercise, newName: String, newMuscleGroup: MuscleGroup, newTemplateId: String?) {
        exercise.exerciseName = newName
        exercise.muscleGroup = newMuscleGroup
        exercise.exerciseTemplateId = newTemplateId
        try? context.save()
        objectWillChange.send()
        loadSuggestion(for: exercise)
    }

    // MARK: - Supersets

    /// Links two exercises as a superset. If either is already in a group the other joins it;
    /// otherwise a new shared group ID is assigned.
    func linkSuperset(_ a: WorkoutExercise, with b: WorkoutExercise) {
        let groupId = a.supersetGroupId ?? b.supersetGroupId ?? UUID().uuidString
        a.supersetGroupId = groupId
        b.supersetGroupId = groupId
        try? context.save()
        objectWillChange.send()
    }

    /// Removes `exercise` from its superset group. If only one other exercise remains in the
    /// group, that exercise is also unlinked (a superset needs at least two exercises).
    func unlinkSuperset(_ exercise: WorkoutExercise) {
        guard let groupId = exercise.supersetGroupId else { return }
        exercise.supersetGroupId = nil
        let remaining = exercises.filter { $0.supersetGroupId == groupId }
        if remaining.count == 1 { remaining.first?.supersetGroupId = nil }
        try? context.save()
        objectWillChange.send()
    }

    // MARK: - Save as Template

    /// Snapshots the current workout into a new reusable template.
    func saveAsTemplate(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let templateRepo = WorkoutTemplateRepository(context: context)
        let _ = templateRepo.createTemplate(from: workout, userId: userId, name: name)
        try? templateRepo.save()
    }

    // MARK: - Finish / Discard

    func finishWorkout() {
        workoutTimer?.invalidate()
        restTimerTask?.cancel()
        restTimerRemaining = nil
        workout.complete()
        try? context.save()

        // Reset inactivity countdown from this workout's completion time
        if let s = settings, s.receiveInactivityReminders {
            NotificationService.shared.rescheduleInactivityReminder(
                from: workout.completedAt ?? Date(),
                thresholdDays: s.inactivityThresholdDays
            )
        }

        // Post social event to friends' feeds if enabled
        if settings?.notifyFriendsOnWorkout == true {
            postWorkoutEvent()
        }

        isFinished = true
    }

    private func postWorkoutEvent() {
        let friendIds = (try? FriendRepository(context: context)
            .fetchAcceptedFriends(userId: userId)
            .map { $0.friendUserId }) ?? []
        guard !friendIds.isEmpty else { return }

        let name = userDisplayName.isEmpty ? "Someone" : userDisplayName
        let event = SocialNotificationEvent(
            actorUserId: userId,
            actorUsername: userUsername,
            actorDisplayName: name,
            type: .workoutCompleted,
            title: "Workout Completed",
            body: "\(name) completed \(workout.title)",
            targetUserIds: friendIds,
            metadata: ["workoutId": workout.id, "title": workout.title]
        )
        // Local feed item (my own activity)
        let feedRepo = FeedRepository(context: context)
        let _ = feedRepo.createFeedItem(
            actorUserId: userId, actorUsername: userUsername, actorDisplayName: name,
            type: .workoutCompleted, title: "Workout Completed",
            body: "You completed \(workout.title)", isMine: true
        )
        try? context.save()
        // Backend fanout
        Task { try? await socialService.postSocialEvent(event) }
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
