import SwiftUI

/// The pick-from-a-library half of the "New exercise" sheet: every `ExercisePreset`
/// grouped by category, multi-selectable, with the ones already in the queue greyed
/// out and marked "Added".
///
/// Deliberately not a `List`: the sheet owns the scrolling and a nested list would
/// bring its own insets, separators and background (PLAN.md pitfall 3). Rows are
/// separated by `Tokens.muted` hairlines, exactly like `MuscleTagList`.
///
/// The figure above the list belongs to the sheet, not to this view: it shows the
/// union of the selected presets' muscles, so ticking a row lights the figure up.
struct PresetListView: View {
    /// Selected preset ids (= preset names). Kept by the sheet so switching back to
    /// the form and returning does not lose a selection.
    @Binding var selection: Set<String>
    /// `Exercise.nameKey` of everything already in the store, read once by the sheet.
    var takenNameKeys: Set<String>

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(ExercisePreset.Category.allCases) { category in
                    section(for: category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    // MARK: - Sections

    @ViewBuilder
    private func section(for category: ExercisePreset.Category) -> some View {
        let presets = ExercisePresets.presets(in: category)

        if !presets.isEmpty {
            Text(category.displayName)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(Tokens.ink)
                .padding(.top, category == ExercisePreset.Category.allCases.first ? 0 : 20)
                .padding(.bottom, 2)

            ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                if index > 0 {
                    Rectangle()
                        .fill(Tokens.muted)
                        .frame(height: Tokens.hairline)
                }
                row(for: preset)
            }
        }
    }

    // MARK: - Row

    private func row(for preset: ExercisePreset) -> some View {
        let isTaken = takenNameKeys.contains(Exercise.nameKey(for: preset.name))
        let isSelected = selection.contains(preset.id)

        return Button {
            toggle(preset)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(preset.name)
                            .font(.body)
                            .foregroundStyle(Tokens.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if preset.isUnilateral {
                            unilateralBadge
                        }
                    }

                    Text(preset.primaryMuscleSummary)
                        .font(.caption)
                        .foregroundStyle(Tokens.muted)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                if isTaken {
                    Text(String(localized: "Added"))
                        .font(.caption)
                        .foregroundStyle(Tokens.muted)
                } else {
                    checkbox(isSelected: isSelected)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isTaken)
        .opacity(isTaken ? 0.4 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(preset.name)
        .accessibilityValue(
            isTaken
                ? String(localized: "Already in the queue")
                : (isSelected ? String(localized: "Selected") : String(localized: "Not selected"))
        )
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// 24 pt outlined circle; selected is a blue fill with a dark checkmark, the same
    /// blue-means-picked rule as the muscle filter chips (PLAN.md section 7).
    private func checkbox(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Tokens.blue : Tokens.card)
            Circle()
                .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Tokens.inkOnPastel)
            }
        }
        .frame(width: 24, height: 24)
    }

    /// Same badge as the detail sheet, one size down.
    private var unilateralBadge: some View {
        Text(String(localized: "L/R"))
            .font(.system(size: 10, weight: .bold))
            // Sits on a blue fill, which stays pastel in both appearances.
            .foregroundStyle(Tokens.inkOnPastel)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
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

    private func toggle(_ preset: ExercisePreset) {
        if selection.contains(preset.id) {
            selection.remove(preset.id)
        } else {
            selection.insert(preset.id)
        }
    }
}

#Preview {
    @Previewable @State var selection: Set<String> = ["Push-up", "Plank"]

    ZStack {
        Tokens.paper.ignoresSafeArea()
        PresetListView(selection: $selection, takenNameKeys: ["lat pulldown"])
    }
}
