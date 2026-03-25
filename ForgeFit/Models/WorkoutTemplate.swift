import SwiftData
import Foundation

/// A saved workout layout that can be started as a new workout session.
@Model
final class WorkoutTemplate {
    var id: String
    var userId: String
    var name: String
    var notes: String?
    var createdAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    @Relationship(deleteRule: .cascade) var exercises: [WorkoutTemplateExercise]?

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.lastUsedAt = nil
        self.useCount = 0
    }

    var exerciseCount: Int { exercises?.count ?? 0 }

    var muscleGroups: [MuscleGroup] {
        Array(Set((exercises ?? []).map { $0.muscleGroup }))
            .sorted { $0.rawValue < $1.rawValue }
    }
}

/// One exercise slot inside a WorkoutTemplate.
@Model
final class WorkoutTemplateExercise {
    var id: String
    var templateId: String
    var exerciseName: String
    var exerciseTemplateId: String?
    var muscleGroup: MuscleGroup
    var order: Int
    var defaultSets: Int     // number of working sets to pre-fill
    var defaultReps: Int     // target reps per set
    var defaultWeight: Double // starting weight in kg

    init(
        id: String = UUID().uuidString,
        templateId: String,
        exerciseName: String,
        exerciseTemplateId: String? = nil,
        muscleGroup: MuscleGroup = .other,
        order: Int = 0,
        defaultSets: Int = 3,
        defaultReps: Int = 8,
        defaultWeight: Double = 0
    ) {
        self.id = id
        self.templateId = templateId
        self.exerciseName = exerciseName
        self.exerciseTemplateId = exerciseTemplateId
        self.muscleGroup = muscleGroup
        self.order = order
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
    }
}
