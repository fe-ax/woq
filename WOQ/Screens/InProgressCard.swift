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
///
/// Revision 2026-09-12 (PLAN.md "Multi-set executions"): one visit to the card
/// can log several sets. The punched plus next to the checkmark commits the
/// current fields as set N and leaves the numbers in place for set N+1; the
/// committed sets are listed above the fields, each with a small × that takes it
/// back. The checkmark takes the fields as the last set and hands the whole list
/// to `MainScreen`, which writes it as ONE execution — so a session is one store
/// write and one debounced backup, and the pending list is view state that a
/// put-back keeps and a quit loses (same rule as the fields, PLAN.md 3.4/3.6).
/// The card's muted line and the queue rows therefore show the execution's peak
/// plus its set count ("3 days ago · 80 kg × 10 · 3 sets").
struct InProgressCard: View {
    /// Focus chain for the keyboard toolbar (PLAN.md pitfall 5). The `Done` /
    /// `Next` toolbar lives in `MainScreen`, which owns the `@FocusState`.
    enum Field: Hashable {
        case weight
        case repsLeft
        case repsRight
    }

    /// Height of an outlined input box; the caption label sits above it.
    /// `SetBranchOverlay` needs it to centre the dashed node on the box.
    static let fieldBoxHeight: CGFloat = 44

    /// Space in front of the pending rows and the fields row that the set branch
    /// runs in (PLAN.md section 2, "Set branch"): the 12 pt nodes take its first
    /// 12 pt, the stripe runs down their centre. Always reserved: the branch is
    /// visible from the moment the exercise is in progress (Marco's phone
    /// feedback, 2026-09-12 — at first it only appeared with the first pending
    /// set, and the fields slid aside for it), with the dashed node on the
    /// fields row as its only node until the first plus.
    static let branchGutter: CGFloat = 16

    /// x of the branch stripe in the in-progress *section*'s coordinates: the
    /// card starts after the lane column (28), its own padding (12) is next, and
    /// the node's centre is half a node (6) further — 46 pt, the centre of the
    /// gutter's node column.
    static let branchX: CGFloat = Tokens.laneColumn + Tokens.cardPadding + Tokens.node / 2

    /// Distance from the top of the section to the centre of the lane node
    /// (`LaneColumn.NodePlacement.top`): the card's own 5 pt of row spacing, its
    /// 12 pt padding and half of the 48 pt thumbnail. The header row is `.top`
    /// aligned, so the thumbnail's centre does not move when the card grows —
    /// the branch always forks off the node next to the exercise name.
    static let laneNodeInset: CGFloat = Tokens.rowSpacing / 2 + Tokens.cardPadding + 24

    var exercise: Exercise
    @Binding var draft: SetDraft
    /// Sets already committed with the plus, in the order they were logged.
    /// Owned by `MainScreen` (`CardDraft.pending`); this view only lists them.
    var pendingSets: [PendingSet]
    var focus: FocusState<Field?>.Binding
    var onPutBack: () -> Void
    /// The fields validate and the plus was tapped: `MainScreen` turns the
    /// current `draft` into a `PendingSet` (the card never builds one itself, so
    /// the draft stays the single source of truth for the fields).
    var onAddSet: () -> Void
    var onRemovePendingSet: (PendingSet.ID) -> Void
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

            if !pendingSets.isEmpty {
                pendingList
            }

            fieldsRow
                .padding(.leading, Self.branchGutter)

