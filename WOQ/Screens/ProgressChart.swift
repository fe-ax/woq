import SwiftUI

// The per-exercise progress graph (decided 2026-09-12 evening): the estimated 1RM of every
// execution, drawn in the app's lane language — one yellow lane running left to right through
// an outlined node per session.
//
// Why a lane and not an axis-and-grid chart: the rest of the app talks about work as a git
// graph (the queue lane, the set branch), and the history *is* the queue lane after the fact —
// so the graph is the same stripe, the same 12 pt nodes and the same 1.5 pt ink line, turned
// on its side. There are no axes, no gridlines and no tick marks; the numbers sit on the nodes
// where the eye already is. The oldest execution is on the left, the newest on the right, which
// is also where the graph opens.
//
// Beyond the brief (choices made here, PLAN.md section 2):
//   * the personal record is a blue node AND the two lane segments touching it blend
//     `Tokens.yellow` -> `Tokens.blue` -> `Tokens.yellow`, the same way the set branch grows out
//     of the blue lane and dissolves back into it. The lane "swells" at the best session rather
//     than a chip being pasted onto a yellow line.
//   * the selection is one floating marker (blue disc + ink ring) that SLIDES along the lane
//     with `.snappy` when another column is tapped, instead of the canvas snapping. It is a
//     SwiftUI view over the canvas exactly so it can animate its position.
//   * a bodyweight execution in a 1RM series sits on its own baseline, a hair below the lowest
//     weighted node, as a dashed hollow node labelled "BW" — the same dashed node the in-progress
//     card uses for "not committed yet", here meaning "no 1RM to plot".
//   * no axis line is drawn. "Baseline" is a position, not a rule; a horizontal line would be
//     the first gridline in an app that has none.

// MARK: - Strings

/// Text the progress section needs that `Formatting` does not own (it is chart wording, not
/// set wording, and `WOQ/Model` is not this file's to change).
nonisolated enum ProgressChartText {

    /// The muted caption next to the "Progress" title: what the numbers on the nodes mean.
    static func caption(for metric: ProgressSeries.Metric) -> String {
        switch metric {
        case .oneRepMax: String(localized: "Estimated 1RM \u{00B7} kg")
        case .reps: String(localized: "Peak reps")
        }
    }

    /// The label under a node: "31 Aug". Day and month only — the graph is read as a sequence,
    /// and a year on every column would double the width of the busiest row.
    static func shortDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle().day().month(.abbreviated))
    }

    /// The spoken date in the accessibility summary: "31 August 2026".
    static func longDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle().day().month(.wide).year())
    }

    /// "1 session" / "12 sessions" — hand-written like `Formatting.setCountString`, English only.
    static func sessionCountString(_ count: Int) -> String {
        count == 1 ? String(localized: "1 session") : String(localized: "\(count) sessions")
    }

    /// The unit spoken after the best value.
    static func unitName(for metric: ProgressSeries.Metric) -> String {
        switch metric {
        case .oneRepMax: String(localized: "kilograms")
        case .reps: String(localized: "reps")
        }
    }
}

// MARK: - Geometry

