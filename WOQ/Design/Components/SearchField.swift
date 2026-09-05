import SwiftUI

/// Outlined search field: 1.5 pt ink border, 3 pt radius, card fill, with a clear button.
///
/// The optional trailing round button opens the muscle filter panel
/// (`MuscleFilterPanel`). It is only drawn when `onFilterTap` is set, so every
/// other call site keeps the plain field. When muscles are selected the circle
/// fills with `Tokens.blue` and the glyph switches to `Tokens.inkOnPastel`.
struct SearchField: View {
    @Binding var text: String
    /// Draws the figure button as filled blue instead of card white.
    var isFilterActive: Bool = false
    /// Number of selected muscles, for the button's accessibility value only.
    var filterCount: Int = 0
    /// Set to show the figure button; `nil` hides it.
    var onFilterTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Tokens.muted)
                .accessibilityHidden(true)

            TextField(String(localized: "Search exercises or muscles"), text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Tokens.ink)
                .tint(Tokens.ink)
                .submitLabel(.search)
                .accessibilityLabel(String(localized: "Search exercises or muscles"))

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Tokens.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Clear search"))
            }

            if let onFilterTap {
                filterButton(onFilterTap)
            }
        }
        .padding(.horizontal, 10)
        // The 32 pt circle is taller than the text row, so trim the padding a
        // little when it is there; without the button the field is unchanged.
        .padding(.vertical, onFilterTap == nil ? 8 : 6)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .fill(Tokens.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
        )
    }

    /// 32 pt outlined circle inside the field, styled like `RoundIconButton`
    /// but without its 44 pt padding, which would not fit the field.
    private func filterButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "figure.stand")
                .font(.system(size: 15, weight: .semibold))
                // The active circle is a pastel fill in both appearances.
                .foregroundStyle(isFilterActive ? Tokens.inkOnPastel : Tokens.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(isFilterActive ? Tokens.blue : Tokens.card))
                .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.hairline))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isFilterActive)
        .accessibilityLabel(String(localized: "Filter by muscle"))
        .accessibilityValue(
            filterCount == 0
                ? String(localized: "None selected")
                : String(localized: "\(filterCount) selected")
        )
    }
}

#Preview {
    @Previewable @State var text = ""
    ZStack {
        Tokens.paper
        VStack(spacing: 12) {
            SearchField(text: $text)
            SearchField(text: $text, onFilterTap: {})
            SearchField(text: $text, isFilterActive: true, filterCount: 2, onFilterTap: {})
        }
        .padding()
    }
}
