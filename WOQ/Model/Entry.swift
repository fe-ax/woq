import Foundation
import SwiftData

/// `Entry` everywhere in the app means the current schema version's model class.
/// Only Schema.swift and this file mention a version; every call site writes `Entry`.
/// When V2 arrives, repoint this alias (see the note on `WOQSchemaV1`).
typealias Entry = WOQSchemaV1.Entry

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
