import Foundation
import SwiftData

extension WOQSchemaV1 {

    /// One finalized set for an exercise (PLAN.md section 5).
    ///
    /// Weight is stored as integer half-kilos so 0.5 steps never suffer floating point
    /// rounding: 45 == 22.5 kg, 80 == 40 kg, nil == bodyweight ("BW").
    /// For a unilateral exercise `reps` holds the LEFT side and `repsRight` the right one;
    /// for a bilateral exercise `repsRight` is nil.
    ///
    /// Explicit `nonisolated` per PLAN.md pitfall 25. Only `QueueStore` creates, edits or
    /// deletes entries; it recomputes the owning exercise's `lastPerformedAt` afterwards
    /// (PLAN.md pitfall 11).
    ///
    /// Nested in `WOQSchemaV1` so a future version can hold its own copy (PLAN.md pitfall 12).
    /// The persisted entity name is still `"Entry"`, so this is not a schema change.
    /// **Never edit this class once V2 exists** — copy it into `WOQSchemaV2` and change that copy.
    @Model nonisolated final class Entry {
        @Attribute(.unique) var id: UUID = UUID()

        var date: Date = Date.now
        /// nil = bodyweight. 45 == 22.5 kg.
        var weightHalfKilos: Int?
        /// Bilateral reps, or LEFT reps when the exercise is unilateral.
        var reps: Int = 0
        /// Right-side reps, nil for a bilateral exercise.
        var repsRight: Int?

        var exercise: Exercise?

        init(
            date: Date = .now,
            weightHalfKilos: Int? = nil,
            reps: Int,
            repsRight: Int? = nil
        ) {
            self.id = UUID()
            self.date = date
            self.weightHalfKilos = weightHalfKilos
            self.reps = reps
            self.repsRight = repsRight
        }
    }
}

/// `Entry` everywhere in the app means the current schema version's model class.
/// Only Schema.swift and this file mention a version; every call site writes `Entry`.
/// When V3 arrives, repoint this alias and move it next to the V3 class
/// (see the note on `WOQSchemaV2`).
typealias Entry = WOQSchemaV2.Entry

extension WOQSchemaV2 {

    /// One finalized set for an exercise — V2 copy (PLAN.md section 5 and "Multi-set
    /// executions", 2026-09-12).
    ///
    /// Identical to `WOQSchemaV1.Entry` plus the two execution columns. An `Entry` is still
    /// exactly ONE set; several sets logged in one go (the card's plus button, then the
    /// checkmark) share one `executionID` and number themselves with `setIndex`. Grouping
    /// therefore costs nothing at write time and per-set edit / delete keeps working the way
    /// it always did.
    ///
    /// Weight is stored as integer half-kilos so 0.5 steps never suffer floating point
    /// rounding: 45 == 22.5 kg, 80 == 40 kg, nil == bodyweight ("BW").
    /// For a unilateral exercise `reps` holds the LEFT side and `repsRight` the right one;
    /// for a bilateral exercise `repsRight` is nil.
    ///
    /// Explicit `nonisolated` per PLAN.md pitfall 25. Only `QueueStore` creates, edits or
    /// deletes entries; it recomputes the owning exercise's `lastPerformedAt` afterwards
    /// (PLAN.md pitfall 11).
    ///
    /// **Never edit this class once V3 exists** — copy it into `WOQSchemaV3` and change that copy.
    @Model nonisolated final class Entry {
        @Attribute(.unique) var id: UUID = UUID()

        var date: Date = Date.now
        /// nil = bodyweight. 45 == 22.5 kg.
        var weightHalfKilos: Int?
        /// Bilateral reps, or LEFT reps when the exercise is unilateral.
        var reps: Int = 0
        /// Right-side reps, nil for a bilateral exercise.
        var repsRight: Int?

        /// Sets that share an `executionID` were logged in one go — one "start … checkmark"
        /// round on the in-progress card. Optional because every set written before V2 has
        /// none, which is exactly what makes the migration lightweight: such a set is its own
        /// one-set execution through `executionKey`.
        var executionID: UUID?
        /// Position inside the execution (0-based), for a stable order and the "1 / 2 / 3"
        /// labels in the history. Inline default so the migration can infer it
        /// (PLAN.md pitfall 27).
        var setIndex: Int = 0

        var exercise: Exercise?

        init(
            date: Date = .now,
            weightHalfKilos: Int? = nil,
            reps: Int,
            repsRight: Int? = nil,
            executionID: UUID? = nil,
            setIndex: Int = 0
        ) {
            self.id = UUID()
            self.date = date
            self.weightHalfKilos = weightHalfKilos
            self.reps = reps
            self.repsRight = repsRight
            self.executionID = executionID
            self.setIndex = setIndex
        }

        // MARK: - Derived state (never persisted, never usable in a #Predicate)

        /// The key sets are grouped by. A pre-V2 set has no `executionID` and falls back to its
        /// own `id`, so it forms a one-set execution without a single row being rewritten.
        ///
        /// Computed, so it can NEVER appear in a `#Predicate` (PLAN.md pitfall 28): grouping
        /// happens in memory in `Execution.group(_:isUnilateral:)`, over the entries SwiftData
        /// already materialised through the relationship.
        var executionKey: UUID { executionID ?? id }
    }
}
