import Foundation
import SwiftData

@MainActor
final class WorkoutTemplateRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchTemplates(userId: String) throws -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Create from completed Workout

    /// Snapshots a finished workout into a reusable template.
    ///
    /// For each exercise:
    ///   - `defaultSets`   = number of completed (non-warmup) sets, minimum 1
    ///   - `defaultReps`   = average reps across those sets (rounded)
    ///   - `defaultWeight` = average weight across those sets
    ///
    /// If no sets were completed the exercise falls back to 3 × 8 at bodyweight.
    func createTemplate(from workout: Workout, userId: String, name: String) -> WorkoutTemplate {
        let template = WorkoutTemplate(userId: userId, name: name)
        context.insert(template)

        let sortedExercises = (workout.exercises ?? []).sorted { $0.order < $1.order }
        for (index, workoutExercise) in sortedExercises.enumerated() {
            // completedSets already filters isCompleted == true; additionally exclude warmups
            let completedWorkingSets = workoutExercise.completedSets.filter { !$0.isWarmup }

            let defaultSets: Int
            let defaultReps: Int
            let defaultWeight: Double

            if completedWorkingSets.isEmpty {
                defaultSets   = 3
                defaultReps   = 8
                defaultWeight = 0
            } else {
                defaultSets = max(1, completedWorkingSets.count)
                let totalWeight = completedWorkingSets.reduce(0.0) { $0 + $1.weight }
                let totalReps   = completedWorkingSets.reduce(0)   { $0 + $1.reps }
                defaultWeight = totalWeight / Double(completedWorkingSets.count)
                defaultReps   = Int((Double(totalReps) / Double(completedWorkingSets.count)).rounded())
            }

            let templateExercise = WorkoutTemplateExercise(
                templateId: template.id,
                exerciseName: workoutExercise.exerciseName,
                exerciseTemplateId: workoutExercise.exerciseTemplateId,
                muscleGroup: workoutExercise.muscleGroup,
                order: index,
                defaultSets: defaultSets,
                defaultReps: defaultReps,
                defaultWeight: defaultWeight
            )
            context.insert(templateExercise)
            if template.exercises == nil { template.exercises = [] }
            template.exercises?.append(templateExercise)
        }

        return template
    }

    // MARK: - Create blank template

    /// Creates an empty named template with no exercises.
    func createBlankTemplate(userId: String, name: String) -> WorkoutTemplate {
        let template = WorkoutTemplate(userId: userId, name: name)
        template.exercises = []
        context.insert(template)
        return template
    }

    // MARK: - Delete

    func deleteTemplate(_ template: WorkoutTemplate) {
        context.delete(template)
    }

    // MARK: - Persist

    func save() throws {
        try context.save()
    }
}
