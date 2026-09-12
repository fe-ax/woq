import SwiftUI

/// Gitflow lane decoration to the left of a row: a pastel stripe, an ink
/// connector and a node.
///
/// Decoration only (PLAN.md section 2), so the whole column is hidden from
/// VoiceOver. The column fills the height of its row; `connectsUp` /
/// `connectsDown` cut the stripe and the connector above or below the node so
/// the first and last rows of a section end cleanly.
///
/// Drawn with a `Canvas` since 2026-09-12 ("Set branch"): the node is no longer
/// always at the centre — the in-progress card pins it to the thumbnail row so
/// the set branch can fork off it — and one canvas expresses "stripe from A to
/// B, node at Y" more directly than a stack of rectangles whose heights depend
/// on the placement. Dynamic `Color`s resolve per appearance inside a `Canvas`
/// (PLAN.md pitfall 15), so the light/dark pairs still work.
struct LaneColumn: View {
    /// How the node is drawn.
    enum NodeStyle: Equatable {
        /// Card fill with an ink stroke: a queued exercise.
        case outlined
        /// Solid fill with an ink stroke: the in-progress exercise.
        case filled(Color)
    }

    /// Where the node sits in the column.
    enum NodePlacement: Equatable {
        /// Vertical centre of the row — every queue row.
        case centre
        /// A fixed distance from the top edge. The in-progress card uses it to
        /// put the node on the thumbnail's centre instead of the card's, so the
        /// node stays put while the card grows with every pending set (and so
        /// the set branch forks off it next to the exercise name).
        case top(inset: CGFloat)
    }

    var laneColor: Color
    var nodeStyle: NodeStyle
    var connectsUp: Bool
    var connectsDown: Bool
    var nodePlacement: NodePlacement = .centre

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, size in
            let centreX = size.width / 2
            let nodeY = nodeY(in: size.height)

            stripe(in: &context, centreX: centreX, nodeY: nodeY, height: size.height,
                   width: Tokens.laneStripe, color: laneColor)
            stripe(in: &context, centreX: centreX, nodeY: nodeY, height: size.height,
                   width: Tokens.line, color: Tokens.ink)

            let circle = CGRect(
                x: centreX - Tokens.node / 2,
                y: nodeY - Tokens.node / 2,
                width: Tokens.node,
                height: Tokens.node
            )
            context.fill(Path(ellipseIn: circle), with: .color(nodeFill))
            // Inset by half the line width so the stroke stays inside the 12 pt
            // node, like `strokeBorder` did before.
            context.stroke(
                Path(ellipseIn: circle.insetBy(dx: Tokens.line / 2, dy: Tokens.line / 2)),
                with: .color(Tokens.ink),
                lineWidth: Tokens.line
            )
        }
        .frame(width: Tokens.laneColumn)
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private func nodeY(in height: CGFloat) -> CGFloat {
        switch nodePlacement {
        case .centre: height / 2
        case .top(let inset): inset
        }
    }

    /// The two halves of one bar, each drawn only when its side connects.
    private func stripe(
        in context: inout GraphicsContext,
        centreX: CGFloat,
        nodeY: CGFloat,
        height: CGFloat,
        width: CGFloat,
        color: Color
    ) {
        let x = centreX - width / 2
        if connectsUp {
            context.fill(Path(CGRect(x: x, y: 0, width: width, height: nodeY)), with: .color(color))
        }
        if connectsDown {
            context.fill(
                Path(CGRect(x: x, y: nodeY, width: width, height: max(0, height - nodeY))),
                with: .color(color)
            )
        }
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
///
/// `bridgeTop` / `bridgeBottom` continue the lane stripes *through* the rule
/// (PLAN.md section 2, "Set branch", 2026-09-12): the blue in-progress lane runs
/// down to the rule and the yellow queue lane leaves it, so the graph is one
/// unbroken line from the card to the first queued exercise instead of two
/// stripes with a gap. Either side is `nil` when there is no lane there (no
/// exercise in progress, or an empty / filtered-away queue), and then nothing is
/// drawn on that side — a yellow stub under the rule with no row below it would
/// be a lane to nowhere.
///
/// The separator owns its own vertical breathing room so the bridge can cover
/// it; a `.padding(.vertical, 6)` at the call site would leave a 12 pt gap in
/// the lane.
struct LaneSeparator: View {
    var bridgeTop: Color?
    var bridgeBottom: Color?

    init(bridgeTop: Color? = nil, bridgeBottom: Color? = nil) {
        self.bridgeTop = bridgeTop
        self.bridgeBottom = bridgeBottom
    }

    /// Room above and below the rule, formerly applied by `MainScreen`.
    private static let verticalPadding: CGFloat = 6

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
        .padding(.vertical, Self.verticalPadding)
        // Behind the rule: the pastel stripes cross it, the ink connector runs
        // the full height, and the ink rule on top reads as the crossing line of
        // a git graph.
        .background(alignment: .leading) { bridge }
        // The rule itself is decoration; the "QUEUE" label is the only cue that
        // the queue section starts, so it stays as a heading VoiceOver can jump to.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var bridge: some View {
        if bridgeTop != nil || bridgeBottom != nil {
            Canvas(opaque: false, rendersAsynchronously: false) { context, size in
                let centreX = Tokens.laneColumn / 2
                // The rule is centred in the padded frame, so this is its y.
                let ruleY = size.height / 2

                func bar(width: CGFloat, color: Color, from: CGFloat, to: CGFloat) {
                    context.fill(
                        Path(CGRect(x: centreX - width / 2, y: from, width: width, height: to - from)),
                        with: .color(color)
                    )
                }

                if let bridgeTop {
                    bar(width: Tokens.laneStripe, color: bridgeTop, from: 0, to: ruleY)
                    bar(width: Tokens.line, color: Tokens.ink, from: 0, to: ruleY)
                }
                if let bridgeBottom {
                    bar(width: Tokens.laneStripe, color: bridgeBottom, from: ruleY, to: size.height)
                    bar(width: Tokens.line, color: Tokens.ink, from: ruleY, to: size.height)
                }
            }
            .frame(width: Tokens.laneColumn)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
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
                    connectsDown: true,
                    nodePlacement: .top(inset: 41)
                )
                OutlinedCard {
                    Text(verbatim: "In progress")
                        .foregroundStyle(Tokens.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 80)

            LaneSeparator(bridgeTop: Tokens.blue, bridgeBottom: Tokens.yellow)

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
