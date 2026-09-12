import Foundation

/// The on-disk shape of a WOQ backup: one JSON file holding every exercise and every set.
///
/// Design rules (PLAN.md section 5, pitfall 13/25 and docs/swiftui-swiftdata.md 1j):
/// - Plain `Sendable` value types, never `@Model` instances, so a document can cross an
///   isolation boundary and be encoded anywhere. `docs/swiftui-swiftdata.md` 1j is explicit:
///   for export, fetch and encode DTOs — never copy the SQLite file, whose WAL may hold
///   unflushed data.
/// - `nonisolated` everywhere: under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` these types
///   would otherwise be main-actor isolated and could not be `Sendable`.
/// - `inProgressSince` is deliberately NOT backed up. It is transient UI state (PLAN.md 3.4
///   and 3.15): restoring it would resurrect a half-finished set on a fresh install.
/// - `nameKey` and `muscleSearchText` are NOT backed up either: they are denormalised columns
///   derived from `name` / `muscleTags` and are rebuilt by `Exercise.setName(_:)` and
///   `Exercise.setTags(_:)` on import (PLAN.md pitfall 10 and 28).
/// - `lastPerformedAt` IS written (it is the queue sort key, PLAN.md pitfall 1) but the
///   importer recomputes it from the entries anyway, so a hand-edited file cannot corrupt
///   the queue order.
///
/// `formatVersion` is the file format, not the SwiftData schema version (`WOQSchemaV3`).
/// Bump it only when this JSON shape changes incompatibly, and keep a reader for the old
/// value; adding an optional field does not need a bump — which is why schema V2
/// (`executionID` / `setIndex`) and schema V3 (`notes` on both records, `equipment` on the
/// exercise, 2026-09-12) both left it at 1: every added key is optional, an old file decodes
/// with nils and an older build ignores the keys it does not know.
nonisolated struct BackupDocument: Codable, Sendable, Equatable {

    /// Version of this JSON layout. 1 = the shape below.
    var formatVersion: Int = 1
    /// Marketing version + build of the app that wrote the file, for support ("1.0 (1)").
    var appVersion: String
    /// When the file was written.
    var exportedAt: Date
    /// Every exercise, oldest `createdAt` first.
    var exercises: [ExerciseRecord]

    init(
        formatVersion: Int = 1,
        appVersion: String = BackupDocument.currentAppVersion(),
        exportedAt: Date = .now,
        exercises: [ExerciseRecord]
    ) {
        self.formatVersion = formatVersion
        self.appVersion = appVersion
        self.exportedAt = exportedAt
        self.exercises = exercises
    }

    /// Total number of sets in the document; handy for a UI summary.
    var entryCount: Int {
        exercises.reduce(0) { $0 + $1.entries.count }
    }

    // MARK: - File names

    /// The always-current backup. Overwritten on every run; this is the file the importer reads.
    static let fileName = "woq-backup.json"

    /// Prefix shared by the dated snapshots, including the separating dash so that
    /// `woq-backup.json` itself never looks like a snapshot.
    static let snapshotPrefix = "woq-backup-"
    static let fileExtension = "json"

    /// `woq-backup-2026-09-05.json` for the day `date` falls on in `calendar`.
    ///
    /// Built from `DateComponents` with `String(format:)` rather than a `DateFormatter`:
    /// a formatter is not `Sendable` (so it cannot be a shared `static let` under strict
    /// concurrency) and a device locale could otherwise produce non-Gregorian digits.
    static func snapshotFileName(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%@%04d-%02d-%02d.%@",
            snapshotPrefix,
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0,
            fileExtension
        )
    }

    /// Inverse of `snapshotFileName(for:)`: the local midnight of the day encoded in a
    /// snapshot file name, or nil when the name is not a WOQ snapshot. Anything that
    /// returns nil here is left alone by the rotation in `BackupWriter`, so unrelated
    /// files in the chosen folder are never deleted.
    static func snapshotDate(fromFileName name: String, calendar: Calendar = .current) -> Date? {
        guard name.hasPrefix(snapshotPrefix), name.hasSuffix("." + fileExtension) else { return nil }
        let stamp = name.dropFirst(snapshotPrefix.count).dropLast(fileExtension.count + 1)
        let parts = stamp.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }

    // MARK: - JSON

    /// `.iso8601` dates (stable across locales and time zones), `.sortedKeys` so an unchanged
    /// store produces a byte-identical file, `.prettyPrinted` so the backup stays readable and
    /// diffable in the Files app.
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return encoder
    }

    /// Matching decoder; `.iso8601` must mirror the encoder or every date fails to parse.
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - App version

    /// "1.0 (1)" from the bundle, or "unknown" outside an app bundle (previews, scripts).
    static func currentAppVersion() -> String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String
        let build = info?["CFBundleVersion"] as? String
        switch (short, build) {
        case let (short?, build?): return "\(short) (\(build))"
        case let (short?, nil): return short
        default: return "unknown"
        }
    }
}

