import SwiftData
import SwiftUI
import os

#if DEBUG
/// DEBUG root used by `xcrun simctl launch <sim> nl.feax.woq --preview <name>` to show one sheet's content
/// full-screen for visual verification without going through MainScreen. Owned by the sheets agent in wave 3.
/// Names: "add" (ExerciseFormSheet .add), "presets" (ExerciseFormSheet .add opened on the preset list),
/// "edit" (ExerciseFormSheet .edit on a seeded exercise), "detail" (ExerciseDetailSheet on a seeded
/// exercise with entries), "entry" (EntryEditSheet editing a seeded set), "addset"
/// (EntryEditSheet adding a set to the newest seeded execution), "chart" (the Progress
/// section on the seeded exercise with the most executions, plus synthetic series for the
/// shapes the seed cannot produce — see `ChartDemo`).
///
/// The sheets are shown as the root view, not through `.sheet`, so a screenshot captures them full-screen.
/// `presentationBackground` / `presentationDetents` are simply inert there.
struct DebugPreviewRoot: View {
    var name: String

    @Environment(QueueStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]

    /// The sample is picked once and then kept, so deleting an entry does not
    /// make the preview jump to a different exercise mid-check.
    @State private var pinnedID: PersistentIdentifier?

    private static let logger = Logger(subsystem: "nl.feax.woq", category: "debug-preview")

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            content
        }
        .onAppear {
            if exercises.isEmpty {
                SeedData.insertSamples(using: store, context: modelContext)
            }
            pinIfNeeded()
        }
        .onChange(of: exercises.count) { pinIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch name {
        case "add":
            ExerciseFormSheet(mode: .add) { result in
                // No `print`: the result goes to the unified log, where
                // `xcrun simctl spawn <sim> log stream` can pick it up.
                Self.logger.notice(
                    "added \(result.exercise.name, privacy: .public), outcome \(String(describing: result.outcome), privacy: .public)"
                )
            }

        case "presets":
            // Seeded samples share several names with the preset table, so the
            // "Added" rows show up in this preview too.
            ExerciseFormSheet(
                mode: .add,
                onAddedPresets: { count in
                    Self.logger.notice("added \(count, privacy: .public) presets to the queue")
                },
                startsInPresetMode: true
            )

        case "edit":
            if let exercise = pinned ?? taggedExercise {
                ExerciseFormSheet(mode: .edit(exercise))
            } else {
                placeholder(String(localized: "No seeded exercise with muscles yet"))
            }

        case "detail":
            if let exercise = pinned ?? exerciseWithHistory {
                ExerciseDetailSheet(exercise: exercise)
            } else {
                placeholder(String(localized: "No seeded exercise with two entries yet"))
            }

        case "entry":
            if let exercise = pinned ?? exerciseWithHistory,
               let execution = exercise.lastExecution,
               let entry = latestEntry(of: exercise) {
                // The peak of the newest execution, with its real position so the
                // "Set 2 of 3" caption shows what the detail sheet would pass.
                EntryEditSheet(
                    mode: .edit(
                        entry: entry,
                        position: (execution.sets.firstIndex { $0 === entry } ?? 0) + 1,
                        setCount: execution.setCount
                    ),
                    isUnilateral: exercise.isUnilateral
                )
            } else {
                placeholder(String(localized: "No seeded entry yet"))
            }

        case "addset":
            if let exercise = pinned ?? exerciseWithHistory, let execution = exercise.lastExecution {
                EntryEditSheet(
                    mode: .add(execution: execution, exercise: exercise),
                    isUnilateral: exercise.isUnilateral
                )
            } else {
                placeholder(String(localized: "No seeded execution yet"))
            }

        case "chart":
            chartPreview

        default:
            placeholder(String(localized: "Unknown preview \"\(name)\""))
        }
    }

    /// The Progress section on its own. The seeded store tops out at three executions, so the
    /// shapes that only appear further along — horizontal scrolling, a long S-curving lane, a
    /// single lonely node, a bodyweight session inside a weighted history — come from
    /// `ChartDemo`, which builds `Execution`s from unsaved `Entry` objects (never inserted, so
    /// the store is untouched).
    private var chartPreview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let exercise = pinned ?? exerciseWithMostExecutions {
                    demo("Seeded: \(exercise.name)", ProgressSeries.make(from: exercise.executions))
                }
                demo("14 sessions, record in the middle", ChartDemo.longSeries)
                demo("One session", ChartDemo.singleSeries)
                demo("Flat history", ChartDemo.flatSeries)
                demo("Bodyweight session in a weighted history", ChartDemo.mixedSeries)
                demo("Bodyweight only (reps)", ChartDemo.repsSeries)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    private func demo(_ title: String, _ series: ProgressSeries) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: title)
                    .appFont(.headline, weight: .bold)
                    .foregroundStyle(Tokens.ink)
                Text(verbatim: ProgressChartText.caption(for: series.metric))
                    .appFont(.caption)
                    .foregroundStyle(Tokens.muted)
                Spacer(minLength: 0)
            }
            ProgressChart(series: series)
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .appFont(.body)
            .foregroundStyle(Tokens.muted)
            .multilineTextAlignment(.center)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sample pickers

    private var ordered: [Exercise] {
        QueueStore.ordered(exercises)
    }

    private var taggedExercise: Exercise? {
        ordered.first { !$0.muscleTags.isEmpty }
    }

    /// At least two entries, preferring one whose LATEST execution holds several sets (so
    /// `--preview detail` shows the grouped card straight away), then a unilateral exercise
    /// so the R fields show up.
    private var exerciseWithHistory: Exercise? {
        let candidates = ordered.filter { $0.entries.count >= 2 }
        return candidates.first { ($0.lastExecution?.setCount ?? 0) > 1 }
            ?? candidates.first(where: \.isUnilateral)
            ?? candidates.first
    }

    /// What `--preview chart` pins: the longest history the seed produced.
    private var exerciseWithMostExecutions: Exercise? {
        ordered.max { $0.executions.count < $1.executions.count }
    }

    /// The set `--preview entry` opens: the peak of the newest execution, i.e. exactly the
    /// set the queue row and the card show.
    private func latestEntry(of exercise: Exercise) -> Entry? {
        exercise.lastExecution?.peak
    }

    private var pinned: Exercise? {
        guard let pinnedID else { return nil }
        return exercises.first { $0.persistentModelID == pinnedID }
    }

    private func pinIfNeeded() {
        guard pinnedID == nil else { return }
        switch name {
        case "edit": pinnedID = taggedExercise?.persistentModelID
        case "detail", "entry", "addset": pinnedID = exerciseWithHistory?.persistentModelID
        case "chart": pinnedID = exerciseWithMostExecutions?.persistentModelID
        default: break
        }
    }
}

