import SwiftData
import SwiftUI

/// The queue (PLAN.md sections 3 and 6): custom header, search, the single
/// in-progress card on the blue lane and the queue rows on the yellow lane.
///
/// No `NavigationStack`, no system bars and no `List` (PLAN.md pitfalls 3 and
/// 7): rows carry custom backgrounds, a shader and text fields, and any system
/// bar would bring Liquid Glass with it. Every mutation goes through
/// `QueueStore` inside `withAnimation(.snappy)`, so the `@Query` re-sort
/// animates rows between the sections (pitfall 18).
struct MainScreen: View {
    @Environment(QueueStore.self) private var store
    @Environment(BackupFolder.self) private var backupFolder

    @Query(sort: QueueStore.sortDescriptors, animation: .snappy)
    private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var detailExercise: Exercise?

    /// The app menu (long-press the title), which holds the backup settings.
    @State private var showMenu = false
    /// Drives the shared folder picker / restore prompt for the banner (`BackupSetupFlow`).
    @State private var showsFolderPicker = false
    @State private var restoreCheckToken = 0
    /// Mirrors `BackupBanner.isSnoozed()` so tapping "Later" hides the card at once.
    @State private var isBannerSnoozed = false

    /// Muscle filter (PLAN.md section 2, "Search"). View state only: never
    /// persisted, and it never touches the store, so opening the panel or
    /// changing the selection cannot disturb an in-progress draft.
    @State private var selectedMuscles: Set<Muscle> = []
    @State private var showMusclePanel = false
    /// The search row lives behind the header's glass button (PLAN.md section 2,
    /// "Search"). Closing it clears the whole filter, so nothing invisible can
    /// keep hiding queue rows.
    @State private var showSearch = false

    /// Everything the in-progress card holds: the fields being typed plus the
    /// sets already committed with its plus button (PLAN.md "Multi-set
    /// executions", 2026-09-12). View state only, rebuilt whenever the
    /// in-progress exercise changes and never persisted (PLAN.md 3.4). The
    /// fields start as a copy of the previous execution's peak set
    /// (`prefilledDraft(for:)`), so the numbers Marco is about to repeat are
    /// already there; the pending list starts empty and is written to the store
    /// as one execution by the checkmark.
    @State private var card = CardDraft()
    /// Draft handed over by the add sheet; applied when the `@Query` catches up
    /// and the in-progress exercise actually changes.
    @State private var pendingDraft: CardDraft?
    /// Cards of exercises that were put back (PLAN.md section 2, "Drafts
    /// (changed)", extended 2026-09-12 to the pending sets). Restored when the
    /// same exercise is started again, dropped on finalize. In memory only:
    /// never persisted, lost on quit. An entry for a deleted exercise is simply
    /// never looked up again.
    @State private var keptDrafts: [UUID: CardDraft] = [:]

    @State private var hint: String?
    @State private var flashExerciseID: UUID?

    // Haptic triggers must be counters, not Bools (PLAN.md pitfall 14).
    @State private var startHapticCount = 0
    /// The plus on the card: a light tick per committed set, deliberately not
    /// the success haptic — nothing is stored until the checkmark.
    @State private var addSetHapticCount = 0
    @State private var successHapticCount = 0
    @State private var warningHapticCount = 0

    @FocusState private var focus: InProgressCard.Field?

    /// Identity of the in-progress row inside the `LazyVStack`, and the scroll
    /// target for `ScrollViewProxy`. It must NOT be the exercise's `id`: the
    /// same id in two structurally different children of one lazy stack makes
    /// SwiftUI keep the first view it built, so the started exercise kept
    /// rendering as a queue row.
    private static let inProgressID = "woq.inProgress"

