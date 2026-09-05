// GENERATED FILE - DO NOT EDIT BY HAND.
//
// Produced by Scripts/svg2swift.py from Design/figure/front.svg and
// Design/figure/back.svg. Change the SVGs or the generator, then run:
//
//     python3 Scripts/svg2swift.py

import SwiftUI

/// Figure geometry in SVG user units (see `viewBox`).
///
/// Order within each array: body shapes, muscle regions, decoration, outline.
nonisolated enum FigurePaths {
    static let viewBox = CGRect(x: 0, y: 0, width: 120, height: 260)

    static let front: [FigureRegion] = [
        frontTibialisR,
        frontTibialisL,
        frontTrapsUpperR,
        frontTrapsUpperL,
        frontDeltoidFrontR,
        frontDeltoidFrontL,
        frontDeltoidSideR,
        frontDeltoidSideL,
        frontChestR,
        frontChestL,
        frontBicepsR,
        frontBicepsL,
        frontForearmFrontR,
        frontForearmFrontL,
        frontObliquesR,
        frontObliquesL,
        frontAdductorsR,
        frontAdductorsL,
        frontQuadsR,
        frontQuadsL,
        frontAbs,
        frontAbsLines,
        frontOutline,
    ]

    static let back: [FigureRegion] = [
        backTrapsL,
        backTrapsR,
        backDeltoidRearL,
        backDeltoidRearR,
        backDeltoidSideL,
        backDeltoidSideR,
        backRhomboidsUpperBackL,
        backRhomboidsUpperBackR,
        backLatsL,
        backLatsR,
        backTricepsL,
        backTricepsR,
        backForearmBackL,
        backForearmBackR,
        backGlutesL,
        backGlutesR,
        backHamstringsL,
        backHamstringsR,
        backCalvesL,
        backCalvesR,
        backLowerBack,
        backOutline,
    ]
}

// MARK: - Front regions

