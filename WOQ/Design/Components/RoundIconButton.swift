import SwiftUI

/// Small outlined circular icon button (put-back, close, …) with a 44 pt hit area.
struct RoundIconButton: View {
    var systemName: String
    var accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Tokens.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Tokens.card))
                .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.hairline))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        RoundIconButton(
            systemName: "arrow.uturn.backward",
            accessibilityLabel: String(localized: "Put back in the queue")
        ) {}
    }
}