    var body: some View {
        ZStack {
            Tokens.paper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                if showSearch {
                    SearchField(
                        text: $searchText,
                        isFilterActive: !selectedMuscles.isEmpty,
                        filterCount: selectedMuscles.count,
                        autofocus: true,
                        onFilterTap: { withAnimation(.snappy) { showMusclePanel.toggle() } }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showsBackupBanner {
                    BackupBanner(
                        onChoose: { showsFolderPicker = true },
                        onLater: {
                            BackupBanner.snooze()
                            withAnimation(.snappy) { isBannerSnoozed = true }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showMusclePanel {
                    MuscleFilterPanel(
                        selection: $selectedMuscles,
                        isPresented: $showMusclePanel
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                queueScroll
            }
        }
        .hintToast($hint)
        .sensoryFeedback(.impact(weight: .light), trigger: startHapticCount)
        .sensoryFeedback(.impact(weight: .light), trigger: addSetHapticCount)
        .sensoryFeedback(.success, trigger: successHapticCount)
        .sensoryFeedback(.warning, trigger: warningHapticCount)
        // `initial: true` covers the relaunch case: the app comes back with an
        // exercise still in progress and no `start(_:)` ever runs, so the
        // prefill has to happen on the first pass as well (PLAN.md 3.15).
        .onChange(of: inProgress?.id, initial: true) { _, _ in
            card = pendingDraft ?? CardDraft(fields: prefilledDraft(for: inProgress))
            pendingDraft = nil
            focus = nil
        }
        // Paper accessory bar for the number pads, which have no return key
        // (PLAN.md pitfall 5). Only while an in-progress field is focused, so
        // the search field keeps a plain keyboard. With the keyboard up the
        // bottom safe area sits above it, so the bar rides on the keyboard.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if focus != nil {
                KeyboardAccessoryBar(
                    showsNext: canFocusNext,
                    onNext: focusNext,
                    onDone: { focus = nil }
                )
            }
        }
        .animation(.snappy, value: focus)
        .sheet(isPresented: $showAddSheet) {
            ExerciseFormSheet(
                mode: .add,
                onAdded: handleAdded,
                onAddedPresets: { count in
                    // Automatic grammar agreement picks "exercise" / "exercises";
                    // only the AttributedString initializer parses the rule.
                    hint = String(
                        AttributedString(localized: "Added ^[\(count) exercise](inflect: true) to the queue")
                            .characters
                    )
                    successHapticCount += 1
                }
            )
        }
        .sheet(item: $detailExercise) { exercise in
            ExerciseDetailSheet(exercise: exercise)
        }
        .sheet(isPresented: $showMenu) {
            AppMenuSheet(onHint: { hint = $0 })
        }
        // The banner's "Choose folder" shares its picker and restore prompt with
        // the menu sheet (BackupSetupFlow in BackupBanner.swift).
        .backupSetupFlow(
            showsPicker: $showsFolderPicker,
            restoreCheckToken: $restoreCheckToken,
            onMessage: { hint = $0 },
            onRestored: { hint = $0 }
        )
        .task { isBannerSnoozed = BackupBanner.isSnoozed() }
        .animation(.snappy, value: showsBackupBanner)
    }

    /// PLAN.md section 2 "Backups": nudge Marco only when there is something to
    /// lose, no folder is configured yet, and he did not tap "Later" recently.
    private var showsBackupBanner: Bool {
        backupFolder.url == nil && !exercises.isEmpty && !isBannerSnoozed
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            title

            Spacer(minLength: 8)

            searchButton

            PunchedPlusButton {
                showAddSheet = true
            }
        }
    }

    /// Punched-out glass next to the plus. It turns blue while the filter bites,
    /// so a filtered queue is readable even with the row closed — which cannot
    /// happen, since closing the row clears the filter, but the colour is the
    /// state indicator while the row is open.
    private var searchButton: some View {
        PunchedIconButton(
            systemName: "magnifyingglass",
            fill: isFiltering ? Tokens.blue : Tokens.ink,
            strokes: isFiltering,
            accessibilityLabel: String(localized: "Search"),
            glyphSize: 20,
            action: toggleSearch
        )
        .accessibilityValue(
            isFiltering
                ? String(localized: "Filter active")
                : String(localized: "No filter")
        )
        .accessibilityAddTraits(showSearch ? [.isSelected] : [])
    }

    /// Opening only shows the row (the field takes the keyboard itself). Closing
    /// wipes the whole filter: text, muscles and the panel. Removing the field
    /// resigns the keyboard with it.
    private func toggleSearch() {
        withAnimation(.snappy) {
            if showSearch {
                showSearch = false
                searchText = ""
                selectedMuscles = []
                showMusclePanel = false
            } else {
                showSearch = true
            }
        }
    }

    /// Long-pressing the title opens `AppMenuSheet`: the settings menu with the
    /// Appearance and Backups pages (and Developer in DEBUG). In both
    /// configurations, so the settings are reachable in a release build too.
    private var title: some View {
        Text(String(localized: "Workout Queue"))
            .appTitleFont()
            .foregroundStyle(Tokens.ink)
            .accessibilityAddTraits(.isHeader)
            .onLongPressGesture(minimumDuration: 0.8) { showMenu = true }
    }

    // MARK: - Scroll content

    private var queueScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let inProgress {
                        inProgressSection(inProgress)
                    }

                    ForEach(queued, id: \.id) { exercise in
                        queueRow(exercise, proxy: proxy)
                    }

                    emptyState
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.hard, for: .top)
            .safeAreaPadding(.bottom)
            .onChange(of: focus) { _, newValue in
                guard newValue != nil, inProgress != nil else { return }
                withAnimation { proxy.scrollTo(Self.inProgressID, anchor: .top) }
            }
        }
    }

