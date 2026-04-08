import Foundation
import SwiftData

@MainActor
final class PRRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAllPRs(userId: String) throws -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.userId == userId && $0.isActive == true },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchPRs(userId: String, exerciseName: String) throws -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.userId == userId && $0.exerciseName == exerciseName && $0.isActive == true }
        )
        return try context.fetch(descriptor)
    }

    func fetchRecentPRs(userId: String, limit: Int = 5) throws -> [PersonalRecord] {
        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.userId == userId && $0.isActive == true },
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    /// Processes a set's PRs, inserting new records and deactivating superseded ones.
    func processPRs(
        results: [ProgressOverloadEngine.PRResult],
        exerciseName: String,
        setId: String,
        workoutId: String,
        userId: String,
        achievedAt: Date
    ) -> [PersonalRecord] {
        var newPRs: [PersonalRecord] = []

        for result in results {
            // Deactivate any existing PR of same type for this exercise
            if let existing = try? fetchPRs(userId: userId, exerciseName: exerciseName),
               let old = existing.first(where: { $0.recordType == result.type && $0.isActive }) {
                old.isActive = false
            }

            let pr = PersonalRecord(
                userId: userId,
                exerciseName: exerciseName,
                recordType: result.type,
                value: result.value,
                weight: result.weight,
                reps: result.reps,
                setId: setId,
                workoutId: workoutId,
                achievedAt: achievedAt
            )
            context.insert(pr)
            newPRs.append(pr)
        }
        return newPRs
    }

    /// Invalidates PRs tied to a deleted or edited workout.
    func invalidatePRs(forWorkoutId workoutId: String) throws {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.workoutId == workoutId && $0.isActive == true }
        )
        let prs = try context.fetch(descriptor)
        prs.forEach { $0.isActive = false }
    }

    func save() throws { try context.save() }
}
