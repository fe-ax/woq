#if DEBUG
import SwiftUI

/// DEBUG-only showcase of every reusable component, for visual review on the
/// simulator. Not part of any shipped screen; strings are `verbatim` so the
/// gallery never lands in the string catalog.
struct ComponentGallery: View {
    private enum Field: Hashable {
        case weight
        case reps
    }

    @State private var weightText = "40"
    @State private var repsText = "10"
    @State private var chips: [Intensity?] = [.primary, .secondary, .stabiliser, nil]
    @State private var checkmarkEnabled = true
    @State private var glassIsActive = false
    @State private var undoCount = 0
    @State private var addedSetCount = 0
    @State private var hint: String?
    @State private var appearanceChoice = Appearance.system
    @State private var menuTapCount = 0
    @FocusState private var focus: Field?

    var body: some View {
        ZStack {
            Tokens.paper
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    steppers
                    intensityChips
                    lanes
                    buttons
                    punchedButtons
                    menuRows
                    keyboardBar
                    water
                    toast
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.hard, for: .top)
        }
        .hintToast($hint)
    }

    // MARK: - Sections

    private var steppers: some View {
        section("StepperField") {
            HStack(alignment: .top, spacing: 12) {
                StepperField(
                    title: String(localized: "Weight"),
                    text: $weightText,
                    unit: String(localized: "kg"),
                    keyboard: .decimalPad,
                    onStep: { step($0, by: 0.5, text: $weightText) },
                    focus: $focus,
                    field: .weight,
                    isInvalid: weightText.isEmpty,
                    accessibilityLabel: String(localized: "Weight in kilograms")
                )
                StepperField(
                    title: String(localized: "Reps"),
                    text: $repsText,
                    keyboard: .numberPad,
                    onStep: { step($0, by: 1, text: $repsText) },
                    focus: $focus,
                    field: .reps,
                    isInvalid: repsText.isEmpty,
                    accessibilityLabel: String(localized: "Repetitions")
                )
            }
        }
    }

    private var intensityChips: some View {
        section("IntensityChip") {
            // Four chips are a little wider than the screen: scroll the row
            // rather than truncating "Stabiliser".
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(chips.indices, id: \.self) { index in
                        IntensityChip(intensity: chips[index]) {
                            chips[index] = IntensityChip.next(after: chips[index])
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var lanes: some View {
        section("LaneColumn and LaneSeparator") {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    LaneColumn(
                        laneColor: Tokens.blue,
                        nodeStyle: .filled(Tokens.blue),
                        connectsUp: false,
                        connectsDown: true
                    )
                    OutlinedCard {
                        Text(verbatim: "filled(blue), connectsUp: false")
                            .appFont(.footnote)
                            .foregroundStyle(Tokens.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 72)

                // The in-progress section's placement: the node is pinned 30 pt
                // from the top instead of floating with the card's centre.
                HStack(spacing: 0) {
                    LaneColumn(
                        laneColor: Tokens.blue,
                        nodeStyle: .filled(Tokens.blue),
                        connectsUp: true,
                        connectsDown: true,
                        nodePlacement: .top(inset: 30)
                    )
                    OutlinedCard {
                        Text(verbatim: "filled(blue), node .top(inset: 30)")
                            .appFont(.footnote)
                            .foregroundStyle(Tokens.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 90)

                // Bridged: the lane crosses the rule, blue above, yellow below.
                LaneSeparator(bridgeTop: Tokens.blue, bridgeBottom: Tokens.yellow)

                HStack(spacing: 0) {
                    LaneColumn(
                        laneColor: Tokens.yellow,
                        nodeStyle: .outlined,
                        connectsUp: true,
                        connectsDown: true
                    )
                    OutlinedCard {
                        Text(verbatim: "outlined, both connectors")
                            .appFont(.footnote)
                            .foregroundStyle(Tokens.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 64)
            }
        }
    }

    private var buttons: some View {
        section("Buttons") {
            HStack(spacing: 12) {
                // The in-progress card's pair, in both states: punched plus
                // (add a set, card stays) next to the solid checkmark (finish).
                AddSetButton(isEnabled: checkmarkEnabled) {
                    addedSetCount += 1
                }
                AddSetButton(isEnabled: false) {}
                CheckmarkButton(isEnabled: checkmarkEnabled) {
                    checkmarkEnabled = false
                }
                CheckmarkButton(isEnabled: false) {}
                RoundIconButton(
                    systemName: "arrow.uturn.backward",
                    accessibilityLabel: String(localized: "Put back in the queue")
                ) {
                    undoCount += 1
                    checkmarkEnabled = true
                }
                RoundIconButton(
                    systemName: "xmark",
                    diameter: 24,
                    accessibilityLabel: String(localized: "Remove set 1")
                ) {
                    addedSetCount = max(0, addedSetCount - 1)
                }
            }

            // Second row: six circles plus two labelled buttons do not fit on
            // one 396 pt line.
            HStack(spacing: 12) {
                Button {
                    checkmarkEnabled.toggle()
                } label: {
                    Text(verbatim: "Toggle")
                }
                .buttonStyle(.paper)

                Button {
                    checkmarkEnabled = true
                } label: {
                    Text(verbatim: "Reset")
                }
                .buttonStyle(.ink)
            }

            Text(verbatim: "add set \(addedSetCount)x \u{00B7} put back \(undoCount)x")
                .appNumberFont(.caption)
                .foregroundStyle(Tokens.muted)
        }
    }

    /// The header trio: the plus, and the search glass in both of its states
    /// (ink when nothing filters, blue with a hairline outline while it does).
    private var punchedButtons: some View {
        section("PunchedIconButton") {
            HStack(spacing: 12) {
                PunchedPlusButton {}
                PunchedIconButton(
                    systemName: "magnifyingglass",
                    accessibilityLabel: String(localized: "Search"),
                    glyphSize: 20
                ) {
                    glassIsActive.toggle()
                }
                PunchedIconButton(
                    systemName: "magnifyingglass",
                    fill: Tokens.blue,
                    strokes: true,
                    accessibilityLabel: String(localized: "Search"),
                    glyphSize: 20
                ) {
                    glassIsActive.toggle()
                }
                PunchedIconButton(
                    systemName: "magnifyingglass",
                    fill: glassIsActive ? Tokens.blue : Tokens.ink,
                    strokes: glassIsActive,
                    accessibilityLabel: String(localized: "Search"),
                    glyphSize: 20
                ) {
                    glassIsActive.toggle()
                }
            }

            Text(verbatim: "plus · ink glass · blue glass · tap to animate")
                .appFont(.caption)
                .foregroundStyle(Tokens.muted)
        }
    }

    /// The settings menu's building blocks: a root row that pushes a page, the
    /// action row with its paper button (plain, and disabled with an error line),
    /// and the paper segmented control inside a card, as on the Appearance page.
    private var menuRows: some View {
        section("MenuRow, MenuActionRow and SegmentedRow") {
            MenuRow(
                title: String(localized: "Appearance"),
                subtitle: "System \u{00B7} Ripple on \u{00B7} SF Pro"
            ) {
                menuTapCount += 1
            }

            MenuActionRow(
                title: String(localized: "Last backup"),
                subtitle: "Today at 14:21",
                buttonTitle: String(localized: "Back up now")
            ) {
                menuTapCount += 1
            }

            MenuActionRow(
                title: String(localized: "Restore"),
                subtitle: "Merges the backup in the chosen folder into this device",
                detail: "The folder could not be opened",
                buttonTitle: String(localized: "Restore\u{2026}"),
                isDisabled: true
            ) {}

            OutlinedCard {
                VStack(alignment: .leading, spacing: 10) {
                    MenuSectionTitle(String(localized: "Appearance"))
                    SegmentedRow(
                        options: Appearance.allCases,
                        label: \.displayName,
                        selection: $appearanceChoice
                    )
                    MenuCaption("Paper segmented control, no Picker")
                }
            }

            Text(verbatim: "rows tapped \(menuTapCount)x \u{00B7} \(appearanceChoice.displayName)")
                .appNumberFont(.caption)
                .foregroundStyle(Tokens.muted)
        }
    }

    /// Shown inline here; on the real screens it rides on the keyboard through
    /// `.safeAreaInset(edge: .bottom)`.
    private var keyboardBar: some View {
        section("KeyboardAccessoryBar") {
            KeyboardAccessoryBar(showsNext: true, onNext: { focus = .reps }, onDone: { focus = nil })
            KeyboardAccessoryBar(showsNext: false, onNext: {}, onDone: { focus = nil })
        }
    }

    private var water: some View {
        section("WaterBackground") {
            OutlinedCard(padding: 0) {
                ZStack {
                    WaterBackground()
                    Text(verbatim: "Bench press — 40 kg \(Formatting.timesSign) 10")
                        .appNumberFont(.body, weight: .semibold)
                        .foregroundStyle(Tokens.ink)
                }
                .frame(height: 120)
            }
        }
    }

    private var toast: some View {
        section("HintToast") {
            Button {
                hint = "Finish the current exercise first"
            } label: {
                Text(verbatim: "Show hint")
            }
            .buttonStyle(.paper)
        }
    }

    // MARK: - Helpers

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: title.uppercased())
                .appFont(.caption2, weight: .semibold)
                .tracking(1)
                .foregroundStyle(Tokens.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Gallery-only stepping: plain `Double` maths, no validation. The real
    /// screens keep weights in half-kilo `Int`s (PLAN.md pitfall 4).
    private func step(_ delta: Int, by amount: Double, text: Binding<String>) {
        let current = Double(text.wrappedValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        let next = max(0, current + Double(delta) * amount)
        text.wrappedValue = next == next.rounded() ? String(Int(next)) : String(next)
    }
}

#Preview {
    ComponentGallery()
}
#endif
