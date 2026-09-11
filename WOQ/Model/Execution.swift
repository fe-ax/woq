import Foundation

/// One logging event of an exercise: the sets written between "start" and the checkmark
/// (PLAN.md "Multi-set executions", 2026-09-12).
///
/// Nothing about an execution is persisted as such. The sets themselves are the rows
/// (`Entry` is still exactly one set) and they carry the grouping with them:
/// `Entry.executionID` + `Entry.setIndex`, resolved through `Entry.executionKey` so that a
/// set written before schema V2 is its own one-set execution. This type is the read model,
/// built in memory by `group(_:isUnilateral:)` whenever a view needs the history.
///
/// It holds `Entry` (a `@Model` class) references, so it is deliberately NOT `Sendable`:
/// models live on the main actor (PLAN.md pitfall 13 and 25) and so does every use of this
/// type. `nonisolated` on the struct only keeps the *type* usable from non-isolated code such
/// as `Exercise.executions` on the `nonisolated` model class.
nonisolated struct Execution: Identifiable {

    /// `Entry.executionKey` shared by every set in `sets`.
    let id: UUID

    /// The sets, ordered by `setIndex`, then `date`, then `id` — a stable order even for
    /// old sets that all carry `setIndex == 0`. Never empty.
    let sets: [Entry]

    /// The newest set date in the execution. That is the moment the checkmark was tapped
    /// (`QueueStore.finalize` stamps `lastPerformedAt` with the same value), so for the
    /// newest execution this equals `Exercise.lastPerformedAt`.
    let date: Date

    /// The best set of the execution by the peak rule below — what the queue row, the
    /// in-progress card's muted line and the prefill show.
    let peak: Entry

    /// How many sets were logged in this one go. 1 for every pre-V2 set.
    var setCount: Int { sets.count }

    /// Builds one execution from the sets that share a key. Fails only on an empty list,
    /// which `group(_:isUnilateral:)` can never produce.
    init?(id: UUID, sets: [Entry], isUnilateral: Bool) {
        let ordered = Self.ordered(sets)
        guard let peak = Self.peak(of: ordered, isUnilateral: isUnilateral),
              let date = ordered.map(\.date).max()
        else { return nil }
        self.id = id
        self.sets = ordered
        self.date = date
        self.peak = peak
    }

    // MARK: - Grouping

    /// Groups an exercise's entries into executions, **newest first**.
    ///
    /// In memory on purpose (PLAN.md pitfall 28): `executionKey` is computed, so it can never
    /// appear in a `#Predicate`, and the entries of one exercise are a handful of rows the
    /// relationship has already materialised.
    ///
    /// Ties on `date` (two executions finished in the same instant — only reachable through a
    /// hand-edited backup) break on the key's string form, so the order is at least stable
    /// between launches.
    static func group(_ entries: [Entry], isUnilateral: Bool) -> [Execution] {
        guard !entries.isEmpty else { return [] }

        var buckets: [UUID: [Entry]] = [:]
        for entry in entries {
            buckets[entry.executionKey, default: []].append(entry)
        }

        return buckets
            .compactMap { Execution(id: $0.key, sets: $0.value, isUnilateral: isUnilateral) }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date > rhs.date }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    /// The sets of one execution in display order: `setIndex`, then `date`, then `id`.
    /// Pre-V2 sets all have `setIndex == 0`, hence the date fallback; `id` only ever decides
    /// between two sets logged in the same instant, and keeps the order stable.
    private static func ordered(_ sets: [Entry]) -> [Entry] {
        sets.sorted { lhs, rhs in
            if lhs.setIndex != rhs.setIndex { return lhs.setIndex < rhs.setIndex }
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    // MARK: - Peak

    /// The best set of `sets`, or nil when the list is empty.
    ///
    /// Iterates in display order and replaces the champion only on a **strictly** greater
    /// score, so an exact tie is won by the earlier set (lower `setIndex`, then earlier date)
    /// (the tie rule decided with Marco on 2026-09-12).
    ///
    /// `isUnilateral` is the owning exercise's flag and is accepted for call-site clarity
    /// (and so a future rule may use it); the score itself never reads it. Whether a set
    /// counts as unilateral is decided per set by its own `repsRight`, because an exercise
    /// that was switched to L/R later still has bilateral sets in its history.
    static func peak(of sets: [Entry], isUnilateral: Bool) -> Entry? {
        var best: Entry?
        var bestScore: Score?

        for entry in ordered(sets) {
            let candidate = score(
                weightHalfKilos: entry.weightHalfKilos,
                reps: entry.reps,
                repsRight: entry.repsRight
            )
            if let bestScore, candidate <= bestScore { continue }
            best = entry
            bestScore = candidate
        }

        return best
    }

    /// The pure scoring rule, without SwiftData — so a macOS runtime check can exercise it
    /// (~/claude-files/woq/multi-set/peak-check).
    ///
    /// Estimated one-rep max, **Epley**: `kg × (1 + reps / 30)`, with `kg = weightHalfKilos / 2`
    /// and `reps` = the plain reps for a bilateral set, or `(reps + repsRight) / 2` when the set
    /// carries a right side. So 80 kg × 10 (106.67) beats 82.5 kg × 6 (99.0): more volume at
    /// slightly less weight is the better set.
    ///
    /// Computed as `halfKilos × (60 + left + right) / 120`, which is the same number with the
    /// division done last: the numerator is an exact `Int`, so two mathematically equal
    /// estimates produce bit-identical `Double`s and a real tie stays a tie instead of being
    /// decided by floating-point noise.
    ///
    /// A bodyweight set (`weightHalfKilos == nil`, or a non-positive value from a hand-edited
    /// backup) has no 1RM at all: `weighted` is false, which ranks it below EVERY weighted set,
    /// and bodyweight sets rank against each other on reps (same L/R averaging).
    /// Ties fall through to the heavier weight, then to more reps; `peak(of:isUnilateral:)`
    /// resolves what is still tied to the earlier set.
    static func score(weightHalfKilos: Int?, reps: Int, repsRight: Int?) -> Score {
        // A bilateral set counts its reps for both sides, so one formula covers both cases.
        let repsSum = reps + (repsRight ?? reps)
        let averageReps = Double(repsSum) / 2

        guard let halfKilos = weightHalfKilos, halfKilos > 0 else {
            return Score(weighted: false, oneRepMax: 0, weightHalfKilos: 0, reps: averageReps)
        }

        return Score(
            weighted: true,
            oneRepMax: Double(halfKilos * (60 + repsSum)) / 120,
            weightHalfKilos: halfKilos,
            reps: averageReps
        )
    }

    /// How good one set is. Greater is better, so `max()` is the peak.
    ///
    /// `Sendable` (unlike `Execution` itself) because it is plain numbers: the scoring rule can
    /// be checked anywhere, including off the main actor.
    nonisolated struct Score: Comparable, Sendable {
        /// False for a bodyweight set. Any weighted set beats any bodyweight set.
        let weighted: Bool
        /// Epley estimate in kilograms; 0 for a bodyweight set.
        let oneRepMax: Double
        /// Tie-break 1: the heavier set wins. 0 for a bodyweight set.
        let weightHalfKilos: Int
        /// Tie-break 2 (and the only ranking between bodyweight sets): reps, averaged over
        /// both sides for a unilateral set.
        let reps: Double

        static func < (lhs: Score, rhs: Score) -> Bool {
            if lhs.weighted != rhs.weighted { return !lhs.weighted }
            if lhs.oneRepMax != rhs.oneRepMax { return lhs.oneRepMax < rhs.oneRepMax }
            if lhs.weightHalfKilos != rhs.weightHalfKilos { return lhs.weightHalfKilos < rhs.weightHalfKilos }
            return lhs.reps < rhs.reps
        }
    }
}
