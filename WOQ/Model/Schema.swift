import Foundation
import SwiftData

/// Version 1 of the WOQ store schema — the shape that shipped first.
///
/// **Frozen.** The model classes still live in `Exercise.swift` and `Entry.swift` as
/// `extension WOQSchemaV1 { @Model nonisolated final class … }` and must keep describing the
/// V1 store byte for byte: a migration reads the old store through this description, so
/// editing it would leave the migration with nothing to read.
///
/// The persisted entity names are `"Exercise"` and `"Entry"` (SwiftData uses the unqualified
/// type name), and nothing changed when the classes moved into this namespace — so a store
/// written by the very first, unversioned build opens as a V1 store with no migration at all.
nonisolated enum WOQSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Exercise.self, Entry.self]
    }
}

/// Version 2 — sets grouped into executions (PLAN.md "Multi-set executions", 2026-09-12).
///
/// One logging event ("start" … checkmark) writes 1..N `Entry` rows that share one
/// `executionID` and carry their position in `setIndex`. `Entry` still means exactly one set,
/// so per-set edit and delete keep working unchanged and the grouping stays a read-time
/// concern (`Execution.group(_:isUnilateral:)`, never a `#Predicate` — see
/// `Entry.executionKey`).
///
/// Both new properties are migration-friendly by construction (PLAN.md pitfall 27):
/// `executionID` is optional (nil on every set written before V2 — such a set is its own
/// one-set execution) and `setIndex` has the inline default `0`. Nothing else changed, so the
/// hop is a `.lightweight` stage and no data is rewritten.
///
/// The V2 model classes live next to the V1 ones in `Exercise.swift` / `Entry.swift`, each in
/// `extension WOQSchemaV2 { … }`, and the file-scope typealiases point here — so every call
/// site in the app keeps writing plain `Exercise` / `Entry` and only this namespace and those
/// two files ever mention a version.
///
/// ## How to add V3 later (PLAN.md pitfall 12, docs/swiftui-swiftdata.md 1g)
/// The V1 -> V2 hop below is the worked example; repeat it exactly.
/// 1. Add `nonisolated enum WOQSchemaV3: VersionedSchema` with `Schema.Version(3, 0, 0)`.
/// 2. **Copy** the model classes into `extension WOQSchemaV3 { … }` — do not edit the V1 or V2
///    copies, ever. Every shipped version must keep describing its own store. Make the change
///    (new property, renamed property, new type) in the V3 copies only.
/// 3. Add the stage to `WOQMigrationPlan.stages`, after the existing one:
///    - `.lightweight(fromVersion: WOQSchemaV2.self, toVersion: WOQSchemaV3.self)` for anything
///      SwiftData can infer: added properties that are optional or have an inline default
///      (PLAN.md pitfall 27), deleted properties, a renamed model or property that is matched by
///      `@Attribute(originalName:)`.
///    - `.custom(fromVersion:toVersion:willMigrate:didMigrate:)` when values must be computed —
///      e.g. filling a new denormalised column, splitting a field, or de-duplicating rows.
///      `willMigrate` sees the old shape, `didMigrate` the new one; both get a `ModelContext`
///      and must `save()`. (V2 deliberately avoided this: an old set resolves its execution key
///      in memory through `Entry.executionKey`, so no rows had to be touched.)
/// 4. Point the typealiases at the new version (`typealias Exercise = WOQSchemaV3.Exercise`) and
///    move them next to the V3 classes; `WOQApp.makeContainer()` switches to
///    `Schema(versionedSchema: WOQSchemaV3.self)`. `schemas` lists every version, oldest first.
///
/// ### Pitfall: "Duplicate version checksums across stages detected"
/// SwiftData fingerprints each `VersionedSchema` by its contents, not by its version identifier.
/// If the new version is a copy with **no real model change** (or a change SwiftData already
/// handles automatically, so the entity description is identical), both versions hash to the
/// same checksum and building the container traps with *"Duplicate version checksums across
/// stages detected"*. So: bump the version only together with an actual schema change, and
/// while merely iterating in development keep giving new properties defaults / optionals and
/// delete the simulator store instead of inventing a version (docs/swiftui-swiftdata.md 1g,
/// PLAN.md pitfall 12).
nonisolated enum WOQSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Exercise.self, Entry.self]
    }
}

/// The migration plan handed to `ModelContainer`.
///
/// `stages` must contain exactly one stage per hop between neighbouring entries of `schemas`:
/// two versions, one stage. The V1 -> V2 hop only adds an optional property and a property
/// with an inline default, which SwiftData infers on its own, so `.lightweight` is enough and
/// no store is rewritten. See the step-by-step note on `WOQSchemaV2` before adding a version.
nonisolated enum WOQMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WOQSchemaV1.self, WOQSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: WOQSchemaV1.self, toVersion: WOQSchemaV2.self)
        ]
    }
}
