import Foundation

/// One ready-made exercise offered by the preset list in the "New exercise" sheet.
///
/// A preset is pure data: picking one inserts a normal `Exercise` with the same name,
/// unilateral flag and muscle tags, after which nothing distinguishes it from an
/// exercise typed by hand. `id` is the name, which is also the duplicate key
/// (case-insensitively, through `Exercise.nameKey(for:)`), so names must stay unique
/// inside `ExercisePresets.all`.
nonisolated struct ExercisePreset: Identifiable, Hashable, Sendable {

    /// The six groups the preset list is sectioned by, in display order.
    nonisolated enum Category: String, CaseIterable, Identifiable, Hashable, Sendable {
        case chest
        case back
        case shoulders
        case arms
        case legs
        case core

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .chest: String(localized: "Chest")
            case .back: String(localized: "Back")
            case .shoulders: String(localized: "Shoulders")
            case .arms: String(localized: "Arms")
            case .legs: String(localized: "Legs")
            case .core: String(localized: "Core")
            }
        }
    }

    /// Stored verbatim as the exercise name, so this is data and not a UI string:
    /// it lands in the database and is matched case-insensitively against exercises
    /// that already exist. The app is English-only (PLAN.md), and a translated name
    /// would silently create duplicates of exercises added in another language.
    var name: String
    var category: Category
    var isUnilateral: Bool
    var tags: [MuscleTag]

    var id: String { name }

    init(name: String, category: Category, isUnilateral: Bool = false, tags: [MuscleTag]) {
        self.name = name
        self.category = category
        self.isUnilateral = isUnilateral
        self.tags = tags
    }

    /// "Chest, Triceps" — the primary muscles in `Muscle.allCases` order, for the
    /// muted caption under the preset name.
    var primaryMuscleSummary: String {
        let primaries = Set(tags.filter { $0.intensity == .primary }.map(\.muscle))
        return Muscle.allCases
            .filter { primaries.contains($0) }
            .map(\.displayName)
            .joined(separator: ", ")
    }
}

