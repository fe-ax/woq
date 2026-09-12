import SwiftUI

/// The 18 muscle rows of the exercise form: display name left, tappable
/// `IntensityChip` right (PLAN.md section 6).
///
/// Deliberately not a `List`: the sheet is one `ScrollView` and a nested list
/// would bring its own scrolling, insets and separators (PLAN.md pitfall 3).
/// Rows are separated by 1 pt `Tokens.muted` hairlines instead.
///
/// The chip is stateless; cycling goes through `IntensityChip.next(after:)` and
/// rewrites the binding, keeping the array in `Muscle.allCases` order so a saved
/// exercise always lists its muscles the same way.
struct MuscleTagList: View {
    @Binding var tags: [MuscleTag]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Muscle.allCases) { muscle in
                if muscle != Muscle.allCases.first {
                    Rectangle()
                        .fill(Tokens.muted)
                        .frame(height: Tokens.hairline)
                }
                row(for: muscle)
            }
        }
    }

    private func row(for muscle: Muscle) -> some View {
        HStack(spacing: 12) {
            Text(muscle.displayName)
                .appFont(.body)
                .foregroundStyle(Tokens.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            IntensityChip(intensity: intensity(for: muscle)) {
                cycle(muscle)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(muscle.displayName)
        .accessibilityValue(intensity(for: muscle)?.displayName ?? String(localized: "None"))
        .accessibilityHint(String(localized: "Cycles primary, secondary, stabiliser and none"))
    }

    private func intensity(for muscle: Muscle) -> Intensity? {
        tags.first { $0.muscle == muscle }?.intensity
    }

    /// none -> primary -> secondary -> stabiliser -> none, then rebuild the array
    /// in `Muscle.allCases` order (removing the tag when the next value is none).
    private func cycle(_ muscle: Muscle) {
        let next = IntensityChip.next(after: intensity(for: muscle))
        var updated = tags.filter { $0.muscle != muscle }
        if let next {
            updated.append(MuscleTag(muscle: muscle, intensity: next))
        }
        tags = Muscle.allCases.compactMap { candidate in
            updated.first { $0.muscle == candidate }
        }
    }
}

#Preview {
    MuscleTagListPreviewHost()
}

/// `@Binding` needs an owner, so the preview keeps the tags in a host view.
private struct MuscleTagListPreviewHost: View {
    @State private var tags: [MuscleTag] = [
        MuscleTag(muscle: .chest, intensity: .primary),
        MuscleTag(muscle: .triceps, intensity: .secondary),
    ]

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            ScrollView {
                MuscleTagList(tags: $tags)
                    .padding(16)
            }
        }
    }
}
