import Foundation
import SwiftData
import Testing

@testable import WOQ

/// The restore path: `BackupImporter.merge(_:into:)` (CLAUDE.md 8, PLAN.md pitfall 10/11).
///
/// The merge is additive and idempotent: identity is the UUID, a name collision adopts the
/// existing exercise, nothing is ever deleted, and `lastPerformedAt` is recomputed from the
/// merged sets rather than copied from the file.
@Suite("Backup merge")
struct BackupMergeTests {

    // MARK: - Document fixtures

    /// One entry record with whole-second dates (ISO8601 in the file drops fractions).
    private func entryRecord(
        id: UUID = UUID(),
        day: Int,
        second: Int = 0,
        weightHalfKilos: Int? = 80,
        reps: Int = 10,
        repsRight: Int? = nil,
        executionID: UUID? = nil,
        setIndex: Int? = nil
    ) -> EntryRecord {
        EntryRecord(
            id: id,
            date: Fixture.date(day: day, second: second),
            weightHalfKilos: weightHalfKilos,
            reps: reps,
            repsRight: repsRight,
            executionID: executionID,
            setIndex: setIndex
        )
    }

    private func exerciseRecord(
        id: UUID = UUID(),
        name: String,
        isUnilateral: Bool = false,
        createdAt: Date = Fixture.epoch,
        lastPerformedAt: Date? = nil,
        entries: [EntryRecord]
    ) -> ExerciseRecord {
        ExerciseRecord(
            id: id,
            name: name,
            isUnilateral: isUnilateral,
            muscleTags: [MuscleTag(muscle: .chest, intensity: .primary)],
            createdAt: createdAt,
            lastPerformedAt: lastPerformedAt,
            entries: entries
        )
    }

    private func document(_ exercises: [ExerciseRecord]) -> BackupDocument {
        BackupDocument(appVersion: "test", exportedAt: Fixture.epoch, exercises: exercises)
    }

    // MARK: - Inserting

    @Test("merging into an empty store inserts every exercise and set")
    func insertsEverything() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let record = exerciseRecord(
            name: "Bench press",
            entries: [entryRecord(day: 1, reps: 10), entryRecord(day: 2, reps: 8)]
        )

        let summary = try BackupImporter.merge(document([record]), into: context)

