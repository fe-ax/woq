import SwiftUI

/// Long-press detail sheet: large figures, muscles, history (edit/delete entries), Edit and Delete exercise.
/// INTERFACE CONTRACT fixed by the orchestrator; the sheets agent replaces the body.
/// Presented by MainScreen via `.sheet(item:)` with the tapped `Exercise`.
///
/// The sheet holds the model object itself, so every change a `QueueStore` method makes
/// (rename, entry edit, entry delete) redraws this view automatically — `@Model` types are
/// `Observable`. Nothing here mutates a model directly (PLAN.md pitfall 2).
struct ExerciseDetailSheet: View {
    var exercise: Exercise

    @Environment(QueueStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingExercise = false
    @State private var editedEntry: Entry?
    @State private var entryPendingDelete: Entry?
    @State private var isConfirmingExerciseDelete = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Tokens.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    Rectangle()
                        .fill(Tokens.ink)
                        .frame(height: Tokens.hairline)
                    content
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationBackground(Tokens.paper)
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isEditingExercise) {
            ExerciseFormSheet(mode: .edit(exercise))
        }
        .sheet(item: $editedEntry) { entry in
            EntryEditSheet(entry: entry, isUnilateral: exercise.isUnilateral)
        }
        // `confirmationDialog` renders on iOS 26 as a compact card whose only
        // way out is a tap outside, so both destructive confirmations are
        // alerts with a visible Cancel (TODO.md).
        .alert(
            deleteExercisePrompt,
            isPresented: $isConfirmingExerciseDelete
        ) {
            Button(String(localized: "Delete exercise"), role: .destructive) {
                store.deleteExercise(exercise)
                dismiss()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
        .alert(
            String(localized: "Delete this set?"),
            isPresented: entryDeleteBinding,
            presenting: entryPendingDelete
        ) { entry in
            Button(String(localized: "Delete set"), role: .destructive) {
                store.deleteEntry(entry)
                entryPendingDelete = nil
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                entryPendingDelete = nil
            }
        } message: { entry in
            Text(Formatting.setString(for: entry))
        }
    }

    // MARK: - Header

    private var header: some View {
        SheetHeaderBar(title: exercise.name) {
            Button(String(localized: "Edit")) { isEditingExercise = true }
                .buttonStyle(.paper)
            Button(String(localized: "Close")) { dismiss() }
                .buttonStyle(.ink)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FigurePairView(tags: exercise.muscleTags, size: .large, palette: Tokens.figurePalette)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)

                badges
                muscleSummary
                historySection
                deleteButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    private var badges: some View {
        HStack(spacing: 8) {
            if exercise.isUnilateral {
                Text(String(localized: "L/R"))
                    .font(.system(.caption, weight: .bold))
                    // Sits on a blue fill, which stays pastel in both appearances.
                    .foregroundStyle(Tokens.inkOnPastel)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                            .fill(Tokens.blue)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                            .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                    )
                    .accessibilityLabel(String(localized: "Left and right logged separately"))
            }

            Text(Formatting.relativeDayString(from: exercise.lastPerformedAt))
                .font(Tokens.numberFont(.subheadline))
                .foregroundStyle(Tokens.muted)

            Spacer(minLength: 0)
        }
    }

    private var muscleSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(String(localized: "Muscles"))

            if exercise.muscleTags.isEmpty {
                Text(String(localized: "No muscles tagged"))
                    .font(.subheadline)
                    .foregroundStyle(Tokens.muted)
            } else {
                ForEach([Intensity.primary, .secondary, .stabiliser], id: \.rawValue) { intensity in
                    let names = muscleNames(for: intensity)
                    if !names.isEmpty {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(colour(for: intensity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                                )
                                .frame(width: 12, height: 12)

                            Text(String(localized: "\(intensity.displayName): \(names)"))
                                .font(.subheadline)
                                .foregroundStyle(Tokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "History"))

            if history.isEmpty {
                Text(String(localized: "No sets logged yet"))
                    .font(.subheadline)
                    .foregroundStyle(Tokens.muted)
            } else {
                ForEach(history) { execution in
                    executionCard(execution)
                }
            }
        }
    }

    /// One card per execution: when it was finished, how many sets it holds and every set in
    /// order with the peak marked. A one-set execution — every set logged before schema V2,
    /// and every single-set session since — reads exactly the way the old per-set card did.
    ///
    /// Editing and deleting stay per set (PLAN.md section 2 "Detail"): the buttons act on the
    /// `Entry` of their own row, and deleting the last set of an execution makes the whole
    /// card disappear by itself, because an execution is only a grouping of the sets.
    private func executionCard(_ execution: Execution) -> some View {
        OutlinedCard(padding: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(caption(for: execution))
                    .font(Tokens.numberFont(.caption))
                    .foregroundStyle(Tokens.muted)

                ForEach(Array(execution.sets.enumerated()), id: \.element.id) { index, entry in
                    setRow(
                        number: index + 1,
                        entry: entry,
                        isPeak: entry === execution.peak,
                        showsPeakChip: execution.setCount > 1 && entry === execution.peak
                    )
                }
            }
        }
    }

    /// One set: its position in the execution, what was logged, the peak badge, edit, delete.
    ///
    /// The number comes from the position in `execution.sets`, not from `Entry.setIndex`, so
    /// deleting the middle set of three leaves 1 and 2 rather than a gap.
    ///
    /// Everything left of the buttons is combined into a single VoiceOver element; the two
    /// buttons stay separately reachable next to it.
    private func setRow(number: Int, entry: Entry, isPeak: Bool, showsPeakChip: Bool) -> some View {
        HStack(spacing: 4) {
            HStack(spacing: 8) {
                // Fixed width and trailing aligned so the set strings line up under each
                // other whether the execution has 3 sets or 12.
                Text(verbatim: "\(number)")
                    .font(Tokens.numberFont(.caption))
                    .foregroundStyle(Tokens.muted)
                    .frame(width: 16, alignment: .trailing)

                Text(Formatting.setString(for: entry))
                    .font(Tokens.numberFont(.body, weight: isPeak ? .bold : .regular))
                    .foregroundStyle(Tokens.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if showsPeakChip {
                    peakChip
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(setLabel(number: number, entry: entry, isPeak: showsPeakChip))

            Spacer(minLength: 4)

            RoundIconButton(
                systemName: "pencil",
                accessibilityLabel: String(localized: "Edit set")
            ) {
                editedEntry = entry
            }

            RoundIconButton(
                systemName: "trash",
                accessibilityLabel: String(localized: "Delete set")
            ) {
                entryPendingDelete = entry
            }
        }
    }

    /// The blue "peak" badge. Only shown on an execution of several sets: on a single set
    /// there is nothing to be the best of.
    private var peakChip: some View {
        Text(String(localized: "peak"))
            .font(.system(.caption2, weight: .bold))
            // Sits on a blue fill, which stays pastel in both appearances.
            .foregroundStyle(Tokens.inkOnPastel)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.blue)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
            )
            .accessibilityLabel(String(localized: "Peak set"))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            isConfirmingExerciseDelete = true
        } label: {
            Text(String(localized: "Delete exercise"))
                .font(.system(.body, weight: .semibold))
                .foregroundStyle(Tokens.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, weight: .bold))
            .foregroundStyle(Tokens.ink)
    }

    // MARK: - Derived

    /// Every logging event, newest first (PLAN.md section 6): the sets are already grouped
    /// by `Entry.executionKey` and the best set of each group is picked by the model
    /// (PLAN.md section 2 "Peak rule" — best estimated 1RM by Epley, ties to the earlier set).
    private var history: [Execution] {
        exercise.executions
    }

    /// "5 Sep 2026 at 09:41" for a single set, "5 Sep 2026 at 09:41 \u{00B7} 3 sets" when
    /// several sets were logged in one go — the same separator as `Formatting.executionString`.
    private func caption(for execution: Execution) -> String {
        let stamp = Formatting.absoluteDateTimeString(execution.date)
        guard execution.setCount > 1 else { return stamp }
        return "\(stamp) \u{00B7} \(Formatting.setCountString(execution.setCount))"
    }

    /// One VoiceOver sentence per set: "Set 2, 40 kg \u{00D7} 10, peak".
    private func setLabel(number: Int, entry: Entry, isPeak: Bool) -> String {
        let set = Formatting.setString(for: entry)
        return isPeak
            ? String(localized: "Set \(number), \(set), peak")
            : String(localized: "Set \(number), \(set)")
    }

    private func muscleNames(for intensity: Intensity) -> String {
        let tagged = Set(
            exercise.muscleTags.filter { $0.intensity == intensity }.map(\.muscle)
        )
        return Muscle.allCases
            .filter { tagged.contains($0) }
            .map(\.displayName)
            .joined(separator: ", ")
    }

    private func colour(for intensity: Intensity) -> Color {
        switch intensity {
        case .primary: Tokens.red
        case .secondary: Tokens.yellow
        case .stabiliser: Tokens.paleYellow
        }
    }

    private var deleteExercisePrompt: String {
        let count = exercise.entries.count
        return String(localized: "Delete \(exercise.name)? Its \(count) logged sets are deleted too.")
    }

    /// `alert(_:isPresented:presenting:actions:message:)` needs a Bool binding
    /// next to the presented value; clearing it clears the pending entry.
    private var entryDeleteBinding: Binding<Bool> {
        Binding(
            get: { entryPendingDelete != nil },
            set: { isPresented in
                if !isPresented { entryPendingDelete = nil }
            }
        )
    }
}
