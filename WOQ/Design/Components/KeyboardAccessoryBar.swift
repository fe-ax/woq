import SwiftUI

/// Paper bar that rides on top of the keyboard for the number pads, which have
/// no return key (PLAN.md pitfall 5).
///
/// `ToolbarItemGroup(placement: .keyboard)` renders as a floating Liquid Glass
/// pill on iOS 26, so the app draws the bar itself: paper fill, a 1.5 pt ink top
/// rule and `.paper` / `.ink` buttons — never glass (PLAN.md pitfall 29).
///
/// Present it on the screen or sheet root, so the bar sits above the keyboard
/// and the content below it keeps its inset:
/// ```
/// .safeAreaInset(edge: .bottom, spacing: 0) {
///     if focus != nil { KeyboardAccessoryBar(showsNext: …, onNext: …, onDone: …) }
/// }
/// .animation(.snappy, value: focus)
/// ```
struct KeyboardAccessoryBar: View {
    /// "Next" is shown only while the focus chain has a following field.
    var showsNext: Bool
    var onNext: () -> Void
    var onDone: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if showsNext {
                Button(String(localized: "Next"), action: onNext)
                    .buttonStyle(.paper)
            }

            Spacer(minLength: 0)

            Button(String(localized: "Done"), action: onDone)
                .buttonStyle(.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Tokens.paper)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Tokens.ink)
                .frame(height: Tokens.line)
        }
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        VStack {
            Spacer()
            KeyboardAccessoryBar(showsNext: true, onNext: {}, onDone: {})
            KeyboardAccessoryBar(showsNext: false, onNext: {}, onDone: {})
        }
    }
}
