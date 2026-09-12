#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only sample data (PLAN.md section 2 "Seed data", milestone M2). The shipped app
/// starts empty; the UI hides this behind a long-press on the header title.
///
/// Everything goes through `QueueStore`, so the seed cannot break the invariants it owns:
/// `addExercise` creates the exercise, `finalize(_:with:at:)` writes one execution at a time
/// (oldest first, so `lastPerformedAt` ends up on the newest one) and a final `putBack`
/// leaves nothing in progress.
///
/// Since 2026-09-12 the history is execution-shaped (PLAN.md "Multi-set executions"): a
/// sample lists logging events, each holding 1..N sets three minutes apart, so the seeded
/// store exercises the grouping and the peak rule instead of only one-set history.
///
/// Idempotent: names that already exist are skipped, so running it twice changes nothing.
nonisolated enum SeedData {

    /// One sample exercise plus its history.
    nonisolated struct Sample: Sendable {
        var name: String
        var isUnilateral: Bool = false
        var tags: [MuscleTag]
        /// Equipment tag, nil for most samples (schema V3, 2026-09-12).
        var equipment: Equipment?
        /// Exercise note, nil for most samples (schema V3).
        var notes: String?
        /// Logging events, newest first in this table; inserted oldest first.
        var executions: [Execution] = []

        /// One logging event: everything written between "start" and the checkmark.
        /// Deliberately named like the app's `Execution`, but this is just table data —
        /// inside `Sample` the short name always means this type.
        nonisolated struct Execution: Sendable {
            var daysAgo: Int
            /// Sets in the order they were logged; the last one is the checkmark.
            var sets: [Log]

            init(_ daysAgo: Int, sets: [Log]) {
                self.daysAgo = daysAgo
                self.sets = sets
            }
        }

        /// One set inside an execution. Its date comes from the execution, not from here.
        nonisolated struct Log: Sendable {
            /// nil = bodyweight.
            var halfKilos: Int?
            var reps: Int
            var repsRight: Int?
            /// Set note (schema V3), nil for almost every sample set.
            var note: String?

            init(_ halfKilos: Int?, _ reps: Int, _ repsRight: Int? = nil, note: String? = nil) {
                self.halfKilos = halfKilos
                self.reps = reps
                self.repsRight = repsRight
                self.note = note
            }
        }
    }

    @MainActor
    static func insertSamples(using store: QueueStore, context: ModelContext) {
        let known: Set<String> = {
            let all = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
            return Set(all.map(\.nameKey))
        }()

        let calendar = Calendar.current
        let now = Date.now

        for sample in samples {
            guard !known.contains(Exercise.nameKey(for: sample.name)) else { continue }

            let (exercise, _) = store.addExercise(
                name: sample.name,
                isUnilateral: sample.isUnilateral,
                tags: sample.tags,
                equipment: sample.equipment,
                notes: sample.notes,
                firstSet: nil
            )

            for execution in sample.executions.sorted(by: { $0.daysAgo > $1.daysAgo }) {
                let sets = pendingSets(for: execution, calendar: calendar, now: now)
                guard let checkmark = sets.last?.loggedAt else { continue }
                let entries = store.finalize(exercise, with: sets, at: checkmark)

                // A set note is typed afterwards in the detail sheet, never while logging
                // (decided 2026-09-12), so the seed writes it the same way the app does: a
                // second `updateEntry` on a set that already exists, with everything else
                // handed back unchanged. `finalize` returns the entries in set order.
                for (index, log) in execution.sets.enumerated() {
                    guard let note = log.note, index < entries.count else { continue }
                    let entry = entries[index]
                    store.updateEntry(
                        entry,
                        weightHalfKilos: entry.weightHalfKilos,
                        reps: entry.reps,
                        repsRight: entry.repsRight,
                        notes: note
                    )
                }
            }
        }

        // A brand-new exercise with no first set starts in progress; the seed leaves the
        // queue at rest instead (PLAN.md 3.2 keeps at most one in progress either way).
        if let current = store.inProgressExercise() {
            store.putBack(current)
        }
    }

    /// The sets of one sample execution as the card would have committed them: sitting at
    /// 09:00 on their day and three minutes apart, so the sets of one execution keep a
    /// realistic order and the last one is the checkmark time handed to `finalize`.
    private static func pendingSets(
        for execution: Sample.Execution,
        calendar: Calendar,
        now: Date
    ) -> [PendingSet] {
        let day = calendar.date(byAdding: .day, value: -execution.daysAgo, to: now) ?? now
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day

        return execution.sets.enumerated().map { index, log in
            PendingSet(
                set: ValidatedSet(
                    weightHalfKilos: log.halfKilos,
                    reps: log.reps,
                    repsRight: log.repsRight
                ),
                loggedAt: start.addingTimeInterval(Double(index) * 180)
            )
        }
    }

    // MARK: - Table

    private static func tag(_ muscle: Muscle, _ intensity: Intensity) -> MuscleTag {
        MuscleTag(muscle: muscle, intensity: intensity)
    }

    /// 21 exercises: 16 with 1-3 executions spread over the last 60 days, 5 never performed.
    /// Weights are half-kilos (80 == 40 kg); "plank" counts holds as reps, never seconds.
    ///
    /// Five carry an equipment tag (barbell, dumbbell, cable, machine, bodyweight — one of
    /// each, so the chips render in every colour the form can produce), two carry an exercise
    /// note and two sets carry a set note (schema V3, 2026-09-12). Like the names, these
    /// strings are sample DATA, not UI text, so they are plain literals and never go through
    /// `String(localized:)` (same rule as `ExercisePresets`).
    ///
    /// Four of them carry a multi-set latest execution so the queue row, the card line and
    /// the history all show the grouped shape, and each puts the Epley peak somewhere else:
    /// Bench press on set 2 (80 kg \u{00D7} 10 = 106.7 beats the heavier 82.5 kg \u{00D7} 6 = 99.0),
    /// Squat on the last set (85 kg \u{00D7} 8 = 107.7 beats 90 kg \u{00D7} 5 = 105, with the two
    /// identical opening sets resolving to the earlier one), Pull-up on the most reps of three
    /// bodyweight sets, and the unilateral Single-arm dumbbell row on its second set.
    static var samples: [Sample] {
        [
            Sample(
                name: "Bench press",
                tags: [tag(.chest, .primary), tag(.deltoidFront, .secondary), tag(.triceps, .secondary)],
                equipment: .barbell,
                notes: "Feet flat, shoulder blades pinched, bar to the lower chest.",
                executions: [
                    .init(10, sets: [
                        .init(165, 6),
                        .init(160, 10, note: "Best set of the day — try 82.5 next time."),
                        .init(160, 8),
                    ]),
                    .init(24, sets: [.init(170, 8)]),
                    .init(45, sets: [.init(160, 8)]),
                ]
            ),
            Sample(
                name: "Incline dumbbell press",
                tags: [tag(.chest, .primary), tag(.deltoidFront, .secondary), tag(.triceps, .stabiliser)],
                equipment: .dumbbell,
                executions: [
                    .init(17, sets: [.init(64, 10)]),
                    .init(38, sets: [.init(60, 10)]),
                ]
            ),
            Sample(
                name: "Squat",
                tags: [
                    tag(.quads, .primary), tag(.glutes, .primary), tag(.hamstrings, .secondary),
                    tag(.lowerBack, .stabiliser), tag(.abs, .stabiliser),
                ],
                executions: [
                    .init(12, sets: [
                        .init(180, 5),
                        .init(180, 5),
                        .init(170, 8, note: "Depth fine, belt on for the last set."),
                    ]),
                    .init(31, sets: [.init(170, 5)]),
                    .init(52, sets: [.init(160, 5)]),
                ]
            ),
            Sample(
                name: "Deadlift",
                tags: [
                    tag(.hamstrings, .primary), tag(.glutes, .primary), tag(.lowerBack, .primary),
                    tag(.lats, .secondary), tag(.traps, .secondary), tag(.forearms, .stabiliser),
                ],
                executions: [
                    .init(14, sets: [.init(210, 5)]),
                    .init(40, sets: [.init(200, 5)]),
                ]
            ),
            Sample(
                name: "Romanian deadlift",
                tags: [tag(.hamstrings, .primary), tag(.glutes, .secondary), tag(.lowerBack, .secondary)],
                executions: [
                    .init(9, sets: [.init(130, 8)]),
                    .init(33, sets: [.init(120, 8)]),
                ]
            ),
            Sample(
                name: "Barbell row",
                tags: [
                    tag(.upperBack, .primary), tag(.lats, .primary), tag(.biceps, .secondary),
                    tag(.lowerBack, .stabiliser),
                ],
                executions: [
                    .init(6, sets: [.init(125, 8)]),
                    .init(27, sets: [.init(120, 8)]),
                ]
            ),
            Sample(
                name: "Lat pulldown",
                tags: [tag(.lats, .primary), tag(.biceps, .secondary), tag(.upperBack, .secondary)],
                equipment: .cable,
                executions: [
                    .init(5, sets: [.init(115, 10)]),
                    .init(21, sets: [.init(110, 10)]),
                ]
            ),
            Sample(
                name: "Pull-up",
                tags: [
                    tag(.lats, .primary), tag(.biceps, .secondary), tag(.upperBack, .secondary),
                    tag(.abs, .stabiliser),
                ],
                equipment: .bodyweight,
                notes: "Dead hang at the bottom; add a belt once 12 clean reps feel easy.",
                executions: [
                    .init(3, sets: [.init(nil, 8), .init(nil, 11), .init(nil, 9)]),
                    .init(11, sets: [.init(nil, 9)]),
                    .init(30, sets: [.init(nil, 8)]),
                ]
            ),
            Sample(
                name: "Overhead press",
                tags: [
                    tag(.deltoidFront, .primary), tag(.deltoidSide, .secondary),
                    tag(.triceps, .secondary), tag(.abs, .stabiliser),
                ],
                executions: [
                    .init(15, sets: [.init(85, 6)]),
                    .init(36, sets: [.init(80, 6)]),
                ]
            ),
            Sample(
                name: "Lateral raise",
                tags: [tag(.deltoidSide, .primary), tag(.traps, .stabiliser)],
                executions: [
                    .init(4, sets: [.init(25, 16)]),
                    .init(19, sets: [.init(24, 15)]),
                ]
            ),
            Sample(
                name: "Biceps curl",
                tags: [tag(.biceps, .primary), tag(.forearms, .secondary)],
                executions: [
                    .init(7, sets: [.init(54, 12)]),
                    .init(26, sets: [.init(50, 12)]),
                ]
            ),
            Sample(
                name: "Triceps pushdown",
                tags: [tag(.triceps, .primary), tag(.forearms, .stabiliser)],
                executions: [
                    .init(2, sets: [.init(74, 12)]),
                    .init(22, sets: [.init(70, 12)]),
                ]
            ),
            Sample(
                name: "Leg press",
                tags: [tag(.quads, .primary), tag(.glutes, .secondary), tag(.hamstrings, .stabiliser)],
                equipment: .machine,
                executions: [
                    .init(18, sets: [.init(440, 10)]),
                    .init(44, sets: [.init(400, 10)]),
                ]
            ),
            Sample(
                name: "Leg curl",
                tags: [tag(.hamstrings, .primary), tag(.calves, .stabiliser)],
                executions: [
                    .init(13, sets: [.init(95, 12)]),
                    .init(29, sets: [.init(90, 12)]),
                ]
            ),
            Sample(
                name: "Calf raise",
                tags: [tag(.calves, .primary)],
                executions: [
                    .init(1, sets: [.init(210, 15)]),
                    .init(16, sets: [.init(200, 15)]),
                    .init(35, sets: [.init(190, 15)]),
                ]
            ),
            Sample(
                name: "Single-arm dumbbell row",
                isUnilateral: true,
                tags: [
                    tag(.lats, .primary), tag(.upperBack, .secondary), tag(.biceps, .secondary),
                    tag(.obliques, .stabiliser),
                ],
                executions: [
                    .init(8, sets: [.init(74, 9, 8), .init(74, 10, 9)]),
                    .init(28, sets: [.init(70, 10, 10)]),
                ]
            ),
            // Never performed: these stay at the top of the queue (nil sorts first).
            Sample(
                name: "Face pull",
                tags: [tag(.deltoidRear, .primary), tag(.upperBack, .secondary), tag(.traps, .secondary)]
            ),
            Sample(
                name: "Hip thrust",
                tags: [tag(.glutes, .primary), tag(.hamstrings, .secondary), tag(.abs, .stabiliser)]
            ),
            Sample(
                name: "Plank",
                tags: [tag(.abs, .primary), tag(.obliques, .secondary), tag(.lowerBack, .stabiliser)]
            ),
            Sample(
                name: "Bulgarian split squat",
                isUnilateral: true,
                tags: [
                    tag(.quads, .primary), tag(.glutes, .primary), tag(.hamstrings, .secondary),
                    tag(.adductors, .stabiliser),
                ]
            ),
            Sample(
                name: "Cable woodchop",
                isUnilateral: true,
                tags: [tag(.obliques, .primary), tag(.abs, .secondary), tag(.deltoidFront, .stabiliser)]
            ),
        ]
    }
}
#endif
