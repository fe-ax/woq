import SwiftUI

/// One queued exercise: front + back thumbnails, name, relative last-performed
/// date and the latest set (PLAN.md section 6).
///
/// Interaction (PLAN.md 3.3 and 3.7): tap starts the exercise, a 0.4 s long
/// press opens the detail sheet. The card is deliberately NOT a `Button` — a
/// button's own gesture swallows the long press — so it uses `contentShape`
/// plus `onTapGesture` / `onLongPressGesture`.
struct ExerciseRow: View {
    var exercise: Exercise
    /// Green finalize flash (PLAN.md 3.5); fades out when it turns false.
    var isFlashing: Bool = false
    var onTap: () -> Void
    var onLongPress: () -> Void

    var body: some View {
        OutlinedCard {
            HStack(alignment: .center, spacing: 12) {
                FigurePairView(tags: exercise.muscleTags, size: .thumbnail)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(Tokens.ink)
                        .lineLimit(2)

                    Text(relativeDate)
                        .font(Tokens.numberFont(.subheadline))
                        .foregroundStyle(Tokens.muted)

                    // The set string stays on one line at large Dynamic Type
                    // sizes and shrinks a little instead of wrapping.
                    Text(setText)
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Tokens.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
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
        .accessibilityAction(named: Text(String(localized: "Start"))) { onTap() }
        .accessibilityAction(named: Text(String(localized: "Show details"))) { onLongPress() }
        // Half the row spacing on each side keeps the lane node centred on the
        // card while neighbouring cards sit `rowSpacing` apart.
        .padding(.vertical, Tokens.rowSpacing / 2)
    }

    private var relativeDate: String {
        Formatting.relativeDayString(from: exercise.lastPerformedAt)
    }

    private var setText: String {
        guard let entry = exercise.lastEntry else { return String(localized: "No sets yet") }
        return Formatting.setString(for: entry)
    }
}
