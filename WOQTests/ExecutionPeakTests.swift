import Foundation
import SwiftData
import Testing

@testable import WOQ

/// The peak rule and the in-memory grouping of sets into executions
/// (PLAN.md 3.16 and "Multi-set executions", 2026-09-12).
///
/// Peak = best Epley 1RM `kg × (1 + reps / 30)`, unilateral reps = (L + R) / 2; any weighted
/// set beats any bodyweight set, bodyweight sets rank on reps; ties go to the heavier set,
/// then to more reps, then to the EARLIER set.
@Suite("Execution grouping and the Epley peak")
struct ExecutionPeakTests {

    // MARK: - Score

    @Test("80 kg × 10 beats 82.5 kg × 6 on Epley")
    func volumeBeatsSlightlyMoreWeight() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        let heavier = Fixture.entry(in: context, of: exercise, weightHalfKilos: 165, reps: 6, setIndex: 0)
        let better = Fixture.entry(in: context, of: exercise, weightHalfKilos: 160, reps: 10, setIndex: 1)

        // 80 × (1 + 10/30) = 106.67 against 82.5 × (1 + 6/30) = 99.0.
        #expect(Execution.peak(of: [heavier, better], isUnilateral: false) === better)
    }

    @Test("any weighted set beats a bodyweight set")
    func weightedBeatsBodyweight() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Pull-up", in: context)
        let bodyweight = Fixture.entry(in: context, of: exercise, weightHalfKilos: nil, reps: 50, setIndex: 0)
        let weighted = Fixture.entry(in: context, of: exercise, weightHalfKilos: 1, reps: 1, setIndex: 1)

        #expect(Execution.peak(of: [bodyweight, weighted], isUnilateral: false) === weighted)
    }

    @Test("bodyweight sets rank on reps")
    func bodyweightRanksOnReps() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Push-up", in: context)
        let fewer = Fixture.entry(in: context, of: exercise, weightHalfKilos: nil, reps: 10, setIndex: 0)
        let more = Fixture.entry(in: context, of: exercise, weightHalfKilos: nil, reps: 20, setIndex: 1)

        #expect(Execution.peak(of: [fewer, more], isUnilateral: false) === more)
        #expect(Execution.score(weightHalfKilos: nil, reps: 20, repsRight: nil)
            > Execution.score(weightHalfKilos: nil, reps: 10, repsRight: nil))
    }

    @Test("an equal one-rep max is won by the heavier set")
    func tieGoesToTheHeavier() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Squat", in: context)
        // 50 kg × 30 and 60 kg × 20 both estimate 100 kg; the integer numerator makes them
        // bit-identical Doubles, so this really is a tie and not floating-point noise.
        let lighter = Fixture.entry(in: context, of: exercise, weightHalfKilos: 100, reps: 30, setIndex: 0)
        let heavier = Fixture.entry(in: context, of: exercise, weightHalfKilos: 120, reps: 20, setIndex: 1)

        #expect(Execution.score(weightHalfKilos: 100, reps: 30, repsRight: nil).oneRepMax
            == Execution.score(weightHalfKilos: 120, reps: 20, repsRight: nil).oneRepMax)
        #expect(Execution.peak(of: [lighter, heavier], isUnilateral: false) === heavier)
    }

    @Test("an exact tie is won by the earlier set")
    func exactTieGoesToTheEarlierSet() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Squat", in: context)
        let first = Fixture.entry(in: context, of: exercise, weightHalfKilos: 160, reps: 10, setIndex: 0)
        let second = Fixture.entry(in: context, of: exercise, weightHalfKilos: 160, reps: 10, setIndex: 1)

        // Order of the argument must not matter: display order (setIndex) decides.
        #expect(Execution.peak(of: [first, second], isUnilateral: false) === first)
        #expect(Execution.peak(of: [second, first], isUnilateral: false) === first)
    }

    @Test("unilateral reps count as the average of both sides")
    func unilateralRepsAverage() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Single-arm row", in: context, isUnilateral: true)
        // L 12 / R 8 averages 10, so it scores exactly like a bilateral 10.
        let unilateral = Fixture.entry(in: context, of: exercise, weightHalfKilos: 80, reps: 12, repsRight: 8, setIndex: 0)
        let bilateral = Fixture.entry(in: context, of: exercise, weightHalfKilos: 80, reps: 10, setIndex: 1)

        #expect(Execution.score(weightHalfKilos: 80, reps: 12, repsRight: 8).oneRepMax
            == Execution.score(weightHalfKilos: 80, reps: 10, repsRight: nil).oneRepMax)
        // A tie, so the earlier set wins.
        #expect(Execution.peak(of: [unilateral, bilateral], isUnilateral: true) === unilateral)

        // And a genuinely better unilateral set does win.
        let stronger = Fixture.entry(in: context, of: exercise, weightHalfKilos: 80, reps: 14, repsRight: 14, setIndex: 2)
        #expect(Execution.peak(of: [unilateral, bilateral, stronger], isUnilateral: true) === stronger)
    }

    @Test("an empty list has no peak")
    func emptyHasNoPeak() {
        #expect(Execution.peak(of: [], isUnilateral: false) == nil)
    }

    // MARK: - Grouping

    @Test("sets sharing an execution id form one execution, ordered by set index")
    func groupsBySharedID() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        let executionID = UUID()
        // Inserted out of order on purpose: display order comes from setIndex, not insertion.
        let third = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1, second: 300),
            weightHalfKilos: 80, reps: 8, executionID: executionID, setIndex: 2
        )
        let first = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1),
            weightHalfKilos: 80, reps: 10, executionID: executionID, setIndex: 0
        )
        let second = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1, second: 150),
            weightHalfKilos: 80, reps: 9, executionID: executionID, setIndex: 1
        )

        let executions = Execution.group([third, first, second], isUnilateral: false)
        let execution = try #require(executions.first)
        #expect(executions.count == 1)
        #expect(execution.id == executionID)
        #expect(execution.setCount == 3)
        #expect(execution.sets.map(\.setIndex) == [0, 1, 2])
        #expect(execution.sets[0] === first)
        #expect(execution.sets[2] === third)
        // The execution's date is the newest set — the moment the checkmark was tapped.
        #expect(execution.date == Fixture.date(day: 1, second: 300))
        #expect(execution.peak === first)
    }

    @Test("executions come back newest first")
    func newestExecutionFirst() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        let old = UUID()
        let recent = UUID()
        let oldSet = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1),
            weightHalfKilos: 80, reps: 10, executionID: old, setIndex: 0
        )
        let recentSet = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 5),
            weightHalfKilos: 85, reps: 10, executionID: recent, setIndex: 0
        )

        let executions = Execution.group([oldSet, recentSet], isUnilateral: false)
        #expect(executions.map(\.id) == [recent, old])
        // `Exercise.executions` uses the same rule over the relationship.
        #expect(exercise.executions.map(\.id) == [recent, old])
        #expect(exercise.lastExecution?.id == recent)
    }

    @Test("a set written before V2 is its own one-set execution")
    func preV2SetIsItsOwnExecution() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        // executionID nil = the pre-V2 shape; `executionKey` falls back to the set's own id.
        let older = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1),
            weightHalfKilos: 80, reps: 10, executionID: nil
        )
        let newer = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 2),
            weightHalfKilos: 80, reps: 10, executionID: nil
        )

        let executions = Execution.group([older, newer], isUnilateral: false)
        #expect(executions.count == 2)
        #expect(executions.allSatisfy { $0.setCount == 1 })
        #expect(executions.map(\.id) == [newer.executionKey, older.executionKey])
        #expect(newer.executionKey == newer.id)
    }

    @Test("grouping an exercise without sets yields nothing")
    func noSetsNoExecutions() throws {
        let container = try makeContainer()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        #expect(Execution.group([], isUnilateral: false).isEmpty)
        #expect(exercise.executions.isEmpty)
        #expect(exercise.lastExecution == nil)
    }
}
