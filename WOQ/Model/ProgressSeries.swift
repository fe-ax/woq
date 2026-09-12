import Foundation

/// The per-exercise progress chart's data (decided 2026-09-12 evening): one point per
/// execution, oldest first, plotting the estimated one-rep max of the execution's peak set —
/// the same Epley number that picks the peak (`Execution.score`, PLAN.md "Peak rule").
///
/// Built in memory from `Exercise.executions`, like `Execution` itself; nothing is persisted.
/// Holds `Execution` values (which hold `Entry` models), so it is main-actor data like they
/// are; `nonisolated` only keeps the type usable from non-isolated code.
nonisolated struct ProgressSeries {

    /// What `Point.value` means for the whole series.
    enum Metric: Equatable, Sendable {
        /// Estimated 1RM in kilograms. Bodyweight executions in such a series sit at 0 with
        /// `isBodyweight` set and are drawn as "BW × reps" at the baseline.
        case oneRepMax
        /// Every execution's peak is a bodyweight set: the value is the peak's reps
        /// (unilateral: the L/R average).
        case reps
    }

    struct Point: Identifiable {
        /// `Execution.id`.
        let id: UUID
        let execution: Execution
        let date: Date
        /// See `Metric`. Never negative.
        let value: Double
        /// The peak set has no weight (`Execution.Score.weighted == false`).
        let isBodyweight: Bool
        let setCount: Int
        /// The first execution that reached the series' maximum — the personal record. At
        /// most one point per series; none while the series is empty.
        let isRecord: Bool
    }

    let metric: Metric
    /// Oldest first (the chart reads left to right); `Exercise.executions` is newest first.
    let points: [Point]

    var isEmpty: Bool { points.isEmpty }
    var maxValue: Double { points.map(\.value).max() ?? 0 }
    var minValue: Double { points.map(\.value).min() ?? 0 }
    var record: Point? { points.first(where: \.isRecord) }

    /// `executions` in any order; the result is sorted oldest first (date, then id for a
    /// stable order on equal dates — the same tie rule as `Execution.group`).
    ///
    /// Metric rule: one weighted peak anywhere in the history makes it a 1RM series (an
    /// exercise that started as bodyweight and then got loaded keeps one axis); only an
    /// all-bodyweight history plots reps.
    static func make(from executions: [Execution]) -> ProgressSeries {
        let ordered = executions.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        let scores = ordered.map { execution in
            Execution.score(
                weightHalfKilos: execution.peak.weightHalfKilos,
                reps: execution.peak.reps,
                repsRight: execution.peak.repsRight
            )
        }
        let metric: Metric = scores.contains(where: \.weighted) ? .oneRepMax : .reps

        let values: [Double] = scores.map { score in
            switch metric {
            case .oneRepMax: score.weighted ? score.oneRepMax : 0
            case .reps: score.reps
            }
        }
        let recordIndex = values.isEmpty ? nil : values.indices.max { values[$0] < values[$1] }
        // `max(by:)` returns the LAST maximum on ties; the record is the FIRST time it was hit.
        let firstRecordIndex = recordIndex.flatMap { index in
            values.firstIndex(of: values[index])
        }

        let points = zip(ordered, zip(values, scores)).enumerated().map { index, pair in
            let (execution, (value, score)) = pair
            return Point(
                id: execution.id,
                execution: execution,
                date: execution.date,
                value: value,
                isBodyweight: !score.weighted,
                setCount: execution.setCount,
                isRecord: index == firstRecordIndex
            )
        }
        return ProgressSeries(metric: metric, points: points)
    }

    /// Chart label for a value: whole kilograms for a 1RM ("107"), whole reps otherwise.
    /// A bodyweight point in a 1RM series has no number of its own — the chart shows "BW".
    static func valueLabel(_ value: Double, metric: Metric) -> String {
        switch metric {
        case .oneRepMax: String(Int(value.rounded()))
        case .reps: String(Int(value.rounded()))
        }
    }
}
