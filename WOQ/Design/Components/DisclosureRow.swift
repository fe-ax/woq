import SwiftUI

/// Paper disclosure: a tappable outlined row that folds a block of content open and shut
/// (the "More" section of the exercise form, 2026-09-12).
///
/// Hand-drawn rather than a system `DisclosureGroup`, which brings its own list chrome and,
/// on iOS 26, glass (PLAN.md pitfall 29). The chevron rotates a quarter turn and the content
/// fades in with the same `.snappy` the rest of the app uses.
struct DisclosureRow<Content: View>: View {
    var title: String
    /// Spoken after the title, e.g. "Equipment and notes".
    var accessibilityHint: String?
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                row
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(
                isExpanded ? String(localized: "Expanded") : String(localized: "Collapsed")
            )
            .accessibilityHint(accessibilityHint ?? "")

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var row: some View {
        HStack(spacing: 8) {
            Text(title)
                .appFont(.headline, weight: .bold)
                .foregroundStyle(Tokens.ink)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Tokens.ink)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .fill(Tokens.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    DisclosureRowPreviewHost()
}

private struct DisclosureRowPreviewHost: View {
    @State private var isExpanded = true

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            DisclosureRow(
                title: String(localized: "More"),
                accessibilityHint: String(localized: "Equipment and notes"),
                isExpanded: $isExpanded
            ) {
                Text(verbatim: "Content")
                    .appFont(.body)
                    .foregroundStyle(Tokens.ink)
            }
            .padding(16)
        }
    }
}
