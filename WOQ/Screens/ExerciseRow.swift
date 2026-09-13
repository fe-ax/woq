import SwiftUI

/// One queued exercise: front + back thumbnails, name, relative last-performed
/// date and the latest set (PLAN.md section 6).
///
/// Interaction (PLAN.md 3.3 and 3.7): tap starts the exercise, a 0.4 s long
/// press opens the detail sheet. The card is deliberately NOT a `Button` — a
/// button's own gesture swallows the long press — so it uses `contentShape`
/// plus `onTapGesture` / `onLongPressGesture`.
///
/// "Continue" (2026-09-13): for 15 minutes after its checkmark the row that
/// was finished last carries a blue circle with the rise glyph (`RiseGlyph`)
/// at its trailing edge. It is a real `Button` inside the tappable card, so a
/// tap on it is the button's and a tap anywhere else is still "start". Blue
/// because it leads back to the in-progress state; a symbol rather than a
/// word (Marco, 2026-09-13).
struct ExerciseRow: View {
    var exercise: Exercise
    /// Green finalize flash (PLAN.md 3.5); fades out when it turns false.
    var isFlashing: Bool = false
    var onTap: () -> Void
    var onLongPress: () -> Void
    /// Set only on the row that may take its last execution back; nil hides the button.
    var onContinue: (() -> Void)? = nil

    var body: some View {
        OutlinedCard {
            HStack(alignment: .center, spacing: 12) {
                FigurePairView(tags: exercise.muscleTags, size: .thumbnail, palette: Tokens.figurePalette)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .appFont(.headline)
                        .foregroundStyle(Tokens.ink)
                        .lineLimit(2)

                    Text(relativeDate)
                        .appNumberFont(.subheadline)
                        .foregroundStyle(Tokens.muted)

                    // The set string stays on one line at large Dynamic Type
                    // sizes and shrinks a little instead of wrapping.
                    Text(setText)
                        .appNumberFont(.subheadline)
                        .foregroundStyle(Tokens.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                if let onContinue {
                    continueButton(onContinue)
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                .fill(Tokens.green.opacity(isFlashing ? 0.55 : 0))
                .allowsHitTesting(false)
        }
        // Flash in instantly, fade out over 0.8 s.
        .animation(isFlashing ? nil : .easeOut(duration: 0.8), value: isFlashing)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: 0.4) { onLongPress() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.name), \(relativeDate), \(setText)")
        .accessibilityAddTraits(.isButton)
        .accessibilityActions {
            Button(String(localized: "Start")) { onTap() }
            Button(String(localized: "Show details")) { onLongPress() }
            if let onContinue {
                Button(String(localized: "Continue")) { onContinue() }
            }
        }
        // Half the row spacing on each side keeps the lane node centred on the
        // card while neighbouring cards sit `rowSpacing` apart.
        .padding(.vertical, Tokens.rowSpacing / 2)
    }

    /// The blue "Continue" button: a 32 pt circle (the put-back button's size)
    /// with the rise glyph. Deliberately not a U-turn arrow: that already means
    /// "back to the queue" on the card, and this does the opposite. Blue fill
    /// with the 1.5 pt ink outline (heavier than `RoundIconButton`'s hairline)
    /// so it reads as a primary control; the tap target is padded out to 44 pt.
    private func continueButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RiseGlyph(color: Tokens.inkOnPastel)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Tokens.blue))
                .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.line))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Continue \(exercise.name)"))
    }

    private var relativeDate: String {
        Formatting.relativeDayString(from: exercise.lastPerformedAt)
    }

    private var setText: String {
        guard let execution = exercise.lastExecution else { return String(localized: "No sets yet") }
        return Formatting.executionString(peak: execution.peak, setCount: execution.setCount)
    }
}

/// The "bring it back up" glyph Marco described on 2026-09-13 ("i|> but
/// pointing up"): from the bottom, a short bar, a longer bar above it, and a
/// solid triangle pointing up on top — the finished row rising back out of
/// the queue onto the card. The widths taper, 6 / 9 / 12 pt, so the middle
/// bar sits between the bottom bar and the triangle (Marco's tweak). Drawn
/// with shapes, not an SF Symbol: there is no symbol with this stack of bars,
/// and the stack is the point. 14 pt tall, which is `RoundIconButton`'s glyph
/// size for a 32 pt circle.
private struct RiseGlyph: View {
    var color: Color

    var body: some View {
        VStack(spacing: 1.5) {
            UpTriangle()
                .fill(color)
                .frame(width: 12, height: 7)
            Capsule()
                .fill(color)
                .frame(width: 9, height: 2)
            Capsule()
                .fill(color)
                .frame(width: 6, height: 2)
        }
        .accessibilityHidden(true)
    }
}

/// Isosceles triangle with its apex at the top centre.
private struct UpTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
