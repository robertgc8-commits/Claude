import Foundation
import SwiftData

@MainActor
final class WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchAllWorkouts(userId: String) throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchCompletedWorkouts(userId: String) throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.userId == userId && $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchWorkout(id: String) throws -> Workout? {
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchWorkoutsThisWeek(userId: String) throws -> [Workout] {
        let weekStart = StreakEngine.weekStart(for: Date())
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { w in
                w.userId == userId && w.isCompleted == true &&
                w.completedAt != nil && w.completedAt! >= weekStart
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Create / Save

    func createWorkout(userId: String, title: String) -> Workout {
        let workout = Workout(userId: userId, title: title)
        context.insert(workout)
        return workout
    }

    func duplicateWorkout(_ source: Workout, userId: String) -> Workout {
        let copy = Workout(
            userId: userId,
            title: source.title,
            startedAt: Date()
        )
        copy.sourceWorkoutId = source.id
        context.insert(copy)

        for sourceExercise in (source.exercises ?? []).sorted(by: { $0.order < $1.order }) {
            let exercise = WorkoutExercise(
                workoutId: copy.id,
                exerciseName: sourceExercise.exerciseName,
                exerciseTemplateId: sourceExercise.exerciseTemplateId,
                muscleGroup: sourceExercise.muscleGroup,
                order: sourceExercise.order
            )
            context.insert(exercise)

            // Pre-fill sets from last session (empty, ready to log)
            for (i, sourceSet) in (sourceExercise.sets ?? []).filter({ !$0.isWarmup }).enumerated() {
                let set = ExerciseSet(
                    workoutExerciseId: exercise.id,
                    setNumber: i + 1,
                    reps: sourceSet.reps,
                    weight: sourceSet.weight,
                    isWarmup: false
                )
                context.insert(set)
            }
        }
        return copy
    }

    // MARK: - Delete

    func deleteWorkout(_ workout: Workout) {
        context.delete(workout)
    }

    // MARK: - Save

    func save() throws {
        try context.save()
    }
}
