import SwiftUI

/// Gitflow lane decoration to the left of a row: a pastel stripe, an ink
/// connector and a node at the vertical centre.
///
/// Decoration only (PLAN.md section 2), so the whole column is hidden from
/// VoiceOver. The column fills the height of its row; `connectsUp` /
/// `connectsDown` cut the stripe and the connector above or below the node so
/// the first and last rows of a section end cleanly.
struct LaneColumn: View {
    /// How the node at the centre of the column is drawn.
    enum NodeStyle: Equatable {
        /// Card fill with an ink stroke: a queued exercise.
        case outlined
        /// Solid fill with an ink stroke: the in-progress exercise.
        case filled(Color)
    }

    var laneColor: Color
    var nodeStyle: NodeStyle
    var connectsUp: Bool
    var connectsDown: Bool

    var body: some View {
        ZStack {
            halves(width: Tokens.laneStripe, color: laneColor)
            halves(width: Tokens.line, color: Tokens.ink)
            node
        }
        .frame(width: Tokens.laneColumn)
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    /// Two equal vertical bars meeting at the node, each drawn only when its
    /// side connects.
    private func halves(width: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(connectsUp ? color : .clear)
            Rectangle().fill(connectsDown ? color : .clear)
        }
        .frame(width: width)
    }

    private var node: some View {
        Circle()
            .fill(nodeFill)
            .frame(width: Tokens.node, height: Tokens.node)
            .overlay(
                Circle().strokeBorder(Tokens.ink, lineWidth: Tokens.line)
            )
    }

    private var nodeFill: Color {
        switch nodeStyle {
        case .outlined: Tokens.card
        case .filled(let color): color
        }
    }
}

/// Horizontal ink rule with a small caps "QUEUE" label, between the
/// in-progress section and the queue.
struct LaneSeparator: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Tokens.ink)
                .frame(height: Tokens.line)

            Text(String(localized: "QUEUE"))
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(1)
                .foregroundStyle(Tokens.muted)
                .padding(.horizontal, 6)
                .background(Tokens.paper)
                .padding(.leading, Tokens.laneColumn)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // The rule itself is decoration; the "QUEUE" label is the only cue that
        // the queue section starts, so it stays as a heading VoiceOver can jump to.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                LaneColumn(
                    laneColor: Tokens.blue,
                    nodeStyle: .filled(Tokens.blue),
                    connectsUp: false,
                    connectsDown: true
                )
                OutlinedCard {
                    Text(verbatim: "In progress")
                        .foregroundStyle(Tokens.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 80)

            LaneSeparator()

            HStack(spacing: 0) {
                LaneColumn(
                    laneColor: Tokens.yellow,
                    nodeStyle: .outlined,
                    connectsUp: true,
                    connectsDown: true
                )
                OutlinedCard {
                    Text(verbatim: "Queued")
                        .foregroundStyle(Tokens.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 64)
        }
        .padding(.horizontal, 16)
    }
}
