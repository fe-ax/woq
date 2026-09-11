import Foundation
import SwiftData
import os

/// Reads a `BackupDocument` back and merges it into the store.
///
/// Restore story (Marco's requirement): delete the app, reinstall it, point the picker at the
/// same folder, import. The merge is **additive and idempotent** — it never deletes anything,
/// and running it twice on the same file changes nothing the second time.
///
/// `@MainActor` for the same reason as `BackupWriter`: it creates and mutates `@Model`
/// instances (PLAN.md pitfall 13 and 25).
@MainActor enum BackupImporter {

    private static let logger = Logger(subsystem: "nl.feax.woq", category: "backup")

    // MARK: - Reading

    /// Reads `woq-backup.json` from `directory`.
    ///
    /// Returns nil when the file is simply not there (an empty or never-used folder), which
    /// lets the UI say "nothing to restore" without an error. A file that exists but is
    /// unreadable or malformed throws, because that is worth showing.
    ///
    /// The caller is responsible for security scope: for a picked folder call this inside
    /// `BackupFolder.withAccess { try BackupImporter.load(from: $0) }`.
    static func load(from directory: URL) throws -> BackupDocument? {
        let url = directory.appending(path: BackupDocument.fileName)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
        let data = try Data(contentsOf: url)
        return try BackupDocument.makeDecoder().decode(BackupDocument.self, from: data)
    }

    /// The day of the most recent `woq-backup-YYYY-MM-DD.json` in `directory` (local
    /// midnight), or nil when the folder holds no snapshot. Used to show "last backup" for a
    /// folder without parsing every file, and to spot a folder that stopped receiving them.
    static func latestSnapshotDate(in directory: URL) -> Date? {
        guard let names = try? FileManager.default.contentsOfDirectory(
            atPath: directory.path(percentEncoded: false)
        ) else { return nil }
        return names.compactMap { BackupDocument.snapshotDate(fromFileName: $0) }.max()
    }

    /// What a merge changed.
    nonisolated struct MergeSummary: Sendable, Equatable {
        var exercisesInserted = 0
        var exercisesUpdated = 0
        var entriesInserted = 0
        var entriesUpdated = 0

        /// True when the file held nothing the store did not already have.
        var insertedNothing: Bool { exercisesInserted == 0 && entriesInserted == 0 }

        var description: String {
            "exercises +\(exercisesInserted)/~\(exercisesUpdated), sets +\(entriesInserted)/~\(entriesUpdated)"
        }
    }

    // MARK: - Merging

