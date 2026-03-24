import SwiftData
import Foundation

// One record per calendar week
@Model
final class WeeklyStreakRecord {
    var id: String
    var userId: String
    var weekStartDate: Date    // Monday of the week (normalized)
    var weekEndDate: Date      // Sunday of the week
    var targetCount: Int       // user's target at time of this week
    var completedCount: Int    // workouts completed this week
    var isTargetMet: Bool
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        weekStartDate: Date,
        weekEndDate: Date,
        targetCount: Int
    ) {
        self.id = id
        self.userId = userId
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.targetCount = targetCount
        self.completedCount = 0
        self.isTargetMet = false
        self.updatedAt = Date()
    }

    func update(completedCount: Int) {
        self.completedCount = completedCount
        self.isTargetMet = completedCount >= targetCount
        self.updatedAt = Date()
    }
}

// Computed streak state (not persisted, derived from WeeklyStreakRecords)
struct StreakStatus {
    let currentStreak: Int        // consecutive weeks target was met
    let longestStreak: Int
    let currentWeekCompleted: Int // workouts done this week
    let currentWeekTarget: Int
    let isOnTrack: Bool           // current week still achievable
    let weeklyHistory: [WeeklyStreakRecord]

    var progressText: String {
        "\(currentWeekCompleted)/\(currentWeekTarget) this week"
    }

    var isCurrentWeekComplete: Bool {
        currentWeekCompleted >= currentWeekTarget
    }

    var remainingThisWeek: Int {
        max(0, currentWeekTarget - currentWeekCompleted)
    }
}
