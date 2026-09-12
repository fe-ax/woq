import SwiftUI

/// The 8 `Equipment` cases as wrapping chips, at most one selected (2026-09-12).
///
/// Same chip shape as the muscle filter: 3 pt corners, hairline ink outline, blue fill with
/// fixed dark ink when picked (`Tokens.inkOnPastel`, because blue stays pastel in both
/// appearances), card fill otherwise. Tapping the selected chip clears the tag, so no
/// separate "none" chip is needed. `ChipWrap` (Design note: it lives in MuscleFilterPanel.swift)
/// does the line breaking.
struct EquipmentChipRow: View {
    @Binding var selection: Equipment?

    var body: some View {
        ChipWrap(spacing: 6, lineSpacing: 6) {
            ForEach(Equipment.allCases) { equipment in
                chip(for: equipment)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy, value: selection)
    }

    private func chip(for equipment: Equipment) -> some View {
        let isSelected = selection == equipment

        return Button {
            selection = isSelected ? nil : equipment
        } label: {
            Text(equipment.displayName)
                .appFont(.footnote, weight: .semibold)
                .foregroundStyle(isSelected ? Tokens.inkOnPastel : Tokens.ink)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .fill(isSelected ? Tokens.blue : Tokens.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                )
                .contentShape(RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(equipment.displayName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(
            isSelected
                ? String(localized: "Removes the equipment tag")
                : String(localized: "Tags this exercise with this equipment")
        )
    }
}

#Preview {
    EquipmentChipRowPreviewHost()
}

private struct EquipmentChipRowPreviewHost: View {
    @State private var selection: Equipment? = .dumbbell

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            EquipmentChipRow(selection: $selection)
                .padding(16)
        }
    }
}