/// Synthetic progress series for `--preview chart`.
///
/// The `Entry` objects are created but never inserted into a `ModelContext`: they exist only
/// for the length of the redraw, which is all `Execution` and `ProgressSeries` need (both are
/// in-memory read models). Nothing here can reach the store or a backup.
private enum ChartDemo {

    /// Fourteen sessions climbing, stalling and dipping, with the best one in the middle so
    /// the PR chip is not at the scrolled-to end.
    static var longSeries: ProgressSeries {
        series([
            (60, [(140, 8)]),
            (55, [(145, 8)]),
            (51, [(145, 10)]),
            (46, [(150, 8), (150, 7)]),
            (41, [(150, 10)]),
            (37, [(155, 8)]),
            (32, [(160, 10), (165, 6), (160, 8)]),
            (28, [(155, 8)]),
            (23, [(150, 10)]),
            (19, [(155, 9)]),
            (14, [(160, 8)]),
            (10, [(160, 9)]),
            (5, [(162, 9), (160, 10)]),
            (1, [(165, 8), (165, 8)]),
        ])
    }

    /// A single node: no stripe to draw.
    static var singleSeries: ProgressSeries {
        series([(4, [(80, 10)])])
    }

    /// Every session identical — the lane must run flat through the middle instead of
    /// dividing by a zero range.
    static var flatSeries: ProgressSeries {
        series([(30, [(100, 10)]), (20, [(100, 10)]), (10, [(100, 10)]), (2, [(100, 10)])])
    }

    /// A weighted history with one bodyweight session in it: that node drops to the baseline
    /// as a dashed "BW".
    static var mixedSeries: ProgressSeries {
        series([
            (28, [(60, 10)]),
            (21, [(nil, 12), (nil, 10)]),
            (14, [(64, 10)]),
            (7, [(70, 8)]),
            (1, [(70, 10)]),
        ])
    }

    /// No weight anywhere: the series plots reps instead, and nothing is a baseline node.
    static var repsSeries: ProgressSeries {
        series([
            (30, [(nil, 8)]),
            (22, [(nil, 9)]),
            (15, [(nil, 11), (nil, 9)]),
            (8, [(nil, 10)]),
            (2, [(nil, 12), (nil, 10), (nil, 9)]),
        ])
    }

    /// `[(daysAgo, [(halfKilos, reps)])]` -> a finished series, oldest first.
    private static func series(_ table: [(Int, [(Int?, Int)])]) -> ProgressSeries {
        ProgressSeries.make(from: table.compactMap { execution(daysAgo: $0.0, sets: $0.1) })
    }

    private static func execution(daysAgo: Int, sets: [(Int?, Int)]) -> Execution? {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let start = calendar.date(bySettingHour: 9, minute: 6, second: 0, of: day) ?? day
        let id = UUID()

        let entries = sets.enumerated().map { index, set in
            Entry(
                date: start.addingTimeInterval(Double(index) * 180),
                weightHalfKilos: set.0,
                reps: set.1,
                executionID: id,
                setIndex: index
            )
        }
        return Execution(id: id, sets: entries, isUnilateral: false)
    }
}
#endif
