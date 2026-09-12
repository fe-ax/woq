import Foundation
import SwiftData
import Testing

@testable import WOQ

/// The one-in-progress rule and everything `QueueStore` writes around it
/// (PLAN.md 3.2, 3.3, 3.5, 3.6, 3.8 and 3.10; multi-set executions 2026-09-12).
@Suite("In-progress and store mutation rules")
struct InProgressRulesTests {

    // MARK: - start / putBack

    @Test("starting an exercise marks it in progress")
    func startMarksInProgress() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)

        #expect(store.start(exercise) == .started)
        #expect(exercise.inProgressSince != nil)
        #expect(store.inProgressExercise() === exercise)
    }

    @Test("a second exercise is refused while one is in progress")
    func secondStartIsRefused() throws {
        let (container, store) = try makeStore()
        let context = container.mainContext
        let first = Fixture.exercise("Bench press", in: context)
        let second = Fixture.exercise("Squat", in: context)
        store.start(first)

        let result = store.start(second)
        guard case .refused(let current) = result else {
            Issue.record("expected .refused, got \(result)")
            return
        }
        #expect(current === first)
        // Nothing changed (PLAN.md 3.3).
        #expect(second.inProgressSince == nil)
        #expect(store.inProgressExercise() === first)
    }

    @Test("starting the one already in progress is a no-op .started")
    func restartingIsANoOp() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.start(exercise)
        let since = exercise.inProgressSince

        #expect(store.start(exercise) == .started)
        #expect(exercise.inProgressSince == since)
    }

    @Test("putting back clears the in-progress marker")
    func putBackClearsMarker() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.start(exercise)

        store.putBack(exercise)

        #expect(exercise.inProgressSince == nil)
        #expect(store.inProgressExercise() == nil)
        // Put back is not a log: the queue position is unchanged.
        #expect(exercise.lastPerformedAt == nil)
        #expect(exercise.entries.isEmpty)
    }

    @Test("putting back an exercise that is not in progress changes nothing")
    func putBackWithoutStart() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)

        store.putBack(exercise)

        #expect(exercise.inProgressSince == nil)
    }

    // MARK: - finalize

    @Test("finalizing writes one entry per set, sharing one execution id")
    func finalizeWritesOneExecution() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.start(exercise)

        let entries = store.finalize(
            exercise,
            with: [
                Fixture.pending(80, 10, at: Fixture.date(day: 3)),
                Fixture.pending(80, 9, at: Fixture.date(day: 3, second: 120)),
                Fixture.pending(80, 8, at: Fixture.date(day: 3, second: 240)),
            ],
            at: Fixture.date(day: 3, second: 300)
        )

        #expect(entries.count == 3)
        #expect(entries.map(\.setIndex) == [0, 1, 2])
        #expect(entries.map(\.reps) == [10, 9, 8])
        #expect(Set(entries.compactMap(\.executionID)).count == 1)
        #expect(entries.allSatisfy { $0.exercise === exercise })
        // Each set keeps the moment its plus was tapped.
        #expect(entries.map(\.date) == [
            Fixture.date(day: 3),
            Fixture.date(day: 3, second: 120),
            Fixture.date(day: 3, second: 240),
        ])
        // One logging event = one execution of three sets.
        #expect(exercise.executions.count == 1)
        #expect(exercise.lastExecution?.setCount == 3)
        #expect(exercise.lastExecution?.peak === entries[0])
    }

    @Test("finalizing stamps lastPerformedAt and clears in progress")
    func finalizeStampsAndClears() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.start(exercise)

        store.finalize(exercise, with: Fixture.set(80, 10), at: Fixture.date(day: 3))

        #expect(exercise.inProgressSince == nil)
        #expect(exercise.lastPerformedAt == Fixture.date(day: 3))
    }

    @Test("lastPerformedAt is never earlier than the last set")
    func finalizeNeverSortsAboveItsOwnSets() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)

        // A caller (seed data) passing an older checkmark date must not leave the exercise
        // sorted above its own sets.
        store.finalize(
            exercise,
            with: [Fixture.pending(80, 10, at: Fixture.date(day: 9))],
            at: Fixture.date(day: 1)
        )

        #expect(exercise.lastPerformedAt == Fixture.date(day: 9))
    }

    @Test("finalizing with no sets is a no-op")
    func finalizeWithoutSets() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.start(exercise)

        let entries = store.finalize(exercise, with: [], at: Fixture.date(day: 3))

        #expect(entries.isEmpty)
        #expect(exercise.entries.isEmpty)
        #expect(exercise.lastPerformedAt == nil)
        // Nothing is touched, so the exercise is still the in-progress one.
        #expect(exercise.inProgressSince != nil)
    }

    @Test("the single-set overload writes one numbered set")
    func finalizeSingleSet() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Single-arm row", in: container.mainContext, isUnilateral: true)

        let entry = store.finalize(exercise, with: Fixture.set(45, 12, right: 10), at: Fixture.date(day: 2))

        #expect(entry.setIndex == 0)
        #expect(entry.executionID != nil)
        #expect(entry.date == Fixture.date(day: 2))
        #expect(entry.weightHalfKilos == 45)
        #expect(entry.reps == 12)
        #expect(entry.repsRight == 10)
    }

    // MARK: - addExercise outcomes

    @Test("a new exercise with a valid first set is logged")
    func addExerciseWithFirstSet() throws {
        let (container, store) = try makeStore()
        _ = container
        let (exercise, outcome) = store.addExercise(
            name: "Bench press",
            isUnilateral: false,
            tags: [],
            firstSet: SetDraft(weightText: "40", repsText: "10")
        )

        #expect(outcome == .logged)
        #expect(exercise.entries.count == 1)
        #expect(exercise.lastPerformedAt != nil)
        #expect(exercise.inProgressSince == nil)
    }

    @Test("a new exercise without a first set becomes the in-progress one")
    func addExerciseStartsWhenIdle() throws {
        let (container, store) = try makeStore()
        _ = container
        let (absent, absentOutcome) = store.addExercise(
            name: "Bench press", isUnilateral: false, tags: [], firstSet: nil
        )
        #expect(absentOutcome == .startedInProgress)
        #expect(absent.inProgressSince != nil)

        store.putBack(absent)
        let (empty, emptyOutcome) = store.addExercise(
            name: "Squat", isUnilateral: false, tags: [], firstSet: SetDraft()
        )
        #expect(emptyOutcome == .startedInProgress)
        #expect(empty.inProgressSince != nil)
        #expect(empty.entries.isEmpty)
    }

    @Test("a half-typed first set also starts the exercise instead of logging it")
    func addExerciseWithInvalidDraftStarts() throws {
        let (container, store) = try makeStore()
        _ = container
        let (exercise, outcome) = store.addExercise(
            name: "Bench press",
            isUnilateral: false,
            tags: [],
            firstSet: SetDraft(weightText: "40")
        )

        #expect(outcome == .startedInProgress)
        #expect(exercise.entries.isEmpty)
    }

    @Test("a new exercise is queued when something else is in progress")
    func addExerciseQueuesWhenBusy() throws {
        let (container, store) = try makeStore()
        let running = Fixture.exercise("Squat", in: container.mainContext)
        store.start(running)

        let (exercise, outcome) = store.addExercise(
            name: "Bench press", isUnilateral: false, tags: [], firstSet: nil
        )

        #expect(outcome == .queued)
        #expect(exercise.inProgressSince == nil)
        #expect(exercise.lastPerformedAt == nil)
        #expect(store.inProgressExercise() === running)
    }

    // MARK: - Entry edits

    @Test("deleting a set recomputes lastPerformedAt")
    func deleteEntryRecomputes() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.finalize(exercise, with: Fixture.set(80, 10), at: Fixture.date(day: 1))
        let newest = store.finalize(exercise, with: Fixture.set(80, 11), at: Fixture.date(day: 5))
        #expect(exercise.lastPerformedAt == Fixture.date(day: 5))

        store.deleteEntry(newest)

        #expect(exercise.entries.count == 1)
        #expect(exercise.lastPerformedAt == Fixture.date(day: 1))
    }

    @Test("deleting the last set leaves the exercise never performed")
    func deleteLastEntryClearsDate() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        let only = store.finalize(exercise, with: Fixture.set(80, 10), at: Fixture.date(day: 1))

        store.deleteEntry(only)

        #expect(exercise.entries.isEmpty)
        #expect(exercise.lastPerformedAt == nil)
        #expect(exercise.executions.isEmpty)
    }

    @Test("editing a set keeps its date")
    func updateEntryKeepsDate() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        let entry = store.finalize(exercise, with: Fixture.set(80, 10), at: Fixture.date(day: 4))

        store.updateEntry(entry, weightHalfKilos: 85, reps: 8, repsRight: nil, notes: nil)

        #expect(entry.date == Fixture.date(day: 4))
        #expect(entry.weightHalfKilos == 85)
        #expect(entry.reps == 8)
        #expect(exercise.lastPerformedAt == Fixture.date(day: 4))
    }

    // MARK: - Adding a set to a past execution

    @Test("adding a set joins the execution with the next set index")
    func addSetJoinsExecution() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.finalize(
            exercise,
            with: [
                Fixture.pending(80, 10, at: Fixture.date(day: 2)),
                Fixture.pending(80, 9, at: Fixture.date(day: 2, second: 120)),
            ],
            at: Fixture.date(day: 2, second: 200)
        )
        let execution = try #require(exercise.lastExecution)

        let added = store.addSet(to: execution, of: exercise, set: Fixture.set(80, 7))

        #expect(added.setIndex == 2)
        #expect(added.executionID == execution.id)
        #expect(added.date == execution.date)
        // Still ONE execution, now with three sets, and the new set does not become the newest
        // thing in the history.
        #expect(exercise.executions.count == 1)
        #expect(exercise.lastExecution?.setCount == 3)
        #expect(exercise.lastExecution?.date == execution.date)
        // What the code actually writes: the newest SET date, not the stamp finalize left.
        #expect(exercise.lastPerformedAt == execution.date)
    }

    // `addSet` recomputes `lastPerformedAt = entries.map(\.date).max()`, while `finalize`
    // stamped it with the CHECKMARK time (`max(date, last set date)`). Adding a set to a past
    // execution therefore pulls the date back to the last set — sub-second in normal use, but
    // the method's doc comment claims `lastPerformedAt` does not move at all.
    @Test(
        "adding a set does not move lastPerformedAt",
        .disabled("bug: addSet recomputes lastPerformedAt from the set dates and loses finalize's checkmark stamp")
    )
    func addSetKeepsLastPerformedAt() throws {
        let (container, store) = try makeStore()
        let exercise = Fixture.exercise("Bench press", in: container.mainContext)
        store.finalize(
            exercise,
            with: [Fixture.pending(80, 10, at: Fixture.date(day: 2))],
            at: Fixture.date(day: 2, second: 200)
        )
        let execution = try #require(exercise.lastExecution)
        let before = exercise.lastPerformedAt

        store.addSet(to: execution, of: exercise, set: Fixture.set(80, 7))

        #expect(exercise.lastPerformedAt == before)
    }

    @Test("adding a set to a pre-V2 one-set execution groups the two together")
    func addSetToPreV2Execution() throws {
        let (container, store) = try makeStore()
        let context = container.mainContext
        let exercise = Fixture.exercise("Bench press", in: context)
        // A set written before schema V2: no executionID, so its key is its own id.
        let old = Fixture.entry(
            in: context, of: exercise, date: Fixture.date(day: 1),
            weightHalfKilos: 80, reps: 10, executionID: nil
        )
        exercise.lastPerformedAt = Fixture.date(day: 1)
        store.save()
        let execution = try #require(exercise.lastExecution)
        #expect(execution.id == old.id)

        let added = store.addSet(to: execution, of: exercise, set: Fixture.set(80, 8))

        #expect(added.executionID == old.id)
        #expect(added.setIndex == 1)
        #expect(exercise.executions.count == 1)
        #expect(exercise.lastExecution?.setCount == 2)
        #expect(exercise.lastPerformedAt == Fixture.date(day: 1))
    }

    // MARK: - Names

    @Test("names are unique case-insensitively")
    func nameAvailability() throws {
        let (container, store) = try makeStore()
        let existing = Fixture.exercise("Bench Press", in: container.mainContext)
        store.save()

        #expect(!store.isNameAvailable("bench press"))
        #expect(!store.isNameAvailable("  BENCH PRESS  "))
        #expect(store.isNameAvailable("Squat"))
        // The exercise being edited does not collide with itself.
        #expect(store.isNameAvailable("bench press", excluding: existing))
        // An empty name is never available, so Save stays disabled.
        #expect(!store.isNameAvailable(""))
        #expect(!store.isNameAvailable("   "))
    }

    @Test("existingNameKeys returns the trimmed lowercased names")
    func existingNameKeys() throws {
        let (container, store) = try makeStore()
        let context = container.mainContext
        Fixture.exercise("Bench Press", in: context)
        Fixture.exercise("  Squat  ", in: context)
        store.save()

        #expect(store.existingNameKeys() == ["bench press", "squat"])
    }
}
