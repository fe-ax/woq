import Foundation
import SwiftData
import Testing

@testable import WOQ

/// Queue order (PLAN.md 3.1 and pitfall 30): `lastPerformedAt` ascending with nil FIRST
/// (never performed = longest ago), tie-break `createdAt` ascending, then name — in memory
/// through `QueueStore.ordered(_:)` and in SQLite through `QueueStore.sortDescriptors`.
/// Plus the batch rule for preset adds (PLAN.md section 2 "New exercise").
@Suite("Queue ordering")
struct QueueOrderingTests {

    // MARK: - ordered(_:)

    @Test("never performed sorts first")
    func neverPerformedFirst() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let performed = Fixture.exercise(
            "Bench press", in: context,
            createdAt: Fixture.date(day: 0), lastPerformedAt: Fixture.date(day: 1)
        )
        let never = Fixture.exercise("Squat", in: context, createdAt: Fixture.date(day: 9))

        #expect(QueueStore.ordered([performed, never]).map(\.name) == ["Squat", "Bench press"])
    }

    @Test("performed exercises sort by last performed date ascending")
    func oldestPerformedFirst() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let recent = Fixture.exercise(
            "Row", in: context, createdAt: Fixture.date(day: 0), lastPerformedAt: Fixture.date(day: 8)
        )
        let ancient = Fixture.exercise(
            "Curl", in: context, createdAt: Fixture.date(day: 0), lastPerformedAt: Fixture.date(day: 2)
        )
        let middle = Fixture.exercise(
            "Dip", in: context, createdAt: Fixture.date(day: 0), lastPerformedAt: Fixture.date(day: 5)
        )

        #expect(QueueStore.ordered([recent, ancient, middle]).map(\.name) == ["Curl", "Dip", "Row"])
    }

    @Test("an equal last performed date breaks on createdAt")
    func tieBreaksOnCreatedAt() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let sameDay = Fixture.date(day: 4)
        let younger = Fixture.exercise(
            "Aardvark", in: context, createdAt: Fixture.date(day: 3), lastPerformedAt: sameDay
        )
        let older = Fixture.exercise(
            "Zebra", in: context, createdAt: Fixture.date(day: 1), lastPerformedAt: sameDay
        )

        // createdAt wins over the alphabet.
        #expect(QueueStore.ordered([younger, older]).map(\.name) == ["Zebra", "Aardvark"])
    }

    @Test("an equal createdAt breaks on name")
    func tieBreaksOnName() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let created = Fixture.date(day: 1)
        let zebra = Fixture.exercise("Zebra", in: context, createdAt: created)
        let aardvark = Fixture.exercise("Aardvark", in: context, createdAt: created)

        #expect(QueueStore.ordered([zebra, aardvark]).map(\.name) == ["Aardvark", "Zebra"])
    }

    // MARK: - sortDescriptors (the fetch the screen actually uses)

    @Test("a fetch with the store's sort descriptors puts nil first too")
    func fetchOrderMatches() throws {
        let (container, store) = try makeStore()
        let context = container.mainContext
        Fixture.exercise(
            "Row", in: context, createdAt: Fixture.date(day: 0), lastPerformedAt: Fixture.date(day: 8)
        )
        Fixture.exercise(
            "Curl", in: context, createdAt: Fixture.date(day: 0), lastPerformedAt: Fixture.date(day: 2)
        )
        Fixture.exercise("Squat", in: context, createdAt: Fixture.date(day: 1))
        Fixture.exercise("Plank", in: context, createdAt: Fixture.date(day: 0))
        store.save()

        try #expect(Fixture.fetchQueue(store).map(\.name) == ["Plank", "Squat", "Curl", "Row"])
    }

    // MARK: - finalize moves a row to the bottom

    @Test("finalizing sends the exercise to the bottom of the queue")
    func finalizeSendsToBottom() throws {
        let (container, store) = try makeStore()
        let context = container.mainContext
        let first = Fixture.exercise("Curl", in: context, createdAt: Fixture.date(day: 0))
        Fixture.exercise("Dip", in: context, createdAt: Fixture.date(day: 1))
        Fixture.exercise("Row", in: context, createdAt: Fixture.date(day: 2))
        store.save()
        try #expect(Fixture.fetchQueue(store).map(\.name) == ["Curl", "Dip", "Row"])

        store.finalize(first, with: Fixture.set(80, 10), at: Fixture.date(day: 10))

        let queue = try Fixture.fetchQueue(store)
        #expect(queue.map(\.name) == ["Dip", "Row", "Curl"])
        // The in-memory rule agrees with the fetch.
        #expect(QueueStore.ordered(queue).map(\.name) == ["Dip", "Row", "Curl"])
    }

    // MARK: - Preset batch adds

    @Test("a preset batch queues everything as never performed and starts nothing")
    func batchQueuesNeverPerformed() throws {
        let (container, store) = try makeStore()
        let added = store.addExercises([
            Fixture.preset("Barbell row"),
            Fixture.preset("Lat pulldown"),
        ])

        #expect(added.map(\.name) == ["Barbell row", "Lat pulldown"])
        #expect(added.allSatisfy { $0.lastPerformedAt == nil })
        #expect(added.allSatisfy { $0.inProgressSince == nil })
        #expect(store.inProgressExercise() == nil)
        try #expect(container.mainContext.fetch(FetchDescriptor<Entry>()).isEmpty)
    }

    @Test("a preset batch skips names that are already taken, case-insensitively")
    func batchSkipsTakenNames() throws {
        let (container, store) = try makeStore()
        Fixture.exercise("barbell ROW", in: container.mainContext)
        store.save()

        let added = store.addExercises([
            Fixture.preset("Barbell row"),
            Fixture.preset("Lat pulldown"),
        ])

        #expect(added.map(\.name) == ["Lat pulldown"])
        try #expect(container.mainContext.fetch(FetchDescriptor<Exercise>()).count == 2)
    }

    @Test("a preset batch skips duplicates inside the batch itself")
    func batchSkipsInternalDuplicates() throws {
        let (container, store) = try makeStore()
        let added = store.addExercises([
            Fixture.preset("Barbell row"),
            Fixture.preset("BARBELL ROW"),
            Fixture.preset("  barbell row  "),
        ])

        #expect(added.count == 1)
        try #expect(container.mainContext.fetch(FetchDescriptor<Exercise>()).count == 1)
    }

    @Test("a batch of only known names inserts nothing")
    func batchOfKnownNamesInsertsNothing() throws {
        let (container, store) = try makeStore()
        Fixture.exercise("Barbell row", in: container.mainContext)
        store.save()

        #expect(store.addExercises([Fixture.preset("Barbell row")]).isEmpty)
        try #expect(container.mainContext.fetch(FetchDescriptor<Exercise>()).count == 1)
    }

    @Test("a preset batch never starts anything, not even with the queue at rest")
    func batchNeverStarts() throws {
        let (container, store) = try makeStore()
        _ = container
        store.addExercises([Fixture.preset("Barbell row")])

        #expect(store.inProgressExercise() == nil)
    }

    @Test("a preset carries its unilateral flag and tags")
    func batchCarriesPresetData() throws {
        let (container, store) = try makeStore()
        _ = container
        let added = store.addExercises([Fixture.preset("Single-arm row", isUnilateral: true)])
        let exercise = try #require(added.first)

        #expect(exercise.isUnilateral)
        #expect(exercise.muscleTags == [MuscleTag(muscle: .lats, intensity: .primary)])
        // The denormalised search column is filled by the initializer (PLAN.md pitfall 28).
        #expect(exercise.muscleSearchText.contains("lats"))
    }
}
