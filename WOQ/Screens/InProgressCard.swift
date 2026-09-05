import SwiftUI
import UIKit

/// The single in-progress exercise (PLAN.md sections 3.4 to 3.6 and 6).
///
/// Water shader background with the card outline drawn on top — the card fill
/// would hide the water, so the border is an overlay over a `ZStack` instead of
/// an `OutlinedCard`. The draft lives in `MainScreen` (`@State`, never
/// persisted, PLAN.md 3.4); this view only edits the binding and reports the
/// validated set back.
///
/// Revision after Marco's phone test (2026-09-05): the draft arrives *prefilled*
/// with the previous set (see `MainScreen.prefilledDraft(for:)`), so the fields
/// carry real values instead of grey placeholders, stepping starts from the last
/// numbers and the checkmark is enabled on sight — logging the same set again is
/// one tap. That made "Same as last time" redundant, so it is gone; the previous
/// set now reads as one muted line under the exercise name. The fields shrank to
/// fit on one row together with the checkmark.
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
        }
        .padding(Tokens.cardPadding)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 10) {
            // Decoration here: the muscles are read out on the detail sheet, and
            // VoiceOver should reach the name and the fields first.
            FigurePairView(tags: exercise.muscleTags, size: .thumbnail, palette: Tokens.figurePalette)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
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
                    }
                }

                // What the fields are prefilled with, so the numbers in the
                // boxes have a visible origin: "3 days ago · 40 kg × 10".
                Text(lastSetLine)
                    .font(Tokens.numberFont(.subheadline))
                    .foregroundStyle(Tokens.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            // One element that announces which exercise is in progress and what
            // the previous set was.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityTitle)
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            RoundIconButton(
                systemName: "arrow.uturn.backward",
                accessibilityLabel: String(localized: "Put back")
            ) {
                onPutBack()
            }
        }
    }

    /// Bilateral: `[Weight kg] [Reps] [✓]` on one row.
    ///
    /// Unilateral needs three fields, and three do not fit next to the
    /// checkmark: the card is 428 − 32 (screen padding) − 28 (lane) − 24 (card
    /// padding) = 344 pt wide, while 134 + 100 + 100 + 36 plus three 10 pt gaps
    /// is 400 pt. So the shared weight keeps the checkmark company on the first
    /// row and Reps L / Reps R sit underneath.
    @ViewBuilder
    private var fieldsRow: some View {
        if exercise.isUnilateral {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 10) {
                    weightField
                    Spacer(minLength: 0)
                    checkmark
                }
                HStack(alignment: .bottom, spacing: 10) {
                    repsLeftField
                    repsRightField
                    Spacer(minLength: 0)
                }
            }
        } else {
            HStack(alignment: .bottom, spacing: 10) {
                weightField
                repsLeftField
                Spacer(minLength: 0)
                checkmark
            }
        }
    }

    /// Bottom-aligned with the 44 pt input boxes and nudged up by (44 − 36) / 2,
    /// so the circle is centred on the boxes and not on the boxes plus their
    /// caption labels.
    private var checkmark: some View {
        CheckmarkButton(isEnabled: isValid) {
            guard case .success(let set) = draft.validate(isUnilateral: exercise.isUnilateral) else { return }
            onFinalize(set)
        }
        .padding(.bottom, (CompactStepperField<Field>.boxHeight - 36) / 2)
    }

    // MARK: - Fields

    private var weightField: some View {
        CompactStepperField(
            title: String(localized: "Weight"),
            text: $draft.weightText,
            fieldWidth: 56,
            unit: String(localized: "kg"),
            keyboard: .decimalPad,
            onStep: { draft.weightText = SetDraft.steppedWeightText(draft.weightText, by: $0) },
            focus: focus,
            field: .weight,
            isInvalid: draft.weightProblem() != nil,
            accessibilityLabel: String(localized: "Weight in kilograms")
        )
    }

    private var repsLeftField: some View {
        CompactStepperField(
            title: exercise.isUnilateral ? String(localized: "Reps L") : String(localized: "Reps"),
            text: $draft.repsText,
            fieldWidth: 44,
            keyboard: .numberPad,
            onStep: { draft.repsText = SetDraft.steppedRepsText(draft.repsText, by: $0) },
            focus: focus,
            field: .repsLeft,
            accessibilityLabel: exercise.isUnilateral
                ? String(localized: "Repetitions left side")
                : String(localized: "Repetitions")
        )
    }

    private var repsRightField: some View {
        CompactStepperField(
            title: String(localized: "Reps R"),
            text: $draft.repsRightText,
            fieldWidth: 44,
            keyboard: .numberPad,
            onStep: { draft.repsRightText = SetDraft.steppedRepsText(draft.repsRightText, by: $0) },
            focus: focus,
            field: .repsRight,
            accessibilityLabel: String(localized: "Repetitions right side")
        )
    }

    // MARK: - Derived

    /// "3 days ago · 40 kg × 10", or "First time" when there is no history.
    private var lastSetLine: String {
        guard let entry = exercise.lastEntry else { return String(localized: "First time") }
        let when = Formatting.relativeDayString(from: entry.date)
        return "\(when) \u{00B7} \(Formatting.setString(for: entry))"
    }

    /// "Bench press, in progress, last set 3 days ago, 40 kg × 10" — the card's
    /// state and the numbers the fields start from, spoken before the fields.
    private var accessibilityTitle: String {
        let name = exercise.isUnilateral
            ? String(localized: "\(exercise.name), in progress, left and right separately")
            : String(localized: "\(exercise.name), in progress")
        guard let entry = exercise.lastEntry else {
            return String(localized: "\(name), first time")
        }
        let when = Formatting.relativeDayString(from: entry.date)
        return String(localized: "\(name), last set \(when), \(Formatting.setString(for: entry))")
    }

    private var isValid: Bool {
        draft.isComplete(isUnilateral: exercise.isUnilateral)
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

/// The in-progress card's own narrow stepper field.
///
/// `StepperField` (used by the add sheet and the gallery) sizes its text field
/// with `maxWidth: .infinity` and gives each stepper button a 44 pt *visual*
/// box, which is right for a full-width form but leaves no room for weight,
/// reps and the checkmark on one card row. This variant fixes the text field
/// width (56 pt for a weight like "22.5", 44 pt for reps) and draws the buttons
/// 28 pt wide while keeping a 44 pt tap target through an outset content shape.
/// No placeholder prompt: the draft arrives prefilled, so grey ghost numbers
/// would only compete with the real ones.
private struct CompactStepperField<Field: Hashable>: View {
    /// Height of the outlined box; the caption sits above it.
    static var boxHeight: CGFloat { 44 }
    /// Drawn width of a minus / plus button.
    private static var buttonWidth: CGFloat { 28 }
    /// Outset that brings the tap target back to 44 pt.
    private static var buttonSlop: CGFloat { (44 - buttonWidth) / 2 }

    var title: String
    @Binding var text: String
    var fieldWidth: CGFloat
    var unit: String?
    var keyboard: UIKeyboardType
    var onStep: (Int) -> Void
    var focus: FocusState<Field?>.Binding
    var field: Field
    var isInvalid: Bool = false
    var accessibilityLabel: String

    init(
        title: String,
        text: Binding<String>,
        fieldWidth: CGFloat,
        unit: String? = nil,
        keyboard: UIKeyboardType,
        onStep: @escaping (Int) -> Void,
        focus: FocusState<Field?>.Binding,
        field: Field,
        isInvalid: Bool = false,
        accessibilityLabel: String
    ) {
        self.title = title
        self._text = text
        self.fieldWidth = fieldWidth
        self.unit = unit
        self.keyboard = keyboard
        self.onStep = onStep
        self.focus = focus
        self.field = field
        self.isInvalid = isInvalid
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Tokens.muted)

            HStack(spacing: 0) {
                stepButton(
                    systemName: "minus",
                    delta: -1,
                    label: String(localized: "Decrease \(accessibilityLabel)")
                )

                TextField("", text: $text)
                    .font(Tokens.numberFont(.body))
                    .multilineTextAlignment(.center)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Tokens.ink)
                    .tint(Tokens.ink)
                    .focused(focus, equals: field)
                    .frame(width: fieldWidth)
                    .accessibilityLabel(accessibilityLabel)

                if let unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(Tokens.muted)
                        .padding(.trailing, 2)
                        .accessibilityHidden(true)
                }

                stepButton(
                    systemName: "plus",
                    delta: 1,
                    label: String(localized: "Increase \(accessibilityLabel)")
                )
            }
            .frame(height: Self.boxHeight)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(isInvalid ? Tokens.danger : Tokens.ink, lineWidth: Tokens.line)
            )
            .animation(.snappy, value: isInvalid)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func stepButton(systemName: String, delta: Int, label: String) -> some View {
        Button {
            onStep(delta)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Tokens.ink)
                .frame(width: Self.buttonWidth, height: Self.boxHeight)
                .contentShape(Rectangle().inset(by: -Self.buttonSlop))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
