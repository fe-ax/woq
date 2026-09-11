import SwiftUI

/// 36 pt circular "log this set and keep going" button — the sibling of
/// `CheckmarkButton` on the in-progress card (PLAN.md "Multi-set executions",
/// 2026-09-12).
///
/// Both buttons are the same size and sit next to each other, so they have to
/// read as two different actions at a glance. The checkmark is a *solid* ink
/// circle with a paper glyph (it ends the exercise); the plus is a *punched* ink
/// circle in the header's style (`PunchedIconButton`), so the water shader
/// behind the card shows through the glyph — the set is added, the card stays.
///
/// The punch is a `.blendMode(.destinationOut)` inside a `.compositingGroup()`
/// (PLAN.md pitfall 16): without the group the blend clears everything drawn
/// behind the button, water and card outline included. The disabled state can
/// therefore not be punched (there is nothing to punch out of a pale card fill
/// that would still read as a plus), so it mirrors `CheckmarkButton` instead:
/// card fill, ink outline, muted glyph.
struct AddSetButton: View {
    var isEnabled: Bool
    var action: () -> Void

    /// Same diameter as `CheckmarkButton`: the two circles are a pair.
    private static let diameter: CGFloat = 36
    private static let glyphSize: CGFloat = 16

    var body: some View {
        Button(action: action) {
            circle
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.snappy, value: isEnabled)
        .accessibilityLabel(String(localized: "Add set"))
    }

    @ViewBuilder
    private var circle: some View {
        if isEnabled {
            ZStack {
                Circle()
                    .fill(Tokens.ink)
                Image(systemName: "plus")
                    .font(.system(size: Self.glyphSize, weight: .bold))
                    .blendMode(.destinationOut)
            }
            .frame(width: Self.diameter, height: Self.diameter)
            .compositingGroup()
        } else {
            ZStack {
                Circle()
                    .fill(Tokens.card)
                Circle()
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
                Image(systemName: "plus")
                    .font(.system(size: Self.glyphSize, weight: .bold))
                    .foregroundStyle(Tokens.muted)
            }
            .frame(width: Self.diameter, height: Self.diameter)
        }
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        HStack(spacing: 20) {
            AddSetButton(isEnabled: true) {}
            AddSetButton(isEnabled: false) {}
            CheckmarkButton(isEnabled: true) {}
            CheckmarkButton(isEnabled: false) {}
        }
    }
}