/// Where every node of the graph sits. Pure numbers, so the layout can be reasoned about
/// (and checked) without a view; `nonisolated` for the same reason `Formatting` is.
nonisolated struct ProgressChartGeometry {

    /// One column per execution; the node is on its centre line.
    let columnWidth: CGFloat
    /// Height of the drawing area, label row excluded.
    let plotHeight: CGFloat
    /// Room above the highest node for its value label (and the PR chip).
    let topInset: CGFloat
    /// Room under the lowest node, so it never touches the bottom edge.
    let bottomInset: CGFloat
    let count: Int

    /// Lowest plotted value and the span above it; `span == 0` when every execution scored the
    /// same (then the lane runs flat through the middle).
    private let low: Double
    private let span: Double
    private let metric: ProgressSeries.Metric
    /// True when at least one execution has no 1RM at all and needs the baseline.
    private let hasBaseline: Bool

    /// Gap between the bodyweight baseline and the lowest weighted node, so "no weight at all"
    /// is visibly a different row and not just the worst session.
    private static let baselineGap: CGFloat = 20

    init(
        series: ProgressSeries,
        columnWidth: CGFloat,
        plotHeight: CGFloat,
        topInset: CGFloat,
        bottomInset: CGFloat
    ) {
        self.columnWidth = columnWidth
        self.plotHeight = plotHeight
        self.topInset = topInset
        self.bottomInset = bottomInset
        self.count = series.points.count
        self.metric = series.metric
        self.hasBaseline = series.points.contains { Self.isBaseline($0, metric: series.metric) }

        // The scale is built from the values that actually carry a number. A bodyweight point
        // in a 1RM series has `value == 0`, and letting that 0 into the range would flatten
        // 100 kg of history into the top third of the card.
        let plotted = series.points
            .filter { !Self.isBaseline($0, metric: series.metric) }
            .map(\.value)
        self.low = plotted.min() ?? 0
        self.span = (plotted.max() ?? 0) - (plotted.min() ?? 0)
    }

    /// Total width of the scrollable content.
    var contentWidth: CGFloat { columnWidth * CGFloat(count) }

    /// y of the highest a node can go.
    var topY: CGFloat { topInset }

    /// y of the bodyweight baseline — the lowest row of the drawing area.
    var baselineY: CGFloat { plotHeight - bottomInset }

    /// y of the lowest *weighted* node.
    var bottomY: CGFloat { baselineY - (hasBaseline ? Self.baselineGap : 0) }

    /// Centre line of column `index`.
    func x(_ index: Int) -> CGFloat { columnWidth * (CGFloat(index) + 0.5) }

    /// A bodyweight execution in a 1RM series: it has no estimate to plot.
    /// In a `.reps` series EVERY point is bodyweight (that is what makes it a reps series),
    /// so the metric has to be part of the test.
    static func isBaseline(_ point: ProgressSeries.Point, metric: ProgressSeries.Metric) -> Bool {
        metric == .oneRepMax && point.isBodyweight
    }

    func isBaseline(_ point: ProgressSeries.Point) -> Bool {
        Self.isBaseline(point, metric: metric)
    }

    /// Where this execution's node sits vertically.
    func y(of point: ProgressSeries.Point) -> CGFloat {
        if isBaseline(point) { return baselineY }
        // Every execution scored the same (or there is only one): mid-height, so a flat
        // history reads as flat instead of as a record at the ceiling.
        guard span > 0 else { return (topY + bottomY) / 2 }
        let fraction = (point.value - low) / span
        return bottomY - CGFloat(fraction) * (bottomY - topY)
    }

    func point(of point: ProgressSeries.Point, at index: Int) -> CGPoint {
        CGPoint(x: x(index), y: y(of: point))
    }
}

// MARK: - Chart

/// The "Progress" card of the detail sheet: the lane graph, horizontally scrollable, with the
/// selected session written out underneath.
///
/// Takes a finished `ProgressSeries` rather than the exercise, so the detail sheet decides
/// whether there is anything to show at all (an exercise with no executions has no section).
struct ProgressChart: View {
    var series: ProgressSeries

    /// nil = the newest execution, which is what the card opens on. Kept as an id, not an
    /// index, so editing or deleting a set somewhere in the history cannot move the selection
    /// onto a different session behind the user's back — it falls back to the newest instead.
    @State private var selectedID: UUID?

    /// The column grid follows Dynamic Type: at XXXL the value labels and the "31 Aug" row are
    /// half again as wide, and a fixed 64 pt column would overlap them.
    @ScaledMetric(relativeTo: .caption) private var columnWidth: CGFloat = 64
    @ScaledMetric(relativeTo: .caption) private var plotHeight: CGFloat = 150
    /// Fixed slot the value label is bottom-aligned in, so its distance to the node is the same
    /// on every column whatever the text does.
    @ScaledMetric(relativeTo: .caption) private var labelSlot: CGFloat = 24

