import SwiftUI

/// Paper segmented control: equal-width plain buttons inside one outlined
/// rounded rectangle, the selected one filled with ink.
///
/// Not a `Picker(.segmented)`: iOS 26 draws that as Liquid Glass, which is
/// exactly the look the app avoids everywhere else (PLAN.md pitfall 29).
/// VoiceOver reads it as a group of buttons of which one is selected.
struct SegmentedRow<Value: Hashable>: View {
    var options: [Value]
    var label: (Value) -> String
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                if index > 0 {
                    Rectangle()
                        .fill(Tokens.ink)
                        .frame(width: Tokens.hairline)
                }

                segment(option)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
        )
        .animation(.snappy, value: selection)
        .accessibilityElement(children: .contain)
    }

    private func segment(_ option: Value) -> some View {
        let isSelected = option == selection

        return Button {
            guard !isSelected else { return }
            selection = option
        } label: {
            Text(label(option))
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(isSelected ? Tokens.paper : Tokens.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Tokens.ink : Tokens.card)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label(option))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    @Previewable @State var appearance = Appearance.system

    ZStack {
        Tokens.paper.ignoresSafeArea()
        OutlinedCard {
            SegmentedRow(
                options: Appearance.allCases,
                label: \.displayName,
                selection: $appearance
            )
        }
        .padding(16)
    }
}
