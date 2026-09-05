import SwiftData
import SwiftUI

#if DEBUG
/// DEBUG root used by `xcrun simctl launch <sim> nl.feax.woq --preview <name>` to show one sheet's content
/// full-screen for visual verification without going through MainScreen. Owned by the sheets agent in wave 3.
/// Names: "add" (ExerciseFormSheet .add), "edit" (ExerciseFormSheet .edit on a seeded exercise),
/// "detail" (ExerciseDetailSheet on a seeded exercise with entries), "entry" (EntryEditSheet on a seeded entry).
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
                print("ADDED", result.exercise.name, result.outcome)
            }

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
            .font(.body)
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

    /// At least two entries, preferring a unilateral exercise so the R fields show up.
    private var exerciseWithHistory: Exercise? {
        let candidates = ordered.filter { $0.entries.count >= 2 }
        return candidates.first(where: \.isUnilateral) ?? candidates.first
    }

    private func latestEntry(of exercise: Exercise) -> Entry? {
        exercise.entries.max { $0.date < $1.date }
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
