import SwiftUI

/// 36 pt circular finalize button: ink with the glyph punched out when the set
/// is valid, outlined and disabled when it is not (PLAN.md section 6).
///
/// Two glyphs, one button (2026-09-13, Marco's rule after the pair "+" / "+✓"
/// kept confusing): with `showsPlus` the checkmark carries a tiny plus tucked
/// into its top-left corner, above the short arm — "add this set and finish".
/// Without it, a plain centred checkmark — "finish with what is listed". The
/// card flips `showsPlus` on whether the reps box holds anything, and the
/// switch animates: the plus scales in at the corner while the check shifts
/// 1.5 pt down-right so the pair as a whole stays centred in the circle.
///
/// Punched like `AddSetButton` (Marco, 2026-09-13; it started as a solid circle
/// with a paper glyph): `.blendMode(.destinationOut)` inside a
/// `.compositingGroup()` so the water behind the card shows through the glyph
/// (PLAN.md pitfall 16 — without the group the blend clears everything drawn
/// behind the button). The two buttons now differ by their glyphs alone. The
/// disabled state cannot be punched (nothing to punch out of a pale card fill),
/// so it is card fill, ink outline, muted glyph.
struct CheckmarkButton: View {
    /// True = "+✓" (add the fields as the last set, then finish); false = "✓"
    /// (finish with the pending sets as they are).
    var showsPlus: Bool = true
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
        .accessibilityLabel(
            showsPlus
                ? String(localized: "Add set and finish")
                : String(localized: "Finish")
        )
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

    /// The checkmark, with the plus in its top-left corner when `showsPlus`.
    private var glyph: some View {
        ZStack {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .offset(x: showsPlus ? 1.5 : 0, y: showsPlus ? 1.5 : 0)
            if showsPlus {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                    .offset(x: -7, y: -6.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.snappy, value: showsPlus)
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        HStack(spacing: 20) {
            CheckmarkButton(showsPlus: true, isEnabled: true) {}
            CheckmarkButton(showsPlus: false, isEnabled: true) {}
            CheckmarkButton(showsPlus: true, isEnabled: false) {}
            CheckmarkButton(showsPlus: false, isEnabled: false) {}
        }
    }
}