    /// Merges `document` into `context` and saves.
    ///
    /// Rules:
    /// 1. **Identity is the UUID.** An exercise/entry whose `id` already exists is updated in
    ///    place; anything else is inserted. That is what makes a second merge a no-op.
    /// 2. **Name collision adopts the existing exercise.** If a record's `id` is unknown but
    ///    its case-insensitive `nameKey` (PLAN.md pitfall 10) matches an exercise already in
    ///    the store, the two are treated as the same exercise and the record's sets are merged
    ///    into the existing one. The existing `id` is kept — renumbering a live row would
    ///    orphan its entries. This is what stops "Bench press" from becoming two rows when
    ///    Marco created it by hand on a fresh install before importing. Consequence to be
    ///    aware of: two genuinely different exercises that happen to share a name cannot be
    ///    distinguished, and the store forbids duplicate names anyway (PLAN.md 3.10).
    /// 3. **Nothing is ever deleted.** An exercise or set missing from the file stays. A
    ///    backup is a safety net, not a mirror; deleting on import would turn a stale file
    ///    into data loss.
    /// 4. `lastPerformedAt` is recomputed from the merged entries (PLAN.md pitfall 1 and 11),
    ///    never copied from the file, so the queue order is always consistent with the sets.
    /// 5. `inProgressSince` is untouched: whatever is in progress right now stays in progress.
    /// 6. **Executions travel with the sets.** `executionID` / `setIndex` are taken from the
    ///    record; a file written before schema V2 has neither, and each of its sets then keeps
    ///    its own id as the execution key — one set, one execution, which is exactly how the
    ///    store reads such a set anyway (`Entry.executionKey`).
    ///
    /// The denormalised `nameKey` / `muscleSearchText` are refreshed through
    /// `Exercise.setName(_:)` / `setTags(_:)`, the only writers allowed to touch them.
    @discardableResult
    static func merge(_ document: BackupDocument, into context: ModelContext) throws -> MergeSummary {
        var summary = MergeSummary()

        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        var byID = Dictionary(existingExercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var byNameKey = Dictionary(existingExercises.map { ($0.nameKey, $0) }, uniquingKeysWith: { first, _ in first })

        // Entries are keyed globally: `Entry.id` is @Attribute(.unique), so an id that already
        // exists must be updated (and re-parented if needed) rather than inserted, otherwise
        // save() would silently upsert (docs/swiftui-swiftdata.md 1e).
        let existingEntries = try context.fetch(FetchDescriptor<Entry>())
        var entriesByID = Dictionary(existingEntries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for record in document.exercises {
            let nameKey = Exercise.nameKey(for: record.name)
            let exercise: Exercise

            if let match = byID[record.id] ?? byNameKey[nameKey] {
                exercise = match
                exercise.setName(record.name)
                exercise.isUnilateral = record.isUnilateral
                exercise.setTags(record.muscleTags)
                exercise.createdAt = record.createdAt
                summary.exercisesUpdated += 1
            } else {
                let created = Exercise(
                    name: record.name,
                    isUnilateral: record.isUnilateral,
                    tags: record.muscleTags,
                    createdAt: record.createdAt
                )
                // The initializer mints a fresh UUID; the backup's id is the identity that
                // makes a repeated merge idempotent, so overwrite it before inserting.
                created.id = record.id
                context.insert(created)
                exercise = created
                summary.exercisesInserted += 1
            }

            // Register under both keys so a later record that collides on either one lands on
            // the same object instead of inserting a duplicate.
            byID[record.id] = exercise
            byID[exercise.id] = exercise
            byNameKey[exercise.nameKey] = exercise

            for entryRecord in record.entries {
                // A file written before schema V2 carries neither field. Falling back to the
                // set's own id (the same rule as `Entry.executionKey`) turns every such set
                // into its own one-set execution instead of merging unrelated sets.
                let executionID = entryRecord.executionID ?? entryRecord.id
                let setIndex = entryRecord.setIndex ?? 0

                if let existing = entriesByID[entryRecord.id] {
                    existing.date = entryRecord.date
                    existing.weightHalfKilos = entryRecord.weightHalfKilos
                    existing.reps = entryRecord.reps
                    existing.repsRight = entryRecord.repsRight
                    existing.executionID = executionID
                    existing.setIndex = setIndex
                    if existing.exercise !== exercise {
                        existing.exercise = exercise
                    }
                    summary.entriesUpdated += 1
                } else {
                    let entry = Entry(
                        date: entryRecord.date,
                        weightHalfKilos: entryRecord.weightHalfKilos,
                        reps: entryRecord.reps,
                        repsRight: entryRecord.repsRight,
                        executionID: executionID,
                        setIndex: setIndex
                    )
                    entry.id = entryRecord.id
                    context.insert(entry)
                    entry.exercise = exercise
                    entriesByID[entryRecord.id] = entry
                    summary.entriesInserted += 1
                }
            }

            // Recompute the denormalised sort key. The record's own dates are folded in as
            // well, so the value is right even if the inverse relationship has not been
            // materialised yet (docs/swiftui-swiftdata.md 1i).
            let dates = exercise.entries.map(\.date) + record.entries.map(\.date)
            exercise.lastPerformedAt = dates.max()
        }

        try context.save()
        logger.notice("merged backup: \(summary.description, privacy: .public)")
        return summary
    }
}
