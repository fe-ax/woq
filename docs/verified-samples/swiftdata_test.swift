import Foundation
import SwiftData

enum Side: String, Codable { case left, right, both }

@Model
final class Exercise {
    #Index<Exercise>([\.lastPerformed], [\.name])
    #Unique<Exercise>([\.name])
    var name: String
    var lastPerformed: Date?
    var isUnilateral: Bool
    @Relationship(deleteRule: .cascade, inverse: \PerformanceEntry.exercise)
    var entries: [PerformanceEntry]
    init(name: String, lastPerformed: Date? = nil, isUnilateral: Bool = false) {
        self.name = name; self.lastPerformed = lastPerformed; self.isUnilateral = isUnilateral; self.entries = []
    }
}

@Model
final class PerformanceEntry {
    var date: Date
    var weight: Double
    var reps: Int
    var sideRaw: String
    var sideEnum: Side
    var exercise: Exercise?
    init(date: Date, weight: Double, reps: Int, side: Side) {
        self.date = date; self.weight = weight; self.reps = reps; self.sideRaw = side.rawValue; self.sideEnum = side
    }
}

@Model final class Tag {
    @Attribute(.unique) var name: String
    var color: String
    init(name: String, color: String) { self.name = name; self.color = color }
}

@main
struct Main {
    static func main() throws {
        setvbuf(stdout, nil, _IONBF, 0)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, PerformanceEntry.self, Tag.self, configurations: config)
        let ctx = ModelContext(container)
        let now = Date()
        ctx.insert(Exercise(name: "b-old", lastPerformed: now.addingTimeInterval(-864000)))
        ctx.insert(Exercise(name: "nil1"))
        ctx.insert(Exercise(name: "a-recent", lastPerformed: now))
        ctx.insert(Exercise(name: "nil2"))
        try ctx.save()
        func run<T: PersistentModel>(_ label: String, _ fd: FetchDescriptor<T>, _ f: (T) -> String) {
            do { print(label, try ctx.fetch(fd).map(f)) } catch { print(label, "ERROR:", error) }
        }
        run("sort forward :", FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.lastPerformed, order: .forward), SortDescriptor(\.name)]), \.name)
        run("sort reverse :", FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.lastPerformed, order: .reverse), SortDescriptor(\.name)]), \.name)
        let q = "NIL"
        run("localizedStandardContains(\"NIL\"):", FetchDescriptor(predicate: #Predicate<Exercise> { $0.name.localizedStandardContains(q) }), \.name)
        run("contains(\"NIL\") case-sensitive:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.name.contains(q) }), \.name)
        run("lastPerformed == nil:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.lastPerformed == nil }), \.name)
        let cutoff = now.addingTimeInterval(-1)
        run("forced unwrap:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.lastPerformed! < cutoff }), \.name)
        let past = Date.distantPast
        run("?? coalesce < cutoff:", FetchDescriptor(predicate: #Predicate<Exercise> { ($0.lastPerformed ?? past) < cutoff }), \.name)
        run("flatMap < cutoff == true:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.lastPerformed.flatMap { $0 < cutoff } == true }), \.name)
        run("nil || flatMap:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.lastPerformed == nil || $0.lastPerformed.flatMap { $0 < cutoff } == true }), \.name)
        let ex = try ctx.fetch(FetchDescriptor(predicate: #Predicate<Exercise> { $0.name == "nil1" })).first!
        let e = PerformanceEntry(date: now, weight: 20, reps: 8, side: .left)
        e.exercise = ex
        ctx.insert(e)
        try ctx.save()
        print("entries via relationship after save:", ex.entries.count, "| exercise.lastPerformed still nil:", ex.lastPerformed == nil)
        let sideRaw = Side.left.rawValue
        run("optional-relationship chain + rawValue:", FetchDescriptor(predicate: #Predicate<PerformanceEntry> { $0.exercise?.name == "nil1" && $0.sideRaw == sideRaw }), { "\($0.reps)" })
        let sideEnum = Side.left
        run("stored enum == .left:", FetchDescriptor(predicate: #Predicate<PerformanceEntry> { $0.sideEnum == sideEnum }), { "\($0.reps)" })
        run("entries.count > 0:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.entries.count > 0 }), \.name)
        run("entries.isEmpty:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.entries.isEmpty }), \.name)
        run("entries.contains{reps>5}:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.entries.contains { $0.reps > 5 } }), \.name)
        // upsert tests
        ctx.insert(Tag(name: "a", color: "red")); try ctx.save()
        ctx.insert(Tag(name: "a", color: "blue"))
        do { try ctx.save(); print("@Attribute(.unique) second save OK") } catch { print("unique save ERROR:", error) }
        run("tags after upsert:", FetchDescriptor<Tag>(), { "\($0.name)=\($0.color)" })
        ctx.insert(Exercise(name: "nil1", isUnilateral: true))
        do { try ctx.save(); print("#Unique second save OK") } catch { print("#Unique save ERROR:", error) }
        run("exercises named nil1:", FetchDescriptor(predicate: #Predicate<Exercise> { $0.name == "nil1" }), { "\($0.name) unilateral=\($0.isUnilateral) entries=\($0.entries.count)" })
        // delete cascade
        ctx.delete(ex); try ctx.save()
        print("entries after cascade delete of exercise:", try ctx.fetchCount(FetchDescriptor<PerformanceEntry>()))
        print("in-memory config url:", config.url.path)
        let custom = ModelConfiguration("export", schema: Schema([Exercise.self, PerformanceEntry.self, Tag.self]), url: URL.temporaryDirectory.appending(path: "woq-test.store"))
        print("custom url:", custom.url.path)
        let custom2 = ModelConfiguration(url: URL.temporaryDirectory.appending(path: "woq-test2.store"))
        print("custom2 url:", custom2.url.lastPathComponent, "| default appSupport:", URL.applicationSupportDirectory.path)
    }
}
