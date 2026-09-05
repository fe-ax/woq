import SwiftUI

/// 36 pt circular finalize button: solid ink when the set is valid, outlined
/// and disabled when it is not (PLAN.md section 6).
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
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isEnabled ? Tokens.paper : Tokens.muted)
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.snappy, value: isEnabled)
        .accessibilityLabel(String(localized: "Finalize set"))
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