    /// The blue lane, the card and the set branch (PLAN.md section 2, "Set
    /// branch"): the lane node sits on the card's thumbnail row instead of the
    /// card's centre, so it stays put while pending sets make the card grow, and
    /// the branch overlay forks off it, runs down the card's gutter and merges
    /// back into the lane at the bottom of the section. The separator then
    /// carries the lane through the QUEUE rule and hands it to the yellow queue
    /// lane.
    private func inProgressSection(_ exercise: Exercise) -> some View {
        Group {
            HStack(alignment: .top, spacing: 0) {
                LaneColumn(
                    laneColor: Tokens.blue,
                    nodeStyle: .filled(Tokens.blue),
                    connectsUp: false,
                    connectsDown: true,
                    nodePlacement: .top(inset: InProgressCard.laneNodeInset)
                )

                InProgressCard(
                    exercise: exercise,
                    draft: $card.fields,
                    pendingSets: card.pending,
                    focus: $focus,
                    onPutBack: { putBack(exercise) },
                    onAddSet: { addSet(exercise) },
                    onRemovePendingSet: { removePendingSet($0) },
                    onFinalize: { set in finalize(exercise, with: set) }
                )
                .onLongPressGesture(minimumDuration: 0.4) { detailExercise = exercise }
            }
            // Before `.id`, so the section's identity in the lazy stack is
            // unchanged (pitfall 7).
            .setBranchOverlay(
                forkFrom: CGPoint(
                    x: Tokens.laneColumn / 2,
                    y: InProgressCard.laneNodeInset + Tokens.node / 2
                ),
                branchX: InProgressCard.branchX
            )
            .id(Self.inProgressID)

            // The bridge only continues lanes that exist: no yellow below the
            // rule when the queue is empty or filtered away.
            LaneSeparator(
                bridgeTop: Tokens.blue,
                bridgeBottom: queued.isEmpty ? nil : Tokens.yellow
            )
        }
    }

    private func queueRow(_ exercise: Exercise, proxy: ScrollViewProxy) -> some View {
        let index = queued.firstIndex { $0.id == exercise.id } ?? 0

        return HStack(alignment: .top, spacing: 0) {
            LaneColumn(
                laneColor: Tokens.yellow,
                nodeStyle: .outlined,
                connectsUp: index > 0 || inProgress != nil,
                connectsDown: index < queued.count - 1
            )

            ExerciseRow(
                exercise: exercise,
                isFlashing: flashExerciseID == exercise.id,
                onTap: { start(exercise, proxy: proxy) },
                onLongPress: { detailExercise = exercise }
            )
        }
        .id(exercise.id)
    }

