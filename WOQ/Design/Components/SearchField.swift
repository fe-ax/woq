import SwiftUI

/// Outlined search field: 1.5 pt ink border, 3 pt radius, card fill, with a clear button.
struct SearchField: View {
    @Binding var text: String

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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .fill(Tokens.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
        )
    }
}

#Preview {
    @Previewable @State var text = ""
    ZStack {
        Tokens.paper
        SearchField(text: $text).padding()
    }
}
