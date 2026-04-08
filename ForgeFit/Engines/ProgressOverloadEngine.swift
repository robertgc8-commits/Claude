import Foundation

/// Analyzes exercise history to detect PRs and generate progressive overload suggestions.
final class ProgressOverloadEngine {

    // MARK: - PR Detection

    struct PRResult {
        let type: PRType
        let value: Double
        let weight: Double
        let reps: Int
        let previousBest: Double?
        let improvement: Double?  // absolute difference
    }

    /// Detects new PRs for a given exercise set against historical sets.
    static func detectPRs(
        currentSet: ExerciseSet,
        exerciseName: String,
        historicalSets: [ExerciseSet],  // all past sets for this exercise, excluding current workout
        existingPRs: [PersonalRecord]
    ) -> [PRResult] {
        var results: [PRResult] = []
        let completedHistorical = historicalSets.filter { $0.isCompleted && $0.weight > 0 && $0.reps > 0 }

        // 1. Heaviest weight PR
        let prevMaxWeight = completedHistorical.map { $0.weight }.max()
        if currentSet.weight > 0 && currentSet.reps > 0 {
            if currentSet.weight > (prevMaxWeight ?? 0) {
                results.append(PRResult(
                    type: .heaviestWeight,
                    value: currentSet.weight,
                    weight: currentSet.weight,
                    reps: currentSet.reps,
                    previousBest: prevMaxWeight,
                    improvement: prevMaxWeight.map { currentSet.weight - $0 }
                ))
            }

            // 2. Most reps at this specific weight
            let setsAtSameWeight = completedHistorical.filter {
                abs($0.weight - currentSet.weight) < 0.1
            }
            let prevMaxRepsAtWeight = setsAtSameWeight.map { $0.reps }.max()
            if currentSet.reps > (prevMaxRepsAtWeight ?? 0) {
                results.append(PRResult(
                    type: .mostRepsAtWeight,
                    value: Double(currentSet.reps),
                    weight: currentSet.weight,
                    reps: currentSet.reps,
                    previousBest: prevMaxRepsAtWeight.map { Double($0) },
                    improvement: prevMaxRepsAtWeight.map { Double(currentSet.reps - $0) }
                ))
            }

            // 3. Best set volume (w * r)
            let setVolume = currentSet.volume
            let prevMaxSetVolume = completedHistorical.map { $0.volume }.max()
            if setVolume > (prevMaxSetVolume ?? 0) {
                results.append(PRResult(
                    type: .highestVolume,
                    value: setVolume,
                    weight: currentSet.weight,
                    reps: currentSet.reps,
                    previousBest: prevMaxSetVolume,
                    improvement: prevMaxSetVolume.map { setVolume - $0 }
                ))
            }
        }

        return results
    }

    // MARK: - Overload Suggestions

    struct OverloadSuggestion {
        enum SuggestionType {
            case increaseWeight(by: Double)
            case increaseReps(by: Int)
            case addSet
            case maintainLoad  // first time, just hit last performance
        }

        let type: SuggestionType
        let suggestedWeight: Double
        let suggestedReps: Int
        let rationale: String
    }

    /// Suggests targets for the next set based on last session performance.
    /// `increment`: weight step per overload cycle. Falls back to the unit default (2.5 kg / 5 lb) when 0.
    static func suggest(
        exerciseName: String,
        lastSessionSets: [ExerciseSet],
        currentSessionSetCount: Int,
        weightUnit: WeightUnit,
        increment: Double = 0
    ) -> OverloadSuggestion? {
        guard !lastSessionSets.isEmpty else { return nil }

        let completed = lastSessionSets.filter { $0.isCompleted && $0.reps > 0 }
        guard !completed.isEmpty else { return nil }

        // Use the working set with the most volume from last session
        let bestSet = completed.filter { !$0.isWarmup }.max(by: { $0.volume < $1.volume }) ?? completed[0]
        let targetReps = 8  // standard rep target for progressive overload
        let weightIncrement = increment > 0 ? increment : (weightUnit == .kg ? 2.5 : 5.0)

        if bestSet.reps >= targetReps {
            // Ready to increase weight
            return OverloadSuggestion(
                type: .increaseWeight(by: weightIncrement),
                suggestedWeight: bestSet.weight + weightIncrement,
                suggestedReps: max(5, bestSet.reps - 2),
                rationale: "You hit \(bestSet.reps) reps last time. Try \(String(format: "%.1f", bestSet.weight + weightIncrement))\(weightUnit.label)."
            )
        } else {
            // Same weight, aim for more reps
            return OverloadSuggestion(
                type: .increaseReps(by: 1),
                suggestedWeight: bestSet.weight,
                suggestedReps: bestSet.reps + 1,
                rationale: "Match \(bestSet.weight)\(weightUnit.label) and aim for \(bestSet.reps + 1) reps."
            )
        }
    }

