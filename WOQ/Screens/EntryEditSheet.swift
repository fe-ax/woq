import SwiftUI

/// Edit one logged set, or add a set to an execution that is already in the history
/// (2026-09-12). Presented from `ExerciseDetailSheet`'s history list.
///
/// The draft is copied out of the model once, in `init`, and written back only on Save
/// (PLAN.md pitfall 19). The date is read-only in both modes: editable dates are out of
/// scope (PLAN.md section 14), and a set added to a past execution takes that execution's
/// date so neither the history order nor `lastPerformedAt` moves.
struct EntryEditSheet: View {

    /// Which set the sheet is about. `nonisolated` so its `Identifiable` conformance (used by
    /// `.sheet(item:)`) is not main-actor isolated; `Entry`, `Exercise` and `Execution` are
    /// all nonisolated types themselves.
    nonisolated enum Mode: Identifiable {
        /// An existing set, with its 1-based position in the execution and the execution's
        /// set count — that is what the "Set 2 of 3" caption reads.
        case edit(entry: Entry, position: Int, setCount: Int)
        /// A new set appended to `execution`; the caption counts it in ("Set 4 of 4").
        case add(execution: Execution, exercise: Exercise)

        nonisolated var id: UUID {
            switch self {
            case .edit(let entry, _, _): entry.id
            case .add(let execution, _): execution.id
            }
        }
    }

    var mode: Mode
    var isUnilateral: Bool

