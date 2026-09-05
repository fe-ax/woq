import SwiftUI

/// Add / edit an exercise. INTERFACE CONTRACT fixed by the orchestrator; the sheets agent replaces the body.
/// - `.add`: name, unilateral toggle, muscle chips with live figure, optional first set; Save calls
///   `store.addExercise(...)` and then `onAdded` with the result so MainScreen can carry a partial draft
///   into the in-progress card when the outcome is `.startedInProgress`.
/// - `.edit(exercise)`: same fields without the first-set section; Save calls `store.updateExercise(...)`.
///
/// The sheet copies the edited exercise into local `@State` once and writes back only on Save
/// (PLAN.md pitfall 19). No system navigation bar: the bar is hidden and a custom header row carries
/// Cancel / Save, so no Liquid Glass appears (PLAN.md pitfall 7 and 29).
struct ExerciseFormSheet: View {
    enum Mode {
        case add
        case edit(Exercise)
    }

    struct AddResult {
        let exercise: Exercise
        let outcome: QueueStore.FirstSetOutcome
        let draft: SetDraft
    }

    var mode: Mode
    var onAdded: ((AddResult) -> Void)? = nil

    @Environment(QueueStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var isUnilateral = false
    @State private var tags: [MuscleTag] = []
    /// Add mode only; ignored while editing.
    @State private var firstSet = SetDraft()
    /// Guards the one-time copy in `onAppear`.
    @State private var didLoad = false

    private enum Field: Hashable {
        case name
        case weight
        case reps
        case repsRight
    }

    @FocusState private var focus: Field?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Tokens.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    figureBlock
                    Rectangle()
                        .fill(Tokens.ink)
                        .frame(height: Tokens.hairline)
                    form
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            // Paper bar above the number pads, which have no return key
            // (PLAN.md pitfall 5). The name field keeps its own return key.
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
        .presentationBackground(Tokens.paper)
        .presentationDragIndicator(.visible)
        .onAppear(perform: loadOnce)
    }

    // MARK: - Header

