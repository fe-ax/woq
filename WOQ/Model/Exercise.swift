import Foundation
import SwiftData

extension WOQSchemaV1 {

    /// One exercise in the queue.
    ///
    /// Ordering rule (PLAN.md 3.1): `lastPerformedAt` ascending with nil FIRST, then
    /// `createdAt` ascending, then `name`. `lastPerformedAt` is denormalised on purpose
    /// (PLAN.md pitfall 1) — an aggregate over `entries` cannot be used as a `@Query` sort key.
    ///
    /// Mutation rule (PLAN.md pitfall 2 and 13): `QueueStore` is the ONLY type that mutates
    /// an `Exercise`. Views read; they never assign `inProgressSince` or `lastPerformedAt`.
    /// `setName(_:)` and `setTags(_:)` are the single place where the denormalised
    /// `nameKey` / `muscleSearchText` are kept in sync — `QueueStore` always goes through them.
    ///
    /// Explicit `nonisolated` on the class per PLAN.md pitfall 25 (Apple DTS recommendation
    /// under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
    /// Every stored property has an inline default or is optional (PLAN.md pitfall 27), so
    /// adding one later still opens an existing store with lightweight migration.
    ///
    /// Nested in `WOQSchemaV1` so a future version can hold its own copy (PLAN.md pitfall 12).
    /// The persisted entity name is still `"Exercise"`, so this is not a schema change.
    /// **Never edit this class once V2 exists** — copy it into `WOQSchemaV2` and change that copy.
    @Model nonisolated final class Exercise {
        @Attribute(.unique) var id: UUID = UUID()

        /// Display name as typed by the user (trimmed).
        private(set) var name: String = ""
        /// Lowercased, whitespace-trimmed `name`. Duplicate checks and text search use this
        /// (PLAN.md pitfall 10 and 28: `#Predicate`'s `contains` is case-sensitive).
        private(set) var nameKey: String = ""

        var isUnilateral: Bool = false

        /// Muscle tags, stored as a Codable blob. Not queryable — that is what
        /// `muscleSearchText` is for (PLAN.md pitfall 28).
        private(set) var muscleTags: [MuscleTag] = []
        /// Denormalised lowercased muscle display names ("chest front delts triceps") so text
        /// search can match muscles with `localizedStandardContains`.
        private(set) var muscleSearchText: String = ""

        var createdAt: Date = Date.now

        /// Date of the most recent entry, or nil when never performed. Written by `QueueStore` only.
        var lastPerformedAt: Date?
        /// Non-nil while this exercise is the single in-progress one. Written by `QueueStore` only.
        var inProgressSince: Date?

        @Relationship(deleteRule: .cascade, inverse: \Entry.exercise)
        var entries: [Entry] = []

        /// `@MainActor` because `Muscle.searchText(for:)` (declared in an unowned extension in
        /// Muscle.swift) is main-actor isolated under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
        /// Models are only ever created and edited on the main actor anyway (PLAN.md pitfall 13).
        @MainActor
        init(
            name: String,
            isUnilateral: Bool = false,
            tags: [MuscleTag] = [],
            createdAt: Date = .now
        ) {
            self.id = UUID()
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.nameKey = Exercise.nameKey(for: name)
            self.isUnilateral = isUnilateral
            self.muscleTags = tags
            self.muscleSearchText = Muscle.searchText(for: tags)
            self.createdAt = createdAt
            self.lastPerformedAt = nil
            self.inProgressSince = nil
            self.entries = []
        }

        // MARK: - Derived state (never persisted, never usable in a #Predicate)

        /// True while this is the one in-progress exercise.
        var isInProgress: Bool { inProgressSince != nil }

        /// The most recent entry by date, or nil when never performed.
        var lastEntry: Entry? {
            entries.max { $0.date < $1.date }
        }

        // MARK: - Keyed mutation (QueueStore is the only caller)

        /// Sets `name` and keeps `nameKey` in sync.
        @MainActor
        func setName(_ newName: String) {
            name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            nameKey = Exercise.nameKey(for: newName)
        }

        /// Sets `muscleTags` and keeps `muscleSearchText` in sync.
        @MainActor
        func setTags(_ newTags: [MuscleTag]) {
            muscleTags = newTags
            muscleSearchText = Muscle.searchText(for: newTags)
        }

        /// Lowercased, whitespace-trimmed key used for duplicate checks and search.
        static func nameKey(for name: String) -> String {
            name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

extension WOQSchemaV2 {

    /// One exercise in the queue — V2 copy (PLAN.md "Multi-set executions", 2026-09-12).
    ///
    /// Stored shape is identical to `WOQSchemaV1.Exercise`; only the relationship now points at
    /// the V2 `Entry` (which carries `executionID` / `setIndex`). What changed is derived
    /// state: `lastEntry` is gone, because "the last thing I did" is an *execution* of 1..N
    /// sets, not a single set. `executions` groups the entries in memory and `lastExecution`
    /// is what the queue row, the in-progress card and the prefill read.
    ///
    /// Ordering rule (PLAN.md 3.1): `lastPerformedAt` ascending with nil FIRST, then
    /// `createdAt` ascending, then `name`. `lastPerformedAt` is denormalised on purpose
    /// (PLAN.md pitfall 1) — an aggregate over `entries` cannot be used as a `@Query` sort key.
    ///
    /// Mutation rule (PLAN.md pitfall 2 and 13): `QueueStore` is the ONLY type that mutates
    /// an `Exercise`. Views read; they never assign `inProgressSince` or `lastPerformedAt`.
    /// `setName(_:)` and `setTags(_:)` are the single place where the denormalised
    /// `nameKey` / `muscleSearchText` are kept in sync — `QueueStore` always goes through them.
    ///
    /// Explicit `nonisolated` on the class per PLAN.md pitfall 25 (Apple DTS recommendation
    /// under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
    /// Every stored property has an inline default or is optional (PLAN.md pitfall 27), so
    /// adding one later still opens an existing store with lightweight migration.
    ///
    /// **Frozen since V3 exists (2026-09-12)** — never edit; the V3 copy below is the live class.
    @Model nonisolated final class Exercise {
        @Attribute(.unique) var id: UUID = UUID()

        /// Display name as typed by the user (trimmed).
        private(set) var name: String = ""
        /// Lowercased, whitespace-trimmed `name`. Duplicate checks and text search use this
        /// (PLAN.md pitfall 10 and 28: `#Predicate`'s `contains` is case-sensitive).
        private(set) var nameKey: String = ""

        var isUnilateral: Bool = false

        /// Muscle tags, stored as a Codable blob. Not queryable — that is what
        /// `muscleSearchText` is for (PLAN.md pitfall 28).
        private(set) var muscleTags: [MuscleTag] = []
        /// Denormalised lowercased muscle display names ("chest front delts triceps") so text
        /// search can match muscles with `localizedStandardContains`.
        private(set) var muscleSearchText: String = ""

        var createdAt: Date = Date.now

        /// Date of the most recent entry, or nil when never performed. Written by `QueueStore` only.
        var lastPerformedAt: Date?
        /// Non-nil while this exercise is the single in-progress one. Written by `QueueStore` only.
        var inProgressSince: Date?

        /// The version is spelled out: inside this extension `Entry` would resolve to
        /// `WOQSchemaV2.Entry` anyway, but a relationship that silently pointed at the wrong
        /// version's class would only show up as a migration failure on a real store.
        @Relationship(deleteRule: .cascade, inverse: \WOQSchemaV2.Entry.exercise)
        var entries: [Entry] = []

        /// `@MainActor` because `Muscle.searchText(for:)` (declared in an unowned extension in
        /// Muscle.swift) is main-actor isolated under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
        /// Models are only ever created and edited on the main actor anyway (PLAN.md pitfall 13).
        @MainActor
        init(
            name: String,
            isUnilateral: Bool = false,
            tags: [MuscleTag] = [],
            createdAt: Date = .now
        ) {
            self.id = UUID()
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.nameKey = Exercise.nameKey(for: name)
            self.isUnilateral = isUnilateral
            self.muscleTags = tags
            self.muscleSearchText = Muscle.searchText(for: tags)
            self.createdAt = createdAt
            self.lastPerformedAt = nil
            self.inProgressSince = nil
            self.entries = []
        }

        // MARK: - Derived state (never persisted, never usable in a #Predicate)

        /// True while this is the one in-progress exercise.
        var isInProgress: Bool { inProgressSince != nil }

        /// `executions` / `lastExecution` live on the live (V3) copy only: they are built on
        /// `Execution`, a read model over the CURRENT `Entry`, and a frozen version must not
        /// depend on the live types. Computed properties are not part of the stored shape, so
        /// dropping them here does not change what this version describes.

        // MARK: - Keyed mutation (QueueStore is the only caller)

        /// Sets `name` and keeps `nameKey` in sync.
        @MainActor
        func setName(_ newName: String) {
            name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            nameKey = Exercise.nameKey(for: newName)
        }

        /// Sets `muscleTags` and keeps `muscleSearchText` in sync.
        @MainActor
        func setTags(_ newTags: [MuscleTag]) {
            muscleTags = newTags
            muscleSearchText = Muscle.searchText(for: newTags)
        }

        /// Lowercased, whitespace-trimmed key used for duplicate checks and search.
        static func nameKey(for name: String) -> String {
            name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}

/// `Exercise` everywhere in the app means the current schema version's model class.
/// Only Schema.swift and this file mention a version; every call site writes `Exercise`.
/// When V4 arrives, repoint this alias and move it next to the V4 class
/// (see the note on `WOQSchemaV3`).
typealias Exercise = WOQSchemaV3.Exercise

extension WOQSchemaV3 {

    /// One exercise in the queue — V3 copy (notes + equipment, decided 2026-09-12).
    ///
    /// Stored shape is `WOQSchemaV2.Exercise` plus two optional columns, `notes` and
    /// `equipmentRawValue`; both optional, so the V2 -> V3 hop is a lightweight stage. The rest
    /// is a verbatim copy — the ordering, mutation and denormalisation rules documented on the
    /// V2 class apply unchanged, and `QueueStore` is still the only mutator.
    ///
    /// **Never edit this class once V4 exists** — copy it into `WOQSchemaV4` and change that copy.
    @Model nonisolated final class Exercise {
        @Attribute(.unique) var id: UUID = UUID()

        /// Display name as typed by the user (trimmed).
        private(set) var name: String = ""
        /// Lowercased, whitespace-trimmed `name`. Duplicate checks and text search use this
        /// (PLAN.md pitfall 10 and 28: `#Predicate`'s `contains` is case-sensitive).
        private(set) var nameKey: String = ""

        var isUnilateral: Bool = false

        /// Muscle tags, stored as a Codable blob. Not queryable — that is what
        /// `muscleSearchText` is for (PLAN.md pitfall 28).
        private(set) var muscleTags: [MuscleTag] = []
        /// Denormalised lowercased muscle display names ("chest front delts triceps") so text
        /// search can match muscles with `localizedStandardContains`.
        private(set) var muscleSearchText: String = ""

        var createdAt: Date = Date.now

        /// Date of the most recent entry, or nil when never performed. Written by `QueueStore` only.
        var lastPerformedAt: Date?
        /// Non-nil while this exercise is the single in-progress one. Written by `QueueStore` only.
        var inProgressSince: Date?

        /// Free-form note about the exercise (setup, cues). nil or empty = none. V3.
        var notes: String?
        /// `Equipment.rawValue`, nil = not set. V3. Read and written through `equipment`.
        var equipmentRawValue: String?

        /// The version is spelled out: inside this extension `Entry` would resolve to
        /// `WOQSchemaV3.Entry` anyway, but a relationship that silently pointed at the wrong
        /// version's class would only show up as a migration failure on a real store.
        @Relationship(deleteRule: .cascade, inverse: \WOQSchemaV3.Entry.exercise)
        var entries: [Entry] = []

        /// `@MainActor` because `Muscle.searchText(for:)` (declared in an unowned extension in
        /// Muscle.swift) is main-actor isolated under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
        /// Models are only ever created and edited on the main actor anyway (PLAN.md pitfall 13).
        @MainActor
        init(
            name: String,
            isUnilateral: Bool = false,
            tags: [MuscleTag] = [],
            equipment: Equipment? = nil,
            notes: String? = nil,
            createdAt: Date = .now
        ) {
            self.id = UUID()
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            self.nameKey = Exercise.nameKey(for: name)
            self.isUnilateral = isUnilateral
            self.muscleTags = tags
            self.muscleSearchText = Muscle.searchText(for: tags)
            self.createdAt = createdAt
            self.lastPerformedAt = nil
            self.inProgressSince = nil
            self.notes = Exercise.cleanedNotes(notes)
            self.equipmentRawValue = equipment?.rawValue
            self.entries = []
        }

        // MARK: - Derived state (never persisted, never usable in a #Predicate)

        /// True while this is the one in-progress exercise.
        var isInProgress: Bool { inProgressSince != nil }

        /// Every logging event, newest first: the sets grouped by `Entry.executionKey`
        /// (`Execution.group(_:isUnilateral:)`). Sets written before V2 have no `executionID`
        /// and each become a one-set execution, so old history reads exactly as it did.
        ///
        /// Computed on access, over the entries the relationship already materialised — an
        /// exercise carries a handful of sets, and a stored column could not be kept in sync
        /// with per-set edits anyway.
        var executions: [Execution] {
            Execution.group(entries, isUnilateral: isUnilateral)
        }

        /// The most recent execution, or nil when never performed. Its `peak` is the set the
        /// queue row, the card's muted line and the prefill show (PLAN.md "Peak rule").
        var lastExecution: Execution? {
            executions.first
        }

        /// The equipment tag as the enum; nil when unset or when the stored raw value is unknown
        /// (a backup from a newer build). Setting writes the raw value.
        var equipment: Equipment? {
            get { equipmentRawValue.flatMap(Equipment.init(rawValue:)) }
            set { equipmentRawValue = newValue?.rawValue }
        }

        /// Trimmed note, nil when empty — so "no note" is one value, not "" or "  ".
        static func cleanedNotes(_ raw: String?) -> String? {
            guard let raw else { return nil }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        // MARK: - Keyed mutation (QueueStore is the only caller)

        /// Sets `name` and keeps `nameKey` in sync.
        @MainActor
        func setName(_ newName: String) {
            name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            nameKey = Exercise.nameKey(for: newName)
        }

        /// Sets `notes`, normalised through `cleanedNotes`.
        func setNotes(_ newNotes: String?) {
            notes = Exercise.cleanedNotes(newNotes)
        }

        /// Sets `muscleTags` and keeps `muscleSearchText` in sync.
        @MainActor
        func setTags(_ newTags: [MuscleTag]) {
            muscleTags = newTags
            muscleSearchText = Muscle.searchText(for: newTags)
        }

        /// Lowercased, whitespace-trimmed key used for duplicate checks and search.
        static func nameKey(for name: String) -> String {
            name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
}