    @Environment(QueueStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SetDraft
    @State private var note: String

    private enum Field: Hashable {
        case weight
        case reps
        case repsRight
        case note
    }

    @FocusState private var focus: Field?

    init(mode: Mode, isUnilateral: Bool) {
        self.mode = mode
        self.isUnilateral = isUnilateral

        // Edit starts on the set itself; add starts on the execution's peak — the same
        // numbers the queue row and the in-progress card show (PLAN.md "Peak rule").
        // A note is never carried over: it belongs to the set that was logged.
        let source: Entry
        switch mode {
        case .edit(let entry, _, _): source = entry
        case .add(let execution, _): source = execution.peak
        }

        _draft = State(
            initialValue: SetDraft(
                weightText: SetDraft.weightText(fromHalfKilos: source.weightHalfKilos),
                repsText: SetDraft.repsText(fromReps: source.reps),
                repsRightText: SetDraft.repsText(fromReps: source.repsRight)
            )
        )
        _note = State(initialValue: mode.isAdd ? "" : (source.notes ?? ""))
    }

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
            // Paper bar above the number pads, which have no return key
            // (PLAN.md pitfall 5). The note field keeps its own return key.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isNumericFieldFocused {
                    KeyboardAccessoryBar(
                        showsNext: canFocusNext,
                        onNext: focusNext,
                        onDone: { focus = nil }
                    )
                }
            }
            .animation(.snappy, value: focus)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Tokens.paper)
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        SheetHeaderBar(title: mode.isAdd ? String(localized: "Add set") : String(localized: "Edit set")) {
            Button(String(localized: "Cancel")) { dismiss() }
                .buttonStyle(.paper)
            Button(String(localized: "Save"), action: save)
                .buttonStyle(.ink)
                .disabled(validatedSet == nil)
                .opacity(validatedSet == nil ? 0.4 : 1)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Logged"))
                        .appFont(.caption)
                        .foregroundStyle(Tokens.muted)
                    Text(Formatting.absoluteDateTimeString(date))
                        .appNumberFont(.body)
                        .foregroundStyle(Tokens.ink)
                    Text(positionCaption)
                        .appNumberFont(.caption)
                        .foregroundStyle(Tokens.muted)
                }
                .accessibilityElement(children: .combine)

                HStack(alignment: .top, spacing: 12) {
                    StepperField(
                        title: String(localized: "Weight"),
                        text: $draft.weightText,
                        unit: String(localized: "kg"),
                        keyboard: .decimalPad,
                        onStep: { step in
                            draft.weightText = SetDraft.steppedWeightText(draft.weightText, by: step)
                        },
                        focus: $focus,
                        field: .weight,
                        isInvalid: weightProblem != nil,
                        accessibilityLabel: String(localized: "Weight in kilograms")
                    )

                    StepperField(
                        title: isUnilateral ? String(localized: "Reps L") : String(localized: "Reps"),
                        text: $draft.repsText,
                        keyboard: .numberPad,
                        onStep: { step in
                            draft.repsText = SetDraft.steppedRepsText(draft.repsText, by: step)
                        },
                        focus: $focus,
                        field: .reps,
                        accessibilityLabel: isUnilateral
                            ? String(localized: "Repetitions left")
                            : String(localized: "Repetitions")
                    )
                }

                if isUnilateral {
                    HStack(alignment: .top, spacing: 12) {
                        StepperField(
                            title: String(localized: "Reps R"),
                            text: $draft.repsRightText,
                            keyboard: .numberPad,
                            onStep: { step in
                                draft.repsRightText = SetDraft.steppedRepsText(draft.repsRightText, by: step)
                            },
                            focus: $focus,
                            field: .repsRight,
                            accessibilityLabel: String(localized: "Repetitions right")
                        )
                        Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }

                if let weightProblem {
                    Text(SetFieldHint.text(for: weightProblem))
                        .appFont(.caption)
                        .foregroundStyle(Tokens.danger)
                }

                NotesField(
                    title: String(localized: "Note"),
                    placeholder: String(localized: "Notes"),
                    text: $note,
                    lineLimit: 1...3,
                    focus: $focus,
                    field: .note,
                    accessibilityLabel: String(localized: "Note on this set")
                )

                Text(String(localized: "Leave the weight empty for a bodyweight set."))
                    .appFont(.caption)
                    .foregroundStyle(Tokens.muted)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    // MARK: - State

    private var weightProblem: DraftProblem? {
        draft.weightProblem()
    }

    /// The moment the execution was logged. Never editable — in add mode the new set simply
    /// joins that execution (`QueueStore.addSet(to:of:set:notes:)` stamps the same date).
    private var date: Date {
        switch mode {
        case .edit(let entry, _, _): entry.date
        case .add(let execution, _): execution.date
        }
    }

    /// "Set 2 of 3" while editing; in add mode the new set is counted in, so appending to a
    /// three-set execution reads "Set 4 of 4".
    private var positionCaption: String {
        switch mode {
        case .edit(_, let position, let setCount):
            String(localized: "Set \(position) of \(setCount)")
        case .add(let execution, _):
            String(localized: "Set \(execution.setCount + 1) of \(execution.setCount + 1)")
        }
    }

    // MARK: - Focus chain (PLAN.md pitfall 5)

    /// The accessory bar belongs to the number pads only; the note field has a return key.
    private var isNumericFieldFocused: Bool {
        switch focus {
        case .weight, .reps, .repsRight: true
        case .note, .none: false
        }
    }

    /// The R field is skipped for a bilateral exercise; the chain stops before the note.
    private var canFocusNext: Bool {
        switch focus {
        case .weight: true
        case .reps: isUnilateral
        case .repsRight, .note, .none: false
        }
    }

    private func focusNext() {
        switch focus {
        case .weight: focus = .reps
        case .reps: focus = isUnilateral ? .repsRight : nil
        case .repsRight, .note, .none: focus = nil
        }
    }

    private var validatedSet: ValidatedSet? {
        switch draft.validate(isUnilateral: isUnilateral) {
        case .success(let set): set
        case .failure: nil
        }
    }

    private func save() {
        guard let set = validatedSet else { return }
        focus = nil

        // The store normalises the note (blank -> nil) through `Exercise.cleanedNotes`.
        switch mode {
        case .edit(let entry, _, _):
            store.updateEntry(
                entry,
                weightHalfKilos: set.weightHalfKilos,
                reps: set.reps,
                repsRight: set.repsRight,
                notes: note
            )
        case .add(let execution, let exercise):
            store.addSet(to: execution, of: exercise, set: set, notes: note)
        }

        dismiss()
    }
}

extension EntryEditSheet.Mode {
    /// Title, caption and the note prefill all branch on this.
    nonisolated var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}
