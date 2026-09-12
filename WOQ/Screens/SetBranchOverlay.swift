import SwiftUI

// The set branch: the pending sets of the in-progress card drawn as a git side
// branch (PLAN.md section 2, "Set branch", 2026-09-12).
//
// The card already lists the sets committed with its plus; this draws the same
// list the way the rest of the screen talks about work — as a lane. A pastel red
// stripe forks off the blue in-progress node, carries one outlined node per
// pending set and a dashed node on the fields row (the set being typed), and
// merges back into the blue lane at the bottom of the section, where the lane
// runs on through the QUEUE rule into the yellow queue lane. It is there from
// the first frame of the card: with nothing committed yet the fork runs straight
// to the dashed node and merges back (phone feedback 2026-09-12 — showing it
// only from the first plus read as "the branch starts at set two").
//
// Gradients (PLAN.md section 2, "Gradients", 2026-09-12): the graph should read
// as one flow, so no colour on it changes with a hard cut any more. The fork leg
// blends `Tokens.blue` -> `Tokens.red` along its length and the merge leg
// `Tokens.red` -> `Tokens.blue`, so the branch visibly grows out of the blue
// lane and dissolves back into it; only the straight run between the nodes is
// solid red. The ink line stays one solid black line over all three legs — the
// line is the graph, the colour only says which lane you are on.

/// Which row of the in-progress card a `SetBranchAnchor` came from.
nonisolated enum SetBranchAnchorKind: Equatable {
    /// One committed pending set, identified by its `PendingSet.id` so two
    /// identical sets stay two nodes.
    case set(UUID)
    /// The fields row: the set currently being typed.
    case current
}

/// One row's contribution to the branch.
nonisolated struct SetBranchAnchor {
    var kind: SetBranchAnchorKind
    var bounds: Anchor<CGRect>
}

