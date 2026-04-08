import Foundation
import SwiftData

struct AllTimeStats {
    var totalWorkouts: Int = 0
    var totalSets: Int = 0
    var totalVolume: Double = 0
    var totalMinutes: Int = 0
    var uniqueExercises: Int = 0
    var prCount: Int = 0

    var timeDisplay: String {
        if totalMinutes < 60 { return "\(totalMinutes)m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

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

    // Strength Curve (1RM over time, deduplicated by day)
    @Published var strengthCurve: [(date: Date, estimated1RM: Double)] = []

    // Relative strength: 1RM / bodyweight ratio over time
    @Published var relativeStrengthData: [(date: Date, ratio: Double)] = []

    // All-time aggregate stats
    @Published var allTimeStats = AllTimeStats()

    // Calendar heatmap: startOfDay → workout count
    @Published var calendarWorkouts: [Date: Int] = [:]

    // FEATURE 4: Body Measurements
    @Published var measurements: [MeasurementType: [BodyMeasurementEntry]] = [:]
    @Published var showingMeasurements = false

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
            buildAllTimeStats(from: workouts)
            buildCalendarWorkouts(from: workouts)
            loadBodyWeight()
            loadMeasurements()
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

        buildStrengthCurve(exerciseName: name, workouts: workouts)
        buildRelativeStrength()
    }

    // MARK: - Strength Curve

    /// Brzycki 1RM estimate, capped at reps ≤ 12 for reliability.
    static func brzycki1RM(weight: Double, reps: Int) -> Double? {
        guard reps >= 1, reps <= 12, weight > 0 else { return nil }
        return reps == 1 ? weight : weight / (1.0278 - 0.0278 * Double(reps))
    }

    private func buildStrengthCurve(exerciseName: String, workouts: [Workout]) {
        let cal = Calendar.current
        var dayBest: [Date: Double] = [:]

        for workout in workouts {
            guard let completedAt = workout.completedAt else { continue }
            let day = cal.startOfDay(for: completedAt)
            let relevantExercises = (workout.exercises ?? []).filter { $0.exerciseName == exerciseName }

            for exercise in relevantExercises {
                for set in exercise.completedSets {
                    guard let e1rm = Self.brzycki1RM(weight: set.weight, reps: set.reps) else { continue }
                    if e1rm > (dayBest[day] ?? 0) { dayBest[day] = e1rm }
                }
            }
        }

        strengthCurve = dayBest
            .map { (date: $0.key, estimated1RM: $0.value) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Relative Strength

    private func buildRelativeStrength() {
        guard !bodyWeightEntries.isEmpty, !strengthCurve.isEmpty else {
            relativeStrengthData = []
            return
        }
        let bwSorted = bodyWeightEntries.sorted { $0.loggedAt < $1.loggedAt }
        let thirtyDays: TimeInterval = 30 * 24 * 3600
        relativeStrengthData = strengthCurve.compactMap { point in
            guard let closest = bwSorted.min(by: {
                abs($0.loggedAt.timeIntervalSince(point.date)) < abs($1.loggedAt.timeIntervalSince(point.date))
            }), closest.weightKg > 0,
                  abs(closest.loggedAt.timeIntervalSince(point.date)) <= thirtyDays
            else { return nil }
            return (date: point.date, ratio: point.estimated1RM / closest.weightKg)
        }
    }

    // MARK: - All-Time Stats

    private func buildAllTimeStats(from workouts: [Workout]) {
        var stats = AllTimeStats()
        stats.totalWorkouts = workouts.count
        var names = Set<String>()
        for workout in workouts {
            stats.totalMinutes += (workout.durationSeconds ?? 0) / 60
            for exercise in workout.exercises ?? [] {
                names.insert(exercise.exerciseName)
                let completed = exercise.completedSets
                stats.totalSets += completed.count
                stats.totalVolume += completed.reduce(0) { $0 + $1.weight * Double($1.reps) }
            }
        }
        stats.uniqueExercises = names.count
        stats.prCount = personalRecords.count
        allTimeStats = stats
    }

    // MARK: - Calendar Heatmap

    private func buildCalendarWorkouts(from workouts: [Workout]) {
        let cal = Calendar.current
        var dict: [Date: Int] = [:]
        for workout in workouts {
            let day = cal.startOfDay(for: workout.completedAt ?? workout.startedAt)
            dict[day, default: 0] += 1
        }
        calendarWorkouts = dict
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
        buildRelativeStrength()
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

    // MARK: - Feature 4: Body Measurements

    func loadMeasurements() {
        guard let ctx = context else { return }
        let uid = userId
        let descriptor = FetchDescriptor<BodyMeasurementEntry>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        let all = (try? ctx.fetch(descriptor)) ?? []
        var grouped: [MeasurementType: [BodyMeasurementEntry]] = [:]
        for type in MeasurementType.allCases { grouped[type] = [] }
        for entry in all {
            grouped[entry.type, default: []].append(entry)
        }
        measurements = grouped
    }

    func logMeasurement(type: MeasurementType, value: Double) {
        guard let ctx = context, value > 0 else { return }
        let entry = BodyMeasurementEntry(userId: userId, type: type, valueCm: value)
        ctx.insert(entry)
        do {
            try ctx.save()
        } catch {
            print("Measurement save error: \(error)")
        }
        loadMeasurements()
    }

    func deleteMeasurement(_ entry: BodyMeasurementEntry) {
        guard let ctx = context else { return }
        ctx.delete(entry)
        try? ctx.save()
        loadMeasurements()
    }

    func latestMeasurement(type: MeasurementType) -> BodyMeasurementEntry? {
        measurements[type]?.first
    }

    /// Returns latest - earliest (negative = reduction, positive = increase)
    func measurementDelta(type: MeasurementType) -> Double? {
        guard let entries = measurements[type], entries.count >= 2 else { return nil }
        let latest = entries[0].valueCm
        let earliest = entries[entries.count - 1].valueCm
        return latest - earliest
    }
}
