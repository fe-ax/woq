import SwiftUI

/// Small outlined circular icon button (put-back, close, remove a pending set, …).
///
/// `diameter` is the *drawn* circle; the tap target is a separate, larger frame
/// so a small button stays reachable: `max(44, diameter + 12)`, i.e. never below
/// the 44 pt minimum and a 6 pt ring of slop around anything bigger. The glyph
/// scales with the circle (14 pt at the default 32, 11 pt at the 24 pt × used by
/// the in-progress card's pending rows) so the icon keeps the same optical
/// weight inside the outline.
struct RoundIconButton: View {
    var systemName: String
    /// Drawn circle; the hit area is derived from it and is at least 44 pt.
    var diameter: CGFloat = 32
    var accessibilityLabel: String
    var action: () -> Void

    private var hitDiameter: CGFloat {
        max(44, diameter + 12)
    }

    /// 7/16 of the circle, rounded: 32 -> 14, 24 -> 11.
    private var glyphSize: CGFloat {
        (diameter * 7 / 16).rounded()
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: glyphSize, weight: .semibold))
                .foregroundStyle(Tokens.ink)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(Tokens.card))
                .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.hairline))
                .frame(width: hitDiameter, height: hitDiameter)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        HStack(spacing: 8) {
            RoundIconButton(
                systemName: "arrow.uturn.backward",
                accessibilityLabel: String(localized: "Put back in the queue")
            ) {}
            RoundIconButton(
                systemName: "xmark",
                diameter: 24,
                accessibilityLabel: String(localized: "Remove set 1")
            ) {}
        }
    }
}
