import SwiftUI

/// Expandable panel under the search field: tap muscles on a big front/back
/// figure to filter the queue by muscle (PLAN.md section 2, "Search").
///
/// The figures are a picker, not an exercise, so they carry no intensity tags:
/// untouched muscles stay the card colour and selected ones fill blue. Selection
/// is view state only — it is never persisted and never touches the store.
struct MuscleFilterPanel: View {
    @Binding var selection: Set<Muscle>
    @Binding var isPresented: Bool

    var body: some View {
        OutlinedCard {
            VStack(alignment: .leading, spacing: 10) {
                FigurePairView(
                    tags: [],
                    size: .large,
                    palette: Tokens.figurePalette,
                    selection: selection,
                    onTapMuscle: toggle
                )
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "Muscle figure"))
                .accessibilityHint(String(localized: "Tap a muscle to filter the queue"))

                HStack(spacing: 8) {
                    Text(String(localized: "Tap muscles to filter"))
                        .appFont(.subheadline)
                        .foregroundStyle(Tokens.muted)

                    Spacer(minLength: 8)

                    Button {
                        withAnimation(.snappy) { isPresented = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Tokens.ink)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Tokens.card))
                            .overlay(Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.hairline))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Close the muscle filter"))
                }

                if !selected.isEmpty {
                    ChipWrap(spacing: 6, lineSpacing: 6) {
                        ForEach(selected) { muscle in
                            chip(for: muscle)
                        }
                    }

                    Button(String(localized: "Clear")) {
                        withAnimation(.snappy) { selection.removeAll() }
                    }
                    .buttonStyle(.paper)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .animation(.snappy, value: selection)
    }

    /// Selected muscles in `Muscle.allCases` order, so the chips never reshuffle.
    private var selected: [Muscle] {
        Muscle.allCases.filter { selection.contains($0) }
    }

    private func chip(for muscle: Muscle) -> some View {
        Button {
            withAnimation(.snappy) { _ = selection.remove(muscle) }
        } label: {
            HStack(spacing: 5) {
                Text(muscle.displayName)
                    .appFont(.footnote, weight: .semibold)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            // Blue is a pastel in both appearances, so the label stays dark.
            .foregroundStyle(Tokens.inkOnPastel)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.blue)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(muscle.displayName)
        .accessibilityHint(String(localized: "Removes this muscle from the filter"))
    }

    private func toggle(_ muscle: Muscle) {
        withAnimation(.snappy) {
            if selection.contains(muscle) {
                selection.remove(muscle)
            } else {
                selection.insert(muscle)
            }
        }
    }
}

// MARK: - Chip wrapping

/// Minimal flow layout: lays the chips out left to right and wraps to a new
/// line when the proposed width runs out. `LazyVGrid` cannot do this (its
/// columns are fixed) and there is no stock wrapping stack.
nonisolated struct ChipWrap: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let lines = lines(for: subviews, maxWidth: maxWidth)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.map(\.height).reduce(0, +)
            + lineSpacing * CGFloat(max(lines.count - 1, 0))
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var y = bounds.minY
        for line in lines(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for item in line.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y + (line.height - item.size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Item {
        var index: Int
        var size: CGSize
    }

    private struct Line {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(for subviews: Subviews, maxWidth: CGFloat) -> [Line] {
        var result: [Line] = []
        var current = Line()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.items.isEmpty ? size.width : current.width + spacing + size.width
            if !current.items.isEmpty, needed > maxWidth {
                result.append(current)
                current = Line()
            }
            current.width = current.items.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.items.append(Item(index: index, size: size))
        }

        if !current.items.isEmpty { result.append(current) }
        return result
    }
}

#Preview {
    MuscleFilterPanelPreviewHost()
}

/// `@Binding` needs an owner, so the preview keeps the selection in a host view.
private struct MuscleFilterPanelPreviewHost: View {
    @State private var selection: Set<Muscle> = [.chest, .lats, .quads]
    @State private var isPresented = true

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()
            MuscleFilterPanel(selection: $selection, isPresented: $isPresented)
                .padding(16)
        }
    }
}
