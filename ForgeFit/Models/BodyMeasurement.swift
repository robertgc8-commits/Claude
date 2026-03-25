import SwiftData
import Foundation

enum MeasurementType: String, Codable, CaseIterable {
    case neck       = "Neck"
    case chest      = "Chest"
    case waist      = "Waist"
    case hips       = "Hips"
    case leftArm    = "Left Arm"
    case rightArm   = "Right Arm"
    case leftThigh  = "Left Thigh"
    case rightThigh = "Right Thigh"
    case bodyFatPct = "Body Fat %"

    var unit: String {
        self == .bodyFatPct ? "%" : "cm"
    }

    var icon: String {
        switch self {
        case .neck:                return "ruler"
        case .chest:               return "figure.arms.open"
        case .waist:               return "circle"
        case .hips:                return "oval"
        case .leftArm, .rightArm:  return "dumbbell.fill"
        case .leftThigh, .rightThigh: return "figure.walk"
        case .bodyFatPct:          return "percent"
        }
    }
}

/// A single body-measurement data point for one measurement type.
@Model
final class BodyMeasurementEntry {
    var id: String
    var userId: String
    var type: MeasurementType
    var valueCm: Double   // cm for length measurements; % for body fat
    var loggedAt: Date
    var notes: String?

    init(
        id: String = UUID().uuidString,
        userId: String,
        type: MeasurementType,
        valueCm: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.valueCm = valueCm
        self.loggedAt = Date()
        self.notes = notes
    }
}