private nonisolated extension FigurePaths {
    static let frontTibialisR = FigureRegion(
        id: "front.tibialis.r",
        side: .front,
        kind: .body,
        path: Path { p in
            p.move(to: CGPoint(x: 44.4, y: 190.2))
            p.addCurve(to: CGPoint(x: 42.4, y: 191.4), control1: CGPoint(x: 43.8, y: 189.9), control2: CGPoint(x: 42.9, y: 190.2))
            p.addCurve(to: CGPoint(x: 41.5, y: 197.3), control1: CGPoint(x: 42, y: 192.5), control2: CGPoint(x: 41.7, y: 195.4))
            p.addCurve(to: CGPoint(x: 41.1, y: 203), control1: CGPoint(x: 41.3, y: 199.3), control2: CGPoint(x: 41.1, y: 200.3))
            p.addCurve(to: CGPoint(x: 41.5, y: 213.8), control1: CGPoint(x: 41.1, y: 205.7), control2: CGPoint(x: 41.3, y: 210.1))
            p.addCurve(to: CGPoint(x: 42.6, y: 225), control1: CGPoint(x: 41.8, y: 217.5), control2: CGPoint(x: 42.2, y: 221.3))
            p.addCurve(to: CGPoint(x: 44, y: 235.8), control1: CGPoint(x: 43, y: 228.6), control2: CGPoint(x: 43.7, y: 233.7))
            p.addCurve(to: CGPoint(x: 44.7, y: 237.8), control1: CGPoint(x: 44.4, y: 237.9), control2: CGPoint(x: 44.2, y: 237.8))
            p.addCurve(to: CGPoint(x: 47, y: 236), control1: CGPoint(x: 45.2, y: 237.8), control2: CGPoint(x: 46.5, y: 238.6))
            p.addCurve(to: CGPoint(x: 47.5, y: 222), control1: CGPoint(x: 47.5, y: 233.4), control2: CGPoint(x: 47.5, y: 227))
            p.addCurve(to: CGPoint(x: 47.2, y: 206), control1: CGPoint(x: 47.5, y: 217), control2: CGPoint(x: 47.5, y: 210.8))
            p.addCurve(to: CGPoint(x: 46, y: 193), control1: CGPoint(x: 47, y: 201.2), control2: CGPoint(x: 46.5, y: 195.6))
            p.addCurve(to: CGPoint(x: 44.4, y: 190.2), control1: CGPoint(x: 45.5, y: 190.4), control2: CGPoint(x: 45, y: 190.5))
            p.closeSubpath()
        }
    )

    static let frontTibialisL = FigureRegion(
        id: "front.tibialis.l",
        side: .front,
        kind: .body,
        path: Path { p in
            p.move(to: CGPoint(x: 75.6, y: 190.2))
            p.addCurve(to: CGPoint(x: 77.6, y: 191.4), control1: CGPoint(x: 76.2, y: 189.9), control2: CGPoint(x: 77.1, y: 190.2))
            p.addCurve(to: CGPoint(x: 78.5, y: 197.3), control1: CGPoint(x: 78, y: 192.5), control2: CGPoint(x: 78.3, y: 195.4))
            p.addCurve(to: CGPoint(x: 78.9, y: 203), control1: CGPoint(x: 78.7, y: 199.3), control2: CGPoint(x: 78.9, y: 200.3))
            p.addCurve(to: CGPoint(x: 78.5, y: 213.8), control1: CGPoint(x: 78.9, y: 205.7), control2: CGPoint(x: 78.7, y: 210.1))
            p.addCurve(to: CGPoint(x: 77.4, y: 225), control1: CGPoint(x: 78.2, y: 217.5), control2: CGPoint(x: 77.8, y: 221.3))
            p.addCurve(to: CGPoint(x: 76, y: 235.8), control1: CGPoint(x: 77, y: 228.6), control2: CGPoint(x: 76.3, y: 233.7))
            p.addCurve(to: CGPoint(x: 75.3, y: 237.8), control1: CGPoint(x: 75.6, y: 237.9), control2: CGPoint(x: 75.8, y: 237.8))
            p.addCurve(to: CGPoint(x: 73, y: 236), control1: CGPoint(x: 74.8, y: 237.8), control2: CGPoint(x: 73.5, y: 238.6))
            p.addCurve(to: CGPoint(x: 72.5, y: 222), control1: CGPoint(x: 72.5, y: 233.4), control2: CGPoint(x: 72.5, y: 227))
            p.addCurve(to: CGPoint(x: 72.8, y: 206), control1: CGPoint(x: 72.5, y: 217), control2: CGPoint(x: 72.5, y: 210.8))
            p.addCurve(to: CGPoint(x: 74, y: 193), control1: CGPoint(x: 73, y: 201.2), control2: CGPoint(x: 73.5, y: 195.6))
            p.addCurve(to: CGPoint(x: 75.6, y: 190.2), control1: CGPoint(x: 74.5, y: 190.4), control2: CGPoint(x: 75, y: 190.5))
            p.closeSubpath()
        }
    )

    static let frontTrapsUpperR = FigureRegion(
        id: "front.traps-upper.r",
        side: .front,
        kind: .muscle(.traps),
        path: Path { p in
            p.move(to: CGPoint(x: 51.7, y: 47))
            p.addCurve(to: CGPoint(x: 49.6, y: 47.4), control1: CGPoint(x: 51.7, y: 47), control2: CGPoint(x: 50.4, y: 47.3))
            p.addCurve(to: CGPoint(x: 47, y: 47.9), control1: CGPoint(x: 48.8, y: 47.6), control2: CGPoint(x: 47.9, y: 47.7))
            p.addCurve(to: CGPoint(x: 44.4, y: 48.5), control1: CGPoint(x: 46.1, y: 48.1), control2: CGPoint(x: 45.2, y: 48.3))
            p.addCurve(to: CGPoint(x: 41.9, y: 49), control1: CGPoint(x: 43.5, y: 48.7), control2: CGPoint(x: 42.4, y: 48.2))
            p.addCurve(to: CGPoint(x: 41.4, y: 53), control1: CGPoint(x: 41.5, y: 49.8), control2: CGPoint(x: 40.8, y: 52.4))
            p.addCurve(to: CGPoint(x: 45.5, y: 52.4), control1: CGPoint(x: 42, y: 53.6), control2: CGPoint(x: 44.2, y: 52.7))
            p.addCurve(to: CGPoint(x: 49.5, y: 51.4), control1: CGPoint(x: 46.8, y: 52.1), control2: CGPoint(x: 48.5, y: 52.3))
            p.addCurve(to: CGPoint(x: 51.7, y: 47), control1: CGPoint(x: 50.5, y: 50.5), control2: CGPoint(x: 51.7, y: 47))
            p.closeSubpath()
        }
    )

    static let frontTrapsUpperL = FigureRegion(
        id: "front.traps-upper.l",
        side: .front,
        kind: .muscle(.traps),
        path: Path { p in
            p.move(to: CGPoint(x: 68.3, y: 47))
            p.addCurve(to: CGPoint(x: 70.4, y: 47.4), control1: CGPoint(x: 68.3, y: 47), control2: CGPoint(x: 69.6, y: 47.3))
            p.addCurve(to: CGPoint(x: 73, y: 47.9), control1: CGPoint(x: 71.2, y: 47.6), control2: CGPoint(x: 72.1, y: 47.7))
            p.addCurve(to: CGPoint(x: 75.6, y: 48.5), control1: CGPoint(x: 73.9, y: 48.1), control2: CGPoint(x: 74.8, y: 48.3))
            p.addCurve(to: CGPoint(x: 78.1, y: 49), control1: CGPoint(x: 76.5, y: 48.7), control2: CGPoint(x: 77.6, y: 48.2))
            p.addCurve(to: CGPoint(x: 78.6, y: 53), control1: CGPoint(x: 78.5, y: 49.8), control2: CGPoint(x: 79.2, y: 52.4))
            p.addCurve(to: CGPoint(x: 74.5, y: 52.4), control1: CGPoint(x: 78, y: 53.6), control2: CGPoint(x: 75.8, y: 52.7))
            p.addCurve(to: CGPoint(x: 70.5, y: 51.4), control1: CGPoint(x: 73.2, y: 52.1), control2: CGPoint(x: 71.5, y: 52.3))
            p.addCurve(to: CGPoint(x: 68.3, y: 47), control1: CGPoint(x: 69.5, y: 50.5), control2: CGPoint(x: 68.3, y: 47))
            p.closeSubpath()
        }
    )

    static let frontDeltoidFrontR = FigureRegion(
        id: "front.deltoid-front.r",
        side: .front,
        kind: .muscle(.deltoidFront),
        path: Path { p in
            p.move(to: CGPoint(x: 35.8, y: 52.3))
            p.addCurve(to: CGPoint(x: 35.2, y: 54.5), control1: CGPoint(x: 35.6, y: 52.8), control2: CGPoint(x: 35.3, y: 53.7))
            p.addCurve(to: CGPoint(x: 34.9, y: 57), control1: CGPoint(x: 35.1, y: 55.3), control2: CGPoint(x: 35, y: 56.2))
            p.addCurve(to: CGPoint(x: 34.7, y: 59.5), control1: CGPoint(x: 34.8, y: 57.8), control2: CGPoint(x: 34.8, y: 58.7))
            p.addCurve(to: CGPoint(x: 34.4, y: 62), control1: CGPoint(x: 34.6, y: 60.3), control2: CGPoint(x: 34.5, y: 61.2))
            p.addCurve(to: CGPoint(x: 34.1, y: 64.4), control1: CGPoint(x: 34.3, y: 62.8), control2: CGPoint(x: 34, y: 63.7))
            p.addCurve(to: CGPoint(x: 34.7, y: 66.4), control1: CGPoint(x: 34.1, y: 65.1), control2: CGPoint(x: 34.3, y: 66))
            p.addCurve(to: CGPoint(x: 36.5, y: 67), control1: CGPoint(x: 35.1, y: 66.8), control2: CGPoint(x: 35.7, y: 67.7))
            p.addCurve(to: CGPoint(x: 39.5, y: 62.5), control1: CGPoint(x: 37.3, y: 66.3), control2: CGPoint(x: 38.9, y: 64.2))
            p.addCurve(to: CGPoint(x: 40.2, y: 57), control1: CGPoint(x: 40.1, y: 60.8), control2: CGPoint(x: 40.2, y: 58.6))
            p.addCurve(to: CGPoint(x: 39.2, y: 53), control1: CGPoint(x: 40.2, y: 55.4), control2: CGPoint(x: 39.8, y: 53.9))
            p.addCurve(to: CGPoint(x: 36.5, y: 51.4), control1: CGPoint(x: 38.6, y: 52.1), control2: CGPoint(x: 37.1, y: 51.5))
            p.addCurve(to: CGPoint(x: 35.8, y: 52.3), control1: CGPoint(x: 35.9, y: 51.3), control2: CGPoint(x: 36, y: 51.8))
            p.closeSubpath()
        }
    )

    static let frontDeltoidFrontL = FigureRegion(
        id: "front.deltoid-front.l",
        side: .front,
        kind: .muscle(.deltoidFront),
        path: Path { p in
            p.move(to: CGPoint(x: 84.2, y: 52.3))
            p.addCurve(to: CGPoint(x: 84.8, y: 54.5), control1: CGPoint(x: 84.4, y: 52.8), control2: CGPoint(x: 84.7, y: 53.7))
            p.addCurve(to: CGPoint(x: 85.1, y: 57), control1: CGPoint(x: 84.9, y: 55.3), control2: CGPoint(x: 85, y: 56.2))
            p.addCurve(to: CGPoint(x: 85.3, y: 59.5), control1: CGPoint(x: 85.2, y: 57.8), control2: CGPoint(x: 85.2, y: 58.7))
            p.addCurve(to: CGPoint(x: 85.6, y: 62), control1: CGPoint(x: 85.4, y: 60.3), control2: CGPoint(x: 85.5, y: 61.2))
            p.addCurve(to: CGPoint(x: 85.9, y: 64.4), control1: CGPoint(x: 85.7, y: 62.8), control2: CGPoint(x: 86, y: 63.7))
            p.addCurve(to: CGPoint(x: 85.3, y: 66.4), control1: CGPoint(x: 85.9, y: 65.1), control2: CGPoint(x: 85.7, y: 66))
            p.addCurve(to: CGPoint(x: 83.5, y: 67), control1: CGPoint(x: 84.9, y: 66.8), control2: CGPoint(x: 84.3, y: 67.7))
            p.addCurve(to: CGPoint(x: 80.5, y: 62.5), control1: CGPoint(x: 82.7, y: 66.3), control2: CGPoint(x: 81.1, y: 64.2))
            p.addCurve(to: CGPoint(x: 79.8, y: 57), control1: CGPoint(x: 79.9, y: 60.8), control2: CGPoint(x: 79.8, y: 58.6))
            p.addCurve(to: CGPoint(x: 80.8, y: 53), control1: CGPoint(x: 79.8, y: 55.4), control2: CGPoint(x: 80.2, y: 53.9))
            p.addCurve(to: CGPoint(x: 83.5, y: 51.4), control1: CGPoint(x: 81.4, y: 52.1), control2: CGPoint(x: 82.9, y: 51.5))
            p.addCurve(to: CGPoint(x: 84.2, y: 52.3), control1: CGPoint(x: 84.1, y: 51.3), control2: CGPoint(x: 84, y: 51.8))
            p.closeSubpath()
        }
    )

    static let frontDeltoidSideR = FigureRegion(
        id: "front.deltoid-side.r",
        side: .front,
        kind: .muscle(.deltoidSide),
        path: Path { p in
            p.move(to: CGPoint(x: 33.4, y: 51.7))
            p.addCurve(to: CGPoint(x: 31.8, y: 53.2), control1: CGPoint(x: 33, y: 51.8), control2: CGPoint(x: 32.3, y: 52.6))
            p.addCurve(to: CGPoint(x: 30.5, y: 55.2), control1: CGPoint(x: 31.4, y: 53.8), control2: CGPoint(x: 30.9, y: 54.5))
            p.addCurve(to: CGPoint(x: 29.6, y: 57.4), control1: CGPoint(x: 30.1, y: 55.9), control2: CGPoint(x: 29.8, y: 56.6))
            p.addCurve(to: CGPoint(x: 29.1, y: 60.2), control1: CGPoint(x: 29.4, y: 58.3), control2: CGPoint(x: 29.3, y: 58.9))
            p.addCurve(to: CGPoint(x: 28.7, y: 65), control1: CGPoint(x: 29, y: 61.5), control2: CGPoint(x: 28.6, y: 63.9))
            p.addCurve(to: CGPoint(x: 29.6, y: 67), control1: CGPoint(x: 28.8, y: 66.1), control2: CGPoint(x: 29.1, y: 66.5))
            p.addCurve(to: CGPoint(x: 31.5, y: 67.7), control1: CGPoint(x: 30.1, y: 67.5), control2: CGPoint(x: 31, y: 68))
            p.addCurve(to: CGPoint(x: 32.9, y: 65.2), control1: CGPoint(x: 32, y: 67.4), control2: CGPoint(x: 32.6, y: 66.2))
            p.addCurve(to: CGPoint(x: 33.2, y: 62), control1: CGPoint(x: 33.2, y: 64.2), control2: CGPoint(x: 33.1, y: 63))
            p.addCurve(to: CGPoint(x: 33.5, y: 59.5), control1: CGPoint(x: 33.3, y: 61), control2: CGPoint(x: 33.4, y: 60.3))
            p.addCurve(to: CGPoint(x: 33.7, y: 57), control1: CGPoint(x: 33.6, y: 58.7), control2: CGPoint(x: 33.6, y: 57.8))
            p.addCurve(to: CGPoint(x: 34, y: 54.5), control1: CGPoint(x: 33.8, y: 56.2), control2: CGPoint(x: 33.9, y: 55.2))
            p.addCurve(to: CGPoint(x: 34.4, y: 52.6), control1: CGPoint(x: 34.1, y: 53.8), control2: CGPoint(x: 34.5, y: 53.1))
            p.addCurve(to: CGPoint(x: 33.4, y: 51.7), control1: CGPoint(x: 34.3, y: 52.1), control2: CGPoint(x: 33.8, y: 51.6))
            p.closeSubpath()
        }
    )

    static let frontDeltoidSideL = FigureRegion(
        id: "front.deltoid-side.l",
        side: .front,
        kind: .muscle(.deltoidSide),
        path: Path { p in
            p.move(to: CGPoint(x: 86.6, y: 51.7))
            p.addCurve(to: CGPoint(x: 88.2, y: 53.2), control1: CGPoint(x: 87, y: 51.8), control2: CGPoint(x: 87.7, y: 52.6))
            p.addCurve(to: CGPoint(x: 89.5, y: 55.2), control1: CGPoint(x: 88.6, y: 53.8), control2: CGPoint(x: 89.1, y: 54.5))
            p.addCurve(to: CGPoint(x: 90.4, y: 57.4), control1: CGPoint(x: 89.9, y: 55.9), control2: CGPoint(x: 90.2, y: 56.6))
            p.addCurve(to: CGPoint(x: 90.9, y: 60.2), control1: CGPoint(x: 90.6, y: 58.3), control2: CGPoint(x: 90.7, y: 58.9))
            p.addCurve(to: CGPoint(x: 91.3, y: 65), control1: CGPoint(x: 91, y: 61.5), control2: CGPoint(x: 91.4, y: 63.9))
            p.addCurve(to: CGPoint(x: 90.4, y: 67), control1: CGPoint(x: 91.2, y: 66.1), control2: CGPoint(x: 90.9, y: 66.5))
            p.addCurve(to: CGPoint(x: 88.5, y: 67.7), control1: CGPoint(x: 89.9, y: 67.5), control2: CGPoint(x: 89, y: 68))
            p.addCurve(to: CGPoint(x: 87.1, y: 65.2), control1: CGPoint(x: 88, y: 67.4), control2: CGPoint(x: 87.4, y: 66.2))
            p.addCurve(to: CGPoint(x: 86.8, y: 62), control1: CGPoint(x: 86.8, y: 64.2), control2: CGPoint(x: 86.9, y: 63))
            p.addCurve(to: CGPoint(x: 86.5, y: 59.5), control1: CGPoint(x: 86.7, y: 61), control2: CGPoint(x: 86.6, y: 60.3))
            p.addCurve(to: CGPoint(x: 86.3, y: 57), control1: CGPoint(x: 86.4, y: 58.7), control2: CGPoint(x: 86.4, y: 57.8))
            p.addCurve(to: CGPoint(x: 86, y: 54.5), control1: CGPoint(x: 86.2, y: 56.2), control2: CGPoint(x: 86.1, y: 55.2))
            p.addCurve(to: CGPoint(x: 85.6, y: 52.6), control1: CGPoint(x: 85.9, y: 53.8), control2: CGPoint(x: 85.5, y: 53.1))
            p.addCurve(to: CGPoint(x: 86.6, y: 51.7), control1: CGPoint(x: 85.7, y: 52.1), control2: CGPoint(x: 86.2, y: 51.6))
            p.closeSubpath()
        }
    )

    static let frontChestR = FigureRegion(
        id: "front.chest.r",
        side: .front,
        kind: .muscle(.chest),
        path: Path { p in
            p.move(to: CGPoint(x: 58, y: 55.5))
            p.addCurve(to: CGPoint(x: 50, y: 55), control1: CGPoint(x: 58, y: 55.5), control2: CGPoint(x: 52.5, y: 55))
            p.addCurve(to: CGPoint(x: 43, y: 55.8), control1: CGPoint(x: 47.5, y: 55), control2: CGPoint(x: 44.3, y: 54.9))
            p.addCurve(to: CGPoint(x: 42.2, y: 60.5), control1: CGPoint(x: 41.7, y: 56.7), control2: CGPoint(x: 42.3, y: 58.9))
            p.addCurve(to: CGPoint(x: 42.4, y: 65.5), control1: CGPoint(x: 42.1, y: 62.1), control2: CGPoint(x: 42.2, y: 64))
            p.addCurve(to: CGPoint(x: 43.5, y: 69.2), control1: CGPoint(x: 42.6, y: 67), control2: CGPoint(x: 42.7, y: 67.9))
            p.addCurve(to: CGPoint(x: 47, y: 73.2), control1: CGPoint(x: 44.3, y: 70.5), control2: CGPoint(x: 45.2, y: 72.4))
            p.addCurve(to: CGPoint(x: 54, y: 74), control1: CGPoint(x: 48.8, y: 74), control2: CGPoint(x: 52.2, y: 74.1))
            p.addCurve(to: CGPoint(x: 58, y: 72.5), control1: CGPoint(x: 55.8, y: 73.9), control2: CGPoint(x: 58, y: 72.5))
            p.addCurve(to: CGPoint(x: 58, y: 55.5), control1: CGPoint(x: 58, y: 72.5), control2: CGPoint(x: 58, y: 55.5))
            p.closeSubpath()
        }
    )

    static let frontChestL = FigureRegion(
        id: "front.chest.l",
        side: .front,
        kind: .muscle(.chest),
        path: Path { p in
            p.move(to: CGPoint(x: 62, y: 55.5))
            p.addCurve(to: CGPoint(x: 70, y: 55), control1: CGPoint(x: 62, y: 55.5), control2: CGPoint(x: 67.5, y: 55))
            p.addCurve(to: CGPoint(x: 77, y: 55.8), control1: CGPoint(x: 72.5, y: 55), control2: CGPoint(x: 75.7, y: 54.9))
            p.addCurve(to: CGPoint(x: 77.8, y: 60.5), control1: CGPoint(x: 78.3, y: 56.7), control2: CGPoint(x: 77.7, y: 58.9))
            p.addCurve(to: CGPoint(x: 77.6, y: 65.5), control1: CGPoint(x: 77.9, y: 62.1), control2: CGPoint(x: 77.8, y: 64))
            p.addCurve(to: CGPoint(x: 76.5, y: 69.2), control1: CGPoint(x: 77.4, y: 67), control2: CGPoint(x: 77.3, y: 67.9))
            p.addCurve(to: CGPoint(x: 73, y: 73.2), control1: CGPoint(x: 75.7, y: 70.5), control2: CGPoint(x: 74.8, y: 72.4))
            p.addCurve(to: CGPoint(x: 66, y: 74), control1: CGPoint(x: 71.2, y: 74), control2: CGPoint(x: 67.8, y: 74.1))
            p.addCurve(to: CGPoint(x: 62, y: 72.5), control1: CGPoint(x: 64.2, y: 73.9), control2: CGPoint(x: 62, y: 72.5))
            p.addCurve(to: CGPoint(x: 62, y: 55.5), control1: CGPoint(x: 62, y: 72.5), control2: CGPoint(x: 62, y: 55.5))
            p.closeSubpath()
        }
    )

    static let frontBicepsR = FigureRegion(
        id: "front.biceps.r",
        side: .front,
        kind: .muscle(.biceps),
        path: Path { p in
            p.move(to: CGPoint(x: 27.7, y: 72.7))
            p.addCurve(to: CGPoint(x: 26.9, y: 78.3), control1: CGPoint(x: 27, y: 74), control2: CGPoint(x: 27.2, y: 76.4))
            p.addCurve(to: CGPoint(x: 26.1, y: 83.9), control1: CGPoint(x: 26.6, y: 80.2), control2: CGPoint(x: 26.3, y: 82.1))
            p.addCurve(to: CGPoint(x: 25.3, y: 89), control1: CGPoint(x: 25.8, y: 85.7), control2: CGPoint(x: 25.5, y: 87.2))
            p.addCurve(to: CGPoint(x: 24.5, y: 94.3), control1: CGPoint(x: 25, y: 90.7), control2: CGPoint(x: 24.1, y: 93.2))
            p.addCurve(to: CGPoint(x: 27.4, y: 95.6), control1: CGPoint(x: 24.9, y: 95.4), control2: CGPoint(x: 26.5, y: 95.7))
            p.addCurve(to: CGPoint(x: 30.4, y: 93.7), control1: CGPoint(x: 28.4, y: 95.5), control2: CGPoint(x: 29.8, y: 94.9))
            p.addCurve(to: CGPoint(x: 31.2, y: 88), control1: CGPoint(x: 31, y: 92.4), control2: CGPoint(x: 30.9, y: 89.8))
            p.addCurve(to: CGPoint(x: 32.2, y: 82.8), control1: CGPoint(x: 31.5, y: 86.2), control2: CGPoint(x: 31.8, y: 84.6))
            p.addCurve(to: CGPoint(x: 33.4, y: 77.3), control1: CGPoint(x: 32.6, y: 81), control2: CGPoint(x: 33, y: 79.1))
            p.addCurve(to: CGPoint(x: 34.9, y: 72), control1: CGPoint(x: 33.9, y: 75.5), control2: CGPoint(x: 35.2, y: 73.1))
            p.addCurve(to: CGPoint(x: 31.3, y: 70.7), control1: CGPoint(x: 34.5, y: 70.9), control2: CGPoint(x: 32.5, y: 70.6))
            p.addCurve(to: CGPoint(x: 27.7, y: 72.7), control1: CGPoint(x: 30.1, y: 70.8), control2: CGPoint(x: 28.5, y: 71.4))
            p.closeSubpath()
        }
    )

    static let frontBicepsL = FigureRegion(
        id: "front.biceps.l",
        side: .front,
        kind: .muscle(.biceps),
        path: Path { p in
            p.move(to: CGPoint(x: 92.3, y: 72.7))
            p.addCurve(to: CGPoint(x: 93.1, y: 78.3), control1: CGPoint(x: 93, y: 74), control2: CGPoint(x: 92.8, y: 76.4))
            p.addCurve(to: CGPoint(x: 93.9, y: 83.9), control1: CGPoint(x: 93.4, y: 80.2), control2: CGPoint(x: 93.7, y: 82.1))
            p.addCurve(to: CGPoint(x: 94.7, y: 89), control1: CGPoint(x: 94.2, y: 85.7), control2: CGPoint(x: 94.5, y: 87.2))
            p.addCurve(to: CGPoint(x: 95.5, y: 94.3), control1: CGPoint(x: 95, y: 90.7), control2: CGPoint(x: 95.9, y: 93.2))
            p.addCurve(to: CGPoint(x: 92.6, y: 95.6), control1: CGPoint(x: 95.1, y: 95.4), control2: CGPoint(x: 93.5, y: 95.7))
            p.addCurve(to: CGPoint(x: 89.6, y: 93.7), control1: CGPoint(x: 91.6, y: 95.5), control2: CGPoint(x: 90.2, y: 94.9))
            p.addCurve(to: CGPoint(x: 88.8, y: 88), control1: CGPoint(x: 89, y: 92.4), control2: CGPoint(x: 89.1, y: 89.8))
            p.addCurve(to: CGPoint(x: 87.8, y: 82.8), control1: CGPoint(x: 88.5, y: 86.2), control2: CGPoint(x: 88.2, y: 84.6))
            p.addCurve(to: CGPoint(x: 86.6, y: 77.3), control1: CGPoint(x: 87.4, y: 81), control2: CGPoint(x: 87, y: 79.1))
            p.addCurve(to: CGPoint(x: 85.1, y: 72), control1: CGPoint(x: 86.1, y: 75.5), control2: CGPoint(x: 84.8, y: 73.1))
            p.addCurve(to: CGPoint(x: 88.7, y: 70.7), control1: CGPoint(x: 85.5, y: 70.9), control2: CGPoint(x: 87.5, y: 70.6))
            p.addCurve(to: CGPoint(x: 92.3, y: 72.7), control1: CGPoint(x: 89.9, y: 70.8), control2: CGPoint(x: 91.5, y: 71.4))
            p.closeSubpath()
        }
    )

    static let frontForearmFrontR = FigureRegion(
        id: "front.forearm-front.r",
        side: .front,
        kind: .muscle(.forearms),
        path: Path { p in
            p.move(to: CGPoint(x: 23, y: 101.4))
            p.addCurve(to: CGPoint(x: 22.3, y: 107.4), control1: CGPoint(x: 22.4, y: 102.7), control2: CGPoint(x: 22.5, y: 105.1))
            p.addCurve(to: CGPoint(x: 21.7, y: 115.3), control1: CGPoint(x: 22, y: 109.7), control2: CGPoint(x: 21.9, y: 112.5))
            p.addCurve(to: CGPoint(x: 21.4, y: 124.2), control1: CGPoint(x: 21.6, y: 118.1), control2: CGPoint(x: 21.5, y: 121.2))
            p.addCurve(to: CGPoint(x: 21.2, y: 133), control1: CGPoint(x: 21.3, y: 127.1), control2: CGPoint(x: 20.9, y: 131.3))
            p.addCurve(to: CGPoint(x: 23.1, y: 134.4), control1: CGPoint(x: 21.5, y: 134.7), control2: CGPoint(x: 22.4, y: 134.5))
            p.addCurve(to: CGPoint(x: 25, y: 132.5), control1: CGPoint(x: 23.7, y: 134.3), control2: CGPoint(x: 24.4, y: 134.2))
            p.addCurve(to: CGPoint(x: 26.3, y: 124.5), control1: CGPoint(x: 25.5, y: 130.9), control2: CGPoint(x: 25.9, y: 127.1))
            p.addCurve(to: CGPoint(x: 27.5, y: 116.8), control1: CGPoint(x: 26.7, y: 121.9), control2: CGPoint(x: 27.2, y: 119.3))
            p.addCurve(to: CGPoint(x: 28.7, y: 109), control1: CGPoint(x: 27.9, y: 114.2), control2: CGPoint(x: 28.3, y: 111.6))
            p.addCurve(to: CGPoint(x: 29.6, y: 101), control1: CGPoint(x: 29, y: 106.4), control2: CGPoint(x: 30, y: 102.6))
            p.addCurve(to: CGPoint(x: 26.3, y: 99.6), control1: CGPoint(x: 29.2, y: 99.5), control2: CGPoint(x: 27.4, y: 99.5))
            p.addCurve(to: CGPoint(x: 23, y: 101.4), control1: CGPoint(x: 25.2, y: 99.7), control2: CGPoint(x: 23.7, y: 100.1))
            p.closeSubpath()
        }
    )

    static let frontForearmFrontL = FigureRegion(
        id: "front.forearm-front.l",
        side: .front,
        kind: .muscle(.forearms),
        path: Path { p in
            p.move(to: CGPoint(x: 97, y: 101.4))
            p.addCurve(to: CGPoint(x: 97.7, y: 107.4), control1: CGPoint(x: 97.6, y: 102.7), control2: CGPoint(x: 97.5, y: 105.1))
            p.addCurve(to: CGPoint(x: 98.3, y: 115.3), control1: CGPoint(x: 98, y: 109.7), control2: CGPoint(x: 98.1, y: 112.5))
            p.addCurve(to: CGPoint(x: 98.6, y: 124.2), control1: CGPoint(x: 98.4, y: 118.1), control2: CGPoint(x: 98.5, y: 121.2))
            p.addCurve(to: CGPoint(x: 98.8, y: 133), control1: CGPoint(x: 98.7, y: 127.1), control2: CGPoint(x: 99.1, y: 131.3))
            p.addCurve(to: CGPoint(x: 96.9, y: 134.4), control1: CGPoint(x: 98.5, y: 134.7), control2: CGPoint(x: 97.6, y: 134.5))
            p.addCurve(to: CGPoint(x: 95, y: 132.5), control1: CGPoint(x: 96.3, y: 134.3), control2: CGPoint(x: 95.6, y: 134.2))
            p.addCurve(to: CGPoint(x: 93.7, y: 124.5), control1: CGPoint(x: 94.5, y: 130.9), control2: CGPoint(x: 94.1, y: 127.1))
            p.addCurve(to: CGPoint(x: 92.5, y: 116.8), control1: CGPoint(x: 93.3, y: 121.9), control2: CGPoint(x: 92.8, y: 119.3))
            p.addCurve(to: CGPoint(x: 91.3, y: 109), control1: CGPoint(x: 92.1, y: 114.2), control2: CGPoint(x: 91.7, y: 111.6))
            p.addCurve(to: CGPoint(x: 90.4, y: 101), control1: CGPoint(x: 91, y: 106.4), control2: CGPoint(x: 90, y: 102.6))
            p.addCurve(to: CGPoint(x: 93.7, y: 99.6), control1: CGPoint(x: 90.8, y: 99.5), control2: CGPoint(x: 92.6, y: 99.5))
            p.addCurve(to: CGPoint(x: 97, y: 101.4), control1: CGPoint(x: 94.8, y: 99.7), control2: CGPoint(x: 96.3, y: 100.1))
            p.closeSubpath()
        }
    )

    static let frontObliquesR = FigureRegion(
        id: "front.obliques.r",
        side: .front,
        kind: .muscle(.obliques),
        path: Path { p in
            p.move(to: CGPoint(x: 51.5, y: 78.5))
            p.addCurve(to: CGPoint(x: 43.4, y: 78.3), control1: CGPoint(x: 51.5, y: 78.5), control2: CGPoint(x: 44.5, y: 77.1))
            p.addCurve(to: CGPoint(x: 44.8, y: 85.8), control1: CGPoint(x: 42.3, y: 79.5), control2: CGPoint(x: 44.4, y: 83.4))
            p.addCurve(to: CGPoint(x: 46, y: 92.4), control1: CGPoint(x: 45.2, y: 88.1), control2: CGPoint(x: 45.7, y: 90.2))
            p.addCurve(to: CGPoint(x: 46.6, y: 98.8), control1: CGPoint(x: 46.3, y: 94.6), control2: CGPoint(x: 46.6, y: 96.6))
            p.addCurve(to: CGPoint(x: 45.6, y: 105.8), control1: CGPoint(x: 46.5, y: 101.1), control2: CGPoint(x: 46, y: 103.7))
            p.addCurve(to: CGPoint(x: 44.1, y: 111.5), control1: CGPoint(x: 45.2, y: 107.9), control2: CGPoint(x: 44.6, y: 109.6))
            p.addCurve(to: CGPoint(x: 42.4, y: 117), control1: CGPoint(x: 43.5, y: 113.4), control2: CGPoint(x: 41.1, y: 116.1))
            p.addCurve(to: CGPoint(x: 51.5, y: 117), control1: CGPoint(x: 43.6, y: 117.9), control2: CGPoint(x: 51.5, y: 117))
            p.addCurve(to: CGPoint(x: 51.5, y: 78.5), control1: CGPoint(x: 51.5, y: 117), control2: CGPoint(x: 51.5, y: 78.5))
            p.closeSubpath()
        }
    )

    static let frontObliquesL = FigureRegion(
        id: "front.obliques.l",
        side: .front,
        kind: .muscle(.obliques),
        path: Path { p in
            p.move(to: CGPoint(x: 68.5, y: 78.5))
            p.addCurve(to: CGPoint(x: 76.6, y: 78.3), control1: CGPoint(x: 68.5, y: 78.5), control2: CGPoint(x: 75.5, y: 77.1))
            p.addCurve(to: CGPoint(x: 75.2, y: 85.8), control1: CGPoint(x: 77.7, y: 79.5), control2: CGPoint(x: 75.6, y: 83.4))
            p.addCurve(to: CGPoint(x: 74, y: 92.4), control1: CGPoint(x: 74.8, y: 88.1), control2: CGPoint(x: 74.3, y: 90.2))
            p.addCurve(to: CGPoint(x: 73.4, y: 98.8), control1: CGPoint(x: 73.7, y: 94.6), control2: CGPoint(x: 73.4, y: 96.6))
            p.addCurve(to: CGPoint(x: 74.4, y: 105.8), control1: CGPoint(x: 73.5, y: 101.1), control2: CGPoint(x: 74, y: 103.7))
            p.addCurve(to: CGPoint(x: 75.9, y: 111.5), control1: CGPoint(x: 74.8, y: 107.9), control2: CGPoint(x: 75.4, y: 109.6))
            p.addCurve(to: CGPoint(x: 77.6, y: 117), control1: CGPoint(x: 76.5, y: 113.4), control2: CGPoint(x: 78.9, y: 116.1))
            p.addCurve(to: CGPoint(x: 68.5, y: 117), control1: CGPoint(x: 76.4, y: 117.9), control2: CGPoint(x: 68.5, y: 117))
            p.addCurve(to: CGPoint(x: 68.5, y: 78.5), control1: CGPoint(x: 68.5, y: 117), control2: CGPoint(x: 68.5, y: 78.5))
            p.closeSubpath()
        }
    )

    static let frontAdductorsR = FigureRegion(
        id: "front.adductors.r",
        side: .front,
        kind: .muscle(.adductors),
        path: Path { p in
            p.move(to: CGPoint(x: 56.4, y: 128))
            p.addCurve(to: CGPoint(x: 53.5, y: 126.3), control1: CGPoint(x: 55.8, y: 127.5), control2: CGPoint(x: 54.5, y: 126))
            p.addCurve(to: CGPoint(x: 50.6, y: 129.5), control1: CGPoint(x: 52.5, y: 126.5), control2: CGPoint(x: 51.2, y: 127.2))
            p.addCurve(to: CGPoint(x: 50, y: 140), control1: CGPoint(x: 50, y: 131.8), control2: CGPoint(x: 50, y: 136.9))
            p.addCurve(to: CGPoint(x: 50.7, y: 148), control1: CGPoint(x: 50, y: 143.1), control2: CGPoint(x: 50.4, y: 145.7))
            p.addCurve(to: CGPoint(x: 51.6, y: 154), control1: CGPoint(x: 51, y: 150.3), control2: CGPoint(x: 51.2, y: 152.6))
            p.addCurve(to: CGPoint(x: 53.2, y: 156.5), control1: CGPoint(x: 52, y: 155.4), control2: CGPoint(x: 52.8, y: 156.5))
            p.addCurve(to: CGPoint(x: 54.3, y: 154), control1: CGPoint(x: 53.6, y: 156.5), control2: CGPoint(x: 53.9, y: 156.5))
            p.addCurve(to: CGPoint(x: 55.7, y: 141.8), control1: CGPoint(x: 54.7, y: 151.6), control2: CGPoint(x: 55.4, y: 145.2))
            p.addCurve(to: CGPoint(x: 56.6, y: 133.6), control1: CGPoint(x: 56.1, y: 138.4), control2: CGPoint(x: 56.4, y: 135.7))
            p.addCurve(to: CGPoint(x: 57.2, y: 129.3), control1: CGPoint(x: 56.9, y: 131.5), control2: CGPoint(x: 57.2, y: 130.2))
            p.addCurve(to: CGPoint(x: 56.4, y: 128), control1: CGPoint(x: 57.1, y: 128.4), control2: CGPoint(x: 57, y: 128.5))
            p.closeSubpath()
        }
    )

    static let frontAdductorsL = FigureRegion(
        id: "front.adductors.l",
        side: .front,
        kind: .muscle(.adductors),
        path: Path { p in
            p.move(to: CGPoint(x: 63.6, y: 128))
            p.addCurve(to: CGPoint(x: 66.5, y: 126.3), control1: CGPoint(x: 64.2, y: 127.5), control2: CGPoint(x: 65.5, y: 126))
            p.addCurve(to: CGPoint(x: 69.4, y: 129.5), control1: CGPoint(x: 67.5, y: 126.5), control2: CGPoint(x: 68.8, y: 127.2))
            p.addCurve(to: CGPoint(x: 70, y: 140), control1: CGPoint(x: 70, y: 131.8), control2: CGPoint(x: 70, y: 136.9))
            p.addCurve(to: CGPoint(x: 69.3, y: 148), control1: CGPoint(x: 70, y: 143.1), control2: CGPoint(x: 69.6, y: 145.7))
            p.addCurve(to: CGPoint(x: 68.4, y: 154), control1: CGPoint(x: 69, y: 150.3), control2: CGPoint(x: 68.8, y: 152.6))
            p.addCurve(to: CGPoint(x: 66.8, y: 156.5), control1: CGPoint(x: 68, y: 155.4), control2: CGPoint(x: 67.2, y: 156.5))
            p.addCurve(to: CGPoint(x: 65.7, y: 154), control1: CGPoint(x: 66.4, y: 156.5), control2: CGPoint(x: 66.1, y: 156.5))
            p.addCurve(to: CGPoint(x: 64.3, y: 141.8), control1: CGPoint(x: 65.3, y: 151.6), control2: CGPoint(x: 64.6, y: 145.2))
            p.addCurve(to: CGPoint(x: 63.4, y: 133.6), control1: CGPoint(x: 63.9, y: 138.4), control2: CGPoint(x: 63.6, y: 135.7))
            p.addCurve(to: CGPoint(x: 62.8, y: 129.3), control1: CGPoint(x: 63.1, y: 131.5), control2: CGPoint(x: 62.8, y: 130.2))
            p.addCurve(to: CGPoint(x: 63.6, y: 128), control1: CGPoint(x: 62.9, y: 128.4), control2: CGPoint(x: 63, y: 128.5))
            p.closeSubpath()
        }
    )

    static let frontQuadsR = FigureRegion(
        id: "front.quads.r",
        side: .front,
        kind: .muscle(.quads),
        path: Path { p in
            p.move(to: CGPoint(x: 44, y: 124.8))
            p.addCurve(to: CGPoint(x: 40.1, y: 126.3), control1: CGPoint(x: 42.4, y: 124.8), control2: CGPoint(x: 40.8, y: 125.7))
            p.addCurve(to: CGPoint(x: 39.8, y: 128.5), control1: CGPoint(x: 39.3, y: 126.9), control2: CGPoint(x: 39.8, y: 127.7))
            p.addCurve(to: CGPoint(x: 39.6, y: 131), control1: CGPoint(x: 39.7, y: 129.3), control2: CGPoint(x: 39.6, y: 129.3))
            p.addCurve(to: CGPoint(x: 39.7, y: 138.8), control1: CGPoint(x: 39.6, y: 132.7), control2: CGPoint(x: 39.6, y: 135.3))
            p.addCurve(to: CGPoint(x: 40.4, y: 151.7), control1: CGPoint(x: 39.8, y: 142.2), control2: CGPoint(x: 40.1, y: 147.5))
            p.addCurve(to: CGPoint(x: 41.4, y: 164.1), control1: CGPoint(x: 40.7, y: 155.9), control2: CGPoint(x: 41, y: 160.1))
            p.addCurve(to: CGPoint(x: 42.8, y: 175.7), control1: CGPoint(x: 41.8, y: 168.1), control2: CGPoint(x: 42.3, y: 173.3))
            p.addCurve(to: CGPoint(x: 44.5, y: 178.6), control1: CGPoint(x: 43.3, y: 178.1), control2: CGPoint(x: 43.5, y: 178.4))
            p.addCurve(to: CGPoint(x: 48.5, y: 177), control1: CGPoint(x: 45.5, y: 178.8), control2: CGPoint(x: 47.9, y: 180.1))
            p.addCurve(to: CGPoint(x: 48.2, y: 160), control1: CGPoint(x: 49.1, y: 173.9), control2: CGPoint(x: 48.3, y: 165.3))
            p.addCurve(to: CGPoint(x: 47.8, y: 145), control1: CGPoint(x: 48.1, y: 154.7), control2: CGPoint(x: 47.8, y: 149.7))
            p.addCurve(to: CGPoint(x: 48.2, y: 132), control1: CGPoint(x: 47.8, y: 140.3), control2: CGPoint(x: 47.9, y: 135.1))
            p.addCurve(to: CGPoint(x: 49.4, y: 126.5), control1: CGPoint(x: 48.5, y: 128.9), control2: CGPoint(x: 50.1, y: 127.7))
            p.addCurve(to: CGPoint(x: 44, y: 124.8), control1: CGPoint(x: 48.7, y: 125.3), control2: CGPoint(x: 45.6, y: 124.8))
            p.closeSubpath()
        }
    )

    static let frontQuadsL = FigureRegion(
        id: "front.quads.l",
        side: .front,
        kind: .muscle(.quads),
        path: Path { p in
            p.move(to: CGPoint(x: 76, y: 124.8))
            p.addCurve(to: CGPoint(x: 79.9, y: 126.3), control1: CGPoint(x: 77.6, y: 124.8), control2: CGPoint(x: 79.2, y: 125.7))
            p.addCurve(to: CGPoint(x: 80.2, y: 128.5), control1: CGPoint(x: 80.7, y: 126.9), control2: CGPoint(x: 80.2, y: 127.7))
            p.addCurve(to: CGPoint(x: 80.4, y: 131), control1: CGPoint(x: 80.3, y: 129.3), control2: CGPoint(x: 80.4, y: 129.3))
            p.addCurve(to: CGPoint(x: 80.3, y: 138.8), control1: CGPoint(x: 80.4, y: 132.7), control2: CGPoint(x: 80.4, y: 135.3))
            p.addCurve(to: CGPoint(x: 79.6, y: 151.7), control1: CGPoint(x: 80.2, y: 142.2), control2: CGPoint(x: 79.9, y: 147.5))
            p.addCurve(to: CGPoint(x: 78.6, y: 164.1), control1: CGPoint(x: 79.3, y: 155.9), control2: CGPoint(x: 79, y: 160.1))
            p.addCurve(to: CGPoint(x: 77.2, y: 175.7), control1: CGPoint(x: 78.2, y: 168.1), control2: CGPoint(x: 77.7, y: 173.3))
            p.addCurve(to: CGPoint(x: 75.5, y: 178.6), control1: CGPoint(x: 76.7, y: 178.1), control2: CGPoint(x: 76.5, y: 178.4))
            p.addCurve(to: CGPoint(x: 71.5, y: 177), control1: CGPoint(x: 74.5, y: 178.8), control2: CGPoint(x: 72.1, y: 180.1))
            p.addCurve(to: CGPoint(x: 71.8, y: 160), control1: CGPoint(x: 70.9, y: 173.9), control2: CGPoint(x: 71.7, y: 165.3))
            p.addCurve(to: CGPoint(x: 72.2, y: 145), control1: CGPoint(x: 71.9, y: 154.7), control2: CGPoint(x: 72.2, y: 149.7))
            p.addCurve(to: CGPoint(x: 71.8, y: 132), control1: CGPoint(x: 72.2, y: 140.3), control2: CGPoint(x: 72.1, y: 135.1))
            p.addCurve(to: CGPoint(x: 70.6, y: 126.5), control1: CGPoint(x: 71.5, y: 128.9), control2: CGPoint(x: 69.9, y: 127.7))
            p.addCurve(to: CGPoint(x: 76, y: 124.8), control1: CGPoint(x: 71.3, y: 125.3), control2: CGPoint(x: 74.4, y: 124.8))
            p.closeSubpath()
        }
    )

    static let frontAbs = FigureRegion(
        id: "front.abs",
        side: .front,
        kind: .muscle(.abs),
        path: Path { p in
            p.move(to: CGPoint(x: 54, y: 77.5))
            p.addCurve(to: CGPoint(x: 60, y: 76.6), control1: CGPoint(x: 55, y: 74.4), control2: CGPoint(x: 58, y: 76.6))
            p.addCurve(to: CGPoint(x: 66, y: 77.5), control1: CGPoint(x: 62, y: 76.6), control2: CGPoint(x: 65, y: 74.4))
            p.addCurve(to: CGPoint(x: 66.3, y: 95), control1: CGPoint(x: 67, y: 80.6), control2: CGPoint(x: 66.3, y: 89.1))
            p.addCurve(to: CGPoint(x: 66, y: 113), control1: CGPoint(x: 66.3, y: 100.9), control2: CGPoint(x: 66.5, y: 109))
            p.addCurve(to: CGPoint(x: 63, y: 119), control1: CGPoint(x: 65.5, y: 117), control2: CGPoint(x: 64.5, y: 118))
            p.addCurve(to: CGPoint(x: 57, y: 119), control1: CGPoint(x: 61.5, y: 120), control2: CGPoint(x: 58.5, y: 120))
            p.addCurve(to: CGPoint(x: 54, y: 113), control1: CGPoint(x: 55.5, y: 118), control2: CGPoint(x: 54.5, y: 117))
            p.addCurve(to: CGPoint(x: 53.7, y: 95), control1: CGPoint(x: 53.5, y: 109), control2: CGPoint(x: 53.7, y: 100.9))
            p.addCurve(to: CGPoint(x: 54, y: 77.5), control1: CGPoint(x: 53.7, y: 89.1), control2: CGPoint(x: 53, y: 80.6))
            p.closeSubpath()
        }
    )

    static let frontAbsLines = FigureRegion(
        id: "front.abs.lines",
        side: .front,
        kind: .decoration,
        path: Path { p in
            p.move(to: CGPoint(x: 55.5, y: 87))
            p.addLine(to: CGPoint(x: 64.5, y: 87))
            p.move(to: CGPoint(x: 55.5, y: 97.5))
            p.addLine(to: CGPoint(x: 64.5, y: 97.5))
            p.move(to: CGPoint(x: 55.5, y: 108))
            p.addLine(to: CGPoint(x: 64.5, y: 108))
        }
    )

    static let frontOutline = FigureRegion(
        id: "front.outline",
        side: .front,
        kind: .outline,
        path: Path { p in
            p.move(to: CGPoint(x: 60, y: 5.5))
            p.addCurve(to: CGPoint(x: 72.5, y: 22), control1: CGPoint(x: 66.9, y: 5.5), control2: CGPoint(x: 72.5, y: 12.9))
            p.addCurve(to: CGPoint(x: 66, y: 36.5), control1: CGPoint(x: 72.5, y: 28), control2: CGPoint(x: 70, y: 33.6))
            p.addCurve(to: CGPoint(x: 67, y: 45), control1: CGPoint(x: 66, y: 39.5), control2: CGPoint(x: 66.3, y: 42.8))
            p.addCurve(to: CGPoint(x: 85, y: 49), control1: CGPoint(x: 72, y: 46), control2: CGPoint(x: 80, y: 47.5))
            p.addCurve(to: CGPoint(x: 92.5, y: 61), control1: CGPoint(x: 89, y: 50.5), control2: CGPoint(x: 92.5, y: 55))
            p.addCurve(to: CGPoint(x: 97.5, y: 97), control1: CGPoint(x: 93.5, y: 72), control2: CGPoint(x: 96, y: 86))
            p.addCurve(to: CGPoint(x: 100.5, y: 136), control1: CGPoint(x: 100, y: 104), control2: CGPoint(x: 100, y: 120))
            p.addCurve(to: CGPoint(x: 103.5, y: 149), control1: CGPoint(x: 102.5, y: 139), control2: CGPoint(x: 104, y: 144))
            p.addCurve(to: CGPoint(x: 101.5, y: 155), control1: CGPoint(x: 103, y: 151), control2: CGPoint(x: 101.5, y: 152))
            p.addCurve(to: CGPoint(x: 92.5, y: 155), control1: CGPoint(x: 101.5, y: 161), control2: CGPoint(x: 92.5, y: 161))
            p.addLine(to: CGPoint(x: 92.5, y: 150))
            p.addCurve(to: CGPoint(x: 94, y: 136), control1: CGPoint(x: 92.5, y: 144), control2: CGPoint(x: 93.5, y: 140))
            p.addCurve(to: CGPoint(x: 88.5, y: 98), control1: CGPoint(x: 92, y: 124), control2: CGPoint(x: 89.5, y: 110))
            p.addCurve(to: CGPoint(x: 82.5, y: 69), control1: CGPoint(x: 87.5, y: 88), control2: CGPoint(x: 85.5, y: 78))
            p.addCurve(to: CGPoint(x: 79.5, y: 69), control1: CGPoint(x: 81.5, y: 67.5), control2: CGPoint(x: 80, y: 67.5))
            p.addCurve(to: CGPoint(x: 75, y: 98), control1: CGPoint(x: 78.5, y: 80), control2: CGPoint(x: 75.5, y: 90))
            p.addCurve(to: CGPoint(x: 80.5, y: 122), control1: CGPoint(x: 75.5, y: 108), control2: CGPoint(x: 79, y: 114))
            p.addCurve(to: CGPoint(x: 82, y: 132), control1: CGPoint(x: 81.5, y: 125), control2: CGPoint(x: 82, y: 128))
            p.addCurve(to: CGPoint(x: 78, y: 182), control1: CGPoint(x: 82, y: 148), control2: CGPoint(x: 80, y: 168))
            p.addCurve(to: CGPoint(x: 80.5, y: 203), control1: CGPoint(x: 78.5, y: 190), control2: CGPoint(x: 80.5, y: 196))
            p.addCurve(to: CGPoint(x: 77, y: 240), control1: CGPoint(x: 80.5, y: 215), control2: CGPoint(x: 78.5, y: 230))
            p.addCurve(to: CGPoint(x: 82.5, y: 252), control1: CGPoint(x: 78, y: 245), control2: CGPoint(x: 81, y: 248.5))
            p.addCurve(to: CGPoint(x: 80, y: 254), control1: CGPoint(x: 83, y: 253.5), control2: CGPoint(x: 81.5, y: 254))
            p.addLine(to: CGPoint(x: 70, y: 254))
            p.addCurve(to: CGPoint(x: 68, y: 251.5), control1: CGPoint(x: 68, y: 254), control2: CGPoint(x: 67.5, y: 253))
            p.addCurve(to: CGPoint(x: 69.5, y: 240), control1: CGPoint(x: 68.5, y: 248), control2: CGPoint(x: 69.2, y: 244))
            p.addCurve(to: CGPoint(x: 66.5, y: 203), control1: CGPoint(x: 68.5, y: 232), control2: CGPoint(x: 67, y: 218))
            p.addCurve(to: CGPoint(x: 67, y: 182), control1: CGPoint(x: 66.5, y: 195), control2: CGPoint(x: 66.5, y: 188))
            p.addCurve(to: CGPoint(x: 62, y: 136), control1: CGPoint(x: 66, y: 168), control2: CGPoint(x: 63.5, y: 150))
            p.addCurve(to: CGPoint(x: 60, y: 122), control1: CGPoint(x: 61.5, y: 130), control2: CGPoint(x: 60.5, y: 125))
            p.addCurve(to: CGPoint(x: 58, y: 136), control1: CGPoint(x: 59.5, y: 125), control2: CGPoint(x: 58.5, y: 130))
            p.addCurve(to: CGPoint(x: 53, y: 182), control1: CGPoint(x: 56.5, y: 150), control2: CGPoint(x: 54, y: 168))
            p.addCurve(to: CGPoint(x: 53.5, y: 203), control1: CGPoint(x: 53.5, y: 188), control2: CGPoint(x: 53.5, y: 195))
            p.addCurve(to: CGPoint(x: 50.5, y: 240), control1: CGPoint(x: 53, y: 218), control2: CGPoint(x: 51.5, y: 232))
            p.addCurve(to: CGPoint(x: 52, y: 251.5), control1: CGPoint(x: 50.8, y: 244), control2: CGPoint(x: 51.5, y: 248))
            p.addCurve(to: CGPoint(x: 50, y: 254), control1: CGPoint(x: 52.5, y: 253), control2: CGPoint(x: 52, y: 254))
            p.addLine(to: CGPoint(x: 40, y: 254))
            p.addCurve(to: CGPoint(x: 37.5, y: 252), control1: CGPoint(x: 38.5, y: 254), control2: CGPoint(x: 37, y: 253.5))
            p.addCurve(to: CGPoint(x: 43, y: 240), control1: CGPoint(x: 39, y: 248.5), control2: CGPoint(x: 42, y: 245))
            p.addCurve(to: CGPoint(x: 39.5, y: 203), control1: CGPoint(x: 41.5, y: 230), control2: CGPoint(x: 39.5, y: 215))
            p.addCurve(to: CGPoint(x: 42, y: 182), control1: CGPoint(x: 39.5, y: 196), control2: CGPoint(x: 41.5, y: 190))
            p.addCurve(to: CGPoint(x: 38, y: 132), control1: CGPoint(x: 40, y: 168), control2: CGPoint(x: 38, y: 148))
            p.addCurve(to: CGPoint(x: 39.5, y: 122), control1: CGPoint(x: 38, y: 128), control2: CGPoint(x: 38.5, y: 125))
            p.addCurve(to: CGPoint(x: 45, y: 98), control1: CGPoint(x: 41, y: 114), control2: CGPoint(x: 44.5, y: 108))
            p.addCurve(to: CGPoint(x: 40.5, y: 69), control1: CGPoint(x: 44.5, y: 90), control2: CGPoint(x: 41.5, y: 80))
            p.addCurve(to: CGPoint(x: 37.5, y: 69), control1: CGPoint(x: 40, y: 67.5), control2: CGPoint(x: 38.5, y: 67.5))
            p.addCurve(to: CGPoint(x: 31.5, y: 98), control1: CGPoint(x: 34.5, y: 78), control2: CGPoint(x: 32.5, y: 88))
            p.addCurve(to: CGPoint(x: 26, y: 136), control1: CGPoint(x: 30.5, y: 110), control2: CGPoint(x: 28, y: 124))
            p.addCurve(to: CGPoint(x: 27.5, y: 150), control1: CGPoint(x: 26.5, y: 140), control2: CGPoint(x: 27.5, y: 144))
            p.addLine(to: CGPoint(x: 27.5, y: 155))
            p.addCurve(to: CGPoint(x: 18.5, y: 155), control1: CGPoint(x: 27.5, y: 161), control2: CGPoint(x: 18.5, y: 161))
            p.addCurve(to: CGPoint(x: 16.5, y: 149), control1: CGPoint(x: 18.5, y: 152), control2: CGPoint(x: 17, y: 151))
            p.addCurve(to: CGPoint(x: 19.5, y: 136), control1: CGPoint(x: 16, y: 144), control2: CGPoint(x: 17.5, y: 139))
            p.addCurve(to: CGPoint(x: 22.5, y: 97), control1: CGPoint(x: 20, y: 120), control2: CGPoint(x: 20, y: 104))
            p.addCurve(to: CGPoint(x: 27.5, y: 61), control1: CGPoint(x: 24, y: 86), control2: CGPoint(x: 26.5, y: 72))
            p.addCurve(to: CGPoint(x: 35, y: 49), control1: CGPoint(x: 27.5, y: 55), control2: CGPoint(x: 31, y: 50.5))
            p.addCurve(to: CGPoint(x: 53, y: 45), control1: CGPoint(x: 40, y: 47.5), control2: CGPoint(x: 48, y: 46))
            p.addCurve(to: CGPoint(x: 54, y: 36.5), control1: CGPoint(x: 53.7, y: 42.8), control2: CGPoint(x: 54, y: 39.5))
            p.addCurve(to: CGPoint(x: 47.5, y: 22), control1: CGPoint(x: 50, y: 33.6), control2: CGPoint(x: 47.5, y: 28))
            p.addCurve(to: CGPoint(x: 60, y: 5.5), control1: CGPoint(x: 47.5, y: 12.9), control2: CGPoint(x: 53.1, y: 5.5))
            p.closeSubpath()
        }
    )
}

