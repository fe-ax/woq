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
struct FigureView: View {
    var side: FigureSide
    var tags: [MuscleTag]
    var size: FigureSize
    var palette: FigurePalette = .default

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: false) { context, canvasSize in
            draw(in: &context, canvasSize: canvasSize)
        }
        .frame(width: size.fixedSize?.width, height: size.fixedSize?.height)
        .aspectRatio(FigurePaths.viewBox.width / FigurePaths.viewBox.height, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.accessibilityLabel(side: side, tags: tags))
    }

    // MARK: Drawing

    private func draw(in context: inout GraphicsContext, canvasSize: CGSize) {
        let regions = FigurePaths.regions(for: side)
        let transform = Self.fitTransform(FigurePaths.viewBox, into: canvasSize)
        let intensities = Self.intensities(for: tags, side: side)

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
                    with: palette.fill(for: intensities[muscle]),
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

    /// Highest intensity per muscle, with `deltoidSide` folded onto the front
    /// delts (front view) or the rear delts (back view) unless those are
    /// already tagged with a higher intensity.
    static func intensities(for tags: [MuscleTag], side: FigureSide) -> [Muscle: Intensity] {
        var result: [Muscle: Intensity] = [:]
        for tag in tags {
            result[tag.muscle] = max(result[tag.muscle] ?? tag.intensity, tag.intensity)
        }
        if let sideDelts = result[.deltoidSide] {
            let host: Muscle = side == .front ? .deltoidFront : .deltoidRear
            result[host] = max(result[host] ?? sideDelts, sideDelts)
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
struct FigurePairView: View {
    var tags: [MuscleTag]
    var size: FigureSize
    var palette: FigurePalette = .default

    var body: some View {
        HStack(spacing: size.pairSpacing) {
            FigureView(side: .front, tags: tags, size: size, palette: palette)
            FigureView(side: .back, tags: tags, size: size, palette: palette)
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
