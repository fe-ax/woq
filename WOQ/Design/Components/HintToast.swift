import SwiftUI

/// Transient paper pill shown under the safe area at the top of the screen.
///
/// Used for refusals ("Finish the current exercise first"). Setting the bound
/// message shows it; it auto-dismisses after `duration`, a new message cancels
/// the pending dismissal, and a tap dismisses it immediately. Haptics are the
/// caller's job (PLAN.md pitfall 14).
private struct HintToastModifier: ViewModifier {
    @Binding var message: String?
    var duration: Duration

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message {
                    pill(message)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: message)
            .task(id: message) {
                guard message != nil else { return }
                try? await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                withAnimation(.snappy) { message = nil }
            }
    }

    private func pill(_ text: String) -> some View {
        OutlinedCard(padding: 10, showsShadow: true) {
            Text(text)
                .appFont(.subheadline)
                .foregroundStyle(Tokens.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .onTapGesture {
            withAnimation(.snappy) { message = nil }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

extension View {
    /// Overlays a hint toast driven by an optional message binding.
    func hintToast(_ message: Binding<String?>, duration: Duration = .seconds(2)) -> some View {
        modifier(HintToastModifier(message: message, duration: duration))
    }
}

#Preview {
    @Previewable @State var message: String? = "Finish the current exercise first"

    ZStack {
        Tokens.paper.ignoresSafeArea()
        Button {
            message = "Finish the current exercise first"
        } label: {
            Text(verbatim: "Show hint")
        }
        .buttonStyle(.paper)
    }
    .hintToast($message)
}