// MARK: - Back regions

private nonisolated extension FigurePaths {
    static let backTrapsL = FigureRegion(
        id: "back.traps.l",
        side: .back,
        kind: .muscle(.traps),
        path: Path { p in
            p.move(to: CGPoint(x: 58.5, y: 47))
            p.addCurve(to: CGPoint(x: 52.5, y: 46.7), control1: CGPoint(x: 58.5, y: 47), control2: CGPoint(x: 53.8, y: 46.7))
            p.addCurve(to: CGPoint(x: 50.9, y: 47.1), control1: CGPoint(x: 51.2, y: 46.7), control2: CGPoint(x: 51.7, y: 47))
            p.addCurve(to: CGPoint(x: 48, y: 47.7), control1: CGPoint(x: 50.1, y: 47.3), control2: CGPoint(x: 48.9, y: 47.5))
            p.addCurve(to: CGPoint(x: 45.1, y: 48.3), control1: CGPoint(x: 47, y: 47.9), control2: CGPoint(x: 46.1, y: 48.1))
            p.addCurve(to: CGPoint(x: 41.9, y: 49), control1: CGPoint(x: 44.1, y: 48.5), control2: CGPoint(x: 42.6, y: 48.3))
            p.addCurve(to: CGPoint(x: 41, y: 52.8), control1: CGPoint(x: 41.3, y: 49.7), control2: CGPoint(x: 40.4, y: 51.3))
            p.addCurve(to: CGPoint(x: 45.5, y: 58.2), control1: CGPoint(x: 41.6, y: 54.3), control2: CGPoint(x: 43.7, y: 56.1))
            p.addCurve(to: CGPoint(x: 52, y: 65.5), control1: CGPoint(x: 47.3, y: 60.3), control2: CGPoint(x: 49.8, y: 63.4))
            p.addCurve(to: CGPoint(x: 58.5, y: 71), control1: CGPoint(x: 54.2, y: 67.6), control2: CGPoint(x: 58.5, y: 71))
            p.addCurve(to: CGPoint(x: 58.5, y: 47), control1: CGPoint(x: 58.5, y: 71), control2: CGPoint(x: 58.5, y: 47))
            p.closeSubpath()
        }
    )

    static let backTrapsR = FigureRegion(
        id: "back.traps.r",
        side: .back,
        kind: .muscle(.traps),
        path: Path { p in
            p.move(to: CGPoint(x: 61.5, y: 47))
            p.addCurve(to: CGPoint(x: 67.5, y: 46.7), control1: CGPoint(x: 61.5, y: 47), control2: CGPoint(x: 66.2, y: 46.7))
            p.addCurve(to: CGPoint(x: 69.1, y: 47.1), control1: CGPoint(x: 68.8, y: 46.7), control2: CGPoint(x: 68.3, y: 47))
            p.addCurve(to: CGPoint(x: 72, y: 47.7), control1: CGPoint(x: 69.9, y: 47.3), control2: CGPoint(x: 71.1, y: 47.5))
            p.addCurve(to: CGPoint(x: 74.9, y: 48.3), control1: CGPoint(x: 73, y: 47.9), control2: CGPoint(x: 73.9, y: 48.1))
            p.addCurve(to: CGPoint(x: 78.1, y: 49), control1: CGPoint(x: 75.9, y: 48.5), control2: CGPoint(x: 77.4, y: 48.3))
            p.addCurve(to: CGPoint(x: 79, y: 52.8), control1: CGPoint(x: 78.7, y: 49.7), control2: CGPoint(x: 79.6, y: 51.3))
            p.addCurve(to: CGPoint(x: 74.5, y: 58.2), control1: CGPoint(x: 78.4, y: 54.3), control2: CGPoint(x: 76.3, y: 56.1))
            p.addCurve(to: CGPoint(x: 68, y: 65.5), control1: CGPoint(x: 72.7, y: 60.3), control2: CGPoint(x: 70.2, y: 63.4))
            p.addCurve(to: CGPoint(x: 61.5, y: 71), control1: CGPoint(x: 65.8, y: 67.6), control2: CGPoint(x: 61.5, y: 71))
            p.addCurve(to: CGPoint(x: 61.5, y: 47), control1: CGPoint(x: 61.5, y: 71), control2: CGPoint(x: 61.5, y: 47))
            p.closeSubpath()
        }
    )

    static let backDeltoidRearL = FigureRegion(
        id: "back.deltoid-rear.l",
        side: .back,
        kind: .muscle(.deltoidRear),
        path: Path { p in
            p.move(to: CGPoint(x: 35.8, y: 52.3))
            p.addCurve(to: CGPoint(x: 35.2, y: 54.5), control1: CGPoint(x: 35.6, y: 52.8), control2: CGPoint(x: 35.3, y: 53.7))
            p.addCurve(to: CGPoint(x: 34.9, y: 57), control1: CGPoint(x: 35.1, y: 55.3), control2: CGPoint(x: 35, y: 56.2))
            p.addCurve(to: CGPoint(x: 34.7, y: 59.5), control1: CGPoint(x: 34.8, y: 57.8), control2: CGPoint(x: 34.8, y: 58.7))
            p.addCurve(to: CGPoint(x: 34.4, y: 62), control1: CGPoint(x: 34.6, y: 60.3), control2: CGPoint(x: 34.5, y: 61.2))
            p.addCurve(to: CGPoint(x: 34.1, y: 64.4), control1: CGPoint(x: 34.3, y: 62.8), control2: CGPoint(x: 34, y: 63.7))
            p.addCurve(to: CGPoint(x: 34.7, y: 66.4), control1: CGPoint(x: 34.1, y: 65.1), control2: CGPoint(x: 34.3, y: 66))
            p.addCurve(to: CGPoint(x: 36.5, y: 67), control1: CGPoint(x: 35.1, y: 66.8), control2: CGPoint(x: 35.7, y: 67.7))
            p.addCurve(to: CGPoint(x: 39.5, y: 62.5), control1: CGPoint(x: 37.3, y: 66.3), control2: CGPoint(x: 38.9, y: 64.2))
            p.addCurve(to: CGPoint(x: 40.2, y: 57), control1: CGPoint(x: 40.1, y: 60.8), control2: CGPoint(x: 40.2, y: 58.6))
            p.addCurve(to: CGPoint(x: 39.2, y: 53), control1: CGPoint(x: 40.2, y: 55.4), control2: CGPoint(x: 39.8, y: 53.9))
            p.addCurve(to: CGPoint(x: 36.5, y: 51.4), control1: CGPoint(x: 38.6, y: 52.1), control2: CGPoint(x: 37.1, y: 51.5))
            p.addCurve(to: CGPoint(x: 35.8, y: 52.3), control1: CGPoint(x: 35.9, y: 51.3), control2: CGPoint(x: 36, y: 51.8))
            p.closeSubpath()
        }
    )

    static let backDeltoidRearR = FigureRegion(
        id: "back.deltoid-rear.r",
        side: .back,
        kind: .muscle(.deltoidRear),
        path: Path { p in
            p.move(to: CGPoint(x: 84.2, y: 52.3))
            p.addCurve(to: CGPoint(x: 84.8, y: 54.5), control1: CGPoint(x: 84.4, y: 52.8), control2: CGPoint(x: 84.7, y: 53.7))
            p.addCurve(to: CGPoint(x: 85.1, y: 57), control1: CGPoint(x: 84.9, y: 55.3), control2: CGPoint(x: 85, y: 56.2))
            p.addCurve(to: CGPoint(x: 85.3, y: 59.5), control1: CGPoint(x: 85.2, y: 57.8), control2: CGPoint(x: 85.2, y: 58.7))
            p.addCurve(to: CGPoint(x: 85.6, y: 62), control1: CGPoint(x: 85.4, y: 60.3), control2: CGPoint(x: 85.5, y: 61.2))
            p.addCurve(to: CGPoint(x: 85.9, y: 64.4), control1: CGPoint(x: 85.7, y: 62.8), control2: CGPoint(x: 86, y: 63.7))
            p.addCurve(to: CGPoint(x: 85.3, y: 66.4), control1: CGPoint(x: 85.9, y: 65.1), control2: CGPoint(x: 85.7, y: 66))
            p.addCurve(to: CGPoint(x: 83.5, y: 67), control1: CGPoint(x: 84.9, y: 66.8), control2: CGPoint(x: 84.3, y: 67.7))
            p.addCurve(to: CGPoint(x: 80.5, y: 62.5), control1: CGPoint(x: 82.7, y: 66.3), control2: CGPoint(x: 81.1, y: 64.2))
            p.addCurve(to: CGPoint(x: 79.8, y: 57), control1: CGPoint(x: 79.9, y: 60.8), control2: CGPoint(x: 79.8, y: 58.6))
            p.addCurve(to: CGPoint(x: 80.8, y: 53), control1: CGPoint(x: 79.8, y: 55.4), control2: CGPoint(x: 80.2, y: 53.9))
            p.addCurve(to: CGPoint(x: 83.5, y: 51.4), control1: CGPoint(x: 81.4, y: 52.1), control2: CGPoint(x: 82.9, y: 51.5))
            p.addCurve(to: CGPoint(x: 84.2, y: 52.3), control1: CGPoint(x: 84.1, y: 51.3), control2: CGPoint(x: 84, y: 51.8))
            p.closeSubpath()
        }
    )

    static let backDeltoidSideL = FigureRegion(
        id: "back.deltoid-side.l",
        side: .back,
        kind: .muscle(.deltoidSide),
        path: Path { p in
            p.move(to: CGPoint(x: 33.4, y: 51.7))
            p.addCurve(to: CGPoint(x: 31.8, y: 53.2), control1: CGPoint(x: 33, y: 51.8), control2: CGPoint(x: 32.3, y: 52.6))
            p.addCurve(to: CGPoint(x: 30.5, y: 55.2), control1: CGPoint(x: 31.4, y: 53.8), control2: CGPoint(x: 30.9, y: 54.5))
            p.addCurve(to: CGPoint(x: 29.6, y: 57.4), control1: CGPoint(x: 30.1, y: 55.9), control2: CGPoint(x: 29.8, y: 56.6))
            p.addCurve(to: CGPoint(x: 29.1, y: 60.2), control1: CGPoint(x: 29.4, y: 58.3), control2: CGPoint(x: 29.3, y: 58.9))
            p.addCurve(to: CGPoint(x: 28.7, y: 65), control1: CGPoint(x: 29, y: 61.5), control2: CGPoint(x: 28.6, y: 63.9))
            p.addCurve(to: CGPoint(x: 29.6, y: 67), control1: CGPoint(x: 28.8, y: 66.1), control2: CGPoint(x: 29.1, y: 66.5))
            p.addCurve(to: CGPoint(x: 31.5, y: 67.7), control1: CGPoint(x: 30.1, y: 67.5), control2: CGPoint(x: 31, y: 68))
            p.addCurve(to: CGPoint(x: 32.9, y: 65.2), control1: CGPoint(x: 32, y: 67.4), control2: CGPoint(x: 32.6, y: 66.2))
            p.addCurve(to: CGPoint(x: 33.2, y: 62), control1: CGPoint(x: 33.2, y: 64.2), control2: CGPoint(x: 33.1, y: 63))
            p.addCurve(to: CGPoint(x: 33.5, y: 59.5), control1: CGPoint(x: 33.3, y: 61), control2: CGPoint(x: 33.4, y: 60.3))
            p.addCurve(to: CGPoint(x: 33.7, y: 57), control1: CGPoint(x: 33.6, y: 58.7), control2: CGPoint(x: 33.6, y: 57.8))
            p.addCurve(to: CGPoint(x: 34, y: 54.5), control1: CGPoint(x: 33.8, y: 56.2), control2: CGPoint(x: 33.9, y: 55.2))
            p.addCurve(to: CGPoint(x: 34.4, y: 52.6), control1: CGPoint(x: 34.1, y: 53.8), control2: CGPoint(x: 34.5, y: 53.1))
            p.addCurve(to: CGPoint(x: 33.4, y: 51.7), control1: CGPoint(x: 34.3, y: 52.1), control2: CGPoint(x: 33.8, y: 51.6))
            p.closeSubpath()
        }
    )

    static let backDeltoidSideR = FigureRegion(
        id: "back.deltoid-side.r",
        side: .back,
        kind: .muscle(.deltoidSide),
        path: Path { p in
            p.move(to: CGPoint(x: 86.6, y: 51.7))
            p.addCurve(to: CGPoint(x: 88.2, y: 53.2), control1: CGPoint(x: 87, y: 51.8), control2: CGPoint(x: 87.7, y: 52.6))
            p.addCurve(to: CGPoint(x: 89.5, y: 55.2), control1: CGPoint(x: 88.6, y: 53.8), control2: CGPoint(x: 89.1, y: 54.5))
            p.addCurve(to: CGPoint(x: 90.4, y: 57.4), control1: CGPoint(x: 89.9, y: 55.9), control2: CGPoint(x: 90.2, y: 56.6))
            p.addCurve(to: CGPoint(x: 90.9, y: 60.2), control1: CGPoint(x: 90.6, y: 58.3), control2: CGPoint(x: 90.7, y: 58.9))
            p.addCurve(to: CGPoint(x: 91.3, y: 65), control1: CGPoint(x: 91, y: 61.5), control2: CGPoint(x: 91.4, y: 63.9))
            p.addCurve(to: CGPoint(x: 90.4, y: 67), control1: CGPoint(x: 91.2, y: 66.1), control2: CGPoint(x: 90.9, y: 66.5))
            p.addCurve(to: CGPoint(x: 88.5, y: 67.7), control1: CGPoint(x: 89.9, y: 67.5), control2: CGPoint(x: 89, y: 68))
            p.addCurve(to: CGPoint(x: 87.1, y: 65.2), control1: CGPoint(x: 88, y: 67.4), control2: CGPoint(x: 87.4, y: 66.2))
            p.addCurve(to: CGPoint(x: 86.8, y: 62), control1: CGPoint(x: 86.8, y: 64.2), control2: CGPoint(x: 86.9, y: 63))
            p.addCurve(to: CGPoint(x: 86.5, y: 59.5), control1: CGPoint(x: 86.7, y: 61), control2: CGPoint(x: 86.6, y: 60.3))
            p.addCurve(to: CGPoint(x: 86.3, y: 57), control1: CGPoint(x: 86.4, y: 58.7), control2: CGPoint(x: 86.4, y: 57.8))
            p.addCurve(to: CGPoint(x: 86, y: 54.5), control1: CGPoint(x: 86.2, y: 56.2), control2: CGPoint(x: 86.1, y: 55.2))
            p.addCurve(to: CGPoint(x: 85.6, y: 52.6), control1: CGPoint(x: 85.9, y: 53.8), control2: CGPoint(x: 85.5, y: 53.1))
            p.addCurve(to: CGPoint(x: 86.6, y: 51.7), control1: CGPoint(x: 85.7, y: 52.1), control2: CGPoint(x: 86.2, y: 51.6))
            p.closeSubpath()
        }
    )

    static let backRhomboidsUpperBackL = FigureRegion(
        id: "back.rhomboids-upper-back.l",
        side: .back,
        kind: .muscle(.upperBack),
        path: Path { p in
            p.move(to: CGPoint(x: 58.5, y: 75))
            p.addCurve(to: CGPoint(x: 54, y: 69.5), control1: CGPoint(x: 58.5, y: 75), control2: CGPoint(x: 55.7, y: 70.8))
            p.addCurve(to: CGPoint(x: 48.5, y: 67), control1: CGPoint(x: 52.3, y: 68.2), control2: CGPoint(x: 49.8, y: 66.9))
            p.addCurve(to: CGPoint(x: 46.5, y: 70), control1: CGPoint(x: 47.2, y: 67.1), control2: CGPoint(x: 46.7, y: 68.4))
            p.addCurve(to: CGPoint(x: 47.5, y: 76.5), control1: CGPoint(x: 46.3, y: 71.6), control2: CGPoint(x: 46.7, y: 74.3))
            p.addCurve(to: CGPoint(x: 51.5, y: 83), control1: CGPoint(x: 48.3, y: 78.7), control2: CGPoint(x: 49.7, y: 81.2))
            p.addCurve(to: CGPoint(x: 58.5, y: 87), control1: CGPoint(x: 53.3, y: 84.8), control2: CGPoint(x: 58.5, y: 87))
            p.addCurve(to: CGPoint(x: 58.5, y: 75), control1: CGPoint(x: 58.5, y: 87), control2: CGPoint(x: 58.5, y: 75))
            p.closeSubpath()
        }
    )

    static let backRhomboidsUpperBackR = FigureRegion(
        id: "back.rhomboids-upper-back.r",
        side: .back,
        kind: .muscle(.upperBack),
        path: Path { p in
            p.move(to: CGPoint(x: 61.5, y: 75))
            p.addCurve(to: CGPoint(x: 66, y: 69.5), control1: CGPoint(x: 61.5, y: 75), control2: CGPoint(x: 64.3, y: 70.8))
            p.addCurve(to: CGPoint(x: 71.5, y: 67), control1: CGPoint(x: 67.7, y: 68.2), control2: CGPoint(x: 70.2, y: 66.9))
            p.addCurve(to: CGPoint(x: 73.5, y: 70), control1: CGPoint(x: 72.8, y: 67.1), control2: CGPoint(x: 73.3, y: 68.4))
            p.addCurve(to: CGPoint(x: 72.5, y: 76.5), control1: CGPoint(x: 73.7, y: 71.6), control2: CGPoint(x: 73.3, y: 74.3))
            p.addCurve(to: CGPoint(x: 68.5, y: 83), control1: CGPoint(x: 71.7, y: 78.7), control2: CGPoint(x: 70.3, y: 81.2))
            p.addCurve(to: CGPoint(x: 61.5, y: 87), control1: CGPoint(x: 66.7, y: 84.8), control2: CGPoint(x: 61.5, y: 87))
            p.addCurve(to: CGPoint(x: 61.5, y: 75), control1: CGPoint(x: 61.5, y: 87), control2: CGPoint(x: 61.5, y: 75))
            p.closeSubpath()
        }
    )

    static let backLatsL = FigureRegion(
        id: "back.lats.l",
        side: .back,
        kind: .muscle(.lats),
        path: Path { p in
            p.move(to: CGPoint(x: 42.8, y: 74.8))
            p.addCurve(to: CGPoint(x: 43.9, y: 81.4), control1: CGPoint(x: 42.2, y: 74.3), control2: CGPoint(x: 43.6, y: 79.2))
            p.addCurve(to: CGPoint(x: 45.1, y: 87.6), control1: CGPoint(x: 44.3, y: 83.5), control2: CGPoint(x: 44.8, y: 85.5))
            p.addCurve(to: CGPoint(x: 46.2, y: 93.7), control1: CGPoint(x: 45.5, y: 89.6), control2: CGPoint(x: 45.9, y: 91.8))
            p.addCurve(to: CGPoint(x: 46.5, y: 99.2), control1: CGPoint(x: 46.4, y: 95.7), control2: CGPoint(x: 46.6, y: 97.3))
            p.addCurve(to: CGPoint(x: 45.7, y: 105.2), control1: CGPoint(x: 46.5, y: 101.1), control2: CGPoint(x: 45.1, y: 103.6))
            p.addCurve(to: CGPoint(x: 50, y: 108.6), control1: CGPoint(x: 46.3, y: 106.7), control2: CGPoint(x: 48.6, y: 107.9))
            p.addCurve(to: CGPoint(x: 54, y: 109.3), control1: CGPoint(x: 51.4, y: 109.3), control2: CGPoint(x: 54, y: 109.3))
            p.addCurve(to: CGPoint(x: 54.2, y: 102), control1: CGPoint(x: 54, y: 109.3), control2: CGPoint(x: 54.3, y: 104.5))
            p.addCurve(to: CGPoint(x: 53.5, y: 94), control1: CGPoint(x: 54.1, y: 99.5), control2: CGPoint(x: 53.5, y: 94))
            p.addCurve(to: CGPoint(x: 47.8, y: 84.5), control1: CGPoint(x: 53.5, y: 94), control2: CGPoint(x: 49.6, y: 87.7))
            p.addCurve(to: CGPoint(x: 42.8, y: 74.8), control1: CGPoint(x: 46, y: 81.3), control2: CGPoint(x: 43.5, y: 75.4))
            p.closeSubpath()
        }
    )

    static let backLatsR = FigureRegion(
        id: "back.lats.r",
        side: .back,
        kind: .muscle(.lats),
        path: Path { p in
            p.move(to: CGPoint(x: 77.2, y: 74.8))
            p.addCurve(to: CGPoint(x: 76.1, y: 81.4), control1: CGPoint(x: 77.8, y: 74.3), control2: CGPoint(x: 76.4, y: 79.2))
            p.addCurve(to: CGPoint(x: 74.9, y: 87.6), control1: CGPoint(x: 75.7, y: 83.5), control2: CGPoint(x: 75.2, y: 85.5))
            p.addCurve(to: CGPoint(x: 73.8, y: 93.7), control1: CGPoint(x: 74.5, y: 89.6), control2: CGPoint(x: 74.1, y: 91.8))
            p.addCurve(to: CGPoint(x: 73.5, y: 99.2), control1: CGPoint(x: 73.6, y: 95.7), control2: CGPoint(x: 73.4, y: 97.3))
            p.addCurve(to: CGPoint(x: 74.3, y: 105.2), control1: CGPoint(x: 73.5, y: 101.1), control2: CGPoint(x: 74.9, y: 103.6))
            p.addCurve(to: CGPoint(x: 70, y: 108.6), control1: CGPoint(x: 73.7, y: 106.7), control2: CGPoint(x: 71.4, y: 107.9))
            p.addCurve(to: CGPoint(x: 66, y: 109.3), control1: CGPoint(x: 68.6, y: 109.3), control2: CGPoint(x: 66, y: 109.3))
            p.addCurve(to: CGPoint(x: 65.8, y: 102), control1: CGPoint(x: 66, y: 109.3), control2: CGPoint(x: 65.7, y: 104.5))
            p.addCurve(to: CGPoint(x: 66.5, y: 94), control1: CGPoint(x: 65.9, y: 99.5), control2: CGPoint(x: 66.5, y: 94))
            p.addCurve(to: CGPoint(x: 72.2, y: 84.5), control1: CGPoint(x: 66.5, y: 94), control2: CGPoint(x: 70.4, y: 87.7))
            p.addCurve(to: CGPoint(x: 77.2, y: 74.8), control1: CGPoint(x: 74, y: 81.3), control2: CGPoint(x: 76.5, y: 75.4))
            p.closeSubpath()
        }
    )

    static let backTricepsL = FigureRegion(
        id: "back.triceps.l",
        side: .back,
        kind: .muscle(.triceps),
        path: Path { p in
            p.move(to: CGPoint(x: 27.7, y: 72.7))
            p.addCurve(to: CGPoint(x: 26.9, y: 78.3), control1: CGPoint(x: 27, y: 74), control2: CGPoint(x: 27.2, y: 76.4))
            p.addCurve(to: CGPoint(x: 26.1, y: 83.9), control1: CGPoint(x: 26.6, y: 80.2), control2: CGPoint(x: 26.3, y: 82.1))
            p.addCurve(to: CGPoint(x: 25.3, y: 89), control1: CGPoint(x: 25.8, y: 85.7), control2: CGPoint(x: 25.5, y: 87.2))
            p.addCurve(to: CGPoint(x: 24.5, y: 94.3), control1: CGPoint(x: 25, y: 90.7), control2: CGPoint(x: 24.1, y: 93.2))
            p.addCurve(to: CGPoint(x: 27.4, y: 95.6), control1: CGPoint(x: 24.9, y: 95.4), control2: CGPoint(x: 26.5, y: 95.7))
            p.addCurve(to: CGPoint(x: 30.4, y: 93.7), control1: CGPoint(x: 28.4, y: 95.5), control2: CGPoint(x: 29.8, y: 94.9))
            p.addCurve(to: CGPoint(x: 31.2, y: 88), control1: CGPoint(x: 31, y: 92.4), control2: CGPoint(x: 30.9, y: 89.8))
            p.addCurve(to: CGPoint(x: 32.2, y: 82.8), control1: CGPoint(x: 31.5, y: 86.2), control2: CGPoint(x: 31.8, y: 84.6))
            p.addCurve(to: CGPoint(x: 33.4, y: 77.3), control1: CGPoint(x: 32.6, y: 81), control2: CGPoint(x: 33, y: 79.1))
            p.addCurve(to: CGPoint(x: 34.9, y: 72), control1: CGPoint(x: 33.9, y: 75.5), control2: CGPoint(x: 35.2, y: 73.1))
            p.addCurve(to: CGPoint(x: 31.3, y: 70.7), control1: CGPoint(x: 34.5, y: 70.9), control2: CGPoint(x: 32.5, y: 70.6))
            p.addCurve(to: CGPoint(x: 27.7, y: 72.7), control1: CGPoint(x: 30.1, y: 70.8), control2: CGPoint(x: 28.5, y: 71.4))
            p.closeSubpath()
        }
    )

    static let backTricepsR = FigureRegion(
        id: "back.triceps.r",
        side: .back,
        kind: .muscle(.triceps),
        path: Path { p in
            p.move(to: CGPoint(x: 92.3, y: 72.7))
            p.addCurve(to: CGPoint(x: 93.1, y: 78.3), control1: CGPoint(x: 93, y: 74), control2: CGPoint(x: 92.8, y: 76.4))
            p.addCurve(to: CGPoint(x: 93.9, y: 83.9), control1: CGPoint(x: 93.4, y: 80.2), control2: CGPoint(x: 93.7, y: 82.1))
            p.addCurve(to: CGPoint(x: 94.7, y: 89), control1: CGPoint(x: 94.2, y: 85.7), control2: CGPoint(x: 94.5, y: 87.2))
            p.addCurve(to: CGPoint(x: 95.5, y: 94.3), control1: CGPoint(x: 95, y: 90.7), control2: CGPoint(x: 95.9, y: 93.2))
            p.addCurve(to: CGPoint(x: 92.6, y: 95.6), control1: CGPoint(x: 95.1, y: 95.4), control2: CGPoint(x: 93.5, y: 95.7))
            p.addCurve(to: CGPoint(x: 89.6, y: 93.7), control1: CGPoint(x: 91.6, y: 95.5), control2: CGPoint(x: 90.2, y: 94.9))
            p.addCurve(to: CGPoint(x: 88.8, y: 88), control1: CGPoint(x: 89, y: 92.4), control2: CGPoint(x: 89.1, y: 89.8))
            p.addCurve(to: CGPoint(x: 87.8, y: 82.8), control1: CGPoint(x: 88.5, y: 86.2), control2: CGPoint(x: 88.2, y: 84.6))
            p.addCurve(to: CGPoint(x: 86.6, y: 77.3), control1: CGPoint(x: 87.4, y: 81), control2: CGPoint(x: 87, y: 79.1))
            p.addCurve(to: CGPoint(x: 85.1, y: 72), control1: CGPoint(x: 86.1, y: 75.5), control2: CGPoint(x: 84.8, y: 73.1))
            p.addCurve(to: CGPoint(x: 88.7, y: 70.7), control1: CGPoint(x: 85.5, y: 70.9), control2: CGPoint(x: 87.5, y: 70.6))
            p.addCurve(to: CGPoint(x: 92.3, y: 72.7), control1: CGPoint(x: 89.9, y: 70.8), control2: CGPoint(x: 91.5, y: 71.4))
            p.closeSubpath()
        }
    )

    static let backForearmBackL = FigureRegion(
        id: "back.forearm-back.l",
        side: .back,
        kind: .muscle(.forearms),
        path: Path { p in
            p.move(to: CGPoint(x: 23, y: 101.4))
            p.addCurve(to: CGPoint(x: 22.3, y: 107.4), control1: CGPoint(x: 22.4, y: 102.7), control2: CGPoint(x: 22.5, y: 105.1))
            p.addCurve(to: CGPoint(x: 21.7, y: 115.3), control1: CGPoint(x: 22, y: 109.7), control2: CGPoint(x: 21.9, y: 112.5))
            p.addCurve(to: CGPoint(x: 21.4, y: 124.2), control1: CGPoint(x: 21.6, y: 118.1), control2: CGPoint(x: 21.5, y: 121.2))
            p.addCurve(to: CGPoint(x: 21.2, y: 133), control1: CGPoint(x: 21.3, y: 127.1), control2: CGPoint(x: 20.9, y: 131.3))
            p.addCurve(to: CGPoint(x: 23.1, y: 134.4), control1: CGPoint(x: 21.5, y: 134.7), control2: CGPoint(x: 22.4, y: 134.5))
            p.addCurve(to: CGPoint(x: 25, y: 132.5), control1: CGPoint(x: 23.7, y: 134.3), control2: CGPoint(x: 24.4, y: 134.2))
            p.addCurve(to: CGPoint(x: 26.3, y: 124.5), control1: CGPoint(x: 25.5, y: 130.9), control2: CGPoint(x: 25.9, y: 127.1))
            p.addCurve(to: CGPoint(x: 27.5, y: 116.8), control1: CGPoint(x: 26.7, y: 121.9), control2: CGPoint(x: 27.2, y: 119.3))
            p.addCurve(to: CGPoint(x: 28.7, y: 109), control1: CGPoint(x: 27.9, y: 114.2), control2: CGPoint(x: 28.3, y: 111.6))
            p.addCurve(to: CGPoint(x: 29.6, y: 101), control1: CGPoint(x: 29, y: 106.4), control2: CGPoint(x: 30, y: 102.6))
            p.addCurve(to: CGPoint(x: 26.3, y: 99.6), control1: CGPoint(x: 29.2, y: 99.5), control2: CGPoint(x: 27.4, y: 99.5))
            p.addCurve(to: CGPoint(x: 23, y: 101.4), control1: CGPoint(x: 25.2, y: 99.7), control2: CGPoint(x: 23.7, y: 100.1))
            p.closeSubpath()
        }
    )

    static let backForearmBackR = FigureRegion(
        id: "back.forearm-back.r",
        side: .back,
        kind: .muscle(.forearms),
        path: Path { p in
            p.move(to: CGPoint(x: 97, y: 101.4))
            p.addCurve(to: CGPoint(x: 97.7, y: 107.4), control1: CGPoint(x: 97.6, y: 102.7), control2: CGPoint(x: 97.5, y: 105.1))
            p.addCurve(to: CGPoint(x: 98.3, y: 115.3), control1: CGPoint(x: 98, y: 109.7), control2: CGPoint(x: 98.1, y: 112.5))
            p.addCurve(to: CGPoint(x: 98.6, y: 124.2), control1: CGPoint(x: 98.4, y: 118.1), control2: CGPoint(x: 98.5, y: 121.2))
            p.addCurve(to: CGPoint(x: 98.8, y: 133), control1: CGPoint(x: 98.7, y: 127.1), control2: CGPoint(x: 99.1, y: 131.3))
            p.addCurve(to: CGPoint(x: 96.9, y: 134.4), control1: CGPoint(x: 98.5, y: 134.7), control2: CGPoint(x: 97.6, y: 134.5))
            p.addCurve(to: CGPoint(x: 95, y: 132.5), control1: CGPoint(x: 96.3, y: 134.3), control2: CGPoint(x: 95.6, y: 134.2))
            p.addCurve(to: CGPoint(x: 93.7, y: 124.5), control1: CGPoint(x: 94.5, y: 130.9), control2: CGPoint(x: 94.1, y: 127.1))
            p.addCurve(to: CGPoint(x: 92.5, y: 116.8), control1: CGPoint(x: 93.3, y: 121.9), control2: CGPoint(x: 92.8, y: 119.3))
            p.addCurve(to: CGPoint(x: 91.3, y: 109), control1: CGPoint(x: 92.1, y: 114.2), control2: CGPoint(x: 91.7, y: 111.6))
            p.addCurve(to: CGPoint(x: 90.4, y: 101), control1: CGPoint(x: 91, y: 106.4), control2: CGPoint(x: 90, y: 102.6))
            p.addCurve(to: CGPoint(x: 93.7, y: 99.6), control1: CGPoint(x: 90.8, y: 99.5), control2: CGPoint(x: 92.6, y: 99.5))
            p.addCurve(to: CGPoint(x: 97, y: 101.4), control1: CGPoint(x: 94.8, y: 99.7), control2: CGPoint(x: 96.3, y: 100.1))
            p.closeSubpath()
        }
    )

    static let backGlutesL = FigureRegion(
        id: "back.glutes.l",
        side: .back,
        kind: .muscle(.glutes),
        path: Path { p in
            p.move(to: CGPoint(x: 58.5, y: 114.5))
            p.addCurve(to: CGPoint(x: 51, y: 113.3), control1: CGPoint(x: 58.5, y: 114.5), control2: CGPoint(x: 53.5, y: 113.3))
            p.addCurve(to: CGPoint(x: 43.5, y: 114.2), control1: CGPoint(x: 48.5, y: 113.2), control2: CGPoint(x: 44.9, y: 113.7))
            p.addCurve(to: CGPoint(x: 42.5, y: 116.5), control1: CGPoint(x: 42.1, y: 114.7), control2: CGPoint(x: 43, y: 114.8))
            p.addCurve(to: CGPoint(x: 40.6, y: 123.9), control1: CGPoint(x: 42.1, y: 118.1), control2: CGPoint(x: 41, y: 122))
            p.addCurve(to: CGPoint(x: 39.8, y: 127.9), control1: CGPoint(x: 40.1, y: 125.8), control2: CGPoint(x: 40, y: 126.3))
            p.addCurve(to: CGPoint(x: 39.6, y: 133.8), control1: CGPoint(x: 39.7, y: 129.6), control2: CGPoint(x: 39.2, y: 132.1))
            p.addCurve(to: CGPoint(x: 42.5, y: 138), control1: CGPoint(x: 40.1, y: 135.5), control2: CGPoint(x: 40.8, y: 137))
            p.addCurve(to: CGPoint(x: 50, y: 139.6), control1: CGPoint(x: 44.2, y: 139), control2: CGPoint(x: 47.8, y: 139.7))
            p.addCurve(to: CGPoint(x: 55.5, y: 137.5), control1: CGPoint(x: 52.2, y: 139.5), control2: CGPoint(x: 54.2, y: 139.3))
            p.addCurve(to: CGPoint(x: 57.7, y: 129), control1: CGPoint(x: 56.8, y: 135.7), control2: CGPoint(x: 57.2, y: 131.6))
            p.addCurve(to: CGPoint(x: 58.5, y: 122), control1: CGPoint(x: 58.2, y: 126.4), control2: CGPoint(x: 58.5, y: 122))
            p.addCurve(to: CGPoint(x: 58.5, y: 114.5), control1: CGPoint(x: 58.5, y: 122), control2: CGPoint(x: 58.5, y: 114.5))
            p.closeSubpath()
        }
    )

    static let backGlutesR = FigureRegion(
        id: "back.glutes.r",
        side: .back,
        kind: .muscle(.glutes),
        path: Path { p in
            p.move(to: CGPoint(x: 61.5, y: 114.5))
            p.addCurve(to: CGPoint(x: 69, y: 113.3), control1: CGPoint(x: 61.5, y: 114.5), control2: CGPoint(x: 66.5, y: 113.3))
            p.addCurve(to: CGPoint(x: 76.5, y: 114.2), control1: CGPoint(x: 71.5, y: 113.2), control2: CGPoint(x: 75.1, y: 113.7))
            p.addCurve(to: CGPoint(x: 77.5, y: 116.5), control1: CGPoint(x: 77.9, y: 114.7), control2: CGPoint(x: 77, y: 114.8))
            p.addCurve(to: CGPoint(x: 79.4, y: 123.9), control1: CGPoint(x: 77.9, y: 118.1), control2: CGPoint(x: 79, y: 122))
            p.addCurve(to: CGPoint(x: 80.2, y: 127.9), control1: CGPoint(x: 79.9, y: 125.8), control2: CGPoint(x: 80, y: 126.3))
            p.addCurve(to: CGPoint(x: 80.4, y: 133.8), control1: CGPoint(x: 80.3, y: 129.6), control2: CGPoint(x: 80.8, y: 132.1))
            p.addCurve(to: CGPoint(x: 77.5, y: 138), control1: CGPoint(x: 79.9, y: 135.5), control2: CGPoint(x: 79.2, y: 137))
            p.addCurve(to: CGPoint(x: 70, y: 139.6), control1: CGPoint(x: 75.8, y: 139), control2: CGPoint(x: 72.2, y: 139.7))
            p.addCurve(to: CGPoint(x: 64.5, y: 137.5), control1: CGPoint(x: 67.8, y: 139.5), control2: CGPoint(x: 65.8, y: 139.3))
            p.addCurve(to: CGPoint(x: 62.3, y: 129), control1: CGPoint(x: 63.2, y: 135.7), control2: CGPoint(x: 62.8, y: 131.6))
            p.addCurve(to: CGPoint(x: 61.5, y: 122), control1: CGPoint(x: 61.8, y: 126.4), control2: CGPoint(x: 61.5, y: 122))
            p.addCurve(to: CGPoint(x: 61.5, y: 114.5), control1: CGPoint(x: 61.5, y: 122), control2: CGPoint(x: 61.5, y: 114.5))
            p.closeSubpath()
        }
    )

    static let backHamstringsL = FigureRegion(
        id: "back.hamstrings.l",
        side: .back,
        kind: .muscle(.hamstrings),
        path: Path { p in
            p.move(to: CGPoint(x: 39.9, y: 143.2))
            p.addCurve(to: CGPoint(x: 40.4, y: 151.7), control1: CGPoint(x: 38.7, y: 145), control2: CGPoint(x: 40.2, y: 148.9))
            p.addCurve(to: CGPoint(x: 41.1, y: 160.2), control1: CGPoint(x: 40.6, y: 154.5), control2: CGPoint(x: 40.8, y: 157.5))
            p.addCurve(to: CGPoint(x: 41.8, y: 167.9), control1: CGPoint(x: 41.3, y: 162.9), control2: CGPoint(x: 41.6, y: 165.3))
            p.addCurve(to: CGPoint(x: 42.8, y: 175.7), control1: CGPoint(x: 42.1, y: 170.5), control2: CGPoint(x: 41.9, y: 174.1))
            p.addCurve(to: CGPoint(x: 47.3, y: 177.6), control1: CGPoint(x: 43.7, y: 177.3), control2: CGPoint(x: 45.8, y: 177.6))
            p.addCurve(to: CGPoint(x: 51.9, y: 175.9), control1: CGPoint(x: 48.9, y: 177.6), control2: CGPoint(x: 51, y: 177.5))
            p.addCurve(to: CGPoint(x: 52.7, y: 167.8), control1: CGPoint(x: 52.8, y: 174.2), control2: CGPoint(x: 52.4, y: 170.5))
            p.addCurve(to: CGPoint(x: 53.7, y: 159.4), control1: CGPoint(x: 53, y: 165), control2: CGPoint(x: 53.3, y: 162.2))
            p.addCurve(to: CGPoint(x: 54.6, y: 151), control1: CGPoint(x: 54, y: 156.6), control2: CGPoint(x: 54.3, y: 153.8))
            p.addCurve(to: CGPoint(x: 55.6, y: 142.9), control1: CGPoint(x: 55, y: 148.3), control2: CGPoint(x: 56.8, y: 144.6))
            p.addCurve(to: CGPoint(x: 47.7, y: 141.3), control1: CGPoint(x: 54.5, y: 141.3), control2: CGPoint(x: 50.4, y: 141.2))
            p.addCurve(to: CGPoint(x: 39.9, y: 143.2), control1: CGPoint(x: 45.1, y: 141.3), control2: CGPoint(x: 41.1, y: 141.5))
            p.closeSubpath()
        }
    )

    static let backHamstringsR = FigureRegion(
        id: "back.hamstrings.r",
        side: .back,
        kind: .muscle(.hamstrings),
        path: Path { p in
            p.move(to: CGPoint(x: 80.1, y: 143.2))
            p.addCurve(to: CGPoint(x: 79.6, y: 151.7), control1: CGPoint(x: 81.3, y: 145), control2: CGPoint(x: 79.8, y: 148.9))
            p.addCurve(to: CGPoint(x: 78.9, y: 160.2), control1: CGPoint(x: 79.4, y: 154.5), control2: CGPoint(x: 79.2, y: 157.5))
            p.addCurve(to: CGPoint(x: 78.2, y: 167.9), control1: CGPoint(x: 78.7, y: 162.9), control2: CGPoint(x: 78.4, y: 165.3))
            p.addCurve(to: CGPoint(x: 77.2, y: 175.7), control1: CGPoint(x: 77.9, y: 170.5), control2: CGPoint(x: 78.1, y: 174.1))
            p.addCurve(to: CGPoint(x: 72.7, y: 177.6), control1: CGPoint(x: 76.3, y: 177.3), control2: CGPoint(x: 74.2, y: 177.6))
            p.addCurve(to: CGPoint(x: 68.1, y: 175.9), control1: CGPoint(x: 71.1, y: 177.6), control2: CGPoint(x: 69, y: 177.5))
            p.addCurve(to: CGPoint(x: 67.3, y: 167.8), control1: CGPoint(x: 67.2, y: 174.2), control2: CGPoint(x: 67.6, y: 170.5))
            p.addCurve(to: CGPoint(x: 66.3, y: 159.4), control1: CGPoint(x: 67, y: 165), control2: CGPoint(x: 66.7, y: 162.2))
            p.addCurve(to: CGPoint(x: 65.4, y: 151), control1: CGPoint(x: 66, y: 156.6), control2: CGPoint(x: 65.7, y: 153.8))
            p.addCurve(to: CGPoint(x: 64.4, y: 142.9), control1: CGPoint(x: 65, y: 148.3), control2: CGPoint(x: 63.2, y: 144.6))
            p.addCurve(to: CGPoint(x: 72.3, y: 141.3), control1: CGPoint(x: 65.5, y: 141.3), control2: CGPoint(x: 69.6, y: 141.2))
            p.addCurve(to: CGPoint(x: 80.1, y: 143.2), control1: CGPoint(x: 74.9, y: 141.3), control2: CGPoint(x: 78.9, y: 141.5))
            p.closeSubpath()
        }
    )

    static let backCalvesL = FigureRegion(
        id: "back.calves.l",
        side: .back,
        kind: .muscle(.calves),
        path: Path { p in
            p.move(to: CGPoint(x: 42.4, y: 191.4))
            p.addCurve(to: CGPoint(x: 41.7, y: 195.9), control1: CGPoint(x: 41.6, y: 192.4), control2: CGPoint(x: 41.9, y: 194.4))
            p.addCurve(to: CGPoint(x: 41.2, y: 200), control1: CGPoint(x: 41.5, y: 197.3), control2: CGPoint(x: 41.3, y: 198.5))
            p.addCurve(to: CGPoint(x: 41.1, y: 205.3), control1: CGPoint(x: 41.1, y: 201.6), control2: CGPoint(x: 41.1, y: 203))
            p.addCurve(to: CGPoint(x: 41.5, y: 213.8), control1: CGPoint(x: 41.2, y: 207.5), control2: CGPoint(x: 41.1, y: 210.7))
            p.addCurve(to: CGPoint(x: 43.5, y: 224), control1: CGPoint(x: 41.9, y: 216.9), control2: CGPoint(x: 42.7, y: 221.4))
            p.addCurve(to: CGPoint(x: 46.5, y: 229.5), control1: CGPoint(x: 44.3, y: 226.6), control2: CGPoint(x: 45.5, y: 229.5))
            p.addCurve(to: CGPoint(x: 49.5, y: 224), control1: CGPoint(x: 47.5, y: 229.5), control2: CGPoint(x: 48.7, y: 226.6))
            p.addCurve(to: CGPoint(x: 51.4, y: 213.9), control1: CGPoint(x: 50.3, y: 221.4), control2: CGPoint(x: 51, y: 217))
            p.addCurve(to: CGPoint(x: 51.8, y: 205.2), control1: CGPoint(x: 51.8, y: 210.7), control2: CGPoint(x: 51.7, y: 207.5))
            p.addCurve(to: CGPoint(x: 51.9, y: 199.8), control1: CGPoint(x: 51.9, y: 202.8), control2: CGPoint(x: 51.9, y: 201.4))
            p.addCurve(to: CGPoint(x: 51.9, y: 195.3), control1: CGPoint(x: 51.9, y: 198.1), control2: CGPoint(x: 51.9, y: 196.7))
            p.addCurve(to: CGPoint(x: 51.8, y: 191), control1: CGPoint(x: 51.9, y: 193.8), control2: CGPoint(x: 52.7, y: 191.9))
            p.addCurve(to: CGPoint(x: 46.6, y: 189.6), control1: CGPoint(x: 50.9, y: 190.1), control2: CGPoint(x: 48.2, y: 189.5))
            p.addCurve(to: CGPoint(x: 42.4, y: 191.4), control1: CGPoint(x: 45, y: 189.7), control2: CGPoint(x: 43.3, y: 190.3))
            p.closeSubpath()
        }
    )

    static let backCalvesR = FigureRegion(
        id: "back.calves.r",
        side: .back,
        kind: .muscle(.calves),
        path: Path { p in
            p.move(to: CGPoint(x: 77.6, y: 191.4))
            p.addCurve(to: CGPoint(x: 78.3, y: 195.9), control1: CGPoint(x: 78.4, y: 192.4), control2: CGPoint(x: 78.1, y: 194.4))
            p.addCurve(to: CGPoint(x: 78.8, y: 200), control1: CGPoint(x: 78.5, y: 197.3), control2: CGPoint(x: 78.7, y: 198.5))
            p.addCurve(to: CGPoint(x: 78.9, y: 205.3), control1: CGPoint(x: 78.9, y: 201.6), control2: CGPoint(x: 78.9, y: 203))
            p.addCurve(to: CGPoint(x: 78.5, y: 213.8), control1: CGPoint(x: 78.8, y: 207.5), control2: CGPoint(x: 78.9, y: 210.7))
            p.addCurve(to: CGPoint(x: 76.5, y: 224), control1: CGPoint(x: 78.1, y: 216.9), control2: CGPoint(x: 77.3, y: 221.4))
            p.addCurve(to: CGPoint(x: 73.5, y: 229.5), control1: CGPoint(x: 75.7, y: 226.6), control2: CGPoint(x: 74.5, y: 229.5))
            p.addCurve(to: CGPoint(x: 70.5, y: 224), control1: CGPoint(x: 72.5, y: 229.5), control2: CGPoint(x: 71.3, y: 226.6))
            p.addCurve(to: CGPoint(x: 68.6, y: 213.9), control1: CGPoint(x: 69.7, y: 221.4), control2: CGPoint(x: 69, y: 217))
            p.addCurve(to: CGPoint(x: 68.2, y: 205.2), control1: CGPoint(x: 68.2, y: 210.7), control2: CGPoint(x: 68.3, y: 207.5))
            p.addCurve(to: CGPoint(x: 68.1, y: 199.8), control1: CGPoint(x: 68.1, y: 202.8), control2: CGPoint(x: 68.1, y: 201.4))
            p.addCurve(to: CGPoint(x: 68.1, y: 195.3), control1: CGPoint(x: 68.1, y: 198.1), control2: CGPoint(x: 68.1, y: 196.7))
            p.addCurve(to: CGPoint(x: 68.2, y: 191), control1: CGPoint(x: 68.1, y: 193.8), control2: CGPoint(x: 67.3, y: 191.9))
            p.addCurve(to: CGPoint(x: 73.4, y: 189.6), control1: CGPoint(x: 69.1, y: 190.1), control2: CGPoint(x: 71.8, y: 189.5))
            p.addCurve(to: CGPoint(x: 77.6, y: 191.4), control1: CGPoint(x: 75, y: 189.7), control2: CGPoint(x: 76.7, y: 190.3))
            p.closeSubpath()
        }
    )

    static let backLowerBack = FigureRegion(
        id: "back.lower-back",
        side: .back,
        kind: .muscle(.lowerBack),
        path: Path { p in
            p.move(to: CGPoint(x: 56.8, y: 93))
            p.addCurve(to: CGPoint(x: 60, y: 92.4), control1: CGPoint(x: 57.4, y: 91.3), control2: CGPoint(x: 58.9, y: 92.4))
            p.addCurve(to: CGPoint(x: 63.2, y: 93), control1: CGPoint(x: 61.1, y: 92.4), control2: CGPoint(x: 62.6, y: 91.3))
            p.addCurve(to: CGPoint(x: 63.5, y: 102.5), control1: CGPoint(x: 63.8, y: 94.7), control2: CGPoint(x: 63.5, y: 99.3))
            p.addCurve(to: CGPoint(x: 63.2, y: 112), control1: CGPoint(x: 63.5, y: 105.7), control2: CGPoint(x: 63.8, y: 110.3))
            p.addCurve(to: CGPoint(x: 60, y: 112.8), control1: CGPoint(x: 62.6, y: 113.7), control2: CGPoint(x: 61.1, y: 112.8))
            p.addCurve(to: CGPoint(x: 56.8, y: 112), control1: CGPoint(x: 58.9, y: 112.8), control2: CGPoint(x: 57.4, y: 113.7))
            p.addCurve(to: CGPoint(x: 56.5, y: 102.5), control1: CGPoint(x: 56.2, y: 110.3), control2: CGPoint(x: 56.5, y: 105.7))
            p.addCurve(to: CGPoint(x: 56.8, y: 93), control1: CGPoint(x: 56.5, y: 99.3), control2: CGPoint(x: 56.2, y: 94.7))
            p.closeSubpath()
        }
    )

    static let backOutline = FigureRegion(
        id: "back.outline",
        side: .back,
        kind: .outline,
        path: Path { p in
            p.move(to: CGPoint(x: 60, y: 5.5))
            p.addCurve(to: CGPoint(x: 72.5, y: 22), control1: CGPoint(x: 66.9, y: 5.5), control2: CGPoint(x: 72.5, y: 12.9))
            p.addCurve(to: CGPoint(x: 66, y: 36.5), control1: CGPoint(x: 72.5, y: 28), control2: CGPoint(x: 70, y: 33.6))
            p.addCurve(to: CGPoint(x: 67, y: 45), control1: CGPoint(x: 66, y: 39.5), control2: CGPoint(x: 66.3, y: 42.8))
            p.addCurve(to: CGPoint(x: 85, y: 49), control1: CGPoint(x: 72, y: 46), control2: CGPoint(x: 80, y: 47.5))
            p.addCurve(to: CGPoint(x: 92.5, y: 61), control1: CGPoint(x: 89, y: 50.5), control2: CGPoint(x: 92.5, y: 55))
            p.addCurve(to: CGPoint(x: 97.5, y: 97), control1: CGPoint(x: 93.5, y: 72), control2: CGPoint(x: 96, y: 86))
            p.addCurve(to: CGPoint(x: 100.5, y: 136), control1: CGPoint(x: 100, y: 104), control2: CGPoint(x: 100, y: 120))
            p.addCurve(to: CGPoint(x: 103.5, y: 149), control1: CGPoint(x: 102.5, y: 139), control2: CGPoint(x: 104, y: 144))
            p.addCurve(to: CGPoint(x: 101.5, y: 155), control1: CGPoint(x: 103, y: 151), control2: CGPoint(x: 101.5, y: 152))
            p.addCurve(to: CGPoint(x: 92.5, y: 155), control1: CGPoint(x: 101.5, y: 161), control2: CGPoint(x: 92.5, y: 161))
            p.addLine(to: CGPoint(x: 92.5, y: 150))
            p.addCurve(to: CGPoint(x: 94, y: 136), control1: CGPoint(x: 92.5, y: 144), control2: CGPoint(x: 93.5, y: 140))
            p.addCurve(to: CGPoint(x: 88.5, y: 98), control1: CGPoint(x: 92, y: 124), control2: CGPoint(x: 89.5, y: 110))
            p.addCurve(to: CGPoint(x: 82.5, y: 69), control1: CGPoint(x: 87.5, y: 88), control2: CGPoint(x: 85.5, y: 78))
            p.addCurve(to: CGPoint(x: 79.5, y: 69), control1: CGPoint(x: 81.5, y: 67.5), control2: CGPoint(x: 80, y: 67.5))
            p.addCurve(to: CGPoint(x: 75, y: 98), control1: CGPoint(x: 78.5, y: 80), control2: CGPoint(x: 75.5, y: 90))
            p.addCurve(to: CGPoint(x: 80.5, y: 122), control1: CGPoint(x: 75.5, y: 108), control2: CGPoint(x: 79, y: 114))
            p.addCurve(to: CGPoint(x: 82, y: 132), control1: CGPoint(x: 81.5, y: 125), control2: CGPoint(x: 82, y: 128))
            p.addCurve(to: CGPoint(x: 78, y: 182), control1: CGPoint(x: 82, y: 148), control2: CGPoint(x: 80, y: 168))
            p.addCurve(to: CGPoint(x: 80.5, y: 203), control1: CGPoint(x: 78.5, y: 190), control2: CGPoint(x: 80.5, y: 196))
            p.addCurve(to: CGPoint(x: 77, y: 240), control1: CGPoint(x: 80.5, y: 215), control2: CGPoint(x: 78.5, y: 230))
            p.addCurve(to: CGPoint(x: 82.5, y: 252), control1: CGPoint(x: 78, y: 245), control2: CGPoint(x: 81, y: 248.5))
            p.addCurve(to: CGPoint(x: 80, y: 254), control1: CGPoint(x: 83, y: 253.5), control2: CGPoint(x: 81.5, y: 254))
            p.addLine(to: CGPoint(x: 70, y: 254))
            p.addCurve(to: CGPoint(x: 68, y: 251.5), control1: CGPoint(x: 68, y: 254), control2: CGPoint(x: 67.5, y: 253))
            p.addCurve(to: CGPoint(x: 69.5, y: 240), control1: CGPoint(x: 68.5, y: 248), control2: CGPoint(x: 69.2, y: 244))
            p.addCurve(to: CGPoint(x: 66.5, y: 203), control1: CGPoint(x: 68.5, y: 232), control2: CGPoint(x: 67, y: 218))
            p.addCurve(to: CGPoint(x: 67, y: 182), control1: CGPoint(x: 66.5, y: 195), control2: CGPoint(x: 66.5, y: 188))
            p.addCurve(to: CGPoint(x: 62, y: 136), control1: CGPoint(x: 66, y: 168), control2: CGPoint(x: 63.5, y: 150))
            p.addCurve(to: CGPoint(x: 60, y: 122), control1: CGPoint(x: 61.5, y: 130), control2: CGPoint(x: 60.5, y: 125))
            p.addCurve(to: CGPoint(x: 58, y: 136), control1: CGPoint(x: 59.5, y: 125), control2: CGPoint(x: 58.5, y: 130))
            p.addCurve(to: CGPoint(x: 53, y: 182), control1: CGPoint(x: 56.5, y: 150), control2: CGPoint(x: 54, y: 168))
            p.addCurve(to: CGPoint(x: 53.5, y: 203), control1: CGPoint(x: 53.5, y: 188), control2: CGPoint(x: 53.5, y: 195))
            p.addCurve(to: CGPoint(x: 50.5, y: 240), control1: CGPoint(x: 53, y: 218), control2: CGPoint(x: 51.5, y: 232))
            p.addCurve(to: CGPoint(x: 52, y: 251.5), control1: CGPoint(x: 50.8, y: 244), control2: CGPoint(x: 51.5, y: 248))
            p.addCurve(to: CGPoint(x: 50, y: 254), control1: CGPoint(x: 52.5, y: 253), control2: CGPoint(x: 52, y: 254))
            p.addLine(to: CGPoint(x: 40, y: 254))
            p.addCurve(to: CGPoint(x: 37.5, y: 252), control1: CGPoint(x: 38.5, y: 254), control2: CGPoint(x: 37, y: 253.5))
            p.addCurve(to: CGPoint(x: 43, y: 240), control1: CGPoint(x: 39, y: 248.5), control2: CGPoint(x: 42, y: 245))
            p.addCurve(to: CGPoint(x: 39.5, y: 203), control1: CGPoint(x: 41.5, y: 230), control2: CGPoint(x: 39.5, y: 215))
            p.addCurve(to: CGPoint(x: 42, y: 182), control1: CGPoint(x: 39.5, y: 196), control2: CGPoint(x: 41.5, y: 190))
            p.addCurve(to: CGPoint(x: 38, y: 132), control1: CGPoint(x: 40, y: 168), control2: CGPoint(x: 38, y: 148))
            p.addCurve(to: CGPoint(x: 39.5, y: 122), control1: CGPoint(x: 38, y: 128), control2: CGPoint(x: 38.5, y: 125))
            p.addCurve(to: CGPoint(x: 45, y: 98), control1: CGPoint(x: 41, y: 114), control2: CGPoint(x: 44.5, y: 108))
            p.addCurve(to: CGPoint(x: 40.5, y: 69), control1: CGPoint(x: 44.5, y: 90), control2: CGPoint(x: 41.5, y: 80))
            p.addCurve(to: CGPoint(x: 37.5, y: 69), control1: CGPoint(x: 40, y: 67.5), control2: CGPoint(x: 38.5, y: 67.5))
            p.addCurve(to: CGPoint(x: 31.5, y: 98), control1: CGPoint(x: 34.5, y: 78), control2: CGPoint(x: 32.5, y: 88))
            p.addCurve(to: CGPoint(x: 26, y: 136), control1: CGPoint(x: 30.5, y: 110), control2: CGPoint(x: 28, y: 124))
            p.addCurve(to: CGPoint(x: 27.5, y: 150), control1: CGPoint(x: 26.5, y: 140), control2: CGPoint(x: 27.5, y: 144))
            p.addLine(to: CGPoint(x: 27.5, y: 155))
            p.addCurve(to: CGPoint(x: 18.5, y: 155), control1: CGPoint(x: 27.5, y: 161), control2: CGPoint(x: 18.5, y: 161))
            p.addCurve(to: CGPoint(x: 16.5, y: 149), control1: CGPoint(x: 18.5, y: 152), control2: CGPoint(x: 17, y: 151))
            p.addCurve(to: CGPoint(x: 19.5, y: 136), control1: CGPoint(x: 16, y: 144), control2: CGPoint(x: 17.5, y: 139))
            p.addCurve(to: CGPoint(x: 22.5, y: 97), control1: CGPoint(x: 20, y: 120), control2: CGPoint(x: 20, y: 104))
            p.addCurve(to: CGPoint(x: 27.5, y: 61), control1: CGPoint(x: 24, y: 86), control2: CGPoint(x: 26.5, y: 72))
            p.addCurve(to: CGPoint(x: 35, y: 49), control1: CGPoint(x: 27.5, y: 55), control2: CGPoint(x: 31, y: 50.5))
            p.addCurve(to: CGPoint(x: 53, y: 45), control1: CGPoint(x: 40, y: 47.5), control2: CGPoint(x: 48, y: 46))
            p.addCurve(to: CGPoint(x: 54, y: 36.5), control1: CGPoint(x: 53.7, y: 42.8), control2: CGPoint(x: 54, y: 39.5))
            p.addCurve(to: CGPoint(x: 47.5, y: 22), control1: CGPoint(x: 50, y: 33.6), control2: CGPoint(x: 47.5, y: 28))
            p.addCurve(to: CGPoint(x: 60, y: 5.5), control1: CGPoint(x: 47.5, y: 12.9), control2: CGPoint(x: 53.1, y: 5.5))
            p.closeSubpath()
        }
    )
}
