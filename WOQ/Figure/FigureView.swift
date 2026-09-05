import SwiftUI

// MARK: - Palette

/// Colours used by the figure. Defaults are the PLAN.md tokens; the UI wave can
/// inject `Tokens`-backed colours later without touching the drawing code.
nonisolated struct FigurePalette: Sendable {
    var card: Color
    var ink: Color
    var primary: Color
    var secondary: Color
    var stabiliser: Color
    /// Fill for a muscle in `FigureView.selection` (the filter picker). Same
    /// value as `Tokens.blue`; it wins over any intensity fill.
    var selected: Color = hex(0xA8C8F0)

    static let `default` = FigurePalette(
        card: hex(0xFFFDF8),
        ink: hex(0x111111),
        primary: hex(0xF4A6A6),
        secondary: hex(0xF6E3A1),
        stabiliser: hex(0xFBF2CF)
    )

    /// Fill for a region: the intensity colour, or the plain card colour when
    /// the muscle is not tagged.
    func fill(for intensity: Intensity?) -> Color {
        switch intensity {
        case .primary: primary
        case .secondary: secondary
        case .stabiliser: stabiliser
        case nil: card
        }
    }

    static func hex(_ value: UInt32) -> Color {
        Color(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Size

/// The two sizes the figure is drawn at. Line widths are in points and do not
/// scale with the figure; below ~60 pt tall the region strokes turn to mud, so
/// the thumbnail keeps fills and the silhouette only (PLAN.md pitfall 17).
nonisolated enum FigureSize: Sendable, CaseIterable {
    case thumbnail
    case large

    /// Fixed frame for the thumbnail; `nil` means "fill what you are given".
    var fixedSize: CGSize? {
        switch self {
        case .thumbnail: CGSize(width: 22, height: 48)
        case .large: nil
        }
    }

    var outlineWidth: CGFloat {
        switch self {
        case .thumbnail: 0.5
        case .large: 1
        }
    }

    /// `nil` = no region strokes at all.
    var regionStrokeWidth: CGFloat? {
        switch self {
        case .thumbnail: nil
        case .large: 0.75
        }
    }

    /// `nil` = decoration omitted.
    var decorationStrokeWidth: CGFloat? {
        switch self {
        case .thumbnail: nil
        case .large: 0.75
        }
    }

    /// Gap between the front and the back figure in `FigurePairView`.
    var pairSpacing: CGFloat {
        switch self {
        case .thumbnail: 4
        case .large: 8
        }
    }
}

// MARK: - Figure

/// One stylised human figure (front or back) with the tagged muscles filled.
///
/// Two independent layers of colour: `tags` paint intensity colours (an
/// exercise) and `selection` paints `palette.selected` (the muscle filter).
/// Selection wins where both apply.
///
/// When `onTapMuscle` is set the figure becomes a picker: taps are hit-tested
/// against the muscle regions with the inverse of `fitTransform`, and taps on
/// the body, the outline or empty canvas are ignored. Without the callback no
/// gesture is attached at all, so a figure inside a tappable row (ExerciseRow)
/// keeps letting the row's own tap through.
struct FigureView: View {
    var side: FigureSide
    var tags: [MuscleTag]
    var size: FigureSize
    var palette: FigurePalette = .default
    /// Muscles drawn in the selection colour, on top of any intensity fill.
    var selection: Set<Muscle> = []
    /// Set to make the figure tappable; called with the muscle that was hit.
    var onTapMuscle: ((Muscle) -> Void)?

    /// Last laid-out canvas size, needed to invert the fit transform for taps.
    /// Only tracked when the figure is tappable.
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        let figure = Canvas(opaque: false, rendersAsynchronously: false) { context, canvasSize in
            draw(in: &context, canvasSize: canvasSize)
        }
        .frame(width: size.fixedSize?.width, height: size.fixedSize?.height)
        .aspectRatio(FigurePaths.viewBox.width / FigurePaths.viewBox.height, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityLabel(side: side, tags: tags))

        if let onTapMuscle {
            figure
                .onGeometryChange(for: CGSize.self) { $0.size } action: { canvasSize = $0 }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard
                        let muscle = Self.muscle(
                            at: location,
                            canvasSize: canvasSize,
                            side: side
                        )
                    else { return }
                    onTapMuscle(muscle)
                }
        } else {
            figure
        }
    }

    // MARK: Drawing

    private func draw(in context: inout GraphicsContext, canvasSize: CGSize) {
        let regions = FigurePaths.regions(for: side)
        let transform = Self.fitTransform(FigurePaths.viewBox, into: canvasSize)
        let intensities = Self.intensities(for: tags, side: side)
        let selected = Self.selected(from: selection, side: side)

        // The outline doubles as the body shape: fill it first, stroke it last.
        for region in regions where region.kind == .outline {
            context.fill(region.path.applying(transform), with: .color(palette.card))
        }

        for region in regions {
            switch region.kind {
            case .outline:
                continue
            case .decoration:
                guard let width = size.decorationStrokeWidth else { continue }
                context.stroke(
                    region.path.applying(transform),
                    with: .color(palette.ink),
                    style: Self.stroke(width)
                )
            case .body:
                fill(region, with: palette.card, transform: transform, in: &context)
            case .muscle(let muscle):
                fill(
                    region,
                    with: selected.contains(muscle)
                        ? palette.selected
                        : palette.fill(for: intensities[muscle]),
                    transform: transform,
                    in: &context
                )
            }
        }

        for region in regions where region.kind == .outline {
            context.stroke(
                region.path.applying(transform),
                with: .color(palette.ink),
                style: Self.stroke(size.outlineWidth)
            )
        }
    }

    private func fill(
        _ region: FigureRegion,
        with color: Color,
        transform: CGAffineTransform,
        in context: inout GraphicsContext
    ) {
        let path = region.path.applying(transform)
        context.fill(path, with: .color(color))
        if let width = size.regionStrokeWidth {
            context.stroke(path, with: .color(palette.ink), style: Self.stroke(width))
        }
    }

    private static func stroke(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    /// Aspect-fit the SVG viewBox into the canvas, centred.
    static func fitTransform(_ viewBox: CGRect, into canvasSize: CGSize) -> CGAffineTransform {
        guard viewBox.width > 0, viewBox.height > 0 else { return .identity }
        let scale = min(canvasSize.width / viewBox.width, canvasSize.height / viewBox.height)
        let dx = (canvasSize.width - viewBox.width * scale) / 2 - viewBox.minX * scale
        let dy = (canvasSize.height - viewBox.height * scale) / 2 - viewBox.minY * scale
        return CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)
    }

    /// The muscle drawn at `point` in a canvas of `canvasSize`, or `nil` for
    /// the body, the outline, the decoration and the empty margins of the
    /// aspect-fit box.
    ///
    /// Inverts `fitTransform` and tests the untransformed region paths, so the
    /// hit area is exactly the shape that was painted. Every muscle owns its
    /// regions, so a tap on the lateral half of a shoulder cap yields
    /// `deltoidSide` and a tap on the medial half `deltoidFront` (front figure)
    /// or `deltoidRear` (back figure).
    static func muscle(at point: CGPoint, canvasSize: CGSize, side: FigureSide) -> Muscle? {
        let transform = fitTransform(FigurePaths.viewBox, into: canvasSize)
        let determinant = transform.a * transform.d - transform.b * transform.c
        guard abs(determinant) > .ulpOfOne else { return nil }
        let local = point.applying(transform.inverted())

        // The generator validates that muscle regions do not overlap, so the
        // first containing region is also the one on top.
        for region in FigurePaths.regions(for: side) {
            guard let muscle = region.muscle else { continue }
            if region.path.contains(local) { return muscle }
        }
        return nil
    }

    /// The muscles to paint in the selection colour.
    ///
    /// Every muscle owns its regions, so this is the selection itself; `side`
    /// is kept in the signature because which regions exist is a per-view fact
    /// and callers already pass it.
    static func selected(from selection: Set<Muscle>, side: FigureSide) -> Set<Muscle> {
        selection
    }

    /// Highest intensity per muscle. A muscle paints only its own regions, so
    /// there is nothing to fold: `deltoidSide` colours the lateral half of the
    /// shoulder cap in both views and leaves `deltoidFront` / `deltoidRear`
    /// alone. `side` is unused for the same reason as in `selected(from:side:)`.
    static func intensities(for tags: [MuscleTag], side: FigureSide) -> [Muscle: Intensity] {
        var result: [Muscle: Intensity] = [:]
        for tag in tags {
            result[tag.muscle] = max(result[tag.muscle] ?? tag.intensity, tag.intensity)
        }
        return result
    }

    /// e.g. "Front: chest primary, triceps secondary".
    static func accessibilityLabel(side: FigureSide, tags: [MuscleTag]) -> String {
        let intensities = intensities(for: tags, side: side)
        let listed = Muscle.allCases.compactMap { muscle -> String? in
            guard let intensity = intensities[muscle] else { return nil }
            return "\(muscle.displayName.lowercased()) \(intensity.displayName.lowercased())"
        }
        guard listed.isEmpty == false else {
            return "\(side.displayName): \(String(localized: "no muscles tagged"))"
        }
        return "\(side.displayName): \(listed.joined(separator: ", "))"
    }
}

// MARK: - Pair

/// Front and back figure side by side.
///
/// Each `FigureView` hit-tests its own taps, so `onTapMuscle` needs no
/// knowledge of which half was hit.
struct FigurePairView: View {
    var tags: [MuscleTag]
    var size: FigureSize
    var palette: FigurePalette = .default
    var selection: Set<Muscle> = []
    var onTapMuscle: ((Muscle) -> Void)?

    var body: some View {
        HStack(spacing: size.pairSpacing) {
            FigureView(
                side: .front,
                tags: tags,
                size: size,
                palette: palette,
                selection: selection,
                onTapMuscle: onTapMuscle
            )
            FigureView(
                side: .back,
                tags: tags,
                size: size,
                palette: palette,
                selection: selection,
                onTapMuscle: onTapMuscle
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(FigureView.accessibilityLabel(side: .front, tags: tags)), "
            + "\(FigureView.accessibilityLabel(side: .back, tags: tags))"
        )
    }
}

nonisolated extension FigurePaths {
    static func regions(for side: FigureSide) -> [FigureRegion] {
        switch side {
        case .front: front
        case .back: back
        }
    }
}
