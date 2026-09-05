import SwiftUI

/// Which of the two figures a region belongs to.
nonisolated enum FigureSide: String, Codable, Sendable, CaseIterable {
    case front
    case back

    var displayName: String {
        switch self {
        case .front: String(localized: "Front")
        case .back: String(localized: "Back")
        }
    }
}

/// What a region is for when drawing.
///
/// - `muscle`: filled with the intensity colour when the muscle is tagged.
/// - `body`: anatomical shape without a muscle of its own (tibialis); always
///   drawn in the plain card colour.
/// - `outline`: the silhouette. Filled first (card colour) and stroked last.
/// - `decoration`: stroke-only detail (the ab lines). Omitted at thumbnail size.
nonisolated enum FigureRegionKind: Sendable, Equatable {
    case muscle(Muscle)
    case body
    case outline
    case decoration
}

/// One drawable shape of the figure, generated from `Design/figure/*.svg`.
///
/// SVG group name -> `Muscle` mapping (kept in sync with `Scripts/svg2swift.py`,
/// which is the only writer of `FigurePaths.swift`):
///
/// | SVG group              | kind             |
/// |------------------------|------------------|
/// | `traps-upper` (front)  | `.muscle(.traps)`|
/// | `traps` (back)         | `.muscle(.traps)`|
/// | `deltoid-front`        | `.muscle(.deltoidFront)` |
/// | `deltoid-rear`         | `.muscle(.deltoidRear)`  |
/// | `chest`                | `.muscle(.chest)`        |
/// | `biceps`               | `.muscle(.biceps)`       |
/// | `triceps`              | `.muscle(.triceps)`      |
/// | `forearm-front`        | `.muscle(.forearms)`     |
/// | `forearm-back`         | `.muscle(.forearms)`     |
/// | `abs`                  | `.muscle(.abs)`          |
/// | `obliques`             | `.muscle(.obliques)`     |
/// | `rhomboids-upper-back` | `.muscle(.upperBack)`    |
/// | `lats`                 | `.muscle(.lats)`         |
/// | `lower-back`           | `.muscle(.lowerBack)`    |
/// | `glutes`               | `.muscle(.glutes)`       |
/// | `quads`                | `.muscle(.quads)`        |
/// | `hamstrings`           | `.muscle(.hamstrings)`   |
/// | `adductors`            | `.muscle(.adductors)`    |
/// | `calves`               | `.muscle(.calves)`       |
/// | `tibialis`             | `.body`                  |
/// | `abs.lines`            | `.decoration`            |
/// | `outline`              | `.outline`               |
///
/// `Muscle.deltoidSide` has no region of its own: `FigureView` paints it onto
/// the front delts (front view) and rear delts (back view) instead.
nonisolated struct FigureRegion: Sendable, Identifiable {
    let id: String
    let side: FigureSide
    let kind: FigureRegionKind
    let path: Path

    init(id: String, side: FigureSide, kind: FigureRegionKind, path: Path) {
        self.id = id
        self.side = side
        self.kind = kind
        self.path = path
    }

    /// The muscle this region paints, if any.
    var muscle: Muscle? {
        if case .muscle(let muscle) = kind { return muscle }
        return nil
    }
}
