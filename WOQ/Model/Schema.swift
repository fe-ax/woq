import Foundation
import SwiftData

/// Version 1 of the WOQ store schema — the shape that shipped first.
///
/// The model classes themselves live in `Exercise.swift` and `Entry.swift` as
/// `extension WOQSchemaV1 { @Model nonisolated final class … }`, the way Apple nests them in
/// WWDC23 "Model your schema with SwiftData". File-scope `typealias Exercise = WOQSchemaV1.Exercise`
/// and `typealias Entry = WOQSchemaV1.Entry` keep every call site in the app writing plain
/// `Exercise` / `Entry`, so only this namespace ever mentions a version.
///
/// The persisted entity names stay `"Exercise"` and `"Entry"` (SwiftData uses the unqualified
/// type name), and no property, attribute, relationship or default changed when the classes moved
/// in here — so a store written by the previous unversioned build opens with no migration at all.
/// Verified on the simulator: seeded with the committed build, then opened with this one; the queue
/// was unchanged and the log contained neither "model container failed" nor "rebuilt after deleting".
///
/// ## How to add V2 later (PLAN.md pitfall 12, docs/swiftui-swiftdata.md 1g)
/// 1. Add `nonisolated enum WOQSchemaV2: VersionedSchema` with `Schema.Version(2, 0, 0)`.
/// 2. **Copy** the model classes into `extension WOQSchemaV2 { … }` — do not edit the V1 copies,
///    ever. V1 must keep describing the old store byte for byte or the migration has nothing to
///    read. Make the change (new property, renamed property, new type) in the V2 copies only.
/// 3. Add the stage to `WOQMigrationPlan.stages`:
///    - `.lightweight(fromVersion: WOQSchemaV1.self, toVersion: WOQSchemaV2.self)` for anything
///      SwiftData can infer: added properties that are optional or have an inline default
///      (PLAN.md pitfall 27), deleted properties, a renamed model or property that is matched by
///      `@Attribute(originalName:)`.
///    - `.custom(fromVersion:toVersion:willMigrate:didMigrate:)` when values must be computed —
///      e.g. filling a new denormalised column, splitting a field, or de-duplicating rows.
///      `willMigrate` sees the old shape, `didMigrate` the new one; both get a `ModelContext`
///      and must `save()`.
/// 4. Point the typealiases at the new version (`typealias Exercise = WOQSchemaV2.Exercise`) and
///    move them next to the V2 classes; `WOQApp.makeContainer()` switches to
///    `Schema(versionedSchema: WOQSchemaV2.self)`. `schemas` lists every version, oldest first.
///
/// ### Pitfall: "Duplicate version checksums across stages detected"
/// SwiftData fingerprints each `VersionedSchema` by its contents, not by its version identifier.
/// If V2 is a copy of V1 with **no real model change** (or a change SwiftData already handles
/// automatically, so the entity description is identical), both versions hash to the same checksum
/// and building the container traps with *"Duplicate version checksums across stages detected"*.
/// So: bump the version only together with an actual schema change, and while merely iterating in
/// development keep giving new properties defaults / optionals and delete the simulator store
/// instead of inventing a version (docs/swiftui-swiftdata.md 1g, PLAN.md pitfall 12).
nonisolated enum WOQSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Exercise.self, Entry.self]
    }
}

/// The migration plan handed to `ModelContainer`. One version, so no stages yet.
///
/// `stages` must contain exactly one stage per hop between neighbouring entries of `schemas`;
/// with a single schema the list is empty and SwiftData just opens the store. See the
/// step-by-step note on `WOQSchemaV1` before adding a version.
nonisolated enum WOQMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WOQSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
