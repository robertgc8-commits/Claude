import SwiftData
import Foundation

@Model
final class ExerciseTemplate {
    var id: String
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: Equipment
    var instructions: String?
    var isCustom: Bool
    var usageCount: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        instructions: String? = nil,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
        self.usageCount = 0
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case bands = "Bands"
    case other = "Other"
}

// MARK: - Preset Exercise Library
extension ExerciseTemplate {
    static let presets: [ExerciseTemplate] = [
        // Chest
        ExerciseTemplate(name: "Bench Press", muscleGroup: .chest, equipment: .barbell),
        ExerciseTemplate(name: "Incline Bench Press", muscleGroup: .chest, equipment: .barbell),
        ExerciseTemplate(name: "Dumbbell Fly", muscleGroup: .chest, equipment: .dumbbell),
        ExerciseTemplate(name: "Push-Up", muscleGroup: .chest, equipment: .bodyweight),
        ExerciseTemplate(name: "Cable Crossover", muscleGroup: .chest, equipment: .cable),
        ExerciseTemplate(name: "Chest Dip", muscleGroup: .chest, equipment: .bodyweight),
        // Back
        ExerciseTemplate(name: "Deadlift", muscleGroup: .back, equipment: .barbell),
        ExerciseTemplate(name: "Pull-Up", muscleGroup: .back, equipment: .bodyweight),
        ExerciseTemplate(name: "Barbell Row", muscleGroup: .back, equipment: .barbell),
        ExerciseTemplate(name: "Lat Pulldown", muscleGroup: .back, equipment: .cable),
        ExerciseTemplate(name: "Seated Cable Row", muscleGroup: .back, equipment: .cable),
        ExerciseTemplate(name: "Dumbbell Row", muscleGroup: .back, equipment: .dumbbell),
        // Shoulders
        ExerciseTemplate(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell),
        ExerciseTemplate(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, equipment: .dumbbell),
        ExerciseTemplate(name: "Lateral Raise", muscleGroup: .shoulders, equipment: .dumbbell),
        ExerciseTemplate(name: "Face Pull", muscleGroup: .shoulders, equipment: .cable),
        // Legs
        ExerciseTemplate(name: "Squat", muscleGroup: .legs, equipment: .barbell),
        ExerciseTemplate(name: "Romanian Deadlift", muscleGroup: .legs, equipment: .barbell),
        ExerciseTemplate(name: "Leg Press", muscleGroup: .legs, equipment: .machine),
        ExerciseTemplate(name: "Leg Curl", muscleGroup: .legs, equipment: .machine),
        ExerciseTemplate(name: "Leg Extension", muscleGroup: .legs, equipment: .machine),
        ExerciseTemplate(name: "Bulgarian Split Squat", muscleGroup: .legs, equipment: .dumbbell),
        ExerciseTemplate(name: "Calf Raise", muscleGroup: .legs, equipment: .machine),
        ExerciseTemplate(name: "Hack Squat", muscleGroup: .legs, equipment: .machine),
        // Biceps
        ExerciseTemplate(name: "Barbell Curl", muscleGroup: .biceps, equipment: .barbell),
        ExerciseTemplate(name: "Dumbbell Curl", muscleGroup: .biceps, equipment: .dumbbell),
        ExerciseTemplate(name: "Hammer Curl", muscleGroup: .biceps, equipment: .dumbbell),
        ExerciseTemplate(name: "Preacher Curl", muscleGroup: .biceps, equipment: .machine),
        // Triceps
        ExerciseTemplate(name: "Tricep Pushdown", muscleGroup: .triceps, equipment: .cable),
        ExerciseTemplate(name: "Skull Crusher", muscleGroup: .triceps, equipment: .barbell),
        ExerciseTemplate(name: "Overhead Tricep Extension", muscleGroup: .triceps, equipment: .dumbbell),
        ExerciseTemplate(name: "Tricep Dip", muscleGroup: .triceps, equipment: .bodyweight),
        // Core
        ExerciseTemplate(name: "Plank", muscleGroup: .core, equipment: .bodyweight),
        ExerciseTemplate(name: "Ab Wheel Rollout", muscleGroup: .core, equipment: .other),
        ExerciseTemplate(name: "Cable Crunch", muscleGroup: .core, equipment: .cable),
        ExerciseTemplate(name: "Hanging Leg Raise", muscleGroup: .core, equipment: .bodyweight),
        // Glutes
        ExerciseTemplate(name: "Hip Thrust", muscleGroup: .glutes, equipment: .barbell),
        ExerciseTemplate(name: "Glute Bridge", muscleGroup: .glutes, equipment: .bodyweight),
        // Cardio
        ExerciseTemplate(name: "Running", muscleGroup: .cardio, equipment: .other),
        ExerciseTemplate(name: "Cycling", muscleGroup: .cardio, equipment: .machine),
        ExerciseTemplate(name: "Rowing", muscleGroup: .cardio, equipment: .machine),
    ]
}