    // MARK: - Volume Trend

    struct VolumeTrend {
        let exerciseName: String
        let weeklyVolumes: [(weekStart: Date, volume: Double)]  // last 8 weeks
        let fourWeekAverage: Double
        let trend: TrendDirection

        enum TrendDirection {
            case improving, declining, stable, insufficient  // not enough data
        }
    }

    static func computeVolumeTrend(
        exerciseName: String,
        historicalWorkouts: [Workout],
        calendar: Calendar = .current
    ) -> VolumeTrend {
        let relevant = historicalWorkouts
            .filter { $0.isCompleted }
            .filter { workout in
                (workout.exercises ?? []).contains { $0.exerciseName == exerciseName }
            }
            .sorted { ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt) }

        guard relevant.count >= 2 else {
            return VolumeTrend(exerciseName: exerciseName, weeklyVolumes: [], fourWeekAverage: 0, trend: .insufficient)
        }

        // Group by week
        var weeklyMap: [Date: Double] = [:]
        for workout in relevant {
            let date = workout.completedAt ?? workout.startedAt
            let weekStart = StreakEngine.weekStart(for: date, calendar: calendar)
            let volume = (workout.exercises ?? [])
                .filter { $0.exerciseName == exerciseName }
                .reduce(0.0) { $0 + $1.totalVolume }
            weeklyMap[weekStart, default: 0] += volume
        }

        let sorted = weeklyMap.sorted { $0.key < $1.key }
        let recent8 = Array(sorted.suffix(8))
        let weeklyVolumes = recent8.map { ($0.key, $0.value) }

        let last4 = recent8.suffix(4).map { $0.value }
        let prev4 = recent8.prefix(4).map { $0.value }

        let lastAvg = last4.isEmpty ? 0 : last4.reduce(0, +) / Double(last4.count)
        let prevAvg = prev4.isEmpty ? 0 : prev4.reduce(0, +) / Double(prev4.count)

        let trend: VolumeTrend.TrendDirection
        if recent8.count < 4 {
            trend = .insufficient
        } else if lastAvg > prevAvg * 1.05 {
            trend = .improving
        } else if lastAvg < prevAvg * 0.95 {
            trend = .declining
        } else {
            trend = .stable
        }

        return VolumeTrend(
            exerciseName: exerciseName,
            weeklyVolumes: weeklyVolumes,
            fourWeekAverage: lastAvg,
            trend: trend
        )
    }

    // MARK: - Last Session Summary

    struct LastSessionSummary {
        let workoutDate: Date
        let sets: [ExerciseSet]
        let totalVolume: Double
        let maxWeight: Double
        let bestSetDisplay: String  // e.g. "4 × 100 kg"
    }

    static func lastSessionSummary(
        exerciseName: String,
        workouts: [Workout],
        excludingWorkoutId: String? = nil
    ) -> LastSessionSummary? {
        let relevant = workouts
            .filter { $0.isCompleted && $0.id != excludingWorkoutId }
            .filter { ($0.exercises ?? []).contains { $0.exerciseName == exerciseName } }
            .sorted { ($0.completedAt ?? $0.startedAt) > ($1.completedAt ?? $1.startedAt) }

        guard let lastWorkout = relevant.first,
              let exercise = (lastWorkout.exercises ?? []).first(where: { $0.exerciseName == exerciseName })
        else { return nil }

        let completedSets = exercise.completedSets
        guard !completedSets.isEmpty else { return nil }

        let maxWeight = completedSets.map { $0.weight }.max() ?? 0
        let bestSet = completedSets.max(by: { $0.volume < $1.volume })
        let bestDisplay: String
        if let best = bestSet {
            bestDisplay = "\(best.setNumber) × \(String(format: "%.1f", best.weight))kg"
        } else {
            bestDisplay = ""
        }

        return LastSessionSummary(
            workoutDate: lastWorkout.completedAt ?? lastWorkout.startedAt,
            sets: completedSets,
            totalVolume: exercise.totalVolume,
            maxWeight: maxWeight,
            bestSetDisplay: bestDisplay
        )
    }
}
