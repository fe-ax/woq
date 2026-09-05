import SwiftUI

/// The single in-progress exercise (PLAN.md sections 3.4 to 3.6 and 6).
///
/// Water shader background with the card outline drawn on top — the card fill
/// would hide the water, so the border is an overlay over a `ZStack` instead of
/// an `OutlinedCard`. The draft lives in `MainScreen` (`@State`, never
/// persisted, PLAN.md 3.4); this view only edits the binding and reports the
/// validated set back.
struct InProgressCard: View {
    /// Focus chain for the keyboard toolbar (PLAN.md pitfall 5). The `Done` /
    /// `Next` toolbar lives in `MainScreen`, which owns the `@FocusState`.
    enum Field: Hashable {
        case weight
        case repsLeft
        case repsRight
    }

    var exercise: Exercise
    @Binding var draft: SetDraft
    var focus: FocusState<Field?>.Binding
    var onPutBack: () -> Void
    var onFinalize: (ValidatedSet) -> Void
    var onSameAsLast: () -> Void

    var body: some View {
        ZStack {
            WaterBackground()
            content
        }
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
        )
        .padding(.vertical, Tokens.rowSpacing / 2)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            fieldsRow

            if let problem = weightProblemText {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(Tokens.danger)
                    .accessibilityAddTraits(.isStaticText)
            }

            actionsRow
        }
        .padding(Tokens.cardPadding)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            FigurePairView(tags: exercise.muscleTags, size: .thumbnail)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(Tokens.ink)
                    .lineLimit(2)

                if exercise.isUnilateral {
                    Text(String(localized: "L/R"))
                        .font(.caption)
                        .foregroundStyle(Tokens.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                                .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                        )
                        .accessibilityLabel(String(localized: "Left and right separately"))
                }
            }

            Spacer(minLength: 0)

            RoundIconButton(
                systemName: "arrow.uturn.backward",
                accessibilityLabel: String(localized: "Put back")
            ) {
                onPutBack()
            }
        }
    }

    /// Three stepper fields do not fit next to each other on a 428 pt screen
    /// (each stepper needs 88 pt of buttons alone), so a unilateral exercise
    /// puts the shared weight on its own row above Reps L / Reps R.
    @ViewBuilder
    private var fieldsRow: some View {
        if exercise.isUnilateral {
            weightField
            HStack(alignment: .top, spacing: 10) {
                repsLeftField
                repsRightField
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                weightField
                repsLeftField
            }
        }
    }

    private var actionsRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if exercise.lastEntry != nil {
                Button(String(localized: "Same as last time")) {
                    onSameAsLast()
                }
                .buttonStyle(.paper)
            }

            Spacer(minLength: 0)

            CheckmarkButton(isEnabled: isValid) {
                guard case .success(let set) = draft.validate(isUnilateral: exercise.isUnilateral) else { return }
                onFinalize(set)
            }
        }
    }

    // MARK: - Fields

    private var weightField: some View {
        StepperField(
            title: String(localized: "Weight"),
            text: $draft.weightText,
            unit: String(localized: "kg"),
            keyboard: .decimalPad,
            onStep: { draft.weightText = SetDraft.steppedWeightText(draft.weightText, by: $0) },
            focus: focus,
            field: .weight,
            isInvalid: draft.weightProblem() != nil,
            prompt: lastWeightPrompt,
            accessibilityLabel: String(localized: "Weight in kilograms")
        )
    }

    private var repsLeftField: some View {
        StepperField(
            title: exercise.isUnilateral ? String(localized: "Reps L") : String(localized: "Reps"),
            text: $draft.repsText,
            keyboard: .numberPad,
            onStep: { draft.repsText = SetDraft.steppedRepsText(draft.repsText, by: $0) },
            focus: focus,
            field: .repsLeft,
            prompt: SetDraft.repsText(fromReps: exercise.lastEntry?.reps),
            accessibilityLabel: exercise.isUnilateral
                ? String(localized: "Repetitions left side")
                : String(localized: "Repetitions")
        )
    }

    private var repsRightField: some View {
        StepperField(
            title: String(localized: "Reps R"),
            text: $draft.repsRightText,
            keyboard: .numberPad,
            onStep: { draft.repsRightText = SetDraft.steppedRepsText(draft.repsRightText, by: $0) },
            focus: focus,
            field: .repsRight,
            prompt: SetDraft.repsText(fromReps: exercise.lastEntry?.repsRight),
            accessibilityLabel: String(localized: "Repetitions right side")
        )
    }

    // MARK: - Derived

    private var isValid: Bool {
        draft.isComplete(isUnilateral: exercise.isUnilateral)
    }

    /// "BW" when the last set was bodyweight or there is no history: an empty
    /// weight field means bodyweight (PLAN.md section 2 "Units").
    private var lastWeightPrompt: String {
        guard let entry = exercise.lastEntry else { return String(localized: "BW") }
        let text = SetDraft.weightText(fromHalfKilos: entry.weightHalfKilos)
        return text.isEmpty ? String(localized: "BW") : text
    }

    private var weightProblemText: String? {
        switch draft.weightProblem() {
        case .weightNotHalfStep: String(localized: "Weight must be a multiple of 0.5 kg")
        case .weightOutOfRange: String(localized: "Weight must be between 0.5 and 500 kg")
        case .weightNotANumber: String(localized: "Weight is not a number")
        default: nil
        }
    }
}
