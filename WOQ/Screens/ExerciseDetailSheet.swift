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
    /// The set editor: `.edit` from a set's pencil, `.add` from an execution's "Add set"
    /// row. One piece of state for both, so only one of them can be up at a time.
    @State private var setSheet: EntryEditSheet.Mode?
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
        .sheet(item: $setSheet) { mode in
            EntryEditSheet(mode: mode, isUnilateral: exercise.isUnilateral)
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
                detailsSection
                progressSection
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
                    .appFont(.caption, weight: .bold)
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
                .appNumberFont(.subheadline)
                .foregroundStyle(Tokens.muted)

            Spacer(minLength: 0)
        }
    }

    private var muscleSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(String(localized: "Muscles"))

            if exercise.muscleTags.isEmpty {
                Text(String(localized: "No muscles tagged"))
                    .appFont(.subheadline)
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
                                .appFont(.subheadline)
                                .foregroundStyle(Tokens.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    /// Equipment tag and exercise note (2026-09-12). The detail sheet is the only place
    /// they are shown; rows and the in-progress card stay as they were. Nothing is drawn when
    /// the exercise carries neither.
    @ViewBuilder
    private var detailsSection: some View {
        let note = exercise.notes ?? ""

        if exercise.equipment != nil || !note.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                if let equipment = exercise.equipment {
                    equipmentChip(equipment)
                }

                if !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Notes"))
                            .appFont(.caption)
                            .foregroundStyle(Tokens.muted)
                        Text(note)
                            .appFont(.body)
                            .foregroundStyle(Tokens.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    /// The L/R badge's shape in quiet clothes: card fill and muted text, because the
    /// equipment is a label, not a state.
    private func equipmentChip(_ equipment: Equipment) -> some View {
        Text(equipment.displayName)
            .appFont(.caption, weight: .bold)
            .foregroundStyle(Tokens.muted)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
            )
            .accessibilityLabel(String(localized: "Equipment: \(equipment.displayName)"))
    }

    /// The progress graph (decided 2026-09-12 evening): one node per execution, plotting the
    /// estimated 1RM of its peak set — the same Epley number the peak rule already uses.
    ///
    /// Nothing is drawn for an exercise that was never performed: an empty card with a title
    /// over it would be a promise, and the "No sets logged yet" line under History already says
    /// what is going on. The series is rebuilt on every redraw like `history` is, from the same
    /// in-memory grouping.
    @ViewBuilder
    private var progressSection: some View {
        let series = ProgressSeries.make(from: history)

        if !series.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    sectionTitle(String(localized: "Progress"))

                    Text(ProgressChartText.caption(for: series.metric))
                        .appFont(.caption)
                        .foregroundStyle(Tokens.muted)

                    Spacer(minLength: 0)
                }

                ProgressChart(series: series)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "History"))

            if history.isEmpty {
                Text(String(localized: "No sets logged yet"))
                    .appFont(.subheadline)
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
                    .appNumberFont(.caption)
                    .foregroundStyle(Tokens.muted)

                ForEach(Array(execution.sets.enumerated()), id: \.element.id) { index, entry in
                    setRow(
                        number: index + 1,
                        entry: entry,
                        setCount: execution.setCount,
                        isPeak: entry === execution.peak,
                        showsPeakChip: execution.setCount > 1 && entry === execution.peak
                    )
                }

                addSetRow(for: execution)
            }
        }
    }

    /// "Add set" under every execution card (decided 2026-09-12): a set logged on the phone
    /// but forgotten can be written into the session it belongs to instead of becoming a
    /// separate one. The whole row is the button; `QueueStore.addSet(to:of:set:notes:)` puts
    /// the new set at the end of the execution with the execution's own date.
    private func addSetRow(for execution: Execution) -> some View {
        Button {
            setSheet = .add(execution: execution, exercise: exercise)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Tokens.ink)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Tokens.card))
                    .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.hairline))

                Text(String(localized: "Add set"))
                    .appFont(.caption)
                    .foregroundStyle(Tokens.muted)

                Spacer(minLength: 0)
            }
            .padding(.top, 2)
            .frame(minHeight: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Add set to this execution"))
    }

    /// One set: its position in the execution, what was logged, the peak badge, edit, delete.
    ///
    /// The number comes from the position in `execution.sets`, not from `Entry.setIndex`, so
    /// deleting the middle set of three leaves 1 and 2 rather than a gap.
    ///
    /// Everything left of the buttons is combined into a single VoiceOver element; the two
    /// buttons stay separately reachable next to it. A note typed afterwards (2026-09-12)
    /// hangs under the row as its own muted line.
    private func setRow(
        number: Int,
        entry: Entry,
        setCount: Int,
        isPeak: Bool,
        showsPeakChip: Bool
    ) -> some View {
        let note = entry.notes ?? ""

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                HStack(spacing: 8) {
                    // Fixed width and trailing aligned so the set strings line up under
                    // each other whether the execution has 3 sets or 12.
                    Text(verbatim: "\(number)")
                        .appNumberFont(.caption)
                        .foregroundStyle(Tokens.muted)
                        .frame(width: 16, alignment: .trailing)

                    Text(Formatting.setString(for: entry))
                        .appNumberFont(.body, weight: isPeak ? .bold : .regular)
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
                    setSheet = .edit(entry: entry, position: number, setCount: setCount)
                }

                RoundIconButton(
                    systemName: "trash",
                    accessibilityLabel: String(localized: "Delete set")
                ) {
                    entryPendingDelete = entry
                }
            }

            // The note the set was given afterwards, indented under its set string
            // (16 pt number column + 8 pt spacing).
            if !note.isEmpty {
                Text(note)
                    .appFont(.caption)
                    .foregroundStyle(Tokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 24)
                    .padding(.bottom, 2)
                    .accessibilityLabel(String(localized: "Note: \(note)"))
            }
        }
    }

    /// The blue "peak" badge. Only shown on an execution of several sets: on a single set
    /// there is nothing to be the best of.
    private var peakChip: some View {
        Text(String(localized: "peak"))
            .appFont(.caption2, weight: .bold)
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
                .appFont(.body, weight: .semibold)
                .foregroundStyle(Tokens.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appFont(.headline, weight: .bold)
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
