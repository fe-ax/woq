import SwiftUI

/// Edit weight and reps (not the date) of one logged entry. INTERFACE CONTRACT fixed by the orchestrator;
/// the sheets agent replaces the body. Presented from ExerciseDetailSheet's history list.
///
/// The draft is copied out of the entry once, in `init`, and written back only on Save
/// (PLAN.md pitfall 19). The date is read-only: editable dates are out of scope (PLAN.md section 14).
struct EntryEditSheet: View {
    var entry: Entry
    var isUnilateral: Bool

    @Environment(QueueStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SetDraft

    private enum Field: Hashable {
        case weight
        case reps
        case repsRight
    }

    @FocusState private var focus: Field?

    init(entry: Entry, isUnilateral: Bool) {
        self.entry = entry
        self.isUnilateral = isUnilateral
        _draft = State(
            initialValue: SetDraft(
                weightText: SetDraft.weightText(fromHalfKilos: entry.weightHalfKilos),
                repsText: SetDraft.repsText(fromReps: entry.reps),
                repsRightText: SetDraft.repsText(fromReps: entry.repsRight)
            )
        )
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) { focus = nil }
                        .buttonStyle(.plain)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(Tokens.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Tokens.paper)
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        SheetHeaderBar(title: String(localized: "Edit set")) {
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
                        .font(.caption)
                        .foregroundStyle(Tokens.muted)
                    Text(Formatting.absoluteDateTimeString(entry.date))
                        .font(Tokens.numberFont(.body))
                        .foregroundStyle(Tokens.ink)
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
                        .font(.caption)
                        .foregroundStyle(Tokens.danger)
                }

                Text(String(localized: "Leave the weight empty for a bodyweight set."))
                    .font(.caption)
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

    private var validatedSet: ValidatedSet? {
        switch draft.validate(isUnilateral: isUnilateral) {
        case .success(let set): set
        case .failure: nil
        }
    }

    private func save() {
        guard let set = validatedSet else { return }
        focus = nil
        store.updateEntry(
            entry,
            weightHalfKilos: set.weightHalfKilos,
            reps: set.reps,
            repsRight: set.repsRight
        )
        dismiss()
    }
}
