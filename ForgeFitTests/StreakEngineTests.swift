import XCTest
@testable import ForgeFit

final class StreakEngineTests: XCTestCase {

    // MARK: - Week Start

    func testWeekStartIsMonday() {
        // 2024-03-20 is a Wednesday
        let wednesday = DateComponents(calendar: .current, year: 2024, month: 3, day: 20).date!
        let weekStart = StreakEngine.weekStart(for: wednesday)
        // Should be Monday 2024-03-18
        let expected = DateComponents(calendar: .current, year: 2024, month: 3, day: 18).date!
        XCTAssertEqual(weekStart, expected)
    }

    func testSameWeekDetection() {
        let monday = DateComponents(calendar: .current, year: 2024, month: 3, day: 18).date!
        let friday = DateComponents(calendar: .current, year: 2024, month: 3, day: 22).date!
        let nextMonday = DateComponents(calendar: .current, year: 2024, month: 3, day: 25).date!
        XCTAssertTrue(StreakEngine.isSameWeek(monday, friday))
        XCTAssertFalse(StreakEngine.isSameWeek(friday, nextMonday))
    }

    // MARK: - Streak Computation

    func testEmptyWorkoutsZeroStreak() {
        let status = StreakEngine.computeStreakStatus(
            workouts: [], weeklyRecords: [], target: 4, today: Date()
        )
        XCTAssertEqual(status.currentStreak, 0)
        XCTAssertEqual(status.currentWeekCompleted, 0)
    }

    func testCurrentWeekCountedWhenComplete() {
        let today = Date()
        let workouts = (0..<4).map { _ -> Workout in
            let w = Workout(userId: "test", title: "Test")
            w.completedAt = today
            w.isCompleted = true
            return w
        }
        let status = StreakEngine.computeStreakStatus(
            workouts: workouts, weeklyRecords: [], target: 4, today: today
        )
        XCTAssertEqual(status.currentWeekCompleted, 4)
        XCTAssertTrue(status.isCurrentWeekComplete)
        // Streak includes this week since target met
        XCTAssertEqual(status.currentStreak, 1)
    }

    func testStreakBreaksOnMissedWeek() {
        // Build: 2 good weeks, 1 miss, 1 good week
        var records: [WeeklyStreakRecord] = []
        let baseMonday = DateComponents(calendar: .current, year: 2024, month: 3, day: 4).date!

        for i in 0..<4 {
            let wStart = Calendar.current.date(byAdding: .weekOfYear, value: i, to: baseMonday)!
            let wEnd = StreakEngine.weekEnd(for: wStart)
            let record = WeeklyStreakRecord(userId: "test", weekStartDate: wStart, weekEndDate: wEnd, targetCount: 4)
            record.update(completedCount: i == 2 ? 2 : 4)  // Week index 2 is missed
            records.append(record)
        }

        let today = Calendar.current.date(byAdding: .weekOfYear, value: 5, to: baseMonday)!
        let status = StreakEngine.computeStreakStatus(
            workouts: [], weeklyRecords: records, target: 4, today: today
        )

        // Most recent consecutive streak should be 1 (only last week was good)
        XCTAssertEqual(status.currentStreak, 1)
    }

    func testMilestonesDetection() {
        XCTAssertTrue(StreakEngine.isStreakMilestone(4))
        XCTAssertTrue(StreakEngine.isStreakMilestone(8))
        XCTAssertFalse(StreakEngine.isStreakMilestone(3))
        XCTAssertFalse(StreakEngine.isStreakMilestone(5))
    }
}
