import Foundation
import SwiftData

/// Turns the SwiftData store into a `BackupDocument` and writes it out.
///
/// Concurrency (PLAN.md pitfall 13 and 25): the enum is `@MainActor` because
/// `makeDocument(context:)` touches `@Model` instances, which live on the main actor and are
/// explicitly not `Sendable`. There is deliberately **no `Task.detached`** anywhere: a model
/// instance may never cross that boundary. Encoding is the only part that could run
/// elsewhere, so it is factored out as `nonisolated encode(_:)` taking the `Sendable`
/// document — but it is still called synchronously, because a full backup of this store is a
/// few dozen kilobytes and a hop would only add failure modes.
@MainActor enum BackupWriter {

    // MARK: - Building

    /// Snapshots every exercise and every set.
    ///
    /// Exercises come back sorted by `createdAt` (then name, so the order is total and the
    /// file is byte-stable between runs), entries sorted by `date` oldest first.
    /// `inProgressSince` is skipped on purpose — see `BackupDocument`.
    ///
    /// Throws whatever `fetch` throws; the caller (`BackupScheduler`) logs it rather than
    /// letting a backup failure take the app down.
    static func makeDocument(context: ModelContext) throws -> BackupDocument {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [
                SortDescriptor(\Exercise.createdAt, order: .forward),
                SortDescriptor(\Exercise.name, order: .forward),
            ]
        )
        let exercises = try context.fetch(descriptor)

        let records = exercises.map { exercise in
            ExerciseRecord(
                id: exercise.id,
                name: exercise.name,
                isUnilateral: exercise.isUnilateral,
                muscleTags: exercise.muscleTags,
                createdAt: exercise.createdAt,
                lastPerformedAt: exercise.lastPerformedAt,
                entries: exercise.entries
                    .sorted { $0.date < $1.date }
                    .map { entry in
                        EntryRecord(
                            id: entry.id,
                            date: entry.date,
                            weightHalfKilos: entry.weightHalfKilos,
                            reps: entry.reps,
                            repsRight: entry.repsRight
                        )
                    }
            )
        }

        return BackupDocument(exportedAt: .now, exercises: records)
    }

    /// JSON for a document. `nonisolated` and taking only `Sendable` values, so it is usable
    /// from any isolation without ever seeing a `@Model`.
    nonisolated static func encode(_ document: BackupDocument) throws -> Data {
        try BackupDocument.makeEncoder().encode(document)
    }

    // MARK: - Writing

    /// Writes `woq-backup.json` plus today's dated snapshot into `directory`, then prunes old
    /// snapshots.
    ///
    /// - `woq-backup.json` is the file the importer reads; it is replaced every time.
    /// - `woq-backup-YYYY-MM-DD.json` is today's snapshot, overwritten when it already exists,
    ///   so a day of heavy logging still leaves exactly one file per day.
    /// - Snapshots beyond `keepDailySnapshots` (the newest ones win) are deleted. Files whose
    ///   name is not a WOQ snapshot are never touched, so pointing the picker at a shared
    ///   iCloud folder cannot eat unrelated documents.
    ///
    /// Both files are written with `Data.write(options: .atomic)`: a crash or a provider
    /// hiccup mid-write leaves the previous complete file in place rather than a truncated one.
    /// The directory is created when missing (harmless for the local folder, a no-op for a
    /// picked one).
    ///
    /// Throws on the first failed write; rotation failures are swallowed (a stale snapshot is
    /// not worth failing a good backup over).
    static func write(
        _ document: BackupDocument,
        to directory: URL,
        keepDailySnapshots: Int = 14,
        now: Date = .now
    ) throws {
        let data = try encode(document)
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: directory.path(percentEncoded: false)) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        try data.write(to: directory.appending(path: BackupDocument.fileName), options: .atomic)

        let snapshotName = BackupDocument.snapshotFileName(for: now)
        try data.write(to: directory.appending(path: snapshotName), options: .atomic)

        rotateSnapshots(in: directory, keeping: keepDailySnapshots)
    }

    /// Deletes all but the `keep` newest dated snapshots. Never deletes `woq-backup.json`
    /// (its name has no date) and never deletes a file whose name does not parse as a
    /// snapshot. `keep` is clamped to at least 1 so a bad argument cannot wipe the folder.
    static func rotateSnapshots(in directory: URL, keeping keep: Int) {
        let limit = max(1, keep)
        let fileManager = FileManager.default
        guard let names = try? fileManager.contentsOfDirectory(atPath: directory.path(percentEncoded: false)) else {
            return
        }

        let dated = names
            .compactMap { name -> (name: String, date: Date)? in
                guard let date = BackupDocument.snapshotDate(fromFileName: name) else { return nil }
                return (name, date)
            }
            .sorted { $0.date > $1.date }

        guard dated.count > limit else { return }
        for stale in dated.dropFirst(limit) {
            try? fileManager.removeItem(at: directory.appending(path: stale.name))
        }
    }
}
