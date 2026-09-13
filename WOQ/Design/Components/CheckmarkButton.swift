import SwiftUI

/// 36 pt circular finalize button: solid ink when the set is valid, outlined
/// and disabled when it is not (PLAN.md section 6).
///
/// The glyph is a checkmark with a tiny plus tucked into its top-left corner,
/// above the short arm (phone feedback 2026-09-13, placement Marco's). The
/// button does not only finish the exercise, it also logs the fields as the
/// last set — so next to `AddSetButton`'s plain plus a lone checkmark read as
/// "finish without this set" and the pair was confusing. The plus is
/// deliberately small and off to the corner: the checkmark stays the dominant,
/// centred shape (this is still the finish button), nudged down-right a touch
/// so the pair as a whole sits in the middle of the 36 pt circle.
struct CheckmarkButton: View {
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isEnabled ? Tokens.ink : Tokens.card)
                Circle()
                    .strokeBorder(isEnabled ? Color.clear : Tokens.ink, lineWidth: Tokens.line)
                ZStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .offset(x: 1.5, y: 1.5)
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .offset(x: -7, y: -6.5)
                }
                .foregroundStyle(isEnabled ? Tokens.paper : Tokens.muted)
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.snappy, value: isEnabled)
        .accessibilityLabel(String(localized: "Add set and finish"))
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
