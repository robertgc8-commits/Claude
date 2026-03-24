import SwiftData
import Foundation

@Model
final class Workout {
    var id: String
    var userId: String
    var title: String
    var notes: String?
    var startedAt: Date
    var completedAt: Date?
    var durationSeconds: Int?
    var isCompleted: Bool
    var sourceWorkoutId: String?  // ID of workout this was duplicated from

    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]?

    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        notes: String? = nil,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.notes = notes
        self.startedAt = startedAt
        self.completedAt = nil
        self.durationSeconds = nil
        self.isCompleted = false
    }

    var totalVolume: Double {
        exercises?.flatMap { $0.sets ?? [] }.reduce(0) { $0 + ($1.weight * Double($1.reps)) } ?? 0
    }

    var totalSets: Int {
        exercises?.flatMap { $0.sets ?? [] }.count ?? 0
    }

    var exerciseCount: Int {
        exercises?.count ?? 0
    }

    func complete() {
        completedAt = Date()
        isCompleted = true
        durationSeconds = Int(completedAt!.timeIntervalSince(startedAt))
    }
}

@Model
final class WorkoutExercise {
    var id: String
    var workoutId: String
    var exerciseName: String
    var exerciseTemplateId: String?
    var muscleGroup: MuscleGroup
    var order: Int
    var notes: String?

    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]?

    init(
        id: String = UUID().uuidString,
        workoutId: String,
        exerciseName: String,
        exerciseTemplateId: String? = nil,
        muscleGroup: MuscleGroup = .other,
        order: Int = 0
    ) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseName = exerciseName
        self.exerciseTemplateId = exerciseTemplateId
        self.muscleGroup = muscleGroup
        self.order = order
    }

    var completedSets: [ExerciseSet] {
        (sets ?? []).filter { $0.isCompleted }.sorted { $0.setNumber < $1.setNumber }
    }

    var totalVolume: Double {
        completedSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

@Model
final class ExerciseSet {
    var id: String
    var workoutExerciseId: String
    var setNumber: Int
    var reps: Int
    var weight: Double
    var rpe: Int?  // Rate of Perceived Exertion 1-10
    var notes: String?
    var isCompleted: Bool
    var isWarmup: Bool
    var loggedAt: Date

    init(
        id: String = UUID().uuidString,
        workoutExerciseId: String,
        setNumber: Int,
        reps: Int = 0,
        weight: Double = 0,
        isWarmup: Bool = false
    ) {
        self.id = id
        self.workoutExerciseId = workoutExerciseId
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.rpe = nil
        self.notes = nil
        self.isCompleted = false
        self.isWarmup = isWarmup
        self.loggedAt = Date()
    }

    var volume: Double { weight * Double(reps) }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case glutes = "Glutes"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    case other = "Other"

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "dumbbell.fill"
        case .legs, .glutes: return "figure.walk"
        case .core: return "circle.grid.cross.fill"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        case .other: return "dumbbell"
        }
    }
}