            if let problem = weightProblemText {
                Text(problem)
                    .font(.caption)
                    .foregroundStyle(Tokens.danger)
                    .accessibilityAddTraits(.isStaticText)
                    .padding(.leading, Self.branchGutter)
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

    /// The sets committed with the plus so far, newest at the bottom: the list
    /// grows downwards towards the fields the next set is typed in.
    ///
    /// Numbering is by position, not by any stored index — removing set 1 of
    /// three renumbers the rest, exactly like the detail sheet will after the
    /// execution is written. `ForEach` is keyed on `PendingSet.id` (a fresh UUID
    /// per row) so two identical sets stay two rows.
    private var pendingList: some View {
        VStack(spacing: 6) {
            ForEach(Array(pendingSets.enumerated()), id: \.element.id) { index, pending in
                pendingRow(number: index + 1, pending: pending)
            }
        }
    }

    private func pendingRow(number: Int, pending: PendingSet) -> some View {
        let numberText = "\(number)"
        let setText = Formatting.setString(
            weightHalfKilos: pending.set.weightHalfKilos,
            reps: pending.set.reps,
            repsRight: pending.set.repsRight
        )

        return HStack(spacing: 8) {
            // Fixed, trailing-aligned width so "1" and "10" share a right edge
            // and the set strings stay in one column.
            Text(numberText)
                .font(Tokens.numberFont(.subheadline))
                .foregroundStyle(Tokens.muted)
                .frame(width: 16, alignment: .trailing)

            // No `minimumScaleFactor` here: a row that is inserted with the
            // move transition keeps the scale it was measured with mid-animation
            // until something else relays it out, so the newest row rendered
            // smaller than its siblings (seen with three pending sets). The
            // set string is short and the row has ~250 pt for it.
            Text(setText)
                .font(Tokens.numberFont(.subheadline))
                .foregroundStyle(Tokens.ink)
                .lineLimit(1)

            Spacer(minLength: 0)

            RoundIconButton(
                systemName: "xmark",
                diameter: 24,
                accessibilityLabel: String(localized: "Remove set \(numberText)")
            ) {
                onRemovePendingSet(pending.id)
            }
        }
        // One element per set: VoiceOver should hear "Set 1, 40 kg × 10" and
        // reach the × as an action, not as a separate unlabelled stop.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Set \(numberText), \(setText)"))
        .accessibilityAction(named: Text(String(localized: "Remove"))) {
            onRemovePendingSet(pending.id)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .padding(.leading, Self.branchGutter)
        // The overlay puts this set's node on the row's vertical centre.
        .setBranchAnchor(.set(pending.id))
    }

    /// Bilateral: `[Weight kg] [Reps] [+] [✓]` on one row — 130 + 96 + 36 + 36
    /// plus the 10 / 6 / 10 pt gaps is 324 pt.
    ///
    /// The card is 428 − 32 (screen padding) − 28 (lane) − 24 (card padding) =
    /// 344 pt wide, and the set branch takes 16 of those (`branchGutter`), so
    /// the row has to live in 328. It used to need all 344, so three things
    /// gave: the `Spacer` between the reps and the buttons is gone (the buttons
    /// push themselves to the trailing edge instead, which drops one 10 pt
    /// `HStack` gap), the two buttons sit 6 pt apart instead of 8, and the
    /// stepper buttons are 26 pt wide instead of 28 — a 44 pt tap target either
    /// way, since `CompactStepperField` outsets their content shape.
    ///
    /// Unilateral needs three fields, and three never fit next to the buttons
    /// (130 + 96 + 96 + 78 plus gaps), so the shared weight keeps the buttons
    /// company on the first row and Reps L / Reps R sit underneath.
    @ViewBuilder
    private var fieldsRow: some View {
        if exercise.isUnilateral {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 10) {
                    weightField
                    actionButtons
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                // The branch's dashed node belongs on the *weight* box: it is the
                // row the plus and the checkmark act on.
                .setBranchAnchor(.current)

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
                actionButtons
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .setBranchAnchor(.current)
        }
    }

    /// `[+] [✓]`: add this set and stay, or add this set and finish. 6 pt apart
    /// (closer than the 10 pt field gaps, so they read as one pair), bottom-
    /// aligned with the 44 pt input boxes and nudged up by (44 − 36) / 2 so the
    /// circles are centred on the boxes and not on the boxes plus their caption
    /// labels.
    private var actionButtons: some View {
        HStack(spacing: 6) {
            addSetButton
            checkmark
        }
        .padding(.bottom, (Self.fieldBoxHeight - 36) / 2)
    }

    /// Commits the fields as a pending set. Validated here as well as in
    /// `MainScreen` — the button is disabled while the draft is incomplete, but
    /// the guard keeps the two paths (plus and checkmark) symmetrical.
    private var addSetButton: some View {
        AddSetButton(isEnabled: isValid) {
            guard case .success = draft.validate(isUnilateral: exercise.isUnilateral) else { return }
            onAddSet()
        }
    }

    private var checkmark: some View {
        CheckmarkButton(isEnabled: isValid) {
            guard case .success(let set) = draft.validate(isUnilateral: exercise.isUnilateral) else { return }
            onFinalize(set)
        }
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

    /// "3 days ago · 40 kg × 10 · 3 sets", or "First time" when there is no history.
    private var lastSetLine: String {
        guard let execution = exercise.lastExecution else { return String(localized: "First time") }
        let when = Formatting.relativeDayString(from: execution.date)
        return "\(when) \u{00B7} \(Formatting.executionString(peak: execution.peak, setCount: execution.setCount))"
    }

    /// "Bench press, in progress, last time 3 days ago, 80 kg × 10, 3 sets" —
    /// the card's state and the numbers the fields start from, spoken before the
    /// fields. Same content as `lastSetLine`, but with commas instead of the
    /// middle dot, which VoiceOver reads as "middle dot".
    private var accessibilityTitle: String {
        let name = exercise.isUnilateral
            ? String(localized: "\(exercise.name), in progress, left and right separately")
            : String(localized: "\(exercise.name), in progress")
        guard let execution = exercise.lastExecution else {
            return String(localized: "\(name), first time")
        }
        let when = Formatting.relativeDayString(from: execution.date)
        let set = Formatting.setString(for: execution.peak)
        let count = Formatting.setCountString(execution.setCount)
        return String(localized: "\(name), last time \(when), \(set), \(count)")
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
/// 26 pt wide while keeping a 44 pt tap target through an outset content shape.
/// No placeholder prompt: the draft arrives prefilled, so grey ghost numbers
/// would only compete with the real ones.
private struct CompactStepperField<Field: Hashable>: View {
    /// Height of the outlined box; the caption sits above it.
    static var boxHeight: CGFloat { InProgressCard.fieldBoxHeight }
    /// Drawn width of a minus / plus button. 26 rather than 28 buys the 4 pt per
    /// field the set branch's gutter needs; the outset content shape below keeps
    /// the tap target at 44 pt.
    private static var buttonWidth: CGFloat { 26 }
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
