import Foundation
import SwiftData

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
