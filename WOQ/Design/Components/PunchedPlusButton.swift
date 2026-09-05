import SwiftUI

/// Filled circle with an SF Symbol punched out of it, so the paper background
/// shows through the glyph. See PLAN.md section 7 and pitfall 16: the
/// destination-out blend must sit inside a compositing group, otherwise it eats
/// everything drawn behind the button.
///
/// `fill` swaps the circle colour — the header's search glass turns
/// `Tokens.blue` while a filter is active — and `strokes` adds the hairline ink
/// outline such a pastel circle needs to keep an edge on paper. The plus keeps
/// the plain ink circle through `PunchedPlusButton`.
struct PunchedIconButton: View {
    var systemName: String
    var fill: Color = Tokens.ink
    /// Hairline ink outline around the circle. Only needed for pastel fills; the
    /// ink circle is its own outline.
    var strokes: Bool = false
    var accessibilityLabel: String
    var diameter: CGFloat = 44
    var glyphSize: CGFloat = 22
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(fill)
                Image(systemName: systemName)
                    .font(.system(size: glyphSize, weight: .bold))
                    .blendMode(.destinationOut)
            }
            .frame(width: diameter, height: diameter)
            .compositingGroup()
            // Outside the group: a stroke inside it would be punched as well.
            .overlay {
                if strokes {
                    Circle()
                        .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: fill)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Black circle with the plus punched out, so the paper background shows through.
/// Thin wrapper over `PunchedIconButton` so the header's plus is unchanged.
struct PunchedPlusButton: View {
    var diameter: CGFloat = 44
    var action: () -> Void

    var body: some View {
        PunchedIconButton(
            systemName: "plus",
            accessibilityLabel: String(localized: "Add exercise"),
            diameter: diameter,
            action: action
        )
    }
}

#Preview {
    ZStack {
        Tokens.paper
        HStack(spacing: 12) {
            PunchedIconButton(
                systemName: "magnifyingglass",
                accessibilityLabel: "Search",
                glyphSize: 20
            ) {}
            PunchedIconButton(
                systemName: "magnifyingglass",
                fill: Tokens.blue,
                strokes: true,
                accessibilityLabel: "Search",
                glyphSize: 20
            ) {}
            PunchedPlusButton {}
        }
    }
}
