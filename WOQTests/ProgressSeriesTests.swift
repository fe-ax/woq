import Foundation
import SwiftData
import Testing
@testable import WOQ

/// `ProgressSeries` — the per-exercise progress chart's data (PLAN.md section 2 "Charts",
/// 2026-09-12 evening): one point per execution, oldest first, the estimated 1RM of the peak.
@Suite("Progress series")
struct ProgressSeriesTests {

    /// Two executions on separate days, the second one heavier: 80 kg × 10 then 85 kg × 8.
    private func twoExecutions() throws -> (ModelContainer, Exercise) {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        let first = UUID()
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 1), weightHalfKilos: 160, reps: 10, executionID: first, setIndex: 0)
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 1, second: 60), weightHalfKilos: 160, reps: 8, executionID: first, setIndex: 1)
        let second = UUID()
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 4), weightHalfKilos: 170, reps: 8, executionID: second, setIndex: 0)
        return (container, exercise)
    }

    @Test("points come oldest first with the peak's Epley estimate")
    func oldestFirstWithEpley() throws {
        // The container must outlive the assertions: dropping it resets the context and
        // destroys the model instances the series points at.
        let (container, exercise) = try twoExecutions()
        let series = withExtendedLifetime(container) { ProgressSeries.make(from: exercise.executions) }

        #expect(series.metric == .oneRepMax)
        #expect(series.points.count == 2)
        #expect(series.points.map(\.date) == [Fixture.date(day: 1, second: 60), Fixture.date(day: 4)])
        // 80 kg × 10 -> 80 × (1 + 10/30) = 106.67; 85 kg × 8 -> 85 × (1 + 8/30) = 107.67.
        #expect(abs(series.points[0].value - 106.666_67) < 0.001)
        #expect(abs(series.points[1].value - 107.666_67) < 0.001)
        #expect(series.points.map(\.setCount) == [2, 1])
        #expect(series.points.map(\.isBodyweight) == [false, false])
    }

    @Test("the record is the newest maximum's FIRST occurrence")
    func recordIsFirstMaximum() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Squat", in: context)
        // 100 kg × 5 three times, then a lighter session: the PR is day 1, not day 3.
        for day in [1, 3] {
            Fixture.entry(in: context, of: exercise, date: Fixture.date(day: day), weightHalfKilos: 200, reps: 5, executionID: UUID())
        }
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 5), weightHalfKilos: 180, reps: 5, executionID: UUID())

        let series = ProgressSeries.make(from: exercise.executions)

        #expect(series.points.filter(\.isRecord).count == 1)
        #expect(series.record?.date == Fixture.date(day: 1))
        #expect(series.maxValue == series.points[0].value)
        #expect(series.minValue == series.points[2].value)
    }

    @Test("one weighted peak makes it a 1RM series; bodyweight points sit at zero")
    func mixedHistoryIsOneRepMax() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Pull-up", in: context)
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 1), weightHalfKilos: nil, reps: 12, executionID: UUID())
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 8), weightHalfKilos: 20, reps: 8, executionID: UUID())

        let series = ProgressSeries.make(from: exercise.executions)

        #expect(series.metric == .oneRepMax)
        #expect(series.points[0].isBodyweight)
        #expect(series.points[0].value == 0)
        #expect(!series.points[1].isBodyweight)
        #expect(series.points[1].isRecord)
    }

    @Test("an all-bodyweight history plots reps, averaged over both sides")
    func bodyweightHistoryPlotsReps() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Split squat", in: context, isUnilateral: true)
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 1), weightHalfKilos: nil, reps: 10, repsRight: 12, executionID: UUID())
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 3), weightHalfKilos: nil, reps: 14, repsRight: 14, executionID: UUID())

        let series = ProgressSeries.make(from: exercise.executions)

        #expect(series.metric == .reps)
        #expect(series.points.map(\.value) == [11, 14])
        #expect(series.points.map(\.isBodyweight) == [true, true])
        #expect(series.record?.value == 14)
    }

    @Test("an exercise without sets gives an empty series")
    func emptySeries() throws {
        let container = try makeContainer()
        let exercise = Fixture.exercise("New", in: container.mainContext)

        let series = ProgressSeries.make(from: exercise.executions)

        #expect(series.isEmpty)
        #expect(series.record == nil)
        #expect(series.maxValue == 0)
    }

    @Test("pre-V2 sets are their own points")
    func preV2SetsAreOwnPoints() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Row", in: context)
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 1), weightHalfKilos: 100, reps: 10)
        Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 2), weightHalfKilos: 100, reps: 11)

        let series = ProgressSeries.make(from: exercise.executions)

        #expect(series.points.count == 2)
        #expect(series.points.map(\.setCount) == [1, 1])
        #expect(series.record?.date == Fixture.date(day: 2))
    }

    @Test("value labels are whole numbers")
    func valueLabels() {
        #expect(ProgressSeries.valueLabel(106.666, metric: .oneRepMax) == "107")
        #expect(ProgressSeries.valueLabel(107.4, metric: .oneRepMax) == "107")
        #expect(ProgressSeries.valueLabel(11, metric: .reps) == "11")
    }
}
