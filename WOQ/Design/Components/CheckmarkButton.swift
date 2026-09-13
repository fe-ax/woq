import SwiftUI

/// 36 pt circular finalize button: solid ink when the set is valid, outlined
/// and disabled when it is not (PLAN.md section 6).
///
/// The glyph is a tiny plus in front of the checkmark ("+✓", phone feedback
/// 2026-09-13). The button does not only finish the exercise, it also logs the
/// fields as the last set — so next to `AddSetButton`'s plain plus a lone
/// checkmark read as "finish without this set" and the pair was confusing. The
/// plus is deliberately small: the checkmark stays the dominant shape (this is
/// still the finish button) and the two glyphs fit the 36 pt circle.
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
                HStack(spacing: 1.5) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
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
