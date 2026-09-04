import Foundation
import SwiftData

public enum Side: String, Codable, Sendable { case left, right, both }

@Model
public final class Exercise {
    public var name: String
    public var lastPerformed: Date?
    public var isUnilateral: Bool
    @Relationship(deleteRule: .cascade, inverse: \PerformanceEntry.exercise)
    public var entries: [PerformanceEntry]
    public init(name: String, lastPerformed: Date? = nil, isUnilateral: Bool = false) {
        self.name = name; self.lastPerformed = lastPerformed; self.isUnilateral = isUnilateral; self.entries = []
    }
}

@Model
public final class PerformanceEntry {
    public var date: Date
    public var weight: Double
    public var reps: Int
    public var sideRaw: String
    public var exercise: Exercise?
    public init(date: Date, weight: Double, reps: Int, side: Side) {
        self.date = date; self.weight = weight; self.reps = reps; self.sideRaw = side.rawValue
    }
}

public enum Store {
    public static func inMemory() throws -> ModelContainer {
        try ModelContainer(for: Exercise.self, PerformanceEntry.self,
                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}

/// Pure helper deliberately opted out of the module's MainActor default.
nonisolated public func queueSortKey(_ last: Date?) -> Double { last?.timeIntervalSince1970 ?? -.infinity }
