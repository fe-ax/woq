#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only sample data (PLAN.md section 2 "Seed data", milestone M2). The shipped app
/// starts empty; the UI hides this behind a long-press on the header title.
///
/// Everything goes through `QueueStore`, so the seed cannot break the invariants it owns:
/// `addExercise` creates the exercise, `finalize(_:with:at:)` writes each historic entry
/// (oldest first, so `lastPerformedAt` ends up on the newest one) and a final `putBack`
/// leaves nothing in progress.
///
/// Idempotent: names that already exist are skipped, so running it twice changes nothing.
nonisolated enum SeedData {

    /// One sample exercise plus its history.
    nonisolated struct Sample: Sendable {
        var name: String
        var isUnilateral: Bool = false
        var tags: [MuscleTag]
        /// Historic sets, newest first in this table; inserted oldest first.
        var sets: [Sample.Log] = []

        nonisolated struct Log: Sendable {
            var daysAgo: Int
            /// nil = bodyweight.
            var halfKilos: Int?
            var reps: Int
            var repsRight: Int?

            init(_ daysAgo: Int, _ halfKilos: Int?, _ reps: Int, _ repsRight: Int? = nil) {
                self.daysAgo = daysAgo
                self.halfKilos = halfKilos
                self.reps = reps
                self.repsRight = repsRight
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
                firstSet: nil
            )

            for set in sample.sets.sorted(by: { $0.daysAgo > $1.daysAgo }) {
                let date = calendar.date(byAdding: .day, value: -set.daysAgo, to: now) ?? now
                store.finalize(
                    exercise,
                    with: ValidatedSet(
                        weightHalfKilos: set.halfKilos,
                        reps: set.reps,
                        repsRight: set.repsRight
                    ),
                    at: date
                )
            }
        }

        // A brand-new exercise with no first set starts in progress; the seed leaves the
        // queue at rest instead (PLAN.md 3.2 keeps at most one in progress either way).
        if let current = store.inProgressExercise() {
            store.putBack(current)
        }
    }

    // MARK: - Table

    private static func tag(_ muscle: Muscle, _ intensity: Intensity) -> MuscleTag {
        MuscleTag(muscle: muscle, intensity: intensity)
    }

    /// 21 exercises: 16 with 1-4 sets spread over the last 60 days, 5 never performed.
    /// Weights are half-kilos (80 == 40 kg); "plank" counts holds as reps, never seconds.
    static var samples: [Sample] {
        [
            Sample(
                name: "Bench press",
                tags: [tag(.chest, .primary), tag(.deltoidFront, .secondary), tag(.triceps, .secondary)],
                sets: [.init(10, 170, 9), .init(24, 170, 8), .init(45, 160, 8)]
            ),
            Sample(
                name: "Incline dumbbell press",
                tags: [tag(.chest, .primary), tag(.deltoidFront, .secondary), tag(.triceps, .stabiliser)],
                sets: [.init(17, 64, 10), .init(38, 60, 10)]
            ),
            Sample(
                name: "Squat",
                tags: [
                    tag(.quads, .primary), tag(.glutes, .primary), tag(.hamstrings, .secondary),
                    tag(.lowerBack, .stabiliser), tag(.abs, .stabiliser),
                ],
                sets: [.init(12, 180, 5), .init(31, 170, 5), .init(52, 160, 5)]
            ),
            Sample(
                name: "Deadlift",
                tags: [
                    tag(.hamstrings, .primary), tag(.glutes, .primary), tag(.lowerBack, .primary),
                    tag(.lats, .secondary), tag(.traps, .secondary), tag(.forearms, .stabiliser),
                ],
                sets: [.init(14, 210, 5), .init(40, 200, 5)]
            ),
            Sample(
                name: "Romanian deadlift",
                tags: [tag(.hamstrings, .primary), tag(.glutes, .secondary), tag(.lowerBack, .secondary)],
                sets: [.init(9, 130, 8), .init(33, 120, 8)]
            ),
            Sample(
                name: "Barbell row",
                tags: [
                    tag(.upperBack, .primary), tag(.lats, .primary), tag(.biceps, .secondary),
                    tag(.lowerBack, .stabiliser),
                ],
                sets: [.init(6, 125, 8), .init(27, 120, 8)]
            ),
            Sample(
                name: "Lat pulldown",
                tags: [tag(.lats, .primary), tag(.biceps, .secondary), tag(.upperBack, .secondary)],
                sets: [.init(5, 115, 10), .init(21, 110, 10)]
            ),
            Sample(
                name: "Pull-up",
                tags: [
                    tag(.lats, .primary), tag(.biceps, .secondary), tag(.upperBack, .secondary),
                    tag(.abs, .stabiliser),
                ],
                sets: [.init(3, nil, 10), .init(11, nil, 9), .init(30, nil, 8)]
            ),
            Sample(
                name: "Overhead press",
                tags: [
                    tag(.deltoidFront, .primary), tag(.deltoidSide, .secondary),
                    tag(.triceps, .secondary), tag(.abs, .stabiliser),
                ],
                sets: [.init(15, 85, 6), .init(36, 80, 6)]
            ),
            Sample(
                name: "Lateral raise",
                tags: [tag(.deltoidSide, .primary), tag(.traps, .stabiliser)],
                sets: [.init(4, 25, 16), .init(19, 24, 15)]
            ),
            Sample(
                name: "Biceps curl",
                tags: [tag(.biceps, .primary), tag(.forearms, .secondary)],
                sets: [.init(7, 54, 12), .init(26, 50, 12)]
            ),
            Sample(
                name: "Triceps pushdown",
                tags: [tag(.triceps, .primary), tag(.forearms, .stabiliser)],
                sets: [.init(2, 74, 12), .init(22, 70, 12)]
            ),
            Sample(
                name: "Leg press",
                tags: [tag(.quads, .primary), tag(.glutes, .secondary), tag(.hamstrings, .stabiliser)],
                sets: [.init(18, 440, 10), .init(44, 400, 10)]
            ),
            Sample(
                name: "Leg curl",
                tags: [tag(.hamstrings, .primary), tag(.calves, .stabiliser)],
                sets: [.init(13, 95, 12), .init(29, 90, 12)]
            ),
            Sample(
                name: "Calf raise",
                tags: [tag(.calves, .primary)],
                sets: [.init(1, 210, 15), .init(16, 200, 15), .init(35, 190, 15)]
            ),
            Sample(
                name: "Single-arm dumbbell row",
                isUnilateral: true,
                tags: [
                    tag(.lats, .primary), tag(.upperBack, .secondary), tag(.biceps, .secondary),
                    tag(.obliques, .stabiliser),
                ],
                sets: [.init(8, 74, 10, 9), .init(28, 70, 10, 10)]
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
