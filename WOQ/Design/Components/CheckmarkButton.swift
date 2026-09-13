import SwiftUI

/// 36 pt circular finalize button: ink with the glyph punched out when the set
/// is valid, outlined and disabled when it is not (PLAN.md section 6).
///
/// The glyph is a checkmark with a tiny plus tucked into its top-left corner,
/// above the short arm (phone feedback 2026-09-13, placement Marco's). The
/// button does not only finish the exercise, it also logs the fields as the
/// last set — so next to `AddSetButton`'s plain plus a lone checkmark read as
/// "finish without this set" and the pair was confusing. The plus is
/// deliberately small and off to the corner: the checkmark stays the dominant,
/// centred shape (this is still the finish button), nudged down-right a touch
/// so the pair as a whole sits in the middle of the circle.
///
/// Punched like `AddSetButton` (Marco, 2026-09-13; it started as a solid circle
/// with a paper glyph): `.blendMode(.destinationOut)` inside a
/// `.compositingGroup()` so the water behind the card shows through the glyph
/// (PLAN.md pitfall 16 — without the group the blend clears everything drawn
/// behind the button). The two buttons now differ by their glyphs alone. The
/// disabled state cannot be punched (nothing to punch out of a pale card fill),
/// so it is card fill, ink outline, muted glyph.
struct CheckmarkButton: View {
    var isEnabled: Bool
    var action: () -> Void

    private static let diameter: CGFloat = 36

    var body: some View {
        Button(action: action) {
            circle
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.snappy, value: isEnabled)
        .accessibilityLabel(String(localized: "Add set and finish"))
    }

    @ViewBuilder
    private var circle: some View {
        if isEnabled {
            ZStack {
                Circle()
                    .fill(Tokens.ink)
                glyph
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
                glyph
                    .foregroundStyle(Tokens.muted)
            }
            .frame(width: Self.diameter, height: Self.diameter)
        }
    }

    /// The checkmark with the plus in its top-left corner.
    private var glyph: some View {
        ZStack {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .offset(x: 1.5, y: 1.5)
            Image(systemName: "plus")
                .font(.system(size: 8, weight: .bold))
                .offset(x: -7, y: -6.5)
        }
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        HStack(spacing: 20) {
            CheckmarkButton(isEnabled: true) {}
            CheckmarkButton(isEnabled: false) {}
        }
    }
}
