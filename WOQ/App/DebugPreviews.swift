import SwiftData
import SwiftUI
import os

#if DEBUG
/// DEBUG root used by `xcrun simctl launch <sim> nl.feax.woq --preview <name>` to show one sheet's content
/// full-screen for visual verification without going through MainScreen. Owned by the sheets agent in wave 3.
/// Names: "add" (ExerciseFormSheet .add), "presets" (ExerciseFormSheet .add opened on the preset list),
/// "edit" (ExerciseFormSheet .edit on a seeded exercise), "detail" (ExerciseDetailSheet on a seeded
/// exercise with entries), "entry" (EntryEditSheet on a seeded entry).
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
            if let exercise = pinned ?? exerciseWithHistory, let entry = latestEntry(of: exercise) {
                EntryEditSheet(entry: entry, isUnilateral: exercise.isUnilateral)
            } else {
                placeholder(String(localized: "No seeded entry yet"))
            }

        default:
            placeholder(String(localized: "Unknown preview \"\(name)\""))
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
        case "detail", "entry": pinnedID = exerciseWithHistory?.persistentModelID
        default: break
        }
    }
}
#endif
