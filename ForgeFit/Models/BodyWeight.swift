import SwiftData
import Foundation

@Model
final class BodyWeightEntry {
    var id: String
    var userId: String
    var weightKg: Double
    var loggedAt: Date
    var notes: String?

    init(userId: String, weightKg: Double, notes: String? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.weightKg = weightKg
        self.loggedAt = Date()
        self.notes = notes
    }
}
