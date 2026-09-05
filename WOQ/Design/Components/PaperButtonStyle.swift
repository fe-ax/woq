import SwiftUI

/// Outlined paper button: card fill, 1.5 pt ink border, ink label.
///
/// `.bordered` and `.borderedProminent` turn into Liquid Glass on iOS 26
/// (PLAN.md pitfall 29), so every button in the app uses `.plain`, `.paper`
/// or `.ink`.
struct PaperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(Tokens.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(configuration.isPressed ? Tokens.paper : Tokens.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
            )
            .contentShape(RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous))
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}

/// Solid ink button: ink fill, paper label. The confirming action of a sheet.
struct InkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(Tokens.paper)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(configuration.isPressed ? Tokens.muted : Tokens.ink)
            )
            .contentShape(RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous))
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PaperButtonStyle {
    /// Outlined paper pill.
    static var paper: PaperButtonStyle { PaperButtonStyle() }
}

extension ButtonStyle where Self == InkButtonStyle {
    /// Solid ink pill.
    static var ink: InkButtonStyle { InkButtonStyle() }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        HStack(spacing: 12) {
            Button(String(localized: "Cancel")) {}
                .buttonStyle(.paper)
            Button(String(localized: "Save")) {}
                .buttonStyle(.ink)
        }
    }
}
