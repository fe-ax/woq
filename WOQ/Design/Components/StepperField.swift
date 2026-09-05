import SwiftUI
import UIKit

/// Outlined numeric field with a minus / plus stepper on either side.
///
/// The field keeps a `String` binding on purpose: decimal parsing is locale
/// sensitive and must be normalised by the caller (PLAN.md pitfall 26), and
/// `TextField(value:format:)` only commits on focus loss. The stepper buttons
/// report a direction (`-1` / `+1`); the caller decides the step size, so the
/// same component serves 0.5 kg weights and 1-rep counts.
struct StepperField<Field: Hashable>: View {
    var title: String
    @Binding var text: String
    var unit: String?
    var keyboard: UIKeyboardType
    var onStep: (Int) -> Void
    var focus: FocusState<Field?>.Binding
    var field: Field
    var isInvalid: Bool
    var accessibilityLabel: String

    init(
        title: String,
        text: Binding<String>,
        unit: String? = nil,
        keyboard: UIKeyboardType,
        onStep: @escaping (Int) -> Void,
        focus: FocusState<Field?>.Binding,
        field: Field,
        isInvalid: Bool = false,
        accessibilityLabel: String
    ) {
        self.title = title
        self._text = text
        self.unit = unit
        self.keyboard = keyboard
        self.onStep = onStep
        self.focus = focus
        self.field = field
        self.isInvalid = isInvalid
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Tokens.muted)

            HStack(spacing: 0) {
                stepButton(
                    systemName: "minus",
                    delta: -1,
                    label: String(localized: "Decrease \(accessibilityLabel)")
                )

                TextField("", text: $text)
                    .font(Tokens.numberFont(.body))
                    .multilineTextAlignment(.center)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(Tokens.ink)
                    .tint(Tokens.ink)
                    .focused(focus, equals: field)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(accessibilityLabel)

                if let unit {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(Tokens.muted)
                        .padding(.trailing, 2)
                        .accessibilityHidden(true)
                }

                stepButton(
                    systemName: "plus",
                    delta: 1,
                    label: String(localized: "Increase \(accessibilityLabel)")
                )
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(isInvalid ? Tokens.danger : Tokens.ink, lineWidth: Tokens.line)
            )
            .animation(.snappy, value: isInvalid)
        }
    }

    private func stepButton(systemName: String, delta: Int, label: String) -> some View {
        Button {
            onStep(delta)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Tokens.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    StepperFieldPreviewHost()
}

/// Preview host: `@FocusState` needs an owning view, so the preview cannot use
/// `@Previewable` for the focus binding.
private struct StepperFieldPreviewHost: View {
    private enum Field: Hashable {
        case weight
        case reps
    }

    @State private var weight = "40"
    @State private var reps = "10"
    @FocusState private var focus: Field?

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            HStack(spacing: 12) {
                StepperField(
                    title: String(localized: "Weight"),
                    text: $weight,
                    unit: String(localized: "kg"),
                    keyboard: .decimalPad,
                    onStep: { _ in },
                    focus: $focus,
                    field: .weight,
                    accessibilityLabel: String(localized: "Weight in kilograms")
                )
                StepperField(
                    title: String(localized: "Reps"),
                    text: $reps,
                    keyboard: .numberPad,
                    onStep: { _ in },
                    focus: $focus,
                    field: .reps,
                    isInvalid: true,
                    accessibilityLabel: String(localized: "Repetitions")
                )
            }
            .padding()
        }
    }
}