    @ViewBuilder
    private var emptyState: some View {
        if ordered.isEmpty {
            VStack(spacing: 6) {
                Text(String(localized: "No exercises yet"))
                    .appFont(.title3)
                    .foregroundStyle(Tokens.ink)
                Text(String(localized: "Tap + to add your first exercise"))
                    .appFont(.subheadline)
                    .foregroundStyle(Tokens.muted)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, 120)
        } else if queued.isEmpty && isFiltering {
            VStack(spacing: 6) {
                Text(String(localized: "No matches"))
                    .appFont(.title3)
                    .foregroundStyle(Tokens.ink)
                Text(noMatchesDetail)
                    .appFont(.subheadline)
                    .foregroundStyle(Tokens.muted)
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.top, 60)
        }
    }

    // MARK: - Data

    /// Safety net for the `@Query` sort (PLAN.md 3.1 and pitfall 30).
    private var ordered: [Exercise] {
        QueueStore.ordered(exercises)
    }

    private var inProgress: Exercise? {
        store.inProgressExercise(in: exercises)
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFiltering: Bool {
        !query.isEmpty || !selectedMuscles.isEmpty
    }

    /// The queue section: everything except the in-progress exercise, filtered
    /// in memory. Search never hides the in-progress card and never reorders
    /// (PLAN.md 3.11 and pitfall 20).
    ///
    /// Text and muscles are ANDed; within the muscle filter the rule is ANY
    /// (an exercise matches when it tags at least one selected muscle, at any
    /// intensity). The text matches the name, the muscle names and the
    /// equipment tag.
    private var queued: [Exercise] {
        let inProgressID = inProgress?.id
        var base = ordered.filter { $0.id != inProgressID }

        if !query.isEmpty {
            base = base.filter {
                $0.nameKey.localizedStandardContains(query)
                    || $0.muscleSearchText.localizedStandardContains(query)
                    // The equipment tag searches too (2026-09-12): "dumbbell" finds every
                    // dumbbell exercise. Read off the enum rather than a denormalised
                    // column, because the tag is one short word per exercise.
                    || ($0.equipment?.displayName.localizedStandardContains(query) ?? false)
            }
        }

        if !selectedMuscles.isEmpty {
            base = base.filter { exercise in
                exercise.muscleTags.contains { selectedMuscles.contains($0.muscle) }
            }
        }

        return base
    }

    private var noMatchesDetail: String {
        switch (query.isEmpty, selectedMuscles.isEmpty) {
        case (false, false):
            String(localized: "Nothing matches \"\(query)\" in the selected muscles")
        case (false, true):
            String(localized: "Nothing matches \"\(query)\"")
        default:
            String(localized: "Nothing matches the selected muscles")
        }
    }

    // MARK: - Actions

    private func start(_ exercise: Exercise, proxy: ScrollViewProxy) {
        let result = withAnimation(.snappy) { store.start(exercise) }
        switch result {
        case .started:
            startHapticCount += 1
            // A card kept when this exercise was put back comes back with it,
            // pending sets and all.
            // It has to travel through `pendingDraft` as well, because the
            // `onChange(of: inProgress?.id)` below resets `card` afterwards.
            // Otherwise the previous set is copied in, so "one more set of the
            // same" is a single tap on the checkmark.
            let next = keptDrafts.removeValue(forKey: exercise.id)
                ?? CardDraft(fields: prefilledDraft(for: exercise))
            pendingDraft = next
            card = next
            focus = nil
            // The row only exists after this update, so scroll on the next turn.
            Task { withAnimation(.snappy) { proxy.scrollTo(Self.inProgressID, anchor: .top) } }
        case .refused(let current):
            hint = String(localized: "Finish or put back \(current.name) first")
            warningHapticCount += 1
        }
    }

    /// The card's plus (PLAN.md "Multi-set executions"): the current fields
    /// become set N of this execution and the list on the card grows, but
    /// nothing is stored yet — the checkmark writes the whole execution.
    ///
    /// The fields are left exactly as they are: the next set of the same
    /// exercise is usually the same numbers, so "3 × 40 kg × 10" is plus, plus,
    /// checkmark without typing. Focus drops so the list is visible above the
    /// keyboard and the just-added row is not hidden behind it.
    private func addSet(_ exercise: Exercise) {
        guard case .success(let set) = card.fields.validate(isUnilateral: exercise.isUnilateral) else { return }
        withAnimation(.snappy) { card.pending.append(PendingSet(set: set)) }
        focus = nil
        addSetHapticCount += 1
    }

    /// The × on a pending row. Removal is by id, never by position: the row
    /// numbers are display-only and shift as soon as one disappears.
    private func removePendingSet(_ id: PendingSet.ID) {
        withAnimation(.snappy) { card.pending.removeAll { $0.id == id } }
    }

    private func putBack(_ exercise: Exercise) {
        focus = nil
        // Half-typed numbers and committed sets survive the swap (PLAN.md
        // section 2, "Drafts (changed)"); an untouched card is not worth keeping
        // — and since the fields now start as a copy of the previous set,
        // "untouched" means "still equal to the prefill", which would otherwise
        // go stale if that entry were edited in the meantime. Pending sets are
        // always worth keeping: they are work Marco actually did.
        if !card.pending.isEmpty
            || (!card.fields.isEmpty && card.fields != prefilledDraft(for: exercise)) {
            keptDrafts[exercise.id] = card
        }
        withAnimation(.snappy) { store.putBack(exercise) }
        card = CardDraft()
    }

    /// The checkmark: the fields are the last set, and pending + current are
    /// written as ONE execution (one store write, one debounced backup).
    private func finalize(_ exercise: Exercise, with set: ValidatedSet) {
        let id = exercise.id
        focus = nil
        keptDrafts.removeValue(forKey: id)
        let sets = card.pending + [PendingSet(set: set)]
        withAnimation(.snappy) { _ = store.finalize(exercise, with: sets) }
        successHapticCount += 1
        card = CardDraft()
        flashExerciseID = id
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            if flashExerciseID == id { flashExerciseID = nil }
        }
    }

