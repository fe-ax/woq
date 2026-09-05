import Foundation

/// The 18 muscle groups WOQ can tag an exercise with.
///
/// Raw values are persisted in SwiftData and must never change. The case order
/// is the display order used by pickers, chips and accessibility summaries.
nonisolated enum Muscle: String, CaseIterable, Codable, Identifiable, Sendable {
    case chest
    case deltoidFront
    case deltoidSide
    case deltoidRear
    case biceps
    case triceps
    case forearms
    case abs
    case obliques
    case traps
    case upperBack
    case lats
    case lowerBack
    case glutes
    case quads
    case hamstrings
    case adductors
    case calves

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: String(localized: "Chest")
        case .deltoidFront: String(localized: "Front delts")
        case .deltoidSide: String(localized: "Side delts")
        case .deltoidRear: String(localized: "Rear delts")
        case .biceps: String(localized: "Biceps")
        case .triceps: String(localized: "Triceps")
        case .forearms: String(localized: "Forearms")
        case .abs: String(localized: "Abs")
        case .obliques: String(localized: "Obliques")
        case .traps: String(localized: "Traps")
        case .upperBack: String(localized: "Upper back")
        case .lats: String(localized: "Lats")
        case .lowerBack: String(localized: "Lower back")
        case .glutes: String(localized: "Glutes")
        case .quads: String(localized: "Quads")
        case .hamstrings: String(localized: "Hamstrings")
        case .adductors: String(localized: "Adductors")
        case .calves: String(localized: "Calves")
        }
    }
}

/// How hard a muscle works in an exercise. Raw values are persisted.
nonisolated enum Intensity: Int, Codable, CaseIterable, Sendable, Comparable {
    case stabiliser = 1
    case secondary = 2
    case primary = 3

    var displayName: String {
        switch self {
        case .stabiliser: String(localized: "Stabiliser")
        case .secondary: String(localized: "Secondary")
        case .primary: String(localized: "Primary")
        }
    }

    static func < (lhs: Intensity, rhs: Intensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// One muscle plus how hard it works. Stored as a Codable blob on Exercise.
nonisolated struct MuscleTag: Codable, Hashable, Sendable {
    var muscle: Muscle
    var intensity: Intensity

    init(muscle: Muscle, intensity: Intensity) {
        self.muscle = muscle
        self.intensity = intensity
    }
}

extension Muscle {
    /// Denormalised search text for a tag list: lowercased display names joined
    /// by spaces, in `Muscle.allCases` order. Used by the data layer so text
    /// search can match muscle names with `localizedStandardContains`.
    static func searchText(for tags: [MuscleTag]) -> String {
        let tagged = Set(tags.map(\.muscle))
        return Muscle.allCases
            .filter { tagged.contains($0) }
            .map { $0.displayName.lowercased() }
            .joined(separator: " ")
    }
}