    /// Width of the scroll view, so a history that fits can be pinned to the LEFT while a
    /// longer one still opens on its right-hand end (`defaultScrollAnchor(.trailing)` alone
    /// pushes three sessions against the right edge, which reads as a graph scrolled away).
    @State private var viewportWidth: CGFloat = 0

    /// Gap between a node and the label above it.
    private static let labelGap: CGFloat = 4
    /// Diameter of the ring around the selected node.
    private static let selectionRing: CGFloat = Tokens.node + 8

    var body: some View {
        OutlinedCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                plot

                Rectangle()
                    .fill(Tokens.ink)
                    .frame(height: Tokens.hairline)

                caption
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(selectedCaption)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(by: 1)
            case .decrement: move(by: -1)
            @unknown default: break
            }
        }
    }

    // MARK: - Plot

    private var plot: some View {
        let geometry = self.geometry

        return ScrollView(.horizontal) {
            ZStack(alignment: .topLeading) {
                lane(geometry)
                labels(geometry)
                selectionMarker(geometry)
                dates(geometry)
                tapTargets(geometry)
            }
            .frame(width: geometry.contentWidth, height: geometry.plotHeight + dateRowHeight)
            .padding(.horizontal, Tokens.cardPadding)
            .padding(.top, 6)
            .frame(minWidth: viewportWidth, alignment: .leading)
        }
        // Opens on the newest execution, which is the one the caption starts on, and stays
        // pinned there when a set is added and the content grows.
        .defaultScrollAnchor(.trailing)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { viewportWidth = $0 }
        // A system scroll bar under a paper card would be the only grey pill in the app; the
        // columns are cut off at the card's edge, which says "there is more" by itself.
        .scrollIndicators(.hidden)
    }

    /// The stripe and the nodes: the same build-up as `LaneColumn` (pastel stripe, ink
    /// connector on top, nodes over both), only running horizontally.
    private func lane(_ geometry: ProgressChartGeometry) -> some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, _ in
            let points = series.points
            var whole = Path()

            for index in points.indices.dropLast() {
                let from = geometry.point(of: points[index], at: index)
                let to = geometry.point(of: points[index + 1], at: index + 1)
                let segment = segmentPath(from: from, to: to)
                whole.addPath(segment)

                context.stroke(
                    segment,
                    with: shading(from: points[index], to: points[index + 1], start: from, end: to),
                    style: StrokeStyle(lineWidth: Tokens.laneStripe, lineCap: .round)
                )
            }

            // One solid ink line over every segment — the line is the graph, the colour only
            // says which session was the best (same rule as the set branch).
            if !whole.isEmpty {
                context.stroke(
                    whole,
                    with: .color(Tokens.ink),
                    style: StrokeStyle(lineWidth: Tokens.line, lineCap: .round)
                )
            }

            for (index, point) in points.enumerated() {
                node(
                    in: &context,
                    at: geometry.point(of: point, at: index),
                    fill: point.isRecord ? Tokens.blue : Tokens.card,
                    dashed: geometry.isBaseline(point)
                )
            }
        }
        .frame(width: geometry.contentWidth, height: geometry.plotHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Between two heights: a cubic with both control points on the midway x, which gives the
    /// symmetric S a git graph draws — the mirror image of the set branch's fork and merge,
    /// whose control points share a y. Same height: a plain straight run.
    private func segmentPath(from: CGPoint, to: CGPoint) -> Path {
        var path = Path()
        path.move(to: from)
        if abs(from.y - to.y) < 0.5 {
            path.addLine(to: to)
        } else {
            let midX = (from.x + to.x) / 2
            path.addCurve(
                to: to,
                control1: CGPoint(x: midX, y: from.y),
                control2: CGPoint(x: midX, y: to.y)
            )
        }
        return path
    }

    /// Yellow everywhere, except the two segments that touch the record: they blend into blue
    /// and back out, so the best session is a swelling of the lane rather than a dot on it.
    /// Dynamic `Color`s (and gradient stops) resolve per appearance inside a `Canvas`
    /// (PLAN.md pitfall 15).
    private func shading(
        from: ProgressSeries.Point,
        to: ProgressSeries.Point,
        start: CGPoint,
        end: CGPoint
    ) -> GraphicsContext.Shading {
        let colors: [Color]
        switch (from.isRecord, to.isRecord) {
        case (true, _): colors = [Tokens.blue, Tokens.yellow]
        case (_, true): colors = [Tokens.yellow, Tokens.blue]
        default: return .color(Tokens.yellow)
        }
        return .linearGradient(Gradient(colors: colors), startPoint: start, endPoint: end)
    }

    /// A lane node: card fill with an ink stroke, dashed when the execution has no 1RM.
    private func node(
        in context: inout GraphicsContext,
        at centre: CGPoint,
        fill: Color,
        dashed: Bool
    ) {
        let rect = CGRect(
            x: centre.x - Tokens.node / 2,
            y: centre.y - Tokens.node / 2,
            width: Tokens.node,
            height: Tokens.node
        )
        context.fill(Path(ellipseIn: rect), with: .color(fill))
        context.stroke(
            Path(ellipseIn: rect.insetBy(dx: Tokens.line / 2, dy: Tokens.line / 2)),
            with: .color(Tokens.ink),
            style: StrokeStyle(lineWidth: Tokens.line, dash: dashed ? [2.5, 2.5] : [])
        )
    }

    // MARK: - Labels

    /// The value over each node ("107", or "BW" for a bodyweight session), with the PR chip
    /// beside the record's number.
    private func labels(_ geometry: ProgressChartGeometry) -> some View {
        ForEach(Array(series.points.enumerated()), id: \.element.id) { index, point in
            HStack(spacing: 4) {
                Text(valueLabel(for: point))
                    .appNumberFont(.caption, weight: point.isRecord ? .bold : .regular)
                    .foregroundStyle(geometry.isBaseline(point) ? Tokens.muted : Tokens.ink)

                if point.isRecord {
                    recordChip
                }
            }
            .fixedSize()
            // Bottom-aligned in a fixed slot: the gap to the node stays `labelGap` whether the
            // label is "8", "107" or "107 PR".
            .frame(height: labelSlot, alignment: .bottom)
            .position(
                x: geometry.x(index),
                y: geometry.y(of: point) - Tokens.node / 2 - Self.labelGap - labelSlot / 2
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The history's "peak" chip, re-cut for the whole series: same shape, same blue, same
    /// fixed dark ink (it sits on a pastel that stays pastel in both appearances).
    private var recordChip: some View {
        Text(String(localized: "PR"))
            .appFont(.caption2, weight: .bold)
            .foregroundStyle(Tokens.inkOnPastel)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .fill(Tokens.blue)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
            )
    }

    /// "31 Aug" under every column; the selected one steps up from muted to ink.
    private func dates(_ geometry: ProgressChartGeometry) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(series.points.enumerated()), id: \.element.id) { _, point in
                let isSelected = point.id == selected?.id
                Text(ProgressChartText.shortDate(point.date))
                    .appNumberFont(.caption2, weight: isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Tokens.ink : Tokens.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: geometry.columnWidth)
            }
        }
        .frame(height: dateRowHeight)
        .offset(y: geometry.plotHeight)
        .animation(.snappy, value: selected?.id)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The selected node, drawn over the canvas instead of in it so it can SLIDE: `.position`
    /// animates, a canvas redraw does not.
    @ViewBuilder
    private func selectionMarker(_ geometry: ProgressChartGeometry) -> some View {
        if let selected, let index = index(of: selected) {
            ZStack {
                Circle()
                    .fill(Tokens.blue)
                Circle()
                    .strokeBorder(
                        Tokens.ink,
                        style: StrokeStyle(
                            lineWidth: Tokens.line,
                            dash: geometry.isBaseline(selected) ? [2.5, 2.5] : []
                        )
                    )
            }
            .frame(width: Tokens.node, height: Tokens.node)
            .overlay {
                Circle()
                    .strokeBorder(Tokens.ink, lineWidth: Tokens.hairline)
                    .frame(width: Self.selectionRing, height: Self.selectionRing)
            }
            .position(geometry.point(of: selected, at: index))
            .animation(.snappy, value: selected.id)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// One invisible column per execution over the whole plot, so the tap area is the column
    /// and not the 12 pt node.
    private func tapTargets(_ geometry: ProgressChartGeometry) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(series.points.enumerated()), id: \.element.id) { _, point in
                Color.clear
                    .frame(width: geometry.columnWidth)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedID = point.id }
            }
        }
        .frame(height: geometry.plotHeight + dateRowHeight)
    }

    // MARK: - Caption

    /// What the selected node stands for, written the way the history writes it.
    private var caption: some View {
        Text(selectedCaption)
            .appNumberFont(.caption)
            .foregroundStyle(Tokens.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Tokens.cardPadding)
            .animation(.snappy, value: selected?.id)
            .accessibilityHidden(true)
    }

    // MARK: - Derived

    private var geometry: ProgressChartGeometry {
        ProgressChartGeometry(
            series: series,
            columnWidth: columnWidth,
            plotHeight: plotHeight,
            topInset: labelSlot + Self.labelGap + Tokens.node / 2,
            bottomInset: Tokens.node / 2 + 8
        )
    }

    /// Room for the "31 Aug" row, scaled like everything else in the card.
    private var dateRowHeight: CGFloat { labelSlot }

    /// The selected execution — the newest until one is tapped, and back to the newest if the
    /// selected one is deleted from the history above.
    private var selected: ProgressSeries.Point? {
        series.points.first { $0.id == selectedID } ?? series.points.last
    }

    private func index(of point: ProgressSeries.Point) -> Int? {
        series.points.firstIndex { $0.id == point.id }
    }

    private func valueLabel(for point: ProgressSeries.Point) -> String {
        ProgressChartGeometry.isBaseline(point, metric: series.metric)
            ? Formatting.weightString(halfKilos: nil)
            : ProgressSeries.valueLabel(point.value, metric: series.metric)
    }

    /// "31 Aug 2026 at 09:06 \u{00B7} 85 kg \u{00D7} 8 \u{00B7} 4 sets".
    private var selectedCaption: String {
        guard let selected else { return "" }
        let stamp = Formatting.absoluteDateTimeString(selected.date)
        let peak = Formatting.executionString(
            peak: selected.execution.peak,
            setCount: selected.setCount
        )
        return "\(stamp) \u{00B7} \(peak)"
    }

    /// "Progress, 12 sessions, best 107 kilograms on 31 August 2026".
    private var accessibilityLabel: String {
        let sessions = ProgressChartText.sessionCountString(series.points.count)
        guard let record = series.record else {
            return String(localized: "Progress, \(sessions)")
        }
        let best = ProgressSeries.valueLabel(record.value, metric: series.metric)
        let unit = ProgressChartText.unitName(for: series.metric)
        let day = ProgressChartText.longDate(record.date)
        return String(localized: "Progress, \(sessions), best \(best) \(unit) on \(day)")
    }

    /// VoiceOver's adjustable action: increment walks towards the newest session.
    private func move(by step: Int) {
        guard let selected, let index = index(of: selected) else { return }
        let next = min(max(index + step, 0), series.points.count - 1)
        guard next != index else { return }
        withAnimation(.snappy) { selectedID = series.points[next].id }
    }
}