/// The built-in exercise library (39 common dumbbell / barbell / machine / bodyweight
/// moves) shown by the preset list in the "New exercise" sheet.
///
/// Tagging follows the same three intensities as the form: `primary` is what the
/// exercise trains, `secondary` clearly helps, `stabiliser` only holds the position.
/// Every preset has at least one primary muscle.
nonisolated enum ExercisePresets {

    typealias Category = ExercisePreset.Category

    /// Every preset, grouped by category in `Category.allCases` order.
    static let all: [ExercisePreset] = [

        // MARK: Chest

        ExercisePreset(
            name: "Dumbbell bench press",
            category: .chest,
            tags: tags(primary: [.chest], secondary: [.deltoidFront, .triceps])
        ),
        ExercisePreset(
            name: "Incline dumbbell press",
            category: .chest,
            tags: tags(primary: [.chest], secondary: [.deltoidFront, .triceps])
        ),
        ExercisePreset(
            name: "Dumbbell fly",
            category: .chest,
            tags: tags(primary: [.chest], secondary: [.deltoidFront], stabiliser: [.biceps])
        ),
        ExercisePreset(
            name: "Cable crossover",
            category: .chest,
            tags: tags(primary: [.chest], secondary: [.deltoidFront], stabiliser: [.abs])
        ),
        ExercisePreset(
            name: "Push-up",
            category: .chest,
            tags: tags(
                primary: [.chest],
                secondary: [.deltoidFront, .triceps],
                stabiliser: [.abs, .lowerBack]
            )
        ),

        // MARK: Back

        ExercisePreset(
            name: "Dumbbell row",
            category: .back,
            tags: tags(
                primary: [.lats, .upperBack],
                secondary: [.biceps, .traps],
                stabiliser: [.forearms, .lowerBack]
            )
        ),
        ExercisePreset(
            name: "Pull-up",
            category: .back,
            tags: tags(
                primary: [.lats],
                secondary: [.biceps, .upperBack],
                stabiliser: [.forearms, .abs]
            )
        ),
        ExercisePreset(
            name: "Lat pulldown",
            category: .back,
            tags: tags(primary: [.lats], secondary: [.biceps, .upperBack], stabiliser: [.forearms])
        ),
        ExercisePreset(
            name: "Seated cable row",
            category: .back,
            tags: tags(
                primary: [.upperBack],
                secondary: [.biceps, .traps, .lats],
                stabiliser: [.lowerBack]
            )
        ),
        ExercisePreset(
            name: "Dumbbell shrug",
            category: .back,
            tags: tags(primary: [.traps], secondary: [.forearms, .upperBack])
        ),

        // MARK: Shoulders

        ExercisePreset(
            name: "Dumbbell shoulder press",
            category: .shoulders,
            tags: tags(
                primary: [.deltoidFront],
                secondary: [.deltoidSide, .triceps, .traps],
                stabiliser: [.abs]
            )
        ),
        ExercisePreset(
            name: "Lateral raise",
            category: .shoulders,
            tags: tags(primary: [.deltoidSide], secondary: [.deltoidFront, .traps])
        ),
        ExercisePreset(
            name: "Front raise",
            category: .shoulders,
            tags: tags(primary: [.deltoidFront], secondary: [.deltoidSide], stabiliser: [.traps, .abs])
        ),
        ExercisePreset(
            name: "Rear delt fly",
            category: .shoulders,
            tags: tags(primary: [.deltoidRear], secondary: [.upperBack, .traps])
        ),
        ExercisePreset(
            name: "Face pull",
            category: .shoulders,
            tags: tags(primary: [.deltoidRear], secondary: [.upperBack, .traps], stabiliser: [.biceps])
        ),

        // MARK: Arms

        ExercisePreset(
            name: "Dumbbell bicep curl",
            category: .arms,
            tags: tags(primary: [.biceps], secondary: [.forearms])
        ),
        ExercisePreset(
            name: "Dumbbell hammer curl",
            category: .arms,
            tags: tags(primary: [.biceps, .forearms])
        ),
        ExercisePreset(
            name: "Dumbbell preacher curl",
            category: .arms,
            tags: tags(primary: [.biceps], secondary: [.forearms])
        ),
        ExercisePreset(
            name: "Concentration curl",
            category: .arms,
            isUnilateral: true,
            tags: tags(primary: [.biceps], secondary: [.forearms])
        ),
        ExercisePreset(
            name: "Overhead tricep extension",
            category: .arms,
            tags: tags(primary: [.triceps], stabiliser: [.deltoidFront, .abs])
        ),
        ExercisePreset(
            name: "Tricep kickback",
            category: .arms,
            tags: tags(primary: [.triceps], secondary: [.deltoidRear], stabiliser: [.lowerBack])
        ),
        ExercisePreset(
            name: "Skull crusher",
            category: .arms,
            tags: tags(primary: [.triceps], stabiliser: [.deltoidFront, .forearms])
        ),

        // MARK: Legs

        ExercisePreset(
            name: "Dumbbell squat",
            category: .legs,
            tags: tags(
                primary: [.quads, .glutes],
                secondary: [.hamstrings, .adductors],
                stabiliser: [.abs, .lowerBack]
            )
        ),
        ExercisePreset(
            name: "Goblet squat",
            category: .legs,
            tags: tags(
                primary: [.quads],
                secondary: [.glutes, .adductors, .abs],
                stabiliser: [.lowerBack]
            )
        ),
        ExercisePreset(
            name: "Bulgarian split squat",
            category: .legs,
            isUnilateral: true,
            tags: tags(
                primary: [.quads, .glutes],
                secondary: [.hamstrings, .adductors],
                stabiliser: [.abs, .calves]
            )
        ),
        ExercisePreset(
            name: "Dumbbell lunge",
            category: .legs,
            isUnilateral: true,
            tags: tags(
                primary: [.quads, .glutes],
                secondary: [.hamstrings],
                stabiliser: [.abs, .calves]
            )
        ),
        ExercisePreset(
            name: "Romanian deadlift",
            category: .legs,
            tags: tags(
                primary: [.hamstrings, .glutes],
                secondary: [.lowerBack],
                stabiliser: [.traps, .forearms]
            )
        ),
        ExercisePreset(
            name: "Dumbbell deadlift",
            category: .legs,
            tags: tags(
                primary: [.hamstrings, .glutes],
                secondary: [.lowerBack, .quads],
                stabiliser: [.traps, .forearms]
            )
        ),
        ExercisePreset(
            name: "Glute bridge",
            category: .legs,
            tags: tags(primary: [.glutes], secondary: [.hamstrings], stabiliser: [.abs, .lowerBack])
        ),
        ExercisePreset(
            name: "Hip thrust",
            category: .legs,
            tags: tags(primary: [.glutes], secondary: [.hamstrings, .quads], stabiliser: [.abs])
        ),
        ExercisePreset(
            name: "Calf raise",
            category: .legs,
            tags: tags(primary: [.calves])
        ),
        ExercisePreset(
            name: "Leg extension",
            category: .legs,
            tags: tags(primary: [.quads])
        ),

        // MARK: Core

        ExercisePreset(
            name: "Plank",
            category: .core,
            tags: tags(primary: [.abs], secondary: [.obliques], stabiliser: [.deltoidFront, .lowerBack])
        ),
        ExercisePreset(
            name: "Side plank",
            category: .core,
            isUnilateral: true,
            tags: tags(primary: [.obliques], secondary: [.abs], stabiliser: [.deltoidSide, .glutes])
        ),
        ExercisePreset(
            name: "Crunch",
            category: .core,
            tags: tags(primary: [.abs], secondary: [.obliques])
        ),
        ExercisePreset(
            name: "Bicycle crunch",
            category: .core,
            tags: tags(primary: [.abs, .obliques], stabiliser: [.quads])
        ),
        ExercisePreset(
            name: "Leg raise",
            category: .core,
            tags: tags(primary: [.abs], secondary: [.obliques], stabiliser: [.quads])
        ),
        ExercisePreset(
            name: "Russian twist",
            category: .core,
            tags: tags(primary: [.obliques, .abs], stabiliser: [.lowerBack])
        ),
        ExercisePreset(
            name: "Farmer's walk",
            category: .core,
            tags: tags(
                primary: [.forearms, .traps],
                secondary: [.abs, .obliques],
                stabiliser: [.lowerBack]
            )
        ),
    ]

    /// The presets of one category, in table order.
    static func presets(in category: Category) -> [ExercisePreset] {
        all.filter { $0.category == category }
    }

    /// Builds a tag list in `Muscle.allCases` order — the same order `MuscleTagList`
    /// produces — so an exercise added from a preset is byte-identical to one whose
    /// chips were tapped by hand.
    private static func tags(
        primary: [Muscle] = [],
        secondary: [Muscle] = [],
        stabiliser: [Muscle] = []
    ) -> [MuscleTag] {
        var byMuscle: [Muscle: Intensity] = [:]
        for muscle in stabiliser { byMuscle[muscle] = .stabiliser }
        for muscle in secondary { byMuscle[muscle] = .secondary }
        for muscle in primary { byMuscle[muscle] = .primary }
        return Muscle.allCases.compactMap { muscle in
            byMuscle[muscle].map { MuscleTag(muscle: muscle, intensity: $0) }
        }
    }
}
