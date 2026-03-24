import Foundation
import SwiftData

/// Smart weekly streak engine.
///
/// A streak = consecutive calendar weeks where the user met their workout target.
/// Week boundaries are Monday-Sunday.
/// The current in-progress week is NEVER counted as broken — only completed past weeks matter.
/// This prevents punishing users mid-week for rest days.
final class StreakEngine {

    // MARK: - Week Utilities

    static func weekStart(for date: Date, calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2  // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    static func weekEnd(for weekStart: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    static func isSameWeek(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Bool {
        weekStart(for: a, calendar: calendar) == weekStart(for: b, calendar: calendar)
    }

    // MARK: - Core Computation

    /// Recomputes streak status from workout dates and weekly records.
    /// Call this after any workout is added, edited, or deleted.
    static func computeStreakStatus(
        workouts: [Workout],
        weeklyRecords: [WeeklyStreakRecord],
        target: Int,
        today: Date = Date()
    ) -> StreakStatus {
        let completedWorkouts = workouts.filter { $0.isCompleted }
        let currentWeekStart = weekStart(for: today)
        let currentWeekEnd = weekEnd(for: currentWeekStart)

        // Count workouts in the current week
        let thisWeekCount = completedWorkouts.filter {
            guard let completed = $0.completedAt else { return false }
            return completed >= currentWeekStart && completed <= currentWeekEnd
        }.count

        // Sort past weeks (completed, not current)
        let pastRecords = weeklyRecords
            .filter { $0.weekStartDate < currentWeekStart }
            .sorted { $0.weekStartDate > $1.weekStartDate }  // newest first

        // Calculate current streak: consecutive past weeks that met target
        var currentStreak = 0
        var prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart)!

        for record in pastRecords {
            // Ensure records are contiguous (no gaps)
            guard isSameWeek(record.weekStartDate, prevWeekStart) else { break }
            if record.isTargetMet {
                currentStreak += 1
                prevWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: record.weekStartDate)!
            } else {
                break
            }
        }

        // If this week is already complete, count it too
        if thisWeekCount >= target {
            currentStreak += 1
        }

        // Longest streak across all history
        let longestStreak = computeLongestStreak(records: weeklyRecords)

        return StreakStatus(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            currentWeekCompleted: thisWeekCount,
            currentWeekTarget: target,
            isOnTrack: thisWeekCount < target,  // still in progress
            weeklyHistory: pastRecords
        )
    }

    /// Updates or creates the WeeklyStreakRecord for a given week.
    static func updateWeekRecord(
        for date: Date,
        workouts: [Workout],
        records: inout [WeeklyStreakRecord],
        userId: String,
        target: Int,
        context: ModelContext
    ) {
        let wStart = weekStart(for: date)
        let wEnd = weekEnd(for: wStart)

        let weekWorkouts = workouts.filter { w in
            guard let completed = w.completedAt, w.isCompleted else { return false }
            return completed >= wStart && completed <= wEnd
        }.count

        if let existing = records.first(where: { isSameWeek($0.weekStartDate, wStart) }) {
            existing.update(completedCount: weekWorkouts)
        } else {
            let record = WeeklyStreakRecord(
                userId: userId,
                weekStartDate: wStart,
                weekEndDate: wEnd,
                targetCount: target
            )
            record.update(completedCount: weekWorkouts)
            context.insert(record)
            records.append(record)
        }
    }

    // MARK: - Helpers

    private static var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    private static func computeLongestStreak(records: [WeeklyStreakRecord]) -> Int {
        let sorted = records.sorted { $0.weekStartDate < $1.weekStartDate }
        var longest = 0
        var current = 0
        var prevWeekStart: Date?

        for record in sorted {
            if let prev = prevWeekStart,
               let expectedNext = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: prev),
               isSameWeek(record.weekStartDate, expectedNext) {
                if record.isTargetMet {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0
                }
            } else {
                current = record.isTargetMet ? 1 : 0
                longest = max(longest, current)
            }
            prevWeekStart = record.weekStartDate
        }
        return longest
    }

    // MARK: - Notification Triggers

    /// Returns true if the user just hit a streak milestone worth notifying
    static func isStreakMilestone(_ streak: Int) -> Bool {
        let milestones = [2, 4, 8, 12, 16, 20, 26, 52]
        return milestones.contains(streak)
    }
}