        #expect(summary.exercisesInserted == 1)
        #expect(summary.entriesInserted == 2)
        #expect(summary.exercisesUpdated == 0)
        #expect(!summary.insertedNothing)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let exercise = try #require(exercises.first)
        #expect(exercises.count == 1)
        #expect(exercise.id == record.id)
        #expect(exercise.name == "Bench press")
        #expect(exercise.entries.count == 2)
        // The denormalised columns are rebuilt on import, never read from the file.
        #expect(exercise.nameKey == "bench press")
        #expect(exercise.muscleSearchText.contains("chest"))
    }

    @Test("merging the same file twice changes nothing the second time")
    func mergeIsIdempotent() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let doc = document([
            exerciseRecord(name: "Bench press", entries: [entryRecord(day: 1), entryRecord(day: 2)])
        ])

        try BackupImporter.merge(doc, into: context)
        let second = try BackupImporter.merge(doc, into: context)

        #expect(second.exercisesInserted == 0)
        #expect(second.entriesInserted == 0)
        #expect(second.exercisesUpdated == 1)
        #expect(second.entriesUpdated == 2)
        #expect(second.insertedNothing)
        try #expect(context.fetch(FetchDescriptor<Exercise>()).count == 1)
        try #expect(context.fetch(FetchDescriptor<Entry>()).count == 2)
    }

    // MARK: - Matching

    @Test("an exercise is matched by id even when the file renamed it")
    func matchesExerciseByID() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let existing = Fixture.exercise("Bench press", in: context)
        try context.save()

        let record = exerciseRecord(id: existing.id, name: "Flat bench press", entries: [entryRecord(day: 1)])
        let summary = try BackupImporter.merge(document([record]), into: context)

        #expect(summary.exercisesInserted == 0)
        #expect(summary.exercisesUpdated == 1)
        try #expect(context.fetch(FetchDescriptor<Exercise>()).count == 1)
        #expect(existing.name == "Flat bench press")
        #expect(existing.nameKey == "flat bench press")
        #expect(existing.entries.count == 1)
    }

    @Test("an unknown id with a known name adopts the existing exercise")
    func adoptsSameNameExercise() throws {
        let container = try makeContainer()
        let context = container.mainContext
        // Marco recreated it by hand on a fresh install before importing: same name,
        // different case, different id.
        let existing = Fixture.exercise("bench PRESS", in: context)
        let existingID = existing.id
        try context.save()

        let record = exerciseRecord(name: "Bench press", entries: [entryRecord(day: 1)])
        #expect(record.id != existingID)

        let summary = try BackupImporter.merge(document([record]), into: context)

        #expect(summary.exercisesInserted == 0)
        #expect(summary.exercisesUpdated == 1)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
        // The live id is kept — renumbering the row would orphan its entries.
        #expect(existing.id == existingID)
        #expect(existing.entries.count == 1)
    }

    @Test("a set is matched by id and updated in place")
    func matchesEntryByID() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        let entry = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1), weightHalfKilos: 80, reps: 10
        )
        exercise.lastPerformedAt = Fixture.date(day: 1)
        try context.save()

        let record = exerciseRecord(
            id: exercise.id,
            name: "Bench press",
            entries: [entryRecord(id: entry.id, day: 1, weightHalfKilos: 85, reps: 6)]
        )
        let summary = try BackupImporter.merge(document([record]), into: context)

        #expect(summary.entriesInserted == 0)
        #expect(summary.entriesUpdated == 1)
        try #expect(context.fetch(FetchDescriptor<Entry>()).count == 1)
        #expect(entry.weightHalfKilos == 85)
        #expect(entry.reps == 6)
        #expect(entry.exercise === exercise)
    }

    // MARK: - Never deletes

    @Test("an exercise missing from the file survives the merge")
    func keepsUnmentionedExercise() throws {
        let container = try makeContainer()
        let context = container.mainContext
        Fixture.exercise("Squat", in: context)
        try context.save()

        try BackupImporter.merge(document([exerciseRecord(name: "Bench press", entries: [])]), into: context)

        let names = try context.fetch(FetchDescriptor<Exercise>()).map(\.name).sorted()
        #expect(names == ["Bench press", "Squat"])
    }

    @Test("a set missing from the file survives the merge")
    func keepsUnmentionedEntry() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        let kept = Fixture.entry(in: context, of: exercise, date: Fixture.date(day: 1), reps: 10)
        try context.save()

        let record = exerciseRecord(id: exercise.id, name: "Bench press", entries: [entryRecord(day: 4)])
        try BackupImporter.merge(document([record]), into: context)

        #expect(exercise.entries.count == 2)
        #expect(exercise.entries.contains { $0 === kept })
    }

    // MARK: - Derived columns

    @Test("lastPerformedAt is recomputed from the sets, not taken from the file")
    func recomputesLastPerformedAt() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let record = exerciseRecord(
            name: "Bench press",
            lastPerformedAt: Fixture.date(day: 900),
            entries: [entryRecord(day: 1), entryRecord(day: 3), entryRecord(day: 2)]
        )

        try BackupImporter.merge(document([record]), into: context)

        let exercise = try #require(context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(exercise.lastPerformedAt == Fixture.date(day: 3))
    }

    @Test("a never performed exercise stays never performed")
    func noEntriesNoDate() throws {
        let container = try makeContainer()
        let context = container.mainContext

        try BackupImporter.merge(
            document([exerciseRecord(name: "Bench press", lastPerformedAt: Fixture.date(day: 5), entries: [])]),
            into: context
        )

        let exercise = try #require(context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(exercise.lastPerformedAt == nil)
    }

    // MARK: - Executions

    @Test("executions travel with the sets")
    func carriesExecutionColumns() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let executionID = UUID()
        let record = exerciseRecord(
            name: "Bench press",
            entries: [
                entryRecord(day: 1, reps: 10, executionID: executionID, setIndex: 0),
                entryRecord(day: 1, second: 120, reps: 9, executionID: executionID, setIndex: 1),
            ]
        )

        try BackupImporter.merge(document([record]), into: context)

        let exercise = try #require(context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(exercise.executions.count == 1)
        #expect(exercise.lastExecution?.id == executionID)
        #expect(exercise.lastExecution?.sets.map(\.setIndex) == [0, 1])
    }

    @Test("a pre-V2 record without execution columns becomes its own one-set execution")
    func preV2RecordIsItsOwnExecution() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let first = entryRecord(day: 1, executionID: nil, setIndex: nil)
        let second = entryRecord(day: 2, executionID: nil, setIndex: nil)

        try BackupImporter.merge(
            document([exerciseRecord(name: "Bench press", entries: [first, second])]),
            into: context
        )

        let exercise = try #require(context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(exercise.executions.count == 2)
        #expect(exercise.executions.allSatisfy { $0.setCount == 1 })
        // The importer resolves the key to the set's own id (the `Entry.executionKey` rule).
        #expect(Set(exercise.entries.map(\.executionKey)) == [first.id, second.id])
        #expect(exercise.entries.allSatisfy { $0.setIndex == 0 })
    }

    // MARK: - Round trip through the writer and the JSON coders

    @Test("a written, encoded and decoded backup restores the same store")
    func roundTripThroughJSON() throws {
        let (sourceContainer, store) = try makeStore()
        let sourceContext = sourceContainer.mainContext
        let bench = Fixture.exercise(
            "Bench press", in: sourceContext,
            tags: [MuscleTag(muscle: .chest, intensity: .primary)], createdAt: Fixture.date(day: 0)
        )
        let row = Fixture.exercise(
            "Single-arm row", in: sourceContext, isUnilateral: true, createdAt: Fixture.date(day: 1)
        )
        let squat = Fixture.exercise("Squat", in: sourceContext, createdAt: Fixture.date(day: 2))
        store.finalize(
            bench,
            with: [
                Fixture.pending(80, 10, at: Fixture.date(day: 3)),
                Fixture.pending(80, 9, at: Fixture.date(day: 3, second: 120)),
            ],
            at: Fixture.date(day: 3, second: 200)
        )
        store.finalize(row, with: Fixture.set(45, 12, right: 10), at: Fixture.date(day: 4))

        let written = try BackupWriter.makeDocument(context: sourceContext)
        let data = try BackupDocument.makeEncoder().encode(written)
        let decoded = try BackupDocument.makeDecoder().decode(BackupDocument.self, from: data)
        // Whole-second dates survive ISO8601 unchanged, so the records match byte for byte.
        #expect(decoded.exercises == written.exercises)
        #expect(decoded.entryCount == 3)

        // Restore onto a fresh install.
        let restoredContainer = try makeContainer()
        let restoredContext = restoredContainer.mainContext
        let summary = try BackupImporter.merge(decoded, into: restoredContext)
        #expect(summary.exercisesInserted == 3)
        #expect(summary.entriesInserted == 3)

        let restored = try restoredContext.fetch(
            FetchDescriptor<Exercise>(sortBy: QueueStore.sortDescriptors)
        )
        #expect(restored.map(\.name) == ["Squat", "Bench press", "Single-arm row"])
        #expect(restored.map(\.id) == [squat.id, bench.id, row.id])

        let restoredBench = try #require(restored.first { $0.name == "Bench press" })
        #expect(restoredBench.createdAt == Fixture.date(day: 0))
        #expect(restoredBench.muscleTags == [MuscleTag(muscle: .chest, intensity: .primary)])
        #expect(restoredBench.lastPerformedAt == Fixture.date(day: 3, second: 120))
        #expect(restoredBench.entries.count == 2)
        // One execution of two sets, exactly as it was logged.
        #expect(restoredBench.executions.count == 1)
        #expect(restoredBench.lastExecution?.sets.map(\.reps) == [10, 9])
        #expect(restoredBench.lastExecution?.sets.map(\.date) == [
            Fixture.date(day: 3),
            Fixture.date(day: 3, second: 120),
        ])

        let restoredRow = try #require(restored.first { $0.name == "Single-arm row" })
        #expect(restoredRow.isUnilateral)
        let rowSet = try #require(restoredRow.entries.first)
        #expect(rowSet.weightHalfKilos == 45)
        #expect(rowSet.reps == 12)
        #expect(rowSet.repsRight == 10)
        #expect(rowSet.date == Fixture.date(day: 4))
    }
}
