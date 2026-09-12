import Foundation

/// The fixed equipment list an exercise can be tagged with (decided 2026-09-12: chips, not
/// free text). One per exercise, optional.
///
/// Raw values are persisted in SwiftData (`Exercise.equipmentRawValue`) and in the backup JSON
/// and must never change; add cases at the end. The case order is the chip order on the form.
/// Stored as the raw string rather than the enum so the list can grow without a schema change
/// and a `#Predicate` could still compare it (PLAN.md pitfall 28: enums cannot be compared).
nonisolated enum Equipment: String, CaseIterable, Codable, Identifiable, Sendable {
    case barbell
    case dumbbell
    case kettlebell
    case cable
    case machine
    case bodyweight
    case band
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: String(localized: "Barbell")
        case .dumbbell: String(localized: "Dumbbell")
        case .kettlebell: String(localized: "Kettlebell")
        case .cable: String(localized: "Cable")
        case .machine: String(localized: "Machine")
        case .bodyweight: String(localized: "Bodyweight")
        case .band: String(localized: "Band")
        case .other: String(localized: "Other")
        }
    }
}
