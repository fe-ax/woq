import Foundation
import SwiftData
import Testing

@testable import WOQ

// Shared scaffolding for the WOQ test bundle (first tests, 2026-09-12).
//
// Everything here is main-actor isolated on purpose: `@Model` classes live on the main actor
// and are not `Sendable` (PLAN.md pitfall 13 and 25), and the test target builds with the
// app's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so a plain `@Test` function is
// main-actor isolated too and can touch models directly.
//
// Every test builds its OWN container: SwiftData stores are stateful and Swift Testing runs
// tests in parallel, so nothing may be shared between them.

/// A fresh in-memory store with the CURRENT schema.
///
/// `Schema([Exercise.self, Entry.self])` deliberately uses the typealiases rather than
/// `WOQSchemaV2` — they always point at the current version (WOQ/Model/Schema.swift), so this
/// helper follows a future V3 without being touched. No migration plan: an empty in-memory
/// store has nothing to migrate.
@MainActor
func makeContainer() throws -> ModelContainer {
    let schema = Schema([Exercise.self, Entry.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: configuration)
}

/// A fresh store plus the `QueueStore` that owns every mutation of it (PLAN.md 3.2).
///
/// The container is returned as well and must be kept alive by the test: dropping it takes
/// the `mainContext` — and every model fetched from it — with it.
@MainActor
func makeStore() throws -> (ModelContainer, QueueStore) {
    let container = try makeContainer()
    return (container, QueueStore(modelContext: container.mainContext))
}

/// Fixture helpers. Namespaced so `@testable import WOQ` keeps the app's symbols unshadowed.
@MainActor
enum Fixture {

    /// A fixed instant with NO fractional part, so dates survive the backup's whole-second
    /// ISO8601 round trip unchanged (CLAUDE.md 8). Tests never use `.now`: a wall clock makes
    /// ordering assertions flaky.
    static let epoch = Date(timeIntervalSinceReferenceDate: 800_000_000)

    /// `epoch` shifted by whole days (and optionally seconds) — still whole seconds.
    static func date(day: Int, second: Int = 0) -> Date {
        epoch.addingTimeInterval(TimeInterval(day * 86_400 + second))
    }

    /// Inserts an exercise straight into the context (no `QueueStore` side effects), for tests
    /// that need a specific `createdAt` or a queue built by hand.
    @discardableResult
    static func exercise(
        _ name: String,
        in context: ModelContext,
        isUnilateral: Bool = false,
        tags: [MuscleTag] = [],
        createdAt: Date = Fixture.epoch,
        lastPerformedAt: Date? = nil
    ) -> Exercise {
        let exercise = Exercise(name: name, isUnilateral: isUnilateral, tags: tags, createdAt: createdAt)
        context.insert(exercise)
        exercise.lastPerformedAt = lastPerformedAt
        return exercise
    }

    /// Inserts one set and attaches it to `exercise`. `lastPerformedAt` is NOT touched — only
    /// `QueueStore` maintains that column (PLAN.md pitfall 1), so a test that wants it right
    /// either goes through the store or sets it itself.
    @discardableResult
    static func entry(
        in context: ModelContext,
        of exercise: Exercise? = nil,
        date: Date = Fixture.epoch,
        weightHalfKilos: Int? = nil,
        reps: Int,
        repsRight: Int? = nil,
        executionID: UUID? = nil,
        setIndex: Int = 0
    ) -> Entry {
        let entry = Entry(
            date: date,
            weightHalfKilos: weightHalfKilos,
            reps: reps,
            repsRight: repsRight,
            executionID: executionID,
            setIndex: setIndex
        )
        context.insert(entry)
        if let exercise { entry.exercise = exercise }
        return entry
    }

    /// A validated set, bypassing the draft strings.
    static func set(_ weightHalfKilos: Int?, _ reps: Int, right repsRight: Int? = nil) -> ValidatedSet {
        ValidatedSet(weightHalfKilos: weightHalfKilos, reps: reps, repsRight: repsRight)
    }

    /// A pending set (what the card's plus button produces) with a fixed log time.
    static func pending(
        _ weightHalfKilos: Int?,
        _ reps: Int,
        right repsRight: Int? = nil,
        at loggedAt: Date
    ) -> PendingSet {
        PendingSet(set: set(weightHalfKilos, reps, right: repsRight), loggedAt: loggedAt)
    }

    /// A preset for `QueueStore.addExercises(_:)`; the muscle tag is irrelevant to the batch
    /// rules, so one primary tag keeps the fixtures short.
    static func preset(_ name: String, isUnilateral: Bool = false) -> ExercisePreset {
        ExercisePreset(
            name: name,
            category: .back,
            isUnilateral: isUnilateral,
            tags: [MuscleTag(muscle: .lats, intensity: .primary)]
        )
    }

    /// The exercises of `store` in queue order, straight from a fetch with
    /// `QueueStore.sortDescriptors` (the descriptors `@Query` uses on the main screen).
    static func fetchQueue(_ store: QueueStore) throws -> [Exercise] {
        try store.modelContext.fetch(FetchDescriptor<Exercise>(sortBy: QueueStore.sortDescriptors))
    }
}
