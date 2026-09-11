import Foundation
import SwiftData
import os

/// The single owner of every `Exercise` / `Entry` mutation (PLAN.md 3.2 and pitfalls 1, 2, 11).
///
/// Views read models through `@Query` and call into the store to change anything. Nothing
/// else may write `lastPerformedAt` or `inProgressSince`, and nothing else keeps the
/// denormalised `nameKey` / `muscleSearchText` in sync — that happens through
/// `Exercise.setName(_:)` / `Exercise.setTags(_:)`, called from here only.
///
/// Everything stays on the main actor with the container's `mainContext`
/// (PLAN.md pitfall 13 and 25): no `Task.detached`, no background context, no `@ModelActor`.
@Observable @MainActor final class QueueStore {

    @ObservationIgnored let modelContext: ModelContext

    @ObservationIgnored
    private let logger = Logger(subsystem: "nl.feax.woq", category: "store")

    /// Set when a save fails, so the UI can show something instead of losing data silently.
    var lastError: String?

    /// Called after every successful `save()`. `BackupScheduler.noteChange()` hangs here, so
    /// any mutation the store performs schedules a debounced backup without views knowing.
    /// `@ObservationIgnored` because a callback is not view state (same as `modelContext`).
    @ObservationIgnored var onSaved: (() -> Void)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Ordering

    /// Queue order (PLAN.md 3.1 and pitfall 30): `lastPerformedAt` forward puts nil FIRST
    /// (verified on SQLite and in memory, docs/swiftui-swiftdata.md 1d), so a never
    /// performed exercise counts as "longest ago". Ties break on `createdAt`, then `name`.
    static let sortDescriptors: [SortDescriptor<Exercise>] = [
        SortDescriptor(\Exercise.lastPerformedAt, order: .forward),
        SortDescriptor(\Exercise.createdAt, order: .forward),
        SortDescriptor(\Exercise.name, order: .forward),
    ]

