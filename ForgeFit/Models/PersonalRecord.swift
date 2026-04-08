import SwiftData
import Foundation

@Model
final class PersonalRecord {
    var id: String
    var userId: String
    var exerciseName: String
    var recordType: PRType
    var value: Double      // weight (kg), reps, or volume
    var weight: Double     // always stored
    var reps: Int          // always stored
    var setId: String      // ExerciseSet ID
    var workoutId: String
    var achievedAt: Date
    var isActive: Bool     // false if surpassed or workout deleted

    init(
        id: String = UUID().uuidString,
        userId: String,
        exerciseName: String,
        recordType: PRType,
        value: Double,
        weight: Double,
        reps: Int,
        setId: String,
        workoutId: String,
        achievedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.exerciseName = exerciseName
        self.recordType = recordType
        self.value = value
        self.weight = weight
        self.reps = reps
        self.setId = setId
        self.workoutId = workoutId
        self.achievedAt = achievedAt
        self.isActive = true
    }
}

enum PRType: String, Codable, CaseIterable {
    case heaviestWeight = "heaviest_weight"     // highest single weight lifted
    case mostRepsAtWeight = "most_reps_weight"  // most reps at a specific weight
    case highestVolume = "highest_volume"       // highest single set volume (w * r)
    case highestSessionVolume = "session_volume" // total session volume for exercise

    var label: String {
        switch self {
        case .heaviestWeight: return "Max Weight"
        case .mostRepsAtWeight: return "Max Reps"
        case .highestVolume: return "Best Set Volume"
        case .highestSessionVolume: return "Session Volume"
        }
    }

    var icon: String {
        switch self {
        case .heaviestWeight: return "scalemass.fill"
        case .mostRepsAtWeight: return "repeat"
        case .highestVolume, .highestSessionVolume: return "flame.fill"
        }
    }
}
