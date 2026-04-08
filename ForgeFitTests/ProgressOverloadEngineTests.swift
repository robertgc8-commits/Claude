import XCTest
@testable import ForgeFit

final class ProgressOverloadEngineTests: XCTestCase {

    func testWeightPRDetected() {
        let historicalSets = makeHistoricalSets(weight: 80, reps: 8, count: 3)
        let currentSet = makeSet(weight: 85, reps: 8)

        let prs = ProgressOverloadEngine.detectPRs(
            currentSet: currentSet,
            exerciseName: "Bench Press",
            historicalSets: historicalSets,
            existingPRs: []
        )
        XCTAssertTrue(prs.contains { $0.type == .heaviestWeight })
        XCTAssertEqual(prs.first { $0.type == .heaviestWeight }?.value, 85)
    }

    func testNoPRWhenBelowHistorical() {
        let historicalSets = makeHistoricalSets(weight: 100, reps: 8, count: 3)
        let currentSet = makeSet(weight: 95, reps: 8)

        let prs = ProgressOverloadEngine.detectPRs(
            currentSet: currentSet,
            exerciseName: "Bench Press",
            historicalSets: historicalSets,
            existingPRs: []
        )
        XCTAssertFalse(prs.contains { $0.type == .heaviestWeight })
    }

    func testRepsPRDetectedAtSameWeight() {
        let historicalSets = makeHistoricalSets(weight: 80, reps: 6, count: 3)
        let currentSet = makeSet(weight: 80, reps: 8)

        let prs = ProgressOverloadEngine.detectPRs(
            currentSet: currentSet,
            exerciseName: "Bench Press",
            historicalSets: historicalSets,
            existingPRs: []
        )
        XCTAssertTrue(prs.contains { $0.type == .mostRepsAtWeight })
    }

    func testSuggestionIncreaseWeightWhenRepsHigh() {
        let lastSets = [makeCompletedSet(weight: 80, reps: 10)]
        let suggestion = ProgressOverloadEngine.suggest(
            exerciseName: "Bench Press",
            lastSessionSets: lastSets,
            currentSessionSetCount: 0,
            weightUnit: .kg
        )
        XCTAssertNotNil(suggestion)
        if case .increaseWeight(let by) = suggestion?.type {
            XCTAssertEqual(by, 2.5)
        } else {
            XCTFail("Expected increaseWeight suggestion")
        }
        XCTAssertEqual(suggestion?.suggestedWeight, 82.5)
    }

    func testSuggestionIncreaseRepsWhenBelowTarget() {
        let lastSets = [makeCompletedSet(weight: 80, reps: 6)]
        let suggestion = ProgressOverloadEngine.suggest(
            exerciseName: "Bench Press",
            lastSessionSets: lastSets,
            currentSessionSetCount: 0,
            weightUnit: .kg
        )
        XCTAssertNotNil(suggestion)
        if case .increaseReps(let by) = suggestion?.type {
            XCTAssertEqual(by, 1)
        } else {
            XCTFail("Expected increaseReps suggestion")
        }
    }

    // MARK: - Helpers

    private func makeHistoricalSets(weight: Double, reps: Int, count: Int) -> [ExerciseSet] {
        (0..<count).map { i in
            let s = ExerciseSet(
                workoutExerciseId: "ex_\(i)",
                setNumber: i + 1, reps: reps, weight: weight
            )
            s.isCompleted = true
            return s
        }
    }

    private func makeSet(weight: Double, reps: Int) -> ExerciseSet {
        let s = ExerciseSet(workoutExerciseId: "current", setNumber: 1, reps: reps, weight: weight)
        s.isCompleted = true
        return s
    }

    private func makeCompletedSet(weight: Double, reps: Int) -> ExerciseSet {
        let s = ExerciseSet(workoutExerciseId: "ex", setNumber: 1, reps: reps, weight: weight)
        s.isCompleted = true
        return s
    }
}