    /// The same rule applied in memory. Safety net for views that already hold an array
    /// (and for any future fetch that forgets the descriptors).
    static func ordered(_ exercises: [Exercise]) -> [Exercise] {
        exercises.sorted { lhs, rhs in
            switch (lhs.lastPerformedAt, rhs.lastPerformedAt) {
            case let (left?, right?) where left != right:
                return left < right
            case (nil, .some):
                return true
            case (.some, nil):
                return false
            default:
                break
            }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    // MARK: - In progress

    /// The in-progress exercise inside a list the view already has (PLAN.md 5).
    func inProgressExercise(in exercises: [Exercise]) -> Exercise? {
        exercises.first { $0.inProgressSince != nil }
    }

    /// The in-progress exercise fetched from the store, for callers without a list.
    func inProgressExercise() -> Exercise? {
        var descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.inProgressSince != nil },
            sortBy: [SortDescriptor(\Exercise.inProgressSince, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor).first
    }

    nonisolated enum StartResult: Equatable {
        case started
        /// Another exercise is already in progress; nothing changed (PLAN.md 3.3).
        case refused(current: Exercise)
    }

    /// Starts an exercise. Exactly one exercise may be in progress; starting the one that
    /// already is, is a no-op `.started`.
    @discardableResult
    func start(_ exercise: Exercise) -> StartResult {
        if let current = inProgressExercise(), current !== exercise {
            return .refused(current: current)
        }
        if exercise.inProgressSince == nil {
            exercise.inProgressSince = .now
            save()
        }
        return .started
    }

    /// Put back: the exercise returns to its sorted queue position, drafts are discarded
    /// by the view (PLAN.md 3.6).
    func putBack(_ exercise: Exercise) {
        guard exercise.inProgressSince != nil else { return }
        exercise.inProgressSince = nil
        save()
    }

    /// Finalize (PLAN.md 3.5, extended 2026-09-12): write the whole execution — one `Entry`
    /// per set, all sharing one fresh `executionID` and numbered by `setIndex` — stamp
    /// `lastPerformedAt`, clear the in-progress marker. The exercise sorts to the bottom of
    /// the queue afterwards.
    ///
    /// The pending sets come from the card (plus, plus, … checkmark) and are saved in ONE go:
    /// one `save()`, so one debounced backup, and the sets can never end up half-written.
    /// Each set keeps the moment its plus was tapped as its `Entry.date` (`PendingSet.loggedAt`),
    /// while `date` is the checkmark. An empty list is a no-op: there is no such thing as an
    /// execution without sets (the checkmark always contributes one), so it is logged and
    /// nothing is touched.
    @discardableResult
    func finalize(_ exercise: Exercise, with sets: [PendingSet], at date: Date = .now) -> [Entry] {
        guard !sets.isEmpty else {
            logger.error("finalize with no sets for \(exercise.nameKey, privacy: .public)")
            return []
        }

        let executionID = UUID()
        var entries: [Entry] = []
        entries.reserveCapacity(sets.count)

        for (index, pending) in sets.enumerated() {
            let entry = Entry(
                date: pending.loggedAt,
                weightHalfKilos: pending.set.weightHalfKilos,
                reps: pending.set.reps,
                repsRight: pending.set.repsRight,
                executionID: executionID,
                setIndex: index
            )
            modelContext.insert(entry)
            entry.exercise = exercise
            entries.append(entry)
        }

        // `lastPerformedAt` is the checkmark time, but never earlier than the last set:
        // `Execution.date` is the max set date and the queue sorts on `lastPerformedAt`, so a
        // caller that passes an older `date` (seed data, a runtime check) must not leave the
        // exercise sorted above its own sets.
        let lastSetAt = sets.map(\.loggedAt).max() ?? date
        exercise.lastPerformedAt = max(date, lastSetAt)
        exercise.inProgressSince = nil
        save()
        return entries
    }

    /// Single-set convenience: one set is simply an execution of one (`addExercise`'s
    /// optional first set, `SeedData`). Returns that entry; the list handed to the multi-set
    /// `finalize` is never empty, so the subscript cannot trap.
    @discardableResult
    func finalize(_ exercise: Exercise, with set: ValidatedSet, at date: Date = .now) -> Entry {
        finalize(exercise, with: [PendingSet(set: set, loggedAt: date)], at: date)[0]
    }

    // MARK: - Exercises

    nonisolated enum FirstSetOutcome: Equatable {
        /// The first set validated: an entry was written straight away.
        case logged
        /// Nothing valid was typed and nothing was in progress: the new exercise started.
        case startedInProgress
        /// Something else is in progress: the new exercise waits in the queue.
        case queued
    }

    /// New exercise (PLAN.md section 2 "New exercise" and 3.3).
    ///
    /// A valid first set is logged immediately. Otherwise, when nothing is in progress the
    /// new exercise becomes the in-progress one — also when the draft is partially filled,
    /// because the UI carries the typed values into the in-progress card. When another
    /// exercise is in progress the new one is simply queued (never performed = top).
    func addExercise(
        name: String,
        isUnilateral: Bool,
        tags: [MuscleTag],
        firstSet: SetDraft?
    ) -> (Exercise, FirstSetOutcome) {
        let exercise = Exercise(name: name, isUnilateral: isUnilateral, tags: tags)
        modelContext.insert(exercise)

        if let firstSet, case .success(let set) = firstSet.validate(isUnilateral: isUnilateral) {
            finalize(exercise, with: set)
            return (exercise, .logged)
        }

        if inProgressExercise() == nil {
            start(exercise)
            return (exercise, .startedInProgress)
        }

        save()
        return (exercise, .queued)
    }

    /// Adds a batch of presets from the "New exercise" sheet's preset list.
    ///
    /// Deliberately different from `addExercise(name:isUnilateral:tags:firstSet:)`: a batch
    /// NEVER starts anything in progress, not even when the queue is at rest. Ticking five
    /// presets means "put these in my queue", and picking one of them to start would be a
    /// guess; every preset therefore lands as never performed, which sorts it to the top
    /// (PLAN.md 3.1). One `save()` for the whole batch, so one debounced backup follows.
    ///
    /// Names that are no longer available (case-insensitively, including duplicates inside
    /// `presets` itself) are skipped silently — the list already shows those rows as
    /// "Added", so a name can only collide if the store changed underneath the sheet.
    /// Returns the exercises that were actually inserted, in the order they were given.
    @discardableResult
    func addExercises(_ presets: [ExercisePreset]) -> [Exercise] {
        var taken = Set(fetch(FetchDescriptor<Exercise>()).map(\.nameKey))
        var added: [Exercise] = []

        for preset in presets {
            let key = Self.nameKey(for: preset.name)
            guard !key.isEmpty, !taken.contains(key) else { continue }
            taken.insert(key)

            let exercise = Exercise(
                name: preset.name,
                isUnilateral: preset.isUnilateral,
                tags: preset.tags
            )
            modelContext.insert(exercise)
            added.append(exercise)
        }

        guard !added.isEmpty else { return [] }
        save()
        return added
    }

    /// Edit an exercise. Flipping `isUnilateral` leaves existing entries untouched: their
    /// `repsRight` stays as recorded, so old sets keep reading the way they were logged.
    func updateExercise(
        _ exercise: Exercise,
        name: String,
        isUnilateral: Bool,
        tags: [MuscleTag]
    ) {
        exercise.setName(name)
        exercise.isUnilateral = isUnilateral
        exercise.setTags(tags)
        save()
    }

    /// Delete an exercise; the cascade rule deletes its entries (PLAN.md 3.9).
    func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        save()
    }

    // MARK: - Entries

    /// Delete one entry and recompute the owner's `lastPerformedAt` as the max remaining
    /// entry date — nil when none is left (PLAN.md 3.8 and pitfall 11).
    ///
    /// Executions need no bookkeeping here: they are grouped from the entries at read time
    /// (`Execution.group(_:isUnilateral:)`), so deleting the last set of an execution makes
    /// that execution disappear by itself, and the history numbers sets by position rather
    /// than by the now-gapped `setIndex`.
    func deleteEntry(_ entry: Entry) {
        let owner = entry.exercise
        entry.exercise = nil
        modelContext.delete(entry)
        if let owner {
            let remaining = owner.entries.filter { $0 !== entry }
            owner.lastPerformedAt = remaining.map(\.date).max()
        }
        save()
    }

    /// Edit one entry (weight and reps only; the date is fixed, PLAN.md section 2 "Detail")
    /// and recompute the owner's `lastPerformedAt`.
    func updateEntry(_ entry: Entry, weightHalfKilos: Int?, reps: Int, repsRight: Int?) {
        entry.weightHalfKilos = weightHalfKilos
        entry.reps = reps
        entry.repsRight = repsRight
        if let owner = entry.exercise {
            owner.lastPerformedAt = owner.entries.map(\.date).max()
        }
        save()
    }

    // MARK: - Names

    /// Lowercased, whitespace-trimmed duplicate key (PLAN.md pitfall 10).
    static func nameKey(for name: String) -> String {
        Exercise.nameKey(for: name)
    }

    /// Every name key currently in the store. The preset list checks 39 names at once and
    /// would otherwise run one `isNameAvailable(_:)` fetch per row on every redraw.
    func existingNameKeys() -> Set<String> {
        Set(fetch(FetchDescriptor<Exercise>()).map(\.nameKey))
    }

    /// True when no other exercise already uses this name, case- and whitespace-insensitively.
    /// An empty name is never available, so Save stays disabled for it.
    func isNameAvailable(_ name: String, excluding: Exercise? = nil) -> Bool {
        let key = Self.nameKey(for: name)
        guard !key.isEmpty else { return false }
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate<Exercise> { $0.nameKey == key })
        return !fetch(descriptor).contains { $0 !== excluding }
    }

    // MARK: - Persistence

    /// Every mutating method ends here. Failures are logged and surfaced through `lastError`
    /// instead of crashing.
    func save() {
        do {
            try modelContext.save()
            if lastError != nil { lastError = nil }
            onSaved?()
        } catch {
            logger.error("save failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }

    /// Never `try!` a predicate fetch: unsupported predicates only fail at fetch time
    /// (PLAN.md pitfall 28).
    private func fetch(_ descriptor: FetchDescriptor<Exercise>) -> [Exercise] {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("fetch failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
            return []
        }
    }
}
