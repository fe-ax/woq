import SwiftUI

/// Reusable paper card: card fill, 1.5 pt ink border, 3 pt corners and an optional 2 pt hard offset shadow.
///
/// The shadow uses `Tokens.shadow`, not ink: on dark paper an ink-coloured
/// offset would read as a light halo around the card instead of a shadow.
struct OutlinedCard<Content: View>: View {
    var padding: CGFloat = Tokens.cardPadding
    var showsShadow: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
            )
            .background {
                if showsShadow {
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .fill(Tokens.shadow)
                        .offset(x: Tokens.shadowOffset, y: Tokens.shadowOffset)
                }
            }
    }
}

#Preview {
    ZStack {
        Tokens.paper
        OutlinedCard(showsShadow: true) {
            Text(verbatim: "Bench press")
                .foregroundStyle(Tokens.ink)
        }
        .padding()
    }
}