/// Collects the row anchors of one in-progress section.
///
/// `nonisolated` on purpose: `PreferenceKey`'s requirements are nonisolated, and
/// the module compiles with `MainActor` as the default isolation (PLAN.md
/// pitfall 1), which would otherwise make the conformance actor-isolated.
nonisolated struct SetBranchAnchorsKey: PreferenceKey {
    static let defaultValue: [SetBranchAnchor] = []

    static func reduce(value: inout [SetBranchAnchor], nextValue: () -> [SetBranchAnchor]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    /// Reports this view's bounds as one node of the set branch.
    func setBranchAnchor(_ kind: SetBranchAnchorKind) -> some View {
        anchorPreference(key: SetBranchAnchorsKey.self, value: .bounds) {
            [SetBranchAnchor(kind: kind, bounds: $0)]
        }
    }

    /// Draws the set branch over this view (the in-progress section).
    ///
    /// Why an overlay on the *section* (the `HStack` of lane column + card)
    /// rather than something the card draws itself: the fork and the merge cross
    /// the card's outline, which the card's own children sit under, and the fork
    /// starts outside the card entirely — on the lane node, 28 pt to its left.
    /// The overlay sits above both and owns the whole curve.
    ///
    /// Why anchor preferences rather than fixed offsets: the pending rows and
    /// the fields row have Dynamic Type heights and animate in and out, so the
    /// only honest source for "where is set 3's node" is the row itself. Each
    /// row reports its bounds through `SetBranchAnchorsKey`; the overlay
    /// resolves them in its own coordinate space and follows the rows while they
    /// slide.
    ///
    /// - Parameters:
    ///   - forkFrom: bottom of the blue lane node, where the branch leaves the
    ///     main lane.
    ///   - branchX: x of the branch stripe inside the card
    ///     (`InProgressCard.branchX`).
    func setBranchOverlay(forkFrom: CGPoint, branchX: CGFloat) -> some View {
        overlayPreferenceValue(SetBranchAnchorsKey.self) { anchors in
            SetBranchShape(anchors: anchors, forkFrom: forkFrom, branchX: branchX)
        }
    }
}

/// The drawing half of `setBranchOverlay`, split out so the geometry stays
/// readable.
private struct SetBranchShape: View {
    var anchors: [SetBranchAnchor]
    var forkFrom: CGPoint
    var branchX: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Canvas(opaque: false, rendersAsynchronously: false) { context, size in
                guard let layout = layout(proxy: proxy, height: size.height) else { return }

                let legs = branchLegs(layout)
                // Same build-up as the lane column: pastel stripe first, ink
                // connector on top — but the stripe goes down in three passes so
                // the colour can travel from the blue lane into the red branch
                // and back. Dynamic `Color`s resolve per appearance inside a
                // `Canvas` (PLAN.md pitfall 15) and that holds for the colours of
                // a `Gradient` too, verified in dark mode 2026-09-12, so the
                // light/dark token pairs need no manual `resolve(in:)`.
                context.stroke(
                    legs.fork.path,
                    with: .linearGradient(
                        Gradient(colors: [Tokens.blue, Tokens.red]),
                        startPoint: legs.fork.start,
                        endPoint: legs.fork.end
                    ),
                    style: stripeStyle(Tokens.laneStripe)
                )
                if let run = legs.run {
                    context.stroke(run, with: .color(Tokens.red), style: stripeStyle(Tokens.laneStripe))
                }
                context.stroke(
                    legs.merge.path,
                    with: .linearGradient(
                        Gradient(colors: [Tokens.red, Tokens.blue]),
                        startPoint: legs.merge.start,
                        endPoint: legs.merge.end
                    ),
                    style: stripeStyle(Tokens.laneStripe)
                )
                context.stroke(legs.whole, with: .color(Tokens.ink), style: stripeStyle(Tokens.line))

                for y in layout.setNodeYs {
                    node(in: &context, y: y, dashed: false)
                }
                if let currentY = layout.currentNodeY {
                    node(in: &context, y: currentY, dashed: true)
                }
            }
            // Decoration over live controls: it must never eat a tap on the ×
            // of a pending row or on the stepper buttons underneath.
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        // The rows animate with `.snappy` (MainScreen wraps append / remove in
        // it) and the anchors follow those positions by themselves; the count
        // animation only smooths the redraw when a row comes or goes.
        .animation(.snappy, value: anchors.count)
    }

    // MARK: - Geometry

    private struct Layout {
        var setNodeYs: [CGFloat]
        var currentNodeY: CGFloat?
        var sectionHeight: CGFloat
        /// Where the straight part of the branch ends: the typed set's node, or
        /// the last committed one when the fields row did not report.
        var lastY: CGFloat
    }

    /// `nil` (draw nothing) only while no row has reported yet — the first layout
    /// pass. From then on the fields row alone is enough for a branch.
    private func layout(proxy: GeometryProxy, height: CGFloat) -> Layout? {
        var setYs: [CGFloat] = []
        var currentY: CGFloat?

        for anchor in anchors {
            let rect = proxy[anchor.bounds]
            switch anchor.kind {
            case .set:
                setYs.append(rect.midY)
            case .current:
                // The caption sits above the outlined box, so the node centres
                // on the box, not on caption + box.
                currentY = rect.maxY - InProgressCard.fieldBoxHeight / 2
            }
        }

        guard let lastY = currentY ?? setYs.max() else { return nil }
        setYs.sort()
        return Layout(
            setNodeYs: setYs,
            currentNodeY: currentY,
            sectionHeight: height,
            lastY: lastY
        )
    }

    /// One leg of the branch together with the axis its gradient runs along:
    /// the straight line from where the leg starts to where it ends, which is
    /// the chord of the S-curve, so the blend follows the leg's direction.
    private struct Leg {
        var path: Path
        var start: CGPoint
        var end: CGPoint
    }

    /// The branch cut into the three pieces the stripe is painted in.
    private struct Legs {
        var fork: Leg
        /// `nil` when the fork lands straight on the last node (no pending set
        /// yet): the run would be zero length, and a zero-length gradient axis
        /// is undefined. Nothing is lost — the fork already ends on that node.
        var run: Path?
        var merge: Leg
        /// Fork + run + merge in one path, for the single solid ink line.
        var whole: Path
    }

    /// Fork, straight run through the nodes, merge.
    ///
    /// Both curves are cubics with their control points on the same y (the
    /// midpoint of the leg), which gives the symmetric S a git graph draws when
    /// a branch leaves or rejoins a lane.
    ///
    /// They are separate subpaths so each can take its own shading. The fork
    /// ends and the run starts on the same point with the same (vertical)
    /// tangent, so the butt caps of the two strokes meet without a seam.
    private func branchLegs(_ layout: Layout) -> Legs {
        // With no pending set the fork lands on the dashed node directly and
        // the straight run has zero length.
        let firstY = layout.setNodeYs.first ?? layout.lastY
        let forkEnd = CGPoint(x: branchX, y: firstY)

        var fork = Path()
        fork.move(to: forkFrom)
        let forkMid = (forkFrom.y + firstY) / 2
        fork.addCurve(
            to: forkEnd,
            control1: CGPoint(x: forkFrom.x, y: forkMid),
            control2: CGPoint(x: branchX, y: forkMid)
        )

        var run: Path?
        if layout.lastY > firstY {
            var line = Path()
            line.move(to: forkEnd)
            line.addLine(to: CGPoint(x: branchX, y: layout.lastY))
            run = line
        }

        // Out of the bottom of the last node and back to the lane, ending
        // exactly on the section's bottom edge where the blue lane continues
        // (the separator's bridge takes over from there — and takes over in
        // blue, so the two gradients meet on the same colour).
        let mergeStart = CGPoint(x: branchX, y: layout.lastY + Tokens.node / 2)
        let mergeEnd = CGPoint(x: forkFrom.x, y: layout.sectionHeight)
        let mergeMid = (mergeStart.y + layout.sectionHeight) / 2
        var merge = Path()
        merge.move(to: mergeStart)
        merge.addCurve(
            to: mergeEnd,
            control1: CGPoint(x: branchX, y: mergeMid),
            control2: CGPoint(x: forkFrom.x, y: mergeMid)
        )

        var whole = fork
        if let run { whole.addPath(run) }
        whole.addPath(merge)

        return Legs(
            fork: Leg(path: fork, start: forkFrom, end: forkEnd),
            run: run,
            merge: Leg(path: merge, start: mergeStart, end: mergeEnd),
            whole: whole
        )
    }

    private func stripeStyle(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .butt, lineJoin: .round)
    }

    /// A branch node: card fill with an ink stroke, dashed for the set that is
    /// still being typed (it is not committed yet).
    private func node(in context: inout GraphicsContext, y: CGFloat, dashed: Bool) {
        let rect = CGRect(
            x: branchX - Tokens.node / 2,
            y: y - Tokens.node / 2,
            width: Tokens.node,
            height: Tokens.node
        )
        context.fill(Path(ellipseIn: rect), with: .color(Tokens.card))
        context.stroke(
            Path(ellipseIn: rect.insetBy(dx: Tokens.line / 2, dy: Tokens.line / 2)),
            with: .color(Tokens.ink),
            style: StrokeStyle(lineWidth: Tokens.line, dash: dashed ? [2.5, 2.5] : [])
        )
    }
}
