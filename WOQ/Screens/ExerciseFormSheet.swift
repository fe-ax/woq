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
///
/// Add mode has a second face: the switch button next to the title (or a tap on the title)
/// flips the sheet to the preset list, where several ready-made exercises can be ticked and
/// added to the queue at once through `QueueStore.addExercises(_:)`. The header and the figure
/// stay put across the switch; only the part under the hairline slides.
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
    /// Add mode only: called once after the preset list added `count` exercises to the
    /// queue (never performed, nothing started). MainScreen shows a hint with the count.
    var onAddedPresets: ((Int) -> Void)? = nil
    /// Add mode only: opens straight on the preset list. Used by `--preview presets`.
    var startsInPresetMode = false

    @Environment(QueueStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var isUnilateral = false
    @State private var tags: [MuscleTag] = []
    /// Add mode only; ignored while editing.
    @State private var firstSet = SetDraft()
    /// Guards the one-time copy in `onAppear`.
    @State private var didLoad = false

    /// Add mode only: false = the form, true = the preset list.
    @State private var showsPresets = false
    /// Ticked preset ids (= names). Survives switching back to the form; Cancel drops it.
    @State private var selectedPresets: Set<String> = []
    /// `nameKey`s already in the store, read when the preset list appears so its rows can
    /// show "Added" without one fetch per row.
    @State private var takenNameKeys: Set<String> = []

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
                    pages
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

    /// Form and preset list overlap in a `ZStack` so the one sliding out does not push
    /// the other down for the length of the transition.
    @ViewBuilder
    private var pages: some View {
        ZStack(alignment: .top) {
            if showsPresets {
                PresetListView(selection: $selectedPresets, takenNameKeys: takenNameKeys)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
            } else {
                form
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if isAdd {
            // The title is a switch target too (`onTitleTap`), next to the switch button.
            SheetHeaderBar(
                title: title,
                onTitleTap: toggleMode,
                leading: { switchButton },
                trailing: { trailingButtons }
            )
            .accessibilityHint(switchHint)
        } else {
            SheetHeaderBar(title: title) { trailingButtons }
        }
    }

    @ViewBuilder
    private var trailingButtons: some View {
        Button(String(localized: "Cancel")) { dismiss() }
            .buttonStyle(.paper)

        if showsPresets {
            Button(addPresetsTitle, action: addSelectedPresets)
                .buttonStyle(.ink)
                .disabled(selectedPresets.isEmpty)
                .opacity(selectedPresets.isEmpty ? 0.4 : 1)
        } else {
            Button(String(localized: "Save"), action: save)
                .buttonStyle(.ink)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.4)
        }
    }

    /// 32 pt outlined circle, 44 pt hit area — `RoundIconButton`'s look, but this one
    /// carries the mode instead of an action glyph. The negative padding gives the 12 pt
    /// the hit area sticks out back to the title; the taps overlap on the title, which
    /// switches too.
    private var switchButton: some View {
        Button(action: toggleMode) {
            Image(systemName: "arrow.2.squarepath")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Tokens.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Tokens.card))
                .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.hairline))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .padding(.horizontal, -6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            showsPresets
                ? String(localized: "Switch to the new exercise form")
                : String(localized: "Switch to the preset list")
        )
    }

    private var switchHint: String {
        showsPresets
            ? String(localized: "Switches back to the new exercise form")
            : String(localized: "Switches to the preset list")
    }

    private var title: String {
        if showsPresets { return String(localized: "Presets") }
        return isAdd ? String(localized: "New exercise") : String(localized: "Edit exercise")
    }

    /// "Add" with nothing ticked, "Add 3" from one onwards.
    private var addPresetsTitle: String {
        selectedPresets.isEmpty
            ? String(localized: "Add")
            : String(localized: "Add \(selectedPresets.count)")
    }

    /// Pinned above the scrolling form so the highlights follow every chip tap. In preset
    /// mode it shows the union of the ticked presets, so the figure fills up while ticking.
    private var figureBlock: some View {
        FigurePairView(
            tags: showsPresets ? selectedPresetTags : tags,
            size: .large,
            palette: Tokens.figurePalette
        )
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
                .appFont(.caption)
                .foregroundStyle(Tokens.muted)

            TextField("", text: $name)
                .appFont(.body)
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
                    .appFont(.caption)
                    .foregroundStyle(Tokens.danger)
            }
        }
    }

    private var unilateralToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(String(localized: "Left and right separately"), isOn: $isUnilateral)
                .appFont(.body)
                .foregroundStyle(Tokens.ink)
                .tint(Tokens.ink)

            Text(String(localized: "Log reps for each side, shared weight"))
                .appFont(.caption)
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
                    .appFont(.caption)
                    .foregroundStyle(Tokens.danger)
            }

            Text(String(localized: "Fill in a set to log it now; leave empty to start the exercise"))
                .appFont(.caption)
                .foregroundStyle(Tokens.muted)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appFont(.headline, weight: .bold)
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

        if let exercise = editedExercise {
            name = exercise.name
            isUnilateral = exercise.isUnilateral
            tags = exercise.muscleTags
            return
        }

        if startsInPresetMode {
            takenNameKeys = store.existingNameKeys()
            showsPresets = true
        }
    }

    // MARK: - Presets (add mode only)

    /// The switch button and the title share this. Editing never switches.
    private func toggleMode() {
        guard isAdd else { return }
        focus = nil
        if !showsPresets {
            // Refreshed on every entry: an exercise may have been added since the sheet opened.
            takenNameKeys = store.existingNameKeys()
        }
        withAnimation(.snappy) {
            showsPresets.toggle()
        }
    }

    /// Union of the ticked presets, keeping the highest intensity per muscle, in
    /// `Muscle.allCases` order — the figure treats it like any other tag list.
    private var selectedPresetTags: [MuscleTag] {
        var byMuscle: [Muscle: Intensity] = [:]
        for preset in ExercisePresets.all where selectedPresets.contains(preset.id) {
            for tag in preset.tags {
                if let current = byMuscle[tag.muscle] {
                    byMuscle[tag.muscle] = max(current, tag.intensity)
                } else {
                    byMuscle[tag.muscle] = tag.intensity
                }
            }
        }
        return Muscle.allCases.compactMap { muscle in
            byMuscle[muscle].map { MuscleTag(muscle: muscle, intensity: $0) }
        }
    }

    /// Adds every ticked preset in one go (never performed, nothing started — see
    /// `QueueStore.addExercises(_:)`) and hands MainScreen the count for its hint.
    private func addSelectedPresets() {
        let chosen = ExercisePresets.all.filter { selectedPresets.contains($0.id) }
        guard !chosen.isEmpty else { return }

        let added = store.addExercises(chosen)
        if !added.isEmpty {
            onAddedPresets?(added.count)
        }
        dismiss()
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

// `SheetHeaderBar` lives in Design/Components/SheetHeaderBar.swift.

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