    private var header: some View {
        SheetHeaderBar(title: title) {
            Button(String(localized: "Cancel")) { dismiss() }
                .buttonStyle(.paper)
            Button(String(localized: "Save"), action: save)
                .buttonStyle(.ink)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.4)
        }
    }

    private var title: String {
        isAdd ? String(localized: "New exercise") : String(localized: "Edit exercise")
    }

    /// Pinned above the scrolling form so the highlights follow every chip tap.
    private var figureBlock: some View {
        FigurePairView(tags: tags, size: .large, palette: Tokens.figurePalette)
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                nameField
                unilateralToggle

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle(String(localized: "Muscles"))
                    MuscleTagList(tags: $tags)
                }

                if isAdd {
                    firstSetSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Name"))
                .font(.caption)
                .foregroundStyle(Tokens.muted)

            TextField("", text: $name)
                .font(.body)
                .foregroundStyle(Tokens.ink)
                .tint(Tokens.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focus, equals: .name)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .fill(Tokens.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .strokeBorder(isDuplicateName ? Tokens.danger : Tokens.ink, lineWidth: Tokens.line)
                )
                .accessibilityLabel(String(localized: "Exercise name"))

            if isDuplicateName {
                Text(String(localized: "An exercise with this name already exists"))
                    .font(.caption)
                    .foregroundStyle(Tokens.danger)
            }
        }
    }

    private var unilateralToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(String(localized: "Left and right separately"), isOn: $isUnilateral)
                .font(.body)
                .foregroundStyle(Tokens.ink)
                .tint(Tokens.ink)

            Text(String(localized: "Log reps for each side, shared weight"))
                .font(.caption)
                .foregroundStyle(Tokens.muted)
        }
    }

    private var firstSetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(String(localized: "First set (optional)"))

            HStack(alignment: .top, spacing: 12) {
                StepperField(
                    title: String(localized: "Weight"),
                    text: $firstSet.weightText,
                    unit: String(localized: "kg"),
                    keyboard: .decimalPad,
                    onStep: { step in
                        firstSet.weightText = SetDraft.steppedWeightText(firstSet.weightText, by: step)
                    },
                    focus: $focus,
                    field: .weight,
                    isInvalid: weightProblem != nil,
                    accessibilityLabel: String(localized: "Weight in kilograms")
                )

                StepperField(
                    title: isUnilateral ? String(localized: "Reps L") : String(localized: "Reps"),
                    text: $firstSet.repsText,
                    keyboard: .numberPad,
                    onStep: { step in
                        firstSet.repsText = SetDraft.steppedRepsText(firstSet.repsText, by: step)
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
                        text: $firstSet.repsRightText,
                        keyboard: .numberPad,
                        onStep: { step in
                            firstSet.repsRightText = SetDraft.steppedRepsText(firstSet.repsRightText, by: step)
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

            Text(String(localized: "Fill in a set to log it now; leave empty to start the exercise"))
                .font(.caption)
                .foregroundStyle(Tokens.muted)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.headline, weight: .bold))
            .foregroundStyle(Tokens.ink)
    }

    // MARK: - State

    private var editedExercise: Exercise? {
        if case .edit(let exercise) = mode { return exercise }
        return nil
    }

    private var isAdd: Bool { editedExercise == nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Only complains once something has been typed (PLAN.md 3.10).
    private var isDuplicateName: Bool {
        !trimmedName.isEmpty && !store.isNameAvailable(name, excluding: editedExercise)
    }

    /// Add mode only: the inline red hint under the weight field.
    private var weightProblem: DraftProblem? {
        isAdd ? firstSet.weightProblem() : nil
    }

    /// A partially filled first set is allowed — it becomes the in-progress draft.
    /// A weight that cannot be logged is not.
    private var canSave: Bool {
        !trimmedName.isEmpty && !isDuplicateName && weightProblem == nil
    }

    // MARK: - Focus chain (PLAN.md pitfall 5)

    /// The accessory bar belongs to the number pads only.
    private var isNumericFieldFocused: Bool {
        switch focus {
        case .weight, .reps, .repsRight: true
        case .name, .none: false
        }
    }

    /// The R field is skipped for a bilateral exercise.
    private var canFocusNext: Bool {
        switch focus {
        case .weight: true
        case .reps: isUnilateral
        case .repsRight, .name, .none: false
        }
    }

    private func focusNext() {
        switch focus {
        case .weight: focus = .reps
        case .reps: focus = isUnilateral ? .repsRight : nil
        case .repsRight, .name, .none: focus = nil
        }
    }

    private func loadOnce() {
        guard !didLoad else { return }
        didLoad = true
        guard let exercise = editedExercise else { return }
        name = exercise.name
        isUnilateral = exercise.isUnilateral
        tags = exercise.muscleTags
    }

    private func save() {
        guard canSave else { return }
        focus = nil

        if let exercise = editedExercise {
            store.updateExercise(
                exercise,
                name: trimmedName,
                isUnilateral: isUnilateral,
                tags: tags
            )
        } else {
            let (exercise, outcome) = store.addExercise(
                name: trimmedName,
                isUnilateral: isUnilateral,
                tags: tags,
                firstSet: firstSet.isEmpty ? nil : firstSet
            )
            onAdded?(AddResult(exercise: exercise, outcome: outcome, draft: firstSet))
        }

        dismiss()
    }
}

// MARK: - Shared sheet chrome

/// Header row of every sheet: title left, action buttons right. Replaces the
/// navigation bar, which stays hidden so iOS 26 cannot put glass on it
/// (PLAN.md pitfall 7 and 29).
struct SheetHeaderBar<Trailing: View>: View {
    var title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(Tokens.titleFont)
                .foregroundStyle(Tokens.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 8)

            // The buttons keep their intrinsic width at every Dynamic Type
            // size — without this "Cancel" hyphenates onto two lines at XXXL.
            // The title shrinks instead.
            HStack(spacing: 8) { trailing }
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

/// Inline hints for an invalid set field, shared by the form sheet and the entry
/// editor. Every string goes through `String(localized:)` (PLAN.md pitfall 22).
enum SetFieldHint {
    static func text(for problem: DraftProblem) -> String {
        switch problem {
        case .weightNotHalfStep:
            String(localized: "Weight goes in steps of 0.5 kg")
        case .weightOutOfRange:
            String(localized: "Weight must be between 0.5 and 500 kg")
        case .weightNotANumber:
            String(localized: "Weight must be a number, or empty for bodyweight")
        case .repsMissing:
            String(localized: "Reps are required")
        case .repsRightMissing:
            String(localized: "Reps for the right side are required")
        case .repsInvalid:
            String(localized: "Reps must be a whole number from 1 to 999")
        }
    }
}
