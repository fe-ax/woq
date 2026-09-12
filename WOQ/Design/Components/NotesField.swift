import SwiftUI

/// Outlined multi-line text field for the free-form notes (2026-09-12): the exercise note on
/// the form sheet and the per-set note in the entry editor.
///
/// Same outline as the name field (card fill, 1.5 pt ink border, 3 pt corners) but it grows
/// with the text between `lineLimit.lowerBound` and `lineLimit.upperBound` lines and then
/// scrolls internally. It deliberately does NOT take part in the `KeyboardAccessoryBar`
/// chain: the text keyboard has its own return key, so the paper bar stays reserved for the
/// number pads (PLAN.md pitfall 5).
struct NotesField<Field: Hashable>: View {
    /// Small muted caption above the field; nil draws the field on its own.
    var title: String?
    /// Grey ghost text while the field is empty.
    var placeholder: String
    @Binding var text: String
    /// How far the field may grow before it scrolls.
    var lineLimit: ClosedRange<Int>
    var focus: FocusState<Field?>.Binding
    var field: Field
    var accessibilityLabel: String

    init(
        title: String? = nil,
        placeholder: String,
        text: Binding<String>,
        lineLimit: ClosedRange<Int> = 1...4,
        focus: FocusState<Field?>.Binding,
        field: Field,
        accessibilityLabel: String
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.lineLimit = lineLimit
        self.focus = focus
        self.field = field
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title {
                Text(title)
                    .appFont(.caption)
                    .foregroundStyle(Tokens.muted)
            }

            // The plain-String initialiser: the placeholder is localized at the call site
            // (PLAN.md pitfall 22), so it must not go through LocalizedStringKey again.
            TextField(placeholder, text: $text, axis: .vertical)
                .appFont(.body)
                .foregroundStyle(Tokens.ink)
                .tint(Tokens.ink)
                .lineLimit(lineLimit)
                .textInputAutocapitalization(.sentences)
                .focused(focus, equals: field)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .frame(minHeight: 44, alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .fill(Tokens.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
                )
                .accessibilityLabel(accessibilityLabel)
        }
    }
}

#Preview {
    NotesFieldPreviewHost()
}

/// `@Binding` and `@FocusState` need an owner.
private struct NotesFieldPreviewHost: View {
    @State private var empty = ""
    @State private var filled = "Felt heavy, wrists sore on the last two reps."
    @FocusState private var focus: Int?

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                NotesField(
                    title: String(localized: "Note"),
                    placeholder: String(localized: "Notes"),
                    text: $empty,
                    lineLimit: 1...3,
                    focus: $focus,
                    field: 0,
                    accessibilityLabel: String(localized: "Note")
                )
                NotesField(
                    placeholder: String(localized: "Notes"),
                    text: $filled,
                    focus: $focus,
                    field: 1,
                    accessibilityLabel: String(localized: "Notes")
                )
            }
            .padding(16)
        }
    }
}