    /// The fields an exercise starts with: the peak set of its last execution,
    /// or empty when it has never been performed. Replaces the old "Same as last
    /// time" button — the values are simply there, ready to be stepped or
    /// overtyped, and because they validate both card buttons are live at once.
    ///
    /// The peak (best estimated 1RM, PLAN.md "Multi-set executions") rather than
    /// the chronologically last set: after three sets of 80 / 80 / 60 kg the
    /// number to beat is 80, not the burn-out set.
    ///
    /// A unilateral exercise whose last entry predates the L/R switch has no
    /// `repsRight`; both sides then start from the bilateral reps.
    private func prefilledDraft(for exercise: Exercise?) -> SetDraft {
        guard let exercise, let entry = exercise.lastExecution?.peak else { return SetDraft() }
        return SetDraft(
            weightText: SetDraft.weightText(fromHalfKilos: entry.weightHalfKilos),
            repsText: SetDraft.repsText(fromReps: entry.reps),
            repsRightText: exercise.isUnilateral
                ? SetDraft.repsText(fromReps: entry.repsRight ?? entry.reps)
                : ""
        )
    }

    private func handleAdded(_ result: ExerciseFormSheet.AddResult) {
        switch result.outcome {
        case .startedInProgress:
            // The `@Query` may update before or after this callback, so set both.
            // The add sheet's optional first set is a single set, so the new
            // card starts with those fields and an empty pending list.
            let next = CardDraft(fields: result.draft)
            pendingDraft = next
            card = next
            startHapticCount += 1
        case .logged:
            successHapticCount += 1
        case .queued:
            hint = String(localized: "Added to the queue")
        }
    }

    // MARK: - Focus chain (PLAN.md pitfall 5)

    private var canFocusNext: Bool {
        switch focus {
        case .weight: true
        case .repsLeft: inProgress?.isUnilateral == true
        case .repsRight, .none: false
        }
    }

    private func focusNext() {
        switch focus {
        case .weight:
            focus = .repsLeft
        case .repsLeft:
            focus = inProgress?.isUnilateral == true ? .repsRight : nil
        case .repsRight, .none:
            focus = nil
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, Entry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let folder = BackupFolder()

    return MainScreen()
        .modelContainer(container)
        .environment(QueueStore(modelContext: container.mainContext))
        .environment(folder)
        .environment(BackupScheduler(context: container.mainContext, folder: folder))
}
