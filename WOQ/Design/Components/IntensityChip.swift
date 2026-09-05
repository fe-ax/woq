import SwiftUI

/// Tappable chip that cycles a muscle through the three intensities and back to none.
///
/// The chip is stateless: it renders `intensity` and reports taps; the owner
/// applies `IntensityChip.next(after:)` to its own model.
struct IntensityChip: View {
    var intensity: Intensity?
    var onTap: () -> Void

    /// none -> primary -> secondary -> stabiliser -> none.
    static func next(after: Intensity?) -> Intensity? {
        switch after {
        case .none: .primary
        case .primary?: .secondary
        case .secondary?: .stabiliser
        case .stabiliser?: nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Tokens.ink)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(minWidth: 96)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .fill(fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                        .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                )
                .contentShape(RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: intensity)
        .accessibilityLabel(String(localized: "Intensity"))
        .accessibilityValue(accessibilityValue)
    }

    private var label: String {
        intensity?.displayName ?? "—"
    }

    private var accessibilityValue: String {
        intensity?.displayName ?? String(localized: "None")
    }

    private var fill: Color {
        switch intensity {
        case .none: Tokens.card
        case .primary?: Tokens.red
        case .secondary?: Tokens.yellow
        case .stabiliser?: Tokens.paleYellow
        }
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        VStack(spacing: 10) {
            IntensityChip(intensity: .primary) {}
            IntensityChip(intensity: .secondary) {}
            IntensityChip(intensity: .stabiliser) {}
            IntensityChip(intensity: nil) {}
        }
        .padding()
    }
}