/// One exercise and its history inside a `BackupDocument`.
///
/// `id` is the `Exercise.id` UUID and is the primary key on import: the same file merged
/// twice updates the same rows instead of duplicating them.
///
/// `notes` / `equipment` (schema V3, 2026-09-12) are optional, so a file written before they
/// existed decodes with nils — synthesized `Codable` reads a missing key for an `Optional`
/// as nil, which is what keeps `formatVersion` at 1.
nonisolated struct ExerciseRecord: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var isUnilateral: Bool
    var muscleTags: [MuscleTag]
    var createdAt: Date
    /// Free-form note about the exercise, nil when there is none. Never the empty string:
    /// the writer passes `Exercise.notes`, already normalised by `Exercise.cleanedNotes(_:)`,
    /// so "no note" is one value in the file as well as in the store.
    var notes: String?
    /// `Equipment.rawValue` ("barbell", "cable", …), nil when the exercise has no tag.
    /// The raw string, deliberately not the enum: a value written by a build with more cases
    /// must survive the round trip untouched instead of decoding as nil (Equipment.swift).
    var equipment: String?
    /// Denormalised queue sort key; recomputed from `entries` on import.
    var lastPerformedAt: Date?
    /// Sets, oldest first.
    var entries: [EntryRecord]

    init(
        id: UUID,
        name: String,
        isUnilateral: Bool,
        muscleTags: [MuscleTag],
        createdAt: Date,
        notes: String? = nil,
        equipment: String? = nil,
        lastPerformedAt: Date?,
        entries: [EntryRecord]
    ) {
        self.id = id
        self.name = name
        self.isUnilateral = isUnilateral
        self.muscleTags = muscleTags
        self.createdAt = createdAt
        self.notes = notes
        self.equipment = equipment
        self.lastPerformedAt = lastPerformedAt
        self.entries = entries
    }
}

/// One finalized set inside a `BackupDocument`. Mirrors `Entry` exactly (PLAN.md section 5):
/// `weightHalfKilos` is integer half-kilos with nil = bodyweight, and for a unilateral
/// exercise `reps` is the LEFT side while `repsRight` holds the right one.
///
/// `executionID` / `setIndex` (schema V2, PLAN.md "Multi-set executions" 2026-09-12) are
/// optional so that a backup written before they existed still decodes: a set without them
/// is its own one-set execution, exactly as `Entry.executionKey` decides in the store. Adding
/// optional fields is compatible in both directions, so `formatVersion` stays 1 — an older
/// build simply ignores the two keys.
/// The writer always fills them in (it writes the *resolved* `Entry.executionKey`, never the
/// raw optional), so every file written from now on groups correctly even when it is restored
/// onto a fresh install.
///
/// `notes` (schema V3, 2026-09-12) follows the same rule: optional, absent in every older
/// file, nil when the set carries no note — never the empty string.
nonisolated struct EntryRecord: Codable, Sendable, Equatable, Identifiable {
    var id: UUID
    var date: Date
    var weightHalfKilos: Int?
    var reps: Int
    var repsRight: Int?
    /// Key shared by the sets of one execution; nil only in files written before V2.
    var executionID: UUID?
    /// Position inside the execution; nil only in files written before V2 (read as 0).
    var setIndex: Int?
    /// Free-form note on this set, nil when there is none (normalised by `Entry.setNotes`).
    var notes: String?

    init(
        id: UUID,
        date: Date,
        weightHalfKilos: Int?,
        reps: Int,
        repsRight: Int?,
        executionID: UUID? = nil,
        setIndex: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weightHalfKilos = weightHalfKilos
        self.reps = reps
        self.repsRight = repsRight
        self.executionID = executionID
        self.setIndex = setIndex
        self.notes = notes
    }
}
